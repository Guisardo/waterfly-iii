import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
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

/// Sync window options for incremental sync date range.
///
/// Determines how far back the incremental sync will look for changes.
/// Shorter windows are more efficient but may miss older changes.
/// Longer windows catch more changes but use more bandwidth.
enum SyncWindow {
  sevenDays('7 days', 7),
  fourteenDays('14 days', 14),
  thirtyDays('30 days', 30),
  sixtyDays('60 days', 60),
  ninetyDays('90 days', 90);

  const SyncWindow(this.label, this.days);

  final String label;
  final int days;
}

/// Cache TTL options for Tier 2 entities (categories, bills, piggy banks).
///
/// These entities change infrequently and use extended cache TTL
/// to minimize API calls.
enum CacheTtl {
  oneHour('1 hour', 1),
  sixHours('6 hours', 6),
  twelveHours('12 hours', 12),
  twentyFourHours('24 hours', 24),
  fortyEightHours('48 hours', 48);

  const CacheTtl(this.label, this.hours);

  final String label;
  final int hours;
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
  SharedPreferences? _prefs;
  BackgroundSyncScheduler? _syncScheduler;
  bool _isInitialized = false;
  bool _isLoading = true;

  /// Factory constructor for creating OfflineSettingsProvider.
  ///
  /// This constructor initializes the provider asynchronously.
  /// The provider will be in a loading state until initialization completes.
  factory OfflineSettingsProvider.create() {
    final provider = OfflineSettingsProvider._internal();
    provider._initializeAsync();
    return provider;
  }

  /// Internal constructor for async initialization.
  OfflineSettingsProvider._internal() : _syncScheduler = null;

  /// Constructor with pre-initialized SharedPreferences.
  ///
  /// Use this when SharedPreferences is already available.
  OfflineSettingsProvider.withPrefs({
    required SharedPreferences prefs,
    BackgroundSyncScheduler? syncScheduler,
  }) : _prefs = prefs,
       _syncScheduler = syncScheduler {
    _isLoading = false;
    _isInitialized = true;
    _loadSettings();
  }

  /// Initialize the provider asynchronously.
  Future<void> _initializeAsync() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _prefs = prefs;
      _syncScheduler = BackgroundSyncScheduler(prefs);
      _loadSettings();

