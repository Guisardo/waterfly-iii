import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/providers/connectivity_provider.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';

/// Logger for EntitySyncButton.
final Logger _log = Logger('EntitySyncButton');

/// Entity types that can be synced.
///
/// Maps to the entity type strings expected by [IncrementalSyncService.forceSyncEntityType].
enum SyncableEntityType {
  /// Transactions entity type.
  transaction('transaction', Icons.receipt_long),

  /// Accounts entity type.
  account('account', Icons.account_balance),

  /// Bills entity type.
  bill('bill', Icons.calendar_today),

  /// Categories entity type.
  category('category', Icons.category),

  /// Piggy banks entity type.
  piggyBank('piggy_bank', Icons.savings),

  /// Budgets entity type.
  budget('budget', Icons.pie_chart);

  const SyncableEntityType(this.apiName, this.icon);

  /// The API name used by IncrementalSyncService.
  final String apiName;

  /// Icon representing this entity type.
  final IconData icon;
}

/// A reusable button widget for triggering entity-specific database synchronization.
///
/// Provides a consistent UI for force syncing any entity type from the Firefly III
/// server to the local database. Shows sync progress and handles errors gracefully.
///
/// Features:
/// - Visual feedback during sync (spinning indicator)
/// - Connectivity check before sync
/// - Comprehensive error handling with user-friendly messages
/// - Snackbar notifications for success/failure
/// - Disabled state when offline or already syncing
///
/// Example usage:
/// ```dart
/// // In app bar actions
/// EntitySyncButton(
///   entityType: SyncableEntityType.bill,
///   onSyncComplete: () => setState(() {}),
/// )
///
/// // As a list tile action
/// EntitySyncButton.listTile(
///   entityType: SyncableEntityType.account,
///   onSyncComplete: () => _refreshAccounts(),
/// )
/// ```
///
/// The button automatically:
/// - Checks for network connectivity
/// - Shows progress during sync
/// - Displays success/error messages
/// - Calls [onSyncComplete] callback when done
class EntitySyncButton extends StatefulWidget {
  /// Creates an entity sync button (icon button variant).
  ///
  /// Parameters:
  /// - [entityType]: The type of entity to sync
  /// - [onSyncComplete]: Optional callback invoked after successful sync
  /// - [showLabel]: Whether to show a text label (default: false for icon button)
  const EntitySyncButton({
    super.key,
    required this.entityType,
    this.onSyncComplete,
    this.showLabel = false,
  }) : _isListTile = false;

  /// Creates an entity sync button as a list tile.
  ///
  /// Useful for settings screens or menu items.
  const EntitySyncButton.listTile({
    super.key,
    required this.entityType,
    this.onSyncComplete,
    this.showLabel = true,
  }) : _isListTile = true;

  /// The type of entity to sync.
  final SyncableEntityType entityType;

  /// Optional callback invoked after successful sync.
  ///
  /// Use this to refresh the UI after sync completes.
  final VoidCallback? onSyncComplete;

  /// Whether to show a text label alongside the icon.
  final bool showLabel;

  /// Internal flag for list tile variant.
  final bool _isListTile;

  @override
  State<EntitySyncButton> createState() => _EntitySyncButtonState();
}

class _EntitySyncButtonState extends State<EntitySyncButton>
    with SingleTickerProviderStateMixin {
  bool _isSyncing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Get localized entity name for display.
  String _getEntityName(BuildContext context) {
    final S l10n = S.of(context);
    switch (widget.entityType) {
      case SyncableEntityType.transaction:
        return l10n.homeTabLabelTransactions;
      case SyncableEntityType.account:
        return l10n.generalAccount;
      case SyncableEntityType.bill:
        return l10n.generalBill;
      case SyncableEntityType.category:
        return l10n.generalCategory;
      case SyncableEntityType.piggyBank:
        return l10n.homeTabLabelPiggybanks;
      case SyncableEntityType.budget:
        return l10n.generalBudget;
    }
  }

  /// Get tooltip text.
  String _getTooltip(BuildContext context) {
    final String entityName = _getEntityName(context);
    return S.of(context).generalSyncEntity(entityName);
  }

  /// Trigger sync for the entity type.
  Future<void> _triggerSync() async {
    if (_isSyncing) return;

    // Check connectivity
    final ConnectivityProvider connectivity =
        context.read<ConnectivityProvider>();
    if (!connectivity.isOnline) {
      _showSnackBar(
        context,
        S.of(context).generalOfflineMessage,
        isError: true,
      );
      return;
    }

    // Get sync service
    final IncrementalSyncService? syncService =
        context.read<IncrementalSyncService?>();
    if (syncService == null) {
      _log.warning('IncrementalSyncService not available');
      _showSnackBar(
        context,
        S.of(context).generalSyncNotAvailable,
        isError: true,
      );
      return;
    }

    setState(() {
      _isSyncing = true;
    });
    unawaited(_animationController.repeat());

    _log.info('Starting force sync for ${widget.entityType.apiName}');

    try {
      final IncrementalSyncStats stats = await syncService.forceSyncEntityType(
        widget.entityType.apiName,
      );

      _log.info(
        'Force sync completed for ${widget.entityType.apiName}: '
        '${stats.itemsUpdated} updated, ${stats.itemsSkipped} skipped',
      );

      if (mounted) {
        final String entityName = _getEntityName(context);
        _showSnackBar(
          context,
          S.of(context).generalSyncComplete(entityName, stats.itemsUpdated),
          isError: false,
        );

        // Invoke callback
        widget.onSyncComplete?.call();
      }
    } catch (e, stackTrace) {
      _log.severe(
        'Force sync failed for ${widget.entityType.apiName}',
        e,
        stackTrace,
      );

      if (mounted) {
        _showSnackBar(
          context,
          S.of(context).generalSyncFailed(e.toString()),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        _animationController.stop();
        _animationController.reset();
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }

  /// Show snackbar with message.
  void _showSnackBar(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isOnline =
        context.watch<ConnectivityProvider?>()?.isOnline ?? false;
    final bool isDisabled = _isSyncing || !isOnline;

    if (widget._isListTile) {
      return ListTile(
        leading: _buildIcon(isDisabled),
        title: Text(_getTooltip(context)),
        subtitle:
            !isOnline
                ? Text(
                  S.of(context).generalOffline,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
                : null,
        onTap: isDisabled ? null : _triggerSync,
        enabled: !isDisabled,
      );
    }

    // Icon button variant
    if (widget.showLabel) {
      return TextButton.icon(
        onPressed: isDisabled ? null : _triggerSync,
        icon: _buildIcon(isDisabled),
        label: Text(_getEntityName(context)),
      );
    }

    return IconButton(
      onPressed: isDisabled ? null : _triggerSync,
      icon: _buildIcon(isDisabled),
      tooltip: _getTooltip(context),
    );
  }

  /// Build the sync icon with animation when syncing.
  Widget _buildIcon(bool isDisabled) {
    if (_isSyncing) {
      return RotationTransition(
        turns: _animationController,
        child: const Icon(Icons.sync),
      );
    }

    return Icon(
      Icons.sync,
      color: isDisabled ? Theme.of(context).disabledColor : null,
    );
  }
}
