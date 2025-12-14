import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
    final age = DateTime.now().difference(lastUpdate);
    final ageText = _formatAge(age);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: hasUnsyncedData
            ? Theme.of(context).colorScheme.tertiaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasUnsyncedData ? Icons.cloud_queue : Icons.access_time,
            size: 12,
            color: hasUnsyncedData
                ? Theme.of(context).colorScheme.onTertiaryContainer
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            hasUnsyncedData ? 'Includes unsynced data' : 'Data as of $ageText',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: hasUnsyncedData
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
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.5),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Unsynced',
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  /// Get color for unsynced data in charts
  static Color getUnsyncedDataColor(BuildContext context) {
    return Theme.of(context).colorScheme.tertiary.withOpacity(0.5);
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
        children: [
          Icon(
            Icons.cloud_off,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Viewing offline data. Some information may be outdated.',
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
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No $dataType Available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to the internet to load $dataType',
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
  static String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'just now';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    if (age.inDays < 7) return '${age.inDays}d ago';
    return '${age.inDays} days ago';
  }

  /// Check if data is stale (older than 1 hour)
  static bool isDataStale(DateTime lastUpdate) {
    final age = DateTime.now().difference(lastUpdate);
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
        children: [
          Icon(
            Icons.info_outline,
            size: 16,
            color: Theme.of(context).colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Data may be outdated. Last updated ${_formatAge(DateTime.now().difference(lastUpdate))}.',
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
