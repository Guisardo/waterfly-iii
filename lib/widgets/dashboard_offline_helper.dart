import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';

/// Helper for displaying offline data in dashboard charts.
///
/// Features:
/// - Include unsynced transactions in charts
/// - Visual distinction for unsynced data
/// - Data freshness indicator
/// - "Data as of [timestamp]" label
/// - Handle missing server data gracefully
class DashboardOfflineHelper {
  // Reserved for future logging of dashboard events
  // ignore: unused_field
  static final Logger _logger = Logger('DashboardOfflineHelper');

  /// Build data freshness indicator
  static Widget buildDataFreshnessIndicator({
    required BuildContext context,
    required DateTime lastUpdate,
    required bool hasUnsyncedData,
  }) {
    final Duration age = DateTime.now().difference(lastUpdate);
    final String ageText = _formatAge(age, context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            hasUnsyncedData
                ? Theme.of(context).colorScheme.tertiaryContainer
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            hasUnsyncedData ? Icons.cloud_queue : Icons.access_time,
            size: 12,
            color:
                hasUnsyncedData
                    ? Theme.of(context).colorScheme.onTertiaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            hasUnsyncedData
                ? S.of(context).dashboardOfflineIncludesUnsynced
                : S.of(context).dashboardOfflineDataAsOf(ageText),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color:
                  hasUnsyncedData
                      ? Theme.of(context).colorScheme.onTertiaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build unsynced data legend item for charts
  static Widget buildUnsyncedLegendItem(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          S.of(context).dashboardOfflineUnsynced,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  /// Get color for unsynced data in charts
  static Color getUnsyncedDataColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5);
  }

  /// Get border color for unsynced data in charts
  static Color getUnsyncedBorderColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary;
  }

  /// Build offline mode banner for dashboard
  static Widget buildOfflineBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.cloud_off,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              S.of(context).dashboardOfflineViewingOfflineData,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build empty state for missing server data
  static Widget buildMissingDataPlaceholder({
    required BuildContext context,
    required String dataType,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).dashboardOfflineNoDataAvailable(dataType),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).dashboardOfflineConnectToLoad(dataType),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Format age duration
  static String _formatAge(Duration age, BuildContext context) {
    final S localizations = S.of(context);
    if (age.inMinutes < 1) return localizations.syncStatusJustNow;
    if (age.inHours < 1) {
      return localizations.syncStatusMinutesAgo(age.inMinutes);
    }
    if (age.inDays < 1) return localizations.syncStatusHoursAgo(age.inHours);
    if (age.inDays < 7) return localizations.syncStatusDaysAgo(age.inDays);
    return localizations.syncStatusDaysAgo(age.inDays);
  }

  /// Check if data is stale (older than 1 hour)
  static bool isDataStale(DateTime lastUpdate) {
    final Duration age = DateTime.now().difference(lastUpdate);
    return age.inHours >= 1;
  }

  /// Build stale data warning
  static Widget? buildStaleDataWarning(
    BuildContext context,
    DateTime lastUpdate,
  ) {
    if (!isDataStale(lastUpdate)) {
      return null;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              S
                  .of(context)
                  .dashboardOfflineDataOutdated(
                    _formatAge(DateTime.now().difference(lastUpdate), context),
                  ),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
