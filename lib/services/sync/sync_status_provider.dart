import 'package:flutter/foundation.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/services/sync/upload_service.dart';
import 'package:waterflyiii/settings.dart';

/// Global provider for sync status that can be watched from anywhere in the app
class SyncStatusProvider extends ChangeNotifier {
  SyncService? _syncService;
  UploadService? _uploadService;
  SyncMetadata? _downloadMetadata;
  SyncMetadata? _uploadMetadata;
  SyncMetadata? _authMetadata;

  bool get isDownloadSyncing => _syncService?.isSyncing ?? false;
  bool get isUploading => _uploadService?.isUploading ?? false;
  bool get isSyncing => isDownloadSyncing || isUploading;
  SyncMetadata? get downloadMetadata => _downloadMetadata;
  SyncMetadata? get uploadMetadata => _uploadMetadata;
  SyncMetadata? get authMetadata => _authMetadata;

  bool get hasDownloadError => _downloadMetadata?.syncPaused ?? false;
  bool get hasUploadError => _uploadMetadata?.syncPaused ?? false;
  bool get hasError => hasDownloadError || hasUploadError;
  String? get downloadError => _downloadMetadata?.lastError;
  String? get uploadError => _uploadMetadata?.lastError;

  /// Initialize sync services (call once when app starts)
  Future<void> initialize({
    required FireflyService fireflyService,
    required ConnectivityService connectivityService,
    required SettingsProvider settingsProvider,
  }) async {
    if (_syncService != null && _uploadService != null) {
      return; // Already initialized
    }

    try {
      final Isar isar = await AppDatabase.instance;
      final SyncNotifications notifications = SyncNotifications();
      notifications.setSettingsProvider(settingsProvider);

      _syncService = SyncService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        settingsProvider: settingsProvider,
      );

      _uploadService = UploadService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        settingsProvider: settingsProvider,
      );

      // Listen to sync service changes
      _syncService!.addListener(_onSyncStatusChanged);
      _uploadService!.addListener(_onSyncStatusChanged);

      // Load initial metadata
      await refreshMetadata();
    } catch (e) {
      // Ignore initialization errors
    }
  }

  void _onSyncStatusChanged() {
    notifyListeners();
  }

  /// Refresh sync metadata from database
  Future<void> refreshMetadata() async {
    try {
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

      _downloadMetadata = download;
      _uploadMetadata = upload;
      _authMetadata = auth;
      notifyListeners();
    } catch (e) {
      // Ignore errors, metadata will be null
    }
  }

  /// Trigger download sync
  Future<void> sync() async {
    if (_syncService == null) {
      return;
    }
    await _syncService!.sync();
    await refreshMetadata();
  }

  /// Trigger upload sync
  Future<void> upload() async {
    if (_uploadService == null) {
      return;
    }
    await _uploadService!.uploadPendingChanges(forceRetry: true);
    await refreshMetadata();
  }

  /// Trigger both download and upload sync
  Future<void> syncAll() async {
    await sync();
    await upload();
  }

  @override
  void dispose() {
    _syncService?.removeListener(_onSyncStatusChanged);
    _uploadService?.removeListener(_onSyncStatusChanged);
    super.dispose();
  }
}

