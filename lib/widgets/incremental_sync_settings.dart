import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';

final Logger _log = Logger('IncrementalSyncSettings');

/// Get localized label for sync window.
String _getSyncWindowLabel(BuildContext context, SyncWindow window) {
  final S localizations = S.of(context);
  return localizations.incrementalSyncWindowDays(window.days);
}

/// Get localized label for cache TTL.
String _getCacheTtlLabel(BuildContext context, CacheTtl ttl) {
  final S localizations = S.of(context);
  return localizations.incrementalSyncCacheHours(ttl.hours);
}

/// A comprehensive settings section for configuring incremental sync behavior.
///
/// This widget provides a complete UI for managing incremental sync settings:
/// - Enable/disable incremental sync
/// - Sync window configuration (7-90 days)
/// - Cache TTL for Tier 2 entities (1-48 hours)
/// - Sync timestamps display
/// - Status indicators
///
/// ## Features
///
/// **Incremental Sync Toggle:**
/// When enabled, syncs fetch only changed data since last sync.
/// When disabled, each sync fetches all data (full sync).
///
/// **Sync Window:**
/// Controls how far back to look for changes during incremental sync.
/// Shorter windows are more efficient but may miss older changes.
///
/// **Cache TTL:**
/// Controls how long Tier 2 entities (categories, bills, piggy banks)
/// are cached before re-fetching. These entities change infrequently.
///
/// ## Example Usage
///
/// ```dart
/// Scaffold(
///   body: ListView(
///     children: [
///       // Other settings sections...
///       IncrementalSyncSettingsSection(
///         onForceFullSync: () async {
///           // Trigger full sync
///         },
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ## Architecture
///
/// Uses [OfflineSettingsProvider] for state management and persistence.
/// All changes are automatically saved to SharedPreferences.
class IncrementalSyncSettingsSection extends StatefulWidget {
  const IncrementalSyncSettingsSection({
    super.key,
    this.onForceFullSync,
    this.onForceIncrementalSync,
    this.showAdvancedSettings = true,
  });

  /// Callback when "Force Full Sync" is pressed.
  final VoidCallback? onForceFullSync;

  /// Callback when "Force Incremental Sync" is pressed.
  final VoidCallback? onForceIncrementalSync;

  /// Whether to show advanced settings (cache TTL, reset stats).
  final bool showAdvancedSettings;

  @override
  State<IncrementalSyncSettingsSection> createState() =>
      _IncrementalSyncSettingsSectionState();
}

