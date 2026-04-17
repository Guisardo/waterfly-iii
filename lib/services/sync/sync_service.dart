import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:chopper/chopper.dart';
import 'package:intl/intl.dart' as intl;
import 'package:logging/logging.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/auth.dart' show FireflyService;
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/data/repositories/bill_repository.dart';
import 'package:waterflyiii/data/repositories/budget_repository.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/data/repositories/currency_repository.dart';
import 'package:waterflyiii/data/repositories/insight_repository.dart';
import 'package:waterflyiii/data/repositories/piggy_bank_repository.dart';
import 'package:waterflyiii/data/repositories/tag_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart'
    show ConflictResolver, ConflictType, ConflictResolution;
import 'package:waterflyiii/services/sync/retry_manager.dart';
import 'package:waterflyiii/services/sync/sync_error_classifier.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/settings.dart';
import 'package:waterflyiii/timezonehandler.dart';
import 'package:waterflyiii/extensions.dart';

final Logger log = Logger("Sync");

/// Progress information for sync operations.
class SyncProgress {
  /// The type of entity being synced (e.g., 'transactions', 'accounts').
  final String entityType;

  /// Current number of items processed.
  final int current;

  /// Total number of items to process.
  final int total;

  /// Optional status message.
  final String? message;

  SyncProgress({
    required this.entityType,
    required this.current,
    required this.total,
    this.message,
  });
}

/// Service for downloading and synchronizing data from Firefly III API.
///
/// Handles background synchronization with exponential backoff retry logic,
/// conflict resolution, and offline support. Automatically pauses sync on
/// network errors, timeouts, or server errors, and resumes after backoff period.
///
/// Sync operations are idempotent and can be safely retried.
class SyncService extends ChangeNotifier {
  final Isar isar;
  final FireflyService fireflyService;
  final ConnectivityService connectivityService;
  final RetryManager retryManager;
  final ConflictResolver conflictResolver;
  final SyncNotifications notifications;
  final SettingsProvider? settingsProvider;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  StreamController<SyncProgress>? _progressController;
  Stream<SyncProgress>? get progressStream => _progressController?.stream;

