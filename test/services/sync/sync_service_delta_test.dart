import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/services/connectivity/connectivity_service.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';

import '../../helpers/mock_api.dart';
import '../../helpers/mock_isar.dart';

const Map<String, String> _jsonHeaders = <String, String>{
  'content-type': 'application/json',
};

const List<String> _bothFeatures = <String>[
  'incremental.transactions',
  'deleted_items',
];

/// Overlap the client subtracts from its cursor on every delta read.
const Duration _overlap = Duration(hours: 2);

class _OnlineConnectivity extends ChangeNotifier
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

class _SilentNotifications extends SyncNotifications {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showCredentialError() async {}

  @override
  Future<void> showSyncCompleted() async {}

  @override
  Future<void> showSyncPaused(String error) async {}

  @override
  Future<void> showSyncProgress({
    required String entityType,
    required int current,
    required int total,
    String? message,
  }) async {}

  @override
  Future<void> showSyncStarted() async {}
}

/// A moment [minutesAgo] minutes before now, on a whole minute so that values
/// survive an ISO-8601 round trip unchanged.
DateTime _at(int minutesAgo) {
  final DateTime now = DateTime.now().toUtc();
  return DateTime.utc(
    now.year,
    now.month,
    now.day,
    now.hour,
    now.minute,
  ).subtract(Duration(minutes: minutesAgo));
}

class _ServerTransaction {
  _ServerTransaction(this.id, this.updatedAt);

  final String id;
  DateTime updatedAt;
  String description = 'original';

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': 'transactions',
    'id': id,
    'attributes': <String, Object?>{
      'created_at': updatedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'group_title': null,
      'transactions': <Map<String, Object>>[
        <String, Object>{
          'transaction_journal_id': id,
          'type': 'withdrawal',
          'date': updatedAt.toIso8601String(),
          'order': 0,
          'currency_id': '1',
          'currency_code': 'USD',
          'currency_symbol': '\$',
          'currency_decimal_places': 2,
          'amount': '10.00',
          'description': description,
          'source_id': '1',
          'source_name': 'Source',
          'source_type': 'asset',
          'destination_id': '2',
          'destination_name': 'Destination',
          'destination_type': 'expense',
          'reconciled': false,
          'tags': <dynamic>[],
          'links': <dynamic>[],
        },
      ],
    },
    'links': <String, String>{
      'self': 'http://test.firefly.local/api/v1/transactions/$id',
    },
  };
}

class _ServerDeletion {
  _ServerDeletion(this.id, this.deletedAt);

  final String id;
  final DateTime deletedAt;
}

/// Minimal Firefly III stand-in that honours updated_since, sort, limit, page
/// on the transaction list and since, types, limit, page on the deleted list.
class _FakeServer {
  final List<_ServerTransaction> transactions = <_ServerTransaction>[];
  final List<_ServerDeletion> deletions = <_ServerDeletion>[];

  List<String> capabilities = _bothFeatures;
  int aboutStatus = 200;
  String? aboutRawBody;
  int? listFailureStatus;

  /// Called before each transaction list request is answered, so a test can
  /// change the data while the client is paging.
  void Function(Uri uri, int requestNumber)? onListRequest;

  final List<Uri> aboutRequests = <Uri>[];
  final List<Uri> listRequests = <Uri>[];
  final List<Uri> deletedRequests = <Uri>[];

  void install(MockHttpClient client) {
    client.setHandler('/v1/about', _about);
    client.setHandler('/v1/transactions', _list);
    client.setHandler('/v1/data/deleted', _deleted);
  }

  /// Full-page reads: list requests that are not the limit=1 stability probe.
  List<Uri> get pageReads =>
      listRequests.where((Uri u) => u.queryParameters['limit'] != '1').toList();

  List<Uri> get probes =>
      listRequests.where((Uri u) => u.queryParameters['limit'] == '1').toList();

  /// Requests that asked for every transaction, without a change filter.
  List<Uri> get unfilteredReads => pageReads
      .where((Uri u) => !u.queryParameters.containsKey('updated_since'))
      .toList();

