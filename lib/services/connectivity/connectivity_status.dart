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
