import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final Logger log = Logger("Connectivity");

enum NetworkType {
  none,
  wifi,
  mobile,
  other,
}

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  NetworkType _currentNetworkType = NetworkType.none;
  bool _isOnline = false;

  NetworkType get currentNetworkType => _currentNetworkType;
  bool get isOnline => _isOnline;
  bool get isWifi => _currentNetworkType == NetworkType.wifi;
  bool get isMobile => _currentNetworkType == NetworkType.mobile;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    await _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );
  }

  Future<void> _checkConnectivity() async {
    final List<ConnectivityResult> results =
        await _connectivity.checkConnectivity();
    _updateNetworkStatus(results);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateNetworkStatus(results);
  }

  void _updateNetworkStatus(List<ConnectivityResult> results) {
    final NetworkType previousType = _currentNetworkType;
    final bool previousOnline = _isOnline;

    if (results.contains(ConnectivityResult.wifi)) {
      _currentNetworkType = NetworkType.wifi;
      _isOnline = true;
    } else if (results.contains(ConnectivityResult.mobile)) {
      _currentNetworkType = NetworkType.mobile;
      _isOnline = true;
    } else if (results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.other)) {
      _currentNetworkType = NetworkType.other;
      _isOnline = true;
    } else {
      _currentNetworkType = NetworkType.none;
      _isOnline = false;
    }

    if (previousType != _currentNetworkType || previousOnline != _isOnline) {
      log.config(
        "Network status changed: ${_currentNetworkType.name}, online: $_isOnline",
      );
      notifyListeners();
    }
  }

  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

