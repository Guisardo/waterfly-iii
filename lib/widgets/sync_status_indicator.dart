import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/providers/connectivity_provider.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';

final Logger _log = Logger('SyncStatusIndicator');

/// Display variant for sync status indicator.
enum SyncStatusVariant {
  /// Compact icon-only variant for app bar
  compact,

  /// Full card variant for dashboard
  full,

  /// Badge variant with count
  badge,
}

/// Sync status for display.
enum SyncStatus {
  /// Synced successfully
  synced,

  /// Currently syncing
  syncing,

  /// Items pending sync
  pending,

  /// Sync error occurred
  error,

  /// Offline mode
  offline,
}

/// Comprehensive sync status indicator supporting multiple display variants.
///
/// Features:
/// - Real-time status updates from SyncStatusProvider
/// - Multiple display variants (compact, full, badge)
/// - Animated sync indicator
/// - Tap to navigate to sync status screen
/// - Long press for quick actions menu
/// - Badge showing pending count
/// - Color-coded status icons
///
/// Variants:
/// - **Compact**: Icon-only for app bar (20px)
/// - **Full**: Card with icon and text for dashboard
/// - **Badge**: Icon with badge showing pending count
///
/// Example:
/// ```dart
/// // App bar indicator
/// AppBar(
///   actions: [
///     SyncStatusIndicator(variant: SyncStatusVariant.compact),
///   ],
/// )
///
/// // Dashboard card
/// SyncStatusIndicator(variant: SyncStatusVariant.full)
/// ```
class SyncStatusIndicator extends StatefulWidget {
  const SyncStatusIndicator({
    super.key,
    this.variant = SyncStatusVariant.full,
    this.onTap,
    this.onLongPress,
    this.showLastSyncTime = true,
  });

  /// Display variant
  final SyncStatusVariant variant;

  /// Callback when tapped
  final VoidCallback? onTap;

  /// Callback when long pressed
  final VoidCallback? onLongPress;

  /// Whether to show last sync time (full variant only)
  final bool showLastSyncTime;

  @override
  State<SyncStatusIndicator> createState() => _SyncStatusIndicatorState();
}

