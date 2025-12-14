import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../providers/connectivity_provider.dart';
import '../services/connectivity/connectivity_status.dart';
import '../services/sync/sync_queue_manager.dart';
import '../services/sync/sync_statistics.dart';
import '../services/sync/sync_manager.dart';
import '../database/conflicts_table.dart';

/// Dashboard widget showing sync status and health.
///
/// Features:
/// - Sync health indicator (good, warning, error)
/// - Queue count display
/// - Last sync time
/// - Tap action to open sync status screen
/// - Conflicts requiring attention
/// - Material 3 card design
class DashboardSyncStatus extends StatelessWidget {
  static final Logger _logger = Logger('DashboardSyncStatus');

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback when "Sync Now" is tapped
  final VoidCallback? onSyncNow;

  const DashboardSyncStatus({
    super.key,
    this.onTap,
    this.onSyncNow,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final status = connectivityProvider.status;
        final isSyncing = connectivityProvider.isSyncing;

        return FutureBuilder<Map<String, dynamic>>(
          future: _loadSyncData(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final data = snapshot.data!;
            final queueCount = data['queueCount'] as int;
            final conflictCount = data['conflictCount'] as int;
            final lastSyncTime = data['lastSyncTime'] as DateTime?;
            final syncHealth = _getSyncHealth(status, queueCount, conflictCount);

            return Card(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Icon(
                            _getHealthIcon(syncHealth),
                            color: _getHealthColor(context, syncHealth),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Sync Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          if (status == ConnectivityStatus.online && !isSyncing)
                            IconButton(
                              icon: const Icon(Icons.sync),
                              onPressed: onSyncNow,
                              tooltip: 'Sync Now',
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Status message
                      Text(
                        _getStatusMessage(status, isSyncing, queueCount, conflictCount),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),

                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatItem(
                              context,
                              'Pending',
                              queueCount.toString(),
                              Icons.schedule,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              'Conflicts',
                              conflictCount.toString(),
                              Icons.warning_amber,
                            ),
                          ),
                          Expanded(
                            child: _buildStatItem(
                              context,
                              'Last Sync',
                              _formatLastSync(lastSyncTime),
                              Icons.access_time,
                            ),
                          ),
                        ],
                      ),

                      // Conflict warning
                      if (conflictCount > 0) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning,
                                size: 16,
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '$conflictCount conflict${conflictCount == 1 ? '' : 's'} need${conflictCount == 1 ? 's' : ''} attention',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
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

  Future<Map<String, dynamic>> _loadSyncData() async {
    try {
      final queueManager = SyncQueueManager();
      final conflictsTable = ConflictsTable();
      final statistics = SyncStatistics();

      final operations = await queueManager.getPendingOperations();
      final conflicts = await conflictsTable.getUnresolvedConflicts();
      final stats = await statistics.getStatistics();

      return {
        'queueCount': operations.length,
        'conflictCount': conflicts.length,
        'lastSyncTime': stats['lastSyncTime'] as DateTime?,
      };
    } catch (e, stackTrace) {
      _logger.warning('Failed to load sync data', e, stackTrace);
      return {
        'queueCount': 0,
        'conflictCount': 0,
        'lastSyncTime': null,
      };
    }
  }

  String _getSyncHealth(
    ConnectivityStatus status,
    int queueCount,
    int conflictCount,
  ) {
    if (conflictCount > 0) return 'error';
    if (status == ConnectivityStatus.offline && queueCount > 10) return 'warning';
    if (queueCount > 0) return 'warning';
    return 'good';
  }

  IconData _getHealthIcon(String health) {
    switch (health) {
      case 'good':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning_amber;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getHealthColor(BuildContext context, String health) {
    switch (health) {
      case 'good':
        return Theme.of(context).colorScheme.tertiary;
      case 'warning':
        return Theme.of(context).colorScheme.tertiary;
      case 'error':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.onSurface;
    }
  }

  String _getStatusMessage(
    ConnectivityStatus status,
    bool isSyncing,
    int queueCount,
    int conflictCount,
  ) {
    if (isSyncing) {
      return 'Syncing data...';
    }

    if (conflictCount > 0) {
      return 'Conflicts detected - action required';
    }

    if (status == ConnectivityStatus.offline) {
      if (queueCount > 0) {
        return 'Offline - $queueCount operation${queueCount == 1 ? '' : 's'} queued';
      }
      return 'Offline - no pending operations';
    }

    if (queueCount > 0) {
      return '$queueCount operation${queueCount == 1 ? '' : 's'} pending sync';
    }

    return 'All data synced';
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Never';

    final now = DateTime.now();
    final diff = now.difference(lastSync);

    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${lastSync.day}/${lastSync.month}';
  }
}
