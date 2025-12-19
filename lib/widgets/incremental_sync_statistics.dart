import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';

/// A comprehensive statistics display widget for incremental sync performance.
///
/// This widget displays:
/// - Total items fetched, updated, and skipped
/// - Skip rate and update rate percentages
/// - Bandwidth saved (formatted as B/KB/MB/GB)
/// - API calls saved
/// - Sync count
/// - Efficiency indicators
///
/// ## Display Modes
///
/// - **Card Mode:** Full statistics card with all details
/// - **Compact Mode:** Condensed view for embedding in other widgets
/// - **Summary Mode:** Single-line summary for dashboards
///
/// ## Example Usage
///
/// ```dart
/// // Full card display
/// IncrementalSyncStatisticsWidget(
///   mode: IncrementalSyncStatisticsMode.card,
/// )
///
/// // Compact display
/// IncrementalSyncStatisticsWidget(
///   mode: IncrementalSyncStatisticsMode.compact,
/// )
///
/// // With live sync result
/// IncrementalSyncStatisticsWidget(
///   mode: IncrementalSyncStatisticsMode.card,
///   liveResult: currentSyncResult,
/// )
/// ```
class IncrementalSyncStatisticsWidget extends StatelessWidget {
  const IncrementalSyncStatisticsWidget({
    super.key,
    this.mode = IncrementalSyncStatisticsMode.card,
    this.liveResult,
    this.showHeader = true,
    this.onRefresh,
  });

  /// Display mode for the statistics.
  final IncrementalSyncStatisticsMode mode;

  /// Live sync result to display (overrides provider data).
  final IncrementalSyncResult? liveResult;

  /// Whether to show the section header.
  final bool showHeader;

