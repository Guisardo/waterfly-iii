import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import 'package:waterflyiii/services/connectivity/connectivity_status.dart';

/// Service for monitoring network connectivity and server reachability.
///
/// This service provides real-time connectivity status updates and methods
/// to check if the device has network access and can reach the Firefly III server.
///
/// Features:
/// - Real-time connectivity monitoring
/// - Debounced status changes to prevent rapid fluctuations
/// - Server reachability checks
/// - Automatic periodic checks when offline
/// - App lifecycle awareness
///
/// Example:
/// ```dart
/// final service = ConnectivityService();
/// await service.initialize();
///
/// // Listen to connectivity changes
/// service.statusStream.listen((status) {
///   print('Connectivity: ${status.displayName}');
/// });
///
/// // Check current status
/// final isOnline = await service.checkConnectivity();
/// ```
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  
  /// Returns the singleton instance of [ConnectivityService].
  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Logger _logger = Logger('ConnectivityService');
  final Connectivity _connectivity = Connectivity();
  final InternetConnection _internetChecker = InternetConnection();

  /// Subject for broadcasting connectivity status changes.
  final BehaviorSubject<ConnectivityStatus> _statusSubject =
      BehaviorSubject<ConnectivityStatus>.seeded(ConnectivityStatus.unknown);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  StreamSubscription<InternetStatus>? _internetSubscription;
  Timer? _periodicCheckTimer;

  bool _isInitialized = false;
  bool _isCheckingConnectivity = false;

  /// Stream of connectivity status changes.
  ///
  /// Emits [ConnectivityStatus] whenever the connectivity state changes.
  /// The stream is debounced by 500ms to prevent rapid status changes.
  Stream<ConnectivityStatus> get statusStream =>
      _statusSubject.stream.debounceTime(const Duration(milliseconds: 500));

  /// Current connectivity status.
  ///
  /// Returns the most recent connectivity status. If the service hasn't
  /// been initialized, returns [ConnectivityStatus.unknown].
  ConnectivityStatus get currentStatus => _statusSubject.value;

  /// Whether the service has been initialized.
  bool get isInitialized => _isInitialized;

  /// Initializes the connectivity service.
  ///
  /// Sets up listeners for connectivity changes and performs an initial
  /// connectivity check. Should be called once during app startup.
  ///
  /// Throws [StateError] if the service is already initialized.
  Future<void> initialize() async {
    if (_isInitialized) {
      _logger.warning('ConnectivityService already initialized');
      return;
    }

    _logger.info('Initializing ConnectivityService');

    try {
      // Set up connectivity monitoring
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error, stackTrace) {
          _logger.severe(
            'Error in connectivity stream',
            error,
            stackTrace,
          );
        },
      );

      // Set up internet connection monitoring
      _internetSubscription = _internetChecker.onStatusChange.listen(
        _onInternetStatusChanged,
        onError: (error, stackTrace) {
          _logger.severe(
            'Error in internet status stream',
            error,
            stackTrace,
          );
        },
      );

      // Perform initial connectivity check
      await checkConnectivity();

      _isInitialized = true;
      _logger.info('ConnectivityService initialized successfully');
    } catch (error, stackTrace) {
      _logger.severe(
        'Failed to initialize ConnectivityService',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Handles connectivity changes from the connectivity_plus package.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _logger.info('Connectivity changed: $results');

    if (results.contains(ConnectivityResult.none)) {
      _updateStatus(ConnectivityStatus.offline);
      _startPeriodicChecks();
    } else {
      // Has network connection, but need to verify internet access
      checkConnectivity();
    }
  }

  /// Handles internet status changes from internet_connection_checker_plus.
  void _onInternetStatusChanged(InternetStatus status) {
    _logger.info('Internet status changed: $status');

    switch (status) {
      case InternetStatus.connected:
        checkConnectivity(); // Verify server reachability
        break;
      case InternetStatus.disconnected:
        _updateStatus(ConnectivityStatus.offline);
        _startPeriodicChecks();
        break;
    }
  }

  /// Checks current connectivity status.
  ///
  /// Performs a comprehensive connectivity check including:
  /// 1. Network connectivity (WiFi, mobile data, etc.)
  /// 2. Internet access verification
  /// 3. Server reachability check (if configured)
  ///
  /// Returns `true` if online, `false` if offline.
  Future<bool> checkConnectivity() async {
    if (_isCheckingConnectivity) {
      _logger.fine('Connectivity check already in progress');
      return currentStatus.isOnline;
    }

    _isCheckingConnectivity = true;

    try {
      _logger.fine('Checking connectivity');

      // Check network connectivity
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _logger.info('No network connectivity');
        _updateStatus(ConnectivityStatus.offline);
        _startPeriodicChecks();
        return false;
      }

      // Check internet access
      final bool hasInternet = await _internetChecker.hasInternetAccess;
      
      if (!hasInternet) {
        _logger.info('Network connected but no internet access');
        _updateStatus(ConnectivityStatus.offline);
        _startPeriodicChecks();
        return false;
      }

      // TODO: Add server reachability check when API client is available
      // For now, assume online if we have internet
      _logger.info('Connectivity check passed: online');
      _updateStatus(ConnectivityStatus.online);
      _stopPeriodicChecks();
      return true;
    } catch (error, stackTrace) {
      _logger.severe(
        'Error checking connectivity',
        error,
        stackTrace,
      );
      _updateStatus(ConnectivityStatus.unknown);
      return false;
    } finally {
      _isCheckingConnectivity = false;
    }
  }

  /// Checks if the Firefly III server is reachable.
  ///
  /// Attempts to ping the configured Firefly III server endpoint.
  /// Returns `true` if the server responds within the timeout period.
  ///
  /// [timeout] - Maximum time to wait for server response (default: 5 seconds).
  ///
  /// TODO: Implement actual server ping using API client
  Future<bool> checkServerReachability({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _logger.fine('Checking server reachability');

    try {
      // TODO: Implement server ping using API client
      // For now, return true if we have internet
      final bool hasInternet = await _internetChecker.hasInternetAccess;
      
      if (hasInternet) {
        _logger.info('Server reachability check passed');
        return true;
      } else {
        _logger.warning('Server reachability check failed: no internet');
        return false;
      }
    } catch (error, stackTrace) {
      _logger.severe(
        'Error checking server reachability',
        error,
        stackTrace,
      );
      return false;
    }
  }

  /// Updates the connectivity status and notifies listeners.
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_statusSubject.value != newStatus) {
      _logger.info('Connectivity status changed: ${newStatus.displayName}');
      _statusSubject.add(newStatus);
    }
  }

  /// Starts periodic connectivity checks when offline.
  ///
  /// Checks connectivity every 30 seconds to detect when connection is restored.
  void _startPeriodicChecks() {
    if (_periodicCheckTimer != null && _periodicCheckTimer!.isActive) {
      return; // Already running
    }

    _logger.info('Starting periodic connectivity checks');
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => checkConnectivity(),
    );
  }

  /// Stops periodic connectivity checks.
  void _stopPeriodicChecks() {
    if (_periodicCheckTimer != null) {
      _logger.info('Stopping periodic connectivity checks');
      _periodicCheckTimer!.cancel();
      _periodicCheckTimer = null;
    }
  }

  /// Pauses connectivity monitoring.
  ///
  /// Should be called when the app goes to the background to save battery.
  void pause() {
    _logger.info('Pausing connectivity monitoring');
    _stopPeriodicChecks();
    _connectivitySubscription?.pause();
    _internetSubscription?.pause();
  }

  /// Resumes connectivity monitoring.
  ///
  /// Should be called when the app returns to the foreground.
  Future<void> resume() async {
    _logger.info('Resuming connectivity monitoring');
    _connectivitySubscription?.resume();
    _internetSubscription?.resume();
    
    // Perform immediate connectivity check
    await checkConnectivity();
  }

  /// Disposes of the service and releases resources.
  ///
  /// Should be called when the service is no longer needed.
  Future<void> dispose() async {
    _logger.info('Disposing ConnectivityService');

    await _connectivitySubscription?.cancel();
    await _internetSubscription?.cancel();
    _stopPeriodicChecks();
    await _statusSubject.close();

    _isInitialized = false;
  }
}
