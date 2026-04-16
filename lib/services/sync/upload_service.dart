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
            (List<PendingChanges> list) => list.toList()
              ..sort(
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
          if (SyncErrorClassifier.isConflictError(e)) {
            // Conflict: keep the pending change for manual resolution, increment retry
            await conflictResolver.logConflict(
              entityType: change.entityType,
              entityId: change.entityId ?? 'unknown',
              conflictType: ConflictType.upload,
              localUpdatedAt: null,
              serverUpdatedAt: null,
              resolution: ConflictResolution.localCancelled,
            );
            change
              ..retryCount = change.retryCount + 1
              ..lastError = 'Conflict (409): server version is different';
            await isar.writeTxn(() async {
              await isar.pendingChanges.put(change);
            });
            continue;
          }

          // Handle errors
          if (SyncErrorClassifier.isNetworkError(e) ||
              SyncErrorClassifier.isTimeoutError(e) ||
              SyncErrorClassifier.isServerError(e)) {
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

      if (SyncErrorClassifier.isNetworkError(e) ||
          SyncErrorClassifier.isTimeoutError(e) ||
          SyncErrorClassifier.isServerError(e)) {
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
              if (SyncErrorClassifier.isConflictError(e)) {
                await conflictResolver.logConflict(
                  entityType: change.entityType,
                  entityId: change.entityId ?? 'unknown',
                  conflictType: ConflictType.upload,
                  localUpdatedAt: null,
                  serverUpdatedAt: null,
                  resolution: ConflictResolution.localCancelled,
                );
                change
                  ..retryCount = change.retryCount + 1
                  ..lastError = 'Conflict (409): server version is different';
                await isar.writeTxn(() async {
                  await isar.pendingChanges.put(change);
                });
                return false;
              }
              rethrow;
            }

            if (response.statusCode == 409) {
              await conflictResolver.logConflict(
                entityType: change.entityType,
                entityId: change.entityId ?? 'unknown',
                conflictType: ConflictType.upload,
                localUpdatedAt: null,
                serverUpdatedAt: null,
                resolution: ConflictResolution.localCancelled,
              );
              change
                ..retryCount = change.retryCount + 1
                ..lastError = 'Conflict (409): server version is different';
              await isar.writeTxn(() async {
                await isar.pendingChanges.put(change);
              });
              return false;
            }
            if (response.isSuccessful && response.body != null) {
              try {
                final TransactionRead created = response.body!.data;
                final TransactionRepository repo = TransactionRepository(isar);

                // Find and delete the pending transaction using localPendingId (fast path)
                // or fall back to fuzzy matching for legacy pending changes.
                try {
                  Transactions? matchingPending;

                  if (change.localPendingId != null) {
                    matchingPending = await isar.transactions
                        .filter()
                        .transactionIdEqualTo(change.localPendingId!)
                        .findFirst();
                  } else {
                    final List<Transactions> allPending = await isar
                        .transactions
                        .filter()
                        .transactionIdStartsWith('pending-')
                        .findAll();

                    for (final Transactions pendingTx in allPending) {
                      Map<String, dynamic>? pendingData;
                      try {
                        pendingData =
                            jsonDecode(pendingTx.data) as Map<String, dynamic>;
                        final TransactionStore pendingStore =
                            TransactionStore.fromJson(pendingData);
                        if (_transactionsMatch(store, pendingStore)) {
                          matchingPending = pendingTx;
                          break;
                        }
                      } catch (e) {
                        if (pendingData != null) {
                          try {
                            final Map<String, dynamic> storeJson = store
                                .toJson();
                            if (_jsonTransactionsMatch(
                              storeJson,
                              pendingData,
                            )) {
                              matchingPending = pendingTx;
                              break;
                            }
                          } catch (_) {
                            continue;
                          }
                        } else {
                          continue;
                        }
                      }
                    }
                  }

                  if (matchingPending != null) {
                    await isar.writeTxn(() async {
                      await isar.transactions.delete(matchingPending!.id);
                    });
                  }
                } catch (e, stackTrace) {
                  log.warning(
                    "Error finding/deleting matching pending transaction",
                    e,
                    stackTrace,
                  );
                  // Continue anyway - upsert will still work
                }

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
                    localUpdatedAt: null,
                    serverUpdatedAt: null,
                    resolution: ConflictResolution.localCancelled,
                  );
                  change
                    ..retryCount = change.retryCount + 1
                    ..lastError = 'Conflict (409): server version is different';
                  await isar.writeTxn(() async {
                    await isar.pendingChanges.put(change);
                  });
                  return false;
                }
                rethrow;
              }
            }
            break;
          case 'accounts':
            final AccountStore store = AccountStore.fromJson(data);
            response = await api.v1AccountsPost(body: store);
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
            if (response.isSuccessful && response.body != null) {
              try {
                final CategoryRead created = response.body!.data;
                final CategoryRepository repo = CategoryRepository(isar);

                // Find and delete the pending category using localPendingId (fast path)
                // or fall back to name-matching for legacy pending changes.
                try {
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
                        final CategoryRead pendingRead = CategoryRead.fromJson(
                          pendingData,
                        );
                        if (pendingRead.attributes.name == store.name &&
                            (pendingRead.attributes.notes ?? '') ==
                                (store.notes ?? '')) {
                          matchingPending = pendingCat;
                          break;
                        }
                      } catch (e) {
                        continue;
                      }
                    }
                  }

                  if (matchingPending != null) {
                    await isar.writeTxn(() async {
                      await isar.categories.delete(matchingPending!.id);
                    });
                  }
                } catch (e, stackTrace) {
                  log.warning(
                    "Error finding/deleting matching pending category",
                    e,
                    stackTrace,
                  );
                  // Continue anyway - upsert will still work
                }

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
                    localUpdatedAt: null,
                    serverUpdatedAt: null,
                    resolution: ConflictResolution.localCancelled,
                  );
                  change
                    ..retryCount = change.retryCount + 1
                    ..lastError = 'Conflict (409): server version is different';
                  await isar.writeTxn(() async {
                    await isar.pendingChanges.put(change);
                  });
                  return false;
                }
                rethrow;
              }
            }
            break;
          case 'tags':
            final TagModelStore store = TagModelStore.fromJson(data);
            response = await api.v1TagsPost(body: store);
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
            if (response.isSuccessful && response.body != null) {
              final BudgetRepository budgetRepo = BudgetRepository(isar);
              await budgetRepo.upsertFromSync(response.body!.data);
              await _markChangeAsSynced(change.id);
              return true;
            }
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
      } catch (apiError) {
        // Check if response was set before exception (Chopper might set response then throw)
        final bool isConflict409 =
            (response != null && response.statusCode == 409) ||
            SyncErrorClassifier.isConflictError(apiError);
        if (isConflict409) {
          await conflictResolver.logConflict(
            entityType: change.entityType,
            entityId: change.entityId ?? 'unknown',
            conflictType: ConflictType.upload,
            localUpdatedAt: null,
            serverUpdatedAt: null,
            resolution: ConflictResolution.localCancelled,
          );
          change
            ..retryCount = change.retryCount + 1
            ..lastError = 'Conflict (409): server version is different';
          await isar.writeTxn(() async {
            await isar.pendingChanges.put(change);
          });
          return false;
        }
        // Re-throw if not a conflict - this will be caught by outer catch
        rethrow;
      }

      // Check statusCode directly for 409 conflicts
      if (response.statusCode == 409) {
        await conflictResolver.logConflict(
          entityType: change.entityType,
          entityId: change.entityId ?? 'unknown',
          conflictType: ConflictType.upload,
          localUpdatedAt: null,
          serverUpdatedAt: null,
          resolution: ConflictResolution.localCancelled,
        );
        change
          ..retryCount = change.retryCount + 1
          ..lastError = 'Conflict (409): server version is different';
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(change);
        });
        return false;
      }

      if (response.isSuccessful) {
        await _markChangeAsSynced(change.id);
        return true;
      } else {
        if (SyncErrorClassifier.isConflictError(response)) {
          await conflictResolver.logConflict(
            entityType: change.entityType,
            entityId: change.entityId ?? 'unknown',
            conflictType: ConflictType.upload,
            localUpdatedAt: null,
            serverUpdatedAt: null,
            resolution: ConflictResolution.localCancelled,
          );
          change
            ..retryCount = change.retryCount + 1
            ..lastError = 'Conflict (409): server version is different';
          await isar.writeTxn(() async {
            await isar.pendingChanges.put(change);
          });
          return false;
        }
        throw Exception(
          "Failed to create ${change.entityType}: ${response.error}",
        );
      }
    } catch (e) {
      if (SyncErrorClassifier.isConflictError(e)) {
        await conflictResolver.logConflict(
          entityType: change.entityType,
          entityId: change.entityId ?? 'unknown',
          conflictType: ConflictType.upload,
          localUpdatedAt: null,
          serverUpdatedAt: null,
          resolution: ConflictResolution.localCancelled,
        );
        change
          ..retryCount = change.retryCount + 1
          ..lastError = 'Conflict (409): server version is different';
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(change);
        });
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
        await conflictResolver.logConflict(
          entityType: change.entityType,
          entityId: entityId,
          conflictType: ConflictType.upload,
          localUpdatedAt: null,
          serverUpdatedAt: null,
          resolution: ConflictResolution.localCancelled,
        );
        change
          ..retryCount = change.retryCount + 1
          ..lastError = 'Conflict (409): server version is different';
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(change);
        });
        return false;
      } else {
        throw Exception(
          "Failed to update ${change.entityType}: ${response.error}",
        );
      }
    } catch (e) {
      if (SyncErrorClassifier.isConflictError(e)) {
        await conflictResolver.logConflict(
          entityType: change.entityType,
          entityId: entityId,
          conflictType: ConflictType.upload,
          localUpdatedAt: null,
          serverUpdatedAt: null,
          resolution: ConflictResolution.localCancelled,
        );
        change
          ..retryCount = change.retryCount + 1
          ..lastError = 'Conflict (409): server version is different';
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(change);
        });
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
  }) async {
    final SyncMetadata? existing = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    if (existing == null) {
      final SyncMetadata metadata = SyncMetadata()
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