  void resetRequests() {
    aboutRequests.clear();
    listRequests.clear();
    deletedRequests.clear();
  }

  http.Response _about(http.BaseRequest request) {
    aboutRequests.add(request.url);
    if (aboutRawBody != null) {
      return http.Response(aboutRawBody!, aboutStatus, headers: _jsonHeaders);
    }
    return http.Response(
      jsonEncode(<String, Object?>{
        'data': <String, Object?>{
          'version': '6.7.0',
          'api_version': '6.7.0',
          'php_version': '8.4.0',
          'os': 'Linux',
          'driver': 'sqlite',
          'capabilities': capabilities,
        },
      }),
      aboutStatus,
      headers: _jsonHeaders,
    );
  }

  http.Response _list(http.BaseRequest request) {
    final Uri uri = request.url;
    listRequests.add(uri);
    onListRequest?.call(uri, listRequests.length);
    if (listFailureStatus != null) {
      return http.Response('{"message":"boom"}', listFailureStatus!);
    }

    final Map<String, String> query = uri.queryParameters;
    final DateTime? since = query['updated_since'] == null
        ? null
        : DateTime.parse(query['updated_since']!);
    final List<_ServerTransaction> rows = transactions
        .where(
          (_ServerTransaction t) =>
              since == null || !t.updatedAt.isBefore(since),
        )
        .toList();
    final String sort = query['sort'] ?? 'id';
    rows.sort((_ServerTransaction a, _ServerTransaction b) {
      switch (sort) {
        case '-updated_at':
          return b.updatedAt.compareTo(a.updatedAt);
        case 'updated_at':
          return a.updatedAt.compareTo(b.updatedAt);
        default:
          return a.id.compareTo(b.id);
      }
    });

    return _paged(
      query,
      rows.map((_ServerTransaction t) => t.toJson()).toList(),
    );
  }

  http.Response _deleted(http.BaseRequest request) {
    final Uri uri = request.url;
    deletedRequests.add(uri);
    final Map<String, String> query = uri.queryParameters;
    final DateTime? since = query['since'] == null
        ? null
        : DateTime.parse(query['since']!);
    final List<_ServerDeletion> rows =
        deletions
            .where(
              (_ServerDeletion d) =>
                  since == null || !d.deletedAt.isBefore(since),
            )
            .toList()
          ..sort(
            (_ServerDeletion a, _ServerDeletion b) =>
                a.deletedAt.compareTo(b.deletedAt),
          );

    return _paged(
      query,
      rows
          .map(
            (_ServerDeletion d) => <String, Object?>{
              'type': 'deleted-items',
              'id': d.id,
              'attributes': <String, Object?>{
                'entity': 'transactions',
                'deleted_at': d.deletedAt.toIso8601String(),
              },
            },
          )
          .toList(),
    );
  }

  http.Response _paged(Map<String, String> query, List<Object?> all) {
    final int limit = int.parse(query['limit'] ?? '50');
    final int page = int.parse(query['page'] ?? '1');
    final int totalPages = all.isEmpty ? 1 : (all.length / limit).ceil();
    final List<Object?> slice = all
        .skip((page - 1) * limit)
        .take(limit)
        .toList();
    return http.Response(
      jsonEncode(<String, Object?>{
        'data': slice,
        'meta': <String, Object?>{
          'pagination': <String, Object?>{
            'total': all.length,
            'count': slice.length,
            'per_page': limit,
            'current_page': page,
            'total_pages': totalPages,
          },
        },
        'links': <String, Object?>{
          'self': 'http://test.firefly.local/api/v1/test?page=$page',
          'first': 'http://test.firefly.local/api/v1/test?page=1',
          'last': 'http://test.firefly.local/api/v1/test?page=$totalPages',
        },
      }),
      200,
      headers: _jsonHeaders,
    );
  }
}

