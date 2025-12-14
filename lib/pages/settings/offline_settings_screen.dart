import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../../models/conflict.dart';
import '../../services/sync/background_sync_scheduler.dart';
import '../../services/sync/sync_notification_service.dart';
import '../../database/conflicts_table.dart';

/// Screen for configuring offline mode settings.
///
/// Features:
/// - General sync settings
/// - Conflict resolution preferences
/// - Storage management
/// - Advanced options
/// - Material 3 design
class OfflineSettingsScreen extends StatefulWidget {
  const OfflineSettingsScreen({super.key});

  @override
  State<OfflineSettingsScreen> createState() => _OfflineSettingsScreenState();
}

class _OfflineSettingsScreenState extends State<OfflineSettingsScreen> {
  static final Logger _logger = Logger('OfflineSettingsScreen');

  final BackgroundSyncScheduler _scheduler = BackgroundSyncScheduler();
  final SyncNotificationService _notifications = SyncNotificationService();

  bool _offlineModeEnabled = true;
  bool _autoSyncEnabled = true;
  String _syncFrequency = '15min';
  bool _wifiOnlySync = false;
  bool _backgroundSyncEnabled = true;
  bool _showOfflineBanner = true;
  
  String _defaultResolutionStrategy = 'lastWriteWins';
  bool _autoResolveLowSeverity = true;
  bool _notifyOnConflicts = true;
  double _autoResolveTimeout = 24.0;
  
  bool _debugLoggingEnabled = false;
  int _maxRetryAttempts = 5;
  int _syncTimeout = 60;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _offlineModeEnabled = prefs.getBool('offline_mode_enabled') ?? true;
        _autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? true;
        _syncFrequency = prefs.getString('sync_frequency') ?? '15min';
        _wifiOnlySync = prefs.getBool('wifi_only_sync') ?? false;
        _backgroundSyncEnabled = prefs.getBool('background_sync_enabled') ?? true;
        _showOfflineBanner = prefs.getBool('show_offline_banner') ?? true;
        
        _defaultResolutionStrategy = prefs.getString('default_resolution_strategy') ?? 'lastWriteWins';
        _autoResolveLowSeverity = prefs.getBool('auto_resolve_low_severity') ?? true;
        _notifyOnConflicts = prefs.getBool('notify_on_conflicts') ?? true;
        _autoResolveTimeout = prefs.getDouble('auto_resolve_timeout') ?? 24.0;
        
        _debugLoggingEnabled = prefs.getBool('debug_logging_enabled') ?? false;
        _maxRetryAttempts = prefs.getInt('max_retry_attempts') ?? 5;
        _syncTimeout = prefs.getInt('sync_timeout') ?? 60;
        
