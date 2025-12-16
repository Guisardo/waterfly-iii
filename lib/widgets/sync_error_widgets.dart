import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:waterflyiii/exceptions/sync_exceptions.dart';

/// Widgets for displaying sync errors with user-friendly messages.
///
/// Features:
/// - User-friendly error messages
/// - "Retry" button
/// - "View Details" button
/// - Error timestamp
/// - Appropriate icons and colors
/// - Specific dialogs for each error type
class SyncErrorWidgets {
  // Reserved for future logging of sync error events
  // ignore: unused_field
  static final Logger _logger = Logger('SyncErrorWidgets');

  /// Build error card widget
  static Widget buildErrorCard({
    required BuildContext context,
    required Exception error,
    required DateTime timestamp,
    VoidCallback? onRetry,
    VoidCallback? onViewDetails,
  }) {
    final Map<String, dynamic> errorInfo = _getErrorInfo(error);

    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  errorInfo['icon'] as IconData,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorInfo['title'] as String,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              errorInfo['message'] as String,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                if (onViewDetails != null)
                  TextButton(
                    onPressed: onViewDetails,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    child: const Text('View Details'),
                  ),
                if (onRetry != null) ...<Widget>[
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onRetry,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show error dialog
  static Future<void> showErrorDialog({
    required BuildContext context,
    required Exception error,
    VoidCallback? onRetry,
  }) async {
    final Map<String, dynamic> errorInfo = _getErrorInfo(error);

    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        icon: Icon(
          errorInfo['icon'] as IconData,
          color: Theme.of(context).colorScheme.error,
        ),
        title: Text(errorInfo['title'] as String),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(errorInfo['message'] as String),
            if (errorInfo['suggestion'] != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                'Suggestion:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(errorInfo['suggestion'] as String),
            ],
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (onRetry != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                onRetry();
              },
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }

  /// Show error snackbar
  static void showErrorSnackbar({
    required BuildContext context,
    required Exception error,
    VoidCallback? onRetry,
  }) {
    final Map<String, dynamic> errorInfo = _getErrorInfo(error);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            Icon(
              errorInfo['icon'] as IconData,
              color: Theme.of(context).colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(errorInfo['message'] as String),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: Theme.of(context).colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Get error information
  static Map<String, dynamic> _getErrorInfo(Exception error) {
    if (error is NetworkError) {
      return <String, dynamic>{
        'icon': Icons.wifi_off,
        'title': 'Network Error',
        'message': 'Unable to connect to the server. Please check your internet connection.',
        'suggestion': 'Make sure you are connected to the internet and try again.',
      };
    }

    if (error is ServerError) {
      return <String, dynamic>{
        'icon': Icons.cloud_off,
        'title': 'Server Error',
        'message': 'The server encountered an error. Please try again later.',
        'suggestion': 'If the problem persists, contact support.',
      };
    }

    if (error is AuthenticationError) {
      return <String, dynamic>{
        'icon': Icons.lock_outline,
        'title': 'Authentication Error',
        'message': 'Your session has expired. Please log in again.',
        'suggestion': 'Go to settings and re-authenticate.',
      };
    }

    if (error is ValidationError) {
      return <String, dynamic>{
        'icon': Icons.error_outline,
        'title': 'Validation Error',
        'message': error.message,
        'suggestion': 'Please check your data and try again.',
      };
    }

    if (error is ConflictError) {
      return <String, dynamic>{
        'icon': Icons.warning_amber,
        'title': 'Conflict Detected',
        'message': 'This data has been modified on the server.',
        'suggestion': 'Please resolve the conflict manually.',
      };
    }

    if (error is RateLimitError) {
      return <String, dynamic>{
        'icon': Icons.speed,
        'title': 'Too Many Requests',
        'message': 'You are making too many requests. Please wait a moment.',
        'suggestion': 'Try again in a few minutes.',
      };
    }

    if (error is TimeoutError) {
      return <String, dynamic>{
        'icon': Icons.access_time,
        'title': 'Request Timeout',
        'message': 'The request took too long to complete.',
        'suggestion': 'Check your connection and try again.',
      };
    }

    if (error is CircuitBreakerOpenError) {
      return <String, dynamic>{
        'icon': Icons.block,
        'title': 'Service Temporarily Unavailable',
        'message': 'Too many errors occurred. Service is temporarily disabled.',
        'suggestion': 'Please wait a moment before trying again.',
      };
    }

    // Generic error
    return <String, dynamic>{
      'icon': Icons.error,
      'title': 'Sync Error',
      'message': error.toString(),
      'suggestion': null,
    };
  }

  static String _formatTimestamp(DateTime timestamp) {
    final DateTime now = DateTime.now();
    final Duration diff = now.difference(timestamp);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}

/// Error details dialog
class ErrorDetailsDialog extends StatelessWidget {
  final Exception error;
  final DateTime timestamp;
  final String? stackTrace;

  const ErrorDetailsDialog({
    super.key,
    required this.error,
    required this.timestamp,
    this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Error Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildDetailRow(context, 'Type', error.runtimeType.toString()),
            _buildDetailRow(context, 'Time', timestamp.toString()),
            _buildDetailRow(context, 'Message', error.toString()),
            if (stackTrace != null) ...<Widget>[
              const SizedBox(height: 16),
              Text(
                'Stack Trace:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  stackTrace!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
