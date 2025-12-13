import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../connectivity/connectivity_service.dart';
import '../connectivity/connectivity_status.dart';
import 'app_mode.dart';

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
  final BehaviorSubject<AppMode> _modeSubject =
      BehaviorSubject<AppMode>.seeded(AppMode.offline);

  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;
  SharedPreferences? _prefs;

  bool _isInitialized = false;
  bool _manualOverride = false;
  AppMode? _manualMode;

  static const String _prefKeyLastMode = 'app_mode_last_mode';
  static const String _prefKeyManualOverride = 'app_mode_manual_override';

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
      _connectivitySubscription =
          _connectivityService.statusStream.listen(_onConnectivityChanged);

      // Determine initial mode based on current connectivity
      await _updateModeFromConnectivity();

      _isInitialized = true;
      _logger.info(
        'AppModeManager initialized successfully. Current mode: ${currentMode.displayName}',
      );
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to initialize AppModeManager',
        error,
        stackTrace,
      );
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
        final lastModeIndex = _prefs?.getInt(_prefKeyLastMode);
        if (lastModeIndex != null && lastModeIndex < AppMode.values.length) {
          _manualMode = AppMode.values[lastModeIndex];
          _updateMode(_manualMode!);
          _logger.info(
            'Restored manual mode override: ${_manualMode!.displayName}',
          );
        }
      } else {
        // Restore last automatic mode
        final lastModeIndex = _prefs?.getInt(_prefKeyLastMode);
        if (lastModeIndex != null && lastModeIndex < AppMode.values.length) {
          final lastMode = AppMode.values[lastModeIndex];
          _updateMode(lastMode);
          _logger.info('Restored last mode: ${lastMode.displayName}');
        }
      }
    } catch (error, stackTrace) {
      _logger.warning(
        'Failed to restore app mode state',
        error,
        stackTrace,
      );
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
  Future<void> _updateModeFromConnectivity() async {
    if (_manualOverride) {
      return; // Don't change mode if manual override is active
    }

    final connectivityStatus = _connectivityService.currentStatus;

    final newMode = switch (connectivityStatus) {
      ConnectivityStatus.online => AppMode.online,
      ConnectivityStatus.offline => AppMode.offline,
      ConnectivityStatus.unknown => AppMode.offline, // Safe default
    };

    if (newMode != currentMode) {
      _updateMode(newMode);
    }
  }

  /// Updates the app mode and persists it.
  void _updateMode(AppMode newMode) {
    if (_modeSubject.value == newMode) {
      return; // No change
    }

    final oldMode = _modeSubject.value;
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

  /// Disposes of the service and releases resources.
  Future<void> dispose() async {
    _logger.info('Disposing AppModeManager');

    await _connectivitySubscription?.cancel();
    await _modeSubject.close();

    _isInitialized = false;
  }
}
