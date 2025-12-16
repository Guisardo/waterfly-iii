import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';

final Logger _log = Logger('IncrementalSyncProgressWidget');

/// A comprehensive progress widget specifically designed for incremental sync.
///
/// This widget provides detailed progress information including:
/// - Overall progress with percentage
/// - Current entity type being synced
/// - Per-entity-type breakdown with icons
/// - Real-time statistics (fetched, updated, skipped)
/// - Retry notifications
/// - Cache hit indicators
/// - Completion summary
///
/// ## Features
///
/// **Entity-Level Progress:**
/// Shows which entity type is currently being synced with appropriate icons:
/// - Transactions: receipt icon
/// - Accounts: bank icon
/// - Budgets: wallet icon
/// - Categories: category icon
/// - Bills: receipt_long icon
/// - Piggy Banks: savings icon
///
/// **Real-Time Statistics:**
/// Displays live counts of items fetched, updated, and skipped during sync.
///
/// **Three-Tier Visual Indicators:**
/// - Tier 1 (Date-Range Filtered): Blue indicators
/// - Tier 2 (Extended Cache): Green indicators with cache badges
///
/// ## Example Usage
///
/// ```dart
/// // As a dialog
/// showDialog(
///   context: context,
///   barrierDismissible: false,
///   builder: (context) => IncrementalSyncProgressWidget(
///     progressStream: syncService.progressStream,
///     displayMode: IncrementalSyncProgressDisplayMode.dialog,
///     onCancel: () => syncService.cancel(),
///   ),
/// );
///
/// // As an embedded widget
/// IncrementalSyncProgressWidget(
///   progressStream: syncService.progressStream,
///   displayMode: IncrementalSyncProgressDisplayMode.embedded,
/// )
/// ```
class IncrementalSyncProgressWidget extends StatefulWidget {
  const IncrementalSyncProgressWidget({
    super.key,
    required this.progressStream,
    this.displayMode = IncrementalSyncProgressDisplayMode.dialog,
    this.allowCancel = true,
    this.onCancel,
    this.onComplete,
    this.autoDismissOnComplete = true,
    this.autoDismissDelay = const Duration(seconds: 3),
  });

  /// Stream of progress events from IncrementalSyncService.
  final Stream<SyncProgressEvent> progressStream;

  /// Display mode (dialog, sheet, or embedded).
  final IncrementalSyncProgressDisplayMode displayMode;

  /// Whether to show cancel button.
  final bool allowCancel;

  /// Callback when cancel is pressed.
  final VoidCallback? onCancel;

  /// Callback when sync completes.
  final void Function(IncrementalSyncResult?)? onComplete;

  /// Whether to auto-dismiss when sync completes.
  final bool autoDismissOnComplete;

  /// Delay before auto-dismiss.
  final Duration autoDismissDelay;

  @override
  State<IncrementalSyncProgressWidget> createState() =>
      _IncrementalSyncProgressWidgetState();
}