class _IncrementalSyncSettingsSectionState
    extends State<IncrementalSyncSettingsSection> {
  bool _isResettingStats = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSettingsProvider>(
      builder: (
        BuildContext context,
        OfflineSettingsProvider settings,
        Widget? child,
      ) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildIncrementalSyncToggle(context, settings),
                _buildSyncWindowSelector(context, settings),
                if (widget.showAdvancedSettings)
                  _buildCacheTtlSelector(context, settings),
                const Divider(height: 32),
                _buildSyncTimestamps(context, settings),
                if (settings.needsFullSync) _buildFullSyncWarning(context),
                const SizedBox(height: 16),
                _buildActionButtons(context, settings),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build the section header with icon and title.
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.sync_alt,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                S.of(context).incrementalSyncTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                S.of(context).incrementalSyncDescription,
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

  /// Build incremental sync enable/disable toggle.
  Widget _buildIncrementalSyncToggle(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return SwitchListTile(
      title: Text(S.of(context).incrementalSyncEnable),
      subtitle: Text(
        settings.incrementalSyncEnabled
            ? S.of(context).incrementalSyncEnabledDesc
            : S.of(context).incrementalSyncDisabledDesc,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      value: settings.incrementalSyncEnabled,
      onChanged: (bool value) async {
        try {
          await settings.setIncrementalSyncEnabled(value);
          _log.info('Incremental sync ${value ? "enabled" : "disabled"}');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  value
                      ? S.of(context).incrementalSyncEnabled
                      : S.of(context).incrementalSyncDisabled,
                ),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          _log.severe('Failed to toggle incremental sync', e);
          if (mounted) {
            _showError(context, S.of(context).incrementalSyncFailedToUpdate);
          }
        }
      },
      secondary: Icon(
        settings.incrementalSyncEnabled ? Icons.flash_on : Icons.flash_off,
        color: settings.incrementalSyncEnabled ? Colors.amber : Colors.grey,
      ),
    );
  }

  /// Build sync window selector dropdown.
  Widget _buildSyncWindowSelector(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.date_range),
      title: Text(S.of(context).incrementalSyncWindow),
      subtitle: Text(
        S.of(context).incrementalSyncWindowDesc,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: DropdownButton<SyncWindow>(
        value: settings.syncWindow,
        underline: const SizedBox(),
        items:
            SyncWindow.values.map((SyncWindow window) {
              return DropdownMenuItem<SyncWindow>(
                value: window,
                child: Text(_getSyncWindowLabel(context, window)),
              );
            }).toList(),
        onChanged:
            settings.incrementalSyncEnabled
                ? (SyncWindow? window) async {
                  if (window == null) return;
                  try {
                    await settings.setSyncWindow(window);
                    _log.info('Sync window set to ${window.label}');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            S
                                .of(context)
                                .incrementalSyncWindowSet(
                                  _getSyncWindowLabel(context, window),
                                ),
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    _log.severe('Failed to set sync window', e);
                    if (mounted) {
                      _showError(
                        context,
                        S.of(context).incrementalSyncWindowFailed,
                      );
                    }
                  }
                }
                : null,
      ),
      enabled: settings.incrementalSyncEnabled,
    );
  }

  /// Build cache TTL selector dropdown (advanced setting).
  Widget _buildCacheTtlSelector(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return ExpansionTile(
      leading: const Icon(Icons.timer),
      title: Text(S.of(context).incrementalSyncCacheDuration),
      subtitle: Text(
        S
            .of(context)
            .incrementalSyncCacheCurrent(
              _getCacheTtlLabel(context, settings.cacheTtl),
            ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      children: <Widget>[
        Text(
          S.of(context).incrementalSyncCacheDurationDesc,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              CacheTtl.values.map((CacheTtl ttl) {
                final bool isSelected = settings.cacheTtl == ttl;
                return ChoiceChip(
                  label: Text(_getCacheTtlLabel(context, ttl)),
                  selected: isSelected,
                  onSelected:
                      settings.incrementalSyncEnabled
                          ? (bool selected) async {
                            if (!selected) return;
                            try {
                              await settings.setCacheTtl(ttl);
                              _log.info('Cache TTL set to ${ttl.label}');
                            } catch (e) {
                              _log.severe('Failed to set cache TTL', e);
                              if (mounted) {
                                _showError(
                                  context,
                                  S
                                      .of(context)
                                      .incrementalSyncCacheDurationFailed,
                                );
                              }
                            }
                          }
                          : null,
                );
              }).toList(),
        ),
      ],
    );
  }

  /// Build sync timestamps display.
  Widget _buildSyncTimestamps(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          _buildTimestampRow(
            context,
            icon: Icons.sync,
            label: S.of(context).incrementalSyncLastIncremental,
            timestamp: settings.lastIncrementalSyncTime,
            daysSince: settings.daysSinceLastIncrementalSync,
          ),
          const SizedBox(height: 8),
          _buildTimestampRow(
            context,
            icon: Icons.sync_alt,
            label: S.of(context).incrementalSyncLastFull,
            timestamp: settings.lastFullSyncTime,
            daysSince: settings.daysSinceLastFullSync,
            isWarning: settings.needsFullSync,
          ),
        ],
      ),
    );
  }

  /// Build a single timestamp row.
  Widget _buildTimestampRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required DateTime? timestamp,
    required int daysSince,
    bool isWarning = false,
  }) {
    final Color iconColor =
        isWarning ? Colors.orange : Theme.of(context).colorScheme.primary;

    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                timestamp != null
                    ? _formatTimestamp(timestamp, daysSince)
                    : S.of(context).incrementalSyncNever,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isWarning
                          ? Colors.orange
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (daysSince >= 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getDaysSinceColor(daysSince, isWarning).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              daysSince == 0
                  ? S.of(context).incrementalSyncToday
                  : S.of(context).incrementalSyncDaysAgo(daysSince),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _getDaysSinceColor(daysSince, isWarning),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  /// Format timestamp for display.
  String _formatTimestamp(DateTime timestamp, int daysSince) {
    final DateFormat format = DateFormat('MMM d, y HH:mm');
    return format.format(timestamp.toLocal());
  }

  /// Get color based on days since sync.
  Color _getDaysSinceColor(int days, bool isWarning) {
    if (isWarning || days > 7) return Colors.orange;
    if (days > 3) return Colors.amber;
    return Colors.green;
  }

  /// Build warning banner when full sync is needed.
  Widget _buildFullSyncWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.warning_amber, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  S.of(context).incrementalSyncFullSyncRecommended,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                Text(
                  S.of(context).incrementalSyncFullSyncRecommendedDesc,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.orange[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons (force sync, reset stats).
  Widget _buildActionButtons(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed:
                    widget.onForceIncrementalSync != null &&
                            settings.incrementalSyncEnabled
                        ? widget.onForceIncrementalSync
                        : null,
                icon: const Icon(Icons.sync),
                label: Text(S.of(context).incrementalSyncIncrementalButton),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onForceFullSync,
                icon: const Icon(Icons.sync_alt),
                label: Text(S.of(context).incrementalSyncFullButton),
                style:
                    settings.needsFullSync
                        ? OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          foregroundColor: Colors.orange,
                        )
                        : null,
              ),
            ),
          ],
        ),
        if (widget.showAdvancedSettings) ...<Widget>[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed:
                _isResettingStats
                    ? null
                    : () => _confirmResetStatistics(context, settings),
            icon:
                _isResettingStats
                    ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Icon(Icons.restart_alt, size: 18),
            label: Text(
              _isResettingStats
                  ? S.of(context).incrementalSyncResetting
                  : S.of(context).incrementalSyncResetStatistics,
            ),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }

  /// Confirm and reset incremental sync statistics.
  Future<void> _confirmResetStatistics(
    BuildContext context,
    OfflineSettingsProvider settings,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext context) => AlertDialog(
            title: Text(S.of(context).incrementalSyncResetStatisticsTitle),
            content: Text(S.of(context).incrementalSyncResetStatisticsMessage),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  MaterialLocalizations.of(context).cancelButtonLabel,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(S.of(context).incrementalSyncResetStatistics),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isResettingStats = true);

    try {
      await settings.resetIncrementalSyncStatistics();
      _log.info('Incremental sync statistics reset');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).incrementalSyncResetStatisticsSuccess),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _log.severe('Failed to reset statistics', e);
      if (mounted) {
        _showError(context, S.of(context).incrementalSyncResetStatisticsFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isResettingStats = false);
      }
    }
  }

  /// Show error snackbar.
  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// A compact version of the incremental sync settings for embedding
