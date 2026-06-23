import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/auth.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/local/database/tables/categories.dart';
import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/data/repositories/bill_repository.dart';
import 'package:waterflyiii/data/repositories/budget_repository.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/data/repositories/insight_repository.dart';
import 'package:waterflyiii/data/repositories/tag_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/retry_manager.dart';
import 'package:waterflyiii/services/sync/sync_error_classifier.dart';
import 'package:waterflyiii/services/sync/sync_log_sanitizer.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/settings.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';

final Logger log = Logger("Upload");

enum UploadRunStatus {
  success,
  noPendingChanges,
  skippedAlreadyRunning,
  skippedOffline,
  skippedMobileDataDisabled,
  paused,
  partialFailure,
  authFailure,
}

class UploadRunResult {
  const UploadRunResult({
    required this.status,
    required this.initialPendingCount,
    required this.succeededCount,
    required this.failedCount,
    required this.unattemptedCount,
    this.firstSanitizedError,
  });

  final UploadRunStatus status;
  final int initialPendingCount;
  final int succeededCount;
  final int failedCount;
  final int unattemptedCount;
  final String? firstSanitizedError;

  bool get completedSuccessfully =>
      status == UploadRunStatus.success ||
      status == UploadRunStatus.noPendingChanges;

  bool get shouldReportBackgroundSuccess => completedSuccessfully;
}

class UploadPermanentException implements Exception {
  const UploadPermanentException({
    required this.entityType,
    required this.statusCode,
    required this.message,
  });

  final String entityType;
  final int statusCode;
  final String message;

  @override
  String toString() =>
      'UploadPermanentException(entityType: $entityType, statusCode: $statusCode, message: $message)';
}

class UploadService extends ChangeNotifier {
  static const String _uploadLeaseEntityType = 'upload_lease';
  static const Duration _uploadLeaseTtl = Duration(minutes: 30);

