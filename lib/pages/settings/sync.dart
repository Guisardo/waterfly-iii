import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/services/sync/sync_status_provider.dart';
import 'package:waterflyiii/settings.dart';

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Refresh metadata every 2 seconds when page is visible
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        context.read<SyncStatusProvider>().refreshMetadata();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final SyncStatusProvider syncStatus = context.watch<SyncStatusProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(S.of(context).syncSettingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: <Widget>[
          // Mobile data toggle
          SwitchListTile(
            title: Text(S.of(context).syncSettingsMobileDataTitle),
            subtitle: Text(S.of(context).syncSettingsMobileDataSubtitle),
            value: settings.syncUseMobileData,
            onChanged: (bool value) {
              settings.syncUseMobileData = value;
            },
          ),
          const Divider(),

          // Credential status
          ListTile(
            title: Text(S.of(context).syncSettingsCredentialsTitle),
            subtitle: Text(
              syncStatus.authMetadata?.credentialsInvalid ?? false
                  ? S.of(context).syncSettingsCredentialsInvalid
                  : syncStatus.authMetadata?.credentialsValidated ?? false
                  ? S.of(context).syncSettingsCredentialsValidated
                  : S.of(context).syncSettingsCredentialsNotValidated,
            ),
            trailing:
                syncStatus.authMetadata?.credentialsInvalid ?? false
                    ? ElevatedButton(
                      onPressed: () {
                        // Navigate to login or show credential update dialog
                        Navigator.pushNamed(context, '/login');
                      },
                      child: Text(S.of(context).syncSettingsReenterButton),
                    )
                    : null,
          ),
          const Divider(),

          // Download sync status
          _buildSyncStatusSection(
            context,
            S.of(context).syncSettingsDownloadSync,
            syncStatus.downloadMetadata,
            syncStatus.isDownloadSyncing,
            () async {
              await syncStatus.sync(forceRetry: true);
            },
          ),

          // Upload sync status
          _buildSyncStatusSection(
            context,
            S.of(context).syncSettingsUploadSync,
            syncStatus.uploadMetadata,
            syncStatus.isUploading,
            () async {
              await syncStatus.upload();
            },
          ),

          // Entity sync status section
          const Divider(),
          _buildEntityStatusSection(context, syncStatus),

          // Manual sync buttons
          const Divider(),
          ListTile(
            title: Text(S.of(context).syncSettingsManualSyncTitle),
            subtitle: Text(S.of(context).syncSettingsManualSyncSubtitle),
            trailing:
                syncStatus.isSyncing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : ElevatedButton(
                      onPressed: () async {
                        await syncStatus.syncAll(forceRetry: true);
                        // Force a refresh to ensure UI updates
                        if (mounted) {
                          await syncStatus.refreshMetadata();
                          setState(() {});
                        }
                      },
                      child: Text(S.of(context).syncSettingsSyncNowButton),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusSection(
    BuildContext context,
    String title,
    dynamic metadata,
    bool isSyncing,
    VoidCallback onResume,
  ) {
    final bool isPaused = metadata?.syncPaused ?? false;
    final int retryCount = metadata?.retryCount ?? 0;
    final DateTime? nextRetryAt = metadata?.nextRetryAt;
    final String? lastError = metadata?.lastError;
    final DateTime? lastSync =
        metadata?.lastDownloadSync ?? metadata?.lastUploadSync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          title: Row(
            children: <Widget>[
              Expanded(child: Text(title)),
              if (isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (isSyncing)
                Text(
                  S.of(context).syncSettingsStatusSyncing,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (lastSync != null && !isSyncing)
                Text(
                  S
                      .of(context)
                      .syncSettingsLastSync(
                        DateFormat.yMd().add_Hms().format(lastSync),
                      ),
                ),
              if (isPaused && !isSyncing) ...<Widget>[
                Text(
                  S.of(context).syncSettingsStatusPaused,
                  style: const TextStyle(color: Colors.orange),
                ),
                if (retryCount > 0)
                  Text(S.of(context).syncSettingsRetryCount(retryCount)),
                if (nextRetryAt != null)
                  Text(
                    S
                        .of(context)
                        .syncSettingsNextRetry(
                          DateFormat.yMd().add_Hms().format(nextRetryAt),
                        ),
                  ),
              ],
              // Show errors even when not paused if they exist
              if (lastError != null && !isSyncing)
                Text(
                  S.of(context).syncSettingsError(lastError),
                  style: const TextStyle(color: Colors.red),
                ),
              if (!isPaused && !isSyncing && lastError == null)
                Text(S.of(context).syncSettingsStatusActive),
            ],
          ),
          trailing:
              isPaused && !isSyncing
                  ? ElevatedButton(
                    onPressed: onResume,
                    child: Text(S.of(context).syncSettingsResumeButton),
                  )
                  : null,
        ),
        const Divider(),
      ],
    );
  }

  Widget _buildEntityStatusSection(
    BuildContext context,
    SyncStatusProvider syncStatus,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            S.of(context).syncSettingsEntityStatusTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        ...SyncStatusProvider.entityTypes.map<Widget>((String entityType) {
          return _buildEntityStatusTile(context, syncStatus, entityType);
        }),
      ],
    );
  }

  Widget _buildEntityStatusTile(
    BuildContext context,
    SyncStatusProvider syncStatus,
    String entityType,
  ) {
    final SyncMetadata? metadata = syncStatus.entityMetadata[entityType];
    final bool isSyncing = syncStatus.currentSyncingEntity == entityType;
    final DateTime? lastSync = metadata?.lastDownloadSync;
    final bool isPaused = metadata?.syncPaused ?? false;
    final String? lastError = metadata?.lastError;
    final DateTime? nextRetryAt = metadata?.nextRetryAt;
    final SyncProgress? progress =
        isSyncing && syncStatus.currentProgress?.entityType == entityType
            ? syncStatus.currentProgress
            : null;

    // Determine status
    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (isSyncing) {
      statusText = S.of(context).syncSettingsEntityStatusSyncing;
      statusIcon = Icons.sync;
      statusColor = Theme.of(context).colorScheme.primary;
    } else if (isPaused &&
        (nextRetryAt == null || nextRetryAt.isAfter(DateTime.now().toUtc()))) {
      statusText = S.of(context).syncSettingsEntityStatusPaused;
      statusIcon = Icons.pause_circle_outline;
      statusColor = Colors.orange;
    } else if (lastError != null) {
      // Show error status if there's an error, even if never synced
      statusText = S.of(context).syncSettingsEntityStatusError;
      statusIcon = Icons.error_outline;
      statusColor = Colors.red;
    } else if (lastSync != null) {
      statusText = S.of(context).syncSettingsEntityStatusSuccess;
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.green;
    } else {
      statusText = S.of(context).syncSettingsEntityStatusNeverSynced;
      statusIcon = Icons.help_outline;
      statusColor = Colors.grey;
    }

    // Get localized entity name
    String entityName;
    switch (entityType) {
      case 'transactions':
        entityName = S.of(context).syncSettingsEntityTransactions;
        break;
      case 'accounts':
        entityName = S.of(context).syncSettingsEntityAccounts;
        break;
      case 'categories':
        entityName = S.of(context).syncSettingsEntityCategories;
        break;
      case 'tags':
        entityName = S.of(context).syncSettingsEntityTags;
        break;
      case 'bills':
        entityName = S.of(context).syncSettingsEntityBills;
        break;
      case 'budgets':
        entityName = S.of(context).syncSettingsEntityBudgets;
        break;
      case 'currencies':
        entityName = S.of(context).syncSettingsEntityCurrencies;
        break;
      case 'piggy_banks':
        entityName = S.of(context).syncSettingsEntityPiggyBanks;
        break;
      default:
        entityName = entityType;
    }

    return ListTile(
      leading:
          isSyncing
              ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              )
              : Icon(statusIcon, color: statusColor),
      title: Text(entityName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(statusText, style: TextStyle(color: statusColor)),
          if (progress != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (progress.total > 0)
                    Text(
                      S
                          .of(context)
                          .syncSettingsEntityProgress(
                            progress.current,
                            progress.total,
                          ),
                      style: TextStyle(color: statusColor, fontSize: 12),
                    )
                  else
                    Text(
                      S.of(context).syncSettingsEntityStatusSyncing,
                      style: TextStyle(color: statusColor, fontSize: 12),
                    ),
                  if (progress.total > 0) ...<Widget>[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress.current / progress.total,
                      backgroundColor: statusColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 4,
                    ),
                  ],
                ],
              ),
            ),
          if (progress?.message != null && progress!.message!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                progress.message!,
                style: TextStyle(color: statusColor, fontSize: 12),
              ),
            ),
          if (lastSync != null && !isSyncing)
            Text(
              S
                  .of(context)
                  .syncSettingsLastSync(
                    DateFormat.yMd().add_Hms().format(lastSync),
                  ),
            ),
          if (lastError != null && !isSyncing)
            Text(
              S.of(context).syncSettingsError(lastError),
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          if (isPaused && nextRetryAt != null && !isSyncing)
            Text(
              S
                  .of(context)
                  .syncSettingsNextRetry(
                    DateFormat.yMd().add_Hms().format(nextRetryAt),
                  ),
              style: const TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