      // Load existing statistics from database if available
      await _loadStatisticsFromDatabase();

      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    } catch (error, stackTrace) {
      final Logger log = Logger('OfflineSettingsProvider');
      log.severe(
        'Failed to initialize OfflineSettingsProvider',
        error,
        stackTrace,
      );
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load aggregated statistics from database sync_statistics table.
  ///
  /// This syncs the provider with existing database statistics that may have
  /// been written by IncrementalSyncService but not yet synced to SharedPreferences.
  Future<void> _loadStatisticsFromDatabase() async {
    try {
      final AppDatabase database = AppDatabase();
      // Import the generated types - they're available through app_database.dart
      final allStats = await database.select(database.syncStatistics).get();

      if (allStats.isEmpty) {
        return;
      }

      // Aggregate statistics across all entity types
      int totalFetched = 0;
      int totalUpdated = 0;
      int totalSkipped = 0;
      int totalBandwidthSaved = 0;
      int totalApiCallsSaved = 0;
      DateTime? latestIncrementalSync;
      DateTime? latestFullSync;

      for (final stats in allStats) {
        totalFetched += stats.itemsFetchedTotal;
        totalUpdated += stats.itemsUpdatedTotal;
        totalSkipped += stats.itemsSkippedTotal;
        totalBandwidthSaved += stats.bandwidthSavedBytes;
        totalApiCallsSaved += stats.apiCallsSavedCount;

        // lastIncrementalSync is not nullable, always has a value
        if (latestIncrementalSync == null ||
            stats.lastIncrementalSync.isAfter(latestIncrementalSync)) {
          latestIncrementalSync = stats.lastIncrementalSync;
        }

        // lastFullSync is nullable
        if (stats.lastFullSync != null) {
          if (latestFullSync == null ||
              stats.lastFullSync!.isAfter(latestFullSync)) {
            latestFullSync = stats.lastFullSync;
          }
        }
      }

      // Only update if database has more recent data than SharedPreferences
      // (i.e., if SharedPreferences values are 0 or database has newer timestamp)
      final bool shouldUpdate =
          _totalItemsFetched == 0 ||
          (latestIncrementalSync != null &&
              (_lastIncrementalSyncTime == null ||
                  latestIncrementalSync.isAfter(_lastIncrementalSyncTime!)));

      if (shouldUpdate && totalFetched > 0) {
        // Update in-memory values
        _totalItemsFetched = totalFetched;
        _totalItemsUpdated = totalUpdated;
        _totalItemsSkipped = totalSkipped;
        _totalBandwidthSaved = totalBandwidthSaved;
        _totalApiCallsSaved = totalApiCallsSaved;

        if (latestIncrementalSync != null) {
          _lastIncrementalSyncTime = latestIncrementalSync;
        }
        if (latestFullSync != null) {
          _lastFullSyncTime = latestFullSync;
        }

        // Persist to SharedPreferences
        if (_prefs != null) {
          await _prefs!.setInt(_keyTotalItemsFetched, _totalItemsFetched);
          await _prefs!.setInt(_keyTotalItemsUpdated, _totalItemsUpdated);
          await _prefs!.setInt(_keyTotalItemsSkipped, _totalItemsSkipped);
          await _prefs!.setInt(_keyTotalBandwidthSaved, _totalBandwidthSaved);
          await _prefs!.setInt(_keyTotalApiCallsSaved, _totalApiCallsSaved);

          if (_lastIncrementalSyncTime != null) {
            await _prefs!.setInt(
              _keyLastIncrementalSync,
              _lastIncrementalSyncTime!.millisecondsSinceEpoch,
            );
          }
          if (_lastFullSyncTime != null) {
            await _prefs!.setInt(
              _keyLastFullSync,
              _lastFullSyncTime!.millisecondsSinceEpoch,
            );
          }
        }
      }
    } catch (e, stackTrace) {
      _log.warning('Failed to load statistics from database', e, stackTrace);
      // Don't fail initialization if database read fails
    }
  }

  /// Whether the provider is currently loading.
  bool get isLoading => _isLoading;

  /// Whether the provider has been initialized.
  bool get isInitialized => _isInitialized;

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

  // Incremental sync settings keys
  static const String _keyIncrementalSyncEnabled = 'incremental_sync_enabled';
  static const String _keySyncWindow = 'incremental_sync_window';
  static const String _keyCacheTtl = 'incremental_cache_ttl';
  static const String _keyLastIncrementalSync = 'last_incremental_sync_time';
  static const String _keyLastFullSync = 'last_full_sync_time';
  static const String _keyTotalItemsFetched = 'incremental_total_fetched';
  static const String _keyTotalItemsUpdated = 'incremental_total_updated';
  static const String _keyTotalItemsSkipped = 'incremental_total_skipped';
  static const String _keyTotalBandwidthSaved = 'incremental_bandwidth_saved';
  static const String _keyTotalApiCallsSaved = 'incremental_api_calls_saved';
  static const String _keyIncrementalSyncCount = 'incremental_sync_count';

  // Settings values
  SyncInterval _syncInterval = SyncInterval.oneHour;
  bool _autoSyncEnabled = true;
  bool _wifiOnlyEnabled = true;
  ResolutionStrategy _conflictStrategy = ResolutionStrategy.lastWriteWins;
  DateTime? _lastSyncTime;
  DateTime? _nextSyncTime;
  int _totalSyncs = 0;
  int _totalConflicts = 0;
  int _totalErrors = 0;
  int _databaseSize = 0;

  // Incremental sync settings values
  bool _incrementalSyncEnabled = true;
  SyncWindow _syncWindow = SyncWindow.thirtyDays;
  CacheTtl _cacheTtl = CacheTtl.twentyFourHours;
  DateTime? _lastIncrementalSyncTime;
  DateTime? _lastFullSyncTime;
  int _totalItemsFetched = 0;
  int _totalItemsUpdated = 0;
  int _totalItemsSkipped = 0;
  int _totalBandwidthSaved = 0;
  int _totalApiCallsSaved = 0;
  int _incrementalSyncCount = 0;

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

  // Incremental sync getters

  /// Whether incremental sync is enabled.
  ///
  /// When enabled, syncs fetch only changed data since last sync.
  /// When disabled, each sync fetches all data (full sync).
  bool get incrementalSyncEnabled => _incrementalSyncEnabled;

  /// Sync window for incremental sync (how far back to look for changes).
  SyncWindow get syncWindow => _syncWindow;

  /// Cache TTL for Tier 2 entities (categories, bills, piggy banks).
  CacheTtl get cacheTtl => _cacheTtl;

  /// Timestamp of last incremental sync.
  DateTime? get lastIncrementalSyncTime => _lastIncrementalSyncTime;

  /// Timestamp of last full sync.
  DateTime? get lastFullSyncTime => _lastFullSyncTime;

  /// Total items fetched across all incremental syncs.
  int get totalItemsFetched => _totalItemsFetched;

  /// Total items updated (had changes) across all incremental syncs.
  int get totalItemsUpdated => _totalItemsUpdated;

  /// Total items skipped (no changes) across all incremental syncs.
  int get totalItemsSkipped => _totalItemsSkipped;

  /// Total bandwidth saved in bytes across all incremental syncs.
  int get totalBandwidthSaved => _totalBandwidthSaved;

  /// Total API calls saved across all incremental syncs.
  int get totalApiCallsSaved => _totalApiCallsSaved;

  /// Total number of incremental sync operations performed.
  int get incrementalSyncCount => _incrementalSyncCount;

  /// Overall skip rate across all incremental syncs (percentage).
  double get overallSkipRate {
    if (_totalItemsFetched == 0) return 0.0;
    return (_totalItemsSkipped / _totalItemsFetched) * 100.0;
  }

  /// Overall update rate across all incremental syncs (percentage).
  double get overallUpdateRate {
    if (_totalItemsFetched == 0) return 0.0;
    return (_totalItemsUpdated / _totalItemsFetched) * 100.0;
  }

  /// Format bandwidth saved as human-readable string.
  String get formattedBandwidthSaved {
    if (_totalBandwidthSaved < 1024) {
      return '$_totalBandwidthSaved B';
    } else if (_totalBandwidthSaved < 1024 * 1024) {
      return '${(_totalBandwidthSaved / 1024).toStringAsFixed(1)} KB';
    } else if (_totalBandwidthSaved < 1024 * 1024 * 1024) {
      return '${(_totalBandwidthSaved / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(_totalBandwidthSaved / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Check if full sync is needed (>7 days since last full sync).
  bool get needsFullSync {
    if (_lastFullSyncTime == null) return true;
    final int daysSinceFullSync =
        DateTime.now().difference(_lastFullSyncTime!).inDays;
    return daysSinceFullSync > 7;
  }

  /// Get days since last incremental sync.
  int get daysSinceLastIncrementalSync {
    if (_lastIncrementalSyncTime == null) return -1;
    return DateTime.now().difference(_lastIncrementalSyncTime!).inDays;
  }

  /// Get days since last full sync.
  int get daysSinceLastFullSync {
    if (_lastFullSyncTime == null) return -1;
    return DateTime.now().difference(_lastFullSyncTime!).inDays;
  }

  /// Load settings from SharedPreferences.
  void _loadSettings() {
    if (_prefs == null) {
      return; // Not initialized yet
    }
    _log.info('Loading offline settings from SharedPreferences');

    try {
      // Load sync interval
      final int? intervalIndex = _prefs!.getInt(_keySyncInterval);
      if (intervalIndex != null &&
          intervalIndex >= 0 &&
          intervalIndex < SyncInterval.values.length) {
        _syncInterval = SyncInterval.values[intervalIndex];
      }

      // Load boolean settings
      _autoSyncEnabled = _prefs!.getBool(_keyAutoSync) ?? true;
      _wifiOnlyEnabled = _prefs!.getBool(_keyWifiOnly) ?? true;

      // Load conflict strategy
      final int? strategyIndex = _prefs!.getInt(_keyConflictStrategy);
      if (strategyIndex != null &&
          strategyIndex >= 0 &&
          strategyIndex < ResolutionStrategy.values.length) {
        _conflictStrategy = ResolutionStrategy.values[strategyIndex];
      }

      // Load statistics
      final int? lastSyncMillis = _prefs!.getInt(_keyLastSyncTime);
      if (lastSyncMillis != null) {
        _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(
          lastSyncMillis,
          isUtc: true,
        );
      }

      final int? nextSyncMillis = _prefs!.getInt(_keyNextSyncTime);
      if (nextSyncMillis != null) {
        _nextSyncTime = DateTime.fromMillisecondsSinceEpoch(
          nextSyncMillis,
          isUtc: true,
        );
      }

      _totalSyncs = _prefs!.getInt(_keyTotalSyncs) ?? 0;
      _totalConflicts = _prefs!.getInt(_keyTotalConflicts) ?? 0;
      _totalErrors = _prefs!.getInt(_keyTotalErrors) ?? 0;
      _databaseSize = _prefs!.getInt(_keyDatabaseSize) ?? 0;

      // Load incremental sync settings
      _incrementalSyncEnabled =
          _prefs!.getBool(_keyIncrementalSyncEnabled) ?? true;

      final int? syncWindowIndex = _prefs!.getInt(_keySyncWindow);
      if (syncWindowIndex != null &&
          syncWindowIndex >= 0 &&
          syncWindowIndex < SyncWindow.values.length) {
        _syncWindow = SyncWindow.values[syncWindowIndex];
      }

      final int? cacheTtlIndex = _prefs!.getInt(_keyCacheTtl);
      if (cacheTtlIndex != null &&
          cacheTtlIndex >= 0 &&
          cacheTtlIndex < CacheTtl.values.length) {
        _cacheTtl = CacheTtl.values[cacheTtlIndex];
      }

      // Load incremental sync timestamps
      final int? lastIncrementalMillis = _prefs!.getInt(
        _keyLastIncrementalSync,
      );
      if (lastIncrementalMillis != null) {
        _lastIncrementalSyncTime = DateTime.fromMillisecondsSinceEpoch(
          lastIncrementalMillis,
          isUtc: true,
        );
      }

      final int? lastFullMillis = _prefs!.getInt(_keyLastFullSync);
      if (lastFullMillis != null) {
        _lastFullSyncTime = DateTime.fromMillisecondsSinceEpoch(
          lastFullMillis,
          isUtc: true,
        );
      }

      // Load incremental sync statistics
      _totalItemsFetched = _prefs!.getInt(_keyTotalItemsFetched) ?? 0;
      _totalItemsUpdated = _prefs!.getInt(_keyTotalItemsUpdated) ?? 0;
      _totalItemsSkipped = _prefs!.getInt(_keyTotalItemsSkipped) ?? 0;
      _totalBandwidthSaved = _prefs!.getInt(_keyTotalBandwidthSaved) ?? 0;
      _totalApiCallsSaved = _prefs!.getInt(_keyTotalApiCallsSaved) ?? 0;
      _incrementalSyncCount = _prefs!.getInt(_keyIncrementalSyncCount) ?? 0;

      _log.info(
        'Loaded settings: interval=$_syncInterval, '
        'autoSync=$_autoSyncEnabled, wifiOnly=$_wifiOnlyEnabled, '
        'strategy=$_conflictStrategy, '
        'incrementalSync=$_incrementalSyncEnabled, '
        'syncWindow=${_syncWindow.label}, cacheTtl=${_cacheTtl.label}',
      );
    } catch (e, stackTrace) {
      _log.severe('Failed to load offline settings', e, stackTrace);
    }
  }

  /// Set sync interval and update background scheduler.
  Future<void> setSyncInterval(SyncInterval interval) async {
    if (_prefs == null) {
      throw StateError('OfflineSettingsProvider not initialized');
    }

    _log.info('Setting sync interval to: ${interval.label}');

    try {
      _syncInterval = interval;
      await _prefs!.setInt(_keySyncInterval, interval.index);

      // Update background scheduler if auto-sync is enabled
      if (_autoSyncEnabled && _syncScheduler != null) {
        if (interval == SyncInterval.manual) {
          await _syncScheduler!.cancelAll();
          _log.info('Cancelled scheduled sync (manual mode)');
        } else if (interval.duration != null) {
          await _syncScheduler!.schedulePeriodicSync(
            interval: interval.duration!,
          );
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
      await _prefs!.setBool(_keyAutoSync, enabled);

      // Update background scheduler
      if (_syncScheduler != null) {
        if (enabled && _syncInterval.duration != null) {
          await _syncScheduler!.schedulePeriodicSync(
            interval: _syncInterval.duration!,
          );
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
      await _prefs!.setBool(_keyWifiOnly, enabled);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set WiFi-only enabled', e, stackTrace);
      rethrow;
    }
  }

  /// Toggle mobile data allowance for syncing.
  ///
  /// When enabled, the app will allow syncing over mobile data connections.
  /// When disabled (default), mobile data connections are treated as offline mode.
  /// Set conflict resolution strategy.
  Future<void> setConflictStrategy(ResolutionStrategy strategy) async {
    _log.info('Setting conflict resolution strategy: $strategy');

    try {
      _conflictStrategy = strategy;
      await _prefs!.setInt(_keyConflictStrategy, strategy.index);
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
        await _prefs!.setInt(_keyLastSyncTime, lastSync.millisecondsSinceEpoch);
      }

      if (nextSync != null) {
        _nextSyncTime = nextSync;
        await _prefs!.setInt(_keyNextSyncTime, nextSync.millisecondsSinceEpoch);
      }

      if (totalSyncs != null) {
        _totalSyncs = totalSyncs;
        await _prefs!.setInt(_keyTotalSyncs, totalSyncs);
      }

      if (totalConflicts != null) {
        _totalConflicts = totalConflicts;
        await _prefs!.setInt(_keyTotalConflicts, totalConflicts);
      }

      if (totalErrors != null) {
        _totalErrors = totalErrors;
        await _prefs!.setInt(_keyTotalErrors, totalErrors);
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
      if (_prefs == null) {
        _log.warning(
          'Cannot update database size: SharedPreferences not initialized',
        );
        return;
      }

      _databaseSize = sizeInBytes;
      await _prefs!.setInt(_keyDatabaseSize, sizeInBytes);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to update database size', e, stackTrace);
      rethrow;
    }
  }

  // ==================== Incremental Sync Settings ====================

  /// Toggle incremental sync on/off.
  ///
  /// When enabled, syncs fetch only changed data since last sync using
  /// the three-tier strategy (date-range filtered, extended cache, sync window).
  /// When disabled, each sync fetches all data (full sync).
  ///
  /// Parameters:
  /// - [enabled]: Whether to enable incremental sync.
  ///
  /// Throws on failure to persist setting.
  Future<void> setIncrementalSyncEnabled(bool enabled) async {
    _log.info('Setting incremental sync enabled: $enabled');

    try {
      _incrementalSyncEnabled = enabled;
      await _prefs!.setBool(_keyIncrementalSyncEnabled, enabled);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set incremental sync enabled', e, stackTrace);
      rethrow;
    }
  }

  /// Set sync window (how far back to look for changes).
  ///
  /// Shorter windows are more efficient but may miss older changes.
  /// Longer windows catch more changes but use more bandwidth.
  ///
  /// Parameters:
  /// - [window]: The sync window to use.
  ///
  /// Throws on failure to persist setting.
  Future<void> setSyncWindow(SyncWindow window) async {
    _log.info('Setting sync window: ${window.label}');

    try {
      _syncWindow = window;
      await _prefs!.setInt(_keySyncWindow, window.index);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set sync window', e, stackTrace);
      rethrow;
    }
  }

  /// Set cache TTL for Tier 2 entities.
  ///
  /// Categories, bills, and piggy banks use extended cache TTL
  /// to minimize API calls since they change infrequently.
  ///
  /// Parameters:
  /// - [ttl]: The cache TTL to use.
  ///
  /// Throws on failure to persist setting.
  Future<void> setCacheTtl(CacheTtl ttl) async {
    _log.info('Setting cache TTL: ${ttl.label}');

    try {
      _cacheTtl = ttl;
      await _prefs!.setInt(_keyCacheTtl, ttl.index);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to set cache TTL', e, stackTrace);
      rethrow;
    }
  }

  /// Update incremental sync statistics after a sync operation.
  ///
  /// Called by the IncrementalSyncService after completing a sync
  /// to track cumulative statistics.
  ///
  /// Parameters:
  /// - [isIncremental]: Whether this was an incremental sync (vs full).
  /// - [itemsFetched]: Number of items fetched from server.
  /// - [itemsUpdated]: Number of items that had changes.
  /// - [itemsSkipped]: Number of items that were unchanged.
  /// - [bandwidthSaved]: Estimated bandwidth saved in bytes.
  /// - [apiCallsSaved]: Number of API calls avoided.
  ///
  /// Throws on failure to persist statistics.
  Future<void> updateIncrementalSyncStatistics({
    required bool isIncremental,
    int itemsFetched = 0,
    int itemsUpdated = 0,
    int itemsSkipped = 0,
    int bandwidthSaved = 0,
    int apiCallsSaved = 0,
  }) async {
    _log.fine(
      'Updating incremental sync statistics: '
      'fetched=$itemsFetched, updated=$itemsUpdated, skipped=$itemsSkipped',
    );

    try {
      // Update timestamps
      final DateTime now = DateTime.now();
      if (isIncremental) {
        _lastIncrementalSyncTime = now;
        await _prefs!.setInt(
          _keyLastIncrementalSync,
          now.millisecondsSinceEpoch,
        );
        _incrementalSyncCount++;
        await _prefs!.setInt(_keyIncrementalSyncCount, _incrementalSyncCount);
      } else {
        _lastFullSyncTime = now;
        await _prefs!.setInt(_keyLastFullSync, now.millisecondsSinceEpoch);
      }

      // Accumulate statistics
      _totalItemsFetched += itemsFetched;
      _totalItemsUpdated += itemsUpdated;
      _totalItemsSkipped += itemsSkipped;
      _totalBandwidthSaved += bandwidthSaved;
      _totalApiCallsSaved += apiCallsSaved;

      // Persist accumulated statistics
      await _prefs!.setInt(_keyTotalItemsFetched, _totalItemsFetched);
      await _prefs!.setInt(_keyTotalItemsUpdated, _totalItemsUpdated);
      await _prefs!.setInt(_keyTotalItemsSkipped, _totalItemsSkipped);
      await _prefs!.setInt(_keyTotalBandwidthSaved, _totalBandwidthSaved);
      await _prefs!.setInt(_keyTotalApiCallsSaved, _totalApiCallsSaved);

      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe(
        'Failed to update incremental sync statistics',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Record a full sync completion.
  ///
  /// Called when a full sync completes to update the last full sync timestamp.
  /// This is important for the incremental sync fallback logic.
  Future<void> recordFullSyncCompleted() async {
    _log.info('Recording full sync completed');

    try {
      final DateTime now = DateTime.now();
      _lastFullSyncTime = now;
      await _prefs!.setInt(_keyLastFullSync, now.millisecondsSinceEpoch);
      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to record full sync completed', e, stackTrace);
      rethrow;
    }
  }

  /// Reset incremental sync statistics.
  ///
  /// Clears all accumulated statistics while preserving settings.
  /// Useful for troubleshooting or starting fresh.
  Future<void> resetIncrementalSyncStatistics() async {
    _log.warning('Resetting incremental sync statistics');

    try {
      _totalItemsFetched = 0;
      _totalItemsUpdated = 0;
      _totalItemsSkipped = 0;
      _totalBandwidthSaved = 0;
      _totalApiCallsSaved = 0;
      _incrementalSyncCount = 0;
      _lastIncrementalSyncTime = null;
      _lastFullSyncTime = null;

      if (_prefs != null) {
        await _prefs!.remove(_keyTotalItemsFetched);
        await _prefs!.remove(_keyTotalItemsUpdated);
        await _prefs!.remove(_keyTotalItemsSkipped);
        await _prefs!.remove(_keyTotalBandwidthSaved);
        await _prefs!.remove(_keyTotalApiCallsSaved);
        await _prefs!.remove(_keyIncrementalSyncCount);
        await _prefs!.remove(_keyLastIncrementalSync);
        await _prefs!.remove(_keyLastFullSync);
      }

      notifyListeners();
    } catch (e, stackTrace) {
      _log.severe('Failed to reset incremental sync statistics', e, stackTrace);
      rethrow;
    }
  }

  /// Clear all offline data and reset statistics.
  ///
  /// Clears both general offline statistics and incremental sync statistics.
  /// Settings (sync interval, conflict strategy, etc.) are preserved.
  Future<void> clearAllData() async {
    _log.warning('Clearing all offline data');

    try {
      _isLoading = true;
      notifyListeners();

      // Reset general statistics
      _lastSyncTime = null;
      _nextSyncTime = null;
      _totalSyncs = 0;
      _totalConflicts = 0;
      _totalErrors = 0;
      _databaseSize = 0;

      // Clear general statistics from preferences
      if (_prefs != null) {
        await _prefs!.remove(_keyLastSyncTime);
        await _prefs!.remove(_keyNextSyncTime);
        await _prefs!.remove(_keyTotalSyncs);
        await _prefs!.remove(_keyTotalConflicts);
        await _prefs!.remove(_keyTotalErrors);
        await _prefs!.remove(_keyDatabaseSize);
      }

      // Reset incremental sync statistics
      _totalItemsFetched = 0;
      _totalItemsUpdated = 0;
      _totalItemsSkipped = 0;
      _totalBandwidthSaved = 0;
      _totalApiCallsSaved = 0;
      _incrementalSyncCount = 0;
      _lastIncrementalSyncTime = null;
      _lastFullSyncTime = null;

      // Clear incremental sync statistics from preferences
      if (_prefs != null) {
        await _prefs!.remove(_keyTotalItemsFetched);
        await _prefs!.remove(_keyTotalItemsUpdated);
        await _prefs!.remove(_keyTotalItemsSkipped);
        await _prefs!.remove(_keyTotalBandwidthSaved);
        await _prefs!.remove(_keyTotalApiCallsSaved);
        await _prefs!.remove(_keyIncrementalSyncCount);
        await _prefs!.remove(_keyLastIncrementalSync);
        await _prefs!.remove(_keyLastFullSync);
      }

      _log.info(
        'Cleared all offline data including incremental sync statistics',
      );
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
    final int successfulSyncs = _totalSyncs - _totalErrors;
    return (successfulSyncs / _totalSyncs) * 100;
  }
}
