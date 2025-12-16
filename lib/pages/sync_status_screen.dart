import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/models/sync_progress.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';
import 'package:waterflyiii/services/sync/sync_statistics.dart';

/// Comprehensive sync status screen with real-time updates.
///
/// Features:
/// - Real-time sync status display
/// - Sync history list (last 20 syncs)
/// - Entity-specific statistics
/// - Conflict list
/// - Error list
/// - Pull-to-refresh
/// - Detailed sync result view
///
/// Uses Provider for state management and automatically updates during sync.
class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Status'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const <Widget>[
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 20)),
            Tab(text: 'History', icon: Icon(Icons.history, size: 20)),
            Tab(text: 'Conflicts', icon: Icon(Icons.warning_amber, size: 20)),
            Tab(text: 'Errors', icon: Icon(Icons.error, size: 20)),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(context),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<SyncStatusProvider>(
        builder: (BuildContext context, SyncStatusProvider provider, Widget? child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () => provider.refresh(),
            child: TabBarView(
              controller: _tabController,
              children: <Widget>[
                _buildOverviewTab(context, provider),
                _buildHistoryTab(context, provider),
                _buildConflictsTab(context, provider),
                _buildErrorsTab(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build overview tab with current status and statistics.
  Widget _buildOverviewTab(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: <Widget>[
        _buildCurrentStatusCard(context, provider),
        const SizedBox(height: 16),
        _buildStatisticsCard(context, provider),
        const SizedBox(height: 16),
        _buildEntityStatsCard(context, provider),
      ],
    );
  }

  /// Build current status card.
  Widget _buildCurrentStatusCard(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    final SyncProgress? progress = provider.currentProgress;
    final bool isSyncing = provider.isSyncing;
    final String? error = provider.currentError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  _getSyncStatusIcon(isSyncing, error),
                  color: _getSyncStatusColor(isSyncing, error),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _getSyncStatusText(isSyncing, error),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (progress != null)
                        Text(
                          _getProgressText(progress),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (progress != null) ...<Widget>[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress.percentage / 100,
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    '${progress.completedOperations}/${progress.totalOperations}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${progress.percentage.toStringAsFixed(1)}%',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (progress.estimatedTimeRemaining != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'ETA: ${_formatDuration(progress.estimatedTimeRemaining!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (progress.currentOperation != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(
                  'Current: ${progress.currentOperation}',
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
            if (error != null) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[300]!),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build statistics card.
  Widget _buildStatisticsCard(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    final SyncStatistics? stats = provider.statistics;

    if (stats == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No statistics available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Total syncs',
              stats.totalSyncs.toString(),
              Icons.sync,
            ),
            _buildStatRow(
              context,
              'Successful',
              stats.successfulSyncs.toString(),
              Icons.check_circle,
              color: Colors.green,
            ),
            _buildStatRow(
              context,
              'Failed',
              stats.failedSyncs.toString(),
              Icons.error,
              color: stats.failedSyncs > 0 ? Colors.red : null,
            ),
            _buildStatRow(
              context,
              'Success rate',
              '${(stats.successRate * 100).toStringAsFixed(1)}%',
              Icons.trending_up,
              color: stats.successRate >= 0.9 ? Colors.green : Colors.orange,
            ),
            _buildStatRow(
              context,
              'Avg duration',
              _formatDuration(stats.averageDuration),
              Icons.timer,
            ),
            _buildStatRow(
              context,
              'Total operations',
              stats.totalOperations.toString(),
              Icons.list,
            ),
            _buildStatRow(
              context,
              'Conflicts',
              '${stats.conflictsResolved}/${stats.conflictsDetected}',
              Icons.warning_amber,
              color: stats.conflictsDetected > 0 ? Colors.orange : null,
            ),
            if (stats.lastSyncTime != null) ...<Widget>[
              const Divider(height: 24),
              Text(
                'Last sync: ${_formatDateTime(stats.lastSyncTime!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (stats.nextScheduledSync != null) ...<Widget>[
              Text(
                'Next sync: ${_formatDateTime(stats.nextScheduledSync!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build entity statistics card.
  Widget _buildEntityStatsCard(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    final Map<String, EntitySyncStats> entityStats = provider.entityStats;

    if (entityStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No entity statistics available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Entity Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...entityStats.entries.map((MapEntry<String, EntitySyncStats> entry) {
              final EntitySyncStats stats = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          _formatEntityType(stats.entityType),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${stats.successful}/${stats.total}',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: stats.failed > 0 ? Colors.orange : Colors.green,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        _buildEntityStatChip('C: ${stats.creates}', Colors.blue),
                        const SizedBox(width: 4),
                        _buildEntityStatChip('U: ${stats.updates}', Colors.orange),
                        const SizedBox(width: 4),
                        _buildEntityStatChip('D: ${stats.deletes}', Colors.red),
                        if (stats.conflicts > 0) ...<Widget>[
                          const SizedBox(width: 4),
                          _buildEntityStatChip(
                            'Conflicts: ${stats.conflicts}',
                            Colors.amber,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Build history tab with sync history list.
  Widget _buildHistoryTab(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    final List<SyncResult> history = provider.syncHistory;

    if (history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No sync history',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sync history will appear here',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: history.length,
      itemBuilder: (BuildContext context, int index) {
        final SyncResult result = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
              size: 32,
            ),
            title: Text(
              result.success ? 'Sync successful' : 'Sync failed',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_formatDateTime(result.startTime)),
                Text(
                  '${result.successfulOperations}/${result.totalOperations} operations • '
                  '${_formatDuration(result.duration)}',
                ),
                if (result.conflictsDetected > 0)
                  Text(
                    '${result.conflictsDetected} conflicts detected',
                    style: const TextStyle(color: Colors.orange),
                  ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showSyncResultDetails(context, result),
          ),
        );
      },
    );
  }

  /// Build conflicts tab.
  Widget _buildConflictsTab(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    final List<dynamic> conflicts = provider.unresolvedConflicts;

    if (conflicts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'No conflicts',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'All conflicts have been resolved',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: conflicts.length,
      itemBuilder: (BuildContext context, int index) {
        final conflict = conflicts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: const Icon(Icons.warning_amber, color: Colors.orange, size: 32),
            title: Text('Conflict #${index + 1}'),
            subtitle: Text(conflict.toString()),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to conflict resolution screen
              Navigator.pushNamed(
                context,
                '/conflicts',
              );
            },
          ),
        );
      },
    );
  }

  /// Build errors tab.
  Widget _buildErrorsTab(
    BuildContext context,
    SyncStatusProvider provider,
  ) {
    final List<SyncError> errors = provider.recentErrors;

    if (errors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.check_circle, size: 64, color: Colors.green[400]),
            const SizedBox(height: 16),
            Text(
              'No errors',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.green[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No sync errors have occurred',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${errors.length} errors',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                onPressed: () {
                  provider.clearErrors();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Errors cleared')),
                  );
                },
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear all'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemCount: errors.length,
            itemBuilder: (BuildContext context, int index) {
              final SyncError error = errors[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: const Icon(Icons.error, color: Colors.red, size: 32),
                  title: Text(
                    error.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(_formatDateTime(error.timestamp)),
                  trailing: IconButton(
                    icon: const Icon(Icons.info_outline),
                    onPressed: () => _showErrorDetails(context, error),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// Build statistics row.
  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  /// Build entity stat chip.
  Widget _buildEntityStatChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Show sync result details dialog.
  void _showSyncResultDetails(BuildContext context, SyncResult result) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(result.success ? 'Sync Successful' : 'Sync Failed'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow('Started', _formatDateTime(result.startTime)),
              _buildDetailRow('Ended', _formatDateTime(result.endTime)),
              _buildDetailRow('Duration', _formatDuration(result.duration)),
              const Divider(),
              _buildDetailRow('Total operations', result.totalOperations.toString()),
              _buildDetailRow('Successful', result.successfulOperations.toString()),
              _buildDetailRow('Failed', result.failedOperations.toString()),
              _buildDetailRow('Skipped', result.skippedOperations.toString()),
              const Divider(),
              _buildDetailRow('Conflicts detected', result.conflictsDetected.toString()),
              _buildDetailRow('Conflicts resolved', result.conflictsResolved.toString()),
              const Divider(),
              _buildDetailRow('Success rate', '${(result.successRate * 100).toStringAsFixed(1)}%'),
              _buildDetailRow('Throughput', '${result.throughput.toStringAsFixed(2)} ops/s'),
              if (result.errorMessage != null) ...<Widget>[
                const Divider(),
                const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(result.errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show error details dialog.
  void _showErrorDetails(BuildContext context, SyncError error) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _buildDetailRow('Time', _formatDateTime(error.timestamp)),
              const Divider(),
              const Text('Message:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(error.message),
              if (error.exception != null) ...<Widget>[
                const SizedBox(height: 12),
                const Text('Exception:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(error.exception.toString()),
              ],
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build detail row for dialogs.
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  /// Refresh data.
  Future<void> _refresh(BuildContext context) async {
    final SyncStatusProvider provider = context.read<SyncStatusProvider>();
    await provider.refresh();
  }

  /// Get sync status icon.
  IconData _getSyncStatusIcon(bool isSyncing, String? error) {
    if (error != null) return Icons.error;
    if (isSyncing) return Icons.sync;
    return Icons.check_circle;
  }

  /// Get sync status color.
  Color _getSyncStatusColor(bool isSyncing, String? error) {
    if (error != null) return Colors.red;
    if (isSyncing) return Colors.blue;
    return Colors.green;
  }

  /// Get sync status text.
  String _getSyncStatusText(bool isSyncing, String? error) {
    if (error != null) return 'Sync Failed';
    if (isSyncing) return 'Syncing...';
    return 'Synced';
  }

  /// Get progress text.
  String _getProgressText(SyncProgress progress) {
    return '${progress.completedOperations} of ${progress.totalOperations} operations';
  }

  /// Format duration for display.
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format DateTime for display.
  String _formatDateTime(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return DateFormat('MMM d, y HH:mm').format(dateTime);
    }
  }

  /// Format entity type for display.
  String _formatEntityType(String entityType) {
    return entityType[0].toUpperCase() + entityType.substring(1);
  }
}