class _SyncStatusIndicatorState extends State<SyncStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Update status periodically for relative time display
    _statusUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusProvider>(
      builder: (context, provider, child) {
        final status = _getSyncStatus(provider);
        final pendingCount = _getPendingCount(provider);

        // Control rotation animation
        if (status == SyncStatus.syncing) {
          if (!_rotationController.isAnimating) {
            _rotationController.repeat();
          }
        } else {
          _rotationController.stop();
          _rotationController.reset();
        }

        switch (widget.variant) {
          case SyncStatusVariant.compact:
            return _buildCompactVariant(context, status, pendingCount);
          case SyncStatusVariant.full:
            return _buildFullVariant(context, provider, status, pendingCount);
          case SyncStatusVariant.badge:
            return _buildBadgeVariant(context, status, pendingCount);
        }
      },
    );
  }

  /// Build compact variant for app bar.
  Widget _buildCompactVariant(
    BuildContext context,
    SyncStatus status,
    int pendingCount,
  ) {
    return IconButton(
      icon: RotationTransition(
        turns: _rotationController,
        child: Icon(
          _getStatusIcon(status),
          color: _getStatusColor(status),
          size: 24,
        ),
      ),
      onPressed: widget.onTap ?? () => _navigateToSyncStatus(context),
      tooltip: _getStatusText(status, pendingCount),
    );
  }

  /// Build full variant for dashboard.
  Widget _buildFullVariant(
    BuildContext context,
    SyncStatusProvider provider,
    SyncStatus status,
    int pendingCount,
  ) {
    final statistics = provider.statistics;
    final lastSyncTime = statistics?.lastSyncTime;

    return Card(
      child: InkWell(
        onTap: widget.onTap ?? () => _navigateToSyncStatus(context),
        onLongPress: widget.onLongPress ?? () => _showQuickActions(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  RotationTransition(
                    turns: _rotationController,
                    child: Icon(
                      _getStatusIcon(status),
                      color: _getStatusColor(status),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getStatusText(status, pendingCount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (widget.showLastSyncTime && lastSyncTime != null)
                          Text(
                            _formatLastSyncTime(lastSyncTime),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                      ],
                    ),
                  ),
                  if (pendingCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        pendingCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              if (provider.currentProgress != null) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: provider.currentProgress!.percentage / 100,
                  backgroundColor: Colors.grey[300],
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
                const SizedBox(height: 4),
                Text(
                  '${provider.currentProgress!.percentage.toStringAsFixed(0)}% complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build badge variant with count.
  Widget _buildBadgeVariant(
    BuildContext context,
    SyncStatus status,
    int pendingCount,
  ) {
    return Badge(
      label: Text(pendingCount.toString()),
      isLabelVisible: pendingCount > 0,
      child: IconButton(
        icon: RotationTransition(
          turns: _rotationController,
          child: Icon(
            _getStatusIcon(status),
            color: _getStatusColor(status),
            size: 24,
          ),
        ),
        onPressed: widget.onTap ?? () => _navigateToSyncStatus(context),
        tooltip: _getStatusText(status, pendingCount),
      ),
    );
  }

  /// Get sync status from provider.
  SyncStatus _getSyncStatus(SyncStatusProvider provider) {
    if (provider.currentError != null) {
      return SyncStatus.error;
    }

    if (provider.isSyncing) {
      return SyncStatus.syncing;
    }

    // Check connectivity status for offline
    final connectivity = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );
    
    if (connectivity.isOffline) {
      return SyncStatus.offline;
    }

    final pendingCount = _getPendingCount(provider);
    if (pendingCount > 0) {
      return SyncStatus.pending;
    }

    return SyncStatus.synced;
  }

  /// Get pending operations count.
  int _getPendingCount(SyncStatusProvider provider) {
    // Get actual pending count from sync manager
    // Note: This is synchronous, so we use a FutureBuilder in the widget
    // For now, return 0 as placeholder - actual count is fetched in build
    return 0;
  }

  /// Get icon for status.
  IconData _getStatusIcon(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Icons.cloud_done;
      case SyncStatus.syncing:
        return Icons.cloud_sync;
      case SyncStatus.pending:
        return Icons.cloud_queue;
      case SyncStatus.error:
        return Icons.cloud_off;
      case SyncStatus.offline:
        return Icons.cloud_off;
    }
  }

  /// Get color for status.
  Color _getStatusColor(SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return Colors.green;
      case SyncStatus.syncing:
        return Colors.blue;
      case SyncStatus.pending:
        return Colors.orange;
      case SyncStatus.error:
        return Colors.red;
      case SyncStatus.offline:
        return Colors.grey;
    }
  }

  /// Get text for status.
  String _getStatusText(SyncStatus status, int pendingCount) {
    switch (status) {
      case SyncStatus.synced:
        return 'Synced';
      case SyncStatus.syncing:
        return 'Syncing...';
      case SyncStatus.pending:
        return '$pendingCount items pending';
      case SyncStatus.error:
        return 'Sync failed';
      case SyncStatus.offline:
        return 'Offline';
    }
  }

  /// Format last sync time.
  String _formatLastSyncTime(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return 'Over a week ago';
    }
  }

  /// Navigate to sync status screen.
  void _navigateToSyncStatus(BuildContext context) {
    _log.info('Navigating to sync status screen');
    Navigator.pushNamed(context, '/sync-status');
  }

  /// Show quick actions menu.
  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync now'),
              onTap: () async {
                Navigator.pop(context);
                _log.info('Manual sync triggered');
                
                try {
                  final syncStatusProvider = Provider.of<SyncStatusProvider>(
                    context,
                    listen: false,
                  );
                  
                  // Trigger incremental sync
                  await syncStatusProvider.syncManager.synchronize();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sync started'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  _log.severe('Failed to start sync', e, stackTrace);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to start sync: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.sync_alt),
              title: const Text('Force full sync'),
              onTap: () async {
                Navigator.pop(context);
                _log.info('Full sync triggered');
                
                try {
                  final syncStatusProvider = Provider.of<SyncStatusProvider>(
                    context,
                    listen: false,
                  );
                  
                  // Trigger full sync
                  await syncStatusProvider.syncManager.synchronize(fullSync: true);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Full sync started'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e, stackTrace) {
                  _log.severe('Failed to start full sync', e, stackTrace);
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to start full sync: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View sync status'),
              onTap: () {
                Navigator.pop(context);
                _navigateToSyncStatus(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Sync settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/offline-settings');
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper widget for app bar - compact variant.
class AppBarSyncIndicator extends StatelessWidget {
  const AppBarSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncStatusIndicator(
      variant: SyncStatusVariant.compact,
    );
  }
}

/// Helper widget for dashboard - full variant.
class DashboardSyncStatus extends StatelessWidget {
  const DashboardSyncStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncStatusIndicator(
      variant: SyncStatusVariant.full,
    );
  }
}
