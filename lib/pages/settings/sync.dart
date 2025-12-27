import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/auth.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/services/sync/upload_service.dart';
import 'package:waterflyiii/settings.dart';

class SyncSettingsPage extends StatefulWidget {
  const SyncSettingsPage({super.key});

  @override
  State<SyncSettingsPage> createState() => _SyncSettingsPageState();
}

class _SyncSettingsPageState extends State<SyncSettingsPage> {
  SyncMetadata? _downloadMetadata;
  SyncMetadata? _uploadMetadata;
  SyncMetadata? _authMetadata;

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final Isar isar = await AppDatabase.instance;
    final SyncMetadata? download = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo('download')
        .findFirst();
    final SyncMetadata? upload = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo('upload')
        .findFirst();
    final SyncMetadata? auth = await isar.syncMetadatas
        .filter()
        .entityTypeEqualTo('auth')
        .findFirst();

    if (mounted) {
      setState(() {
        _downloadMetadata = download;
        _uploadMetadata = upload;
        _authMetadata = auth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final SettingsProvider settings = context.watch<SettingsProvider>();
    final FireflyService fireflyService = context.watch<FireflyService>();
    final ConnectivityService connectivityService =
        context.watch<ConnectivityService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).syncSettingsTitle),
      ),
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
              _authMetadata?.credentialsInvalid ?? false
                  ? S.of(context).syncSettingsCredentialsInvalid
                  : _authMetadata?.credentialsValidated ?? false
                      ? S.of(context).syncSettingsCredentialsValidated
                      : S.of(context).syncSettingsCredentialsNotValidated,
            ),
            trailing: _authMetadata?.credentialsInvalid ?? false
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
            _downloadMetadata,
            () async {
              final Isar isar = await AppDatabase.instance;
              final SyncService syncService = SyncService(
                isar: isar,
                fireflyService: fireflyService,
                connectivityService: connectivityService,
                notifications: SyncNotifications(),
                settingsProvider: settings,
              );
              await syncService.sync();
              _loadMetadata();
            },
          ),

          // Upload sync status
          _buildSyncStatusSection(
            context,
            S.of(context).syncSettingsUploadSync,
            _uploadMetadata,
            () async {
              final Isar isar = await AppDatabase.instance;
              final UploadService uploadService = UploadService(
                isar: isar,
                fireflyService: fireflyService,
                connectivityService: connectivityService,
                notifications: SyncNotifications(),
                settingsProvider: settings,
              );
              await uploadService.uploadPendingChanges(forceRetry: true);
              _loadMetadata();
            },
          ),

          // Manual sync buttons
          const Divider(),
          ListTile(
            title: Text(S.of(context).syncSettingsManualSyncTitle),
            subtitle: Text(S.of(context).syncSettingsManualSyncSubtitle),
            trailing: ElevatedButton(
              onPressed: () async {
                final Isar isar = await AppDatabase.instance;
                final SyncService syncService = SyncService(
                  isar: isar,
                  fireflyService: fireflyService,
                  connectivityService: connectivityService,
                  notifications: SyncNotifications(),
                  settingsProvider: settings,
                );
                final UploadService uploadService = UploadService(
                  isar: isar,
                  fireflyService: fireflyService,
                  connectivityService: connectivityService,
                  notifications: SyncNotifications(),
                  settingsProvider: settings,
                );

                await syncService.sync();
                await uploadService.uploadPendingChanges(forceRetry: true);
                _loadMetadata();
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
    SyncMetadata? metadata,
    VoidCallback onResume,
  ) {
    final bool isPaused = metadata?.syncPaused ?? false;
    final int retryCount = metadata?.retryCount ?? 0;
    final DateTime? nextRetryAt = metadata?.nextRetryAt;
    final String? lastError = metadata?.lastError;
    final DateTime? lastSync = metadata?.lastDownloadSync ?? metadata?.lastUploadSync;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          title: Text(title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (lastSync != null)
                Text(S.of(context).syncSettingsLastSync(
                  DateFormat.yMd().add_Hms().format(lastSync),
                )),
              if (isPaused) ...[
                Text(
                  S.of(context).syncSettingsStatusPaused,
                  style: const TextStyle(color: Colors.orange),
                ),
                if (retryCount > 0)
                  Text(S.of(context).syncSettingsRetryCount(retryCount)),
                if (nextRetryAt != null)
                  Text(
                    S.of(context).syncSettingsNextRetry(
                      DateFormat.yMd().add_Hms().format(nextRetryAt),
                    ),
                  ),
                if (lastError != null)
                  Text(
                    S.of(context).syncSettingsError(lastError),
                    style: const TextStyle(color: Colors.red),
                  ),
              ] else
                Text(S.of(context).syncSettingsStatusActive),
            ],
          ),
          trailing: isPaused
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

