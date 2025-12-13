/// Represents the current operational mode of the application.
///
/// The app mode determines how data operations are handled:
/// - [online]: All operations go directly to the server
/// - [offline]: All operations are stored locally and queued for sync
/// - [syncing]: The app is currently synchronizing offline changes
enum AppMode {
  /// Online mode - connected to server, operations go directly to API.
  online,

  /// Offline mode - no server connection, operations stored locally.
  offline,

  /// Syncing mode - currently synchronizing offline changes with server.
  syncing,
}

/// Extension methods for [AppMode].
extension AppModeExtension on AppMode {
  /// Returns true if the mode is [AppMode.online].
  bool get isOnline => this == AppMode.online;

  /// Returns true if the mode is [AppMode.offline].
  bool get isOffline => this == AppMode.offline;

  /// Returns true if the mode is [AppMode.syncing].
  bool get isSyncing => this == AppMode.syncing;

  /// Returns true if operations should be queued (offline or syncing).
  bool get shouldQueueOperations => isOffline || isSyncing;

  /// Returns true if the app can perform network operations.
  bool get canUseNetwork => isOnline || isSyncing;

  /// Returns a human-readable string representation of the mode.
  String get displayName {
    switch (this) {
      case AppMode.online:
        return 'Online';
      case AppMode.offline:
        return 'Offline';
      case AppMode.syncing:
        return 'Syncing';
    }
  }

  /// Returns a detailed description of the mode.
  String get description {
    switch (this) {
      case AppMode.online:
        return 'Connected to server. Changes are saved immediately.';
      case AppMode.offline:
        return 'No connection. Changes will sync when online.';
      case AppMode.syncing:
        return 'Synchronizing offline changes with server.';
    }
  }
}
