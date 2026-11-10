/// Insight refresh must not hold the download sync open: with thousands of
/// stale insights it kept `sync()` running for ~40 minutes, which blocked the
/// upload of pending transactions.
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';
import 'package:waterflyiii/timezonehandler.dart';
import '../../helpers/mock_api.dart';
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

class _NoopSyncNotifications extends SyncNotifications {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showSyncStarted() async {}

  @override
  Future<void> showSyncCompleted() async {}

  @override
  Future<void> showSyncPaused(String error) async {}

  @override
  Future<void> showCredentialError() async {}

  @override
  Future<bool> startKeepAlive() async => false;

  @override
  Future<void> stopKeepAlive() async {}

  @override
  Future<void> showSyncProgress({
    required String entityType,
    required int current,
    required int total,
    String? message,
  }) async {}
}

http.Response _emptyJson(http.BaseRequest request) {
  return http.Response(
    jsonEncode(<dynamic>[]),
    200,
    headers: <String, String>{'content-type': 'application/json'},
  );
}

Insights _staleTotal(DateTime start) {
  return Insights()
    ..insightType = 'expense'
    ..insightSubtype = 'total'
    ..startDate = start
    ..endDate = start.add(const Duration(days: 1))
    ..data = '[]'
    ..cachedAt = DateTime.utc(2020, 1, 1)
    ..stale = true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService insight refresh', () {
    late Isar isar;
    late MockFireflyServiceHelper mockApiHelper;
    late SyncService syncService;
    late List<String> staleWindowRequests;

    const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');

    setUpAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(timezoneChannel, (MethodCall call) async {
            return call.method == 'getLocalTimezone' ? 'UTC' : <String>[];
          });
      tz.initializeTimeZones();
      isar = await TestDatabase.instance;
    });

    setUp(() async {
      await TestDatabase.clear();
      staleWindowRequests = <String>[];

      mockApiHelper = MockFireflyServiceHelper()
        ..setSignedIn(true)
        ..setupSystemInfo()
        ..setupAccounts(accounts: <Map<String, dynamic>>[])
        ..setupCategories(categories: <Map<String, dynamic>>[])
        ..setupTags(tags: <Map<String, dynamic>>[])
        ..setupBills(bills: <Map<String, dynamic>>[])
        ..setupBudgets(budgets: <Map<String, dynamic>>[])
        ..setupCurrencies(currencies: <Map<String, dynamic>>[])
        ..setupPiggyBanks(piggyBanks: <Map<String, dynamic>>[]);
      mockApiHelper.mockHttpClient.setHandler('/v1/transactions', (
        http.BaseRequest request,
      ) {
        return http.Response(
          jsonEncode(
            MockApiResponses.transactionList(
              transactions: <Map<String, dynamic>>[],
            ),
          ),
          200,
          headers: <String, String>{'content-type': 'application/json'},
        );
      });
      for (final String path in <String>[
        '/v1/insight/expense/total',
        '/v1/insight/expense/category',
        '/v1/insight/income/total',
        '/v1/insight/income/category',
      ]) {
        mockApiHelper.mockHttpClient.setHandler(path, (
          http.BaseRequest request,
        ) {
          // Prefetch asks for the current months; the seeded stale insights
          // all start on the 1st of a month in 2020.
          final String start = request.url.queryParameters['start'] ?? '';
          if (start.startsWith('2020-')) {
            staleWindowRequests.add(start);
          }
          return _emptyJson(request);
        });
      }

      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(
          SyncMetadata()
            ..entityType = 'auth'
            ..credentialsValidated = true
            ..credentialsInvalid = false,
        );
      });

      final FireflyService fireflyService = mockApiHelper.getFireflyService()
        ..tzHandler = TimeZoneHandler('UTC');
      syncService = SyncService(
        isar: isar,
        fireflyService: fireflyService,
        connectivityService: _OnlineConnectivityService(),
        notifications: _NoopSyncNotifications(),
      );
    });

    tearDown(() {
      syncService.dispose();
    });

    tearDownAll(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(timezoneChannel, null);
      await TestDatabase.close();
    });

    test('sync does not refresh stale insights', () async {
      await isar.writeTxn(() async {
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
      });

      await syncService.sync();

      final int staleLeft = await isar.insights
          .filter()
          .staleEqualTo(true)
          .count();
      expect(
        staleLeft,
        1,
        reason: 'sync() must leave insights to refreshInsights()',
      );
    });

    test('refreshInsights does nothing when credentials are invalid', () async {
      final SyncMetadata auth = (await isar.syncMetadatas
          .filter()
          .entityTypeEqualTo('auth')
          .findFirst())!;
      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(
          auth
            ..credentialsValidated = false
            ..credentialsInvalid = true,
        );
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
      });

      await syncService.refreshInsights();

      expect(staleWindowRequests, isEmpty);
      expect(await isar.insights.filter().staleEqualTo(true).count(), 1);
    });

    test('refreshInsights does nothing when signed out', () async {
      mockApiHelper.setSignedIn(false);
      await isar.writeTxn(() async {
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
      });

      await syncService.refreshInsights();

      expect(staleWindowRequests, isEmpty);
      expect(await isar.insights.filter().staleEqualTo(true).count(), 1);
    });

    test(
      'refreshInsights records the last refresh in the insights metadata',
      () async {
        await isar.writeTxn(() async {
          await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
        });

        await syncService.refreshInsights();

        final SyncMetadata? metadata = await isar.syncMetadatas
            .filter()
            .entityTypeEqualTo('insights')
            .findFirst();
        expect(metadata?.lastDownloadSync, isNotNull);
        expect(metadata?.lastError, isNull);
      },
    );

    test(
      'refreshInsights records an error when insight requests fail',
      () async {
        mockApiHelper.mockHttpClient.setHandler('/v1/insight/expense/total', (
          http.BaseRequest request,
        ) {
          return http.Response('boom', 500);
        });
        await isar.writeTxn(() async {
          await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
          await isar.insights.put(_staleTotal(DateTime.utc(2020, 4, 1)));
        });

        await syncService.refreshInsights();

        final SyncMetadata? metadata = await isar.syncMetadatas
            .filter()
            .entityTypeEqualTo('insights')
            .findFirst();
        expect(metadata?.lastError, contains('2 of 2'));
      },
    );

    test('refreshInsights reports progress and resets it when done', () async {
      await isar.writeTxn(() async {
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 4, 1)));
      });
      final List<(int, int)> seen = <(int, int)>[];
      syncService.addListener(() {
        seen.add((
          syncService.insightsRefreshCurrent,
          syncService.insightsRefreshTotal,
        ));
      });

      await syncService.refreshInsights();

      expect(seen, contains((1, 2)));
      expect(seen, contains((2, 2)));
      expect(syncService.insightsRefreshCurrent, 0);
      expect(syncService.insightsRefreshTotal, 0);
    });

    test('refreshInsights refreshes the stale insights', () async {
      await isar.writeTxn(() async {
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 3, 1)));
        await isar.insights.put(_staleTotal(DateTime.utc(2020, 4, 1)));
      });

      await syncService.refreshInsights();

      final int staleLeft = await isar.insights
          .filter()
          .staleEqualTo(true)
          .count();
      expect(staleLeft, 0);
    });

    test('refreshInsights refreshes only maxStale, most recent first, and '
        'leaves the rest stale', () async {
      await isar.writeTxn(() async {
        for (int month = 1; month <= 5; month++) {
          await isar.insights.put(_staleTotal(DateTime.utc(2020, month, 1)));
        }
      });

      await syncService.refreshInsights(maxStale: 2);

      expect(staleWindowRequests, hasLength(2));
      final List<Insights> stale = await isar.insights
          .filter()
          .staleEqualTo(true)
          .sortByStartDate()
          .findAll();
      expect(
        stale.map((Insights i) => i.startDate.month).toList(),
        <int>[1, 2, 3],
        reason: 'the two most recent (April, May) are refreshed',
      );
    });
  });
}