class _IncrementalSyncProgressWidgetState
    extends State<IncrementalSyncProgressWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  StreamSubscription<SyncProgressEvent>? _subscription;
  Timer? _autoDismissTimer;

  // Current state
  final Map<String, IncrementalSyncStats> _entityStats =
      <String, IncrementalSyncStats>{};
  final List<String> _completedEntities = <String>[];
  String? _currentEntityType;
  bool _isComplete = false;
  bool _hasFailed = false;
  String? _errorMessage;
  IncrementalSyncResult? _result;

  // Progress tracking
  int _totalFetched = 0;
  int _totalUpdated = 0;
  int _totalSkipped = 0;
  int _cacheHits = 0;
  int _retryAttempts = 0;

  // Entity order for progress bar
  static const List<String> _entityOrder = <String>[
    'transaction',
    'account',
    'budget',
    'category',
    'bill',
    'piggy_bank',
  ];

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

    _subscribeToProgress();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _autoDismissTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  /// Subscribe to progress stream.
  void _subscribeToProgress() {
    _subscription = widget.progressStream.listen(
      _handleProgressEvent,
      onError: (Object error) {
        _log.severe('Progress stream error', error);
        setState(() {
          _hasFailed = true;
          _errorMessage = error.toString();
        });
      },
      onDone: () {
        _log.fine('Progress stream completed');
      },
    );
  }

  /// Handle incoming progress event.
  void _handleProgressEvent(SyncProgressEvent event) {
    if (!mounted) return;

    setState(() {
      switch (event.type) {
        case SyncProgressEventType.started:
          _log.fine('Sync started');
          _isComplete = false;
          _hasFailed = false;
          _errorMessage = null;
          _completedEntities.clear();
          _entityStats.clear();
          _totalFetched = 0;
          _totalUpdated = 0;
          _totalSkipped = 0;
          _cacheHits = 0;
          _retryAttempts = 0;
          break;

        case SyncProgressEventType.entityStarted:
          _currentEntityType = event.entityType;
          _log.fine('Started syncing: ${event.entityType}');
          break;

        case SyncProgressEventType.entityCompleted:
          if (event.entityType != null) {
            _completedEntities.add(event.entityType!);
            _entityStats[event.entityType!] = IncrementalSyncStats(
              entityType: event.entityType!,
              itemsFetched: event.itemsFetched,
              itemsUpdated: event.itemsUpdated,
              itemsSkipped: event.itemsSkipped,
            );
          }
          _currentEntityType = null;
          _log.fine('Completed: ${event.entityType}');
          break;

        case SyncProgressEventType.progress:
          _totalFetched = event.itemsFetched;
          _totalUpdated = event.itemsUpdated;
          _totalSkipped = event.itemsSkipped;
          break;

        case SyncProgressEventType.retry:
          _retryAttempts++;
          _log.warning('Retry: ${event.message}');
          break;

        case SyncProgressEventType.cacheHit:
          _cacheHits++;
          if (event.entityType != null) {
            _completedEntities.add(event.entityType!);
          }
          _log.fine('Cache hit: ${event.entityType}');
          break;

        case SyncProgressEventType.completed:
          _isComplete = true;
          _hasFailed = false;
          _totalFetched = event.itemsFetched;
          _totalUpdated = event.itemsUpdated;
          _totalSkipped = event.itemsSkipped;
          _log.info('Sync completed: ${event.message}');
          _handleCompletion();
          break;

        case SyncProgressEventType.failed:
          _hasFailed = true;
          _errorMessage = event.error ?? event.message;
          _log.severe('Sync failed: ${event.error}');
          break;
      }
    });
  }

  /// Handle sync completion.
  void _handleCompletion() {
    // Create result from accumulated stats
    _result = IncrementalSyncResult(
      isIncremental: true,
      success: !_hasFailed,
      duration: const Duration(), // Would need to track this
      statsByEntity: Map<String, IncrementalSyncStats>.from(_entityStats),
      error: _errorMessage,
    );

    // Notify completion callback
    widget.onComplete?.call(_result);

    // Auto-dismiss if enabled
    if (widget.autoDismissOnComplete && mounted && !_hasFailed) {
      _autoDismissTimer = Timer(widget.autoDismissDelay, () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: switch (widget.displayMode) {
        IncrementalSyncProgressDisplayMode.dialog =>
          _buildDialog(context),
        IncrementalSyncProgressDisplayMode.sheet =>
          _buildSheet(context),
        IncrementalSyncProgressDisplayMode.embedded =>
          _buildEmbedded(context),
      },
    );
  }

  /// Build dialog layout.
  Widget _buildDialog(BuildContext context) {
    return AlertDialog(
      title: _buildHeader(context),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: _buildContent(context),
        ),
      ),
      actions: _buildActions(context),
    );
  }

  /// Build sheet layout.
  Widget _buildSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildContent(context),
          if (widget.allowCancel && !_isComplete) ...<Widget>[
            const SizedBox(height: 24),
            ..._buildActions(context) ?? <Widget>[],
          ],
        ],
      ),
    );
  }

  /// Build embedded layout.
  Widget _buildEmbedded(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  /// Build header with status icon and title.
  Widget _buildHeader(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final String title;

    if (_hasFailed) {
      icon = Icons.error;
      iconColor = Colors.red;
      title = 'Sync Failed';
    } else if (_isComplete) {
      icon = Icons.check_circle;
      iconColor = Colors.green;
      title = 'Sync Complete';
    } else {
      icon = Icons.sync;
      iconColor = Theme.of(context).colorScheme.primary;
      title = 'Incremental Sync';
    }

    return Row(
      children: <Widget>[
        if (!_isComplete && !_hasFailed)
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_currentEntityType != null && !_isComplete && !_hasFailed)
                Text(
                  'Syncing ${_formatEntityType(_currentEntityType!)}...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build main content area.
  Widget _buildContent(BuildContext context) {
    if (_hasFailed) {
      return _buildErrorContent(context);
    }

    if (_isComplete) {
      return _buildCompleteContent(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildEntityProgressList(context),
        const SizedBox(height: 16),
        _buildLiveStats(context),
        if (_retryAttempts > 0) ...<Widget>[
          const SizedBox(height: 12),
          _buildRetryIndicator(context),
        ],
        if (_cacheHits > 0) ...<Widget>[
          const SizedBox(height: 12),
          _buildCacheHitIndicator(context),
        ],
      ],
    );
  }

  /// Build entity progress list.
  Widget _buildEntityProgressList(BuildContext context) {
    return Column(
      children: _entityOrder.map((String entityType) {
        final bool isCompleted = _completedEntities.contains(entityType);
        final bool isCurrent = _currentEntityType == entityType;
        final IncrementalSyncStats? stats = _entityStats[entityType];
        final bool isCacheHit = isCompleted && stats == null;

        return _buildEntityProgressItem(
          context,
          entityType: entityType,
          isCompleted: isCompleted,
          isCurrent: isCurrent,
          stats: stats,
          isCacheHit: isCacheHit,
        );
      }).toList(),
    );
  }

  /// Build single entity progress item.
  Widget _buildEntityProgressItem(
    BuildContext context, {
    required String entityType,
    required bool isCompleted,
    required bool isCurrent,
    IncrementalSyncStats? stats,
    bool isCacheHit = false,
  }) {
    final Color iconColor;
    final Widget trailing;

    if (isCompleted) {
      iconColor = Colors.green;
      if (isCacheHit) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'CACHED',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check, color: Colors.green, size: 20),
          ],
        );
      } else if (stats != null) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              '${stats.itemsUpdated}/${stats.itemsFetched}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.check, color: Colors.green, size: 20),
          ],
        );
      } else {
        trailing = const Icon(Icons.check, color: Colors.green, size: 20);
      }
    } else if (isCurrent) {
      iconColor = Theme.of(context).colorScheme.primary;
      trailing = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(iconColor),
        ),
      );
    } else {
      iconColor = Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5);
      trailing = Icon(Icons.circle_outlined, color: iconColor, size: 20);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          _getEntityIcon(entityType, iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _formatEntityType(entityType),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : null,
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : isCompleted
                                ? Colors.green
                                : null,
                      ),
                ),
                if (_isTier2Entity(entityType))
                  Text(
                    'Extended cache',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.7),
                          fontSize: 10,
                        ),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  /// Build live statistics display.
  Widget _buildLiveStats(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _buildStatItem(
            context,
            icon: Icons.download,
            value: _totalFetched.toString(),
            label: 'Fetched',
            color: Colors.blue,
          ),
          _buildStatItem(
            context,
            icon: Icons.edit,
            value: _totalUpdated.toString(),
            label: 'Updated',
            color: Colors.orange,
          ),
          _buildStatItem(
            context,
            icon: Icons.skip_next,
            value: _totalSkipped.toString(),
            label: 'Skipped',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  /// Build single stat item.
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: <Widget>[
        Icon(icon, color: color, size: 20),
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
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  /// Build retry indicator.
  Widget _buildRetryIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.refresh, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Text(
            '$_retryAttempts retry attempt${_retryAttempts > 1 ? "s" : ""}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.orange,
                ),
          ),
        ],
      ),
    );
  }

  /// Build cache hit indicator.
  Widget _buildCacheHitIndicator(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.cached, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Text(
            '$_cacheHits entity type${_cacheHits > 1 ? "s" : ""} served from cache',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
          ),
        ],
      ),
    );
  }

  /// Build error content.
  Widget _buildErrorContent(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(
            'Sync Failed',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'An unknown error occurred',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[800],
                ),
            textAlign: TextAlign.center,
          ),
          if (_completedEntities.isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              'Completed ${_completedEntities.length} entity types before failure',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red[700],
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build completion content.
  Widget _buildCompleteContent(BuildContext context) {
    final double skipRate =
        _totalFetched > 0 ? (_totalSkipped / _totalFetched) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // Success message
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: <Widget>[
              const Icon(Icons.check_circle, color: Colors.green, size: 48),
              const SizedBox(height: 12),
              Text(
                'Sync Completed Successfully',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green[900],
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Summary stats
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _buildCompletionStat(
              context,
              value: _totalUpdated.toString(),
              label: 'Updated',
              icon: Icons.edit,
              color: Colors.orange,
            ),
            _buildCompletionStat(
              context,
              value: _totalSkipped.toString(),
              label: 'Skipped',
              icon: Icons.skip_next,
              color: Colors.green,
            ),
            _buildCompletionStat(
              context,
              value: '${skipRate.toStringAsFixed(0)}%',
              label: 'Efficiency',
              icon: Icons.speed,
              color: _getEfficiencyColor(skipRate),
            ),
          ],
        ),

        if (_cacheHits > 0) ...<Widget>[
          const SizedBox(height: 12),
          Text(
            '$_cacheHits entity types served from cache',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  /// Build completion stat.
  Widget _buildCompletionStat(
    BuildContext context, {
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
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

  /// Build action buttons.
  List<Widget>? _buildActions(BuildContext context) {
    if (_isComplete) {
      return <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ];
    }

    if (!widget.allowCancel) return null;

    return <Widget>[
      TextButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: const Text('Cancel Sync?'),
              content: const Text(
                'Are you sure you want to cancel the sync? '
                'Progress will be lost.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onCancel?.call();
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancel Sync'),
                ),
              ],
            ),
          );
        },
        child: const Text('Cancel'),
      ),
    ];
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

  /// Get icon widget for entity type.
  Widget _getEntityIcon(String entityType, Color color) {
    final IconData icon;
    switch (entityType) {
      case 'transaction':
        icon = Icons.receipt;
        break;
      case 'account':
        icon = Icons.account_balance;
        break;
      case 'budget':
        icon = Icons.account_balance_wallet;
        break;
      case 'category':
        icon = Icons.category;
        break;
      case 'bill':
        icon = Icons.receipt_long;
        break;
      case 'piggy_bank':
        icon = Icons.savings;
        break;
      default:
        icon = Icons.sync;
    }
    return Icon(icon, color: color, size: 24);
  }

  /// Check if entity type is Tier 2 (extended cache).
  bool _isTier2Entity(String entityType) {
    return entityType == 'category' ||
        entityType == 'bill' ||
        entityType == 'piggy_bank';
  }

  /// Get efficiency color based on skip rate.
  Color _getEfficiencyColor(double skipRate) {
    if (skipRate >= 80) return Colors.green;
    if (skipRate >= 60) return Colors.lightGreen;
    if (skipRate >= 40) return Colors.amber;
    return Colors.orange;
  }
}

