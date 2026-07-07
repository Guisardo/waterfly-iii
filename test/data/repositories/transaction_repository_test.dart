import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

Map<String, dynamic> _transactionJson({
  required String id,
  required String amount,
  required String description,
  DateTime? date,
}) {
  final String transactionDate = (date ?? DateTime.now()).toIso8601String();
  return <String, dynamic>{
    'type': 'transactions',
    'id': id,
    'attributes': <String, List<Map<String, String>>>{
      'transactions': <Map<String, String>>[
        <String, String>{
          'type': 'withdrawal',
          'date': transactionDate,
          'amount': amount,
          'description': description,
        },
      ],
    },
    'links': <String, String>{
      'self': 'https://example.com/api/v1/transactions/$id',
    },
  };
}

Transactions _syncedTransactionRow(TransactionRead transaction) {
  final TransactionSplit? split =
      transaction.attributes.transactions.firstOrNull;
  return Transactions()
    ..transactionId = transaction.id
    ..data = jsonEncode(transaction.toJson())
    ..updatedAt = transaction.attributes.updatedAt
    ..localUpdatedAt = DateTime.now().toUtc()
    ..synced = true
    ..date = split?.date
    ..sourceAccountId = split?.sourceId
    ..destinationAccountId = split?.destinationId;
}

TransactionStore _pendingStore({
  required TransactionTypeProperty type,
  required DateTime date,
  required String amount,
  required String description,
  String? sourceId,
  String? sourceName,
  String? destinationId,
  String? destinationName,
  String? foreignAmount,
  String? foreignCurrencyId,
  String? foreignCurrencyCode,
  List<TransactionSplitStore>? splits,
}) {
  return TransactionStore(
    groupTitle: splits == null ? null : 'Pending group',
    transactions:
        splits ??
        <TransactionSplitStore>[
          TransactionSplitStore(
            type: type,
            date: date,
            amount: amount,
            description: description,
            currencyId: '1',
            currencyCode: 'USD',
            sourceId: sourceId,
            sourceName: sourceName,
            destinationId: destinationId,
            destinationName: destinationName,
            categoryName: 'Groceries',
            budgetName: 'Food',
            tags: <String>['pending'],
            notes: 'local note',
            foreignAmount: foreignAmount,
            foreignCurrencyId: foreignCurrencyId,
            foreignCurrencyCode: foreignCurrencyCode,
            reconciled: true,
          ),
        ],
    applyRules: true,
    fireWebhooks: true,
    errorIfDuplicateHash: true,
  );
}

Future<PendingChanges?> _pendingCreateFor(Isar isar, String pendingId) async {
  final List<PendingChanges> changes = await isar.pendingChanges
      .where()
      .findAll();
  for (final PendingChanges change in changes) {
    if (change.entityType == 'transactions' &&
        change.operation == PendingChangeOperation.create.name &&
        !change.synced &&
        change.localPendingId == pendingId) {
      return change;
    }
  }
  return null;
}

