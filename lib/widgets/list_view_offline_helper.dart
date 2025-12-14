import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

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
        children: [
          _buildFilterChip(
            context: context,
            label: 'All',
            value: 'all',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Synced',
            value: 'synced',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
            icon: Icons.cloud_done,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Pending',
            value: 'pending',
            currentFilter: currentFilter,
            onSelected: onFilterChanged,
            icon: Icons.cloud_queue,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            context: context,
            label: 'Failed',
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
    final isSelected = currentFilter == value;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
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
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
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
            children: [
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
                  'Syncing... $syncedCount of $totalCount',
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
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No $entityType Available',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'You are offline. $entityType will appear here when you connect to the internet.',
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
        backgroundColor = Theme.of(context).colorScheme.errorContainer.withOpacity(0.05);
      } else if (isSyncing) {
        backgroundColor = Theme.of(context).colorScheme.primaryContainer.withOpacity(0.05);
      } else {
        backgroundColor = Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.1);
      }
    }

    if (backgroundColor == null) {
      return child;
    }

    return Container(
      color: backgroundColor,
      child: child,
    );
  }

  /// Build last updated indicator
  static Widget buildLastUpdatedIndicator({
    required BuildContext context,
    required DateTime lastUpdated,
  }) {
    final age = DateTime.now().difference(lastUpdated);
    final ageText = _formatAge(age);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Last updated $ageText',
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
      // TODO: Get SyncManager from provider/dependency injection
      // final syncManager = SyncManager(...);
      // await syncManager.synchronize();
      
      _logger.warning('Pull-to-refresh sync not implemented yet');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync not available yet'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.severe('Pull-to-refresh sync failed', e, stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  static String _formatAge(Duration age) {
    if (age.inMinutes < 1) return 'just now';
    if (age.inHours < 1) return '${age.inMinutes}m ago';
    if (age.inDays < 1) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
}