  final Isar isar;
  final FireflyService fireflyService;
  final ConnectivityService connectivityService;
  final RetryManager retryManager;
  final ConflictResolver conflictResolver;
  final SyncNotifications notifications;
  final SettingsProvider? settingsProvider;
  late final String _leaseOwner =
      'upload-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  UploadService({
    required this.isar,
    required this.fireflyService,
    required this.connectivityService,
    required this.notifications,
    this.settingsProvider,
  }) : retryManager = RetryManager(isar),
       conflictResolver = ConflictResolver(isar) {
    // Set settings provider for notifications localization
    notifications.setSettingsProvider(settingsProvider);
  }

  String _leasePayload() {
    return jsonEncode(<String, String>{'owner': _leaseOwner});
  }

  String? _leaseOwnerFrom(SyncMetadata metadata) {
    final String? payload = metadata.lastError;
    if (payload == null) return null;
    try {
      final Map<String, dynamic> jsonData =
          jsonDecode(payload) as Map<String, dynamic>;
      return jsonData['owner'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> _acquireUploadLease() async {
    final DateTime now = DateTime.now().toUtc();
    bool acquired = false;

    await isar.writeTxn(() async {
      final SyncMetadata? existing = await isar.syncMetadatas
          .filter()
          .entityTypeEqualTo(_uploadLeaseEntityType)
          .findFirst();
      final bool expired =
          existing?.nextRetryAt == null || existing!.nextRetryAt!.isBefore(now);
      final bool sameOwner =
          existing != null && _leaseOwnerFrom(existing) == _leaseOwner;

      if (existing == null) {
        final SyncMetadata metadata = SyncMetadata()
          ..entityType = _uploadLeaseEntityType
          ..lastError = _leasePayload()
          ..nextRetryAt = now.add(_uploadLeaseTtl);
        await isar.syncMetadatas.put(metadata);
        acquired = true;
      } else if (expired || sameOwner) {
        existing
          ..lastError = _leasePayload()
          ..nextRetryAt = now.add(_uploadLeaseTtl);
        await isar.syncMetadatas.put(existing);
        acquired = true;
      }
    });

    return acquired;
  }

  Future<void> _renewUploadLease() async {
    final DateTime now = DateTime.now().toUtc();
    await isar.writeTxn(() async {
      final SyncMetadata? existing = await isar.syncMetadatas
          .filter()
          .entityTypeEqualTo(_uploadLeaseEntityType)
          .findFirst();
      if (existing == null || _leaseOwnerFrom(existing) != _leaseOwner) {
        return;
      }
      existing.nextRetryAt = now.add(_uploadLeaseTtl);
      await isar.syncMetadatas.put(existing);
    });
  }

  Future<void> _releaseUploadLease() async {
    await isar.writeTxn(() async {
      final SyncMetadata? existing = await isar.syncMetadatas
          .filter()
          .entityTypeEqualTo(_uploadLeaseEntityType)
          .findFirst();
      if (existing == null || _leaseOwnerFrom(existing) != _leaseOwner) {
        return;
      }
      await isar.syncMetadatas.delete(existing.id);
    });
  }

  String _sanitizeUploadError(Object error) {
    if (error is Response) {
      return sanitizeSyncLogText(
        'HTTP ${error.statusCode}: ${error.error ?? 'request failed'}',
      );
    }
    if (error is UploadPermanentException) {
      return sanitizeSyncLogText('HTTP ${error.statusCode}: ${error.message}');
    }
    return sanitizeSyncLogText(error);
  }

  Future<void> _recordMetadataFailure(
    String entityType,
    String error, {
    required bool syncPaused,
  }) async {
    final String sanitizedError = sanitizeSyncLogText(error);
    await _updateSyncMetadata(
      'upload',
      lastError: sanitizedError,
      syncPaused: syncPaused,
    );
    await _updateSyncMetadata(
      entityType,
      lastError: sanitizedError,
      syncPaused: syncPaused,
    );
  }

  Future<void> _handleAuthFailure(String entityType, String error) async {
    final String sanitizedError = sanitizeSyncLogText(error);
    await _updateSyncMetadata(
      'auth',
      credentialsValidated: false,
      credentialsInvalid: true,
    );
    await _recordMetadataFailure(entityType, sanitizedError, syncPaused: false);
    try {
      await notifications.cancelUploadProgress();
      await notifications.showCredentialError();
    } catch (_) {
      // Notification failures must not hide credential state.
    }
  }

  Future<UploadRunResult> uploadPendingChanges({
    bool forceRetry = false,
  }) async {
    if (_isUploading) {
      log.config("Upload already in progress, skipping");
      return const UploadRunResult(
        status: UploadRunStatus.skippedAlreadyRunning,
        initialPendingCount: 0,
        succeededCount: 0,
        failedCount: 0,
        unattemptedCount: 0,
      );
    }

    final bool leaseAcquired = await _acquireUploadLease();
    if (!leaseAcquired) {
      log.config("Another upload run owns the upload lease, skipping");
      return const UploadRunResult(
        status: UploadRunStatus.skippedAlreadyRunning,
        initialPendingCount: 0,
        succeededCount: 0,
        failedCount: 0,
        unattemptedCount: 0,
      );
    }

    _isUploading = true;
    notifyListeners();

    try {
      if (forceRetry) {
        await _updateSyncMetadata(
          'upload',
          clearError: true,
          syncPaused: false,
          retryCount: 0,
          clearNextRetryAt: true,
        );
      }

      // Check if upload is paused
      if (!forceRetry && await retryManager.isPaused('upload')) {
        log.config("Upload is paused");
        return const UploadRunResult(
          status: UploadRunStatus.paused,
          initialPendingCount: 0,
          succeededCount: 0,
          failedCount: 0,
          unattemptedCount: 0,
        );
      }

      // Check connectivity
      if (!connectivityService.isOnline) {
        log.config("Device is offline, skipping upload");
        return const UploadRunResult(
          status: UploadRunStatus.skippedOffline,
          initialPendingCount: 0,
          succeededCount: 0,
          failedCount: 0,
          unattemptedCount: 0,
        );
      }

      // Check mobile data setting
      if (connectivityService.isMobile &&
          (settingsProvider?.syncUseMobileData ?? false) == false) {
        log.config("Mobile data upload disabled, skipping");
        return const UploadRunResult(
          status: UploadRunStatus.skippedMobileDataDisabled,
          initialPendingCount: 0,
          succeededCount: 0,
          failedCount: 0,
          unattemptedCount: 0,
        );
      }

      // Get pending changes
      final List<PendingChanges> pending = await isar.pendingChanges
          .filter()
          .syncedEqualTo(false)
          .findAll()
          .then(
            (List<PendingChanges> list) => list.toList()
              ..sort(
                (PendingChanges a, PendingChanges b) =>
                    a.createdAt.compareTo(b.createdAt),
              ),
          );

      if (pending.isEmpty) {
        log.config("No pending changes to upload");
        await _updateSyncMetadata(
          'upload',
          clearError: true,
          syncPaused: false,
          retryCount: 0,
          clearNextRetryAt: true,
        );
        return const UploadRunResult(
          status: UploadRunStatus.noPendingChanges,
          initialPendingCount: 0,
          succeededCount: 0,
          failedCount: 0,
          unattemptedCount: 0,
        );
      }

      try {
        await notifications.showSyncStarted(
          notificationId: SyncNotifications.uploadNotificationId,
        );
      } catch (e, stackTrace) {
        log.warning(
          "Failed to show upload started notification",
          sanitizeSyncLogText(e),
          StackTrace.fromString(sanitizeSyncLogText(stackTrace)),
        );
        // Continue anyway - notification failure shouldn't block upload
      }

      final int initialPendingCount = pending.length;
      int successCount = 0;
      int failureCount = 0;
      int unattemptedCount = 0;
      UploadRunStatus status = UploadRunStatus.success;
      String? firstError;

      for (int index = 0; index < pending.length; index++) {
        final PendingChanges change = pending[index];
        await _renewUploadLease();
        try {
          log.info(
            'Upload change start id=${change.id} entity=${change.entityType} '
            'op=${change.operation} hasLocalPending=${change.localPendingId != null} '
            'retry=${change.retryCount}',
          );
          final bool success = await _processChange(change);
          if (success) {
            successCount++;
          } else {
            failureCount++;
            status = UploadRunStatus.partialFailure;
            firstError ??= change.lastError ?? 'Upload change failed';
            final String failureError = firstError;
            await _incrementRetryCount(change.id, failureError);
            await _recordMetadataFailure(
              change.entityType,
              failureError,
              syncPaused: false,
            );
          }
        } catch (e) {
          final String sanitizedError = _sanitizeUploadError(e);
          firstError ??= sanitizedError;
          failureCount++;

          if (SyncErrorClassifier.isAuthError(e)) {
            status = UploadRunStatus.authFailure;
            unattemptedCount = pending.length - index - 1;
            await _handleAuthFailure(change.entityType, sanitizedError);
            break;
          }

          if (SyncErrorClassifier.isNetworkError(e) ||
              SyncErrorClassifier.isTimeoutError(e) ||
              SyncErrorClassifier.isServerError(e)) {
            status = UploadRunStatus.paused;
            unattemptedCount = pending.length - index - 1;
            await retryManager.pauseWithBackoff('upload', sanitizedError);
            final SyncMetadata? uploadMetadata = await retryManager.getMetadata(
              'upload',
            );
            await _updateSyncMetadata(
              change.entityType,
              lastError: sanitizedError,
              syncPaused: true,
              retryCount: uploadMetadata?.retryCount,
              nextRetryAt: uploadMetadata?.nextRetryAt,
            );
            try {
              await notifications.showSyncPaused(
                sanitizedError,
                notificationId: SyncNotifications.uploadNotificationId,
                pausedNotificationId:
                    SyncNotifications.uploadPausedNotificationId,
              );
            } catch (_) {
              // Notification failures must not hide sync state.
            }
            break;
          }

          status = UploadRunStatus.partialFailure;
          await _incrementRetryCount(change.id, sanitizedError);
          await _recordMetadataFailure(
            change.entityType,
            sanitizedError,
            syncPaused: false,
          );
        }
      }

      // Mark insights as stale after successful uploads
      if (successCount > 0) {
        final InsightRepository insightRepo = InsightRepository(isar);
        await insightRepo.markStale(null, null);
      }

      if (failureCount == 0 && unattemptedCount == 0) {
        await retryManager.resetRetry('upload');
        await _updateSyncMetadata(
          'upload',
          lastUploadSync: DateTime.now().toUtc(),
          clearError: true,
          syncPaused: false,
          retryCount: 0,
          clearNextRetryAt: true,
        );
        for (final String entityType
            in pending
                .map((PendingChanges change) => change.entityType)
                .toSet()) {
          await _updateSyncMetadata(
            entityType,
            clearError: true,
            syncPaused: false,
            clearNextRetryAt: true,
          );
        }

        try {
          await notifications.showSyncCompleted(
            notificationId: SyncNotifications.uploadNotificationId,
          );
        } catch (e) {
          log.warning(
            "Failed to show upload completed notification",
            sanitizeSyncLogText(e),
          );
        }
        log.config("Upload completed: $successCount success, 0 failures");
        return UploadRunResult(
          status: UploadRunStatus.success,
          initialPendingCount: initialPendingCount,
          succeededCount: successCount,
          failedCount: 0,
          unattemptedCount: 0,
        );
      }

      if (status == UploadRunStatus.success) {
        status = UploadRunStatus.partialFailure;
      }

      if (status == UploadRunStatus.partialFailure) {
        await _updateSyncMetadata(
          'upload',
          lastError:
              'Upload incomplete: $failureCount failed, $unattemptedCount unattempted',
          syncPaused: false,
        );
        try {
          await notifications.cancelUploadProgress();
        } catch (_) {
          // Notification failures must not hide sync state.
        }
      }

      log.warning(
        "Upload incomplete status=${status.name} success=$successCount "
        "failure=$failureCount unattempted=$unattemptedCount "
        "error=${firstError ?? 'none'}",
      );
      return UploadRunResult(
        status: status,
        initialPendingCount: initialPendingCount,
        succeededCount: successCount,
        failedCount: failureCount,
        unattemptedCount: unattemptedCount,
        firstSanitizedError: firstError,
      );
    } catch (e) {
      final String sanitizedError = _sanitizeUploadError(e);
      log.severe("Upload failed: $sanitizedError");

      if (SyncErrorClassifier.isAuthError(e)) {
        await _handleAuthFailure('upload', sanitizedError);
        return UploadRunResult(
          status: UploadRunStatus.authFailure,
          initialPendingCount: 0,
          succeededCount: 0,
          failedCount: 1,
          unattemptedCount: 0,
          firstSanitizedError: sanitizedError,
        );
      } else if (SyncErrorClassifier.isNetworkError(e) ||
          SyncErrorClassifier.isTimeoutError(e) ||
          SyncErrorClassifier.isServerError(e)) {
        await retryManager.pauseWithBackoff('upload', sanitizedError);
        try {
          await notifications.showSyncPaused(
            sanitizedError,
            notificationId: SyncNotifications.uploadNotificationId,
            pausedNotificationId: SyncNotifications.uploadPausedNotificationId,
          );
        } catch (_) {
          // Notification failures must not hide sync state.
        }
      }
      return UploadRunResult(
        status: UploadRunStatus.partialFailure,
        initialPendingCount: 0,
        succeededCount: 0,
        failedCount: 1,
        unattemptedCount: 0,
        firstSanitizedError: sanitizedError,
      );
    } finally {
      await _releaseUploadLease();
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> _processChange(PendingChanges change) async {
    final FireflyIii api = fireflyService.api;
    final String operation = change.operation.toLowerCase();

    try {
      switch (operation) {
        case final String op when op == PendingChangeOperation.create.name:
          return await _processCreate(change, api);
        case final String op when op == PendingChangeOperation.update.name:
          return await _processUpdate(change, api);
        case final String op when op == PendingChangeOperation.delete.name:
          return await _processDelete(change, api);
        default:
          log.warning("Unknown operation: ${change.operation}");
          return false;
      }
    } catch (e) {
      log.warning(
        "Error processing id=${change.id} op=${change.operation} "
        "entity=${change.entityType}: ${_sanitizeUploadError(e)}",
      );
      rethrow;
    }
  }

  Future<bool> _processCreate(PendingChanges change, FireflyIii api) async {
    final Map<String, dynamic> data =
        jsonDecode(change.data!) as Map<String, dynamic>;
    Response<dynamic>? response;

    try {
      switch (change.entityType) {
        case 'transactions':
          final TransactionStore store = await _backfillPendingExternalIds(
            change,
            TransactionStore.fromJson(data),
          );
          if (await _reconcileExistingTransaction(change, store, api)) {
            return true;
          }

          try {
            response = await api.v1TransactionsPost(body: store);
          } catch (e) {
            if (SyncErrorClassifier.isConflictError(e)) {
              if (await _reconcileExistingTransaction(change, store, api)) {
                return true;
              }
              await _logUploadConflict(change);
              return false;
            }
            rethrow;
          }

          if (SyncErrorClassifier.isConflictError(response)) {
            if (await _reconcileExistingTransaction(change, store, api)) {
              return true;
            }
            await _logUploadConflict(change);
            return false;
          }

          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            await _completeTransactionCreate(
              change: change,
              store: store,
              transaction: response.body!.data as TransactionRead,
            );
            return true;
          }
          break;
        case 'accounts':
          final AccountStore store = AccountStore.fromJson(data);
          response = await api.v1AccountsPost(body: store);
          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            final AccountRepository accountRepo = AccountRepository(isar);
            await accountRepo.upsertFromSync(response.body!.data);
            await _markChangeAsSynced(change.id);
            return true;
          }
          break;
        case 'categories':
          final CategoryStore store = CategoryStore.fromJson(data);
          response = await api.v1CategoriesPost(body: store);
          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            final CategoryRead created = response.body!.data;
            final CategoryRepository repo = CategoryRepository(isar);
            await _deleteMatchingPendingCategory(change, store);
            await repo.upsertFromSync(created);
            await _markChangeAsSynced(change.id);
            return true;
          }
          break;
        case 'tags':
          final TagModelStore store = TagModelStore.fromJson(data);
          response = await api.v1TagsPost(body: store);
          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            final TagRepository tagRepo = TagRepository(isar);
            await tagRepo.upsertFromSync(response.body!.data);
            await _markChangeAsSynced(change.id);
            return true;
          }
          break;
        case 'bills':
          final BillStore store = BillStore.fromJson(data);
          response = await api.v1BillsPost(body: store);
          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            final BillRepository billRepo = BillRepository(isar);
            await billRepo.upsertFromSync(response.body!.data);
            await _markChangeAsSynced(change.id);
            return true;
          }
          break;
        case 'budgets':
          final BudgetStore store = BudgetStore.fromJson(data);
          response = await api.v1BudgetsPost(body: store);
          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            final BudgetRepository budgetRepo = BudgetRepository(isar);
            await budgetRepo.upsertFromSync(response.body!.data);
            await _markChangeAsSynced(change.id);
            return true;
          }
          break;
        case 'budget_limits':
          final String? budgetId = data['budget_id'] as String?;
          if (budgetId == null) {
            log.warning("Budget limit missing budget_id");
            return false;
          }
          final BudgetLimitStore store = BudgetLimitStore.fromJson(data);
          response = await api.v1BudgetsIdLimitsPost(id: budgetId, body: store);
          _throwIfFailedResponse(response, change.entityType);
          if (response.isSuccessful && response.body != null) {
            final BudgetRepository budgetRepo = BudgetRepository(isar);
            await budgetRepo.upsertBudgetLimitFromSync(response.body!.data);
            await _markChangeAsSynced(change.id);
            return true;
          }
          break;
        default:
          log.warning(
            "Unsupported entity type for CREATE: ${change.entityType}",
          );
          return false;
      }

      if (SyncErrorClassifier.isConflictError(response)) {
        await _logUploadConflict(change);
        return false;
      }

      if (response.isSuccessful) {
        await _markChangeAsSynced(change.id);
        return true;
      }
      return false;
    } catch (e) {
      if (SyncErrorClassifier.isConflictError(e)) {
        await _logUploadConflict(change);
        return false;
      }
      rethrow;
    }
  }

  Future<bool> _processUpdate(PendingChanges change, FireflyIii api) async {
    if (change.entityId == null) {
      log.warning("UPDATE operation requires entityId");
      return false;
    }

    final Map<String, dynamic> data =
        jsonDecode(change.data!) as Map<String, dynamic>;

    final String entityId = change.entityId!;
    try {
      Response<dynamic>? response;
      switch (change.entityType) {
        case 'transactions':
          final TransactionUpdate update = TransactionUpdate.fromJson(data);
          response = await api.v1TransactionsIdPut(id: entityId, body: update);
          if (response.isSuccessful && response.body != null) {
            final TransactionRead updated = response.body!.data;
            final TransactionRepository repo = TransactionRepository(isar);
            await repo.upsertFromSync(updated);
          }
          break;
        case 'accounts':
          final AccountUpdate update = AccountUpdate.fromJson(data);
          response = await api.v1AccountsIdPut(id: entityId, body: update);
          break;
        case 'categories':
          final CategoryUpdate update = CategoryUpdate.fromJson(data);
          response = await api.v1CategoriesIdPut(id: entityId, body: update);
          break;
        case 'tags':
          final TagModelUpdate update = TagModelUpdate.fromJson(data);
          response = await api.v1TagsTagPut(tag: entityId, body: update);
          break;
        case 'bills':
          final BillUpdate update = BillUpdate.fromJson(data);
          response = await api.v1BillsIdPut(id: entityId, body: update);
          break;
        case 'budgets':
          final BudgetUpdate update = BudgetUpdate.fromJson(data);
          response = await api.v1BudgetsIdPut(id: entityId, body: update);
          break;
        case 'budget_limits':
          // Budget limits require budgetId and limitId
          final Map<String, dynamic> dataMap = data;
          final String? budgetId = dataMap['budget_id'] as String?;
          if (budgetId == null) {
            log.warning("Budget limit missing budget_id");
            return false;
          }
          final BudgetLimitUpdate update = BudgetLimitUpdate.fromJson(data);
          response = await api.v1BudgetsIdLimitsLimitIdPut(
            id: budgetId,
            limitId: entityId,
            body: update,
          );
          break;
        default:
          log.warning(
            "Unsupported entity type for UPDATE: ${change.entityType}",
          );
          return false;
      }

      if (response.isSuccessful) {
        await _markChangeAsSynced(change.id);
        return true;
      } else if (response.statusCode == 404) {
        // Entity deleted on server
        await _markChangeAsSynced(change.id);
        return true;
      } else if (SyncErrorClassifier.isConflictError(response)) {
        await _logUploadConflict(change);
        return false;
      } else {
        _throwIfFailedResponse(response, change.entityType);
        return false;
      }
    } catch (e) {
      if (SyncErrorClassifier.isConflictError(e)) {
        await _logUploadConflict(change);
        return false;
      }
      rethrow;
    }
  }

  Future<bool> _processDelete(PendingChanges change, FireflyIii api) async {
    if (change.entityId == null) {
      log.warning("DELETE operation requires entityId");
      return false;
    }

    final String entityId = change.entityId!;
    try {
      Response<dynamic>? response;

      switch (change.entityType) {
        case 'transactions':
          response = await api.v1TransactionsIdDelete(id: entityId);
          break;
        case 'accounts':
          response = await api.v1AccountsIdDelete(id: entityId);
          break;
        case 'categories':
          response = await api.v1CategoriesIdDelete(id: entityId);
          break;
        case 'tags':
          // Tags use tag name, not ID
          response = await api.v1TagsTagDelete(tag: entityId);
          break;
        case 'bills':
          response = await api.v1BillsIdDelete(id: entityId);
          break;
        case 'budgets':
          response = await api.v1BudgetsIdDelete(id: entityId);
          break;
        default:
          log.warning(
            "Unsupported entity type for DELETE: ${change.entityType}",
          );
          return false;
      }

      if (response.isSuccessful || response.statusCode == 404) {
        // 404 means already deleted, which is fine
        await _markChangeAsSynced(change.id);
        return true;
      } else if (SyncErrorClassifier.isConflictError(response)) {
        await _logUploadConflict(change);
        return false;
      } else {
        _throwIfFailedResponse(response, change.entityType);
        return false;
      }
    } catch (e) {
      if (SyncErrorClassifier.isConflictError(e)) {
        await _logUploadConflict(change);
        return false;
      }
      rethrow;
    }
  }

  Future<void> _markChangeAsSynced(int changeId) async {
    await isar.writeTxn(() async {
      await isar.pendingChanges.delete(changeId);
    });
  }

  Future<void> _incrementRetryCount(int changeId, String error) async {
    final PendingChanges? change = await isar.pendingChanges
        .filter()
        .idEqualTo(changeId)
        .findFirst();

    if (change == null) {
      return;
    }

    final int newRetryCount = change.retryCount + 1;
    change
      ..retryCount = newRetryCount
      ..lastError = error;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(change);
    });
  }

  void _throwIfFailedResponse(Response<dynamic> response, String entityType) {
    if (response.isSuccessful ||
        SyncErrorClassifier.isConflictError(response)) {
      return;
    }

    if (SyncErrorClassifier.isAuthError(response) ||
        SyncErrorClassifier.isTimeoutError(response) ||
        SyncErrorClassifier.isServerError(response)) {
      throw response;
    }

    throw UploadPermanentException(
      entityType: entityType,
      statusCode: response.statusCode,
      message: sanitizeSyncLogText(response.error ?? 'request failed'),
    );
  }

  Future<void> _logUploadConflict(PendingChanges change) async {
    const String conflictError = 'Conflict (409): server version is different';
    await conflictResolver.logConflict(
      entityType: change.entityType,
      entityId: change.entityId ?? change.localPendingId ?? 'unknown',
      conflictType: ConflictType.upload,
      localUpdatedAt: null,
      serverUpdatedAt: null,
      resolution: ConflictResolution.localCancelled,
    );
    change.lastError = conflictError;
    await isar.writeTxn(() async {
      await isar.pendingChanges.put(change);
    });
  }

  Future<TransactionStore> _backfillPendingExternalIds(
    PendingChanges change,
    TransactionStore store,
  ) async {
    final Transactions? matchingPending = await _findMatchingPendingTransaction(
      change,
      store,
    );
    final String stableId =
        change.localPendingId ??
        matchingPending?.transactionId ??
        'change-${change.id}';

    bool changed = false;
    final List<TransactionSplitStore> splits = <TransactionSplitStore>[];
    for (int i = 0; i < store.transactions.length; i++) {
      final TransactionSplitStore split = store.transactions[i];
      if (split.externalId?.trim().isNotEmpty ?? false) {
        splits.add(split);
        continue;
      }

      changed = true;
      splits.add(split.copyWith(externalId: 'waterflyiii:$stableId:$i'));
    }

    if (!changed) {
      return store;
    }

    final TransactionStore updated = store.copyWith(transactions: splits);
    change.data = jsonEncode(updated.toJson());
    change.localPendingId ??= matchingPending?.transactionId;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(change);
      if (matchingPending != null) {
        matchingPending.data = jsonEncode(updated.toJson());
        await isar.transactions.put(matchingPending);
      }
    });

    return updated;
  }

  Future<void> _completeTransactionCreate({
    required PendingChanges change,
    required TransactionStore store,
    required TransactionRead transaction,
  }) async {
    final Transactions? matchingPending = await _findMatchingPendingTransaction(
      change,
      store,
    );
    final TransactionRepository repo = TransactionRepository(isar);
    await repo.replacePendingCreateFromSync(
      transaction: transaction,
      pendingChangeId: change.id,
      pendingRowId: matchingPending?.id,
    );
  }

  Future<Transactions?> _findMatchingPendingTransaction(
    PendingChanges change,
    TransactionStore store,
  ) async {
    if (change.localPendingId != null) {
      final Transactions? byId = await isar.transactions
          .filter()
          .transactionIdEqualTo(change.localPendingId!)
          .findFirst();
      if (byId != null) {
        return byId;
      }
    }

    final List<Transactions> allPending = await isar.transactions
        .filter()
        .transactionIdStartsWith('pending-')
        .findAll();

    for (final Transactions pendingTx in allPending) {
      Map<String, dynamic>? pendingData;
      try {
        pendingData = jsonDecode(pendingTx.data) as Map<String, dynamic>;
        final TransactionStore pendingStore = TransactionStore.fromJson(
          pendingData,
        );
        if (_transactionsMatch(store, pendingStore)) {
          return pendingTx;
        }
      } catch (_) {
        if (pendingData == null) {
          continue;
        }
        try {
          if (_jsonTransactionsMatch(store.toJson(), pendingData)) {
            return pendingTx;
          }
        } catch (_) {
          continue;
        }
      }
    }

    return null;
  }

  Future<void> _deleteMatchingPendingCategory(
    PendingChanges change,
    CategoryStore store,
  ) async {
    Categories? matchingPending;

    if (change.localPendingId != null) {
      matchingPending = await isar.categories
          .filter()
          .categoryIdEqualTo(change.localPendingId!)
          .findFirst();
    } else {
      final List<Categories> allPending = await isar.categories
          .filter()
          .categoryIdStartsWith('pending-')
          .findAll();

      for (final Categories pendingCat in allPending) {
        try {
          final Map<String, dynamic> pendingData =
              jsonDecode(pendingCat.data) as Map<String, dynamic>;
          final CategoryRead pendingRead = CategoryRead.fromJson(pendingData);
          if (pendingRead.attributes.name == store.name &&
              (pendingRead.attributes.notes ?? '') == (store.notes ?? '')) {
            matchingPending = pendingCat;
            break;
          }
        } catch (_) {
          continue;
        }
      }
    }

    if (matchingPending == null) {
      return;
    }

    await isar.writeTxn(() async {
      await isar.categories.delete(matchingPending!.id);
    });
  }

  Future<bool> _reconcileExistingTransaction(
    PendingChanges change,
    TransactionStore store,
    FireflyIii api,
  ) async {
    final Set<String> externalIds = store.transactions
        .map((TransactionSplitStore split) => split.externalId?.trim())
        .whereType<String>()
        .where((String externalId) => externalId.isNotEmpty)
        .toSet();
    bool searchEndpointSucceeded = false;

    for (final String externalId in externalIds) {
      final Response<TransactionArray> response = await api
          .v1SearchTransactionsGet(query: externalId, limit: 50, page: 1);
      if (SyncErrorClassifier.isAuthError(response) ||
          SyncErrorClassifier.isTimeoutError(response) ||
          SyncErrorClassifier.isServerError(response)) {
        throw response;
      }
      if (!response.isSuccessful || response.body == null) {
        continue;
      }
      searchEndpointSucceeded = true;
      for (final TransactionRead candidate in response.body!.data) {
        if (_transactionReadMatchesStore(candidate, store)) {
          await _completeTransactionCreate(
            change: change,
            store: store,
            transaction: candidate,
          );
          log.info(
            'Upload transaction reconciled by external id '
            'change=${change.id}',
          );
          return true;
        }
      }
    }

    if (externalIds.isNotEmpty && !searchEndpointSucceeded) {
      return false;
    }
    if (externalIds.isNotEmpty) {
      return false;
    }

    if (store.transactions.isEmpty) {
      return false;
    }

    final Iterable<DateTime> dates = store.transactions.map(
      (TransactionSplitStore split) => split.date,
    );
    DateTime start = dates.first;
    DateTime end = dates.first;
    for (final DateTime date in dates.skip(1)) {
      if (date.isBefore(start)) start = date;
      if (date.isAfter(end)) end = date;
    }
    start = _dateOnly(start).subtract(const Duration(days: 1));
    end = _dateOnly(end).add(const Duration(days: 1));

    int page = 1;
    int totalPages = 1;
    do {
      final Response<TransactionArray> response = await api.v1TransactionsGet(
        limit: 50,
        page: page,
        start: _apiDate(start),
        end: _apiDate(end),
      );
      _throwIfFailedResponse(response, change.entityType);
      if (!response.isSuccessful || response.body == null) {
        return false;
      }

      for (final TransactionRead candidate in response.body!.data) {
        if (_transactionReadMatchesStore(
          candidate,
          store,
          requireExternalId: false,
        )) {
          await _completeTransactionCreate(
            change: change,
            store: store,
            transaction: candidate,
          );
          log.info(
            'Upload transaction reconciled by date window '
            'change=${change.id}',
          );
          return true;
        }
      }

      totalPages = response.body!.meta.pagination?.totalPages ?? totalPages;
      page++;
    } while (page <= totalPages && page <= 3);

    return false;
  }

  bool _transactionReadMatchesStore(
    TransactionRead read,
    TransactionStore store, {
    bool requireExternalId = true,
  }) {
    final List<TransactionSplit> serverSplits = read.attributes.transactions;
    if (serverSplits.length != store.transactions.length) {
      return false;
    }

    if (!_optionalStringMatches(store.groupTitle, read.attributes.groupTitle)) {
      return false;
    }

    for (int i = 0; i < store.transactions.length; i++) {
      if (!_splitMatches(
        store.transactions[i],
        serverSplits[i],
        requireExternalId: requireExternalId,
      )) {
        return false;
      }
    }

    return true;
  }

  bool _splitMatches(
    TransactionSplitStore expected,
    TransactionSplit actual, {
    required bool requireExternalId,
  }) {
    if (expected.type != actual.type) return false;
    if (!_dateOnly(expected.date).isAtSameMomentAs(_dateOnly(actual.date))) {
      return false;
    }
    if (!_amountMatches(expected.amount, actual.amount)) return false;
    if (expected.description.trim() != actual.description.trim()) return false;
    if (!_externalIdMatches(
      expected.externalId,
      actual.externalId,
      requireExternalId: requireExternalId,
    )) {
      return false;
    }
    if (!_optionalStringMatches(expected.currencyId, actual.currencyId)) {
      return false;
    }
    if (!_optionalStringMatches(expected.currencyCode, actual.currencyCode)) {
      return false;
    }
    if (!_optionalStringMatches(expected.sourceId, actual.sourceId)) {
      return false;
    }
    if (!_optionalStringMatches(expected.sourceName, actual.sourceName)) {
      return false;
    }
    if (!_optionalStringMatches(expected.destinationId, actual.destinationId)) {
      return false;
    }
    if (!_optionalStringMatches(
      expected.destinationName,
      actual.destinationName,
    )) {
      return false;
    }
    return true;
  }

  bool _optionalStringMatches(String? expected, String? actual) {
    final String? normalizedExpected = _normalizeNullableString(expected);
    if (normalizedExpected == null) return true;
    return normalizedExpected == _normalizeNullableString(actual);
  }

  bool _externalIdMatches(
    String? expected,
    String? actual, {
    required bool requireExternalId,
  }) {
    if (requireExternalId) {
      return _optionalStringMatches(expected, actual);
    }

    final String? normalizedExpected = _normalizeNullableString(expected);
    final String? normalizedActual = _normalizeNullableString(actual);
    if (normalizedExpected == null || normalizedActual == null) return true;
    return normalizedExpected == normalizedActual;
  }

  String? _normalizeNullableString(String? value) {
    final String? trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _amountMatches(String expected, String actual) {
    final double? expectedNumber = double.tryParse(expected.trim());
    final double? actualNumber = double.tryParse(actual.trim());
    if (expectedNumber != null && actualNumber != null) {
      return (expectedNumber - actualNumber).abs() < 0.000001;
    }
    return expected.trim() == actual.trim();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _apiDate(DateTime date) {
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Compares two TransactionStore objects to determine if they represent the same transaction
  /// Matches by comparing key fields: date, amount, description, source/destination names
  bool _transactionsMatch(TransactionStore store1, TransactionStore store2) {
    // Compare number of transaction splits
    if (store1.transactions.length != store2.transactions.length) {
      return false;
    }

    // Compare group title (handle null as empty string for comparison)
    final String? title1 = store1.groupTitle;
    final String? title2 = store2.groupTitle;
    if ((title1?.trim().isEmpty ?? true) != (title2?.trim().isEmpty ?? true) ||
        (title1?.trim().isNotEmpty ?? false) &&
            title1?.trim() != title2?.trim()) {
      return false;
    }

    // Compare each transaction split
    for (int i = 0; i < store1.transactions.length; i++) {
      final TransactionSplitStore split1 = store1.transactions[i];
      final TransactionSplitStore split2 = store2.transactions[i];

      // Compare date (normalize to same precision)
      final DateTime date1 = split1.date;
      final DateTime date2 = split2.date;
      // Compare dates ignoring time differences (only date matters)
      final DateTime normalizedDate1 = DateTime(
        date1.year,
        date1.month,
        date1.day,
      );
      final DateTime normalizedDate2 = DateTime(
        date2.year,
        date2.month,
        date2.day,
      );
      if (!normalizedDate1.isAtSameMomentAs(normalizedDate2)) {
        return false;
      }

      // Compare amount (normalize strings)
      final String amount1 = split1.amount.trim();
      final String amount2 = split2.amount.trim();
      if (amount1 != amount2) {
        return false;
      }

      // Compare description (normalize strings)
      final String desc1 = split1.description.trim();
      final String desc2 = split2.description.trim();
      if (desc1 != desc2) {
        return false;
      }

      // Compare source and destination names (handle null/empty as equivalent)
      final String? source1 = split1.sourceName?.trim();
      final String? source2 = split2.sourceName?.trim();
      final bool source1Empty = source1?.isEmpty ?? true;
      final bool source2Empty = source2?.isEmpty ?? true;
      if (source1Empty != source2Empty ||
          (!source1Empty && source1 != source2)) {
        return false;
      }

      final String? dest1 = split1.destinationName?.trim();
      final String? dest2 = split2.destinationName?.trim();
      final bool dest1Empty = dest1?.isEmpty ?? true;
      final bool dest2Empty = dest2?.isEmpty ?? true;
      if (dest1Empty != dest2Empty || (!dest1Empty && dest1 != dest2)) {
        return false;
      }
    }

    return true;
  }

  /// Fallback matching by comparing JSON directly
  bool _jsonTransactionsMatch(
    Map<String, dynamic> json1,
    Map<String, dynamic> json2,
  ) {
    // Compare transactions array
    final List<dynamic>? tx1 = json1['transactions'] as List<dynamic>?;
    final List<dynamic>? tx2 = json2['transactions'] as List<dynamic>?;
    if ((tx1?.length ?? 0) != (tx2?.length ?? 0)) {
      return false;
    }
    if (tx1 == null || tx2 == null) {
      return tx1 == tx2;
    }

    for (int i = 0; i < tx1.length; i++) {
      final Map<String, dynamic> split1 = tx1[i] as Map<String, dynamic>;
      final Map<String, dynamic> split2 = tx2[i] as Map<String, dynamic>;

      // Compare essential fields (handle both snake_case and camelCase)
      if (_normalizeString(split1['amount']) !=
          _normalizeString(split2['amount'])) {
        return false;
      }
      if (_normalizeString(split1['description']) !=
          _normalizeString(split2['description'])) {
        return false;
      }
      // Try both snake_case and camelCase field names
      final String source1 = _normalizeString(
        split1['source_name'] ?? split1['sourceName'],
      );
      final String source2 = _normalizeString(
        split2['source_name'] ?? split2['sourceName'],
      );
      if (source1 != source2) {
        return false;
      }
      final String dest1 = _normalizeString(
        split1['destination_name'] ?? split1['destinationName'],
      );
      final String dest2 = _normalizeString(
        split2['destination_name'] ?? split2['destinationName'],
      );
      if (dest1 != dest2) {
        return false;
      }
    }

    return true;
  }

  String _normalizeString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  Future<void> _updateSyncMetadata(
    String entityType, {
    DateTime? lastUploadSync,
    bool clearError = false,
    String? lastError,
    bool? syncPaused,
    int? retryCount,
    DateTime? nextRetryAt,
    bool clearNextRetryAt = false,
    bool? credentialsValidated,
    bool? credentialsInvalid,
  }) async {
    final SyncMetadata? existing = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    if (existing == null) {
      final SyncMetadata metadata = SyncMetadata()
        ..entityType = entityType
        ..lastUploadSync = lastUploadSync
        ..lastError = clearError ? null : lastError
        ..syncPaused = syncPaused ?? false
        ..retryCount = retryCount ?? 0
        ..nextRetryAt = clearNextRetryAt ? null : nextRetryAt
        ..credentialsValidated = credentialsValidated ?? false
        ..credentialsInvalid = credentialsInvalid ?? false;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });
    } else {
      if (lastUploadSync != null) existing.lastUploadSync = lastUploadSync;
      if (clearError) {
        existing.lastError = null;
      } else if (lastError != null) {
        existing.lastError = lastError;
      }
      if (syncPaused != null) existing.syncPaused = syncPaused;
      if (retryCount != null) existing.retryCount = retryCount;
      if (clearNextRetryAt) {
        existing.nextRetryAt = null;
      } else if (nextRetryAt != null) {
        existing.nextRetryAt = nextRetryAt;
      }
      if (credentialsValidated != null) {
        existing.credentialsValidated = credentialsValidated;
      }
      if (credentialsInvalid != null) {
        existing.credentialsInvalid = credentialsInvalid;
      }

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(existing);
      });
    }
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    super.dispose();
  }
}
