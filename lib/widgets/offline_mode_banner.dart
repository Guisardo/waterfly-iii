import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';

import '../providers/connectivity_provider.dart';
import '../services/connectivity/connectivity_status.dart';

/// Prominent banner displayed when the app is offline.
///
/// Features:
/// - Shows informative message about offline mode
/// - "Learn More" button for help
/// - Dismissible by user
/// - Remembers dismissal preference
/// - Shows again after app restart if still offline
/// - Material 3 design
/// - Accessibility support
class OfflineModeBanner extends StatefulWidget {
  /// Callback when "Learn More" is tapped
  final VoidCallback? onLearnMore;

  const OfflineModeBanner({
    super.key,
    this.onLearnMore,
  });

  @override
  State<OfflineModeBanner> createState() => _OfflineModeBannerState();
}

class _OfflineModeBannerState extends State<OfflineModeBanner> {
  static final Logger _logger = Logger('OfflineModeBanner');
  static const String _dismissalKey = 'offline_banner_dismissed';

  bool _isDismissed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDismissalState();
  }

  /// Load dismissal state from shared preferences
  Future<void> _loadDismissalState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = prefs.getBool(_dismissalKey) ?? false;

      if (mounted) {
        setState(() {
          _isDismissed = dismissed;
          _isLoading = false;
        });
      }

      _logger.fine('Loaded banner dismissal state: dismissed=$dismissed');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to load banner dismissal state',
        e,
        stackTrace,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Save dismissal state to shared preferences
  Future<void> _saveDismissalState(bool dismissed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissalKey, dismissed);
      _logger.info('Saved banner dismissal state: dismissed=$dismissed');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to save banner dismissal state',
        e,
        stackTrace,
      );
    }
  }

  /// Handle banner dismissal
  void _handleDismiss() {
    setState(() {
      _isDismissed = true;
    });
    _saveDismissalState(true);
    _logger.info('Offline banner dismissed by user');
  }

  /// Reset dismissal state (called when going back online)
  Future<void> _resetDismissalState() async {
    await _saveDismissalState(false);
    if (mounted) {
      setState(() {
        _isDismissed = false;
      });
    }
    _logger.fine('Reset banner dismissal state');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        final status = connectivityProvider.status;

        // Reset dismissal when going back online
        if (status == ConnectivityStatus.online && _isDismissed) {
          _resetDismissalState();
        }

        // Only show when offline and not dismissed
        if (status != ConnectivityStatus.offline || _isDismissed) {
          return const SizedBox.shrink();
        }

        return Semantics(
          label: 'You are offline. Changes will sync when you are back online. '
              'Swipe to dismiss or tap Learn More for details.',
          child: Material(
            color: Theme.of(context).colorScheme.errorContainer,
            elevation: 4,
            child: Dismissible(
              key: const Key('offline_mode_banner'),
              direction: DismissDirection.horizontal,
              onDismissed: (direction) => _handleDismiss(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Warning icon
                    Icon(
                      Icons.cloud_off,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      size: 24,
                    ),
                    const SizedBox(width: 16),

                    // Message
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'You\'re offline',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Changes will sync when online.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Learn More button
                    if (widget.onLearnMore != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: widget.onLearnMore,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        child: const Text('Learn More'),
                      ),
                    ],

                    // Close button
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color:
                            Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      onPressed: _handleDismiss,
                      tooltip: 'Dismiss',
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
