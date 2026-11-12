import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/pages/home/transactions/running_balance.dart';
import 'package:waterflyiii/settings.dart';

void main() {
  final DateTime now = DateTime(2026, 11, 12);

  test('window start follows the date filter', () {
    expect(
      transactionWindowStart(TransactionDateFilter.currentMonth, now),
      DateTime(2026, 11, 1),
    );
    expect(
      transactionWindowStart(TransactionDateFilter.currentYear, now),
      DateTime(2026, 1, 1),
    );
    expect(
      transactionWindowStart(TransactionDateFilter.last30Days, now),
      now.subtract(const Duration(days: 30)),
    );
    expect(
      transactionWindowStart(TransactionDateFilter.lastYear, now),
      DateTime(2025, 11, 12),
    );
    expect(
      transactionWindowStart(TransactionDateFilter.all, now),
      DateTime.fromMillisecondsSinceEpoch(365 * 24 * 60 * 60 * 1000),
    );
  });

  test('chart series start at zero on their earliest date', () {
    final ChartDataSet set = ChartDataSet.fromJson(<String, dynamic>{
      'label': 'Checking',
      'entries': <String, dynamic>{
        '2026-11-02T00:00:00+00:00': '150',
        '2026-11-01T00:00:00+00:00': '100',
        '2026-11-03T00:00:00+00:00': '80.5',
      },
    });
    final ChartDataSet out = rebaseChartDataSets(<ChartDataSet>[set]).single;
    final Map<String, dynamic> entries = out.entries as Map<String, dynamic>;
    expect(out.label, 'Checking');
    expect(double.parse(entries['2026-11-01T00:00:00+00:00'] as String), 0);
    expect(double.parse(entries['2026-11-02T00:00:00+00:00'] as String), 50);
    expect(double.parse(entries['2026-11-03T00:00:00+00:00'] as String), -19.5);
  });

  test('monthly series start at zero on the first month', () {
    final Map<DateTime, double> out = rebaseMonthlySeries(<DateTime, double>{
      DateTime(2026, 1): 10,
      DateTime(2026, 2): 25,
      DateTime(2026, 3): 5,
    });
    expect(out.values.toList(), <double>[0, 15, -5]);
    expect(rebaseMonthlySeries(<DateTime, double>{}), isEmpty);
  });
}