/// in other settings screens or dialogs.
///
/// Shows only the essential toggle and sync window selector.
class IncrementalSyncSettingsCompact extends StatelessWidget {
  const IncrementalSyncSettingsCompact({super.key, this.showHeader = true});

  /// Whether to show the section header.
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Consumer<OfflineSettingsProvider>(
      builder: (
        BuildContext context,
        OfflineSettingsProvider settings,
        Widget? child,
      ) {
        final String syncWindowLabel = _getSyncWindowLabel(
          context,
          settings.syncWindow,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (showHeader) ...<Widget>[
              Text(
                S.of(context).incrementalSyncTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            SwitchListTile(
              title: Text(S.of(context).incrementalSyncEnable),
              subtitle: Text(
                settings.incrementalSyncEnabled
                    ? '$syncWindowLabel ${S.of(context).incrementalSyncWindowWord}'
                    : S.of(context).incrementalSyncFullSyncEnabled,
              ),
              value: settings.incrementalSyncEnabled,
              onChanged: (bool value) async {
                await settings.setIncrementalSyncEnabled(value);
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
            ),
            if (settings.incrementalSyncEnabled)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.date_range, size: 16),
                    const SizedBox(width: 8),
                    Text(S.of(context).incrementalSyncWindowLabel),
                    DropdownButton<SyncWindow>(
                      value: settings.syncWindow,
                      underline: const SizedBox(),
                      isDense: true,
                      items:
                          SyncWindow.values.map((SyncWindow window) {
                            return DropdownMenuItem<SyncWindow>(
                              value: window,
                              child: Text(_getSyncWindowLabel(context, window)),
                            );
                          }).toList(),
                      onChanged: (SyncWindow? window) async {
                        if (window != null) {
                          await settings.setSyncWindow(window);
                        }
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
