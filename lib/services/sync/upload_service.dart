import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/auth.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/repositories/insight_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/retry_manager.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/settings.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';

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
  }) : retryManager = RetryManager(isar),
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
          .then(
            (List<PendingChanges> list) =>
                list.toList()..sort(
                  (PendingChanges a, PendingChanges b) =>
                      a.createdAt.compareTo(b.createdAt),
                ),
          );

      if (pending.isEmpty) {
        log.config("No pending changes to upload");
        _isUploading = false;
        notifyListeners();
        return;
      }

      try {
        await notifications.showSyncStarted();
      } catch (e, stackTrace) {
        log.warning("Failed to show sync started notification", e, stackTrace);
        // Continue anyway - notification failure shouldn't block upload
      }

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
          log.severe("Error processing change ${change.id}", e, stackTrace);
          failureCount++;

          // Check for conflict errors first
          if (_isConflictError(e)) {
            // Handle conflict - mark change as synced
            await conflictResolver.logConflict(
              entityType: change.entityType,
              entityId: change.entityId ?? 'unknown',
              conflictType: ConflictType.upload,
              serverUpdatedAt: DateTime.now().toUtc(),
              resolution: ConflictResolution.serverWins,
            );
            await _markChangeAsSynced(change.id);
            successCount++;
            failureCount--; // Don't count conflicts as failures
            continue;
          }

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

      // Update lastUploadSync metadata after successful upload
      // Update if we had any successes, or if we had no failures (all succeeded or nothing to do)
      if (successCount > 0) {
        await _updateSyncMetadata(
          'upload',
          lastUploadSync: DateTime.now().toUtc(),
        );
      }

      await notifications.showSyncCompleted();

      log.config(
        "Upload completed: $successCount success, $failureCount failures",
      );

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
      log.warning(
        "Error processing ${change.operation} for ${change.entityType}",
        e,
      );
      rethrow;
    }
  }

  Future<bool> _processCreate(PendingChanges change, FireflyIii api) async {
    final Map<String, dynamic> data =
        jsonDecode(change.data!) as Map<String, dynamic>;

    try {
      Response<dynamic>? response;

      try {
        switch (change.entityType) {
          case 'transactions':
            TransactionStore store;
            try {
              store = TransactionStore.fromJson(data);
            } catch (e, stackTrace) {
              log.warning(
                "Failed to parse TransactionStore from data",
                e,
                stackTrace,
              );
              rethrow;
            }

            try {
              response = await api.v1TransactionsPost(body: store);
            } catch (e) {
              // If Chopper throws during the call, check if it's a conflict
              // before rethrowing
              if (_isConflictError(e)) {
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
              // Also check if the error has a Response with 409 status
              try {
                final dynamic errorObj = e;
                final dynamic errorResponse = (errorObj as dynamic).response;
                if (errorResponse is Response &&
                    errorResponse.statusCode == 409) {
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
              } catch (_) {
                // Response property might not exist
              }
              rethrow;
            }

            // Check for conflict first (before checking isSuccessful)
            // Chopper returns Response with isSuccessful=false for non-2xx status codes
            // But Chopper might also throw an exception for 409 during deserialization
            if (response.statusCode == 409) {
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
            if (response.isSuccessful && response.body != null) {
              try {
                final TransactionRead created = response.body!.data;
                final TransactionRepository repo = TransactionRepository(isar);
                await repo.upsertFromSync(created);
                await _markChangeAsSynced(change.id);
                return true;
              } catch (e) {
                // If deserialization fails but response has 409, treat as conflict
                if (response.statusCode == 409) {
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
            log.warning(
              "Unsupported entity type for CREATE: ${change.entityType}",
            );
            return false;
        }
      } catch (apiError) {
        // Check if response was set before exception (Chopper might set response then throw)
        if (response != null && response.statusCode == 409) {
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
        // Chopper might throw an exception for non-2xx responses or deserialization failures
        // Check if it's a conflict error first
        if (_isConflictError(apiError)) {
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
        // Also check if the error contains a Response with 409 status
        try {
          final dynamic errorObj = apiError;
          // Try to access response property
          final dynamic errorResponse = (errorObj as dynamic).response;
          if (errorResponse is Response && errorResponse.statusCode == 409) {
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
        } catch (_) {
          // Response property might not exist
        }
        // Re-throw if not a conflict - this will be caught by outer catch
        throw apiError;
      }

      // Check for conflict first (before checking isSuccessful)
      // Chopper returns Response with isSuccessful=false for non-2xx status codes
      // Check statusCode directly for 409 conflicts
      if (response.statusCode == 409) {
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

      if (response.isSuccessful) {
        await _markChangeAsSynced(change.id);
        return true;
      } else {
        // Check for conflict before throwing (fallback check using _isConflictError)
        if (_isConflictError(response)) {
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
        throw Exception(
          "Failed to create ${change.entityType}: ${response.error}",
        );
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

    final Map<String, dynamic> data =
        jsonDecode(change.data!) as Map<String, dynamic>;

    try {
      Response<dynamic>? response;

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
          response = await api.v1BillsIdPut(id: change.entityId!, body: update);
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
      } else {
        // Check for conflict before throwing
        if (_isConflictError(response)) {
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
        throw Exception(
          "Failed to update ${change.entityType}: ${response.error}",
        );
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
      Response<dynamic>? response;

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
          log.warning(
            "Unsupported entity type for DELETE: ${change.entityType}",
          );
          return false;
      }

      if (response.isSuccessful || response.statusCode == 404) {
        // 404 means already deleted, which is fine
        await _markChangeAsSynced(change.id);
        return true;
      } else {
        throw Exception(
          "Failed to delete ${change.entityType}: ${response.error}",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _markChangeAsSynced(int changeId) async {
    final PendingChanges? change =
        await isar.pendingChanges.filter().idEqualTo(changeId).findFirst();

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
    final PendingChanges? change =
        await isar.pendingChanges.filter().idEqualTo(changeId).findFirst();

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

  /// Detects network-related errors that should trigger retry with backoff
  bool _isNetworkError(dynamic error) {
    // Check for actual exception types first
    if (error is Exception) {
      final String errorStr = error.toString().toLowerCase();
      return errorStr.contains('socketexception') ||
          errorStr.contains('networkexception') ||
          errorStr.contains('failed host lookup') ||
          errorStr.contains('connection refused') ||
          errorStr.contains('connection reset') ||
          errorStr.contains('connection timed out') ||
          errorStr.contains('no internet connection') ||
          errorStr.contains('network is unreachable');
    }
    // Fallback to string matching
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('socketexception') ||
        errorStr.contains('networkexception') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('connection reset');
  }

  /// Detects timeout errors that should trigger retry with backoff
  bool _isTimeoutError(dynamic error) {
    if (error is Response) {
      // HTTP 408 Request Timeout
      if (error.statusCode == 408) {
        return true;
      }
    }
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('timeoutexception') ||
        errorStr.contains('timeout') ||
        errorStr.contains('timed out') ||
        errorStr.contains('deadline exceeded');
  }

  /// Detects server errors (5xx) and rate limiting (429) that should trigger retry with backoff
  bool _isServerError(dynamic error) {
    if (error is Response) {
      // 5xx server errors and 429 (rate limiting)
      return (error.statusCode >= 500 && error.statusCode < 600) ||
          error.statusCode == 429;
    }
    final String errorStr = error.toString().toLowerCase();
    return errorStr.contains('500') ||
        errorStr.contains('502') ||
        errorStr.contains('503') ||
        errorStr.contains('504') ||
        errorStr.contains('429');
  }

  bool _isConflictError(dynamic error) {
    // Check if it's a Chopper Response object
    if (error is Response) {
      // Chopper Response has statusCode accessible directly
      return error.statusCode == 409;
    }

    // Check if the error has a response with status code
    // Chopper exceptions might have a 'base' or 'response' property that contains the Response
    try {
      if (error is Exception) {
        final dynamic errorObj = error;

        // Try to access 'base' property (Chopper ResponseException pattern)
        try {
          final dynamic base = (errorObj as dynamic).base;
          if (base is Response && base.statusCode == 409) {
            return true;
          }
        } catch (_) {
          // 'base' property might not exist or not be accessible
        }

        // Try to access 'response' property (alternative Chopper exception pattern)
        try {
          final dynamic response = (errorObj as dynamic).response;
          if (response is Response && response.statusCode == 409) {
            return true;
          }
        } catch (_) {
          // 'response' property might not exist or not be accessible
        }

        // Try to access 'originalResponse' property (Chopper might store it here)
        try {
          final dynamic originalResponse =
              (errorObj as dynamic).originalResponse;
          if (originalResponse is Response &&
              originalResponse.statusCode == 409) {
            return true;
          }
        } catch (_) {
          // 'originalResponse' property might not exist
        }

        // Check error string for status code patterns
        final String errorStr = errorObj.toString();

        // Look for status code in various formats: "409", "statusCode: 409", "HTTP 409", etc.
        final RegExp statusCodePattern = RegExp(r'\b409\b');
        if (statusCodePattern.hasMatch(errorStr)) {
          return true;
        }
        if (errorStr.contains('Conflict') || errorStr.contains('conflict')) {
          return true;
        }
      }
    } catch (_) {
      // Ignore reflection/access errors
    }

    // Final fallback: check if it's an Exception with conflict information
    final String errorStr = error.toString();
    return errorStr.contains('409') ||
        errorStr.contains('Conflict') ||
        errorStr.contains('conflict');
  }

  Future<void> _updateSyncMetadata(
    String entityType, {
    DateTime? lastUploadSync,
  }) async {
    final SyncMetadata? existing =
        await isar.syncMetadatas
            .filter()
            .entityTypeEqualTo(entityType)
            .findFirst();

    if (existing == null) {
      final SyncMetadata metadata =
          SyncMetadata()
            ..entityType = entityType
            ..lastUploadSync = lastUploadSync;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });
    } else {
      if (lastUploadSync != null) existing.lastUploadSync = lastUploadSync;

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
