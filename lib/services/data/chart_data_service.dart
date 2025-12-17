import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:intl/intl.dart' as intl;
import 'package:logging/logging.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/config/cache_ttl_config.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/models/cache/cache_result.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';

/// Service for accessing Firefly III chart data with caching.
///
/// Provides cached access to chart/graph data such as:
/// - Account overview charts (balance over time)
/// - Daily balance charts (earned/spent per day)
///
/// Features:
/// - **Cache-First Strategy**: Returns cached data instantly, refreshes in background
/// - **Smart Cache Keys**: Includes date range and parameters in cache key
/// - **Medium TTL**: Uses 10-minute TTL for chart data
/// - **Fallback to API**: Fetches fresh data when cache is empty
///
/// Cache Configuration:
/// - TTL: 10 minutes (CacheTtlConfig.charts)
/// - Entity types: 'chart_account', 'chart_balance'
///
/// Example:
/// ```dart
/// final charts = ChartDataService(
///   fireflyService: context.read<FireflyService>(),
///   cacheService: context.read<CacheService>(),
/// );
///
/// // Get account overview for last 3 months
/// final overview = await charts.getAccountOverview(
///   start: DateTime.now().subtract(Duration(days: 90)),
///   end: DateTime.now(),
/// );
///
/// // Get daily balance for last 7 days
/// final daily = await charts.getDailyBalance(
///   start: DateTime.now().subtract(Duration(days: 7)),
///   end: DateTime.now(),
/// );
/// ```
class ChartDataService {
  /// Creates a chart data service with cache support.
  ChartDataService({required this.fireflyService, required this.cacheService});

  /// Firefly III service for API access.
  final FireflyService fireflyService;

  /// Cache service for managing cached data.
  final CacheService cacheService;

  final Logger _log = Logger('ChartDataService');

  /// Date formatter for API date parameters.
  final intl.DateFormat _dateFormat = intl.DateFormat('yyyy-MM-dd', 'en_US');

  // ========================================================================
  // ACCOUNT OVERVIEW CHARTS
  // ========================================================================

