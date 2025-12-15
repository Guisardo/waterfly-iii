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

  /// Optional API client for server reachability checks
  dynamic _apiClient;

  /// Set the API client for server reachability checks
  void setApiClient(dynamic apiClient) {
    _apiClient = apiClient;
    _logger.fine('API client configured for server reachability checks');
  }

  /// Subject for broadcasting connectivity status changes.
  final BehaviorSubject<ConnectivityStatus> _statusSubject =
      BehaviorSubject<ConnectivityStatus>.seeded(ConnectivityStatus.unknown);

  /// Current network types (WiFi, mobile, ethernet, etc.)
  List<ConnectivityResult> _currentNetworkTypes = [ConnectivityResult.none];

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

  /// Current network types.
  ///
  /// Returns list of active network connection types (WiFi, mobile, etc.).
  List<ConnectivityResult> get currentNetworkTypes => List.unmodifiable(_currentNetworkTypes);

  /// Detailed connectivity information including network type.
  ConnectivityInfo get connectivityInfo => ConnectivityInfo(
        status: currentStatus,
        networkTypes: currentNetworkTypes,
      );

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

    _logger.info('=== Initializing ConnectivityService ===');

    try {
      // Set up connectivity monitoring
      _logger.info('Setting up connectivity monitoring...');
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
      _logger.info('Setting up internet connection monitoring...');
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
      _logger.info('Performing initial connectivity check...');
      await checkConnectivity();

      _isInitialized = true;
      _logger.info('=== ConnectivityService initialized successfully ===');
    } catch (error, stackTrace) {
      _logger.severe(
        '=== Failed to initialize ConnectivityService ===',
        error,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Handles connectivity changes from the connectivity_plus package.
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _logger.info('=== Connectivity changed event ===');
    _logger.info('New connectivity results: $results');

    // Update current network types
    _currentNetworkTypes = results;

    if (results.contains(ConnectivityResult.none)) {
      _logger.info('No network detected, setting offline');
      _updateStatus(ConnectivityStatus.offline);
      _startPeriodicChecks();
    } else {
      _logger.info('Network detected, verifying internet access...');
      // Has network connection, but need to verify internet access
      checkConnectivity();
    }
  }

  /// Handles internet status changes from internet_connection_checker_plus.
  void _onInternetStatusChanged(InternetStatus status) {
    _logger.info('=== Internet status changed event ===');
    _logger.info('New internet status: $status');

    switch (status) {
      case InternetStatus.connected:
        _logger.info('Internet connected, verifying server reachability...');
        checkConnectivity(); // Verify server reachability
        break;
      case InternetStatus.disconnected:
        _logger.info('Internet disconnected, setting offline');
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
    _logger.info('=== Starting connectivity check ===');

    try {
      _logger.info('Step 1: Checking network connectivity...');

      // Check network connectivity
      final List<ConnectivityResult> connectivityResults = await _connectivity.checkConnectivity();
      
      _logger.info('Network connectivity results: $connectivityResults');
      
      // Update current network types
      _currentNetworkTypes = connectivityResults;
      
      if (connectivityResults.contains(ConnectivityResult.none)) {
        _logger.info('Result: No network connectivity detected');
        _updateStatus(ConnectivityStatus.offline);
        _startPeriodicChecks();
        return false;
      }

      _logger.info('Step 2: Checking internet access...');
      
      // Check internet access
      final bool hasInternet = await _internetChecker.hasInternetAccess;
      
      _logger.info('Internet access check result: $hasInternet');
      
      if (!hasInternet) {
        _logger.info('Result: Network connected but no internet access');
        _updateStatus(ConnectivityStatus.offline);
        _startPeriodicChecks();
        return false;
      }

      _logger.info('Step 3: Checking server reachability...');
      
      // Check server reachability if API client is available
      if (_apiClient != null) {
        _logger.info('API client is configured, checking server...');
        final bool serverReachable = await checkServerReachability();
        _logger.info('Server reachability result: $serverReachable');
        
        if (!serverReachable) {
          _logger.info('Result: Internet available but server unreachable');
          _updateStatus(ConnectivityStatus.offline);
          _startPeriodicChecks();
          return false;
        }
      } else {
        _logger.info('No API client configured, skipping server check');
      }

      _logger.info('=== Connectivity check PASSED: Device is ONLINE ===');
      _updateStatus(ConnectivityStatus.online);
      _stopPeriodicChecks();
      return true;
    } catch (error, stackTrace) {
      _logger.severe(
        '=== Connectivity check FAILED with error ===',
        error,
        stackTrace,
      );
      _updateStatus(ConnectivityStatus.unknown);
      return false;
    } finally {
      _isCheckingConnectivity = false;
      _logger.info('=== Connectivity check completed ===');
    }
  }

  /// Checks if the Firefly III server is reachable.
  ///
  /// Attempts to ping the configured Firefly III server endpoint.
  /// Returns `true` if the server responds within the timeout period.
  ///
  /// [timeout] - Maximum time to wait for server response (default: 5 seconds).
  Future<bool> checkServerReachability({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _logger.fine('Checking server reachability');

    try {
      if (_apiClient == null) {
        _logger.fine('No API client configured, skipping server check');
        return true;
      }

      // Ping server using API client's about endpoint
      final response = await _apiClient.v1AboutGet().timeout(timeout);
      
      if (response.isSuccessful) {
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
