import 'package:shared_preferences/shared_preferences.dart';

/// Configuration settings for offline mode functionality.
///
/// This class manages all configurable aspects of offline mode including
/// sync behavior, storage limits, and feature toggles.
///
/// Settings are persisted using SharedPreferences and can be modified
/// through the app's settings UI.
class OfflineConfig {
  static final OfflineConfig _instance = OfflineConfig._internal();

  /// Returns the singleton instance of [OfflineConfig].
  factory OfflineConfig() => _instance;

  OfflineConfig._internal();

  SharedPreferences? _prefs;

  // Preference keys
  static const String _keyOfflineModeEnabled = 'offline_mode_enabled';
  static const String _keyAutoSyncEnabled = 'offline_auto_sync_enabled';
  static const String _keySyncFrequency = 'offline_sync_frequency_minutes';
  static const String _keyMaxRetryAttempts = 'offline_max_retry_attempts';
  static const String _keyDataRetentionDays = 'offline_data_retention_days';
  static const String _keyCacheSizeLimitMB = 'offline_cache_size_limit_mb';
  static const String _keyBackgroundSyncEnabled =
      'offline_background_sync_enabled';
  static const String _keySyncOnlyOnWifi = 'offline_sync_only_on_wifi';
  static const String _keyConflictResolutionStrategy =
      'offline_conflict_resolution_strategy';

  // Default values
  static const bool _defaultOfflineModeEnabled = true;
  static const bool _defaultAutoSyncEnabled = true;
  static const int _defaultSyncFrequencyMinutes = 15;
  static const int _defaultMaxRetryAttempts = 3;
  static const int _defaultDataRetentionDays = 30;
  static const int _defaultCacheSizeLimitMB = 100;
  static const bool _defaultBackgroundSyncEnabled = true;
  static const bool _defaultSyncOnlyOnWifi = false;
  static const String _defaultConflictResolutionStrategy = 'last_write_wins';

  /// Initializes the configuration by loading SharedPreferences.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Whether offline mode is enabled.
  ///
  /// When disabled, the app will always operate in online mode and
  /// will not queue operations for offline sync.
  bool get offlineModeEnabled {
    return _prefs?.getBool(_keyOfflineModeEnabled) ??
        _defaultOfflineModeEnabled;
  }

  set offlineModeEnabled(bool value) {
    _prefs?.setBool(_keyOfflineModeEnabled, value);
  }

  /// Whether automatic synchronization is enabled.
  ///
  /// When enabled, the app will automatically sync queued operations
  /// when connectivity is restored.
  bool get autoSyncEnabled {
    return _prefs?.getBool(_keyAutoSyncEnabled) ?? _defaultAutoSyncEnabled;
  }

  set autoSyncEnabled(bool value) {
    _prefs?.setBool(_keyAutoSyncEnabled, value);
  }

  /// Frequency of automatic sync checks in minutes.
  ///
  /// Determines how often the app checks for pending sync operations
  /// when online. Default is 15 minutes.
  int get syncFrequencyMinutes {
    return _prefs?.getInt(_keySyncFrequency) ?? _defaultSyncFrequencyMinutes;
  }

  set syncFrequencyMinutes(int value) {
    if (value < 1) {
      throw ArgumentError('Sync frequency must be at least 1 minute');
    }
    _prefs?.setInt(_keySyncFrequency, value);
  }

  /// Maximum number of retry attempts for failed sync operations.
  ///
  /// After this many failures, the operation will be marked as failed
  /// and require manual intervention. Default is 3.
  int get maxRetryAttempts {
    return _prefs?.getInt(_keyMaxRetryAttempts) ?? _defaultMaxRetryAttempts;
  }

  set maxRetryAttempts(int value) {
    if (value < 1) {
      throw ArgumentError('Max retry attempts must be at least 1');
    }
    _prefs?.setInt(_keyMaxRetryAttempts, value);
  }

  /// Number of days to retain completed sync operations.
  ///
  /// Completed operations older than this will be automatically deleted
  /// to save storage space. Default is 30 days.
  int get dataRetentionDays {
    return _prefs?.getInt(_keyDataRetentionDays) ?? _defaultDataRetentionDays;
  }

