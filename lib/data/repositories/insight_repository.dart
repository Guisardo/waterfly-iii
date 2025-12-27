import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class InsightRepository {
  final Isar isar;

  InsightRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<InsightTotalEntry>> getTotal(
    String type,
    DateTime start,
    DateTime end,
  ) async {
    final Insights? cached = await isar.insights
        .filter()
        .insightTypeEqualTo(type)
        .insightSubtypeEqualTo('total')
        .startDateEqualTo(start)
        .endDateEqualTo(end)
        .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList =
          jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map((e) => InsightTotalEntry.fromJson(e as Map<String, dynamic>))
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
    final Insights? cached = await isar.insights
        .filter()
        .insightTypeEqualTo(type)
        .insightSubtypeEqualTo(subtype)
        .startDateEqualTo(start)
        .endDateEqualTo(end)
        .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList =
          jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map((e) => InsightGroupEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // No cached data - return empty list (will be fetched by sync service)
    return <InsightGroupEntry>[];
  }

  Future<List<InsightTotalEntry>> getNoGroup(
    String type,
    String subtype,
    DateTime start,
    DateTime end,
  ) async {
    final String noSubtype = 'no-$subtype';
    final Insights? cached = await isar.insights
        .filter()
        .insightTypeEqualTo(type)
        .insightSubtypeEqualTo(noSubtype)
        .startDateEqualTo(start)
        .endDateEqualTo(end)
        .findFirst();

    if (cached != null) {
      // Return cached data even if stale
      final List<dynamic> dataList =
          jsonDecode(cached.data) as List<dynamic>;
      return dataList
          .map((e) => InsightTotalEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // No cached data - return empty list (will be fetched by sync service)
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

    final Insights row = Insights()
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
    final List<Insights> allInsights = await isar.insights.where().findAll();
    final DateTime endDate = end ?? DateTime.now();
    final DateTime startDate = start ?? DateTime(1970);
    final List<Insights> insights = allInsights.where((insight) {
      // Check if insight date range overlaps with the given range
      return insight.startDate.isBefore(endDate) &&
          insight.endDate.isAfter(startDate);
    }).toList();

    await isar.writeTxn(() async {
      for (final Insights insight in insights) {
        insight.stale = true;
        await isar.insights.put(insight);
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
    final List<Insights> staleInsights = await isar.insights
        .filter()
        .staleEqualTo(true)
        .findAll();

    await isar.writeTxn(() async {
      for (final Insights insight in staleInsights) {
        insight.stale = false;
        insight.cachedAt = _getNow();
        await isar.insights.put(insight);
      }
    });
  }

  Future<List<Insights>> getStaleInsights() async {
    return await isar.insights
        .filter()
        .staleEqualTo(true)
        .findAll();
  }
}
