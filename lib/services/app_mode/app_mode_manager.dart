import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/connectivity/connectivity_status.dart';
import 'package:waterflyiii/services/app_mode/app_mode.dart';
import 'package:waterflyiii/services/sync/sync_manager.dart';
import 'package:waterflyiii/models/sync_progress.dart';

/// Manages the application's operational mode (online/offline/syncing).
///
/// This service coordinates between connectivity status and app mode,
/// automatically switching modes based on network availability and
/// providing manual override capabilities for testing.
///
/// Features:
/// - Automatic mode switching based on connectivity
/// - Manual mode override for testing
/// - Mode persistence across app restarts
/// - Mode transition validation
/// - Comprehensive logging
///
/// Example:
/// ```dart
/// final manager = AppModeManager();
/// await manager.initialize();
///
/// // Listen to mode changes
/// manager.modeStream.listen((mode) {
///   print('App mode: ${mode.displayName}');
/// });
///
/// // Check current mode
/// if (manager.currentMode.isOffline) {
///   // Handle offline operations
/// }
/// ```
class AppModeManager {
  static final AppModeManager _instance = AppModeManager._internal();

  /// Returns the singleton instance of [AppModeManager].
  factory AppModeManager() => _instance;

  AppModeManager._internal();

  final Logger _logger = Logger('AppModeManager');
  final ConnectivityService _connectivityService = ConnectivityService();

  /// Subject for broadcasting app mode changes.
  final BehaviorSubject<AppMode> _modeSubject = BehaviorSubject<AppMode>.seeded(
    AppMode.offline,
  );

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool _manualOverride = false;
  AppMode? _manualMode;

  /// Optional SyncManager for triggering auto-sync on reconnect.
  SyncManager? _syncManager;

  /// Timestamp of last sync trigger to prevent rapid multiple triggers.
  DateTime? _lastSyncTriggerTime;
  static const Duration _syncTriggerDebounce = Duration(seconds: 5);

  static const String _prefKeyLastMode = 'app_mode_last_mode';
  static const String _prefKeyManualOverride = 'app_mode_manual_override';
  static const String _prefKeyWifiOnly = 'offline_wifi_only';

  /// Stream of app mode changes.
  ///
  /// Emits [AppMode] whenever the mode changes.
  Stream<AppMode> get modeStream => _modeSubject.stream.distinct();

  /// Current app mode.
  ///
  /// Returns the most recent app mode. If the service hasn't been
  /// initialized, returns [AppMode.offline] as a safe default.
  AppMode get currentMode => _modeSubject.value;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether manual mode override is active.
  bool get hasManualOverride => _manualOverride;

  /// Sets the SyncManager instance for auto-sync on reconnect.
  ///
  /// This should be called after SyncManager is created during app initialization.
  /// The SyncManager is optional - if not set, auto-sync on reconnect will be skipped.
  void setSyncManager(SyncManager? syncManager) {
    _syncManager = syncManager;
    _logger.info(
      syncManager != null
          ? 'SyncManager set for auto-sync on reconnect'
          : 'SyncManager cleared',
    );
  }