  set dataRetentionDays(int value) {
    if (value < 1) {
      throw ArgumentError('Data retention must be at least 1 day');
    }
    _prefs?.setInt(_keyDataRetentionDays, value);
  }

  /// Maximum cache size in megabytes.
  ///
  /// When the cache exceeds this size, older data will be pruned.
  /// Default is 100 MB.
  int get cacheSizeLimitMB {
    return _prefs?.getInt(_keyCacheSizeLimitMB) ?? _defaultCacheSizeLimitMB;
  }

  set cacheSizeLimitMB(int value) {
    if (value < 10) {
      throw ArgumentError('Cache size limit must be at least 10 MB');
    }
    _prefs?.setInt(_keyCacheSizeLimitMB, value);
  }

  /// Whether background synchronization is enabled.
  ///
  /// When enabled, the app will sync in the background even when closed.
  /// Requires appropriate platform permissions.
  bool get backgroundSyncEnabled {
    return _prefs?.getBool(_keyBackgroundSyncEnabled) ??
        _defaultBackgroundSyncEnabled;
  }

  set backgroundSyncEnabled(bool value) {
    _prefs?.setBool(_keyBackgroundSyncEnabled, value);
  }

  /// Whether to sync only when connected to WiFi.
  ///
  /// When enabled, sync operations will not run on mobile data to
  /// save bandwidth. Default is false.
  bool get syncOnlyOnWifi {
    return _prefs?.getBool(_keySyncOnlyOnWifi) ?? _defaultSyncOnlyOnWifi;
  }

  set syncOnlyOnWifi(bool value) {
    _prefs?.setBool(_keySyncOnlyOnWifi, value);
  }

  /// Strategy for resolving conflicts during synchronization.
  ///
  /// Possible values:
  /// - 'last_write_wins': Most recent modification wins
  /// - 'server_wins': Server version always wins
  /// - 'local_wins': Local version always wins
  /// - 'manual': Prompt user to resolve conflicts
  ///
  /// Default is 'last_write_wins'.
  String get conflictResolutionStrategy {
    return _prefs?.getString(_keyConflictResolutionStrategy) ??
        _defaultConflictResolutionStrategy;
  }

  set conflictResolutionStrategy(String value) {
    final List<String> validStrategies = <String>[
      'last_write_wins',
      'server_wins',
      'local_wins',
      'manual',
    ];
    if (!validStrategies.contains(value)) {
      throw ArgumentError(
        'Invalid conflict resolution strategy: $value. '
        'Must be one of: ${validStrategies.join(", ")}',
      );
    }
    _prefs?.setString(_keyConflictResolutionStrategy, value);
  }

  /// Resets all settings to their default values.
  Future<void> resetToDefaults() async {
    await _prefs?.setBool(_keyOfflineModeEnabled, _defaultOfflineModeEnabled);
    await _prefs?.setBool(_keyAutoSyncEnabled, _defaultAutoSyncEnabled);
    await _prefs?.setInt(_keySyncFrequency, _defaultSyncFrequencyMinutes);
    await _prefs?.setInt(_keyMaxRetryAttempts, _defaultMaxRetryAttempts);
    await _prefs?.setInt(_keyDataRetentionDays, _defaultDataRetentionDays);
    await _prefs?.setInt(_keyCacheSizeLimitMB, _defaultCacheSizeLimitMB);
    await _prefs?.setBool(
      _keyBackgroundSyncEnabled,
      _defaultBackgroundSyncEnabled,
    );
    await _prefs?.setBool(_keySyncOnlyOnWifi, _defaultSyncOnlyOnWifi);
    await _prefs?.setString(
      _keyConflictResolutionStrategy,
      _defaultConflictResolutionStrategy,
    );
  }

  /// Returns a map of all current settings.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'offlineModeEnabled': offlineModeEnabled,
      'autoSyncEnabled': autoSyncEnabled,
      'syncFrequencyMinutes': syncFrequencyMinutes,
      'maxRetryAttempts': maxRetryAttempts,
      'dataRetentionDays': dataRetentionDays,
      'cacheSizeLimitMB': cacheSizeLimitMB,
      'backgroundSyncEnabled': backgroundSyncEnabled,
      'syncOnlyOnWifi': syncOnlyOnWifi,
      'conflictResolutionStrategy': conflictResolutionStrategy,
    };
  }
}
