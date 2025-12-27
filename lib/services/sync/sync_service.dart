import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'package:logging/logging.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/auth.dart' show FireflyService, httpClient;
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
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart' show ConflictResolver, ConflictType, ConflictResolution;
import 'package:waterflyiii/services/sync/retry_manager.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/settings.dart';

final Logger log = Logger("Sync");

class SyncProgress {
  final String entityType;
  final int current;
  final int total;
  final String? message;

  SyncProgress({
    required this.entityType,
    required this.current,
    required this.total,
    this.message,
  });
}

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
  })  : retryManager = RetryManager(isar),
        conflictResolver = ConflictResolver(isar) {
    // Set settings provider for notifications localization
    notifications.setSettingsProvider(settingsProvider);
  }

  Future<bool> validateCredentials() async {
    try {
      final FireflyIii api = fireflyService.api;
      final Response<SystemInfo> about = await api.v1AboutGet();

      if (!about.isSuccessful || about.body == null) {
        return false;
      }

      // Mark credentials as validated
      await _updateSyncMetadata(
        'auth',
        credentialsValidated: true,
        credentialsInvalid: false,
      );

      return true;
    } catch (e) {
      log.warning("Credential validation failed", e);
      await _updateSyncMetadata(
        'auth',
        credentialsValidated: false,
        credentialsInvalid: true,
      );
      return false;
    }
  }

  Future<void> sync({
    bool forceFullSync = false,
    String? entityType,
  }) async {
    if (_isSyncing) {
      log.config("Sync already in progress, skipping");
      return;
    }

    _isSyncing = true;
    _progressController = StreamController<SyncProgress>.broadcast();
    notifyListeners();

    try {
      // Check if sync is paused
      final String syncEntityType = entityType ?? 'download';
      if (await retryManager.isPaused(syncEntityType)) {
        log.config("Sync is paused for $syncEntityType");
        _isSyncing = false;
        notifyListeners();
        return;
      }

      // Check connectivity
      if (!connectivityService.isOnline) {
        log.config("Device is offline, skipping sync");
        _isSyncing = false;
        notifyListeners();
        return;
      }

      // Check mobile data setting
      if (connectivityService.isMobile &&
          (settingsProvider?.syncUseMobileData ?? false) == false) {
        log.config("Mobile data sync disabled, skipping");
        _isSyncing = false;
        notifyListeners();
        return;
      }

      // Validate credentials
      final SyncMetadata? authMetadata = await retryManager.getMetadata('auth');
      if (authMetadata == null || !authMetadata.credentialsValidated) {
        log.config("Validating credentials...");
        final bool valid = await validateCredentials();
        if (!valid) {
          log.warning("Credentials invalid, cannot sync");
          await notifications.showCredentialError();
          _isSyncing = false;
          notifyListeners();
          return;
        }
      }

      if (authMetadata?.credentialsInvalid ?? false) {
        log.warning("Credentials marked as invalid, cannot sync");
        _isSyncing = false;
        notifyListeners();
        return;
      }

      await notifications.showSyncStarted();

      // Sync entities
      final List<String> entityTypes = entityType != null
          ? [entityType]
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
          // Continue with other entity types
        }
      }

      // Refresh stale insights
      await _refreshStaleInsights();

      await retryManager.resetRetry('download');
      await notifications.showSyncCompleted();

      _isSyncing = false;
      notifyListeners();
    } catch (e, stackTrace) {
      log.severe("Sync failed", e, stackTrace);

      // Handle errors
      if (_isNetworkError(e) || _isTimeoutError(e) || _isServerError(e)) {
        await retryManager.pauseWithBackoff(
          entityType ?? 'download',
          e.toString(),
        );
        await notifications.showSyncPaused(e.toString());
      } else if (_isAuthError(e)) {
        await _updateSyncMetadata(
          'auth',
          credentialsInvalid: true,
        );
        await notifications.showCredentialError();
      }

      _isSyncing = false;
      notifyListeners();
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

    // Update last sync time
    await _updateSyncMetadata(
      entityType,
      lastDownloadSync: DateTime.now().toUtc(),
    );
  }

  Future<void> _syncTransactions(DateTime? lastSync) async {
    final TransactionRepository repo = TransactionRepository(isar);
    final http.Client client = httpClient;

    int page = 1;
    bool hasMore = true;
    int totalSynced = 0;

    while (hasMore) {
      try {
        // Use direct HTTP request to include order_by and order_direction parameters
        // Order by updated_at DESC to get newest modified first
        final Uri transactionsUri = fireflyService.user!.host.replace(
          pathSegments: <String>[
            ...fireflyService.user!.host.pathSegments,
            'v1',
            'transactions',
          ],
          queryParameters: <String, String>{
            'page': page.toString(),
            'limit': '50',
            'order_by': 'updated_at',
            'order_direction': 'desc',
          },
        );

        final http.Response httpResponse = await client.get(
          transactionsUri,
          headers: fireflyService.user!.headers(),
        );

        if (httpResponse.statusCode != 200) {
          throw Exception(
            "Failed to fetch transactions: ${httpResponse.statusCode} ${httpResponse.body}",
          );
        }

        final Map<String, dynamic> responseJson =
            jsonDecode(httpResponse.body) as Map<String, dynamic>;
        final TransactionArray transactionArray =
            TransactionArray.fromJson(responseJson);

        final List<TransactionRead> transactions = transactionArray.data;
        if (transactions.isEmpty) {
          hasMore = false;
          break;
        }

        for (final TransactionRead transaction in transactions) {
          final DateTime? updatedAt =
              transaction.attributes.updatedAt;

          // Stop if we've reached already-synced items (incremental sync)
          // Since we're ordering by updated_at DESC, once we hit an item older than lastSync,
          // all subsequent items will also be older
          if (lastSync != null &&
              updatedAt != null &&
              updatedAt.isBefore(lastSync)) {
            hasMore = false;
            break;
          }

          // Check for conflicts
          final TransactionRead? local = await repo.getById(transaction.id);
          if (local != null) {
            final DateTime? localUpdatedAt = local.attributes.updatedAt;
            if (localUpdatedAt != null &&
                updatedAt != null &&
                localUpdatedAt.isAtSameMomentAs(updatedAt) &&
                jsonEncode(local.toJson()) != jsonEncode(transaction.toJson())) {
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
        final int? totalPages = transactionArray.meta.pagination?.totalPages;
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
          hasMore = false;
          break;
        }

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
          hasMore = false;
          break;
        }

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
      final Response<TagArray> response = await api.v1TagsGet(
        page: page,
      );

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
          hasMore = false;
          break;
        }

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
      final Response<BillArray> response = await api.v1BillsGet(
        page: page,
      );

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
          hasMore = false;
          break;
        }

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
      final Response<BudgetArray> response = await api.v1BudgetsGet(
        page: page,
      );

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
          hasMore = false;
          break;
        }

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
      final BudgetLimitRead? existing = await repo.getBudgetLimitById(budgetLimit.id);
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
          hasMore = false;
          break;
        }

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
                      start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                          .format(insight.startDate),
                      end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                          .format(insight.endDate),
                    )
                  : insight.insightType == 'income'
                      ? await api.v1InsightIncomeTotalGet(
                          start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.startDate),
                          end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.endDate),
                        )
                      : await api.v1InsightTransferTotalGet(
                          start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.startDate),
                          end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.endDate),
                        );

          if (response.isSuccessful && response.body != null) {
            data = response.body!.map((e) => e.toJson()).toList();
          }
        } else if (insight.insightSubtype.startsWith('no-')) {
          final String baseType = insight.insightSubtype.substring(3);
          final Response<InsightTotal> response =
              insight.insightType == 'expense'
                  ? baseType == 'category'
                      ? await api.v1InsightExpenseNoCategoryGet(
                          start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.startDate),
                          end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.endDate),
                        )
                      : baseType == 'tag'
                          ? await api.v1InsightExpenseNoTagGet(
                              start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.startDate),
                              end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.endDate),
                            )
                          : await api.v1InsightExpenseNoBillGet(
                              start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.startDate),
                              end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.endDate),
                            )
                  : await api.v1InsightIncomeNoCategoryGet(
                      start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                          .format(insight.startDate),
                      end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                          .format(insight.endDate),
                    );

          if (response.isSuccessful && response.body != null) {
            data = response.body!.map((e) => e.toJson()).toList();
          }
        } else {
          final Response<InsightGroup> response =
              insight.insightType == 'expense'
                  ? insight.insightSubtype == 'category'
                      ? await api.v1InsightExpenseCategoryGet(
                          start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.startDate),
                          end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.endDate),
                        )
                      : insight.insightSubtype == 'tag'
                          ? await api.v1InsightExpenseTagGet(
                              start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.startDate),
                              end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.endDate),
                            )
                          : await api.v1InsightExpenseBillGet(
                              start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.startDate),
                              end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                                  .format(insight.endDate),
                            )
                  : insight.insightSubtype == 'category'
                      ? await api.v1InsightIncomeCategoryGet(
                          start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.startDate),
                          end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.endDate),
                        )
                      : await api.v1InsightIncomeTagGet(
                          start: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.startDate),
                          end: intl.DateFormat('yyyy-MM-dd', 'en_US')
                              .format(insight.endDate),
                        );

          if (response.isSuccessful && response.body != null) {
            data = response.body!.map((e) => e.toJson()).toList();
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
      if (lastDownloadSync != null) existing.lastDownloadSync = lastDownloadSync;
      if (lastUploadSync != null) existing.lastUploadSync = lastUploadSync;
      if (lastFullSync != null) existing.lastFullSync = lastFullSync;
      if (syncPaused != null) existing.syncPaused = syncPaused;
      if (retryCount != null) existing.retryCount = retryCount;
      if (nextRetryAt != null) existing.nextRetryAt = nextRetryAt;
      if (lastError != null) existing.lastError = lastError;
      if (credentialsValidated != null) existing.credentialsValidated = credentialsValidated;
      if (credentialsInvalid != null) existing.credentialsInvalid = credentialsInvalid;

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(existing);
      });
    }
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

  bool _isAuthError(dynamic error) {
    if (error is Response) {
      return error.statusCode == 401 || error.statusCode == 403;
    }
    return error.toString().contains('401') || error.toString().contains('403');
  }

  void dispose() {
    _progressController?.close();
    super.dispose();
  }
}

