import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';

/// A dashboard card widget displaying incremental sync status and quick actions.
///
/// This widget provides a compact, informative overview of incremental sync:
/// - Current sync status (enabled/disabled, last sync time)
/// - Quick efficiency metrics (skip rate, bandwidth saved)
/// - One-tap sync trigger button
/// - Warning indicators when full sync is recommended
/// - Live progress during active sync
///
/// ## Display Modes
///
/// - **Standard Mode:** Full card with all details
/// - **Compact Mode:** Minimal display for smaller spaces
/// - **Mini Mode:** Icon-only status indicator
///
/// ## Integration
///
/// Designed to be placed on the home dashboard or any overview screen.
/// Works seamlessly with OfflineSettingsProvider and IncrementalSyncService.
///
/// ## Example Usage
///
/// ```dart
/// // Standard dashboard card
/// IncrementalSyncDashboardCard(
///   onSyncTap: () => triggerSync(),
///   onSettingsTap: () => navigateToSettings(),
/// )
///
/// // Compact mode for tighter layouts
/// IncrementalSyncDashboardCard(
///   mode: IncrementalSyncDashboardCardMode.compact,
///   onSyncTap: () => triggerSync(),
/// )
///
/// // With live sync progress
/// IncrementalSyncDashboardCard(
///   isSyncing: true,
///   currentProgress: syncProgress,
/// )
/// ```
class IncrementalSyncDashboardCard extends StatefulWidget {
  const IncrementalSyncDashboardCard({
    super.key,
    this.mode = IncrementalSyncDashboardCardMode.standard,
    this.onSyncTap,
    this.onSettingsTap,
    this.isSyncing = false,
    this.currentProgress,
    this.progressStream,
  });

  /// Display mode for the card.
  final IncrementalSyncDashboardCardMode mode;

  /// Callback when sync button is tapped.
  final VoidCallback? onSyncTap;

  /// Callback when settings is tapped.
  final VoidCallback? onSettingsTap;

  /// Whether sync is currently in progress.
  final bool isSyncing;

  /// Current sync progress (if syncing).
  final SyncProgressEvent? currentProgress;

  /// Stream of progress events for live updates.
  final Stream<SyncProgressEvent>? progressStream;

  @override
  State<IncrementalSyncDashboardCard> createState() =>
      _IncrementalSyncDashboardCardState();
}