/// Display mode for the incremental sync progress widget.
enum IncrementalSyncProgressDisplayMode {
  /// Show as dialog.
  dialog,

  /// Show as bottom sheet.
  sheet,

  /// Embed in another widget.
  embedded,
}

/// Helper function to show incremental sync progress as dialog.
Future<void> showIncrementalSyncProgressDialog(
  BuildContext context, {
  required Stream<SyncProgressEvent> progressStream,
  bool allowCancel = true,
  VoidCallback? onCancel,
  void Function(IncrementalSyncResult?)? onComplete,
  bool autoDismissOnComplete = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) => IncrementalSyncProgressWidget(
      progressStream: progressStream,
      displayMode: IncrementalSyncProgressDisplayMode.dialog,
      allowCancel: allowCancel,
      onCancel: onCancel,
      onComplete: onComplete,
      autoDismissOnComplete: autoDismissOnComplete,
    ),
  );
}

/// Helper function to show incremental sync progress as bottom sheet.
Future<void> showIncrementalSyncProgressSheet(
  BuildContext context, {
  required Stream<SyncProgressEvent> progressStream,
  bool allowCancel = true,
  VoidCallback? onCancel,
  void Function(IncrementalSyncResult?)? onComplete,
  bool autoDismissOnComplete = true,
}) {
  return showModalBottomSheet(
    context: context,
    isDismissible: false,
    enableDrag: false,
    builder: (BuildContext context) => IncrementalSyncProgressWidget(
      progressStream: progressStream,
      displayMode: IncrementalSyncProgressDisplayMode.sheet,
      allowCancel: allowCancel,
      onCancel: onCancel,
      onComplete: onComplete,
      autoDismissOnComplete: autoDismissOnComplete,
    ),
  );
}

