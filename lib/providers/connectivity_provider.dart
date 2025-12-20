import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/connectivity/connectivity_status.dart';
import 'package:waterflyiii/services/app_mode/app_mode.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';

/// Provider for connectivity status that integrates with Flutter's state management.
///
/// This provider wraps the [ConnectivityService] and exposes its state
/// to the UI layer using [ChangeNotifier]. It automatically updates
/// when connectivity status changes.
///
/// Example usage with Provider package:
/// ```dart
/// ChangeNotifierProvider(
///   create: (_) => ConnectivityProvider()..initialize(),
///   child: MyApp(),
/// )
///
/// // In a widget:
/// final connectivity = context.watch<ConnectivityProvider>();
/// if (connectivity.isOffline) {
///   // Show offline indicator
/// }
/// ```
class ConnectivityProvider extends ChangeNotifier {
  /// Creates a connectivity provider.
  ConnectivityProvider({ConnectivityService? connectivityService})
    : _connectivityService = connectivityService ?? ConnectivityService();

  final ConnectivityService _connectivityService;
  final AppModeManager _appModeManager = AppModeManager();

  ConnectivityStatus _status = ConnectivityStatus.unknown;
  bool _isInitialized = false;
  StreamSubscription<AppMode>? _appModeSubscription;

  /// Current connectivity status (respects app mode for WiFi-only setting).
  ///
  /// Returns offline if app mode is offline (e.g., WiFi-only enabled on mobile),
  /// even if raw connectivity is online.
  ConnectivityStatus get status {
    // If app mode is offline, return offline regardless of raw connectivity
    if (_appModeManager.isInitialized &&
        _appModeManager.currentMode == AppMode.offline) {
      return ConnectivityStatus.offline;
    }
    return _status;
  }

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the device is online (respects app mode).
  ///
  /// Returns false if app mode is offline (e.g., WiFi-only enabled on mobile),
  /// even if raw connectivity is online.
  bool get isOnline => status.isOnline;

  /// Whether the device is offline (respects app mode).
  ///
  /// Returns true if app mode is offline (e.g., WiFi-only enabled on mobile),
  /// even if raw connectivity is online.
  bool get isOffline => status.isOffline;

  /// Whether the connectivity status is unknown.
  bool get isUnknown => _status.isUnknown;

  /// Human-readable status string.
  String get statusText => _status.displayName;

  /// Current network types (WiFi, mobile, ethernet, etc.).
  List<ConnectivityResult> get networkTypes =>
      _connectivityService.currentNetworkTypes;

  /// Detailed connectivity information including network type.
  ConnectivityInfo get connectivityInfo =>
      _connectivityService.connectivityInfo;

  /// Human-readable network type description (English, for logging/debugging).
  ///
  /// For UI display, use [getLocalizedNetworkTypeDescription] instead.
  String get networkTypeDescription => connectivityInfo.networkTypeDescription;

  /// Get localized network type description for UI display.
  String getLocalizedNetworkTypeDescription(BuildContext context) =>
      connectivityInfo.getLocalizedNetworkTypeDescription(context);

  /// Initializes the connectivity provider.
  ///
  /// Sets up the connectivity service and starts listening to status changes.
  /// Should be called once during app initialization.
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _connectivityService.initialize();

    // Set initial status
    _status = _connectivityService.currentStatus;

    // Listen to status changes
    _connectivityService.statusStream.listen(_onStatusChanged);

    // Listen to app mode changes to update effective status
    _appModeSubscription = _appModeManager.modeStream.listen((_) {
      // App mode changed - notify listeners so they get updated effective status
      notifyListeners();
    });

    _isInitialized = true;
    notifyListeners();
  }

  /// Handles connectivity status changes.
  void _onStatusChanged(ConnectivityStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      notifyListeners();
    }
  }

  /// Manually triggers a connectivity check.
  ///
  /// Useful for pull-to-refresh or manual retry scenarios.
  /// Returns effective online status (respects app mode).
  Future<bool> checkConnectivity() async {
    await _connectivityService.checkConnectivity();
    _status = _connectivityService.currentStatus;
    notifyListeners();
    // Return effective status (considering app mode)
    return isOnline;
  }

  /// Checks if the server is reachable.
  ///
  /// Returns `true` if the Firefly III server can be reached.
  Future<bool> checkServerReachability() {
    return _connectivityService.checkServerReachability();
  }

  @override
  void dispose() {
    _appModeSubscription?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}
