import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../services/accessibility_service.dart';

/// Sync status indicator for list items.
///
/// Shows the sync status of an entity with appropriate icon and color:
/// - Checkmark: Synced
/// - Clock: Pending sync
/// - Warning: Sync failed
/// - Refresh: Currently syncing
///
/// Features:
/// - Material 3 design
/// - Tooltip on long press
/// - Subtle background color for unsynced items
/// - Accessibility support
class SyncStatusIndicator extends StatelessWidget {
  static final Logger _logger = Logger('SyncStatusIndicator');
  static final AccessibilityService _accessibilityService = AccessibilityService();

  /// Whether the item is synced with the server
  final bool isSynced;

  /// Whether the item is currently syncing
  final bool isSyncing;

  /// Whether the sync failed
  final bool hasSyncError;

  /// Optional error message
  final String? errorMessage;

  /// Size of the indicator icon
  final double size;

  /// Whether to show background color for unsynced items
  final bool showBackground;

  const SyncStatusIndicator({
    super.key,
    required this.isSynced,
    this.isSyncing = false,
    this.hasSyncError = false,
    this.errorMessage,
    this.size = 16,
    this.showBackground = false,
  });

  /// Get icon based on sync status
  IconData _getIcon() {
    if (hasSyncError) {
      return Icons.warning_amber_rounded;
    }
    if (isSyncing) {
      return Icons.refresh;
    }
    if (isSynced) {
      return Icons.check_circle;
    }
    return Icons.schedule;
  }

  /// Get icon color based on sync status
  Color _getIconColor(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (hasSyncError) {
      return colorScheme.error;
    }
    if (isSyncing) {
      return colorScheme.primary;
    }
    if (isSynced) {
      return colorScheme.tertiary;
    }
    return colorScheme.outline;
  }

  /// Get tooltip text
  String _getTooltip() {
    if (hasSyncError) {
      return errorMessage ?? 'Sync failed';
    }
    if (isSyncing) {
      return 'Syncing...';
    }
    if (isSynced) {
      return 'Synced';
    }
    return 'Pending sync';
  }

  /// Get background color for unsynced items
  Color? _getBackgroundColor(BuildContext context) {
    if (!showBackground || isSynced) {
      return null;
    }

    final colorScheme = Theme.of(context).colorScheme;

    if (hasSyncError) {
      return colorScheme.errorContainer.withOpacity(0.1);
    }
    if (isSyncing) {
      return colorScheme.primaryContainer.withOpacity(0.1);
    }
    return colorScheme.surfaceContainerHighest.withOpacity(0.3);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _getIcon();
    final iconColor = _getIconColor(context);
    final tooltip = _getTooltip();
    final semanticLabel = _accessibilityService.getSyncStatusLabel(
      isSynced: isSynced,
      isPending: !isSynced && !isSyncing && !hasSyncError,
      isSyncing: isSyncing,
      hasFailed: hasSyncError,
    );
    final backgroundColor = _getBackgroundColor(context);

    Widget indicator = Icon(
      icon,
      size: size,
      color: iconColor,
    );

    // Add rotation animation for syncing state
    if (isSyncing) {
      indicator = RotationTransition(
        turns: const AlwaysStoppedAnimation(0.5),
        child: indicator,
      );
    }

    // Add tooltip
    indicator = Tooltip(
      message: tooltip,
      child: indicator,
    );

    // Add semantic label
    indicator = Semantics(
      label: semanticLabel,
      child: indicator,
    );

    // Add background if needed
    if (backgroundColor != null) {
      indicator = Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: indicator,
      );
    }

    return indicator;
  }
}

/// Extension to add sync status indicator to list tiles
extension SyncStatusListTile on Widget {
  /// Wrap a list tile with sync status background
  Widget withSyncStatus({
    required bool isSynced,
    bool isSyncing = false,
    bool hasSyncError = false,
  }) {
    return Builder(
      builder: (context) {
        Color? backgroundColor;

        if (!isSynced) {
          final colorScheme = Theme.of(context).colorScheme;

          if (hasSyncError) {
            backgroundColor = colorScheme.errorContainer.withOpacity(0.05);
          } else if (isSyncing) {
            backgroundColor = colorScheme.primaryContainer.withOpacity(0.05);
          } else {
            backgroundColor =
                colorScheme.surfaceContainerHighest.withOpacity(0.1);
          }
        }

        if (backgroundColor == null) {
          return this;
        }

        return Container(
          color: backgroundColor,
          child: this,
        );
      },
    );
  }
}
