import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/models/sync_progress.dart';
import 'package:waterflyiii/providers/app_mode_provider.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';
import 'package:waterflyiii/services/cache/query_cache.dart';
import 'package:waterflyiii/services/sync/consistency_service.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';
import 'package:waterflyiii/widgets/incremental_sync_settings.dart';
import 'package:waterflyiii/widgets/incremental_sync_statistics.dart';

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
  bool _isCalculatingDatabaseSize = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Calculate database size when screen loads and context is available
    if (!_isCalculatingDatabaseSize) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _calculateDatabaseSize();
        }
      });
    }
  }

  /// Calculate and update database size.
  Future<void> _calculateDatabaseSize() async {
    if (_isCalculatingDatabaseSize) return;
    if (!mounted) return;
    
    setState(() => _isCalculatingDatabaseSize = true);

    try {
      final BuildContext? currentContext = context;
      if (currentContext == null || !mounted) {
        return;
      }

      final AppDatabase database = Provider.of<AppDatabase>(
        currentContext,
        listen: false,
      );
      final OfflineSettingsProvider settings = Provider.of<OfflineSettingsProvider>(
        currentContext,
        listen: false,
      );

      final int sizeInBytes = await database.getDatabaseSize();
      await settings.updateDatabaseSize(sizeInBytes);
    } catch (e, stackTrace) {
      _log.severe('Failed to calculate database size', e, stackTrace);
    } finally {
      if (mounted) {
        setState(() => _isCalculatingDatabaseSize = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode Settings'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: 'Help',
          ),
        ],
      ),
      body: Consumer<OfflineSettingsProvider>(
        builder: (
          BuildContext context,
          OfflineSettingsProvider settings,
          Widget? child,
        ) {
          if (settings.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: <Widget>[
              _buildSyncSection(context, settings),
              const SizedBox(height: 24),
              _buildIncrementalSyncSection(context, settings),
              const SizedBox(height: 24),
              _buildIncrementalSyncStatisticsSection(context, settings),
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
          children: <Widget>[
            Text(
              'Synchronization',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-sync'),
              subtitle: const Text('Automatically sync in background'),
              value: settings.autoSyncEnabled,
              onChanged: (bool value) async {
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
              onTap:
                  settings.autoSyncEnabled
                      ? () => _showSyncIntervalDialog(context, settings)
                      : null,
            ),
            SwitchListTile(
              title: const Text('WiFi only'),
              subtitle: const Text('Sync only when connected to WiFi'),
              value: settings.wifiOnlyEnabled,
              onChanged: (bool value) async {
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

  /// Build incremental sync settings section.
  ///
  /// Provides comprehensive controls for incremental sync behavior:
  /// - Enable/disable incremental sync
  /// - Sync window configuration (how far back to look for changes)
  /// - Cache TTL for Tier 2 entities (categories, bills, piggy banks)
  Widget _buildIncrementalSyncSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return IncrementalSyncSettingsSection(
      showAdvancedSettings: true,
      onForceIncrementalSync:
          _isSyncing ? null : () => _triggerIncrementalSync(context),
      onForceFullSync: _isSyncing ? null : () => _triggerFullSync(context),
    );
  }

  /// Build incremental sync statistics section.
  ///
  /// Displays comprehensive statistics about incremental sync performance:
  /// - Skip rate (efficiency indicator)
  /// - Items fetched/updated/skipped
  /// - Bandwidth saved
  /// - API calls saved
  Widget _buildIncrementalSyncStatisticsSection(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return IncrementalSyncStatisticsWidget(
      mode: IncrementalSyncStatisticsMode.card,
      showHeader: true,
      onRefresh: () {
        // Trigger a state refresh by forcing a rebuild
        setState(() {});
      },
    );
  }

  /// Trigger incremental sync.
  Future<void> _triggerIncrementalSync(BuildContext context) async {
    if (!mounted) return;

    setState(() => _isSyncing = true);

    try {
      // Get IncrementalSyncService from Provider
      IncrementalSyncService? incrementalSyncService;
      try {
        incrementalSyncService =
            Provider.of<IncrementalSyncService?>(context, listen: false);
      } catch (e, stackTrace) {
        _log.severe('Failed to get IncrementalSyncService', e, stackTrace);
        if (mounted) {
          _showError(context, 'Failed to get sync service: ${e.toString()}');
        }
        return;
      }

      if (incrementalSyncService == null) {
        _log.warning('IncrementalSyncService not available');
        if (mounted) {
          _showError(context, 'Incremental sync service not available');
        }
        return;
      }

      // Check if incremental sync can be used
      final bool canUseIncremental =
          await incrementalSyncService.canUseIncrementalSync();
      if (!canUseIncremental) {
        _log.warning('Incremental sync not available, performing full sync instead');
        if (mounted) {
          _showError(
            context,
            'Incremental sync not available. Please perform a full sync first.',
          );
        }
        return;
      }

      // Show simple loading dialog (SyncProgressWidget requires SyncStatusProvider
      // which is not available in dialog context and not used by IncrementalSyncService)
      if (mounted) {
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              // Use dialogContext to avoid provider issues
              return const AlertDialog(
                content: Row(
                  children: <Widget>[
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text('Performing incremental sync...'),
                    ),
                  ],
                ),
              );
            },
          );
        } catch (e, stackTrace) {
          _log.severe('Failed to show dialog', e, stackTrace);
          // Continue anyway - dialog is optional
        }
      }

      // Start incremental sync in background
      final result = await incrementalSyncService.performIncrementalSync();

      // Close progress dialog
      if (mounted) {
        try {
          Navigator.of(context).pop(); // Close progress dialog
        } catch (e, stackTrace) {
          _log.warning('Failed to close dialog (may already be closed)', e, stackTrace);
          // Continue - dialog might already be closed
        }
      }

      if (result.isIncremental && result.success) {
        if (mounted) {
          try {
            // Use a post-frame callback to ensure context is valid
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Incremental sync completed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e, stackTrace) {
                  _log.severe('Failed to show success snackbar', e, stackTrace);
                }
              }
            });
          } catch (e, stackTrace) {
            _log.severe('Failed to schedule success snackbar', e, stackTrace);
          }
        }
      } else {
        _log.warning('Incremental sync completed with issues: ${result.error}');
        if (mounted) {
          try {
            // Use a post-frame callback to ensure context is valid
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                try {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Incremental sync completed with issues: ${result.error ?? "Unknown error"}',
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } catch (e, stackTrace) {
                  _log.severe('Failed to show warning snackbar', e, stackTrace);
                }
              }
            });
          } catch (e, stackTrace) {
            _log.severe('Failed to schedule warning snackbar', e, stackTrace);
          }
        }
      }
    } catch (e, stackTrace) {
      _log.severe('Incremental sync failed', e, stackTrace);
      if (mounted) {
        try {
          Navigator.of(context).pop(); // Close progress dialog if still open
        } catch (navError) {
          _log.warning('Failed to close dialog in catch block', navError);
        }
        try {
          _showError(context, 'Incremental sync failed: ${e.toString()}');
        } catch (errorError) {
          _log.severe('Failed to show error dialog', errorError);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
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
          children: <Widget>[
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
          children: <Widget>[
            Text('Storage', style: Theme.of(context).textTheme.titleLarge),
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
          children: <Widget>[
            Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
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
          children: <Widget>[
            Text('Actions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isSyncing ? null : () => _triggerManualSync(context),
              icon:
                  _isSyncing
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
              onPressed:
                  _isCheckingConsistency
                      ? null
                      : () => _runConsistencyCheck(context),
              icon:
                  _isCheckingConsistency
                      ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Icon(Icons.fact_check),
              label: Text(
                _isCheckingConsistency ? 'Checking...' : 'Check consistency',
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
        children: <Widget>[
          Icon(icon, size: 20, color: color),
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
      ),
    );
  }

  /// Show sync interval selection dialog.
  Future<void> _showSyncIntervalDialog(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final SyncInterval? selected = await showDialog<SyncInterval>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Sync Interval'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  SyncInterval.values.map((SyncInterval interval) {
                    return RadioListTile<SyncInterval>(
                      title: Text(interval.label),
                      value: interval,
                      groupValue: settings.syncInterval,
                      onChanged:
                          (SyncInterval? value) =>
                              Navigator.pop(context, value),
                    );
                  }).toList(),
            ),
            actions: <Widget>[
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
            SnackBar(content: Text('Sync interval set to ${selected.label}')),
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
    final ResolutionStrategy? selected = await showDialog<ResolutionStrategy>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Conflict Resolution Strategy'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    ResolutionStrategy.values.map((
                      ResolutionStrategy strategy,
                    ) {
                      return RadioListTile<ResolutionStrategy>(
                        title: Text(_getStrategyLabel(strategy)),
                        subtitle: Text(_getStrategyDescription(strategy)),
                        value: strategy,
                        groupValue: settings.conflictStrategy,
                        onChanged:
                            (ResolutionStrategy? value) =>
                                Navigator.pop(context, value),
                      );
                    }).toList(),
              ),
            ),
            actions: <Widget>[
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Clear Cache'),
            content: const Text(
              'This will remove temporary data. Your offline data will be preserved.',
            ),
            actions: <Widget>[
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

    if (confirmed ?? false) {
      try {
        // Clear query cache
        final QueryCache queryCache = QueryCache();
        queryCache.clear();

        _log.info('Cache cleared successfully');

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Cache cleared')));
        }
      } catch (e, stackTrace) {
        _log.severe('Failed to clear cache', e, stackTrace);

        if (mounted) {
          _showError(context, 'Failed to clear cache: ${e.toString()}');
        }
      }
    }
  }

  /// Confirm and clear all data.
  Future<void> _confirmClearAllData(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Clear All Data'),
            content: const Text(
              'This will remove ALL offline data. This action cannot be undone. '
              'You will need to sync again to use offline mode.',
            ),
            actions: <Widget>[
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

    if (confirmed ?? false) {
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
      // Get SyncManager from SyncStatusProvider (if available)
      SyncStatusProvider? syncStatusProvider;
      try {
        syncStatusProvider =
            Provider.of<SyncStatusProvider>(context, listen: false);
      } catch (e) {
        _log.warning('SyncStatusProvider not available: $e');
        if (mounted) {
          _showError(
            context,
            'Sync service not available. Please restart the app.',
          );
        }
        return;
      }

      _log.info('Triggering manual sync');

      // Show simple loading dialog (SyncProgressWidget requires SyncStatusProvider
      // which is not available in dialog context)
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const AlertDialog(
            content: Row(
              children: <Widget>[
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(
                  child: Text('Performing sync...'),
                ),
              ],
            ),
          ),
        );
      }

      // Start sync in background
      final Future<SyncResult> syncFuture =
          syncStatusProvider.syncManager.synchronize();

      // Wait for sync to complete
      await syncFuture;

      if (mounted) {
        Navigator.of(context).pop(); // Close progress dialog
      }

      _log.info('Manual sync completed successfully');
    } catch (e, stackTrace) {
      _log.severe('Manual sync failed', e, stackTrace);
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
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Force Full Sync'),
            content: const Text(
              'This will download all data from the server, replacing local data. '
              'This may take several minutes.',
            ),
            actions: <Widget>[
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

    if (confirmed ?? false) {
      setState(() => _isSyncing = true);

      try {
        // Get SyncManager from SyncStatusProvider (if available)
        SyncStatusProvider? syncStatusProvider;
        try {
          syncStatusProvider =
              Provider.of<SyncStatusProvider>(context, listen: false);
        } catch (e) {
          _log.warning('SyncStatusProvider not available: $e');
          if (mounted) {
            _showError(
              context,
              'Sync service not available. Please restart the app.',
            );
          }
          return;
        }

        _log.info('Triggering full sync');

        // Show simple loading dialog (SyncProgressWidget requires SyncStatusProvider
        // which is not available in dialog context)
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => const AlertDialog(
              content: Row(
                children: <Widget>[
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text('Performing full sync...'),
                  ),
                ],
              ),
            ),
          );
        }

        // Start full sync in background
        final Future<SyncResult> syncFuture = syncStatusProvider.syncManager
            .synchronize(fullSync: true);

        // Wait for sync to complete
        await syncFuture;

        if (mounted) {
          Navigator.of(context).pop(); // Close progress dialog
        }

        _log.info('Full sync completed successfully');
      } catch (e, stackTrace) {
        _log.severe('Full sync failed', e, stackTrace);
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
      // Get database from provider
      final AppDatabase database = Provider.of<AppDatabase>(
        context,
        listen: false,
      );

      // Create ConsistencyService
      final ConsistencyService consistencyService = ConsistencyService(
        database: database,
      );

      _log.info('Running consistency check');

      // Run check
      final List<InconsistencyIssue> issues = await consistencyService.check();

      _log.info('Consistency check completed: ${issues.length} issues found');

      if (mounted) {
        showDialog(
          context: context,
          builder:
              (BuildContext context) => AlertDialog(
                title: const Text('Consistency Check Complete'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      issues.isEmpty
                          ? 'No issues found. Your data is consistent.'
                          : '${issues.length} issue(s) found.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (issues.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        'Issue breakdown:',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...issues
                          .take(5)
                          .map(
                            (InconsistencyIssue issue) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '• ${issue.description}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                      if (issues.length > 5)
                        Text(
                          '... and ${issues.length - 5} more',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontStyle: FontStyle.italic),
                        ),
                    ],
                  ],
                ),
                actions: <Widget>[
                  if (issues.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _repairInconsistencies(
                          context,
                          consistencyService,
                        );
                      },
                      child: const Text('Repair'),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Consistency check failed', e, stackTrace);
      if (mounted) {
        _showError(context, 'Consistency check failed: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isCheckingConsistency = false);
      }
    }
  }

  /// Repair detected inconsistencies.
  Future<void> _repairInconsistencies(
    BuildContext context,
    ConsistencyService consistencyService,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Repair Inconsistencies'),
            content: const Text(
              'This will attempt to automatically fix detected issues. '
              'Some issues may require manual intervention.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Repair'),
              ),
            ],
          ),
    );

    if (confirmed ?? false) {
      try {
        _log.info('Repairing inconsistencies');

        final RepairResult result = await consistencyService.repairAll();

        _log.info(
          'Repair completed: ${result.repaired} repaired, ${result.failed} failed',
        );

        if (mounted) {
          showDialog(
            context: context,
            builder:
                (BuildContext context) => AlertDialog(
                  title: const Text('Repair Complete'),
                  content: Text(
                    '${result.repaired} issue(s) repaired.\n'
                    '${result.failed} issue(s) could not be repaired.',
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
      } catch (e, stackTrace) {
        _log.severe('Repair failed', e, stackTrace);
        if (mounted) {
          _showError(context, 'Repair failed: ${e.toString()}');
        }
      }
    }
  }

  /// Show help dialog.
  void _showHelp() {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: const Text('Offline Mode Help'),
            content: const SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
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
                  Text('Only sync when connected to WiFi to save mobile data.'),
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
            actions: <Widget>[
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

  /// Get conflict strategy label.
  String _getStrategyLabel(ResolutionStrategy strategy) {
    switch (strategy) {
      case ResolutionStrategy.localWins:
        return 'Local Wins';
      case ResolutionStrategy.remoteWins:
        return 'Remote Wins';
      case ResolutionStrategy.lastWriteWins:
        return 'Last Write Wins';
      case ResolutionStrategy.manual:
        return 'Manual Resolution';
      case ResolutionStrategy.merge:
        return 'Merge Changes';
    }
  }

  /// Get conflict strategy description.
  String _getStrategyDescription(ResolutionStrategy strategy) {
    switch (strategy) {
      case ResolutionStrategy.localWins:
        return 'Always keep local changes';
      case ResolutionStrategy.remoteWins:
        return 'Always keep server changes';
      case ResolutionStrategy.lastWriteWins:
        return 'Keep most recently modified version';
      case ResolutionStrategy.manual:
        return 'Manually resolve each conflict';
      case ResolutionStrategy.merge:
        return 'Automatically merge non-conflicting changes';
    }
  }
}
