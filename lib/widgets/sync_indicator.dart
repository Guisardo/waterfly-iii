import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/providers/sync_provider.dart';

/// Small persistent indicator showing sync progress.
/// Displays in app bar when sync is active.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (!syncProvider.isSyncing) {
          return const SizedBox.shrink();
        }

        final progress = syncProvider.progress;
        final hasProgress = progress > 0;
        final currentOp = syncProvider.currentOperation;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;

        return Tooltip(
          message: currentOp ?? 'Syncing data...',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Progress indicator with percentage
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background circle
                      CircularProgressIndicator(
                        value: hasProgress ? progress : null,
                        strokeWidth: 2.5,
                        backgroundColor: primaryColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                      // Percentage text (only show if we have progress)
                      if (hasProgress)
                        Text(
                          '${syncProvider.progressPercent}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: primaryColor,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Sync label with operation name
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasProgress
                              ? 'Syncing ${syncProvider.progressPercent}%'
                              : 'Syncing...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (currentOp != null)
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 120),
                        child: Text(
                          currentOp,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: primaryColor.withValues(alpha: 0.7),
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact sync indicator for tight spaces (just shows icon with progress)
class SyncIndicatorCompact extends StatelessWidget {
  const SyncIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SyncProvider>(
      builder: (context, syncProvider, child) {
        if (!syncProvider.isSyncing) {
          return const SizedBox.shrink();
        }

        final progress = syncProvider.progress;
        final hasProgress = progress > 0;
        final theme = Theme.of(context);
        final primaryColor = theme.colorScheme.primary;

        return Tooltip(
          message: syncProvider.currentOperation ?? 
              'Syncing... ${syncProvider.progressPercent}%',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: hasProgress ? progress : null,
                    strokeWidth: 2,
                    backgroundColor: primaryColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  if (hasProgress)
                    Text(
                      '${syncProvider.progressPercent}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: primaryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