/// [MockIsar] answers every `xEqualTo` filter with the first stored row. These
/// tests need rows told apart (per entity type, per id, per pending change), so
/// this collection evaluates the equality filters the sync code relies on and
/// refuses any other filter instead of silently ignoring it.
class _FilteringCollection<T> extends MockIsarCollection<T> {
  _FilteringCollection(this._properties, Isar owner)
    : super(<String, dynamic Function(T, dynamic)>{}, owner);

  final Map<String, Object? Function(T)> _properties;

  @override
  Query<R> buildQuery<R>({
    List<WhereClause> whereClauses = const <WhereClause>[],
    bool whereDistinct = false,
    Sort whereSort = Sort.asc,
    FilterOperation? filter,
    List<SortProperty> sortBy = const <SortProperty>[],
    List<DistinctProperty> distinctBy = const <DistinctProperty>[],
    int? offset,
    int? limit,
    String? property,
  }) {
    final List<T> matching = data
        .where((T row) => _matches(filter, row))
        .toList();
    return MockQueryBuilder<T, QWhere>(
          matching,
          <String, dynamic Function(T, dynamic)>{},
        ).build()
        as Query<R>;
  }

  bool _matches(FilterOperation? operation, T row) {
    if (operation == null) return true;
    if (operation is FilterGroup) {
      final List<bool> results = operation.filters
          .map((FilterOperation inner) => _matches(inner, row))
          .toList();
      switch (operation.type) {
        case FilterGroupType.and:
          return results.every((bool r) => r);
        case FilterGroupType.or:
          return results.any((bool r) => r);
        case FilterGroupType.xor:
          return results.where((bool r) => r).length == 1;
        case FilterGroupType.not:
          throw UnsupportedError(
            'Filter group not supported: ${operation.type}',
          );
      }
    }
    if (operation is FilterCondition &&
        operation.type == FilterConditionType.equalTo) {
      final Object? Function(T)? read = _properties[operation.property];
      if (read == null) {
        throw UnsupportedError('No test getter for ${operation.property}');
      }
      return read(row) == operation.value1;
    }
    throw UnsupportedError('Filter not supported: $operation');
  }
}

class _FilteringIsar extends MockIsar {
  late final _FilteringCollection<Transactions> _transactions =
      _FilteringCollection<Transactions>(
        <String, Object? Function(Transactions)>{
          'transactionId': (Transactions r) => r.transactionId,
          'synced': (Transactions r) => r.synced,
        },
        this,
      );
  late final _FilteringCollection<SyncMetadata> _syncMetadata =
      _FilteringCollection<SyncMetadata>(
        <String, Object? Function(SyncMetadata)>{
          'entityType': (SyncMetadata r) => r.entityType,
          'syncPaused': (SyncMetadata r) => r.syncPaused,
        },
        this,
      );
  late final _FilteringCollection<PendingChanges> _pendingChanges =
      _FilteringCollection<PendingChanges>(
        <String, Object? Function(PendingChanges)>{
          'entityType': (PendingChanges r) => r.entityType,
          'entityId': (PendingChanges r) => r.entityId,
          'operation': (PendingChanges r) => r.operation,
          'synced': (PendingChanges r) => r.synced,
        },
        this,
      );

  @override
  IsarCollection<T> collection<T>() {
    if (T == Transactions) return _transactions as IsarCollection<T>;
    if (T == SyncMetadata) return _syncMetadata as IsarCollection<T>;
    if (T == PendingChanges) return _pendingChanges as IsarCollection<T>;
    return super.collection<T>();
  }

