import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/models/sync_progress.dart';
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
      final BuildContext currentContext = context;
      if (!mounted) {
        return;
      }

      final AppDatabase database = Provider.of<AppDatabase>(
        currentContext,
        listen: false,
      );
      final OfflineSettingsProvider settings =
          Provider.of<OfflineSettingsProvider>(currentContext, listen: false);

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
    final S localizations = S.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.offlineSettingsTitle),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelp,
            tooltip: localizations.offlineSettingsHelp,
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
              S.of(context).offlineSettingsSynchronization,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(S.of(context).offlineSettingsAutoSync),
              subtitle: Text(S.of(context).offlineSettingsAutoSyncDesc),
              value: settings.autoSyncEnabled,
              onChanged: (bool value) async {
                try {
                  await settings.setAutoSyncEnabled(value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? S.of(context).offlineSettingsAutoSyncEnabled
                              : S.of(context).offlineSettingsAutoSyncDisabled,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  _log.severe('Failed to toggle auto-sync', e);
                  if (mounted) {
                    _showError(
                      context,
                      S.of(context).offlineSettingsFailedToUpdateAutoSync,
                    );
                  }
                }
              },
            ),
            ListTile(
              title: Text(S.of(context).offlineSettingsSyncInterval),
              subtitle: Text(
                _getSyncIntervalLabel(context, settings.syncInterval),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              enabled: settings.autoSyncEnabled,
              onTap:
                  settings.autoSyncEnabled
                      ? () => _showSyncIntervalDialog(context, settings)
                      : null,
            ),
            SwitchListTile(
              title: Text(S.of(context).offlineSettingsWifiOnly),
              subtitle: Text(S.of(context).offlineSettingsWifiOnlyDesc),
              value: settings.wifiOnlyEnabled,
              onChanged: (bool value) async {
                try {
                  await settings.setWifiOnlyEnabled(value);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value
                              ? S.of(context).offlineSettingsWifiOnlyEnabled
                              : S.of(context).offlineSettingsWifiOnlyDisabled,
                        ),
                      ),
                    );
                  }
                } catch (e) {
                  _log.severe('Failed to toggle WiFi-only', e);
                  if (mounted) {
                    _showError(
                      context,
                      S.of(context).offlineSettingsFailedToUpdateWifiOnly,
                    );
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
                  S
                      .of(context)
                      .offlineSettingsLastSync(
                        _formatDateTime(context, settings.lastSyncTime!),
                      ),
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
                  S
                      .of(context)
                      .offlineSettingsNextSync(
                        _formatDateTime(context, settings.nextSyncTime!),
                      ),
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
        incrementalSyncService = Provider.of<IncrementalSyncService?>(
          context,
          listen: false,
        );
      } catch (e, stackTrace) {
        _log.severe('Failed to get IncrementalSyncService', e, stackTrace);
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsFailedToGetSyncService(e.toString()),
          );
        }
        return;
      }

      if (incrementalSyncService == null) {
        _log.warning('IncrementalSyncService not available');
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsIncrementalSyncServiceNotAvailable,
          );
        }
        return;
      }

      // Check if incremental sync can be used
      final bool canUseIncremental =
          await incrementalSyncService.canUseIncrementalSync();
      if (!canUseIncremental) {
        _log.warning(
          'Incremental sync not available, performing full sync instead',
        );
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsIncrementalSyncNotAvailable,
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
              return AlertDialog(
                content: Row(
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        S
                            .of(dialogContext)
                            .offlineSettingsPerformingIncrementalSync,
                      ),
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
      final IncrementalSyncResult result = await incrementalSyncService.performIncrementalSync();

      // Close progress dialog
      if (mounted) {
        try {
          Navigator.of(context).pop(); // Close progress dialog
        } catch (e, stackTrace) {
          _log.warning(
            'Failed to close dialog (may already be closed)',
            e,
            stackTrace,
          );
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
                    SnackBar(
                      content: Text(
                        S.of(context).offlineSettingsIncrementalSyncCompleted,
                      ),
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
                        S
                            .of(context)
                            .offlineSettingsIncrementalSyncIssues(
                              result.error ?? S.of(context).errorUnknown,
                            ),
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
          _showError(
            context,
            S.of(context).offlineSettingsIncrementalSyncFailed(e.toString()),
          );
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
              S.of(context).offlineSettingsConflictResolution,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(S.of(context).offlineSettingsResolutionStrategy),
              subtitle: Text(
                _getStrategyLabel(context, settings.conflictStrategy),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _showConflictStrategyDialog(context, settings),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _getStrategyDescription(context, settings.conflictStrategy),
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
            Text(
              S.of(context).offlineSettingsStorage,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(S.of(context).offlineSettingsDatabaseSize),
              subtitle: Text(settings.formattedDatabaseSize),
              trailing: const Icon(Icons.storage),
            ),
            const Divider(),
            ListTile(
              title: Text(S.of(context).offlineSettingsClearCache),
              subtitle: Text(S.of(context).offlineSettingsClearCacheDesc),
              leading: const Icon(Icons.cleaning_services),
              onTap: () => _confirmClearCache(context, settings),
            ),
            ListTile(
              title: Text(S.of(context).offlineSettingsClearAllData),
              subtitle: Text(S.of(context).offlineSettingsClearAllDataDesc),
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
            Text(
              S.of(context).offlineSettingsStatistics,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              S.of(context).offlineSettingsTotalSyncs,
              settings.totalSyncs.toString(),
              Icons.sync,
            ),
            _buildStatRow(
              context,
              S.of(context).offlineSettingsConflicts,
              settings.totalConflicts.toString(),
              Icons.warning_amber,
              color: settings.totalConflicts > 0 ? Colors.orange : null,
            ),
            _buildStatRow(
              context,
              S.of(context).offlineSettingsErrors,
              settings.totalErrors.toString(),
              Icons.error,
              color: settings.totalErrors > 0 ? Colors.red : null,
            ),
            _buildStatRow(
              context,
              S.of(context).offlineSettingsSuccessRate,
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
            Text(
              S.of(context).offlineSettingsActions,
              style: Theme.of(context).textTheme.titleLarge,
            ),
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
              label: Text(
                _isSyncing
                    ? S.of(context).offlineSettingsSyncing
                    : S.of(context).offlineSettingsSyncNow,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _isSyncing ? null : () => _triggerFullSync(context),
              icon: const Icon(Icons.sync_alt),
              label: Text(S.of(context).offlineSettingsForceFullSync),
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
                _isCheckingConsistency
                    ? S.of(context).offlineSettingsChecking
                    : S.of(context).offlineSettingsCheckConsistency,
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
            title: Text(S.of(context).offlineSettingsSyncIntervalTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  SyncInterval.values.map((SyncInterval interval) {
                    return RadioListTile<SyncInterval>(
                      title: Text(_getSyncIntervalLabel(context, interval)),
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
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
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
              content: Text(
                S
                    .of(context)
                    .offlineSettingsSyncIntervalSet(
                      _getSyncIntervalLabel(context, selected),
                    ),
              ),
            ),
          );
        }
      } catch (e) {
        _log.severe('Failed to set sync interval', e);
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsFailedToUpdateSyncInterval,
          );
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
            title: Text(S.of(context).offlineSettingsConflictStrategyTitle),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    ResolutionStrategy.values.map((
                      ResolutionStrategy strategy,
                    ) {
                      return RadioListTile<ResolutionStrategy>(
                        title: Text(_getStrategyLabel(context, strategy)),
                        subtitle: Text(
                          _getStrategyDescription(context, strategy),
                        ),
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
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
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
                S
                    .of(context)
                    .offlineSettingsConflictStrategySet(
                      _getStrategyLabel(context, selected),
                    ),
              ),
            ),
          );
        }
      } catch (e) {
        _log.severe('Failed to set conflict strategy', e);
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsFailedToUpdateConflictStrategy,
          );
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
            title: Text(S.of(context).offlineSettingsClearCacheTitle),
            content: Text(S.of(context).offlineSettingsClearCacheMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(S.of(context).offlineSettingsClearCache),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).offlineSettingsCacheCleared)),
          );
        }
      } catch (e, stackTrace) {
        _log.severe('Failed to clear cache', e, stackTrace);

        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsFailedToClearCache(e.toString()),
          );
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
            title: Text(S.of(context).offlineSettingsClearAllDataTitle),
            content: Text(S.of(context).offlineSettingsClearAllDataMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(S.of(context).offlineSettingsClearAllData),
              ),
            ],
          ),
    );

    if (confirmed ?? false) {
      try {
        await settings.clearAllData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).offlineSettingsAllDataCleared),
            ),
          );
        }
      } catch (e) {
        _log.severe('Failed to clear all data', e);
        if (mounted) {
          _showError(context, S.of(context).offlineSettingsFailedToClearData);
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
        syncStatusProvider = Provider.of<SyncStatusProvider>(
          context,
          listen: false,
        );
      } catch (e) {
        _log.warning('SyncStatusProvider not available: $e');
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsSyncServiceNotAvailable,
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
          builder:
              (BuildContext context) => AlertDialog(
                content: Row(
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(S.of(context).offlineSettingsPerformingSync),
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
        _showError(
          context,
          S.of(context).offlineSettingsSyncFailed(e.toString()),
        );
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
            title: Text(S.of(context).offlineSettingsForceFullSyncTitle),
            content: Text(S.of(context).offlineSettingsForceFullSyncMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(S.of(context).offlineSettingsSyncNow),
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
          syncStatusProvider = Provider.of<SyncStatusProvider>(
            context,
            listen: false,
          );
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
            builder:
                (BuildContext context) => AlertDialog(
                  content: Row(
                    children: <Widget>[
                      const CircularProgressIndicator(),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          S.of(context).offlineSettingsPerformingFullSync,
                        ),
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
          _showError(
            context,
            S.of(context).offlineSettingsFullSyncFailed(e.toString()),
          );
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
                title: Text(
                  S.of(context).offlineSettingsConsistencyCheckComplete,
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      issues.isEmpty
                          ? S
                              .of(context)
                              .offlineSettingsConsistencyCheckNoIssues
                          : S
                              .of(context)
                              .offlineSettingsConsistencyCheckIssuesFound(
                                issues.length,
                              ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    if (issues.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        S
                            .of(context)
                            .offlineSettingsConsistencyCheckIssueBreakdown,
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
                          S
                              .of(context)
                              .offlineSettingsConsistencyCheckMoreIssues(
                                issues.length - 5,
                              ),
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
                      child: Text(
                        S.of(context).offlineSettingsRepairInconsistencies,
                      ),
                    ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(S.of(context).generalDismiss),
                  ),
                ],
              ),
        );
      }
    } catch (e, stackTrace) {
      _log.severe('Consistency check failed', e, stackTrace);
      if (mounted) {
        _showError(
          context,
          S.of(context).offlineSettingsConsistencyCheckFailed(e.toString()),
        );
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
            title: Text(S.of(context).offlineSettingsRepairInconsistencies),
            content: Text(
              S.of(context).offlineSettingsRepairInconsistenciesMessage,
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(S.of(context).offlineSettingsRepairInconsistencies),
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
                  title: Text(S.of(context).offlineSettingsRepairComplete),
                  content: Text(
                    S
                        .of(context)
                        .offlineSettingsRepairCompleteMessage(
                          result.repaired,
                          result.failed,
                        ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(S.of(context).generalDismiss),
                    ),
                  ],
                ),
          );
        }
      } catch (e, stackTrace) {
        _log.severe('Repair failed', e, stackTrace);
        if (mounted) {
          _showError(
            context,
            S.of(context).offlineSettingsRepairFailed(e.toString()),
          );
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
            title: Text(S.of(context).offlineSettingsHelpTitle),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    S.of(context).offlineSettingsHelpAutoSync,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(S.of(context).offlineSettingsHelpAutoSyncDesc),
                  const SizedBox(height: 12),
                  Text(
                    S.of(context).offlineSettingsHelpWifiOnly,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(S.of(context).offlineSettingsHelpWifiOnlyDesc),
                  const SizedBox(height: 12),
                  Text(
                    S.of(context).offlineSettingsHelpConflictResolution,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(S.of(context).offlineSettingsHelpConflictResolutionDesc),
                  const SizedBox(height: 12),
                  Text(
                    S.of(context).offlineSettingsHelpConsistencyCheck,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(S.of(context).offlineSettingsHelpConsistencyCheckDesc),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(MaterialLocalizations.of(context).closeButtonLabel),
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
          label: S.of(context).offlineSettingsDismiss,
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  /// Format DateTime for display with localization support.
  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);
    final S localizations = S.of(context);

    if (difference.inMinutes < 1) {
      return localizations.offlineSettingsJustNow;
    } else if (difference.inHours < 1) {
      return localizations.offlineSettingsMinutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return localizations.offlineSettingsHoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return localizations.offlineSettingsDaysAgo(difference.inDays);
    } else {
      return DateFormat('MMM d, y HH:mm').format(dateTime);
    }
  }

  /// Get conflict strategy label.
  String _getStrategyLabel(BuildContext context, ResolutionStrategy strategy) {
    final S localizations = S.of(context);
    switch (strategy) {
      case ResolutionStrategy.localWins:
        return localizations.offlineSettingsStrategyLocalWins;
      case ResolutionStrategy.remoteWins:
        return localizations.offlineSettingsStrategyRemoteWins;
      case ResolutionStrategy.lastWriteWins:
        return localizations.offlineSettingsStrategyLastWriteWins;
      case ResolutionStrategy.manual:
        return localizations.offlineSettingsStrategyManual;
      case ResolutionStrategy.merge:
        return localizations.offlineSettingsStrategyMerge;
    }
  }

  /// Get conflict strategy description.
  String _getStrategyDescription(
    BuildContext context,
    ResolutionStrategy strategy,
  ) {
    final S localizations = S.of(context);
    switch (strategy) {
      case ResolutionStrategy.localWins:
        return localizations.offlineSettingsStrategyLocalWinsDesc;
      case ResolutionStrategy.remoteWins:
        return localizations.offlineSettingsStrategyRemoteWinsDesc;
      case ResolutionStrategy.lastWriteWins:
        return localizations.offlineSettingsStrategyLastWriteWinsDesc;
      case ResolutionStrategy.manual:
        return localizations.offlineSettingsStrategyManualDesc;
      case ResolutionStrategy.merge:
        return localizations.offlineSettingsStrategyMergeDesc;
    }
  }

  /// Get localized label for sync interval.
  String _getSyncIntervalLabel(BuildContext context, SyncInterval interval) {
    final S localizations = S.of(context);
    switch (interval) {
      case SyncInterval.manual:
        return localizations.offlineSettingsSyncIntervalManual;
      case SyncInterval.fifteenMinutes:
        return localizations.offlineSettingsSyncInterval15Minutes;
      case SyncInterval.thirtyMinutes:
        return localizations.offlineSettingsSyncInterval30Minutes;
      case SyncInterval.oneHour:
        return localizations.offlineSettingsSyncInterval1Hour;
      case SyncInterval.sixHours:
        return localizations.offlineSettingsSyncInterval6Hours;
      case SyncInterval.twelveHours:
        return localizations.offlineSettingsSyncInterval12Hours;
      case SyncInterval.twentyFourHours:
        return localizations.offlineSettingsSyncInterval24Hours;
    }
  }
}
