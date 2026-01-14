import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:intl/intl.dart' as intl;
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';

class InsightRepository {
  final Isar isar;
  FireflyService? _fireflyService;

  InsightRepository(this.isar);

  void setFireflyService(FireflyService fireflyService) {
    _fireflyService = fireflyService;
  }

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<InsightTotalEntry>> getTotal(
    String type,
    DateTime start,
    DateTime end,
  ) async {
    final Insights? cached =
        await isar.insights
            .filter()
            .insightTypeEqualTo(type)
            .insightSubtypeEqualTo('total')
            .startDateEqualTo(start)
            .endDateEqualTo(end)
            .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList = jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map(
            (dynamic e) =>
                InsightTotalEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    // No cached data - return empty list (will be fetched by sync service)
    return <InsightTotalEntry>[];
  }

  Future<List<InsightGroupEntry>> getGrouped(
    String type,
    String subtype,
    DateTime start,
    DateTime end,
  ) async {
    final Insights? cached =
        await isar.insights
            .filter()
            .insightTypeEqualTo(type)
            .insightSubtypeEqualTo(subtype)
            .startDateEqualTo(start)
            .endDateEqualTo(end)
            .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList = jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map(
            (dynamic e) =>
                InsightGroupEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    // No cached data - fetch from API if available
    if (_fireflyService != null && _fireflyService!.signedIn) {
      try {
        final FireflyIii api = _fireflyService!.api;
        final Response<List<InsightGroupEntry>> response;

        if (type == 'expense') {
          if (subtype == 'category') {
            response = await api.v1InsightExpenseCategoryGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          } else if (subtype == 'tag') {
            response = await api.v1InsightExpenseTagGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          } else {
            response = await api.v1InsightExpenseBillGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          }
        } else if (type == 'income') {
          if (subtype == 'category') {
            response = await api.v1InsightIncomeCategoryGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          } else {
            response = await api.v1InsightIncomeTagGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          }
        } else {
          // transfer
          response = await api.v1InsightTransferCategoryGet(
            start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
            end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
          );
        }

        if (response.isSuccessful && response.body != null) {
          final List<InsightGroupEntry> entries = response.body!;
          // Cache the results
          await cacheInsight(
            type,
            subtype,
            start,
            end,
            entries.map((InsightGroupEntry e) => e.toJson()).toList(),
          );
          return entries;
        }
      } catch (e) {
        // If API fetch fails, return empty list
        // Error will be logged by the caller if needed
      }
    }

    // No cached data and API fetch failed or unavailable - return empty list
    return <InsightGroupEntry>[];
  }

  Future<List<InsightTotalEntry>> getNoGroup(
    String type,
    String subtype,
    DateTime start,
    DateTime end,
  ) async {
    final String noSubtype = 'no-$subtype';
    final Insights? cached =
        await isar.insights
            .filter()
            .insightTypeEqualTo(type)
            .insightSubtypeEqualTo(noSubtype)
            .startDateEqualTo(start)
            .endDateEqualTo(end)
            .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList = jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map(
            (dynamic e) =>
                InsightTotalEntry.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    // No cached data - fetch from API if available
    if (_fireflyService != null && _fireflyService!.signedIn) {
      try {
        final FireflyIii api = _fireflyService!.api;
        final Response<List<InsightTotalEntry>> response;

        if (type == 'expense') {
          if (subtype == 'category') {
            response = await api.v1InsightExpenseNoCategoryGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          } else if (subtype == 'tag') {
            response = await api.v1InsightExpenseNoTagGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          } else {
            response = await api.v1InsightExpenseNoBillGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          }
        } else if (type == 'income') {
          if (subtype == 'category') {
            response = await api.v1InsightIncomeNoCategoryGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          } else {
            response = await api.v1InsightIncomeNoTagGet(
              start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
              end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
            );
          }
        } else {
          // transfer
          response = await api.v1InsightTransferNoCategoryGet(
            start: intl.DateFormat('yyyy-MM-dd', 'en_US').format(start),
            end: intl.DateFormat('yyyy-MM-dd', 'en_US').format(end),
          );
        }

        if (response.isSuccessful && response.body != null) {
          final List<InsightTotalEntry> entries = response.body!;
          // Cache the results
          await cacheInsight(
            type,
            noSubtype,
            start,
            end,
            entries.map((InsightTotalEntry e) => e.toJson()).toList(),
          );
          return entries;
        }
      } catch (e) {
        // If API fetch fails, return empty list
        // Error will be logged by the caller if needed
      }
    }

    // No cached data and API fetch failed or unavailable - return empty list
    return <InsightTotalEntry>[];
  }

  Future<void> cacheInsight(
    String type,
    String subtype,
    DateTime start,
    DateTime end,
    dynamic data,
  ) async {
    final DateTime now = _getNow();

    final Insights row =
        Insights()
          ..insightType = type
          ..insightSubtype = subtype
          ..startDate = start
          ..endDate = end
          ..data = jsonEncode(data)
          ..cachedAt = now
          ..stale = false;

    await isar.writeTxn(() async {
      await isar.insights.put(row);
    });
  }

  Future<void> markStale(DateTime? start, DateTime? end) async {
    if (start == null && end == null) {
      // Mark all insights as stale
      final List<Insights> all = await isar.insights.where().findAll();
      await isar.writeTxn(() async {
        for (final Insights insight in all) {
          insight.stale = true;
          await isar.insights.put(insight);
        }
      });
      return;
    }

    // Mark insights that overlap with the date range as stale
    // Fetch all insights and filter in memory since Isar doesn't support complex date range queries easily
    final DateTime endDate = end ?? DateTime.now();
    final DateTime startDate = start ?? DateTime(1970);

    await isar.writeTxn(() async {
      // Fetch all insights fresh within the transaction
      final List<Insights> allInsights = await isar.insights.where().findAll();
      final List<Insights> insights =
          allInsights.where((Insights insight) {
            // Check if insight date range overlaps with the given range
            // Two ranges [start1, end1] and [start2, end2] overlap if:
            // start1 <= end2 && end1 >= start2
            // Using isBefore/isAfter with strict comparison to avoid edge cases
            return !insight.startDate.isAfter(endDate) &&
                !insight.endDate.isBefore(startDate);
          }).toList();

      for (final Insights insight in insights) {
        // Create a new object with updated values to ensure Isar detects the change
        final Insights updated =
            Insights()
              ..id = insight.id
              ..insightType = insight.insightType
              ..insightSubtype = insight.insightSubtype
              ..startDate = insight.startDate
              ..endDate = insight.endDate
              ..data = insight.data
              ..cachedAt = insight.cachedAt
              ..stale = true;
        await isar.insights.put(updated);
      }
    });
  }

  Future<void> markStaleForTransaction(TransactionRead transaction) async {
    // Get the transaction date
    final DateTime? txDate =
        transaction.attributes.transactions.firstOrNull?.date;
    if (txDate == null) {
      return;
    }

    // Mark insights for the month containing this transaction as stale
    final DateTime monthStart = DateTime(txDate.year, txDate.month, 1);
    final DateTime monthEnd = DateTime(txDate.year, txDate.month + 1, 0);

    await markStale(monthStart, monthEnd);
  }

  Future<void> refreshStaleInsights() async {
    // This method is called by sync service to refresh stale insights
    // The actual fetching from API happens in sync service
    // This method just marks them as no longer stale after refresh
    final DateTime now = _getNow();

    // Update all stale insights in a single transaction
    // Create new objects to ensure MockIsar sees the updates correctly
    await isar.writeTxn(() async {
      // Get all stale insight IDs
      final List<Insights> staleInsights =
          await isar.insights.filter().staleEqualTo(true).findAll();
      if (staleInsights.isEmpty) return;

      // Create new objects with updated values to ensure MockIsar sees the changes
      for (final Insights insight in staleInsights) {
        if (insight.stale) {
          // Create a new object with updated values
          final Insights updated =
              Insights()
                ..id = insight.id
                ..insightType = insight.insightType
                ..insightSubtype = insight.insightSubtype
                ..startDate = insight.startDate
                ..endDate = insight.endDate
                ..data = insight.data
                ..cachedAt = now
                ..stale = false;
          await isar.insights.put(updated);
        }
      }
    });
  }

  Future<List<Insights>> getStaleInsights() {
    return isar.insights.filter().staleEqualTo(true).findAll();
  }

  /// Cache chart data (ChartDataSet list or ChartLine) to the database
  Future<void> cacheChartData(
    String chartType,
    DateTime start,
    DateTime end,
    List<ChartDataSet> data,
  ) async {
    final DateTime now = _getNow();

    await isar.writeTxn(() async {
      // Check if existing row exists
      final Insights? existing =
          await isar.insights
              .filter()
              .insightTypeEqualTo('chart')
              .insightSubtypeEqualTo(chartType)
              .startDateEqualTo(start)
              .endDateEqualTo(end)
              .findFirst();

      final Insights row =
          existing ?? Insights()
            ..insightType = 'chart'
            ..insightSubtype = chartType
            ..startDate = start
            ..endDate = end;

      row
        ..data = jsonEncode(data.map((ChartDataSet e) => e.toJson()).toList())
        ..cachedAt = now
        ..stale = false;

      await isar.insights.put(row);
    });
  }

  /// Retrieve cached chart data from the database
  /// Returns null if no cached data exists
  Future<List<ChartDataSet>?> getChartData(
    String chartType,
    DateTime start,
    DateTime end,
  ) async {
    final Insights? cached =
        await isar.insights
            .filter()
            .insightTypeEqualTo('chart')
            .insightSubtypeEqualTo(chartType)
            .startDateEqualTo(start)
            .endDateEqualTo(end)
            .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList = jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map((dynamic e) => ChartDataSet.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // No cached data
    return null;
  }
}
