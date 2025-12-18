import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';

/// Helper for enhancing list views with offline mode features.
///
/// Features:
/// - Filter for sync status
/// - Sync indicator on each item
/// - Pull-to-refresh for manual sync
/// - Loading state during sync
/// - Real-time list updates as items sync
/// - Empty state for offline mode
class ListViewOfflineHelper {
  static final Logger _logger = Logger('ListViewOfflineHelper');

  /// Build filter chip for sync status
  static Widget buildSyncStatusFilter({
    required BuildContext context,
    required String currentFilter,
    required Function(String) onFilterChanged,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          _buildFilterChip(
            context: context,
            label: S.of(context).generalDateRangeAll,
            value: 'all',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: S.of(context).syncStatusSynced,
            value: 'synced',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
            icon: Icons.cloud_done,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: S.of(context).listViewOfflineFilterPending,
            value: 'pending',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
            icon: Icons.cloud_queue,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: S.of(context).syncStatusFailed,
            value: 'failed',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
            icon: Icons.error_outline,
          ),
        ],
      ),
    );
  }

  static Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required String value,
    required String currentFilter,
    required Function(String) onSelected,
    IconData? icon,
  }) {
    final bool isSelected = currentFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) {
          onSelected(value);
        }
      },
    );
  }

  /// Build pull-to-refresh wrapper
  static Widget buildPullToRefresh({
    required BuildContext context,
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }

  /// Build syncing overlay
  static Widget? buildSyncingOverlay({
    required BuildContext context,
    required bool isSyncing,
    required int syncedCount,
    required int totalCount,
  }) {
    if (!isSyncing) {
      return null;
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  S.of(context).syncStatusSyncingCount(syncedCount, totalCount),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build empty state for offline mode
  static Widget buildOfflineEmptyState({
    required BuildContext context,
    required String entityType,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              S.of(context).listViewOfflineNoDataAvailable(entityType),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              S.of(context).listViewOfflineNoDataMessage(entityType),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build list item with sync status
  static Widget buildListItemWithSyncStatus({
    required BuildContext context,
    required Widget child,
    required bool isSynced,
    required bool isSyncing,
    required bool hasSyncError,
  }) {
    Color? backgroundColor;

    if (!isSynced) {
      if (hasSyncError) {
        backgroundColor = Theme.of(
          context,
        ).colorScheme.errorContainer.withOpacity(0.05);
      } else if (isSyncing) {
        backgroundColor = Theme.of(
          context,
        ).colorScheme.primaryContainer.withOpacity(0.05);
      } else {
        backgroundColor = Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.1);
      }
    }

    if (backgroundColor == null) {
      return child;
    }

    return Container(color: backgroundColor, child: child);
  }

  /// Build last updated indicator
  static Widget buildLastUpdatedIndicator({
    required BuildContext context,
    required DateTime lastUpdated,
  }) {
    final Duration age = DateTime.now().difference(lastUpdated);
    final String ageText = _formatAge(age, context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.access_time,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            S.of(context).listViewOfflineLastUpdated(ageText),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle pull-to-refresh sync
  static Future<void> handlePullToRefresh(BuildContext context) async {
    _logger.info('Pull-to-refresh triggered');

    try {
      final SyncStatusProvider syncStatusProvider =
          Provider.of<SyncStatusProvider>(context, listen: false);

      await syncStatusProvider.syncManager.synchronize(fullSync: false);

      _logger.info('Pull-to-refresh sync completed');
    } catch (e, stackTrace) {
      // Check if it's a ProviderNotFoundException (by checking error message)
      final String errorStr = e.toString();
      if (errorStr.contains('ProviderNotFoundException') ||
          errorStr.contains('Could not find the correct Provider') ||
          errorStr.contains('SyncStatusProvider')) {
        _logger.warning('SyncStatusProvider not found: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).syncServiceNotAvailable),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
      _logger.severe('Pull-to-refresh sync failed', e, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).generalSyncFailed(e.toString())),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static String _formatAge(Duration age, BuildContext context) {
    final S localizations = S.of(context);
    if (age.inMinutes < 1) return localizations.syncStatusJustNow;
    if (age.inHours < 1) return localizations.syncStatusMinutesAgo(age.inMinutes);
    if (age.inDays < 1) return localizations.syncStatusHoursAgo(age.inHours);
    return localizations.syncStatusDaysAgo(age.inDays);
  }
}