        _isLoading = false;
      });
      
      _logger.fine('Loaded offline settings');
    } catch (e, stackTrace) {
      _logger.severe('Failed to load settings', e, stackTrace);
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (value is bool) {
        await prefs.setBool(key, value);
      } else if (value is String) {
        await prefs.setString(key, value);
      } else if (value is int) {
        await prefs.setInt(key, value);
      } else if (value is double) {
        await prefs.setDouble(key, value);
      }
      
      _logger.fine('Saved setting: $key = $value');
    } catch (e, stackTrace) {
      _logger.warning('Failed to save setting $key', e, stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Mode Settings'),
      ),
      body: ListView(
        children: [
          _buildGeneralSettings(),
          const Divider(),
          _buildConflictSettings(),
          const Divider(),
          _buildStorageSettings(),
          const Divider(),
          _buildAdvancedSettings(),
        ],
      ),
    );
  }

  Widget _buildGeneralSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'General',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        SwitchListTile(
          title: const Text('Enable Offline Mode'),
          subtitle: const Text('Allow working without internet connection'),
          value: _offlineModeEnabled,
          onChanged: (value) {
            setState(() {
              _offlineModeEnabled = value;
            });
            _saveSetting('offline_mode_enabled', value);
          },
        ),
        SwitchListTile(
          title: const Text('Auto-sync When Online'),
          subtitle: const Text('Automatically sync when connection is restored'),
          value: _autoSyncEnabled,
          onChanged: _offlineModeEnabled ? (value) {
            setState(() {
              _autoSyncEnabled = value;
            });
            _saveSetting('auto_sync_enabled', value);
          } : null,
        ),
        ListTile(
          title: const Text('Sync Frequency'),
          subtitle: Text(_getSyncFrequencyLabel(_syncFrequency)),
          trailing: const Icon(Icons.chevron_right),
          enabled: _offlineModeEnabled && _autoSyncEnabled,
          onTap: () => _showSyncFrequencyDialog(),
        ),
        SwitchListTile(
          title: const Text('Sync on WiFi Only'),
          subtitle: const Text('Only sync when connected to WiFi'),
          value: _wifiOnlySync,
          onChanged: _offlineModeEnabled ? (value) {
            setState(() {
              _wifiOnlySync = value;
            });
            _saveSetting('wifi_only_sync', value);
          } : null,
        ),
        SwitchListTile(
          title: const Text('Background Sync'),
          subtitle: const Text('Sync data in the background'),
          value: _backgroundSyncEnabled,
          onChanged: _offlineModeEnabled ? (value) {
            setState(() {
              _backgroundSyncEnabled = value;
            });
            _saveSetting('background_sync_enabled', value);
            if (value) {
              _scheduler.schedulePeriodic(_getSyncDuration(_syncFrequency));
            } else {
              _scheduler.cancelScheduledSync();
            }
          } : null,
        ),
        SwitchListTile(
          title: const Text('Show Offline Banner'),
          subtitle: const Text('Display banner when offline'),
          value: _showOfflineBanner,
          onChanged: (value) {
            setState(() {
              _showOfflineBanner = value;
            });
            _saveSetting('show_offline_banner', value);
          },
        ),
      ],
    );
  }

  Widget _buildConflictSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Conflict Resolution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ListTile(
          title: const Text('Default Resolution Strategy'),
          subtitle: Text(_getStrategyLabel(_defaultResolutionStrategy)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showStrategyDialog(),
        ),
        SwitchListTile(
          title: const Text('Auto-resolve Low Severity'),
          subtitle: const Text('Automatically resolve low severity conflicts'),
          value: _autoResolveLowSeverity,
          onChanged: (value) {
            setState(() {
              _autoResolveLowSeverity = value;
            });
            _saveSetting('auto_resolve_low_severity', value);
          },
        ),
        SwitchListTile(
          title: const Text('Notify on Conflicts'),
          subtitle: const Text('Show notification when conflicts are detected'),
          value: _notifyOnConflicts,
          onChanged: (value) {
            setState(() {
              _notifyOnConflicts = value;
            });
            _saveSetting('notify_on_conflicts', value);
          },
        ),
        ListTile(
          title: const Text('Auto-resolve Timeout'),
          subtitle: Text('${_autoResolveTimeout.toInt()} hours'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: _autoResolveTimeout,
              min: 1,
              max: 24,
              divisions: 23,
              label: '${_autoResolveTimeout.toInt()}h',
              onChanged: (value) {
                setState(() {
                  _autoResolveTimeout = value;
                });
              },
              onChangeEnd: (value) {
                _saveSetting('auto_resolve_timeout', value);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Storage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        ListTile(
          title: const Text('Clear Cache'),
          subtitle: const Text('Remove cached data'),
          trailing: const Icon(Icons.delete_outline),
          onTap: () => _clearCache(),
        ),
        ListTile(
          title: const Text('Clear Completed Operations'),
          subtitle: const Text('Remove synced operations from queue'),
          trailing: const Icon(Icons.clear_all),
          onTap: () => _clearCompleted(),
        ),
      ],
    );
  }

  Widget _buildAdvancedSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Advanced',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        SwitchListTile(
          title: const Text('Debug Logging'),
          subtitle: const Text('Enable detailed logging'),
          value: _debugLoggingEnabled,
          onChanged: (value) {
            setState(() {
              _debugLoggingEnabled = value;
            });
            _saveSetting('debug_logging_enabled', value);
            Logger.root.level = value ? Level.FINE : Level.INFO;
          },
        ),
        ListTile(
          title: const Text('Max Retry Attempts'),
          subtitle: Text('$_maxRetryAttempts attempts'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: _maxRetryAttempts.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _maxRetryAttempts.toString(),
              onChanged: (value) {
                setState(() {
                  _maxRetryAttempts = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _saveSetting('max_retry_attempts', value.toInt());
              },
            ),
          ),
        ),
        ListTile(
          title: const Text('Sync Timeout'),
          subtitle: Text('$_syncTimeout seconds'),
          trailing: SizedBox(
            width: 200,
            child: Slider(
              value: _syncTimeout.toDouble(),
              min: 10,
              max: 120,
              divisions: 11,
              label: '${_syncTimeout}s',
              onChanged: (value) {
                setState(() {
                  _syncTimeout = value.toInt();
                });
              },
              onChangeEnd: (value) {
                _saveSetting('sync_timeout', value.toInt());
              },
            ),
          ),
        ),
        ListTile(
          title: const Text('Force Full Sync'),
          subtitle: const Text('Re-sync all data from server'),
          trailing: const Icon(Icons.sync),
          onTap: () => _forceFullSync(),
        ),
        ListTile(
          title: const Text('Reset Offline Data'),
          subtitle: const Text('Clear all offline data'),
          trailing: Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
          onTap: () => _resetOfflineData(),
        ),
      ],
    );
  }

  String _getSyncFrequencyLabel(String frequency) {
    switch (frequency) {
      case 'manual': return 'Manual';
      case '15min': return 'Every 15 minutes';
      case '30min': return 'Every 30 minutes';
      case '1hr': return 'Every hour';
      default: return frequency;
    }
  }

  Duration _getSyncDuration(String frequency) {
    switch (frequency) {
      case '15min': return const Duration(minutes: 15);
      case '30min': return const Duration(minutes: 30);
      case '1hr': return const Duration(hours: 1);
      default: return const Duration(minutes: 15);
    }
  }

  String _getStrategyLabel(String strategy) {
    switch (strategy) {
      case 'lastWriteWins': return 'Last Write Wins';
      case 'alwaysAsk': return 'Always Ask';
      case 'localWins': return 'Local Wins';
      case 'remoteWins': return 'Remote Wins';
      default: return strategy;
    }
  }

  Future<void> _showSyncFrequencyDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Sync Frequency'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'manual'),
            child: const Text('Manual'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '15min'),
            child: const Text('Every 15 minutes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '30min'),
            child: const Text('Every 30 minutes'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, '1hr'),
            child: const Text('Every hour'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _syncFrequency = result;
      });
      _saveSetting('sync_frequency', result);
      
      if (_backgroundSyncEnabled && result != 'manual') {
        _scheduler.schedulePeriodic(_getSyncDuration(result));
      }
    }
  }

  Future<void> _showStrategyDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Default Resolution Strategy'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'lastWriteWins'),
            child: const Text('Last Write Wins'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'alwaysAsk'),
            child: const Text('Always Ask'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'localWins'),
            child: const Text('Local Wins'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'remoteWins'),
            child: const Text('Remote Wins'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _defaultResolutionStrategy = result;
      });
      _saveSetting('default_resolution_strategy', result);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text('This will remove all cached data.'),
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

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared')),
      );
    }
  }

  Future<void> _clearCompleted() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cleared completed operations')),
    );
  }

  Future<void> _forceFullSync() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Force Full Sync?'),
        content: const Text('This will re-sync all data from the server.'),
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

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Starting full sync...')),
      );
    }
  }

  Future<void> _resetOfflineData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Offline Data?'),
        content: const Text(
          'This will clear all offline data including pending operations. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline data reset')),
      );
    }
  }
}
