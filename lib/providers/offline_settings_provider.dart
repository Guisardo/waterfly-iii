import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/services/sync/background_sync_scheduler.dart';

final Logger _log = Logger('OfflineSettingsProvider');

/// Sync interval options for background synchronization.
enum SyncInterval {
  manual('Manual', null),
  fifteenMinutes('15 minutes', Duration(minutes: 15)),
  thirtyMinutes('30 minutes', Duration(minutes: 30)),
  oneHour('1 hour', Duration(hours: 1)),
  sixHours('6 hours', Duration(hours: 6)),
  twelveHours('12 hours', Duration(hours: 12)),
  twentyFourHours('24 hours', Duration(hours: 24));

  const SyncInterval(this.label, this.duration);

  final String label;
  final Duration? duration;
}

/// Provider for managing offline mode settings.
///
/// Handles:
/// - Sync interval configuration
/// - Auto-sync toggle
/// - WiFi-only sync restriction
/// - Conflict resolution strategy
/// - Storage management
/// - Sync statistics
///
/// Uses SharedPreferences for persistence and notifies listeners on changes.
class OfflineSettingsProvider extends ChangeNotifier {
  OfflineSettingsProvider({
    required SharedPreferences prefs,
    BackgroundSyncScheduler? syncScheduler,
  })  : _prefs = prefs,
        _syncScheduler = syncScheduler {
    _loadSettings();
  }

  final SharedPreferences _prefs;
  final BackgroundSyncScheduler? _syncScheduler;

  // Settings keys
  static const String _keySyncInterval = 'offline_sync_interval';
  static const String _keyAutoSync = 'offline_auto_sync';
  static const String _keyWifiOnly = 'offline_wifi_only';
  static const String _keyConflictStrategy = 'offline_conflict_strategy';
  static const String _keyLastSyncTime = 'offline_last_sync_time';
  static const String _keyNextSyncTime = 'offline_next_sync_time';
  static const String _keyTotalSyncs = 'offline_total_syncs';
  static const String _keyTotalConflicts = 'offline_total_conflicts';
  static const String _keyTotalErrors = 'offline_total_errors';
  static const String _keyDatabaseSize = 'offline_database_size';

  // Settings values
  SyncInterval _syncInterval = SyncInterval.oneHour;
  bool _autoSyncEnabled = true;
  bool _wifiOnlyEnabled = false;
  ResolutionStrategy _conflictStrategy =
      ResolutionStrategy.lastWriteWins;
  DateTime? _lastSyncTime;
  DateTime? _nextSyncTime;
  int _totalSyncs = 0;
  int _totalConflicts = 0;
  int _totalErrors = 0;
  int _databaseSize = 0;

  // Loading state
  bool _isLoading = false;

  // Getters
  SyncInterval get syncInterval => _syncInterval;
  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get wifiOnlyEnabled => _wifiOnlyEnabled;
  ResolutionStrategy get conflictStrategy => _conflictStrategy;
  DateTime? get lastSyncTime => _lastSyncTime;
  DateTime? get nextSyncTime => _nextSyncTime;
  int get totalSyncs => _totalSyncs;
  int get totalConflicts => _totalConflicts;
  int get totalErrors => _totalErrors;
  int get databaseSize => _databaseSize;
  bool get isLoading => _isLoading;

  /// Load settings from SharedPreferences.
  void _loadSettings() {
    _log.info('Loading offline settings from SharedPreferences');

    try {
      // Load sync interval
      final intervalIndex = _prefs.getInt(_keySyncInterval);
      if (intervalIndex != null &&
          intervalIndex >= 0 &&
          intervalIndex < SyncInterval.values.length) {
        _syncInterval = SyncInterval.values[intervalIndex];
      }

      // Load boolean settings
      _autoSyncEnabled = _prefs.getBool(_keyAutoSync) ?? true;
      _wifiOnlyEnabled = _prefs.getBool(_keyWifiOnly) ?? false;

      // Load conflict strategy
      final strategyIndex = _prefs.getInt(_keyConflictStrategy);
      if (strategyIndex != null &&
          strategyIndex >= 0 &&
          strategyIndex < ResolutionStrategy.values.length) {
        _conflictStrategy = ResolutionStrategy.values[strategyIndex];
      }

      // Load statistics
      final lastSyncMillis = _prefs.getInt(_keyLastSyncTime);
      if (lastSyncMillis != null) {
        _lastSyncTime =
            DateTime.fromMillisecondsSinceEpoch(lastSyncMillis, isUtc: true);
      }

      final nextSyncMillis = _prefs.getInt(_keyNextSyncTime);
      if (nextSyncMillis != null) {
        _nextSyncTime =
            DateTime.fromMillisecondsSinceEpoch(nextSyncMillis, isUtc: true);
      }

      _totalSyncs = _prefs.getInt(_keyTotalSyncs) ?? 0;
      _totalConflicts = _prefs.getInt(_keyTotalConflicts) ?? 0;
      _totalErrors = _prefs.getInt(_keyTotalErrors) ?? 0;
      _databaseSize = _prefs.getInt(_keyDatabaseSize) ?? 0;

      _log.info('Loaded settings: interval=$_syncInterval, '
          'autoSync=$_autoSyncEnabled, wifiOnly=$_wifiOnlyEnabled, '
          'strategy=$_conflictStrategy');
    } catch (e, stackTrace) {
      _log.severe('Failed to load offline settings', e, stackTrace);
    }
  }

