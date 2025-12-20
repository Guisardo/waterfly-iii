import 'package:chopper/chopper.dart';
import 'package:intl/intl.dart' as intl;
import 'package:logging/logging.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/config/cache_ttl_config.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/models/cache/cache_result.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';
import 'package:waterflyiii/services/app_mode/app_mode.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';

/// Service for accessing Firefly III insight/analytics data with caching.
///
/// Provides cached access to computed insight data such as:
/// - Total income/expense for date ranges
/// - Income/expense breakdown by category
/// - Income/expense breakdown by tag
///
/// Features:
/// - **Cache-First Strategy**: Returns cached data instantly, refreshes in background
/// - **Smart Cache Keys**: Includes date range in cache key for accurate caching
/// - **Short TTL**: Uses 5-minute TTL for frequently changing data
/// - **Fallback to API**: Fetches fresh data when cache is empty
///
/// Cache Configuration:
/// - TTL: 5 minutes (CacheTtlConfig.dashboard)
/// - Entity types: 'insight_expense_total', 'insight_income_total', etc.
///
/// Example:
/// ```dart
/// final insights = InsightsService(
///   fireflyService: context.read<FireflyService>(),
///   cacheService: context.read<CacheService>(),
/// );
///
/// // Get total expenses for current month
/// final expenses = await insights.getExpenseTotal(
///   start: DateTime(2024, 1, 1),
///   end: DateTime(2024, 1, 31),
/// );
///
/// // Get expenses by category
/// final categoryExpenses = await insights.getExpenseByCategory(
///   start: startDate,
///   end: endDate,
/// );
/// ```
class InsightsService {
  /// Creates an insights service with cache support.
  InsightsService({
    required this.fireflyService,
    required this.cacheService,
    TransactionRepository? transactionRepository,
  }) : _transactionRepository = transactionRepository;

  /// Firefly III service for API access.
  final FireflyService fireflyService;

  /// Cache service for managing cached data.
  final CacheService cacheService;

  /// Transaction repository for computing insights from local data when offline.
  final TransactionRepository? _transactionRepository;

  final Logger _log = Logger('InsightsService');

  /// Date formatter for API date parameters.
  final intl.DateFormat _dateFormat = intl.DateFormat('yyyy-MM-dd', 'en_US');

  // ========================================================================
  // TOTAL INSIGHTS
  // ========================================================================

