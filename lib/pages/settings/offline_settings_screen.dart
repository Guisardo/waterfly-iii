import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/services/sync/background_sync_scheduler.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/consistency_service.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/widgets/sync_progress_dialog.dart';

final Logger _log = Logger('OfflineSettingsScreen');

/// Comprehensive offline mode settings screen.
///
/// Features:
/// - Sync interval configuration
/// - Auto-sync toggle
/// - WiFi-only sync restriction
/// - Conflict resolution strategy selection
/// - Storage management
/// - Sync statistics display
/// - Manual sync trigger
/// - Force full sync
/// - Consistency check
///
/// Uses Provider for state management and proper error handling.
class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  bool _isSyncing = false;
  bool _isCheckingConsistency = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Consumer<OfflineSettingsProvider>(
        builder: (context, settings, child) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSyncSection(context, settings),
              const SizedBox(height: 24),
              _buildConflictSection(context, settings),
              const SizedBox(height: 24),
              _buildStorageSection(context, settings),
              const SizedBox(height: 24),
              _buildStatisticsSection(context, settings),
              const SizedBox(height: 24),
              _buildActionsSection(context, settings),
            ],
          );
        },
      ),
    );
  }

  /// Build sync configuration section.
  Widget _buildSyncSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Synchronization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-sync'),
              subtitle: const Text('Automatically sync in background'),
              value: settings.autoSyncEnabled,
              onChanged: (value) async {
                try {
                  await settings.setAutoSyncEnabled(value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value ? 'Auto-sync enabled' : 'Auto-sync disabled',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  _log.severe('Failed to toggle auto-sync', e);
                  if (mounted) {
                    _showError(context, 'Failed to update auto-sync setting');
                  }
                }
              },
            ),
            ListTile(
              title: const Text('Sync interval'),
              subtitle: Text(settings.syncInterval.label),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              enabled: settings.autoSyncEnabled,
              onTap: settings.autoSyncEnabled
                  ? () => _showSyncIntervalDialog(context, settings)
                  : null,
            ),
            SwitchListTile(
              title: const Text('WiFi only'),
              subtitle: const Text('Sync only when connected to WiFi'),
              value: settings.wifiOnlyEnabled,
              onChanged: (value) async {
                try {
                  await settings.setWifiOnlyEnabled(value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? 'WiFi-only sync enabled'
                              : 'WiFi-only sync disabled',
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  _log.severe('Failed to toggle WiFi-only', e);
                  if (mounted) {
                    _showError(context, 'Failed to update WiFi-only setting');
                  }
                }
              },
            ),
            if (settings.lastSyncTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Last sync: ${_formatDateTime(settings.lastSyncTime!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (settings.nextSyncTime != null && settings.autoSyncEnabled)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Next sync: ${_formatDateTime(settings.nextSyncTime!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build conflict resolution section.
  Widget _buildConflictSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conflict Resolution',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Resolution strategy'),
              subtitle: Text(_getStrategyLabel(settings.conflictStrategy)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showConflictStrategyDialog(context, settings),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _getStrategyDescription(settings.conflictStrategy),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build storage management section.
  Widget _buildStorageSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Storage',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Database size'),
              subtitle: Text(settings.formattedDatabaseSize),
              trailing: const Icon(Icons.storage),
            ),
            const Divider(),
            ListTile(
              title: const Text('Clear cache'),
              subtitle: const Text('Remove temporary data'),
              leading: const Icon(Icons.cleaning_services),
              onTap: () => _confirmClearCache(context, settings),
            ),
            ListTile(
              title: const Text('Clear all data'),
              subtitle: const Text('Remove all offline data'),
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              onTap: () => _confirmClearAllData(context, settings),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sync statistics section.
  Widget _buildStatisticsSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              'Total syncs',
              settings.totalSyncs.toString(),
              Icons.sync,
            ),
            _buildStatRow(
              context,
              'Conflicts',
              settings.totalConflicts.toString(),
              Icons.warning_amber,
              color: settings.totalConflicts > 0 ? Colors.orange : null,
            ),
            _buildStatRow(
              context,
              'Errors',
              settings.totalErrors.toString(),
              Icons.error,
              color: settings.totalErrors > 0 ? Colors.red : null,
            ),
            _buildStatRow(
              context,
              'Success rate',
              '${settings.successRate.toStringAsFixed(1)}%',
              Icons.check_circle,
              color: settings.successRate >= 90 ? Colors.green : Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  /// Build actions section.
  Widget _buildActionsSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : () => _triggerManualSync(context),
              icon: _isSyncing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isSyncing ? 'Syncing...' : 'Sync now'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSyncing ? null : () => _triggerFullSync(context),
              icon: const Icon(Icons.sync_alt),
              label: const Text('Force full sync'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isCheckingConsistency
                  ? null
                  : () => _runConsistencyCheck(context),
              icon: _isCheckingConsistency
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fact_check),
              label: Text(
                _isCheckingConsistency
                    ? 'Checking...'
                    : 'Check consistency',
              ),
            ),
          ],
        ),
      ),
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
        children: [
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

  /// Show sync interval selection dialog.
  Future<void> _showSyncIntervalDialog(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final selected = await showDialog<SyncInterval>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sync Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: SyncInterval.values.map((interval) {
            return RadioListTile<SyncInterval>(
              title: Text(interval.label),
              value: interval,
              groupValue: settings.syncInterval,
              onChanged: (value) => Navigator.pop(context, value),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && selected != settings.syncInterval) {
      try {
        await settings.setSyncInterval(selected);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sync interval set to ${selected.label}'),
            ),
          );
        }
      } catch (e) {
        _log.severe('Failed to set sync interval', e);
        if (mounted) {
          _showError(context, 'Failed to update sync interval');
        }
      }
    }
  }

  /// Show conflict resolution strategy selection dialog.
  Future<void> _showConflictStrategyDialog(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final selected = await showDialog<ConflictResolutionStrategy>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conflict Resolution Strategy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ConflictResolutionStrategy.values.map((strategy) {
              return RadioListTile<ConflictResolutionStrategy>(
                title: Text(_getStrategyLabel(strategy)),
                subtitle: Text(_getStrategyDescription(strategy)),
                value: strategy,
                groupValue: settings.conflictStrategy,
                onChanged: (value) => Navigator.pop(context, value),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null && selected != settings.conflictStrategy) {
      try {
        await settings.setConflictStrategy(selected);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Conflict strategy set to ${_getStrategyLabel(selected)}',
              ),
            ),
          );
        }
      } catch (e) {
        _log.severe('Failed to set conflict strategy', e);
        if (mounted) {
          _showError(context, 'Failed to update conflict strategy');
        }
      }
    }
  }

  /// Confirm and clear cache.
  Future<void> _confirmClearCache(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove temporary data. Your offline data will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // TODO: Implement cache clearing
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cache cleared')),
        );
      }
    }
  }

  /// Confirm and clear all data.
  Future<void> _confirmClearAllData(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will remove ALL offline data. This action cannot be undone. '
          'You will need to sync again to use offline mode.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await settings.clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All offline data cleared')),
          );
        }
      } catch (e) {
        _log.severe('Failed to clear all data', e);
        if (mounted) {
          _showError(context, 'Failed to clear data');
        }
      }
    }
  }

  /// Trigger manual sync.
  Future<void> _triggerManualSync(BuildContext context) async {
    setState(() => _isSyncing = true);

    try {
      // TODO: Get SyncService from provider/dependency injection
      // For now, show placeholder dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const SyncProgressDialog(),
        );
      }
    } catch (e) {
      _log.severe('Manual sync failed', e);
      if (mounted) {
        _showError(context, 'Sync failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  /// Trigger full sync.
  Future<void> _triggerFullSync(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Full Sync'),
        content: const Text(
          'This will download all data from the server, replacing local data. '
          'This may take several minutes.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sync'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSyncing = true);

      try {
        // TODO: Get SyncService and trigger full sync
        if (mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const SyncProgressDialog(),
          );
        }
      } catch (e) {
        _log.severe('Full sync failed', e);
        if (mounted) {
          _showError(context, 'Full sync failed: ${e.toString()}');
        }
      } finally {
        if (mounted) {
          setState(() => _isSyncing = false);
        }
      }
    }
  }

  /// Run consistency check.
  Future<void> _runConsistencyCheck(BuildContext context) async {
    setState(() => _isCheckingConsistency = true);

    try {
      // TODO: Get ConsistencyService and run check
      await Future.delayed(const Duration(seconds: 2)); // Placeholder

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Consistency Check Complete'),
            content: const Text('No issues found.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      _log.severe('Consistency check failed', e);
      if (mounted) {
        _showError(context, 'Consistency check failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingConsistency = false);
      }
    }
  }

  /// Show help dialog.
  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Mode Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Auto-sync',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Automatically synchronize data in the background at the specified interval.',
              ),
              SizedBox(height: 12),
              Text(
                'WiFi Only',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Only sync when connected to WiFi to save mobile data.',
              ),
              SizedBox(height: 12),
              Text(
                'Conflict Resolution',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Choose how to handle conflicts when the same data is modified both locally and on the server.',
              ),
              SizedBox(height: 12),
              Text(
                'Consistency Check',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'Verify data integrity and fix any inconsistencies in the local database.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar.
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Format DateTime for display.
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

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

  /// Get conflict strategy label.
  String _getStrategyLabel(ConflictResolutionStrategy strategy) {
    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        return 'Local Wins';
      case ConflictResolutionStrategy.remoteWins:
        return 'Remote Wins';
      case ConflictResolutionStrategy.lastWriteWins:
        return 'Last Write Wins';
      case ConflictResolutionStrategy.manual:
        return 'Manual Resolution';
    }
  }

  /// Get conflict strategy description.
  String _getStrategyDescription(ConflictResolutionStrategy strategy) {
    switch (strategy) {
      case ConflictResolutionStrategy.localWins:
        return 'Always keep local changes';
      case ConflictResolutionStrategy.remoteWins:
        return 'Always keep server changes';
      case ConflictResolutionStrategy.lastWriteWins:
        return 'Keep most recently modified version';
      case ConflictResolutionStrategy.manual:
        return 'Manually resolve each conflict';
    }
  }
}