  /// Set sync interval and update background scheduler.
  Future<void> setSyncInterval(SyncInterval interval) async {
    _log.info('Setting sync interval to: ${interval.label}');

    try {
      _syncInterval = interval;
      await _prefs.setInt(_keySyncInterval, interval.index);

      // Update background scheduler if auto-sync is enabled
      if (_autoSyncEnabled && _syncScheduler != null) {
        if (interval == SyncInterval.manual) {
          await _syncScheduler!.cancelAll();
          _log.info('Cancelled scheduled sync (manual mode)');
        } else if (interval.duration != null) {
          await _syncScheduler!.schedulePeriodicSync(interval: interval.duration!);
          _log.info('Scheduled periodic sync: ${interval.duration}');
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set sync interval', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle auto-sync and update background scheduler.
  Future<void> setAutoSyncEnabled(bool enabled) async {
    _log.info('Setting auto-sync enabled: $enabled');

    try {
      _autoSyncEnabled = enabled;
      await _prefs.setBool(_keyAutoSync, enabled);

      // Update background scheduler
      if (_syncScheduler != null) {
        if (enabled && _syncInterval.duration != null) {
          await _syncScheduler!.schedulePeriodicSync(interval: _syncInterval.duration!);
          _log.info('Enabled periodic sync: ${_syncInterval.duration}');
        } else {
          await _syncScheduler!.cancelAll();
          _log.info('Disabled periodic sync');
        }
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set auto-sync enabled', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle WiFi-only sync restriction.
  Future<void> setWifiOnlyEnabled(bool enabled) async {
    _log.info('Setting WiFi-only enabled: $enabled');

    try {
      _wifiOnlyEnabled = enabled;
      await _prefs.setBool(_keyWifiOnly, enabled);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set WiFi-only enabled', e, stackTrace);
      rethrow;
    }
  }

  /// Set conflict resolution strategy.
  Future<void> setConflictStrategy(ResolutionStrategy strategy) async {
    _log.info('Setting conflict resolution strategy: $strategy');

    try {
      _conflictStrategy = strategy;
      await _prefs.setInt(_keyConflictStrategy, strategy.index);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set conflict strategy', e, stackTrace);
      rethrow;
    }
  }

  /// Update sync statistics.
  Future<void> updateSyncStatistics({
    DateTime? lastSync,
    DateTime? nextSync,
    int? totalSyncs,
    int? totalConflicts,
    int? totalErrors,
  }) async {
    _log.fine('Updating sync statistics');

    try {
      if (lastSync != null) {
        _lastSyncTime = lastSync;
        await _prefs.setInt(
            _keyLastSyncTime, lastSync.millisecondsSinceEpoch);
      }

      if (nextSync != null) {
        _nextSyncTime = nextSync;
        await _prefs.setInt(
            _keyNextSyncTime, nextSync.millisecondsSinceEpoch);
      }

      if (totalSyncs != null) {
        _totalSyncs = totalSyncs;
        await _prefs.setInt(_keyTotalSyncs, totalSyncs);
      }

      if (totalConflicts != null) {
        _totalConflicts = totalConflicts;
        await _prefs.setInt(_keyTotalConflicts, totalConflicts);
      }

      if (totalErrors != null) {
        _totalErrors = totalErrors;
        await _prefs.setInt(_keyTotalErrors, totalErrors);
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to update sync statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Update database size.
  Future<void> updateDatabaseSize(int sizeInBytes) async {
    _log.fine('Updating database size: $sizeInBytes bytes');

    try {
      _databaseSize = sizeInBytes;
      await _prefs.setInt(_keyDatabaseSize, sizeInBytes);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to update database size', e, stackTrace);
      rethrow;
    }
  }

  /// Clear all offline data and reset statistics.
  Future<void> clearAllData() async {
    _log.warning('Clearing all offline data');

    try {
      _isLoading = true;
      notifyListeners();

      // Reset statistics
      _lastSyncTime = null;
      _nextSyncTime = null;
      _totalSyncs = 0;
      _totalConflicts = 0;
      _totalErrors = 0;
      _databaseSize = 0;

      // Clear from preferences
      await _prefs.remove(_keyLastSyncTime);
      await _prefs.remove(_keyNextSyncTime);
      await _prefs.remove(_keyTotalSyncs);
      await _prefs.remove(_keyTotalConflicts);
      await _prefs.remove(_keyTotalErrors);
      await _prefs.remove(_keyDatabaseSize);

      _log.info('Cleared all offline data');
    } catch (e, stackTrace) {
      _log.severe('Failed to clear offline data', e, stackTrace);
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Format database size for display.
  String get formattedDatabaseSize {
    if (_databaseSize < 1024) {
      return '$_databaseSize B';
    } else if (_databaseSize < 1024 * 1024) {
      return '${(_databaseSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(_databaseSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Get success rate as percentage.
  double get successRate {
    if (_totalSyncs == 0) return 100.0;
    final successfulSyncs = _totalSyncs - _totalErrors;
    return (successfulSyncs / _totalSyncs) * 100;
  }
}
