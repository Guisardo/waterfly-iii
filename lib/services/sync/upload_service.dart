import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/auth.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/repositories/insight_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/retry_manager.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/settings.dart';

final Logger log = Logger("Upload");

class UploadService extends ChangeNotifier {
  final Isar isar;
  final FireflyService fireflyService;
  final ConnectivityService connectivityService;
  final RetryManager retryManager;
  final ConflictResolver conflictResolver;
  final SyncNotifications notifications;
  final SettingsProvider? settingsProvider;

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  UploadService({
    required this.isar,
    required this.fireflyService,
    required this.connectivityService,
    required this.notifications,
    this.settingsProvider,
  })  : retryManager = RetryManager(isar),
        conflictResolver = ConflictResolver(isar) {
    // Set settings provider for notifications localization
    notifications.setSettingsProvider(settingsProvider);
  }

  Future<void> uploadPendingChanges({bool forceRetry = false}) async {
    if (_isUploading) {
      log.config("Upload already in progress, skipping");
      return;
    }

    _isUploading = true;
    notifyListeners();

    try {
      // Check if upload is paused
      if (!forceRetry && await retryManager.isPaused('upload')) {
        log.config("Upload is paused");
        _isUploading = false;
        notifyListeners();
        return;
      }

      // Check connectivity
      if (!connectivityService.isOnline) {
        log.config("Device is offline, skipping upload");
        _isUploading = false;
        notifyListeners();
        return;
      }

      // Check mobile data setting
      if (connectivityService.isMobile &&
          (settingsProvider?.syncUseMobileData ?? false) == false) {
        log.config("Mobile data upload disabled, skipping");
        _isUploading = false;
        notifyListeners();
        return;
      }

      // Get pending changes
      final List<PendingChanges> pending = await isar.pendingChanges
          .filter()
          .syncedEqualTo(false)
          .findAll()
          .then((list) => list.toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt)));

      if (pending.isEmpty) {
        log.config("No pending changes to upload");
        _isUploading = false;
        notifyListeners();
        return;
      }

      await notifications.showSyncStarted();

      int successCount = 0;
      int failureCount = 0;

      for (final PendingChanges change in pending) {
        try {
          final bool success = await _processChange(change);
          if (success) {
            successCount++;
          } else {
            failureCount++;
            // If max retries exceeded, stop processing
            if (change.retryCount >= 3) {
              log.warning(
                "Max retries exceeded for ${change.entityType} ${change.entityId}",
              );
            }
          }
        } catch (e, stackTrace) {
          log.severe(
            "Error processing change ${change.id}",
            e,
            stackTrace,
          );
          failureCount++;

          // Handle errors
          if (_isNetworkError(e) || _isTimeoutError(e) || _isServerError(e)) {
            // Pause entire upload sync
            await retryManager.pauseWithBackoff('upload', e.toString());
            await notifications.showSyncPaused(e.toString());
            break;
          } else {
            // Increment retry count for this item
            await _incrementRetryCount(change.id, e.toString());
          }
        }
      }

      // Mark insights as stale after successful uploads
      if (successCount > 0) {
        final InsightRepository insightRepo = InsightRepository(isar);
        await insightRepo.markStale(null, null);
      }

      await retryManager.resetRetry('upload');
      await notifications.showSyncCompleted();

      log.config("Upload completed: $successCount success, $failureCount failures");

