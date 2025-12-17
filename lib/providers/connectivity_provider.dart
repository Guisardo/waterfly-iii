import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/connectivity/connectivity_status.dart';

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

  ConnectivityStatus _status = ConnectivityStatus.unknown;
  bool _isInitialized = false;

  /// Current connectivity status.
  ConnectivityStatus get status => _status;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Whether the device is online.
  bool get isOnline => _status.isOnline;

  /// Whether the device is offline.
  bool get isOffline => _status.isOffline;

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

  /// Human-readable network type description.
  String get networkTypeDescription => connectivityInfo.networkTypeDescription;

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
  Future<bool> checkConnectivity() async {
    final bool isOnline = await _connectivityService.checkConnectivity();
    _status = _connectivityService.currentStatus;
    notifyListeners();
    return isOnline;
  }

  /// Checks if the server is reachable.
  ///
  /// Returns `true` if the Firefly III server can be reached.
  Future<bool> checkServerReachability() async {
    return _connectivityService.checkServerReachability();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }
}
