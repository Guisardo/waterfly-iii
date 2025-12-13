import 'package:flutter/foundation.dart';
import 'package:waterflyiii/services/app_mode/app_mode.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';

/// Provider for app mode that integrates with Flutter's state management.
///
/// This provider wraps the [AppModeManager] and exposes its state
/// to the UI layer using [ChangeNotifier]. It automatically updates
/// when the app mode changes.
///
/// Example usage with Provider package:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => AppModeProvider()..initialize(),
///   child: MyApp(),
/// )
///
/// // In a widget:
/// final appMode = context.watch<AppModeProvider>();
/// if (appMode.isOffline) {
///   // Show offline mode UI
/// }
/// ```
class AppModeProvider extends ChangeNotifier {
  /// Creates an app mode provider.
  AppModeProvider({AppModeManager? appModeManager})
      : _appModeManager = appModeManager ?? AppModeManager();

  final AppModeManager _appModeManager;

  AppMode _mode = AppMode.offline;
  bool _isInitialized = false;

  /// Current app mode.
  AppMode get mode => _mode;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the app is in online mode.
  bool get isOnline => _mode.isOnline;

  /// Whether the app is in offline mode.
  bool get isOffline => _mode.isOffline;

  /// Whether the app is currently syncing.
  bool get isSyncing => _mode.isSyncing;

  /// Whether operations should be queued.
  bool get shouldQueueOperations => _mode.shouldQueueOperations;

  /// Whether the app can use network.
  bool get canUseNetwork => _mode.canUseNetwork;

  /// Human-readable mode string.
  String get modeText => _mode.displayName;

  /// Detailed mode description.
  String get modeDescription => _mode.description;

  /// Whether manual mode override is active.
  bool get hasManualOverride => _appModeManager.hasManualOverride;

  /// Initializes the app mode provider.
  ///
  /// Sets up the app mode manager and starts listening to mode changes.
  /// Should be called once during app initialization.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _appModeManager.initialize();
    
    // Set initial mode
    _mode = _appModeManager.currentMode;
    
    // Listen to mode changes
    _appModeManager.modeStream.listen(_onModeChanged);
    
    _isInitialized = true;
    notifyListeners();
  }

  /// Handles app mode changes.
  void _onModeChanged(AppMode newMode) {
    if (_mode != newMode) {
      _mode = newMode;
      notifyListeners();
    }
  }

  /// Starts syncing mode.
  ///
  /// Transitions from online to syncing mode.
  /// Returns `true` if successful, `false` if transition is not allowed.
  bool startSyncing() {
    final success = _appModeManager.startSyncing();
    if (success) {
      _mode = _appModeManager.currentMode;
      notifyListeners();
    }
    return success;
  }

  /// Stops syncing mode.
  ///
  /// Transitions from syncing back to online mode.
  /// Returns `true` if successful, `false` if transition is not allowed.
  bool stopSyncing() {
    final success = _appModeManager.stopSyncing();
    if (success) {
      _mode = _appModeManager.currentMode;
      notifyListeners();
    }
    return success;
  }

  /// Manually sets the app mode.
  ///
  /// This overrides automatic mode switching. Useful for testing.
  /// To restore automatic mode, call [clearManualOverride].
  Future<void> setManualMode(AppMode mode) async {
    await _appModeManager.setManualMode(mode);
    _mode = _appModeManager.currentMode;
    notifyListeners();
  }

  /// Clears manual mode override.
  ///
  /// Restores automatic mode switching based on connectivity.
  Future<void> clearManualOverride() async {
    await _appModeManager.clearManualOverride();
    _mode = _appModeManager.currentMode;
    notifyListeners();
  }

  /// Forces a mode check.
  ///
  /// Manually triggers mode update based on current connectivity.
  Future<void> checkMode() async {
    await _appModeManager.checkMode();
    _mode = _appModeManager.currentMode;
    notifyListeners();
  }

  @override
  void dispose() {
    _appModeManager.dispose();
    super.dispose();
  }
}