  SyncService({
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

  Future<bool> validateCredentials() async {
    try {
      if (!fireflyService.signedIn) {
        await _updateSyncMetadata(
          'auth',
          credentialsValidated: false,
          credentialsInvalid: true,
        );
        return false;
      }

      // Credentials are considered valid when the user is signed in.
      // Token validity is confirmed implicitly during entity sync.
      // Calling /v1/about here is unreliable — some Firefly III instances
      // return 401 on this endpoint even with valid tokens, while all other
      // endpoints work correctly.
      await _updateSyncMetadata(
        'auth',
        credentialsValidated: true,
        credentialsInvalid: false,
      );

      return true;
    } catch (e) {
      log.warning("Credential check failed", e);
      return false;
    }
  }

  Future<void> sync({
    bool forceFullSync = false,
    String? entityType,
    bool forceRetry = false,
  }) async {
    if (_isSyncing) {
      log.config("Sync already in progress, skipping");
      return;
    }

    _isSyncing = true;
    _progressController = StreamController<SyncProgress>.broadcast();
    _notifyListenersIfNotDisposed();

    try {
      // Check connectivity first - if online, reset pause state
      if (!connectivityService.isOnline) {
        log.config("Device is offline, skipping sync");
        _isSyncing = false;
        _notifyListenersIfNotDisposed();
        return;
      }

      // Check if sync is paused
      final String syncEntityType = entityType ?? 'download';
      final bool isPaused = await retryManager.isPaused(syncEntityType);

      // If forceRetry is true, reset pause state to allow sync to proceed
      // Don't clear errors here - they will be cleared after successful sync
      // This allows manual sync to bypass pause state while still recording new errors
      if (forceRetry) {
        log.config(
          "Force retry requested - resetting pause state for $syncEntityType",
        );
        await retryManager.resetRetry(syncEntityType);
        // Also clear stale credential flags so sync is not blocked by a
        // previous auth failure. forceRetry means the user explicitly asked
        // to retry, so we should re-validate credentials from scratch.
        await _updateSyncMetadata(
          'auth',
          credentialsValidated: false,
          credentialsInvalid: false,
        );
      } else if (isPaused && connectivityService.isOnline) {
        // If network is online and sync is paused, reset pause state to allow retry
        // This handles the case where network reconnected but pause state wasn't reset
        log.config(
          "Network is online but sync is paused - resetting pause state for $syncEntityType",
        );
        await retryManager.resetRetry(syncEntityType);
        // Also clear errors from all entity types to prevent stale error messages in UI
        // This ensures that when network reconnects, all entity-level errors are cleared
        final List<String> entityTypesToClear = entityType != null
            ? <String>[entityType]
            : <String>[
                'transactions',
                'accounts',
                'categories',
                'tags',
                'bills',
                'budgets',
                'currencies',
                'piggy_banks',
              ];
        for (final String type in entityTypesToClear) {
          await _updateSyncMetadata(type, clearError: true);
        }
      } else if (isPaused) {
        log.config("Sync is paused for $syncEntityType");
        _isSyncing = false;
        _notifyListenersIfNotDisposed();
        return;
      }

      // Check mobile data setting
      if (connectivityService.isMobile &&
          (settingsProvider?.syncUseMobileData ?? false) == false) {
        log.config("Mobile data sync disabled, skipping");
        _isSyncing = false;
        _notifyListenersIfNotDisposed();
        return;
      }

      // Validate credentials
      SyncMetadata? authMetadata = await retryManager.getMetadata('auth');
      if (authMetadata == null || !authMetadata.credentialsValidated) {
        log.config("Validating credentials...");
        final bool valid = await validateCredentials();
        if (!valid) {
          log.warning("Credentials invalid, cannot sync");
          await notifications.showCredentialError();
          _isSyncing = false;
          _notifyListenersIfNotDisposed();
          return;
        }
        // Re-read auth metadata after validation to avoid stale reference —
        // validateCredentials() updates the DB, so the old object is outdated.
        authMetadata = await retryManager.getMetadata('auth');
      }

      if (authMetadata?.credentialsInvalid ?? false) {
        log.warning("Credentials marked as invalid, cannot sync");
        _isSyncing = false;
        _notifyListenersIfNotDisposed();
        return;
      }

      await notifications.showSyncStarted();

      // Sync entities
      final List<String> entityTypes = entityType != null
          ? <String>[entityType]
          : <String>[
              'transactions',
              'accounts',
              'categories',
              'tags',
              'bills',
              'budgets',
              'currencies',
              'piggy_banks',
            ];

      for (final String type in entityTypes) {
        try {
          await _syncEntityType(type, forceFullSync: forceFullSync);
        } catch (e, stackTrace) {
          log.severe("Error syncing $type", e, stackTrace);
          // Record error in metadata even when sync fails
          await _updateSyncMetadata(
            type,
            lastError: e.toString(),
            syncPaused: false, // Don't pause individual entity types on error
          );
          // Re-throw network/timeout/server errors so they pause the entire sync
          // Other errors (like auth errors) should also bubble up
          if (SyncErrorClassifier.isNetworkError(e) ||
              SyncErrorClassifier.isTimeoutError(e) ||
              SyncErrorClassifier.isServerError(e) ||
              SyncErrorClassifier.isAuthError(e)) {
            rethrow;
          }
          // Continue with other entity types for non-critical errors
        }
      }

      // Refresh stale insights
      await _refreshStaleInsights();

      // Prefetch common date range insights for dashboard
      await _prefetchCommonInsights();

      // Update lastDownloadSync metadata after successful sync
      await _updateSyncMetadata(
        'download',
        lastDownloadSync: DateTime.now().toUtc(),
      );

      // Clear errors from all entity types after successful sync
      // This ensures stale errors are cleared only when sync actually succeeds
      final List<String> entityTypesToClear = entityType != null
          ? <String>[entityType]
          : <String>[
              'transactions',
              'accounts',
              'categories',
              'tags',
              'bills',
              'budgets',
              'currencies',
              'piggy_banks',
            ];
      for (final String type in entityTypesToClear) {
        await _updateSyncMetadata(type, clearError: true);
      }

      await retryManager.resetRetry('download');
      await notifications.showSyncCompleted();

      _isSyncing = false;
      _notifyListenersIfNotDisposed();
    } catch (e, stackTrace) {
      log.severe("Sync failed", e, stackTrace);

      // Handle errors
      if (SyncErrorClassifier.isNetworkError(e) ||
          SyncErrorClassifier.isTimeoutError(e) ||
          SyncErrorClassifier.isServerError(e)) {
        await retryManager.pauseWithBackoff(
          entityType ?? 'download',
          e.toString(),
        );
        await notifications.showSyncPaused(e.toString());
      } else if (SyncErrorClassifier.isAuthError(e)) {
        // Auth error from an entity endpoint — token is likely expired or revoked.
        // In Firefly III all endpoints share the same Bearer token auth, so a
        // 401 from any entity is a genuine credential failure.
        await _updateSyncMetadata(
          'auth',
          credentialsValidated: false,
          credentialsInvalid: true,
        );
        await notifications.showCredentialError();
      }

      _isSyncing = false;
      _notifyListenersIfNotDisposed();
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  Future<void> _syncEntityType(
    String entityType, {
    bool forceFullSync = false,
  }) async {
    log.config("Syncing $entityType");

    _progressController?.add(
      SyncProgress(
        entityType: entityType,
        current: 0,
        total: 0,
        message: "Starting sync...",
      ),
    );

    final SyncMetadata? metadata = await retryManager.getMetadata(entityType);
    final DateTime? lastSync = forceFullSync
        ? null
        : metadata?.lastDownloadSync;

    bool syncSuccess = false;
    try {
      switch (entityType) {
        case 'transactions':
          await _syncTransactions(lastSync);
          break;
        case 'accounts':
          await _syncAccounts(lastSync);
          break;
        case 'categories':
          await _syncCategories(lastSync);
          break;
        case 'tags':
          await _syncTags(lastSync);
          break;
        case 'bills':
          await _syncBills(lastSync);
          break;
        case 'budgets':
          await _syncBudgets(lastSync);
          break;
        case 'budget_limits':
          await _syncBudgetLimits(lastSync);
          break;
        case 'currencies':
          await _syncCurrencies(lastSync);
          break;
        case 'piggy_banks':
          await _syncPiggyBanks(lastSync);
          break;
      }
      syncSuccess = true;
    } catch (e, stackTrace) {
      log.severe("Error syncing $entityType", e, stackTrace);
      // Record error in metadata even when sync fails
      try {
        await _updateSyncMetadata(
          entityType,
          lastError: e.toString(),
          syncPaused: false, // Don't pause individual entity types on error
        );
      } catch (metadataError) {
        log.severe(
          "Failed to record error in metadata for $entityType",
          metadataError,
        );
      }
      // Don't update lastDownloadSync on error - let it be handled by the caller
      rethrow;
    } finally {
      // Update last sync time only on success
      if (syncSuccess) {
        try {
          final DateTime syncTime = DateTime.now().toUtc();
          await _updateSyncMetadata(
            entityType,
            lastDownloadSync: syncTime,
            clearError: true, // Clear error on success
            syncPaused: false, // Ensure not paused on success
          );
          log.config("Updated metadata for $entityType: $syncTime");
        } catch (e, stackTrace) {
          log.severe(
            "Failed to update metadata for $entityType",
            e,
            stackTrace,
          );
        }
      }
    }
  }

  Future<void> _syncTransactions(DateTime? lastSync) async {
    final TransactionRepository repo = TransactionRepository(isar);
    final FireflyIii api = fireflyService.api;

    int page = 1;
    bool hasMore = true;
    int totalSynced = 0;

    while (hasMore) {
      try {
        // Use Chopper API client so auth headers are properly preserved on
        // any server-side redirects (raw http.Client strips Authorization on redirect).
        // The Firefly III v1 API does not support order_by/order_direction, so we
        // paginate all pages and filter by updatedAt per-item for incremental sync.
        final Response<TransactionArray> response = await api.v1TransactionsGet(
          page: page,
          limit: 50,
        );

        if (!response.isSuccessful || response.body == null) {
          throw Exception(
            "Failed to fetch transactions: ${response.statusCode} ${response.error}",
          );
        }

        final List<TransactionRead> transactions = response.body!.data;

        if (transactions.isEmpty) {
          hasMore = false;
          break;
        }

        for (final TransactionRead transaction in transactions) {
          final DateTime? updatedAt = transaction.attributes.updatedAt;

          // For incremental sync, skip transactions not modified since last sync.
          // We do NOT break early here because ordering is not guaranteed by the
          // API (no order_by=updated_at support), so older items may appear anywhere.
          if (lastSync != null &&
              updatedAt != null &&
              updatedAt.isBefore(lastSync)) {
            continue;
          }

          // Check for conflicts
          final TransactionRead? local = await repo.getById(transaction.id);
          if (local != null) {
            final DateTime? localUpdatedAt = local.attributes.updatedAt;
            if (localUpdatedAt != null &&
                updatedAt != null &&
                localUpdatedAt.isAtSameMomentAs(updatedAt) &&
                jsonEncode(local.toJson()) !=
                    jsonEncode(transaction.toJson())) {
              // Concurrent modification conflict
              await conflictResolver.logConflict(
                entityType: 'transactions',
                entityId: transaction.id,
                conflictType: ConflictType.concurrent,
                localUpdatedAt: localUpdatedAt,
                serverUpdatedAt: updatedAt,
                resolution: ConflictResolution.serverWins,
              );
            }
          }

          if (await _hasPendingChange('transactions', transaction.id)) continue;
          await repo.upsertFromSync(transaction);
          totalSynced++;
        }

        _progressController?.add(
          SyncProgress(
            entityType: 'transactions',
            current: totalSynced,
            total: totalSynced + 1,
          ),
        );

        // Check if there are more pages
        final int? totalPages = response.body!.meta.pagination?.totalPages;
        if (totalPages == null || page >= totalPages) {
          hasMore = false;
        } else {
          page++;
        }
      } catch (e) {
        log.severe("Error syncing transactions page $page", e);
        rethrow;
      }
    }

    log.config("Synced $totalSynced transactions");
  }

  Future<void> _syncAccounts(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final AccountRepository repo = AccountRepository(isar);

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Response<AccountArray> response = await api.v1AccountsGet(
        page: page,
      );

      if (!response.isSuccessful || response.body == null) {
        throw Exception("Failed to fetch accounts: ${response.error}");
      }

      final List<AccountRead> accounts = response.body!.data;
      if (accounts.isEmpty) {
        hasMore = false;
        break;
      }

      for (final AccountRead account in accounts) {
        final DateTime? updatedAt = account.attributes.updatedAt;
        if (lastSync != null &&
            updatedAt != null &&
            updatedAt.isBefore(lastSync)) {
          continue;
        }

        if (await _hasPendingChange('accounts', account.id)) continue;
        await repo.upsertFromSync(account);
      }

      final int? totalPages = response.body!.meta.pagination?.totalPages;
      if (totalPages == null || page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }

  Future<void> _syncCategories(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final CategoryRepository repo = CategoryRepository(isar);

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Response<CategoryArray> response = await api.v1CategoriesGet(
        page: page,
      );

      if (!response.isSuccessful || response.body == null) {
        throw Exception("Failed to fetch categories: ${response.error}");
      }

      final List<CategoryRead> categories = response.body!.data;
      if (categories.isEmpty) {
        hasMore = false;
        break;
      }

      for (final CategoryRead category in categories) {
        final DateTime? updatedAt = category.attributes.updatedAt;
        if (lastSync != null &&
            updatedAt != null &&
            updatedAt.isBefore(lastSync)) {
          continue;
        }

        if (await _hasPendingChange('categories', category.id)) continue;
        await repo.upsertFromSync(category);
      }

      final int? totalPages = response.body!.meta.pagination?.totalPages;
      if (totalPages == null || page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }

  Future<void> _syncTags(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final TagRepository repo = TagRepository(isar);

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Response<TagArray> response = await api.v1TagsGet(page: page);

      if (!response.isSuccessful || response.body == null) {
        throw Exception("Failed to fetch tags: ${response.error}");
      }

      final List<TagRead> tags = response.body!.data;
      if (tags.isEmpty) {
        hasMore = false;
        break;
      }

      for (final TagRead tag in tags) {
        final DateTime? updatedAt = tag.attributes.updatedAt;
        if (lastSync != null &&
            updatedAt != null &&
            updatedAt.isBefore(lastSync)) {
          continue;
        }

        if (await _hasPendingChange('tags', tag.id)) continue;
        await repo.upsertFromSync(tag);
      }

      final int? totalPages = response.body!.meta.pagination?.totalPages;
      if (totalPages == null || page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }

  Future<void> _syncBills(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final BillRepository repo = BillRepository(isar);

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Response<BillArray> response = await api.v1BillsGet(page: page);

      if (!response.isSuccessful || response.body == null) {
        throw Exception("Failed to fetch bills: ${response.error}");
      }

      final List<BillRead> bills = response.body!.data;
      if (bills.isEmpty) {
        hasMore = false;
        break;
      }

      for (final BillRead bill in bills) {
        final DateTime? updatedAt = bill.attributes.updatedAt;
        if (lastSync != null &&
            updatedAt != null &&
            updatedAt.isBefore(lastSync)) {
          continue;
        }

        if (await _hasPendingChange('bills', bill.id)) continue;
        await repo.upsertFromSync(bill);
      }

      final int? totalPages = response.body!.meta.pagination?.totalPages;
      if (totalPages == null || page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }

  Future<void> _syncBudgets(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final BudgetRepository repo = BudgetRepository(isar);

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Response<BudgetArray> response = await api.v1BudgetsGet(page: page);

      if (!response.isSuccessful || response.body == null) {
        throw Exception("Failed to fetch budgets: ${response.error}");
      }

      final List<BudgetRead> budgets = response.body!.data;
      if (budgets.isEmpty) {
        hasMore = false;
        break;
      }

      for (final BudgetRead budget in budgets) {
        final DateTime? updatedAt = budget.attributes.updatedAt;
        if (lastSync != null &&
            updatedAt != null &&
            updatedAt.isBefore(lastSync)) {
          continue;
        }

        if (await _hasPendingChange('budgets', budget.id)) continue;
        await repo.upsertFromSync(budget);
      }

      final int? totalPages = response.body!.meta.pagination?.totalPages;
      if (totalPages == null || page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }

  Future<void> _syncBudgetLimits(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final BudgetRepository repo = BudgetRepository(isar);

    // Budget limits API requires date range
    // Sync last 3 months to current month + 1 month ahead
    final DateTime now = DateTime.now().toUtc();
    final DateTime start = now.subtract(const Duration(days: 90));
    final DateTime end = now.add(const Duration(days: 60));

    final Response<BudgetLimitArray> response = await api.v1BudgetLimitsGet(
      start: intl.DateFormat('yyyy-MM-dd').format(start),
      end: intl.DateFormat('yyyy-MM-dd').format(end),
    );

    if (!response.isSuccessful || response.body == null) {
      throw Exception("Failed to fetch budget limits: ${response.error}");
    }

    final List<BudgetLimitRead> budgetLimits = response.body!.data;

    for (final BudgetLimitRead budgetLimit in budgetLimits) {
      final DateTime? updatedAt = budgetLimit.attributes.updatedAt;
      if (lastSync != null &&
          updatedAt != null &&
          updatedAt.isBefore(lastSync)) {
        // Skip if already synced (incremental sync)
        continue;
      }

      // Check for conflicts
      final BudgetLimitRead? existing = await repo.getBudgetLimitById(
        budgetLimit.id,
      );
      if (existing != null) {
        final DateTime? localUpdatedAt = existing.attributes.updatedAt;
        if (localUpdatedAt != null &&
            updatedAt != null &&
            localUpdatedAt.isAfter(updatedAt)) {
          // Local is newer - log conflict
          await conflictResolver.logConflict(
            entityType: 'budget_limits',
            entityId: budgetLimit.id,
            conflictType: ConflictType.download,
            localUpdatedAt: localUpdatedAt,
            serverUpdatedAt: updatedAt,
            resolution: conflictResolver.resolveConflict(
              localUpdatedAt: localUpdatedAt,
              serverUpdatedAt: updatedAt,
            ),
          );
          // Server wins by default - continue with server data
        }
      }

      await repo.upsertBudgetLimitFromSync(budgetLimit);
    }

    final DateTime syncTime = DateTime.now().toUtc();
    await _updateSyncMetadata('budget_limits', lastDownloadSync: syncTime);
  }

  Future<void> _syncCurrencies(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final CurrencyRepository repo = CurrencyRepository(isar);

    final Response<CurrencyArray> response = await api.v1CurrenciesGet();

    if (!response.isSuccessful || response.body == null) {
      throw Exception("Failed to fetch currencies: ${response.error}");
    }

    for (final CurrencyRead currency in response.body!.data) {
      if (await _hasPendingChange('currencies', currency.id)) continue;
      await repo.upsertFromSync(currency);
    }
  }

  Future<void> _syncPiggyBanks(DateTime? lastSync) async {
    final FireflyIii api = fireflyService.api;
    final PiggyBankRepository repo = PiggyBankRepository(isar);

    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      final Response<PiggyBankArray> response = await api.v1PiggyBanksGet(
        page: page,
      );

      if (!response.isSuccessful || response.body == null) {
        throw Exception("Failed to fetch piggy banks: ${response.error}");
      }

      final List<PiggyBankRead> piggyBanks = response.body!.data;
      if (piggyBanks.isEmpty) {
        hasMore = false;
        break;
      }

      for (final PiggyBankRead piggyBank in piggyBanks) {
        final DateTime? updatedAt = piggyBank.attributes.updatedAt;
        if (lastSync != null &&
            updatedAt != null &&
            updatedAt.isBefore(lastSync)) {
          continue;
        }

        if (await _hasPendingChange('piggy_banks', piggyBank.id)) continue;
        await repo.upsertFromSync(piggyBank);
      }

      final int? totalPages = response.body!.meta.pagination?.totalPages;
      if (totalPages == null || page >= totalPages) {
        hasMore = false;
      } else {
        page++;
      }
    }
  }

  Future<void> _refreshStaleInsights() async {
    final InsightRepository insightRepo = InsightRepository(isar);
    final List<Insights> staleInsights = await insightRepo.getStaleInsights();

    if (staleInsights.isEmpty) {
      return;
    }

    final FireflyIii api = fireflyService.api;

    for (final Insights insight in staleInsights) {
      try {
        dynamic data;

        if (insight.insightSubtype == 'total') {
          final Response<InsightTotal> response =
              insight.insightType == 'expense'
              ? await api.v1InsightExpenseTotalGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.startDate),
                  end: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.endDate),
                )
              : insight.insightType == 'income'
              ? await api.v1InsightIncomeTotalGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.startDate),
                  end: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.endDate),
                )
              : await api.v1InsightTransferTotalGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.startDate),
                  end: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.endDate),
                );

          if (response.isSuccessful && response.body != null) {
            data = response.body!
                .map((InsightTotalEntry e) => e.toJson())
                .toList();
          }
        } else if (insight.insightSubtype.startsWith('no-')) {
          final String baseType = insight.insightSubtype.substring(3);
          final Response<InsightTotal> response =
              insight.insightType == 'expense'
              ? baseType == 'category'
                    ? await api.v1InsightExpenseNoCategoryGet(
                        start: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.startDate),
                        end: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.endDate),
                      )
                    : baseType == 'tag'
                    ? await api.v1InsightExpenseNoTagGet(
                        start: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.startDate),
                        end: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.endDate),
                      )
                    : await api.v1InsightExpenseNoBillGet(
                        start: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.startDate),
                        end: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.endDate),
                      )
              : await api.v1InsightIncomeNoCategoryGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.startDate),
                  end: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.endDate),
                );

          if (response.isSuccessful && response.body != null) {
            data = response.body!
                .map((InsightTotalEntry e) => e.toJson())
                .toList();
          }
        } else {
          final Response<InsightGroup> response =
              insight.insightType == 'expense'
              ? insight.insightSubtype == 'category'
                    ? await api.v1InsightExpenseCategoryGet(
                        start: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.startDate),
                        end: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.endDate),
                      )
                    : insight.insightSubtype == 'tag'
                    ? await api.v1InsightExpenseTagGet(
                        start: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.startDate),
                        end: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.endDate),
                      )
                    : await api.v1InsightExpenseBillGet(
                        start: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.startDate),
                        end: intl.DateFormat(
                          'yyyy-MM-dd',
                          'en_US',
                        ).format(insight.endDate),
                      )
              : insight.insightSubtype == 'category'
              ? await api.v1InsightIncomeCategoryGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.startDate),
                  end: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.endDate),
                )
              : await api.v1InsightIncomeTagGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.startDate),
                  end: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(insight.endDate),
                );

          if (response.isSuccessful && response.body != null) {
            data = response.body!
                .map((InsightGroupEntry e) => e.toJson())
                .toList();
          }
        }

        if (data != null) {
          await insightRepo.cacheInsight(
            insight.insightType,
            insight.insightSubtype,
            insight.startDate,
            insight.endDate,
            data,
          );
        }
      } catch (e) {
        log.warning("Failed to refresh insight", e);
        // Continue with other insights
      }
    }

    await insightRepo.refreshStaleInsights();
  }

  Future<void> _prefetchCommonInsights() async {
    final InsightRepository insightRepo = InsightRepository(isar);
    final FireflyIii api = fireflyService.api;
    final TimeZoneHandler tzHandler = fireflyService.tzHandler;

    final DateTime now = tzHandler.sNow().clearTime();

    try {
      // Prefetch current month category insights (for CategoryChart)
      final DateTime monthStart = now.copyWith(day: 1);
      final DateTime monthEnd = now;

      // Check if already cached
      final List<InsightGroupEntry> expenseCategories = await insightRepo
          .getGrouped('expense', 'category', monthStart, monthEnd);
      final List<InsightGroupEntry> incomeCategories = await insightRepo
          .getGrouped('income', 'category', monthStart, monthEnd);

      // Only fetch if not cached
      if (expenseCategories.isEmpty || incomeCategories.isEmpty) {
        try {
          // Fetch expense categories
          if (expenseCategories.isEmpty) {
            final Response<InsightGroup> response = await api
                .v1InsightExpenseCategoryGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(monthStart),
                  end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(monthEnd),
                );
            if (response.isSuccessful && response.body != null) {
              await insightRepo.cacheInsight(
                'expense',
                'category',
                monthStart,
                monthEnd,
                response.body!
                    .map((InsightGroupEntry e) => e.toJson())
                    .toList(),
              );
            }
          }

          // Fetch income categories
          if (incomeCategories.isEmpty) {
            final Response<InsightGroup> response = await api
                .v1InsightIncomeCategoryGet(
                  start: intl.DateFormat(
                    'yyyy-MM-dd',
                    'en_US',
                  ).format(monthStart),
                  end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(monthEnd),
                );
            if (response.isSuccessful && response.body != null) {
              await insightRepo.cacheInsight(
                'income',
                'category',
                monthStart,
                monthEnd,
                response.body!
                    .map((InsightGroupEntry e) => e.toJson())
                    .toList(),
              );
            }
          }
        } catch (e) {
          log.warning("Failed to prefetch category insights", e);
        }
      }

      // Prefetch last 3 months totals (for NetEarningsChart)
      final List<DateTime> lastMonths = <DateTime>[];
      for (int i = 0; i < 3; i++) {
        lastMonths.add(
          DateTime(now.year, now.month - i, (i == 0) ? now.day : 1),
        );
      }

      for (DateTime monthDate in lastMonths) {
        late DateTime start;
        late DateTime end;
        if (monthDate == lastMonths.first) {
          start = monthDate.copyWith(day: 1);
          end = monthDate;
        } else {
          start = monthDate;
          end = monthDate.copyWith(month: monthDate.month + 1, day: 0);
        }

        // Check if already cached
        final List<InsightTotalEntry> expenseTotal = await insightRepo.getTotal(
          'expense',
          start,
          end,
        );
        final List<InsightTotalEntry> incomeTotal = await insightRepo.getTotal(
          'income',
          start,
          end,
        );

        // Only fetch if not cached
        if (expenseTotal.isEmpty || incomeTotal.isEmpty) {
          try {
            // Fetch expense total
            if (expenseTotal.isEmpty) {
              final Response<InsightTotal> response = await api
                  .v1InsightExpenseTotalGet(
                    start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
                    end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
                  );
              if (response.isSuccessful && response.body != null) {
                await insightRepo.cacheInsight(
                  'expense',
                  'total',
                  start,
                  end,
                  response.body!
                      .map((InsightTotalEntry e) => e.toJson())
                      .toList(),
                );
              }
            }

            // Fetch income total
            if (incomeTotal.isEmpty) {
              final Response<InsightTotal> response = await api
                  .v1InsightIncomeTotalGet(
                    start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
                    end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
                  );
              if (response.isSuccessful && response.body != null) {
                await insightRepo.cacheInsight(
                  'income',
                  'total',
                  start,
                  end,
                  response.body!
                      .map((InsightTotalEntry e) => e.toJson())
                      .toList(),
                );
              }
            }
          } catch (e) {
            log.warning(
              "Failed to prefetch monthly totals for ${start.toString()}",
              e,
            );
          }
        }
      }
    } catch (e) {
      log.warning("Failed to prefetch common insights", e);
      // Don't fail the entire sync if prefetch fails
    }
  }

  Future<void> _updateSyncMetadata(
    String entityType, {
    DateTime? lastDownloadSync,
    DateTime? lastUploadSync,
    DateTime? lastFullSync,
    bool? syncPaused,
    int? retryCount,
    DateTime? nextRetryAt,
    String? lastError,
    bool? credentialsValidated,
    bool? credentialsInvalid,
    bool clearError = false,
  }) async {
    final SyncMetadata? existing = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo(entityType)
        .findFirst();

    if (existing == null) {
      final SyncMetadata metadata = SyncMetadata()
        ..entityType = entityType
        ..lastDownloadSync = lastDownloadSync
        ..lastUploadSync = lastUploadSync
        ..lastFullSync = lastFullSync
        ..syncPaused = syncPaused ?? false
        ..retryCount = retryCount ?? 0
        ..nextRetryAt = nextRetryAt
        ..lastError = lastError
        ..credentialsValidated = credentialsValidated ?? false
        ..credentialsInvalid = credentialsInvalid ?? false;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(metadata);
      });
    } else {
      if (lastDownloadSync != null) {
        existing.lastDownloadSync = lastDownloadSync;
      }
      if (lastUploadSync != null) {
        existing.lastUploadSync = lastUploadSync;
      }
      if (lastFullSync != null) {
        existing.lastFullSync = lastFullSync;
      }
      if (syncPaused != null) {
        existing.syncPaused = syncPaused;
      }
      if (retryCount != null) {
        existing.retryCount = retryCount;
      }
      if (nextRetryAt != null) {
        existing.nextRetryAt = nextRetryAt;
      }
      if (clearError || lastError != null) {
        existing.lastError = clearError ? null : lastError;
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

  /// Returns true if there is an unsynced pending change for this entity.
  /// Used to skip download overwrite when a local edit is queued.
  Future<bool> _hasPendingChange(String entityType, String entityId) async {
    final PendingChanges? pending = await isar.pendingChanges
        .filter()
        .entityTypeEqualTo(entityType)
        .entityIdEqualTo(entityId)
        .syncedEqualTo(false)
        .findFirst();
    return pending != null;
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _progressController?.close();
    super.dispose();
  }

  // Helper to check if disposed before notifying listeners
  // This prevents errors when async operations complete after disposal
  void _notifyListenersIfNotDisposed() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