void main() {
  group('TransactionRepository', () {
    late Isar isar;
    late TransactionRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = TransactionRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no transactions', () async {
      final List<TransactionRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when transaction not found', () async {
      final TransactionRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores transaction and queues pending change', () async {
      final Map<String, dynamic> transactionJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-1',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Test transaction',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-1',
        },
      };

      final TransactionRead transaction = TransactionRead.fromJson(
        transactionJson,
      );

      await repository.create(transaction);

      // Verify transaction was stored
      final TransactionRead? retrieved = await repository.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');

      // Verify pending change was created
      final List<PendingChanges> pending = await isar.pendingChanges
          .filter()
          .entityTypeEqualTo('transactions')
          .findAll();
      expect(pending.length, 1);
      expect(pending.first.operation, PendingChangeOperation.create.name);
    });

    test('update modifies existing transaction', () async {
      final Map<String, dynamic> transactionJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-2',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Original',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-2',
        },
      };

      final TransactionRead transaction = TransactionRead.fromJson(
        transactionJson,
      );
      await repository.create(transaction);

      final Map<String, dynamic> updatedJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-2',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '20.00',
              'description': 'Updated',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-2',
        },
      };

      final TransactionRead updated = TransactionRead.fromJson(updatedJson);
      await repository.update(updated);

      final TransactionRead? retrieved = await repository.getById('test-2');
      expect(retrieved, isNotNull);
      expect(retrieved!.attributes.transactions.first.description, 'Updated');
    });

    test(
      'updateExisting for synced transaction updates local date before sync',
      () async {
        final DateTime originalDate = DateTime(2026, 7, 7, 15, 50);
        final DateTime updatedDate = DateTime(2026, 7, 6, 15, 50);
        final TransactionRead transaction = TransactionRead.fromJson(
          _transactionJson(
            id: 'test-synced-date',
            amount: '123.00',
            description: 'Original date',
            date: originalDate,
          ),
        );
        await isar.writeTxn(() async {
          await isar.transactions.put(_syncedTransactionRow(transaction));
        });

        await repository.updateExisting(
          'test-synced-date',
          TransactionUpdate(
            transactions: <TransactionSplitUpdate>[
              TransactionSplitUpdate(
                date: updatedDate,
                description: 'Original date',
              ),
            ],
          ),
        );

        final TransactionRead? retrieved = await repository.getById(
          'test-synced-date',
        );
        expect(retrieved, isNotNull);
        expect(retrieved!.attributes.transactions.first.date, updatedDate);

        final Transactions? row = await isar.transactions
            .filter()
            .transactionIdEqualTo('test-synced-date')
            .findFirst();
        expect(row, isNotNull);
        expect(row!.synced, isFalse);
        expect(row.date, updatedDate);

        final List<PendingChanges> pending = await isar.pendingChanges
            .filter()
            .entityTypeEqualTo('transactions')
            .entityIdEqualTo('test-synced-date')
            .findAll();
        expect(pending, hasLength(1));
        final TransactionUpdate queuedUpdate = TransactionUpdate.fromJson(
          jsonDecode(pending.single.data!) as Map<String, dynamic>,
        );
        expect(queuedUpdate.transactions?.single.date, updatedDate);
      },
    );

    test('delete removes transaction and queues pending change', () async {
      final Map<String, dynamic> transactionJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-3',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'To delete',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-3',
        },
      };

      final TransactionRead transaction = TransactionRead.fromJson(
        transactionJson,
      );
      await repository.create(transaction);
      await repository.delete('test-3');

      final TransactionRead? retrieved = await repository.getById('test-3');
      expect(retrieved, isNull);

      // Verify delete pending change was created
      final List<PendingChanges> pending = await isar.pendingChanges
          .filter()
          .entityTypeEqualTo('transactions')
          .operationEqualTo(PendingChangeOperation.delete.name)
          .findAll();
      expect(pending.length, greaterThan(0));
    });

    test('search finds transactions by query', () async {
      final Map<String, dynamic> transaction1Json = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-4',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Coffee purchase',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-4',
        },
      };

      final Map<String, dynamic> transaction2Json = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-5',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '20.00',
              'description': 'Lunch expense',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-5',
        },
      };

      await repository.create(TransactionRead.fromJson(transaction1Json));
      await repository.create(TransactionRead.fromJson(transaction2Json));

      final List<TransactionRead> results = await repository.search('Coffee');
      expect(results.length, 1);
      expect(results.first.id, 'test-4');
    });

    test('upsertFromSync creates new transaction if not exists', () async {
      final Map<String, dynamic> transactionJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-6',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Synced transaction',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-6',
        },
      };

      final TransactionRead transaction = TransactionRead.fromJson(
        transactionJson,
      );
      await repository.upsertFromSync(transaction);

      final TransactionRead? retrieved = await repository.getById('test-6');
      expect(retrieved, isNotNull);
    });

    test('upsertFromSync updates existing transaction', () async {
      final Map<String, dynamic> transactionJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-7',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Original',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-7',
        },
      };

      final TransactionRead transaction = TransactionRead.fromJson(
        transactionJson,
      );
      await repository.create(transaction);

      final Map<String, dynamic> updatedJson = <String, dynamic>{
        'type': 'transactions',
        'id': 'test-7',
        'attributes': <String, List<Map<String, String>>>{
          'transactions': <Map<String, String>>[
            <String, String>{
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '20.00',
              'description': 'Updated via sync',
            },
          ],
        },
        'links': <String, String>{
          'self': 'https://example.com/api/v1/transactions/test-7',
        },
      };

      final TransactionRead updated = TransactionRead.fromJson(updatedJson);
      await repository.upsertFromSync(updated);

      final TransactionRead? retrieved = await repository.getById('test-7');
      expect(retrieved, isNotNull);
    });

    test(
      'deleteSyncedMissingFromServer removes stale synced transaction',
      () async {
        final TransactionRead kept = TransactionRead.fromJson(
          _transactionJson(
            id: 'test-8',
            amount: '10.00',
            description: 'Still on server',
          ),
        );
        final TransactionRead removed = TransactionRead.fromJson(
          _transactionJson(
            id: 'test-9',
            amount: '2710.80',
            description: 'remedio Nico',
          ),
        );
        await isar.writeTxn(() async {
          await isar.transactions.put(_syncedTransactionRow(kept));
          await isar.transactions.put(_syncedTransactionRow(removed));
        });

        final int deletedCount = await repository.deleteSyncedMissingFromServer(
          <String>{'test-8'},
        );

        expect(deletedCount, 1);
        final List<Transactions> remainingRows = await isar.transactions
            .where()
            .findAll();
        final Iterable<String> remainingIds = remainingRows.map(
          (Transactions row) => row.transactionId,
        );
        expect(remainingIds, contains('test-8'));
        expect(remainingIds, isNot(contains('test-9')));
      },
    );

    test(
      'deleteSyncedMissingFromServer preserves pending local changes',
      () async {
        final TransactionRead edited = TransactionRead.fromJson(
          _transactionJson(
            id: 'test-10',
            amount: '2710.80',
            description: 'remedio Nico edited locally',
          ),
        );
        await isar.writeTxn(() async {
          await isar.transactions.put(_syncedTransactionRow(edited));
        });
        await repository.update(edited);

        final int deletedCount = await repository.deleteSyncedMissingFromServer(
          <String>{},
        );

        expect(deletedCount, 0);
        final List<Transactions> remainingRows = await isar.transactions
            .where()
            .findAll();
        final Iterable<String> remainingIds = remainingRows.map(
          (Transactions row) => row.transactionId,
        );
        expect(remainingIds, contains('test-10'));
      },
    );

    test('createNew normalizes stored date to midnight', () async {
      // A non-midnight date (15:30 local time) — this was the root cause of the
      // pending-transaction visibility bug: time-of-day caused dateBetween to exclude it.
      final DateTime nonMidnight = DateTime(2026, 4, 17, 15, 30, 0);
      final TransactionStore store = TransactionStore(
        transactions: <TransactionSplitStore>[
          TransactionSplitStore(
            type: TransactionTypeProperty.withdrawal,
            date: nonMidnight,
            amount: '25.00',
            description: 'Pending coffee',
          ),
        ],
      );

      final String pendingId = await repository.createNew(store);

      // Read the raw Isar row to verify the stored date field is midnight
      final Transactions? row = await isar.transactions
          .filter()
          .transactionIdEqualTo(pendingId)
          .findFirst();

      expect(row, isNotNull);
      final DateTime expectedMidnight = DateTime(2026, 4, 17, 0, 0, 0, 0, 0);
      expect(row!.date, equals(expectedMidnight));
    });

    test(
      'getByDateRange includes pending transaction with non-midnight split date',
      () async {
        // Simulate the exact bug scenario: user adds a transaction at 15:30 today.
        // Before the fix, dateBetween(startOfMonth, todayMidnight) excluded it because
        // the stored date had a time component that exceeded todayMidnight in UTC.
        final DateTime today = DateTime.now();
        final DateTime todayAt1530 = DateTime(
          today.year,
          today.month,
          today.day,
          15,
          30,
          0,
        );

        final TransactionStore store = TransactionStore(
          transactions: <TransactionSplitStore>[
            TransactionSplitStore(
              type: TransactionTypeProperty.withdrawal,
              date: todayAt1530,
              amount: '10.00',
              description: 'Afternoon coffee',
            ),
          ],
        );

        await repository.createNew(store);

        final DateTime startOfMonth = DateTime(today.year, today.month, 1);
        final DateTime endOfToday = DateTime(
          today.year,
          today.month,
          today.day,
          0,
          0,
          0,
          0,
          0,
        );

        final List<TransactionRead> results = await repository.getByDateRange(
          startOfMonth,
          endOfToday,
        );

        expect(results, isNotEmpty);
        expect(
          results.any(
            (TransactionRead tx) =>
                tx.attributes.transactions.firstOrNull?.description ==
                'Afternoon coffee',
          ),
          isTrue,
        );
      },
    );

    for (final (
          TransactionTypeProperty type,
          AccountTypeProperty sourceType,
          AccountTypeProperty destinationType,
        )
        in <
          (TransactionTypeProperty, AccountTypeProperty, AccountTypeProperty)
        >[
          (
            TransactionTypeProperty.withdrawal,
            AccountTypeProperty.assetAccount,
            AccountTypeProperty.expenseAccount,
          ),
          (
            TransactionTypeProperty.deposit,
            AccountTypeProperty.revenueAccount,
            AccountTypeProperty.assetAccount,
          ),
          (
            TransactionTypeProperty.transfer,
            AccountTypeProperty.assetAccount,
            AccountTypeProperty.assetAccount,
          ),
        ]) {
      test('getById returns editor-safe pending ${type.name}', () async {
        final DateTime date = DateTime(2026, 5, 1, 12, 30);
        final String pendingId = await repository.createNew(
          _pendingStore(
            type: type,
            date: date,
            amount: '12.34',
            description: 'Pending ${type.name}',
            sourceId: 'source-1',
            sourceName: 'Source account',
            destinationId: 'destination-1',
            destinationName: 'Destination account',
          ),
        );

        final TransactionRead? transaction = await repository.getById(
          pendingId,
        );

        expect(transaction, isNotNull);
        expect(transaction!.id, pendingId);
        final TransactionSplit split =
            transaction.attributes.transactions.first;
        expect(split.type, type);
        expect(split.amount, '12.34');
        expect(split.description, 'Pending ${type.name}');
        expect(split.currencyId, '1');
        expect(split.currencyCode, 'USD');
        expect(split.currencySymbol, isNotNull);
        expect(split.currencyName, isNotNull);
        expect(split.sourceId, 'source-1');
        expect(split.destinationId, 'destination-1');
        expect(split.sourceType, sourceType);
        expect(split.destinationType, destinationType);
        expect(split.categoryName, 'Groceries');
        expect(split.budgetName, 'Food');
        expect(split.tags, <String>['pending']);
        expect(split.notes, 'local note');
        expect(split.reconciled, isTrue);
      });
    }

    test(
      'updateExisting for pending transaction updates row indexes and queued create',
      () async {
        final DateTime originalDate = DateTime(2026, 5, 1, 12, 30);
        final DateTime updatedDate = DateTime(2026, 6, 2, 16, 45);
        final String pendingId = await repository.createNew(
          _pendingStore(
            type: TransactionTypeProperty.withdrawal,
            date: originalDate,
            amount: '10.00',
            description: 'Original first split',
            sourceId: 'asset-1',
            sourceName: 'Checking',
            destinationId: 'expense-1',
            destinationName: 'Shop',
            foreignAmount: '99.00',
            foreignCurrencyId: '2',
            foreignCurrencyCode: 'EUR',
            splits: <TransactionSplitStore>[
              TransactionSplitStore(
                type: TransactionTypeProperty.withdrawal,
                date: originalDate,
                amount: '10.00',
                description: 'Original first split',
                currencyId: '1',
                currencyCode: 'USD',
                sourceId: 'asset-1',
                sourceName: 'Checking',
                destinationId: 'expense-1',
                destinationName: 'Shop',
                categoryName: 'Old category',
                budgetName: 'Old budget',
                tags: <String>['old'],
                notes: 'old note',
                foreignAmount: '99.00',
                foreignCurrencyId: '2',
                foreignCurrencyCode: 'EUR',
                reconciled: false,
              ),
              TransactionSplitStore(
                type: TransactionTypeProperty.withdrawal,
                date: originalDate,
                amount: '20.00',
                description: 'Preserved second split',
                currencyId: '1',
                currencyCode: 'USD',
                sourceId: 'asset-1',
                sourceName: 'Checking',
                destinationId: 'expense-2',
                destinationName: 'Cafe',
                categoryName: 'Coffee',
                tags: <String>['keep'],
                notes: 'keep note',
                reconciled: true,
              ),
            ],
          ),
        );

        await repository.updateExisting(
          pendingId,
          TransactionUpdate(
            groupTitle: 'Updated group',
            transactions: <TransactionSplitUpdate>[
              TransactionSplitUpdate(
                type: TransactionTypeProperty.withdrawal,
                date: updatedDate,
                amount: '15.00',
                description: 'Updated first split',
                sourceId: 'asset-2',
                sourceName: 'Savings',
                destinationId: 'expense-3',
                destinationName: 'Market',
                categoryName: 'New category',
                budgetName: 'New budget',
                tags: <String>['new'],
                notes: 'new note',
                foreignAmount: '0',
                reconciled: true,
              ),
            ],
          ),
        );

        final Transactions? row = await isar.transactions
            .filter()
            .transactionIdEqualTo(pendingId)
            .findFirst();
        expect(row, isNotNull);
        expect(row!.date, DateTime(2026, 6, 2));
        expect(row.sourceAccountId, 'asset-2');
        expect(row.destinationAccountId, 'expense-3');

        final PendingChanges? pendingCreate = await _pendingCreateFor(
          isar,
          pendingId,
        );
        expect(pendingCreate, isNotNull);
        final TransactionStore queuedStore = TransactionStore.fromJson(
          jsonDecode(pendingCreate!.data!) as Map<String, dynamic>,
        );
        expect(queuedStore.groupTitle, 'Updated group');
        expect(queuedStore.transactions.length, 2);
        expect(queuedStore.transactions.first.amount, '15.00');
        expect(
          queuedStore.transactions.first.description,
          'Updated first split',
        );
        expect(queuedStore.transactions.first.sourceId, 'asset-2');
        expect(queuedStore.transactions.first.destinationId, 'expense-3');
        expect(queuedStore.transactions.first.categoryName, 'New category');
        expect(queuedStore.transactions.first.tags, <String>['new']);
        expect(queuedStore.transactions.first.foreignAmount, isNull);
        expect(queuedStore.transactions.first.foreignCurrencyId, isNull);
        expect(
          queuedStore.transactions[1].description,
          'Preserved second split',
        );
        expect(queuedStore.transactions[1].tags, <String>['keep']);
        expect(queuedStore.transactions[1].reconciled, isTrue);
      },
    );

    test(
      'updateExisting preserves all splits when pending update is empty',
      () async {
        final String pendingId = await repository.createNew(
          _pendingStore(
            type: TransactionTypeProperty.withdrawal,
            date: DateTime(2026, 5, 1),
            amount: '10.00',
            description: 'Original',
            splits: <TransactionSplitStore>[
              TransactionSplitStore(
                type: TransactionTypeProperty.withdrawal,
                date: DateTime(2026, 5, 1),
                amount: '10.00',
                description: 'First split',
              ),
              TransactionSplitStore(
                type: TransactionTypeProperty.withdrawal,
                date: DateTime(2026, 5, 1),
                amount: '20.00',
                description: 'Second split',
              ),
            ],
          ),
        );

        await repository.updateExisting(pendingId, const TransactionUpdate());

        final PendingChanges? pendingCreate = await _pendingCreateFor(
          isar,
          pendingId,
        );
        final TransactionStore queuedStore = TransactionStore.fromJson(
          jsonDecode(pendingCreate!.data!) as Map<String, dynamic>,
        );
        expect(queuedStore.transactions.length, 2);
        expect(queuedStore.transactions.first.description, 'First split');
        expect(queuedStore.transactions[1].description, 'Second split');
      },
    );

    test(
      'delete cancels pending transaction create without server delete',
      () async {
        final String pendingId = await repository.createNew(
          _pendingStore(
            type: TransactionTypeProperty.withdrawal,
            date: DateTime(2026, 5, 1),
            amount: '10.00',
            description: 'Cancel me',
          ),
        );

        await repository.delete(pendingId);

        expect(await repository.getById(pendingId), isNull);
        final List<PendingChanges> changes = await isar.pendingChanges
            .where()
            .findAll();
        expect(
          changes.where(
            (PendingChanges change) => change.localPendingId == pendingId,
          ),
          isEmpty,
        );
        expect(
          changes.where(
            (PendingChanges change) =>
                change.entityId == pendingId &&
                change.operation == PendingChangeOperation.delete.name,
          ),
          isEmpty,
        );
      },
    );

    test('delete fails closed when pending create is missing', () async {
      final Transactions row = Transactions()
        ..transactionId = 'pending-missing-create'
        ..data = jsonEncode(
          _pendingStore(
            type: TransactionTypeProperty.withdrawal,
            date: DateTime(2026, 5, 1),
            amount: '10.00',
            description: 'Broken pending',
          ).toJson(),
        )
        ..localUpdatedAt = DateTime.now()
        ..synced = false;
      await isar.writeTxn(() async {
        await isar.transactions.put(row);
      });

      expect(
        () => repository.delete('pending-missing-create'),
        throwsA(isA<StateError>()),
      );
      expect(await repository.getById('pending-missing-create'), isNotNull);
    });
  });
}
