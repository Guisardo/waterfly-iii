import 'dart:async';
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
  Map<String, SyncMetadata> _entityMetadata = <String, SyncMetadata>{};
  String? _currentSyncingEntity;
  StreamSubscription<SyncProgress>? _progressSubscription;
  SyncProgress? _currentProgress;
  Isar? _isar; // Injected Isar for testing, falls back to AppDatabase.instance

  // List of all entity types that are synced
  static const List<String> entityTypes = <String>[
    'transactions',
    'accounts',
    'categories',
    'tags',
    'bills',
    'budgets',
    'currencies',
    'piggy_banks',
  ];

  bool get isDownloadSyncing => _syncService?.isSyncing ?? false;
  bool get isUploading => _uploadService?.isUploading ?? false;
  bool get isSyncing => isDownloadSyncing || isUploading;
  SyncMetadata? get downloadMetadata => _downloadMetadata;
  SyncMetadata? get uploadMetadata => _uploadMetadata;
  SyncMetadata? get authMetadata => _authMetadata;
  Map<String, SyncMetadata> get entityMetadata => _entityMetadata;
  String? get currentSyncingEntity => _currentSyncingEntity;
  SyncProgress? get currentProgress => _currentProgress;

  bool get hasDownloadError => _downloadMetadata?.syncPaused ?? false;
  bool get hasUploadError => _uploadMetadata?.syncPaused ?? false;
  bool get hasError => hasDownloadError || hasUploadError;
  String? get downloadError => _downloadMetadata?.lastError;
  String? get uploadError => _uploadMetadata?.lastError;

  /// Initialize sync services (call once when app starts)
  /// [isar] - Optional Isar instance for testing, falls back to AppDatabase.instance
  Future<void> initialize({
    required FireflyService fireflyService,
    required ConnectivityService connectivityService,
    required SettingsProvider settingsProvider,
    Isar? isar,
  }) async {
    if (_syncService != null && _uploadService != null) {
      return; // Already initialized
    }

    try {
      final Isar isarInstance = isar ?? await AppDatabase.instance;
      _isar = isarInstance; // Store for refreshMetadata
      final SyncNotifications notifications = SyncNotifications();
      notifications.setSettingsProvider(settingsProvider);

      _syncService = SyncService(
        isar: isarInstance,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        settingsProvider: settingsProvider,
      );

      _uploadService = UploadService(
        isar: isarInstance,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        settingsProvider: settingsProvider,
      );

      // Listen to sync service changes
      _syncService!.addListener(_onSyncStatusChanged);
      _uploadService!.addListener(_onSyncStatusChanged);

      // Subscribe to progress stream when it becomes available
      _subscribeToProgressStream();

      // Load initial metadata
      await refreshMetadata();
    } catch (e) {
      // Ignore initialization errors
    }
  }

  void _onSyncStatusChanged() {
    notifyListeners();
    // Re-subscribe to progress stream if sync started
    _subscribeToProgressStream();
  }

  void _subscribeToProgressStream() {
    // Cancel existing subscription if any
    _progressSubscription?.cancel();
    _progressSubscription = null;

    // Listen to sync progress stream to track current syncing entity
    final Stream<SyncProgress>? progressStream = _syncService?.progressStream;
    if (progressStream != null) {
      _progressSubscription = progressStream.listen((SyncProgress progress) {
        _currentSyncingEntity = progress.entityType;
        _currentProgress = progress;
        notifyListeners();
      });
    }
  }

  /// Refresh sync metadata from database
  Future<void> refreshMetadata() async {
    try {
      final Isar isar = _isar ?? await AppDatabase.instance;
      final SyncMetadata? download =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('download')
              .findFirst();
      final SyncMetadata? upload =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('upload')
              .findFirst();
      final SyncMetadata? auth =
          await isar.syncMetadatas
              .filter()
              .entityTypeEqualTo('auth')
              .findFirst();

      _downloadMetadata = download;
      _uploadMetadata = upload;
      _authMetadata = auth;

      // Load metadata for all entity types
      final Map<String, SyncMetadata> entityMetadata = <String, SyncMetadata>{};
      for (final String entityType in entityTypes) {
        try {
          final SyncMetadata? metadata =
              await isar.syncMetadatas
                  .filter()
                  .entityTypeEqualTo(entityType)
                  .findFirst();
          if (metadata != null) {
            entityMetadata[entityType] = metadata;
          }
        } catch (e) {
          // Ignore errors for individual entity types
        }
      }
      _entityMetadata = entityMetadata;

      // Clear current syncing entity and progress if sync is not active
      if (!isDownloadSyncing) {
        _currentSyncingEntity = null;
        _currentProgress = null;
      }

      notifyListeners();
    } catch (e) {
      // Ignore errors, metadata will be null
    }
  }

  /// Trigger download sync
  /// [forceRetry] - If true, bypasses pause state and clears errors (for manual sync)
  Future<void> sync({bool forceRetry = false}) async {
    if (_syncService == null) {
      return;
    }
    await _syncService!.sync(forceRetry: forceRetry);
    // Small delay to ensure database transactions are committed
    await Future<void>.delayed(const Duration(milliseconds: 100));
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
  /// [forceRetry] - If true, bypasses pause state and clears errors (for manual sync)
  Future<void> syncAll({bool forceRetry = false}) async {
    await sync(forceRetry: forceRetry);
    await upload();
    // Small delay to ensure database transactions are committed
    await Future<void>.delayed(const Duration(milliseconds: 100));
    // Ensure metadata is refreshed after both syncs complete
    await refreshMetadata();
  }

  @override
  void dispose() {
    _progressSubscription?.cancel();
    _syncService?.removeListener(_onSyncStatusChanged);
    _uploadService?.removeListener(_onSyncStatusChanged);
    super.dispose();
  }
}