class _IncrementalSyncDashboardCardState
    extends State<IncrementalSyncDashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<SyncProgressEvent>? _progressSubscription;
  SyncProgressEvent? _latestProgress;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isSyncing) {
      _pulseController.repeat(reverse: true);
    }

    _subscribeToProgress();
  }

  @override
  void didUpdateWidget(IncrementalSyncDashboardCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSyncing && !oldWidget.isSyncing) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSyncing && oldWidget.isSyncing) {
      _pulseController.stop();
      _pulseController.reset();
    }

    if (widget.progressStream != oldWidget.progressStream) {
      _progressSubscription?.cancel();
      _subscribeToProgress();
    }
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _subscribeToProgress() {
    if (widget.progressStream != null) {
      _progressSubscription = widget.progressStream!.listen((
        SyncProgressEvent event,
      ) {
        if (mounted) {
          setState(() {
            _latestProgress = event;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSettingsProvider>(
      builder: (
        BuildContext context,
        OfflineSettingsProvider settings,
        Widget? child,
      ) {
        switch (widget.mode) {
          case IncrementalSyncDashboardCardMode.standard:
            return _buildStandardCard(context, settings);
          case IncrementalSyncDashboardCardMode.compact:
            return _buildCompactCard(context, settings);
          case IncrementalSyncDashboardCardMode.mini:
            return _buildMiniCard(context, settings);
        }
      },
    );
  }

  /// Build standard full card.
  Widget _buildStandardCard(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    final bool isSyncing = widget.isSyncing;
    final SyncProgressEvent? progress =
        widget.currentProgress ?? _latestProgress;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onSettingsTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: <Widget>[
                  _buildStatusIcon(context, settings, isSyncing),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Incremental Sync',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _getStatusText(settings, isSyncing, progress),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.onSettingsTap != null)
                    IconButton(
                      onPressed: widget.onSettingsTap,
                      icon: const Icon(Icons.settings),
                      iconSize: 20,
                      tooltip: 'Settings',
                    ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  if (isSyncing && progress != null)
                    _buildProgressIndicator(context, progress)
                  else
                    _buildQuickStats(context, settings),
                  const SizedBox(height: 12),
                  if (settings.needsFullSync && !isSyncing)
                    _buildFullSyncWarning(context),
                  if (!isSyncing) _buildSyncButton(context, settings),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build compact card.
  Widget _buildCompactCard(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    final bool isSyncing = widget.isSyncing;
    final SyncProgressEvent? progress =
        widget.currentProgress ?? _latestProgress;

    return Card(
      child: InkWell(
        onTap: isSyncing ? null : widget.onSyncTap,
        onLongPress: widget.onSettingsTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              _buildStatusIcon(context, settings, isSyncing, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Sync',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(context, settings, isSyncing),
                      ],
                    ),
                    if (isSyncing && progress != null)
                      LinearProgressIndicator(
                        value:
                            progress.progressPercent != null
                                ? progress.progressPercent! / 100.0
                                : null,
                        minHeight: 4,
                        borderRadius: BorderRadius.circular(2),
                      )
                    else
                      Text(
                        _getCompactStatusText(settings),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (!isSyncing)
                IconButton(
                  onPressed: widget.onSyncTap,
                  icon: Icon(
                    Icons.sync,
                    color:
                        settings.needsFullSync
                            ? Colors.orange
                            : Theme.of(context).colorScheme.primary,
                  ),
                  tooltip: 'Sync now',
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build mini card (icon-only).
  Widget _buildMiniCard(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    final bool isSyncing = widget.isSyncing;

    return Tooltip(
      message: _getStatusText(
        settings,
        isSyncing,
        widget.currentProgress ?? _latestProgress,
      ),
      child: InkWell(
        onTap: isSyncing ? null : widget.onSyncTap,
        onLongPress: widget.onSettingsTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getStatusBackgroundColor(context, settings, isSyncing),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildStatusIcon(context, settings, isSyncing, size: 24),
        ),
      ),
    );
  }

  /// Build status icon with optional animation.
  Widget _buildStatusIcon(
    BuildContext context,
    OfflineSettingsProvider settings,
    bool isSyncing, {
    double size = 48,
  }) {
    final IconData icon;
    final Color color;

    if (isSyncing) {
      icon = Icons.sync;
      color = Theme.of(context).colorScheme.primary;
    } else if (settings.needsFullSync) {
      icon = Icons.sync_problem;
      color = Colors.orange;
    } else if (!settings.incrementalSyncEnabled) {
      icon = Icons.sync_disabled;
      color = Colors.grey;
    } else {
      icon = Icons.sync;
      color = Colors.green;
    }

    Widget iconWidget = Icon(icon, color: color, size: size);

    if (isSyncing) {
      iconWidget = AnimatedBuilder(
        animation: _pulseAnimation,
        builder:
            (BuildContext context, Widget? child) =>
                Transform.scale(scale: _pulseAnimation.value, child: child),
        child: iconWidget,
      );
    }

    return Container(
      padding: EdgeInsets.all(size / 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: iconWidget,
    );
  }

  /// Build status badge.
  Widget _buildStatusBadge(
    BuildContext context,
    OfflineSettingsProvider settings,
    bool isSyncing,
  ) {
    final String label;
    final Color color;

    if (isSyncing) {
      label = 'SYNCING';
      color = Theme.of(context).colorScheme.primary;
    } else if (settings.needsFullSync) {
      label = 'OUTDATED';
      color = Colors.orange;
    } else if (!settings.incrementalSyncEnabled) {
      label = 'DISABLED';
      color = Colors.grey;
    } else {
      label = 'OK';
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Build progress indicator during sync.
  Widget _buildProgressIndicator(
    BuildContext context,
    SyncProgressEvent progress,
  ) {
    return Column(
      children: <Widget>[
        if (progress.progressPercent != null) ...<Widget>[
          LinearProgressIndicator(
            value: progress.progressPercent! / 100.0,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                progress.entityType != null
                    ? _formatEntityType(progress.entityType!)
                    : 'Processing...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '${progress.progressPercent!.toStringAsFixed(0)}%',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ] else
          const LinearProgressIndicator(minHeight: 8),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildProgressStat(
              context,
              value: progress.itemsFetched.toString(),
              label: 'Fetched',
              color: Colors.blue,
            ),
            _buildProgressStat(
              context,
              value: progress.itemsUpdated.toString(),
              label: 'Updated',
              color: Colors.orange,
            ),
            _buildProgressStat(
              context,
              value: progress.itemsSkipped.toString(),
              label: 'Skipped',
              color: Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  /// Build quick statistics display.
  Widget _buildQuickStats(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    if (!settings.incrementalSyncEnabled) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Incremental sync is disabled. Enable it in settings for faster syncs.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    if (settings.incrementalSyncCount == 0) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.rocket_launch,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Run your first incremental sync to see efficiency metrics!',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: <Widget>[
        Expanded(
          child: _buildQuickStatItem(
            context,
            icon: Icons.speed,
            value: '${settings.overallSkipRate.toStringAsFixed(0)}%',
            label: 'Efficiency',
            color: _getEfficiencyColor(settings.overallSkipRate),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatItem(
            context,
            icon: Icons.data_saver_on,
            value: settings.formattedBandwidthSaved,
            label: 'Saved',
            color: Colors.teal,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatItem(
            context,
            icon: Icons.sync,
            value: '${settings.incrementalSyncCount}',
            label: 'Syncs',
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  /// Build quick stat item.
  Widget _buildQuickStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build progress stat item.
  Widget _buildProgressStat(
    BuildContext context, {
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// Build full sync warning banner.
  Widget _buildFullSyncWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Full sync recommended (>7 days)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  /// Build sync button.
  Widget _buildSyncButton(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: widget.onSyncTap,
        icon: Icon(settings.needsFullSync ? Icons.sync_alt : Icons.sync),
        label: Text(settings.needsFullSync ? 'Full Sync' : 'Sync Now'),
        style:
            settings.needsFullSync
                ? ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                )
                : null,
      ),
    );
  }

  /// Get status text based on current state.
  String _getStatusText(
    OfflineSettingsProvider settings,
    bool isSyncing,
    SyncProgressEvent? progress,
  ) {
    if (isSyncing) {
      if (progress != null && progress.entityType != null) {
        return 'Syncing ${_formatEntityType(progress.entityType!)}...';
      }
      return 'Syncing in progress...';
    }

    if (!settings.incrementalSyncEnabled) {
      return 'Incremental sync disabled';
    }

    if (settings.needsFullSync) {
      return 'Full sync recommended';
    }

    if (settings.lastIncrementalSyncTime != null) {
      return 'Last sync: ${_formatRelativeTime(settings.lastIncrementalSyncTime!)}';
    }

    return 'Ready to sync';
  }

  /// Get compact status text.
  String _getCompactStatusText(OfflineSettingsProvider settings) {
    if (!settings.incrementalSyncEnabled) {
      return 'Disabled';
    }

    if (settings.needsFullSync) {
      return 'Needs full sync';
    }

    if (settings.lastIncrementalSyncTime != null) {
      return _formatRelativeTime(settings.lastIncrementalSyncTime!);
    }

    return 'Not synced yet';
  }

  /// Get status background color.
  Color _getStatusBackgroundColor(
    BuildContext context,
    OfflineSettingsProvider settings,
    bool isSyncing,
  ) {
    if (isSyncing) {
      return Theme.of(context).colorScheme.primaryContainer;
    }
    if (settings.needsFullSync) {
      return Colors.orange.withOpacity(0.2);
    }
    if (!settings.incrementalSyncEnabled) {
      return Colors.grey.withOpacity(0.2);
    }
    return Colors.green.withOpacity(0.2);
  }

  /// Format entity type for display.
  String _formatEntityType(String entityType) {
    switch (entityType) {
      case 'transaction':
        return 'Transactions';
      case 'account':
        return 'Accounts';
      case 'budget':
        return 'Budgets';
      case 'category':
        return 'Categories';
      case 'bill':
        return 'Bills';
      case 'piggy_bank':
        return 'Piggy Banks';
      default:
        return entityType[0].toUpperCase() + entityType.substring(1);
    }
  }

  /// Format relative time.
  String _formatRelativeTime(DateTime dateTime) {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(dateTime);
  }

  /// Get efficiency color based on skip rate.
  Color _getEfficiencyColor(double skipRate) {
    if (skipRate >= 80) return Colors.green;
    if (skipRate >= 60) return Colors.lightGreen;
    if (skipRate >= 40) return Colors.amber;
    return Colors.orange;
  }
}

/// Display mode for the dashboard card.
enum IncrementalSyncDashboardCardMode {
  /// Full card with all details.
  standard,

  /// Compact horizontal display.
  compact,

  /// Icon-only mini display.
  mini,
}
