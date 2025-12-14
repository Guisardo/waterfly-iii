import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:logging/logging.dart';

import '../../services/connectivity/connectivity_status.dart';
import '../../models/sync_progress.dart';

/// Service for managing accessibility features in offline mode.
///
/// Features:
/// - Screen reader support
/// - Announce connectivity changes
/// - Announce sync progress
/// - Announce conflicts
/// - Keyboard navigation support
/// - Visual accessibility (contrast, labels)
class OfflineAccessibilityService {
  static final Logger _logger = Logger('OfflineAccessibilityService');
  static final OfflineAccessibilityService _instance = OfflineAccessibilityService._internal();

  factory OfflineAccessibilityService() => _instance;

  OfflineAccessibilityService._internal();

  /// Announce connectivity status change
  static void announceConnectivityChange(
    BuildContext context,
    ConnectivityStatus oldStatus,
    ConnectivityStatus newStatus,
  ) {
    String announcement;

    switch (newStatus) {
      case ConnectivityStatus.online:
        announcement = 'You are now online. Data will sync automatically.';
        break;
      case ConnectivityStatus.offline:
        announcement = 'You are now offline. Changes will be saved locally and synced when you reconnect.';
        break;
      case ConnectivityStatus.unknown:
        announcement = 'Checking internet connection.';
        break;
    }

    _logger.fine('Announcing connectivity change: $announcement');
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce sync progress
  static void announceSyncProgress(
    BuildContext context,
    SyncProgress progress,
  ) {
    if (progress.completedOperations == progress.totalOperations) {
      final announcement = 'Sync complete. ${progress.completedOperations} operations synced successfully.';
      _logger.fine('Announcing sync completion: $announcement');
      SemanticsService.announce(announcement, TextDirection.ltr);
    } else if (progress.completedOperations % 10 == 0) {
      // Announce every 10 operations to avoid spam
      final announcement = 'Syncing. ${progress.completedOperations} of ${progress.totalOperations} operations complete.';
      _logger.fine('Announcing sync progress: $announcement');
      SemanticsService.announce(announcement, TextDirection.ltr);
    }
  }

  /// Announce conflict detected
  static void announceConflictDetected(
    BuildContext context,
    int conflictCount,
  ) {
    final announcement = '$conflictCount conflict${conflictCount == 1 ? '' : 's'} detected. '
        'Your attention is required to resolve ${conflictCount == 1 ? 'it' : 'them'}.';
    
    _logger.info('Announcing conflicts: $announcement');
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Announce sync error
  static void announceSyncError(
    BuildContext context,
    String errorMessage,
  ) {
    final announcement = 'Sync error: $errorMessage';
    _logger.warning('Announcing sync error: $announcement');
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Build semantic wrapper for sync status
  static Widget buildSemanticSyncStatus({
    required Widget child,
    required bool isSynced,
    required bool isSyncing,
    required bool hasSyncError,
  }) {
    String label;

    if (hasSyncError) {
      label = 'Sync failed. Tap to retry.';
    } else if (isSyncing) {
      label = 'Currently syncing with server.';
    } else if (isSynced) {
      label = 'Synced with server.';
    } else {
      label = 'Pending sync. Will sync when online.';
    }

    return Semantics(
      label: label,
      child: child,
    );
  }

  /// Build keyboard shortcut hints
  static Widget buildKeyboardShortcutHint({
    required BuildContext context,
    required String action,
    required String shortcut,
  }) {
    return Tooltip(
      message: '$action ($shortcut)',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          shortcut,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
        ),
      ),
    );
  }

  /// Check color contrast for accessibility
  static bool hasGoodContrast(Color foreground, Color background) {
    final fgLuminance = foreground.computeLuminance();
    final bgLuminance = background.computeLuminance();
    
    final lighter = fgLuminance > bgLuminance ? fgLuminance : bgLuminance;
    final darker = fgLuminance > bgLuminance ? bgLuminance : fgLuminance;
    
    final contrast = (lighter + 0.05) / (darker + 0.05);
    
    // WCAG AA requires 4.5:1 for normal text
    return contrast >= 4.5;
  }

  /// Build accessible icon with label
  static Widget buildAccessibleIcon({
    required BuildContext context,
    required IconData icon,
    required String label,
    Color? color,
    double? size,
  }) {
    return Semantics(
      label: label,
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }

  /// Build accessible button with semantic label
  static Widget buildAccessibleButton({
    required BuildContext context,
    required Widget child,
    required String semanticLabel,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: enabled,
      child: child,
    );
  }

  /// Announce list update
  static void announceListUpdate(
    BuildContext context,
    int itemCount,
    String entityType,
  ) {
    final announcement = '$itemCount $entityType${itemCount == 1 ? '' : 's'} in list.';
    SemanticsService.announce(announcement, TextDirection.ltr);
  }

  /// Build focus indicator for keyboard navigation
  static BoxDecoration buildFocusIndicator(BuildContext context, bool hasFocus) {
    if (!hasFocus) {
      return const BoxDecoration();
    }

    return BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.primary,
        width: 2,
      ),
      borderRadius: BorderRadius.circular(4),
    );
  }
}

/// Mixin for keyboard navigation support
mixin KeyboardNavigationMixin<T extends StatefulWidget> on State<T> {
  final Map<LogicalKeySet, VoidCallback> _shortcuts = {};

  /// Register keyboard shortcut
  void registerShortcut(LogicalKeySet keys, VoidCallback callback) {
    _shortcuts[keys] = callback;
  }

  /// Build shortcuts wrapper
  Widget buildWithShortcuts(Widget child) {
    return Shortcuts(
      shortcuts: _shortcuts.map(
        (key, value) => MapEntry(key, VoidCallbackIntent(value)),
      ),
      child: Actions(
        actions: {
          VoidCallbackIntent: CallbackAction<VoidCallbackIntent>(
            onInvoke: (intent) => intent.callback(),
          ),
        },
        child: Focus(
          autofocus: true,
          child: child,
        ),
      ),
    );
  }
}

/// Intent for void callbacks
class VoidCallbackIntent extends Intent {
  final VoidCallback callback;

  const VoidCallbackIntent(this.callback);
}
