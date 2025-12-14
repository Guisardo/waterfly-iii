import 'package:connectivity_plus/connectivity_plus.dart';

/// Represents the current connectivity status of the application.
///
/// This enum is used to track whether the app has network connectivity
/// and can reach the Firefly III server.
enum ConnectivityStatus {
  /// The device has network connectivity and can reach the server.
  online,

  /// The device has no network connectivity or cannot reach the server.
  offline,

  /// The connectivity status is unknown or being determined.
  unknown,
}

/// Detailed connectivity information including network type.
///
/// Provides comprehensive connectivity details including:
/// - Connection status (online/offline/unknown)
/// - Network type (WiFi, mobile, ethernet, etc.)
/// - Multiple connection types (e.g., WiFi + VPN)
class ConnectivityInfo {
  /// Creates connectivity information.
  const ConnectivityInfo({
    required this.status,
    required this.networkTypes,
  });

  /// Current connectivity status.
  final ConnectivityStatus status;

  /// List of active network connection types.
  ///
  /// Can contain multiple types if device has multiple active connections
  /// (e.g., WiFi + VPN, Mobile + Bluetooth).
  final List<ConnectivityResult> networkTypes;

  /// Whether the device is online.
  bool get isOnline => status.isOnline;

  /// Whether the device is offline.
  bool get isOffline => status.isOffline;

  /// Whether the connectivity status is unknown.
  bool get isUnknown => status.isUnknown;

  /// Primary network type (first in list or none).
  ConnectivityResult get primaryNetworkType =>
      networkTypes.isNotEmpty ? networkTypes.first : ConnectivityResult.none;

  /// Human-readable network type description.
  String get networkTypeDescription {
    if (networkTypes.isEmpty || networkTypes.contains(ConnectivityResult.none)) {
      return 'No connection';
    }

    if (networkTypes.length == 1) {
      return _getNetworkTypeName(networkTypes.first);
    }

    // Multiple connections
    final types = networkTypes.map(_getNetworkTypeName).join(' + ');
    return types;
  }

  /// Get human-readable name for network type.
  String _getNetworkTypeName(ConnectivityResult type) {
    switch (type) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
        return 'None';
    }
  }

  /// Whether connected via WiFi.
  bool get isWiFi => networkTypes.contains(ConnectivityResult.wifi);

  /// Whether connected via mobile data.
  bool get isMobile => networkTypes.contains(ConnectivityResult.mobile);

  /// Whether connected via ethernet.
  bool get isEthernet => networkTypes.contains(ConnectivityResult.ethernet);

  /// Whether connected via VPN.
  bool get isVPN => networkTypes.contains(ConnectivityResult.vpn);

  @override
  String toString() =>
      'ConnectivityInfo(status: $status, networkTypes: $networkTypes)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectivityInfo &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          _listEquals(networkTypes, other.networkTypes);

  @override
  int get hashCode => status.hashCode ^ networkTypes.hashCode;

  /// Helper to compare lists.
  bool _listEquals(List<ConnectivityResult> a, List<ConnectivityResult> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Extension methods for [ConnectivityStatus].
extension ConnectivityStatusExtension on ConnectivityStatus {
  /// Returns true if the status is [ConnectivityStatus.online].
  bool get isOnline => this == ConnectivityStatus.online;

  /// Returns true if the status is [ConnectivityStatus.offline].
  bool get isOffline => this == ConnectivityStatus.offline;

  /// Returns true if the status is [ConnectivityStatus.unknown].
  bool get isUnknown => this == ConnectivityStatus.unknown;

  /// Returns a human-readable string representation of the status.
  String get displayName {
    switch (this) {
      case ConnectivityStatus.online:
        return 'Online';
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.unknown:
        return 'Unknown';
    }
  }
}