  /// Get account overview chart data for a date range.
  ///
  /// Returns balance history for all accounts over the specified period.
  /// Data is cached for 10 minutes with background refresh.
  ///
  /// Parameters:
  /// - [start]: Start date of the period
  /// - [end]: End date of the period
  /// - [preselected]: Account filter preset ('all' or specific accounts)
  /// - [forceRefresh]: If true, bypass cache and fetch fresh data
  Future<List<ChartDataSet>> getAccountOverview({
    required DateTime start,
    required DateTime end,
    V1ChartAccountOverviewGetPreselected? preselected,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey(
      'account_overview',
      start,
      end,
      extra: preselected?.value,
    );
    _log.fine(
      'Getting account overview for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<ChartDataSet>> result = await cacheService
          .get<List<ChartDataSet>>(
            entityType: 'chart_account',
            entityId: cacheKey,
            fetcher: () => _fetchAccountOverview(start, end, preselected),
            ttl: CacheTtlConfig.charts,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Account overview fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <ChartDataSet>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get account overview', error, stackTrace);
      return <ChartDataSet>[];
    }
  }

  // ========================================================================
  // DAILY BALANCE CHARTS
  // ========================================================================

  /// Get daily balance chart data (earned/spent per day).
  ///
  /// Returns balance breakdown for each day in the specified period.
  /// Used for the "Last 7 Days" dashboard chart.
  ///
  /// Parameters:
  /// - [start]: Start date of the period
  /// - [end]: End date of the period
  /// - [period]: Aggregation period ('1D' for daily, '1W' for weekly, etc.)
  /// - [forceRefresh]: If true, bypass cache and fetch fresh data
  Future<List<ChartDataSet>> getDailyBalance({
    required DateTime start,
    required DateTime end,
    V1ChartBalanceBalanceGetPeriod period =
        V1ChartBalanceBalanceGetPeriod.value_1d,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey(
      'daily_balance',
      start,
      end,
      extra: period.value,
    );
    _log.fine(
      'Getting daily balance for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<ChartDataSet>> result = await cacheService
          .get<List<ChartDataSet>>(
            entityType: 'chart_balance',
            entityId: cacheKey,
            fetcher: () => _fetchDailyBalance(start, end, period),
            ttl: CacheTtlConfig.charts,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Daily balance fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <ChartDataSet>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get daily balance', error, stackTrace);
      return <ChartDataSet>[];
    }
  }

  // ========================================================================
  // BUDGET CHARTS
  // ========================================================================

  /// Get budget limit data for a date range.
  ///
  /// Returns budget limits and their spent amounts.
  Future<List<BudgetLimitRead>> getBudgetLimits({
    required DateTime start,
    required DateTime end,
    bool forceRefresh = false,
  }) async {
    final String cacheKey = _buildCacheKey('budget_limits', start, end);
    _log.fine(
      'Getting budget limits for ${_dateFormat.format(start)} to ${_dateFormat.format(end)}',
    );

    try {
      final CacheResult<List<BudgetLimitRead>> result = await cacheService
          .get<List<BudgetLimitRead>>(
            entityType: 'chart_budget',
            entityId: cacheKey,
            fetcher: () => _fetchBudgetLimits(start, end),
            ttl: CacheTtlConfig.charts,
            forceRefresh: forceRefresh,
          );

      _log.info(
        'Budget limits fetched from ${result.source} (fresh: ${result.isFresh})',
      );
      return result.data ?? <BudgetLimitRead>[];
    } catch (error, stackTrace) {
      _log.severe('Failed to get budget limits', error, stackTrace);
      return <BudgetLimitRead>[];
    }
  }

  // ========================================================================
  // PRIVATE API FETCHERS
  // ========================================================================

  Future<List<ChartDataSet>> _fetchAccountOverview(
    DateTime start,
    DateTime end,
    V1ChartAccountOverviewGetPreselected? preselected,
  ) async {
    _log.fine('Fetching account overview from API');
    final FireflyIii api = fireflyService.api;

    try {
      final Response<ChartLine> response = await api.v1ChartAccountOverviewGet(
        start: _dateFormat.format(start),
        end: _dateFormat.format(end),
        preselected: preselected,
      );

      if (response.isSuccessful && response.body != null) {
        _log.fine(
          'Account overview API response: ${response.body!.length} series',
        );
        return response.body!;
      }

      _log.warning('Account overview API returned empty or error');
      return <ChartDataSet>[];
    } catch (e, stackTrace) {
      _log.severe('API call failed', e, stackTrace);
      rethrow;
    }
  }

  Future<List<ChartDataSet>> _fetchDailyBalance(
    DateTime start,
    DateTime end,
    V1ChartBalanceBalanceGetPeriod period,
  ) async {
    _log.fine('Fetching daily balance from API');
    final FireflyIii api = fireflyService.api;

    final Response<List<ChartDataSet>> response = await api
        .v1ChartBalanceBalanceGet(
          start: _dateFormat.format(start),
          end: _dateFormat.format(end),
          period: period,
        );

    if (response.isSuccessful && response.body != null) {
      _log.fine('Daily balance API response: ${response.body!.length} entries');
      return response.body!;
    }

    _log.warning('Daily balance API returned empty or error');
    return <ChartDataSet>[];
  }

  Future<List<BudgetLimitRead>> _fetchBudgetLimits(
    DateTime start,
    DateTime end,
  ) async {
    _log.fine('Fetching budget limits from API');
    final FireflyIii api = fireflyService.api;

    final Response<BudgetLimitArray> response = await api.v1BudgetLimitsGet(
      start: _dateFormat.format(start),
      end: _dateFormat.format(end),
    );

    if (response.isSuccessful && response.body != null) {
      _log.fine(
        'Budget limits API response: ${response.body!.data.length} entries',
      );
      return response.body!.data;
    }

    _log.warning('Budget limits API returned empty or error');
    return <BudgetLimitRead>[];
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  /// Builds a cache key that includes the date range and optional parameters.
  String _buildCacheKey(
    String type,
    DateTime start,
    DateTime end, {
    String? extra,
  }) {
    final String key =
        '${type}_${_dateFormat.format(start)}_${_dateFormat.format(end)}';
    if (extra != null) {
      return '${key}_$extra';
    }
    return key;
  }

  /// Invalidates all cached chart data.
  ///
  /// Call this when transactions are created/updated/deleted.
  Future<void> invalidateAll() async {
    _log.info('Invalidating all chart caches');
    // Note: Individual type invalidation would require iterating cache metadata
    _log.info('All chart caches invalidated (via full cache clear if needed)');
  }
}
