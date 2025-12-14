import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;
import 'package:logging/logging.dart';

import '../providers/connectivity_provider.dart';
import '../services/connectivity/connectivity_status.dart';
import '../services/sync/sync_queue_manager.dart';

/// App bar sync status indicator widget.
///
/// Displays a small icon in the app bar showing:
/// - Current connectivity status
/// - Sync state with pulse animation
/// - Badge with pending operations count
/// - Tappable to open sync status screen
///
/// Features:
/// - Material 3 design
/// - Subtle pulse animation when syncing
/// - Badge showing queue count
/// - Accessibility support
class AppBarSyncIndicator extends StatefulWidget {
  /// Callback when indicator is tapped
  final VoidCallback? onTap;

  const AppBarSyncIndicator({
    super.key,
    this.onTap,
  });

  @override
  State<AppBarSyncIndicator> createState() => _AppBarSyncIndicatorState();
}

class _AppBarSyncIndicatorState extends State<AppBarSyncIndicator>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger('AppBarSyncIndicator');

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _logger.fine('Initializing app bar sync indicator');

    // Setup subtle pulse animation for syncing
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Get icon based on connectivity and sync state
  IconData _getIcon(ConnectivityStatus status, bool isSyncing) {
    if (isSyncing) {
      return Icons.sync;
    }

    switch (status) {
      case ConnectivityStatus.online:
        return Icons.cloud_done_outlined;
      case ConnectivityStatus.offline:
        return Icons.cloud_off_outlined;
      case ConnectivityStatus.unknown:
        return Icons.cloud_outlined;
    }
  }

  /// Get icon color based on status
  Color _getIconColor(BuildContext context, ConnectivityStatus status, bool isSyncing) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSyncing) {
      return colorScheme.primary;
    }

    switch (status) {
      case ConnectivityStatus.online:
        return colorScheme.onSurface;
      case ConnectivityStatus.offline:
        return colorScheme.error;
      case ConnectivityStatus.unknown:
        return colorScheme.onSurfaceVariant;
    }
  }

  /// Get semantic label for accessibility
  String _getSemanticLabel(ConnectivityStatus status, bool isSyncing, int queueCount) {
    if (isSyncing) {
      return 'Syncing. Tap to view sync status.';
    }

    switch (status) {
      case ConnectivityStatus.online:
        if (queueCount > 0) {
          return '$queueCount pending operations. Tap to view sync status.';
        }
        return 'Online and synced. Tap to view sync status.';
      case ConnectivityStatus.offline:
        if (queueCount > 0) {
          return 'Offline with $queueCount queued operations. Tap to view sync status.';
        }
        return 'Offline. Tap to view sync status.';
      case ConnectivityStatus.unknown:
        return 'Checking connection. Tap to view sync status.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final status = connectivityProvider.status;
        final isSyncing = connectivityProvider.isSyncing;

        return FutureBuilder<int>(
          future: _getQueueCount(),
          builder: (context, snapshot) {
            final queueCount = snapshot.data ?? 0;
            final icon = _getIcon(status, isSyncing);
            final iconColor = _getIconColor(context, status, isSyncing);
            final semanticLabel = _getSemanticLabel(status, isSyncing, queueCount);

            Widget indicator = IconButton(
              icon: isSyncing
                  ? AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _pulseAnimation.value,
                          child: Icon(
                            icon,
                            color: iconColor,
                          ),
                        );
                      },
                    )
                  : Icon(
                      icon,
                      color: iconColor,
                    ),
              onPressed: widget.onTap,
              tooltip: semanticLabel,
            );

            // Add badge if there are pending operations
            if (queueCount > 0 && !isSyncing) {
              indicator = badges.Badge(
                badgeContent: Text(
                  queueCount > 99 ? '99+' : queueCount.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                        fontSize: 10,
                      ),
                ),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: Theme.of(context).colorScheme.error,
                  padding: const EdgeInsets.all(4),
                ),
                position: badges.BadgePosition.topEnd(top: 8, end: 8),
                child: indicator,
              );
            }

            return Semantics(
              label: semanticLabel,
              button: true,
              child: indicator,
            );
          },
        );
      },
    );
  }

  /// Get current sync queue count
  Future<int> _getQueueCount() async {
    try {
      final queueManager = SyncQueueManager();
      final operations = await queueManager.getPendingOperations();
      return operations.length;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get queue count for app bar indicator',
        e,
        stackTrace,
      );
      return 0;
    }
  }
}