      _isUploading = false;
      notifyListeners();
    } catch (e, stackTrace) {
      log.severe("Upload failed", e, stackTrace);

      if (_isNetworkError(e) || _isTimeoutError(e) || _isServerError(e)) {
        await retryManager.pauseWithBackoff('upload', e.toString());
        await notifications.showSyncPaused(e.toString());
      }

      _isUploading = false;
      notifyListeners();
    }
  }

  Future<bool> _processChange(PendingChanges change) async {
    final FireflyIii api = fireflyService.api;

    try {
      switch (change.operation) {
        case 'CREATE':
          return await _processCreate(change, api);
        case 'UPDATE':
          return await _processUpdate(change, api);
        case 'DELETE':
          return await _processDelete(change, api);
        default:
          log.warning("Unknown operation: ${change.operation}");
          return false;
      }
    } catch (e) {
      log.warning("Error processing ${change.operation} for ${change.entityType}", e);
      rethrow;
    }
  }

  Future<bool> _processCreate(PendingChanges change, FireflyIii api) async {
    final Map<String, dynamic> data = jsonDecode(change.data!) as Map<String, dynamic>;

    try {
      Response? response;

      switch (change.entityType) {
        case 'transactions':
          final TransactionStore store = TransactionStore.fromJson(data);
          response = await api.v1TransactionsPost(body: store);
          if (response.isSuccessful && response.body != null) {
            final TransactionRead created = response.body!.data;
            final TransactionRepository repo = TransactionRepository(isar);
            await repo.upsertFromSync(created);
          }
          break;
        case 'accounts':
          final AccountStore store = AccountStore.fromJson(data);
          response = await api.v1AccountsPost(body: store);
          break;
        case 'categories':
          final CategoryStore store = CategoryStore.fromJson(data);
          response = await api.v1CategoriesPost(body: store);
          break;
        case 'tags':
          final TagModelStore store = TagModelStore.fromJson(data);
          response = await api.v1TagsPost(body: store);
          break;
        case 'bills':
          final BillStore store = BillStore.fromJson(data);
          response = await api.v1BillsPost(body: store);
          break;
        case 'budgets':
          final BudgetStore store = BudgetStore.fromJson(data);
          response = await api.v1BudgetsPost(body: store);
          break;
        case 'budget_limits':
          // Budget limits require budgetId - extract from data
          final Map<String, dynamic> dataMap = data;
          final String? budgetId = dataMap['budget_id'] as String?;
          if (budgetId == null) {
            log.warning("Budget limit missing budget_id");
            return false;
          }
          final BudgetLimitStore store = BudgetLimitStore.fromJson(data);
          response = await api.v1BudgetsIdLimitsPost(
            id: budgetId,
            body: store,
          );
          break;
        default:
          log.warning("Unsupported entity type for CREATE: ${change.entityType}");
          return false;
      }

      if (response.isSuccessful) {
        await _markChangeAsSynced(change.id);
        return true;
      } else {
        throw Exception("Failed to create ${change.entityType}: ${response.error}");
      }
    } catch (e) {
      if (_isConflictError(e)) {
        // Handle conflict
        await conflictResolver.logConflict(
          entityType: change.entityType,
          entityId: change.entityId ?? 'unknown',
          conflictType: ConflictType.upload,
          serverUpdatedAt: DateTime.now().toUtc(),
          resolution: ConflictResolution.serverWins,
        );
        await _markChangeAsSynced(change.id);
        return true;
      }
      rethrow;
    }
  }

  Future<bool> _processUpdate(PendingChanges change, FireflyIii api) async {
    if (change.entityId == null) {
      log.warning("UPDATE operation requires entityId");
      return false;
    }

    final Map<String, dynamic> data = jsonDecode(change.data!) as Map<String, dynamic>;

    try {
      Response? response;

      switch (change.entityType) {
        case 'transactions':
          final TransactionUpdate update = TransactionUpdate.fromJson(data);
          response = await api.v1TransactionsIdPut(
            id: change.entityId!,
            body: update,
          );
          if (response.isSuccessful && response.body != null) {
            final TransactionRead updated = response.body!.data;
            final TransactionRepository repo = TransactionRepository(isar);
            await repo.upsertFromSync(updated);
          }
          break;
        case 'accounts':
          final AccountUpdate update = AccountUpdate.fromJson(data);
          response = await api.v1AccountsIdPut(
            id: change.entityId!,
            body: update,
          );
          break;
        case 'categories':
          final CategoryUpdate update = CategoryUpdate.fromJson(data);
          response = await api.v1CategoriesIdPut(
            id: change.entityId!,
            body: update,
          );
          break;
        case 'tags':
          final TagModelUpdate update = TagModelUpdate.fromJson(data);
          response = await api.v1TagsTagPut(
            tag: change.entityId!,
            body: update,
          );
          break;
        case 'bills':
          final BillUpdate update = BillUpdate.fromJson(data);
          response = await api.v1BillsIdPut(
            id: change.entityId!,
            body: update,
          );
          break;
        case 'budgets':
          final BudgetUpdate update = BudgetUpdate.fromJson(data);
          response = await api.v1BudgetsIdPut(
            id: change.entityId!,
            body: update,
          );
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
            limitId: change.entityId!,
            body: update,
          );
          break;
        default:
          log.warning("Unsupported entity type for UPDATE: ${change.entityType}");
          return false;
      }

      if (response.isSuccessful) {
        await _markChangeAsSynced(change.id);
        return true;
      } else if (response.statusCode == 404) {
        // Entity deleted on server
        await _markChangeAsSynced(change.id);
        return true;
      } else {
        throw Exception("Failed to update ${change.entityType}: ${response.error}");
      }
    } catch (e) {
      if (_isConflictError(e)) {
        await conflictResolver.logConflict(
          entityType: change.entityType,
          entityId: change.entityId!,
          conflictType: ConflictType.upload,
          serverUpdatedAt: DateTime.now().toUtc(),
          resolution: ConflictResolution.serverWins,
        );
        await _markChangeAsSynced(change.id);
        return true;
      }
      rethrow;
    }
  }

  Future<bool> _processDelete(PendingChanges change, FireflyIii api) async {
    if (change.entityId == null) {
      log.warning("DELETE operation requires entityId");
      return false;
    }

    try {
      Response? response;

      switch (change.entityType) {
        case 'transactions':
          response = await api.v1TransactionsIdDelete(id: change.entityId!);
          break;
        case 'accounts':
          response = await api.v1AccountsIdDelete(id: change.entityId!);
          break;
        case 'categories':
          response = await api.v1CategoriesIdDelete(id: change.entityId!);
          break;
        case 'tags':
          // Tags use tag name, not ID
          response = await api.v1TagsTagDelete(tag: change.entityId!);
          break;
        case 'bills':
          response = await api.v1BillsIdDelete(id: change.entityId!);
          break;
        case 'budgets':
          response = await api.v1BudgetsIdDelete(id: change.entityId!);
          break;
        default:
          log.warning("Unsupported entity type for DELETE: ${change.entityType}");
          return false;
      }

      if (response.isSuccessful || response.statusCode == 404) {
        // 404 means already deleted, which is fine
        await _markChangeAsSynced(change.id);
        return true;
      } else {
        throw Exception("Failed to delete ${change.entityType}: ${response.error}");
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _markChangeAsSynced(int changeId) async {
    final PendingChanges? change = await isar.pendingChanges
        .filter()
        .idEqualTo(changeId)
        .findFirst();

    if (change != null) {
      change
        ..synced = true
        ..retryCount = 0
        ..lastError = null;

      await isar.writeTxn(() async {
        await isar.pendingChanges.put(change);
      });
    }
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

  bool _isNetworkError(dynamic error) {
    return error.toString().contains('SocketException') ||
        error.toString().contains('NetworkException') ||
        error.toString().contains('Failed host lookup');
  }

  bool _isTimeoutError(dynamic error) {
    return error.toString().contains('TimeoutException') ||
        error.toString().contains('timeout');
  }

  bool _isServerError(dynamic error) {
    if (error is Response) {
      return error.statusCode >= 500 && error.statusCode < 600;
    }
    return false;
  }

  bool _isConflictError(dynamic error) {
    if (error is Response) {
      return error.statusCode == 409;
    }
    return error.toString().contains('409') || error.toString().contains('Conflict');
  }

  void dispose() {
    super.dispose();
  }
}

