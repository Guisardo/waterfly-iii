import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../models/sync_progress.dart';
import '../services/sync/sync_manager.dart';
import '../services/accessibility_service.dart';
import '../services/animation_service.dart';

/// Dialog showing sync progress with detailed information.
///
/// Features:
/// - Linear progress indicator
/// - Current operation display
/// - Completed/total count
/// - Estimated time remaining
/// - Cancel button with confirmation
/// - Error list if failures occur
/// - Retry failed button
/// - Material 3 design
class SyncProgressDialog extends StatefulWidget {
  /// Sync manager instance
  final SyncManager syncManager;

  /// Callback when sync is cancelled
  final VoidCallback? onCancel;

  const SyncProgressDialog({
    super.key,
    required this.syncManager,
    this.onCancel,
  });

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog> {
  static final Logger _logger = Logger('SyncProgressDialog');
  final AccessibilityService _accessibilityService = AccessibilityService();
  final AnimationService _animationService = AnimationService();
  int _lastAnnouncedProgress = 0;
  DateTime _lastAnnouncementTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncProgress>(
      stream: widget.syncManager.progressTracker.watchProgress(),
      builder: (context, snapshot) {
        final progress = snapshot.data;

        if (progress == null) {
          return const AlertDialog(
            content: CircularProgressIndicator(),
          );
        }

        // Announce progress at intervals
        final now = DateTime.now();
        final timeSinceLastAnnouncement = now.difference(_lastAnnouncementTime).inMilliseconds;
        final progressPercentage = ((progress.completedOperations / progress.totalOperations) * 100).round();
        
        if (progressPercentage != _lastAnnouncedProgress && 
            timeSinceLastAnnouncement >= _accessibilityService.settings.progressAnnouncementInterval) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _accessibilityService.announceSyncProgress(
              completed: progress.completedOperations,
              total: progress.totalOperations,
              currentOperation: progress.currentOperation,
            );
          });
          _lastAnnouncedProgress = progressPercentage;
          _lastAnnouncementTime = now;
        }

        // Announce completion
        if (progress.completedOperations == progress.totalOperations && _lastAnnouncedProgress != 100) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _accessibilityService.announceSyncCompletion(
              successCount: progress.completedOperations - progress.failedOperations.length,
              failureCount: progress.failedOperations.length,
            );
          });
          _lastAnnouncedProgress = 100;
        }

        return AlertDialog(
          title: Text(_getTitle(progress)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: progress.percentage / 100,
                ),
                const SizedBox(height: 16),

                // Progress text
                Text(
                  '${progress.completedOperations} of ${progress.totalOperations} operations',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),

                // Current operation
                if (progress.currentOperation != null)
                  Text(
                    'Current: ${progress.currentOperation}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),

                // Time remaining
                if (progress.estimatedTimeRemaining != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Time remaining: ${_formatDuration(progress.estimatedTimeRemaining!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                // Errors
                if (progress.errors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Errors (${progress.errors.length}):',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                  const SizedBox(height: 8),
                  ...progress.errors.take(3).map((error) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '• $error',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )),
                  if (progress.errors.length > 3)
                    Text(
                      '... and ${progress.errors.length - 3} more',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ],
            ),
          ),
          actions: [
            if (progress.failedOperations > 0)
              TextButton(
                onPressed: () => _retryFailed(),
                child: const Text('Retry Failed'),
              ),
            TextButton(
              onPressed: () => _confirmCancel(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  String _getTitle(SyncProgress progress) {
    if (progress.failedOperations > 0) {
      return 'Sync Errors';
    }
    if (progress.completedOperations == progress.totalOperations) {
      return 'Sync Complete';
    }
    return 'Syncing...';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    return '${duration.inSeconds}s';
  }

  Future<void> _confirmCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Sync?'),
        content: const Text(
          'Are you sure you want to cancel the sync? '
          'Pending operations will remain in the queue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      widget.onCancel?.call();
      Navigator.pop(context);
    }
  }

  Future<void> _retryFailed() async {
    _logger.info('Retrying failed operations');
    // Trigger retry through sync manager
    await widget.syncManager.synchronize();
  }
}
