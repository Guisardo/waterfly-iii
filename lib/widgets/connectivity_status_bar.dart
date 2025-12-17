import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/providers/connectivity_provider.dart';
import 'package:waterflyiii/services/connectivity/connectivity_status.dart';

final Logger _log = Logger('ConnectivityStatusBar');

/// Comprehensive connectivity status bar with real-time updates.
///
/// Features:
/// - Real-time connectivity status updates
/// - Slide animation (slide down when offline, slide up when online)
/// - Color-coded status (green=online, red=offline, yellow=limited)
/// - Network type display (WiFi, Mobile, Ethernet)
/// - Tap to show network details
/// - Auto-hide after 5 seconds when online
/// - Always show when offline
/// - Material Design 3 styling
///
/// Example:
/// ```dart
/// Scaffold(
///   body: Column(
///     children: [
///       ConnectivityStatusBar(),
///       Expanded(child: YourContent()),
///     ],
///   ),
/// )
/// ```
class ConnectivityStatusBar extends StatefulWidget {
  const ConnectivityStatusBar({
    super.key,
    this.autoHideWhenOnline = true,
    this.autoHideDelay = const Duration(seconds: 5),
    this.showNetworkType = true,
    this.onTap,
  });

  /// Whether to auto-hide when online
  final bool autoHideWhenOnline;

  /// Delay before auto-hiding when online
  final Duration autoHideDelay;

  /// Whether to show network type
  final bool showNetworkType;

  /// Callback when tapped
  final VoidCallback? onTap;

  @override
  State<ConnectivityStatusBar> createState() => _ConnectivityStatusBarState();
}

class _ConnectivityStatusBarState extends State<ConnectivityStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  Timer? _autoHideTimer;
  bool _isVisible = false;
  ConnectivityStatus? _previousStatus;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    _autoHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (
        BuildContext context,
        ConnectivityProvider connectivity,
        Widget? child,
      ) {
        final ConnectivityStatus status = connectivity.status;

        // Handle status changes after build completes
        if (_previousStatus != status) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleStatusChange(status);
          });
          _previousStatus = status;
        }

        if (!_isVisible) {
          return const SizedBox.shrink();
        }

        return SlideTransition(
          position: _slideAnimation,
          child: Material(
            color: _getStatusColor(status),
            elevation: 4,
            child: InkWell(
              onTap:
                  widget.onTap ??
                  () => _showNetworkDetails(context, connectivity),
              child: SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _getStatusIcon(status),
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              _getStatusText(status),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.showNetworkType && status.isOnline)
                              Text(
                                _getNetworkTypeText(status),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.info_outline,
                        color: Colors.white.withOpacity(0.7),
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Handle connectivity status change.
  void _handleStatusChange(ConnectivityStatus status) {
    _log.info('Connectivity status changed to: $status');

    _autoHideTimer?.cancel();

    if (status.isOffline || status.isUnknown) {
      // Show immediately when offline
      _show();
    } else if (status.isOnline) {
      // Show briefly when online, then auto-hide
      _show();
      if (widget.autoHideWhenOnline) {
        _autoHideTimer = Timer(widget.autoHideDelay, _hide);
      }
    }
  }

  /// Show the status bar.
  void _show() {
    if (!_isVisible) {
      setState(() => _isVisible = true);
      _slideController.forward();
    }
  }

  /// Hide the status bar.
  void _hide() {
    if (_isVisible) {
      _slideController.reverse().then((_) {
        if (mounted) {
          setState(() => _isVisible = false);
        }
      });
    }
  }

  /// Get color for status.
  Color _getStatusColor(ConnectivityStatus status) {
    if (status.isOnline) {
      return Colors.green[700]!;
    } else if (status.isOffline) {
      return Colors.red[700]!;
    } else {
      return Colors.orange[700]!;
    }
  }

  /// Get icon for status.
  IconData _getStatusIcon(ConnectivityStatus status) {
    if (status.isOnline) {
      return Icons.wifi;
    } else if (status.isOffline) {
      return Icons.wifi_off;
    } else {
      return Icons.signal_wifi_statusbar_null;
    }
  }

  /// Get text for status.
  String _getStatusText(ConnectivityStatus status) {
    if (status.isOnline) {
      return 'Back online';
    } else if (status.isOffline) {
      return 'No internet connection';
    } else {
      return 'Checking connection...';
    }
  }

  /// Get network type text.
  String _getNetworkTypeText(ConnectivityStatus status) {
    // Get actual network type from connectivity service via provider
    final ConnectivityProvider connectivity = Provider.of<ConnectivityProvider>(
      context,
      listen: false,
    );

    if (connectivity.isOffline) {
      return 'No connection';
    }

    return connectivity.networkTypeDescription;
  }

  /// Show network details dialog.
  void _showNetworkDetails(
    BuildContext context,
    ConnectivityProvider connectivity,
  ) {
    showDialog(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Row(
              children: <Widget>[
                Icon(
                  _getStatusIcon(connectivity.status),
                  color: _getStatusColor(connectivity.status),
                ),
                const SizedBox(width: 12),
                const Text('Network Status'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildDetailRow(
                  'Status',
                  connectivity.statusText,
                  connectivity.isOnline ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 12),
                _buildDetailRow(
                  'Connection',
                  connectivity.isOnline ? 'Available' : 'Unavailable',
                  null,
                ),
                const SizedBox(height: 12),
                Text(
                  connectivity.isOffline
                      ? 'Some features may be limited while offline. '
                          'Data will sync automatically when connection is restored.'
                      : 'All features are available.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            actions: <Widget>[
              if (connectivity.isOffline)
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    _log.info('Manual connectivity check requested');

                    try {
                      // Trigger connectivity check via provider
                      final ConnectivityProvider connectivityProvider =
                          Provider.of<ConnectivityProvider>(
                            context,
                            listen: false,
                          );

                      final bool isOnline =
                          await connectivityProvider.checkConnectivity();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isOnline
                                  ? 'Connection restored!'
                                  : 'Still offline. Please check your network settings.',
                            ),
                            backgroundColor:
                                isOnline ? Colors.green : Colors.orange,
                          ),
                        );
                      }
                    } catch (e, stackTrace) {
                      _log.severe(
                        'Failed to check connectivity',
                        e,
                        stackTrace,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to check connectivity'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  /// Build detail row for dialog.
  Widget _buildDetailRow(String label, String value, Color? valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: valueColor != null ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