  Future<void> reset() async {
    await clear();
    await _transactions.clear();
    await _syncMetadata.clear();
    await _pendingChanges.clear();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncService delta sync for transactions', () {
    // Typed as Isar on purpose: MockIsar exposes its own collection fields,
    // which would shadow the collection() lookups the production code uses.
    late Isar isar;
    late _FilteringIsar db;
    late _FakeServer server;
    late MockFireflyServiceHelper helper;
    late _OnlineConnectivity connectivity;
    late SyncService syncService;

    setUpAll(() {
      db = _FilteringIsar();
      isar = db;
    });

    setUp(() async {
      await db.reset();
      server = _FakeServer();
      helper = MockFireflyServiceHelper()..setSignedIn(true);
      server.install(helper.mockHttpClient);
      connectivity = _OnlineConnectivity();
      syncService = SyncService(
        isar: isar,
        fireflyService: helper.getFireflyService(),
        connectivityService: connectivity,
        notifications: _SilentNotifications(),
      );
      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(
          SyncMetadata()
            ..entityType = 'auth'
            ..credentialsValidated = true,
        );
      });
    });

    tearDown(() {
      syncService.dispose();
      connectivity.dispose();
    });

    Future<SyncMetadata> metadata(String entityType) async {
      final SyncMetadata? row = await isar.syncMetadatas
          .filter()
          .entityTypeEqualTo(entityType)
          .findFirst();
      expect(row, isNotNull, reason: 'no metadata row for $entityType');
      return row!;
    }

    Future<void> putMetadata({
      DateTime? deltaCursor,
      DateTime? lastFullSync,
      DateTime? lastDownloadSync,
    }) async {
      await isar.writeTxn(() async {
        await isar.syncMetadatas.put(
          SyncMetadata()
            ..entityType = 'transactions'
            ..deltaCursor = deltaCursor
            ..lastFullSync = lastFullSync
            ..lastDownloadSync = lastDownloadSync,
        );
      });
    }

    Future<void> seedLocal(_ServerTransaction tx) async {
      await TransactionRepository(
        isar,
      ).upsertFromSync(TransactionRead.fromJson(tx.toJson()));
    }

    Future<Map<String, String>> localDescriptions() async {
      final List<Transactions> rows = await isar.transactions.where().findAll();
      return <String, String>{
        for (final Transactions row in rows)
          row.transactionId:
              (((jsonDecode(row.data) as Map<String, dynamic>)['attributes']
                          as Map<String, dynamic>)['transactions']
                      as List<dynamic>)
                  .map(
                    (dynamic split) =>
                        (split as Map<String, dynamic>)['description'],
                  )
                  .join(),
      };
    }

    Future<void> runSync({bool forceFullSync = false}) => syncService.sync(
      entityType: 'transactions',
      forceFullSync: forceFullSync,
    );

    Future<void> firstSync() async {
      await runSync();
      server.resetRequests();
    }

    test('first sync reads everything and records the cursor', () async {
      server.transactions.addAll(<_ServerTransaction>[
        _ServerTransaction('tx-1', _at(300)),
        _ServerTransaction('tx-2', _at(60)),
      ]);

      await runSync();

      expect(server.unfilteredReads, isNotEmpty);
      expect(server.pageReads, hasLength(server.unfilteredReads.length));
      expect(await localDescriptions(), hasLength(2));
      final SyncMetadata row = await metadata('transactions');
      expect(row.deltaCursor, _at(60));
      expect(row.lastFullSync, isNotNull);
      expect(
        DateTime.now().toUtc().difference(row.lastFullSync!).inMinutes,
        lessThan(2),
      );
    });

    test(
      'next sync asks only for changes since cursor minus 2 hours',
      () async {
        server.transactions.addAll(<_ServerTransaction>[
          _ServerTransaction('tx-1', _at(300)),
          _ServerTransaction('tx-2', _at(60)),
        ]);
        await firstSync();
        server.transactions.first
          ..description = 'edited'
          ..updatedAt = _at(10);

        await runSync();

        expect(server.unfilteredReads, isEmpty);
        expect(server.pageReads, isNotEmpty);
        for (final Uri read in server.pageReads) {
          expect(
            read.queryParameters['updated_since'],
            _at(60).subtract(_overlap).toIso8601String(),
          );
          expect(read.queryParameters['sort'], '-updated_at');
          expect(read.queryParameters['limit'], '50');
        }
        expect((await localDescriptions())['tx-1'], 'edited');
        expect((await metadata('transactions')).deltaCursor, _at(10));
      },
    );

    test('pages through a delta larger than one page', () async {
      server.transactions.add(_ServerTransaction('tx-old', _at(600)));
      await firstSync();
      for (int i = 0; i < 120; i++) {
        server.transactions.add(_ServerTransaction('chg-$i', _at(30)));
      }

      await runSync();

      expect(
        server.pageReads.map((Uri u) => u.queryParameters['page']),
        <String?>['1', '2', '3'],
      );
      expect(await localDescriptions(), hasLength(121));
    });

    test(
      'removes rows the server reports as deleted and keeps the rest',
      () async {
        server.transactions.addAll(<_ServerTransaction>[
          _ServerTransaction('tx-1', _at(300)),
          _ServerTransaction('tx-2', _at(60)),
        ]);
        await firstSync();
        server.transactions.removeWhere(
          (_ServerTransaction t) => t.id == 'tx-2',
        );
        server.deletions.add(_ServerDeletion('tx-2', _at(5)));

        await runSync();

        // tx-1 is outside the delta window: it must survive, not be treated as
        // "missing from the server".
        expect((await localDescriptions()).keys, <String>['tx-1']);
        expect(server.deletedRequests, hasLength(1));
        final Map<String, String> asked =
            server.deletedRequests.single.queryParameters;
        expect(asked['types'], 'transactions');
        expect(asked['since'], _at(60).subtract(_overlap).toIso8601String());
        expect((await metadata('transactions')).deltaCursor, _at(5));
      },
    );

    test(
      'a row with a pending local change survives and holds the cursor',
      () async {
        server.transactions.addAll(<_ServerTransaction>[
          _ServerTransaction('tx-1', _at(300)),
          _ServerTransaction('tx-2', _at(200)),
        ]);
        await firstSync();
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(
            PendingChanges()
              ..entityType = 'transactions'
              ..entityId = 'tx-1'
              ..operation = PendingChangeOperation.update.name
              ..createdAt = DateTime.now().toUtc()
              ..synced = false,
          );
        });
        server.transactions[0]
          ..description = 'server edit'
          ..updatedAt = _at(20);
        server.transactions[1]
          ..description = 'other edit'
          ..updatedAt = _at(10);

        await runSync();

        final Map<String, String> local = await localDescriptions();
        expect(local['tx-1'], 'original');
        expect(local['tx-2'], 'other edit');
        expect((await metadata('transactions')).deltaCursor, _at(20));
      },
    );

    test(
      'a server-deleted row with a pending local change is kept and held',
      () async {
        server.transactions.addAll(<_ServerTransaction>[
          _ServerTransaction('tx-1', _at(300)),
          _ServerTransaction('tx-2', _at(200)),
        ]);
        await firstSync();
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(
            PendingChanges()
              ..entityType = 'transactions'
              ..entityId = 'tx-1'
              ..operation = PendingChangeOperation.update.name
              ..createdAt = DateTime.now().toUtc()
              ..synced = false,
          );
        });
        server.transactions.removeAt(0);
        server.deletions.add(_ServerDeletion('tx-1', _at(15)));
        server.transactions[0].updatedAt = _at(5);

        await runSync();

        expect(
          (await localDescriptions()).keys,
          containsAll(<String>['tx-1', 'tx-2']),
        );
        expect((await metadata('transactions')).deltaCursor, _at(15));
      },
    );

    for (final List<String> capabilities in <List<String>>[
      <String>[],
      <String>['incremental.transactions'],
      <String>['deleted_items'],
    ]) {
      test(
        'falls back to the full scan when the server announces $capabilities',
        () async {
          server.capabilities = capabilities;
          server.transactions.add(_ServerTransaction('tx-1', _at(60)));

          await runSync();

          expect(server.unfilteredReads, isNotEmpty);
          expect(server.pageReads, hasLength(server.unfilteredReads.length));
          expect(server.deletedRequests, isEmpty);
          final SyncMetadata row = await metadata('transactions');
          expect(row.deltaCursor, isNull);
          expect(row.lastFullSync, isNull);
        },
      );
    }

    test(
      'forgets the cursor when the server stops announcing the features',
      () async {
        server.capabilities = <String>[];
        server.transactions.add(_ServerTransaction('tx-1', _at(60)));
        await putMetadata(deltaCursor: _at(30), lastFullSync: _at(60));

        await runSync();

        expect(server.unfilteredReads, isNotEmpty);
        expect((await metadata('transactions')).deltaCursor, isNull);
      },
    );

    final Map<String, void Function(_FakeServer)> brokenProbes =
        <String, void Function(_FakeServer)>{
          '401 answer': (_FakeServer s) => s.aboutStatus = 401,
          '500 answer': (_FakeServer s) => s.aboutStatus = 500,
          'unparsable body': (_FakeServer s) {
            s.aboutStatus = 200;
            s.aboutRawBody = 'this is not json';
          },
        };
    brokenProbes.forEach((String name, void Function(_FakeServer) breakIt) {
      test(
        'a failing probe ($name) falls back to the full scan and leaves credentials alone',
        () async {
          breakIt(server);
          server.transactions.add(_ServerTransaction('tx-1', _at(60)));
          final DateTime cursor = _at(30);
          await putMetadata(deltaCursor: cursor, lastFullSync: _at(60));

          await runSync();

          expect(server.aboutRequests, isNotEmpty);
          expect(server.unfilteredReads, isNotEmpty);
          expect(await localDescriptions(), hasLength(1));
          final SyncMetadata auth = await metadata('auth');
          expect(auth.credentialsValidated, isTrue);
          expect(auth.credentialsInvalid, isFalse);
          // A broken probe says nothing about the server: keep the cursor.
          expect((await metadata('transactions')).deltaCursor, cursor);
        },
      );
    });

    test('forceFullSync reads everything and refreshes the cursor', () async {
      server.transactions.addAll(<_ServerTransaction>[
        _ServerTransaction('tx-1', _at(300)),
        _ServerTransaction('tx-2', _at(60)),
      ]);
      final DateTime staleButFresh = _at(120);
      await putMetadata(deltaCursor: _at(200), lastFullSync: staleButFresh);

      await runSync(forceFullSync: true);

      expect(server.unfilteredReads, isNotEmpty);
      expect(server.pageReads, hasLength(server.unfilteredReads.length));
      final SyncMetadata row = await metadata('transactions');
      expect(row.deltaCursor, _at(60));
      expect(row.lastFullSync!.isAfter(staleButFresh), isTrue);
    });

    test(
      'a full read is repeated after 7 days and drops purged rows',
      () async {
        server.transactions.add(_ServerTransaction('tx-1', _at(60)));
        await seedLocal(_ServerTransaction('tx-purged', _at(500)));
        await putMetadata(
          deltaCursor: _at(30),
          lastFullSync: DateTime.now().toUtc().subtract(
            const Duration(days: 8),
          ),
        );

        await runSync();

        expect(server.unfilteredReads, isNotEmpty);
        expect((await localDescriptions()).keys, <String>['tx-1']);
        final SyncMetadata row = await metadata('transactions');
        expect(
          DateTime.now().toUtc().difference(row.lastFullSync!).inMinutes,
          lessThan(2),
        );
      },
    );

    test(
      'a delta is still used just under 7 days after the full read',
      () async {
        server.transactions.add(_ServerTransaction('tx-1', _at(60)));
        await putMetadata(
          deltaCursor: _at(30),
          lastFullSync: DateTime.now().toUtc().subtract(
            const Duration(days: 6, hours: 23),
          ),
        );

        await runSync();

        expect(server.unfilteredReads, isEmpty);
        expect(server.pageReads, isNotEmpty);
      },
    );

    test(
      'an unstable list is read again up to 3 times, then the cursor stays',
      () async {
        server.transactions.addAll(<_ServerTransaction>[
          _ServerTransaction('tx-1', _at(300)),
          _ServerTransaction('tx-2', _at(60)),
        ]);
        await firstSync();
        final DateTime cursor = (await metadata('transactions')).deltaCursor!;
        int added = 0;
        server.transactions[0].updatedAt = _at(20);
        // Every stability probe finds one more changed row than the read saw.
        server.onListRequest = (Uri uri, int number) {
          if (uri.queryParameters['limit'] == '1') {
            server.transactions.add(
              _ServerTransaction('new-${added++}', _at(5)),
            );
          }
        };

        await runSync();

        expect(server.probes, hasLength(3));
        expect((await metadata('transactions')).deltaCursor, cursor);
      },
    );

    test('a list that settles on the second read moves the cursor', () async {
      server.transactions.addAll(<_ServerTransaction>[
        _ServerTransaction('tx-1', _at(300)),
        _ServerTransaction('tx-2', _at(60)),
      ]);
      await firstSync();
      server.transactions[0].updatedAt = _at(20);
      bool changedOnce = false;
      server.onListRequest = (Uri uri, int number) {
        if (uri.queryParameters['limit'] == '1' && !changedOnce) {
          changedOnce = true;
          server.transactions.add(_ServerTransaction('late', _at(5)));
        }
      };

      await runSync();

      expect(server.probes, hasLength(2));
      expect((await localDescriptions()).keys, contains('late'));
      expect((await metadata('transactions')).deltaCursor, _at(5));
    });

    test('a failing delta read leaves the cursor where it was', () async {
      server.transactions.add(_ServerTransaction('tx-1', _at(60)));
      await firstSync();
      final DateTime cursor = (await metadata('transactions')).deltaCursor!;
      server.listFailureStatus = 500;

      await runSync();

      expect((await metadata('transactions')).deltaCursor, cursor);
    });

    test('an empty delta keeps the cursor', () async {
      server.transactions.add(_ServerTransaction('tx-1', _at(600)));
      await firstSync();
      final DateTime cursor = (await metadata('transactions')).deltaCursor!;

      await runSync();

      expect(server.unfilteredReads, isEmpty);
      expect((await metadata('transactions')).deltaCursor, cursor);
    });
  });

  group('TransactionRepository.deleteSyncedByIds', () {
    // Typed as Isar on purpose: MockIsar exposes its own collection fields,
    // which would shadow the collection() lookups the production code uses.
    late Isar isar;
    late _FilteringIsar db;
    late TransactionRepository repo;

    setUpAll(() {
      db = _FilteringIsar();
      isar = db;
    });

    setUp(() async {
      await db.reset();
      repo = TransactionRepository(isar);
    });

    Future<void> put(
      String id, {
      bool synced = true,
      DateTime? deletedAt,
    }) async {
      await isar.writeTxn(() async {
        await isar.transactions.put(
          Transactions()
            ..transactionId = id
            ..data = '{}'
            ..synced = synced
            ..deletedAt = deletedAt,
        );
      });
    }

    Future<List<String>> remaining() async =>
        (await isar.transactions.where().findAll())
            .map((Transactions t) => t.transactionId)
            .toList()
          ..sort();

    test('deletes only the named synced rows', () async {
      await put('a');
      await put('b');
      await put('c');

      final int count = await repo.deleteSyncedByIds(<String>{'a', 'b'});

      expect(count, 2);
      expect(await remaining(), <String>['c']);
    });

    test(
      'keeps unsynced, locally deleted, placeholder and pending rows',
      () async {
        await put('unsynced', synced: false);
        await put('local-delete', deletedAt: DateTime.now().toUtc());
        await put('pending-123');
        await put('queued');
        await isar.writeTxn(() async {
          await isar.pendingChanges.put(
            PendingChanges()
              ..entityType = 'transactions'
              ..entityId = 'queued'
              ..operation = PendingChangeOperation.update.name
              ..createdAt = DateTime.now().toUtc()
              ..synced = false,
          );
        });

        final int count = await repo.deleteSyncedByIds(<String>{
          'unsynced',
          'local-delete',
          'pending-123',
          'queued',
        });

        expect(count, 0);
        expect(await remaining(), hasLength(4));
      },
    );

    test('ignores ids that are not stored and an empty set', () async {
      await put('a');

      expect(await repo.deleteSyncedByIds(<String>{'zzz'}), 0);
      expect(await repo.deleteSyncedByIds(<String>{}), 0);
      expect(await remaining(), <String>['a']);
    });
  });
}
