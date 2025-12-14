import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/models/sync_progress.dart';
import 'package:waterflyiii/providers/sync_status_provider.dart';

final Logger _log = Logger('SyncProgressWidget');

/// Display mode for sync progress widget.
enum SyncProgressDisplayMode {
  /// Show as bottom sheet
  sheet,

  /// Show as dialog
  dialog,
}

/// Comprehensive sync progress widget supporting both sheet and dialog modes.
///
/// Features:
/// - Real-time progress updates from SyncStatusProvider
/// - Linear progress bar with percentage
/// - Current operation display
/// - Entity-specific progress breakdown
/// - Statistics (synced, pending, conflicts, errors)
/// - Estimated time remaining
/// - Cancel button (optional)
/// - Success/error states
/// - Smooth animations
///
/// Can be displayed as either a bottom sheet or dialog based on displayMode.
///
/// Example:
/// ```dart
/// // Show as bottom sheet
/// showModalBottomSheet(
///   context: context,
///   builder: (context) => SyncProgressWidget(
///     displayMode: SyncProgressDisplayMode.sheet,
///   ),
/// );
///
/// // Show as dialog
/// showDialog(
///   context: context,
///   builder: (context) => SyncProgressWidget(
///     displayMode: SyncProgressDisplayMode.dialog,
///   ),
/// );
/// ```
class SyncProgressWidget extends StatefulWidget {
  const SyncProgressWidget({
    super.key,
    this.displayMode = SyncProgressDisplayMode.sheet,
    this.allowCancel = true,
    this.onCancel,
    this.autoDismissOnComplete = true,
  });

  /// Display mode (sheet or dialog)
  final SyncProgressDisplayMode displayMode;

  /// Whether to show cancel button
  final bool allowCancel;

  /// Callback when cancel is pressed
  final VoidCallback? onCancel;

  /// Whether to auto-dismiss when sync completes
  final bool autoDismissOnComplete;

  @override
  State<SyncProgressWidget> createState() => _SyncProgressWidgetState();
}