  /// Initializes the app mode manager.
  ///
  /// Sets up connectivity monitoring, restores last known mode,
  /// and performs initial mode determination.
  ///
  /// Should be called once during app startup.
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.warning('AppModeManager already initialized');
      return;
    }

    _logger.info('Initializing AppModeManager');

    try {
      // Initialize shared preferences
      _prefs = await SharedPreferences.getInstance();

      // Initialize connectivity service if not already initialized
      if (!_connectivityService.isInitialized) {
        await _connectivityService.initialize();
      }

      // Restore last known mode and manual override state
      await _restoreState();

      // Set up connectivity monitoring
      _connectivitySubscription = _connectivityService.statusStream.listen(
        _onConnectivityChanged,
      );

      // Determine initial mode based on current connectivity
      await _updateModeFromConnectivity();

      _isInitialized = true;
      _logger.info(
        'AppModeManager initialized successfully. Current mode: ${currentMode.displayName}',
      );
    } catch (error, stackTrace) {
      _logger.severe('Failed to initialize AppModeManager', error, stackTrace);
      rethrow;
    }
  }

  /// Restores the last known mode and manual override state.
  Future<void> _restoreState() async {
    try {
      // Restore manual override state
      _manualOverride = _prefs?.getBool(_prefKeyManualOverride) ?? false;

      if (_manualOverride) {
        // Restore manual mode
        final int? lastModeIndex = _prefs?.getInt(_prefKeyLastMode);
        if (lastModeIndex != null && lastModeIndex < AppMode.values.length) {
          _manualMode = AppMode.values[lastModeIndex];
          _updateMode(_manualMode!);
          _logger.info(
            'Restored manual mode override: ${_manualMode!.displayName}',
          );
        }
      } else {
        // Restore last automatic mode
        final int? lastModeIndex = _prefs?.getInt(_prefKeyLastMode);
        if (lastModeIndex != null && lastModeIndex < AppMode.values.length) {
          final AppMode lastMode = AppMode.values[lastModeIndex];
          _updateMode(lastMode);
          _logger.info('Restored last mode: ${lastMode.displayName}');
        }
      }
    } catch (error, stackTrace) {
      _logger.warning('Failed to restore app mode state', error, stackTrace);
      // Continue with default mode (offline)
    }
  }

  /// Handles connectivity status changes.
  void _onConnectivityChanged(ConnectivityStatus status) {
    if (_manualOverride) {
      _logger.fine(
        'Ignoring connectivity change due to manual override: $status',
      );
      return;
    }

    _logger.info('Connectivity changed: ${status.displayName}');
    _updateModeFromConnectivity();
  }

  /// Updates app mode based on current connectivity status.
  ///
  /// Checks connectivity status and network type (mobile data vs WiFi).
  /// If on mobile data and WiFi-only setting is enabled, forces offline mode.
  /// If WiFi-only is disabled, allows online mode on mobile data.
  Future<void> _updateModeFromConnectivity() async {
    if (_manualOverride) {
      return; // Don't change mode if manual override is active
    }

    final ConnectivityStatus connectivityStatus =
        _connectivityService.currentStatus;

    _logger.fine(
      'Updating mode from connectivity: status=${connectivityStatus.displayName}',
    );

    // Check if we're online
    if (connectivityStatus == ConnectivityStatus.online) {
      // Ensure connectivity is checked to get latest network type information
      await _connectivityService.checkConnectivity();

      // Get network type information (after refresh)
      final ConnectivityInfo connectivityInfo =
          _connectivityService.connectivityInfo;
      final bool isMobileData = connectivityInfo.isMobile;

      _logger.fine(
        'Connectivity is online. Network type: ${connectivityInfo.networkTypeDescription}, '
        'isMobile: $isMobileData, networkTypes: ${connectivityInfo.networkTypes}',
      );

      // If on mobile data, check WiFi-only setting
      if (isMobileData) {
        final bool wifiOnlyEnabled = _prefs?.getBool(_prefKeyWifiOnly) ?? true;

        _logger.info(
          'On mobile data connection. WiFi-only setting: $wifiOnlyEnabled',
        );

        if (wifiOnlyEnabled) {
          _logger.info(
            'WiFi-only enabled. Forcing offline mode to prevent mobile data usage.',
          );
          // Force offline mode when on mobile data and WiFi-only is enabled
          if (currentMode != AppMode.offline) {
            _updateMode(AppMode.offline);
          }
          return;
        } else {
          _logger.info(
            'WiFi-only disabled. Allowing online mode on mobile data.',
          );
          // WiFi-only is disabled, allow online mode on mobile data
          // Continue to set online mode below
        }
      } else {
        _logger.fine(
          'On WiFi/Ethernet connection. Proceeding with online mode.',
        );
      }

      // Online and either WiFi or mobile data is allowed
      if (currentMode != AppMode.online) {
        _updateMode(AppMode.online);
      }
    } else {
      // Offline or unknown - set to offline mode
      _logger.fine(
        'Connectivity is ${connectivityStatus.displayName}. Setting offline mode.',
      );
      if (currentMode != AppMode.offline) {
        _updateMode(AppMode.offline);
      }
    }
  }

  /// Updates the app mode and persists it.
  void _updateMode(AppMode newMode) {
    if (_modeSubject.value == newMode) {
      return; // No change
    }

    final AppMode oldMode = _modeSubject.value;
    _logger.info(
      'App mode changing: ${oldMode.displayName} → ${newMode.displayName}',
    );

    // Validate mode transition
    if (!_isValidTransition(oldMode, newMode)) {
      _logger.warning(
        'Invalid mode transition: ${oldMode.displayName} → ${newMode.displayName}',
      );
      return;
    }

    // Detect offline → online transition and trigger incremental sync
    if (oldMode == AppMode.offline && newMode == AppMode.online) {
      _logger.info(
        'Network reconnected: transitioning from offline to online. '
        'Triggering incremental sync...',
      );
      _triggerIncrementalSync();
    }

    _modeSubject.add(newMode);

    // Persist mode
    _prefs?.setInt(_prefKeyLastMode, newMode.index);

    _logger.info('App mode changed to: ${newMode.displayName}');
  }

  /// Validates whether a mode transition is allowed.
  bool _isValidTransition(AppMode from, AppMode to) {
    // All transitions are valid except:
    // - Cannot go directly from offline to syncing (must go through online)
    if (from == AppMode.offline && to == AppMode.syncing) {
      return false;
    }

    return true;
  }

  /// Sets the app mode to syncing.
  ///
  /// This should be called when synchronization starts.
  /// Can only be called when in online mode.
  ///
  /// Returns `true` if the mode was changed, `false` otherwise.
  bool startSyncing() {
    if (currentMode != AppMode.online) {
      _logger.warning(
        'Cannot start syncing from ${currentMode.displayName} mode',
      );
      return false;
    }

    _updateMode(AppMode.syncing);
    return true;
  }

  /// Sets the app mode back to online after syncing completes.
  ///
  /// This should be called when synchronization finishes.
  /// Can only be called when in syncing mode.
  ///
  /// Returns `true` if the mode was changed, `false` otherwise.
  bool stopSyncing() {
    if (currentMode != AppMode.syncing) {
      _logger.warning(
        'Cannot stop syncing from ${currentMode.displayName} mode',
      );
      return false;
    }

    _updateMode(AppMode.online);
    return true;
  }

  /// Manually sets the app mode.
  ///
  /// This overrides automatic mode switching based on connectivity.
  /// Useful for testing and debugging.
  ///
  /// To restore automatic mode switching, call [clearManualOverride].
  Future<void> setManualMode(AppMode mode) async {
    _logger.info('Setting manual mode override: ${mode.displayName}');

    _manualOverride = true;
    _manualMode = mode;
    _updateMode(mode);

    await _prefs?.setBool(_prefKeyManualOverride, true);
  }

  /// Clears manual mode override and restores automatic mode switching.
  Future<void> clearManualOverride() async {
    if (!_manualOverride) {
      return;
    }

    _logger.info('Clearing manual mode override');

    _manualOverride = false;
    _manualMode = null;

    await _prefs?.setBool(_prefKeyManualOverride, false);

    // Update mode based on current connectivity
    await _updateModeFromConnectivity();
  }

  /// Forces a mode check based on current connectivity.
  ///
  /// Useful for manually triggering mode updates.
  Future<void> checkMode() async {
    _logger.fine('Manually checking app mode');
    await _connectivityService.checkConnectivity();
    await _updateModeFromConnectivity();
  }

  /// Triggers incremental synchronization when network reconnects.
  ///
  /// This is called automatically when transitioning from offline to online mode.
  /// The sync runs in the background (fire and forget) and errors are logged
  /// but don't affect the mode transition.
  ///
  /// Features:
  /// - Debouncing to prevent multiple rapid triggers
  /// - Checks if sync is already in progress
  /// - Respects manual override (doesn't trigger if override is active)
  /// - Graceful error handling
  void _triggerIncrementalSync() {
    // Don't trigger if manual override is active
    if (_manualOverride) {
      _logger.fine(
        'Skipping auto-sync trigger: manual override is active',
      );
      return;
    }

    // Don't trigger if SyncManager is not available
    if (_syncManager == null) {
      _logger.fine(
        'Skipping auto-sync trigger: SyncManager not available',
      );
      return;
    }

    // Check if sync is already in progress
    if (_syncManager!.isSyncing) {
      _logger.fine(
        'Skipping auto-sync trigger: sync already in progress',
      );
      return;
    }

    // Debounce: prevent multiple rapid triggers
    final DateTime now = DateTime.now();
    if (_lastSyncTriggerTime != null) {
      final Duration timeSinceLastTrigger =
          now.difference(_lastSyncTriggerTime!);
      if (timeSinceLastTrigger < _syncTriggerDebounce) {
        _logger.fine(
          'Skipping auto-sync trigger: debounce period not elapsed '
          '(${timeSinceLastTrigger.inSeconds}s < ${_syncTriggerDebounce.inSeconds}s)',
        );
        return;
      }
    }

    _lastSyncTriggerTime = now;
    _logger.info('Triggering incremental sync on network reconnect');

    // Fire and forget - don't block mode change
    _syncManager!
        .synchronize(fullSync: false)
        .then((SyncResult result) {
      _logger.info(
        'Auto-sync on reconnect completed: '
        'success=${result.success}, '
        'operations=${result.totalOperations}, '
        'successful=${result.successfulOperations}, '
        'failed=${result.failedOperations}',
      );
    }).catchError((error, stackTrace) {
      _logger.warning(
        'Auto-sync on reconnect failed (non-blocking)',
        error,
        stackTrace,
      );
    });
  }

  /// Disposes of the service and releases resources.
  Future<void> dispose() async {
    _logger.info('Disposing AppModeManager');

    await _connectivitySubscription?.cancel();
    await _modeSubject.close();

    _isInitialized = false;
  }
}
