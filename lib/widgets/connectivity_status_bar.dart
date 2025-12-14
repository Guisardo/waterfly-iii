import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../providers/connectivity_provider.dart';
import '../services/connectivity/connectivity_status.dart';
import '../services/sync/sync_manager.dart';
import '../services/sync/sync_queue_manager.dart';
import '../services/accessibility_service.dart';
import '../services/accessibility/visual_accessibility_service.dart';
import '../services/animation_service.dart';

/// Connectivity status bar widget that displays current online/offline status
/// and sync queue information.
///
/// Features:
/// - Color-coded status indicators (green/yellow/red/blue)
/// - Animated syncing state
/// - Dismissible with swipe gesture
/// - Tappable to show sync details
/// - Badge showing pending operations count
/// - Material 3 design compliance
/// - Accessibility support
class ConnectivityStatusBar extends StatefulWidget {
  /// Whether the status bar can be dismissed
  final bool dismissible;

  /// Callback when status bar is tapped
  final VoidCallback? onTap;

  /// Whether to show the sync queue count
  final bool showQueueCount;

  const ConnectivityStatusBar({
    super.key,
    this.dismissible = true,
    this.onTap,
    this.showQueueCount = true,
  });

  @override
  State<ConnectivityStatusBar> createState() => _ConnectivityStatusBarState();
}

class _ConnectivityStatusBarState extends State<ConnectivityStatusBar>
    with SingleTickerProviderStateMixin {
  static final Logger _logger = Logger('ConnectivityStatusBar');
  final AccessibilityService _accessibilityService = AccessibilityService();
  final VisualAccessibilityService _visualAccessibility = VisualAccessibilityService();
  final AnimationService _animationService = AnimationService();

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isDismissed = false;
  ConnectivityStatus? _previousStatus;
  int _previousQueueCount = 0;

  @override
  void initState() {
    super.initState();
    _logger.fine('Initializing connectivity status bar');

    // Setup pulse animation for syncing state
    _animationController = AnimationController(
      duration: AnimationService.long2,
      vsync: this,
    );

    _pulseAnimation = _animationService.createPulseAnimation(_animationController);
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get status bar color based on connectivity and sync state
  Color _getStatusColor(
    BuildContext context,
    ConnectivityStatus status,
    bool isSyncing,
    int queueCount,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isSyncing) {
      return colorScheme.primary; // Blue: Syncing
    }

    switch (status) {
      case ConnectivityStatus.online:
        return queueCount > 0
            ? colorScheme.tertiary // Yellow: Online with pending
            : colorScheme.primaryContainer; // Green: Online and synced
      case ConnectivityStatus.offline:
        return colorScheme.errorContainer; // Red: Offline
      case ConnectivityStatus.unknown:
        return colorScheme.surfaceContainerHighest; // Gray: Unknown
    }
  }

  /// Get status icon based on connectivity and sync state
  IconData _getStatusIcon(
    ConnectivityStatus status,
    bool isSyncing,
    int queueCount,
  ) {
    if (isSyncing) {
      return Icons.sync;
    }

    switch (status) {
      case ConnectivityStatus.online:
        return queueCount > 0 ? Icons.cloud_queue : Icons.cloud_done;
      case ConnectivityStatus.offline:
        return Icons.cloud_off;
      case ConnectivityStatus.unknown:
        return Icons.cloud_outlined;
    }
  }

  /// Get status message text
  String _getStatusMessage(
    ConnectivityStatus status,
    bool isSyncing,
    int queueCount,
  ) {
    if (isSyncing) {
      return 'Syncing...';
    }

    switch (status) {
      case ConnectivityStatus.online:
        if (queueCount > 0) {
          return '$queueCount operation${queueCount == 1 ? '' : 's'} pending';
        }
        return 'Online and synced';
      case ConnectivityStatus.offline:
        if (queueCount > 0) {
          return 'Offline - $queueCount operation${queueCount == 1 ? '' : 's'} queued';
        }
        return 'Offline';
      case ConnectivityStatus.unknown:
        return 'Checking connection...';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDismissed) {
      return const SizedBox.shrink();
    }

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final status = connectivityProvider.status;
        final isSyncing = connectivityProvider.isSyncing;

        // Announce connectivity changes
        if (_previousStatus != null && _previousStatus != status) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _accessibilityService.announceConnectivityChange(
              isOnline: status == ConnectivityStatus.online,
              queueCount: _previousQueueCount,
            );
          });
        }
        _previousStatus = status;

        return FutureBuilder<int>(
          future: _getQueueCount(),
          builder: (context, snapshot) {
            final queueCount = snapshot.data ?? 0;
            
            // Track queue count changes
            if (_previousQueueCount != queueCount) {
              _previousQueueCount = queueCount;
            }
            
            final statusColor = _getStatusColor(
              context,
              status,
              isSyncing,
              queueCount,
            );
            final statusIcon = _getStatusIcon(status, isSyncing, queueCount);
            final statusMessage = _getStatusMessage(
              status,
              isSyncing,
              queueCount,
            );
            final semanticLabel = _accessibilityService.getConnectivityLabel(
              isOnline: status == ConnectivityStatus.online,
              queueCount: queueCount,
            );

            Widget statusBar = Material(
              color: statusColor,
              elevation: 2,
              child: InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      // Animated icon for syncing state
                      if (isSyncing)
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Icon(
                                statusIcon,
                                size: 20,
                                color: _visualAccessibility.getAccessibleTextColor(statusColor),
                              ),
                            );
                          },
                        )
                      else
                        Icon(
                          statusIcon,
                          size: 20,
                          color: _visualAccessibility.getAccessibleTextColor(statusColor),
                        ),
                      const SizedBox(width: 12),

                      // Status message
                      Expanded(
                        child: Text(
                          statusMessage,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _visualAccessibility.getAccessibleTextColor(statusColor),
                              ),
                        ),
                      ),

                      // Queue count badge
                      if (widget.showQueueCount && queueCount > 0 && !isSyncing)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            queueCount.toString(),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),

                      // Tap indicator
                      if (widget.onTap != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: _visualAccessibility.getAccessibleTextColor(statusColor),
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );

            // Add semantic label for accessibility
            statusBar = Semantics(
              label: semanticLabel,
              button: widget.onTap != null,
              child: statusBar,
            );

            // Make dismissible if enabled
            if (widget.dismissible) {
              statusBar = Dismissible(
                key: const Key('connectivity_status_bar'),
                direction: DismissDirection.horizontal,
                onDismissed: (direction) {
                  setState(() {
                    _isDismissed = true;
                  });
                  _logger.info('Status bar dismissed by user');
                },
                child: statusBar,
              );
            }

            // Animate appearance
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: statusBar,
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
        'Failed to get queue count',
        e,
        stackTrace,
      );
      return 0;
    }
  }
}