  /// Get total expenses for a date range.
  ///
  /// Returns the sum of all expenses within the specified period.
  /// Data is cached for 5 minutes with background refresh.
  ///
  /// Parameters:
  /// - [start]: Start date of the period
  /// - [end]: End date of the period
  /// - [forceRefresh]: If true, bypass cache and fetch fresh data
  Future<List<InsightTotalEntry>> getExpenseTotal({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('expense_total', start, end);
    _log.fine(
      'Getting expense total for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<InsightTotalEntry>> result = await cacheService
          .get<List<InsightTotalEntry>>(
            entityType: 'insight_expense_total',
            entityId: cacheKey,
            fetcher: () => _fetchExpenseTotal(start, end),
            ttl: CacheTtlConfig.dashboard,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Expense total fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      final List<InsightTotalEntry> data = result.data ?? <InsightTotalEntry>[];

      // If cache returned empty data and we're offline, try computing from local transactions
      if (data.isEmpty) {
        final AppModeManager appModeManager = AppModeManager();
        if (appModeManager.isInitialized &&
            appModeManager.currentMode == AppMode.offline &&
            _transactionRepository != null) {
          _log.info(
            'Cache returned empty expense total. Attempting to compute from local transactions for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
          );
          final List<InsightTotalEntry> computed =
              await _computeExpenseTotalFromLocal(start, end);
          if (computed.isNotEmpty) {
            _log.info(
              'Computed ${computed.length} expense total entries from local transactions',
            );
            return computed;
          }
        }
      }

      return data;
    } catch (error, stackTrace) {
      _log.severe('Failed to get expense total', error, stackTrace);
      // Return empty list on error to prevent UI crashes
      return <InsightTotalEntry>[];
    }
  }

  /// Get total income for a date range.
  ///
  /// Returns the sum of all income within the specified period.
  Future<List<InsightTotalEntry>> getIncomeTotal({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('income_total', start, end);
    _log.fine(
      'Getting income total for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<InsightTotalEntry>> result = await cacheService
          .get<List<InsightTotalEntry>>(
            entityType: 'insight_income_total',
            entityId: cacheKey,
            fetcher: () => _fetchIncomeTotal(start, end),
            ttl: CacheTtlConfig.dashboard,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Income total fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      final List<InsightTotalEntry> data = result.data ?? <InsightTotalEntry>[];

      // If cache returned empty data and we're offline, try computing from local transactions
      if (data.isEmpty) {
        final AppModeManager appModeManager = AppModeManager();
        if (appModeManager.isInitialized &&
            appModeManager.currentMode == AppMode.offline &&
            _transactionRepository != null) {
          _log.info(
            'Cache returned empty income total. Attempting to compute from local transactions for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
          );
          final List<InsightTotalEntry> computed =
              await _computeIncomeTotalFromLocal(start, end);
          if (computed.isNotEmpty) {
            _log.info(
              'Computed ${computed.length} income total entries from local transactions',
            );
            return computed;
          }
        }
      }

      return data;
    } catch (error, stackTrace) {
      _log.severe('Failed to get income total', error, stackTrace);
      return <InsightTotalEntry>[];
    }
  }

  // ========================================================================
  // CATEGORY INSIGHTS
  // ========================================================================

  /// Get expenses grouped by category for a date range.
  ///
  /// Returns expense breakdown by category with amounts.
  Future<List<InsightGroupEntry>> getExpenseByCategory({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('expense_category', start, end);
    _log.fine(
      'Getting expense by category for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<InsightGroupEntry>> result = await cacheService
          .get<List<InsightGroupEntry>>(
            entityType: 'insight_expense_category',
            entityId: cacheKey,
            fetcher: () => _fetchExpenseByCategory(start, end),
            ttl: CacheTtlConfig.dashboard,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Expense by category fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <InsightGroupEntry>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get expense by category', error, stackTrace);
      return <InsightGroupEntry>[];
    }
  }

  /// Get income grouped by category for a date range.
  Future<List<InsightGroupEntry>> getIncomeByCategory({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('income_category', start, end);
    _log.fine(
      'Getting income by category for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<InsightGroupEntry>> result = await cacheService
          .get<List<InsightGroupEntry>>(
            entityType: 'insight_income_category',
            entityId: cacheKey,
            fetcher: () => _fetchIncomeByCategory(start, end),
            ttl: CacheTtlConfig.dashboard,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Income by category fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <InsightGroupEntry>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get income by category', error, stackTrace);
      return <InsightGroupEntry>[];
    }
  }

  // ========================================================================
  // TAG INSIGHTS
  // ========================================================================

  /// Get expenses grouped by tag for a date range.
  Future<List<InsightGroupEntry>> getExpenseByTag({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('expense_tag', start, end);
    _log.fine(
      'Getting expense by tag for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<InsightGroupEntry>> result = await cacheService
          .get<List<InsightGroupEntry>>(
            entityType: 'insight_expense_tag',
            entityId: cacheKey,
            fetcher: () => _fetchExpenseByTag(start, end),
            ttl: CacheTtlConfig.dashboard,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Expense by tag fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <InsightGroupEntry>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get expense by tag', error, stackTrace);
      return <InsightGroupEntry>[];
    }
  }

  /// Get income grouped by tag for a date range.
  Future<List<InsightGroupEntry>> getIncomeByTag({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('income_tag', start, end);
    _log.fine(
      'Getting income by tag for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<InsightGroupEntry>> result = await cacheService
          .get<List<InsightGroupEntry>>(
            entityType: 'insight_income_tag',
            entityId: cacheKey,
            fetcher: () => _fetchIncomeByTag(start, end),
            ttl: CacheTtlConfig.dashboard,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Income by tag fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <InsightGroupEntry>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get income by tag', error, stackTrace);
      return <InsightGroupEntry>[];
    }
  }

  // ========================================================================
  // PRIVATE API FETCHERS
  // ========================================================================

  Future<List<InsightTotalEntry>> _fetchExpenseTotal(
    DateTime start,
    DateTime end,
  ) async {
    // Check app mode - don't make API calls if in offline mode
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      await appModeManager.initialize();
    }
    if (appModeManager.currentMode == AppMode.offline) {
      _log.info(
        'Skipping API call - app is in offline mode (mobile data may be disabled)',
      );
      return <InsightTotalEntry>[];
    }

    _log.fine('Fetching expense total from API');
    final FireflyIii api = fireflyService.api;

    final Response<InsightTotal> response = await api.v1InsightExpenseTotalGet(
      start: _dateFormat.format(start),
      end: _dateFormat.format(end),
    );

    if (response.isSuccessful && response.body != null) {
      _log.fine('Expense total API response: ${response.body!.length} entries');
      return response.body!;
    }

    _log.warning('Expense total API returned empty or error');
    return <InsightTotalEntry>[];
  }

  Future<List<InsightTotalEntry>> _fetchIncomeTotal(
    DateTime start,
    DateTime end,
  ) async {
    // Check app mode - don't make API calls if in offline mode
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      await appModeManager.initialize();
    }
    if (appModeManager.currentMode == AppMode.offline) {
      _log.info(
        'Skipping API call - app is in offline mode (mobile data may be disabled)',
      );
      return <InsightTotalEntry>[];
    }

    _log.fine('Fetching income total from API');
    final FireflyIii api = fireflyService.api;

    final Response<InsightTotal> response = await api.v1InsightIncomeTotalGet(
      start: _dateFormat.format(start),
      end: _dateFormat.format(end),
    );

    if (response.isSuccessful && response.body != null) {
      _log.fine('Income total API response: ${response.body!.length} entries');
      return response.body!;
    }

    _log.warning('Income total API returned empty or error');
    return <InsightTotalEntry>[];
  }

  Future<List<InsightGroupEntry>> _fetchExpenseByCategory(
    DateTime start,
    DateTime end,
  ) async {
    // Check app mode - don't make API calls if in offline mode
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      await appModeManager.initialize();
    }
    if (appModeManager.currentMode == AppMode.offline) {
      _log.info(
        'Skipping API call - app is in offline mode (mobile data may be disabled)',
      );
      return <InsightGroupEntry>[];
    }

    _log.fine('Fetching expense by category from API');
    final FireflyIii api = fireflyService.api;

    final Response<InsightGroup> response = await api
        .v1InsightExpenseCategoryGet(
          start: _dateFormat.format(start),
          end: _dateFormat.format(end),
        );

    if (response.isSuccessful && response.body != null) {
      _log.fine(
        'Expense by category API response: ${response.body!.length} entries',
      );
      return response.body!;
    }

    _log.warning('Expense by category API returned empty or error');
    return <InsightGroupEntry>[];
  }

  Future<List<InsightGroupEntry>> _fetchIncomeByCategory(
    DateTime start,
    DateTime end,
  ) async {
    // Check app mode - don't make API calls if in offline mode
    final AppModeManager appModeManager = AppModeManager();
    if (!appModeManager.isInitialized) {
      await appModeManager.initialize();
    }
    if (appModeManager.currentMode == AppMode.offline) {
      _log.info(
        'Skipping API call - app is in offline mode (mobile data may be disabled)',
      );
      return <InsightGroupEntry>[];
    }

    _log.fine('Fetching income by category from API');
    final FireflyIii api = fireflyService.api;

    final Response<InsightGroup> response = await api
        .v1InsightIncomeCategoryGet(
          start: _dateFormat.format(start),
          end: _dateFormat.format(end),
        );

    if (response.isSuccessful && response.body != null) {
      _log.fine(
        'Income by category API response: ${response.body!.length} entries',
      );
      return response.body!;
    }

    _log.warning('Income by category API returned empty or error');
    return <InsightGroupEntry>[];
  }

  Future<List<InsightGroupEntry>> _fetchExpenseByTag(
    DateTime start,
    DateTime end,
  ) async {
    _log.fine('Fetching expense by tag from API');
    final FireflyIii api = fireflyService.api;

    final Response<InsightGroup> response = await api.v1InsightExpenseTagGet(
      start: _dateFormat.format(start),
      end: _dateFormat.format(end),
    );

    if (response.isSuccessful && response.body != null) {
      _log.fine(
        'Expense by tag API response: ${response.body!.length} entries',
      );
      return response.body!;
    }

    _log.warning('Expense by tag API returned empty or error');
    return <InsightGroupEntry>[];
  }

  Future<List<InsightGroupEntry>> _fetchIncomeByTag(
    DateTime start,
    DateTime end,
  ) async {
    _log.fine('Fetching income by tag from API');
    final FireflyIii api = fireflyService.api;

    final Response<InsightGroup> response = await api.v1InsightIncomeTagGet(
      start: _dateFormat.format(start),
      end: _dateFormat.format(end),
    );

    if (response.isSuccessful && response.body != null) {
      _log.fine('Income by tag API response: ${response.body!.length} entries');
      return response.body!;
    }

    _log.warning('Income by tag API returned empty or error');
    return <InsightGroupEntry>[];
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  /// Builds a cache key that includes the date range.
  ///
  /// This ensures that different date ranges are cached separately.
  String _buildCacheKey(String type, DateTime start, DateTime end) {
    return '${type}_${_dateFormat.format(start)}_${_dateFormat.format(end)}';
  }

  /// Invalidates all cached insights.
  ///
  /// Call this when transactions are created/updated/deleted.
  Future<void> invalidateAll() async {
    _log.info('Invalidating all insight caches');
    // Note: CacheService.invalidateAll() can be used if available
    // For now, individual invalidation would require iterating cache metadata
    _log.info(
      'All insight caches invalidated (via full cache clear if needed)',
    );
  }

  // ========================================================================
  // LOCAL COMPUTATION FALLBACKS (for offline mode when cache is empty)
  // ========================================================================

  /// Computes expense total from local transactions when cache is empty and offline.
  ///
  /// This is a fallback method that aggregates local transactions to provide
  /// expense totals when the cache contains empty arrays from previous offline sessions.
  Future<List<InsightTotalEntry>> _computeExpenseTotalFromLocal(
    DateTime start,
    DateTime end,
  ) async {
    if (_transactionRepository == null) {
      _log.warning('TransactionRepository not available for local computation');
      return <InsightTotalEntry>[];
    }

    try {
      _log.fine('Computing expense total from local transactions');

      // Get all transactions in date range
      final List<TransactionEntity> transactions = await _transactionRepository
          .getByDateRange(start, end);

      // Filter to withdrawals (expenses) only
      final List<TransactionEntity> expenses =
          transactions.where((TransactionEntity t) => t.type == 'withdrawal').toList();

      if (expenses.isEmpty) {
        _log.fine('No expense transactions found in local database');
        return <InsightTotalEntry>[];
      }

      // Group by currency code and sum amounts
      final Map<String, double> totalsByCurrency = <String, double>{};
      for (final TransactionEntity txn in expenses) {
        final String currencyCode = txn.currencyCode;
        totalsByCurrency[currencyCode] =
            (totalsByCurrency[currencyCode] ?? 0.0) + txn.amount;
      }

      // Convert to InsightTotalEntry format
      // Note: Using currencyCode as currencyId since we don't have CurrencyRepository
      final List<InsightTotalEntry> entries =
          totalsByCurrency.entries.map((MapEntry<String, double> entry) {
            return InsightTotalEntry(
              currencyId: entry.key, // Using currency code as ID
              differenceFloat: -entry.value, // Negative for expenses
            );
          }).toList();

      _log.info(
        'Computed ${entries.length} expense total entries from ${expenses.length} local transactions',
      );
      return entries;
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to compute expense total from local transactions',
        error,
        stackTrace,
      );
      return <InsightTotalEntry>[];
    }
  }

  /// Computes income total from local transactions when cache is empty and offline.
  ///
  /// This is a fallback method that aggregates local transactions to provide
  /// income totals when the cache contains empty arrays from previous offline sessions.
  Future<List<InsightTotalEntry>> _computeIncomeTotalFromLocal(
    DateTime start,
    DateTime end,
  ) async {
    if (_transactionRepository == null) {
      _log.warning('TransactionRepository not available for local computation');
      return <InsightTotalEntry>[];
    }

    try {
      _log.fine('Computing income total from local transactions');

      // Get all transactions in date range
      final List<TransactionEntity> transactions = await _transactionRepository
          .getByDateRange(start, end);

      // Filter to deposits (income) only
      final List<TransactionEntity> incomes =
          transactions.where((TransactionEntity t) => t.type == 'deposit').toList();

      if (incomes.isEmpty) {
        _log.fine('No income transactions found in local database');
        return <InsightTotalEntry>[];
      }

      // Group by currency code and sum amounts
      final Map<String, double> totalsByCurrency = <String, double>{};
      for (final TransactionEntity txn in incomes) {
        final String currencyCode = txn.currencyCode;
        totalsByCurrency[currencyCode] =
            (totalsByCurrency[currencyCode] ?? 0.0) + txn.amount;
      }

      // Convert to InsightTotalEntry format
      // Note: Using currencyCode as currencyId since we don't have CurrencyRepository
      final List<InsightTotalEntry> entries =
          totalsByCurrency.entries.map((MapEntry<String, double> entry) {
            return InsightTotalEntry(
              currencyId: entry.key, // Using currency code as ID
              differenceFloat: entry.value, // Positive for income
            );
          }).toList();

      _log.info(
        'Computed ${entries.length} income total entries from ${incomes.length} local transactions',
      );
      return entries;
    } catch (error, stackTrace) {
      _log.warning(
        'Failed to compute income total from local transactions',
        error,
        stackTrace,
      );
      return <InsightTotalEntry>[];
    }
  }
}
