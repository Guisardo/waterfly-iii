/// Uploading pending changes must not wait for the download sync: a download
/// that never finishes used to leave created transactions unsent forever.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/services/sync/sync_status_provider.dart';
import 'package:waterflyiii/services/sync/upload_service.dart';
import 'package:waterflyiii/settings.dart';
import '../../helpers/test_database.dart';

class _OnlineConnectivityService extends ChangeNotifier
    implements ConnectivityService {
  @override
  NetworkType get currentNetworkType => NetworkType.wifi;

  @override
  bool get isOnline => true;

  @override
  bool get isWifi => true;

  @override
  bool get isMobile => false;
}

class _StubSyncService extends SyncService {
  _StubSyncService({
    required super.isar,
    required super.fireflyService,
    required super.connectivityService,
    required super.notifications,
    required this.onSync,
  });

  final Future<void> Function() onSync;
  int insightRefreshes = 0;

  @override
  Future<void> sync({
    bool forceFullSync = false,
    String? entityType,
    bool forceRetry = false,
  }) => onSync();

  @override
  Future<void> refreshInsights({int maxStale = 0}) async {
    insightRefreshes++;
  }
}

class _StubUploadService extends UploadService {
  _StubUploadService({
    required super.isar,
    required super.fireflyService,
    required super.connectivityService,
    required super.notifications,
    this.onUpload,
  });

  final Future<void> Function()? onUpload;
  int uploads = 0;

  @override
  Future<void> uploadPendingChanges({bool forceRetry = false}) async {
    uploads++;
    await onUpload?.call();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncStatusProvider.syncAll', () {
    late Isar isar;
    late SyncStatusProvider provider;
    late FireflyService fireflyService;
    late ConnectivityService connectivityService;
    late SyncNotifications notifications;

    setUpAll(() async {
      isar = await TestDatabase.instance;
    });

    setUp(() async {
      await TestDatabase.clear();
      fireflyService = FireflyService();
      connectivityService = _OnlineConnectivityService();
      notifications = SyncNotifications();
      provider = SyncStatusProvider();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    Future<void> initializeWith({
      required Future<void> Function() onSync,
      Future<void> Function()? onUpload,
      required void Function(_StubSyncService, _StubUploadService) expose,
    }) async {
      final _StubSyncService syncService = _StubSyncService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        onSync: onSync,
      );
      final _StubUploadService uploadService = _StubUploadService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        notifications: notifications,
        onUpload: onUpload,
      );
      expose(syncService, uploadService);
      await provider.initialize(
        fireflyService: fireflyService,
        connectivityService: connectivityService,
        settingsProvider: SettingsProvider(),
        isar: isar,
        syncService: syncService,
        uploadService: uploadService,
      );
    }

    test('uploads while the download sync is still running', () async {
      final Completer<void> downloadNeverEnds = Completer<void>();
      late _StubUploadService uploadService;
      await initializeWith(
        onSync: () => downloadNeverEnds.future,
        expose: (_, _StubUploadService upload) => uploadService = upload,
      );

      unawaited(provider.syncAll());
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(uploadService.uploads, 1);
      downloadNeverEnds.complete();
    });

    test(
      'still uploads when the download sync fails, then reports it',
      () async {
        late _StubUploadService uploadService;
        await initializeWith(
          onSync: () async => throw StateError('download exploded'),
          expose: (_, _StubUploadService upload) => uploadService = upload,
        );

        await expectLater(
          provider.syncAll(),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              'download exploded',
            ),
          ),
        );
        expect(uploadService.uploads, 1);
      },
    );

    test('still downloads when the upload fails, then reports it', () async {
      bool downloaded = false;
      await initializeWith(
        onSync: () async => downloaded = true,
        onUpload: () async => throw StateError('upload exploded'),
        expose: (_, _) {},
      );

      await expectLater(
        provider.syncAll(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            'upload exploded',
          ),
        ),
      );
      expect(downloaded, isTrue);
    });

    test('lists insights among the synced entities', () {
      expect(SyncStatusProvider.entityTypes, contains('insights'));
    });

    test('counts the insights still waiting to refresh', () async {
      await initializeWith(onSync: () async {}, expose: (_, _) {});
      await isar.writeTxn(() async {
        for (int month = 1; month <= 3; month++) {
          await isar.insights.put(
            Insights()
              ..insightType = 'expense'
              ..insightSubtype = 'total'
              ..startDate = DateTime.utc(2020, month, 1)
              ..endDate = DateTime.utc(2020, month, 28)
              ..data = '[]'
              ..cachedAt = DateTime.utc(2020, 1, 1)
              ..stale = true,
          );
        }
      });

      await provider.refreshMetadata();

      expect(provider.staleInsightsCount, 3);
    });

    test('refreshes insights in the background after the download', () async {
      late _StubSyncService syncService;
      await initializeWith(
        onSync: () async {},
        expose: (_StubSyncService sync, _) => syncService = sync,
      );

      await provider.syncAll();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(syncService.insightRefreshes, 1);
    });
  });
}