class _SyncProgressWidgetState extends State<SyncProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncStatusProvider>(
      builder: (context, provider, child) {
        final progress = provider.currentProgress;
        final isSyncing = provider.isSyncing;
        final error = provider.currentError;

        // Auto-dismiss on completion
        if (widget.autoDismissOnComplete &&
            progress != null &&
            progress.isComplete &&
            _autoDismissTimer == null) {
          _autoDismissTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pop();
            }
          });
        }

        return FadeTransition(
          opacity: _fadeAnimation,
          child: widget.displayMode == SyncProgressDisplayMode.sheet
              ? _buildSheet(context, progress, isSyncing, error)
              : _buildDialog(context, progress, isSyncing, error),
        );
      },
    );
  }

  /// Build bottom sheet layout.
  Widget _buildSheet(
    BuildContext context,
    SyncProgress? progress,
    bool isSyncing,
    String? error,
  ) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, progress, isSyncing, error),
          const SizedBox(height: 24),
          _buildContent(context, progress, isSyncing, error),
          if (widget.allowCancel && isSyncing) ...[
            const SizedBox(height: 24),
            _buildCancelButton(context),
          ],
        ],
      ),
    );
  }

  /// Build dialog layout.
  Widget _buildDialog(
    BuildContext context,
    SyncProgress? progress,
    bool isSyncing,
    String? error,
  ) {
    return AlertDialog(
      title: _buildHeader(context, progress, isSyncing, error),
      content: _buildContent(context, progress, isSyncing, error),
      actions: widget.allowCancel && isSyncing
          ? [
              TextButton(
                onPressed: () => _handleCancel(context),
                child: const Text('Cancel'),
              ),
            ]
          : null,
    );
  }

  /// Build header with status icon and title.
  Widget _buildHeader(
    BuildContext context,
    SyncProgress? progress,
    bool isSyncing,
    String? error,
  ) {
    final IconData icon;
    final Color iconColor;
    final String title;

    if (error != null) {
      icon = Icons.error;
      iconColor = Colors.red;
      title = 'Sync Failed';
    } else if (progress != null && progress.isComplete) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
      title = 'Sync Complete';
    } else if (isSyncing) {
      icon = Icons.sync;
      iconColor = Theme.of(context).colorScheme.primary;
      title = 'Syncing...';
    } else {
      icon = Icons.cloud_sync;
      iconColor = Colors.grey;
      title = 'Preparing...';
    }

    return Row(
      children: [
        if (isSyncing && error == null && (progress == null || !progress.isComplete))
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(iconColor),
            ),
          )
        else
          Icon(icon, color: iconColor, size: 32),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ],
    );
  }

  /// Build main content with progress details.
  Widget _buildContent(
    BuildContext context,
    SyncProgress? progress,
    bool isSyncing,
    String? error,
  ) {
    if (error != null) {
      return _buildErrorContent(context, error);
    }

    if (progress == null) {
      return _buildPreparingContent(context);
    }

    if (progress.isComplete) {
      return _buildCompleteContent(context, progress);
    }

    return _buildProgressContent(context, progress);
  }

  /// Build error content.
  Widget _buildErrorContent(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 48),
          const SizedBox(height: 12),
          Text(
            error,
            style: TextStyle(color: Colors.red[700]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build preparing content.
  Widget _buildPreparingContent(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircularProgressIndicator(),
        SizedBox(height: 16),
        Text('Preparing sync...'),
      ],
    );
  }

  /// Build complete content.
  Widget _buildCompleteContent(BuildContext context, SyncProgress progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.check_circle_outline,
          color: Colors.green[600],
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'Successfully synced ${progress.completedOperations} operations',
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        if (progress.conflictsDetected > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${progress.conflictsDetected} conflicts detected',
            style: TextStyle(color: Colors.orange[700]),
          ),
        ],
        if (progress.failedOperations > 0) ...[
          const SizedBox(height: 8),
          Text(
            '${progress.failedOperations} operations failed',
            style: TextStyle(color: Colors.red[700]),
          ),
        ],
      ],
    );
  }

  /// Build progress content with detailed statistics.
  Widget _buildProgressContent(BuildContext context, SyncProgress progress) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress bar
        LinearProgressIndicator(
          value: progress.percentage / 100,
          backgroundColor: Colors.grey[300],
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 12),

        // Progress percentage and count
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${progress.completedOperations}/${progress.totalOperations} operations',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${progress.percentage.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),

        // Current operation
        if (progress.currentOperation != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current operation:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress.currentOperation!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (progress.currentEntityType != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        _getEntityIcon(progress.currentEntityType!),
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatEntityType(progress.currentEntityType!),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // Statistics
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatChip(
              context,
              Icons.check_circle,
              progress.completedOperations.toString(),
              'Synced',
              Colors.green,
            ),
            _buildStatChip(
              context,
              Icons.pending,
              progress.remainingOperations.toString(),
              'Pending',
              Colors.orange,
            ),
            if (progress.conflictsDetected > 0)
              _buildStatChip(
                context,
                Icons.warning_amber,
                progress.conflictsDetected.toString(),
                'Conflicts',
                Colors.amber,
              ),
            if (progress.failedOperations > 0)
              _buildStatChip(
                context,
                Icons.error,
                progress.failedOperations.toString(),
                'Failed',
                Colors.red,
              ),
          ],
        ),

        // ETA and throughput
        if (progress.estimatedTimeRemaining != null ||
            progress.throughput > 0) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (progress.estimatedTimeRemaining != null)
                _buildInfoRow(
                  context,
                  Icons.timer,
                  'ETA: ${_formatDuration(progress.estimatedTimeRemaining!)}',
                ),
              if (progress.throughput > 0)
                _buildInfoRow(
                  context,
                  Icons.speed,
                  '${progress.throughput.toStringAsFixed(1)} ops/s',
                ),
            ],
          ),
        ],

        // Sync phase
        const SizedBox(height: 12),
        Center(
          child: Text(
            _formatSyncPhase(progress.phase),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
          ),
        ),
      ],
    );
  }

  /// Build statistics chip.
  Widget _buildStatChip(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  /// Build info row.
  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  /// Build cancel button.
  Widget _buildCancelButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _handleCancel(context),
      icon: const Icon(Icons.cancel),
      label: const Text('Cancel Sync'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
      ),
    );
  }

  /// Handle cancel button press.
  void _handleCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Sync'),
        content: const Text(
          'Are you sure you want to cancel the sync? '
          'Progress will be lost and you may need to sync again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Syncing'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close confirmation dialog
              if (widget.onCancel != null) {
                widget.onCancel!();
              } else {
                try {
                  // Get SyncManager from provider and cancel sync
                  final syncStatusProvider = Provider.of<SyncStatusProvider>(
                    context,
                    listen: false,
                  );
                  
                  _log.info('Cancelling sync via SyncManager');
                  await syncStatusProvider.syncManager.cancelSync();
                  _log.info('Sync cancelled successfully');
                } catch (e, stackTrace) {
                  _log.severe(
                    'Failed to cancel sync',
                    e,
                    stackTrace,
                  );
                }
              }
              Navigator.pop(context); // Close progress widget
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Sync'),
          ),
        ],
      ),
    );
  }

  /// Format duration for display.
  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format sync phase for display.
  String _formatSyncPhase(SyncPhase phase) {
    switch (phase) {
      case SyncPhase.preparing:
        return 'Preparing...';
      case SyncPhase.syncing:
        return 'Syncing operations...';
      case SyncPhase.detectingConflicts:
        return 'Detecting conflicts...';
      case SyncPhase.resolvingConflicts:
        return 'Resolving conflicts...';
      case SyncPhase.pulling:
        return 'Pulling updates...';
      case SyncPhase.finalizing:
        return 'Finalizing...';
      case SyncPhase.completed:
        return 'Completed';
      case SyncPhase.failed:
        return 'Failed';
    }
  }

  /// Format entity type for display.
  String _formatEntityType(String entityType) {
    return entityType[0].toUpperCase() + entityType.substring(1);
  }

  /// Get icon for entity type.
  IconData _getEntityIcon(String entityType) {
    switch (entityType.toLowerCase()) {
      case 'transaction':
        return Icons.receipt;
      case 'account':
        return Icons.account_balance;
      case 'category':
        return Icons.category;
      case 'budget':
        return Icons.account_balance_wallet;
      case 'bill':
        return Icons.receipt_long;
      case 'piggybank':
        return Icons.savings;
      default:
        return Icons.sync;
    }
  }
}

/// Helper function to show sync progress as bottom sheet.
Future<void> showSyncProgressSheet(
  BuildContext context, {
  bool allowCancel = true,
  VoidCallback? onCancel,
  bool autoDismissOnComplete = true,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (context) => SyncProgressWidget(
      displayMode: SyncProgressDisplayMode.sheet,
      allowCancel: allowCancel,
      onCancel: onCancel,
      autoDismissOnComplete: autoDismissOnComplete,
    ),
  );
}

/// Helper function to show sync progress as dialog.
Future<void> showSyncProgressDialog(
  BuildContext context, {
  bool allowCancel = true,
  VoidCallback? onCancel,
  bool autoDismissOnComplete = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => SyncProgressWidget(
      displayMode: SyncProgressDisplayMode.dialog,
      allowCancel: allowCancel,
      onCancel: onCancel,
      autoDismissOnComplete: autoDismissOnComplete,
    ),
  );
}