  /// Callback when refresh is requested.
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSettingsProvider>(
      builder: (
        BuildContext context,
        OfflineSettingsProvider settings,
        Widget? child,
      ) {
        switch (mode) {
          case IncrementalSyncStatisticsMode.card:
            return _buildCard(context, settings);
          case IncrementalSyncStatisticsMode.compact:
            return _buildCompact(context, settings);
          case IncrementalSyncStatisticsMode.summary:
            return _buildSummary(context, settings);
        }
      },
    );
  }

  /// Build full card display mode.
  Widget _buildCard(BuildContext context, OfflineSettingsProvider settings) {
    final bool hasData =
        liveResult != null ||
        settings.totalItemsFetched > 0 ||
        settings.incrementalSyncCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showHeader) ...<Widget>[
              _buildHeader(context, settings),
              const SizedBox(height: 16),
            ],
            if (!hasData)
              _buildEmptyState(context)
            else ...<Widget>[
              _buildEfficiencyIndicator(context, settings),
              const SizedBox(height: 16),
              _buildMainStats(context, settings),
              const SizedBox(height: 16),
              _buildSecondaryStats(context, settings),
              if (liveResult != null) ...<Widget>[
                const Divider(height: 24),
                _buildLiveResultDetails(context),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Build compact display mode.
  Widget _buildCompact(BuildContext context, OfflineSettingsProvider settings) {
    final double skipRate =
        liveResult?.overallSkipRate ?? settings.overallSkipRate;
    final String bandwidthSaved =
        liveResult?.bandwidthSavedFormatted ?? settings.formattedBandwidthSaved;
    final bool hasData = liveResult != null || settings.totalItemsFetched > 0;

    if (!hasData) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline, size: 18),
            const SizedBox(width: 8),
            Text(
              S.of(context).incrementalSyncStatsNoDataYet,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildCompactStatItem(
            context,
            icon: Icons.speed,
            value: '${skipRate.toStringAsFixed(0)}%',
            label: S.of(context).incrementalSyncStatsLabelSkipped,
            color: _getEfficiencyColor(skipRate),
          ),
          _buildCompactStatItem(
            context,
            icon: Icons.data_saver_on,
            value: bandwidthSaved,
            label: S.of(context).incrementalSyncStatsLabelSaved,
            color: Colors.blue,
          ),
          _buildCompactStatItem(
            context,
            icon: Icons.sync,
            value: '${settings.incrementalSyncCount}',
            label: S.of(context).incrementalSyncStatsLabelSyncs,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  /// Build summary display mode (single line).
  Widget _buildSummary(BuildContext context, OfflineSettingsProvider settings) {
    final double skipRate =
        liveResult?.overallSkipRate ?? settings.overallSkipRate;
    final String bandwidthSaved =
        liveResult?.bandwidthSavedFormatted ?? settings.formattedBandwidthSaved;
    final bool hasData = liveResult != null || settings.totalItemsFetched > 0;

    if (!hasData) {
      return Text(
        S.of(context).incrementalSyncStatsNoDataAvailable,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.speed, size: 16, color: _getEfficiencyColor(skipRate)),
        const SizedBox(width: 4),
        Text(
          S
              .of(context)
              .incrementalSyncStatsEfficient(skipRate.toStringAsFixed(0)),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _getEfficiencyColor(skipRate),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(Icons.data_saver_on, size: 16, color: Colors.blue),
        const SizedBox(width: 4),
        Text(
          bandwidthSaved,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build section header.
  Widget _buildHeader(BuildContext context, OfflineSettingsProvider settings) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.analytics,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                S.of(context).incrementalSyncStatsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                settings.incrementalSyncCount > 0
                    ? S
                        .of(context)
                        .incrementalSyncStatsDescription(
                          settings.incrementalSyncCount,
                        )
                    : S.of(context).incrementalSyncStatsDescriptionEmpty,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            tooltip: S.of(context).incrementalSyncStatsRefresh,
          ),
      ],
    );
  }

  /// Build empty state when no data is available.
  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        children: <Widget>[
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            S.of(context).incrementalSyncStatsNoData,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            S.of(context).incrementalSyncStatsNoDataDesc,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build efficiency indicator gauge.
  Widget _buildEfficiencyIndicator(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    final double skipRate =
        liveResult?.overallSkipRate ?? settings.overallSkipRate;
    final Color color = _getEfficiencyColor(skipRate);
    final String label = _getEfficiencyLabel(skipRate, context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                CircularProgressIndicator(
                  value: skipRate / 100.0,
                  strokeWidth: 8,
                  backgroundColor: color.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${skipRate.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _getEfficiencyDescription(skipRate, context),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build main statistics grid.
  Widget _buildMainStats(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.download,
            value: _formatNumber(
              liveResult?.totalFetched ?? settings.totalItemsFetched,
            ),
            label: S.of(context).incrementalSyncStatsLabelFetched,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.edit,
            value: _formatNumber(
              liveResult?.totalUpdated ?? settings.totalItemsUpdated,
            ),
            label: S.of(context).incrementalSyncStatsLabelUpdated,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            icon: Icons.skip_next,
            value: _formatNumber(
              liveResult?.totalSkipped ?? settings.totalItemsSkipped,
            ),
            label: 'Skipped',
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  /// Build secondary statistics.
  Widget _buildSecondaryStats(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          _buildSecondaryStatRow(
            context,
            icon: Icons.data_saver_on,
            label: S.of(context).incrementalSyncStatsLabelBandwidthSaved,
            value:
                liveResult?.bandwidthSavedFormatted ??
                settings.formattedBandwidthSaved,
            color: Colors.teal,
          ),
          const Divider(height: 16),
          _buildSecondaryStatRow(
            context,
            icon: Icons.api,
            label: S.of(context).incrementalSyncStatsLabelApiCallsSaved,
            value: _formatNumber(settings.totalApiCallsSaved),
            color: Colors.purple,
          ),
          const Divider(height: 16),
          _buildSecondaryStatRow(
            context,
            icon: Icons.trending_up,
            label: S.of(context).incrementalSyncStatsLabelUpdateRate,
            value:
                '${(liveResult?.overallSkipRate ?? settings.overallUpdateRate).toStringAsFixed(1)}%',
            color: Colors.amber,
          ),
        ],
      ),
    );
  }

  /// Build live result details section.
  Widget _buildLiveResultDetails(BuildContext context) {
    if (liveResult == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          S.of(context).incrementalSyncStatsCurrentSync,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          S
              .of(context)
              .incrementalSyncStatsDuration(
                _formatDuration(liveResult!.duration),
              ),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          liveResult!.success
              ? S.of(context).incrementalSyncStatsStatusSuccess
              : S.of(context).incrementalSyncStatsStatusFailed,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: liveResult!.success ? Colors.green : Colors.red,
          ),
        ),
        if (liveResult!.error != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            S.of(context).incrementalSyncStatsError(liveResult!.error!),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.red),
          ),
        ],
        if (liveResult!.statsByEntity.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            S.of(context).incrementalSyncStatsByEntityType,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ...liveResult!.statsByEntity.entries.map((
            MapEntry<String, IncrementalSyncStats> entry,
          ) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  _getEntityIcon(entry.key),
                  const SizedBox(width: 8),
                  Text(
                    _formatEntityType(entry.key),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.itemsUpdated}/${entry.value.itemsFetched}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Build a compact stat item.
  Widget _buildCompactStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: <Widget>[
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build a stat card.
  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a secondary stat row.
  Widget _buildSecondaryStatRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Get efficiency color based on skip rate.
  Color _getEfficiencyColor(double skipRate) {
    if (skipRate >= 80) return Colors.green;
    if (skipRate >= 60) return Colors.lightGreen;
    if (skipRate >= 40) return Colors.amber;
    if (skipRate >= 20) return Colors.orange;
    return Colors.red;
  }

  /// Get efficiency label based on skip rate.
  String _getEfficiencyLabel(double skipRate, BuildContext context) {
    final S localizations = S.of(context);
    if (skipRate >= 80)
      return localizations.incrementalSyncStatsEfficiencyExcellent;
    if (skipRate >= 60) return localizations.incrementalSyncStatsEfficiencyGood;
    if (skipRate >= 40)
      return localizations.incrementalSyncStatsEfficiencyModerate;
    if (skipRate >= 20) return localizations.incrementalSyncStatsEfficiencyLow;
    return localizations.incrementalSyncStatsEfficiencyVeryLow;
  }

  /// Get efficiency description based on skip rate.
  String _getEfficiencyDescription(double skipRate, BuildContext context) {
    final S localizations = S.of(context);
    if (skipRate >= 80) {
      return localizations.incrementalSyncStatsEfficiencyDescExcellent;
    }
    if (skipRate >= 60) {
      return localizations.incrementalSyncStatsEfficiencyDescGood;
    }
    if (skipRate >= 40) {
      return localizations.incrementalSyncStatsEfficiencyDescModerate;
    }
    if (skipRate >= 20) {
      return localizations.incrementalSyncStatsEfficiencyDescLow;
    }
    return localizations.incrementalSyncStatsEfficiencyDescVeryLow;
  }

  /// Format a large number with K/M suffix.
  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    }
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  /// Format duration for display.
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    }
    return '${duration.inSeconds}s';
  }

  /// Format entity type for display.
  String _formatEntityType(String entityType) {
    return entityType[0].toUpperCase() +
        entityType.substring(1).replaceAll('_', ' ');
  }

  /// Get icon for entity type.
  Widget _getEntityIcon(String entityType) {
    final IconData icon;
    switch (entityType.toLowerCase()) {
      case 'transaction':
        icon = Icons.receipt;
        break;
      case 'account':
        icon = Icons.account_balance;
        break;
      case 'budget':
        icon = Icons.account_balance_wallet;
        break;
      case 'category':
        icon = Icons.category;
        break;
      case 'bill':
        icon = Icons.receipt_long;
        break;
      case 'piggy_bank':
        icon = Icons.savings;
        break;
      default:
        icon = Icons.sync;
    }
    return Icon(icon, size: 16);
  }
}

/// Display mode for the statistics widget.
enum IncrementalSyncStatisticsMode {
  /// Full card with all statistics details.
  card,

  /// Compact horizontal display.
  compact,

  /// Single-line summary.
  summary,
}
