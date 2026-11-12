import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/settings.dart' show TransactionDateFilter;

/// Change that [item] applies to the balance of [accountId].
double transactionBalanceEffect(TransactionRead item, String accountId) {
  double effect = 0;
  for (final TransactionSplit tx in item.attributes.transactions) {
    final double amount = double.tryParse(tx.amount) ?? 0.0;
    if (amount == 0.0) {
      continue;
    }
    if (tx.type == TransactionTypeProperty.withdrawal) {
      effect -= amount;
    } else if (tx.type == TransactionTypeProperty.transfer) {
      effect += tx.destinationId == accountId ? amount : -amount;
    } else {
      effect += amount;
    }
  }
  return effect;
}

/// Balance after the newest row when the balance is zero before the oldest.
double windowBalanceTotal(Iterable<TransactionRead> items, String accountId) =>
    items.fold(
      0.0,
      (double sum, TransactionRead item) =>
          sum + transactionBalanceEffect(item, accountId),
    );

/// First day counted by the transaction date filter.
DateTime transactionWindowStart(TransactionDateFilter filter, DateTime now) {
  switch (filter) {
    case TransactionDateFilter.currentMonth:
      return now.copyWith(day: 1);
    case TransactionDateFilter.currentYear:
      return now.copyWith(month: 1, day: 1);
    case TransactionDateFilter.last30Days:
      return now.subtract(const Duration(days: 30));
    case TransactionDateFilter.lastYear:
      return now.copyWith(year: now.year - 1);
    default:
      // Don't use 0 seconds, as DST & stuff might throw an error:
      // "The start must be a date after 1970-01-02."
      return DateTime.fromMillisecondsSinceEpoch(365 * 24 * 60 * 60 * 1000);
  }
}

/// Every series minus its value on its earliest date, so each starts at zero.
List<ChartDataSet> rebaseChartDataSets(List<ChartDataSet> sets) =>
    sets.map(_rebaseChartDataSet).toList();

ChartDataSet _rebaseChartDataSet(ChartDataSet set) {
  final Object? raw = set.entries;
  if (raw is! Map || raw.isEmpty) {
    return set;
  }
  final List<MapEntry<dynamic, dynamic>> items = raw.entries.toList();
  MapEntry<dynamic, dynamic> first = items.first;
  DateTime? firstDate = DateTime.tryParse(first.key.toString());
  for (final MapEntry<dynamic, dynamic> item in items) {
    final DateTime? date = DateTime.tryParse(item.key.toString());
    if (date != null && (firstDate == null || date.isBefore(firstDate))) {
      first = item;
      firstDate = date;
    }
  }
  final double base = double.tryParse(first.value.toString()) ?? 0;
  final Map<String, dynamic> rebased = <String, dynamic>{
    for (final MapEntry<dynamic, dynamic> item in items)
      item.key.toString():
          ((double.tryParse(item.value.toString()) ?? 0) - base).toString(),
  };
  final Map<String, dynamic> json = set.toJson();
  json['entries'] = rebased;
  return ChartDataSet.fromJson(json);
}

/// Monthly totals minus the earliest month, so the series starts at zero.
Map<DateTime, double> rebaseMonthlySeries(Map<DateTime, double> series) {
  if (series.isEmpty) {
    return series;
  }
  final DateTime firstKey = series.keys.reduce(
    (DateTime a, DateTime b) => a.isBefore(b) ? a : b,
  );
  final double base = series[firstKey]!;
  return Map<DateTime, double>.fromEntries(
    series.entries.map(
      (MapEntry<DateTime, double> e) =>
          MapEntry<DateTime, double>(e.key, e.value - base),
    ),
  );
}
