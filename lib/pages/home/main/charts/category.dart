import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:waterflyiii/animations.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.swagger.dart';
import 'package:waterflyiii/pages/home/transactions.dart';
import 'package:waterflyiii/pages/home/transactions/filter.dart';
import 'package:waterflyiii/widgets/charts.dart';

class CategoryChart extends StatelessWidget {
  const CategoryChart({super.key, required this.data});

  final List<InsightGroupEntry> data;

  @override
  Widget build(BuildContext context) {
    List<LabelAmountChart> chartData = <LabelAmountChart>[];

    for (InsightGroupEntry e in data) {
      if ((e.name?.isEmpty ?? true) || e.differenceFloat == 0) {
        continue;
      }
      chartData.add(LabelAmountChart(e.name!, e.differenceFloat ?? 0));
    }

    chartData.sort(
      (LabelAmountChart a, LabelAmountChart b) => a.amount.compareTo(b.amount),
    );

    if (data.length > 5) {
      final LabelAmountChart otherData = chartData
          .skip(5)
          .reduce(
            (LabelAmountChart v, LabelAmountChart e) =>
                LabelAmountChart(S.of(context).catOther, v.amount + e.amount),
          );
      chartData = chartData.take(5).toList();

      if (otherData.amount != 0) {
        chartData.add(otherData);
      }
    }

    // Show placeholder if no data
    if (chartData.isEmpty) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SizedBox(
            width: constraints.maxWidth > 0
                ? constraints.maxWidth
                : double.infinity,
            height: constraints.maxHeight.isFinite && constraints.maxHeight > 0
                ? constraints.maxHeight
                : 175.0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  S.of(context).homeTransactionsEmpty,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      );
    }

    return Padding(
      padding: const .only(left: 12),
      child: SfCircularChart(
        legend: Legend(
          isVisible: true,
          position: .right,
          itemPadding: 4,
          textStyle: Theme.of(context).textTheme.labelLarge!.copyWith(
            fontWeight: .normal,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          alignment: .center,
          isResponsive: false,
        ),
        series: <CircularSeries<LabelAmountChart, String>>[
          PieSeries<LabelAmountChart, String>(
            dataSource: chartData,
            xValueMapper: (LabelAmountChart data, _) => data.label,
            yValueMapper: (LabelAmountChart data, _) => data.amount.abs(),
            dataLabelMapper: (LabelAmountChart data, _) =>
                data.amount.abs().toStringAsFixed(0),
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
                fontWeight: .normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              connectorLineSettings: ConnectorLineSettings(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            onPointTap: (ChartPointDetails pid) {
              if (pid.pointIndex == null ||
                  pid.dataPoints == null ||
                  pid.dataPoints![pid.pointIndex!] == null) {
                return;
              }
              final ChartPoint<String> chart = pid.dataPoints![pid.pointIndex!];
              final InsightGroupEntry category = data.firstWhere(
                (InsightGroupEntry e) => e.name == chart.x,
                orElse: () => const InsightGroupEntry(),
              );
              // Filters out the "other" category, if the user has none made himself
              if (category.name == null || category.id == null) {
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute<bool>(
                  builder: (BuildContext context) => Scaffold(
                    appBar: AppBar(title: Text(category.name!)),
                    body: HomeTransactions(
                      filters: TransactionFilters(
                        category: CategoryRead(
                          id: category.id!,
                          type: "filter-category",
                          attributes: CategoryProperties(name: category.name!),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            animationDuration:
                animDurationEmphasized.inMilliseconds.toDouble() * 2,
          ),
        ],
        palette: possibleChartColorsDart,
        margin: .zero,
      ),
    );
  }
}
