import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

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
      final Map<String, dynamic> transactionJson = {
        'type': 'transactions',
        'id': 'test-1',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Test transaction',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-1',
        },
      };

      final TransactionRead transaction =
          TransactionRead.fromJson(transactionJson);

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
      expect(pending.first.operation, 'CREATE');
    });

    test('update modifies existing transaction', () async {
      final Map<String, dynamic> transactionJson = {
        'type': 'transactions',
        'id': 'test-2',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Original',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-2',
        },
      };

      final TransactionRead transaction =
          TransactionRead.fromJson(transactionJson);
      await repository.create(transaction);

      final Map<String, dynamic> updatedJson = {
        'type': 'transactions',
        'id': 'test-2',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '20.00',
              'description': 'Updated',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-2',
        },
      };

      final TransactionRead updated = TransactionRead.fromJson(updatedJson);
      await repository.update(updated);

      final TransactionRead? retrieved = await repository.getById('test-2');
      expect(retrieved, isNotNull);
      expect(
        retrieved!.attributes.transactions.first.description,
        'Updated',
      );
    });

    test('delete removes transaction and queues pending change', () async {
      final Map<String, dynamic> transactionJson = {
        'type': 'transactions',
        'id': 'test-3',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'To delete',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-3',
        },
      };

      final TransactionRead transaction =
          TransactionRead.fromJson(transactionJson);
      await repository.create(transaction);
      await repository.delete('test-3');

      final TransactionRead? retrieved = await repository.getById('test-3');
      expect(retrieved, isNull);

      // Verify delete pending change was created
      final List<PendingChanges> pending = await isar.pendingChanges
          .filter()
          .entityTypeEqualTo('transactions')
          .operationEqualTo('DELETE')
          .findAll();
      expect(pending.length, greaterThan(0));
    });

    test('search finds transactions by query', () async {
      final Map<String, dynamic> transaction1Json = {
        'type': 'transactions',
        'id': 'test-4',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Coffee purchase',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-4',
        },
      };

      final Map<String, dynamic> transaction2Json = {
        'type': 'transactions',
        'id': 'test-5',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '20.00',
              'description': 'Lunch expense',
            },
          ],
        },
        'links': {
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
      final Map<String, dynamic> transactionJson = {
        'type': 'transactions',
        'id': 'test-6',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Synced transaction',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-6',
        },
      };

      final TransactionRead transaction =
          TransactionRead.fromJson(transactionJson);
      await repository.upsertFromSync(transaction);

      final TransactionRead? retrieved = await repository.getById('test-6');
      expect(retrieved, isNotNull);
    });

    test('upsertFromSync updates existing transaction', () async {
      final Map<String, dynamic> transactionJson = {
        'type': 'transactions',
        'id': 'test-7',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '10.00',
              'description': 'Original',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-7',
        },
      };

      final TransactionRead transaction =
          TransactionRead.fromJson(transactionJson);
      await repository.create(transaction);

      final Map<String, dynamic> updatedJson = {
        'type': 'transactions',
        'id': 'test-7',
        'attributes': {
          'transactions': [
            {
              'type': 'withdrawal',
              'date': DateTime.now().toIso8601String(),
              'amount': '20.00',
              'description': 'Updated via sync',
            },
          ],
        },
        'links': {
          'self': 'https://example.com/api/v1/transactions/test-7',
        },
      };

      final TransactionRead updated = TransactionRead.fromJson(updatedJson);
      await repository.upsertFromSync(updated);

      final TransactionRead? retrieved = await repository.getById('test-7');
      expect(retrieved, isNotNull);
    });
  });
}
