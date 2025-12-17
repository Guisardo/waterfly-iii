import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import 'package:waterflyiii/providers/connectivity_provider.dart';
import 'package:waterflyiii/services/connectivity/connectivity_status.dart';

/// Offline mode indicator for transaction forms.
///
/// Features:
/// - Shows offline status at top of form
/// - Warning message for offline transactions
/// - "Save Offline" button label
/// - Sync status after save
/// - Material 3 design
class TransactionOfflineIndicator extends StatelessWidget {
  // Reserved for future logging of transaction indicator events
  // ignore: unused_field
  static final Logger _logger = Logger('TransactionOfflineIndicator');

  /// Whether this is a new transaction (create) or edit
  final bool isNewTransaction;

  /// Callback when user taps "Learn More"
  final VoidCallback? onLearnMore;

  const TransactionOfflineIndicator({
    super.key,
    this.isNewTransaction = true,
    this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (
        BuildContext context,
        ConnectivityProvider connectivityProvider,
        Widget? child,
      ) {
        final ConnectivityStatus status = connectivityProvider.status;

        if (status == ConnectivityStatus.online) {
          return const SizedBox.shrink();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.cloud_off,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Offline Mode',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isNewTransaction
                            ? 'Transaction will be saved locally and synced when online'
                            : 'Changes will be saved locally and synced when online',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onLearnMore != null)
                  TextButton(
                    onPressed: onLearnMore,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                    child: const Text('Learn More'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Helper to get appropriate save button label based on connectivity
class SaveButtonHelper {
  static String getSaveButtonLabel(BuildContext context, bool isOffline) {
    if (isOffline) {
      return 'Save Offline';
    }
    return 'Save';
  }

  static IconData getSaveButtonIcon(bool isOffline) {
    if (isOffline) {
      return Icons.save_outlined;
    }
    return Icons.check;
  }
}

/// Success message widget after saving transaction
class TransactionSaveSuccessMessage extends StatelessWidget {
  final bool wasOffline;
  final bool isSynced;

  const TransactionSaveSuccessMessage({
    super.key,
    required this.wasOffline,
    required this.isSynced,
  });

  @override
  Widget build(BuildContext context) {
    String message;
    IconData icon;
    Color? backgroundColor;

    if (wasOffline) {
      if (isSynced) {
        message = 'Transaction saved and synced';
        icon = Icons.cloud_done;
        backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
      } else {
        message = 'Transaction saved offline. Will sync when online.';
        icon = Icons.cloud_queue;
        backgroundColor = Theme.of(context).colorScheme.primaryContainer;
      }
    } else {
      message = 'Transaction saved';
      icon = Icons.check_circle;
      backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: backgroundColor,
      child: Row(
        children: <Widget>[
          Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
