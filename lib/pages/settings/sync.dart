import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
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
              await syncStatus.sync();
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
                        await syncStatus.syncAll();
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
              if (isPaused && !isSyncing) ...[
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
}
