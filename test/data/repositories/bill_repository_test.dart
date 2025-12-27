import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/bill_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

void main() {
  group('BillRepository', () {
    late Isar isar;
    late BillRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = BillRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no bills', () async {
      final List<BillRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when bill not found', () async {
      final BillRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores bill', () async {
      final BillRead bill = BillRead(
        type: 'bills',
        id: 'test-1',
        attributes: BillProperties(
          name: 'Test Bill',
          currencyId: '1',
          currencyCode: 'USD',
          amountMin: '100.00',
          amountMax: '100.00',
        ),
      );

      await repository.create(bill);

      final BillRead? retrieved = await repository.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');
      expect(retrieved.attributes.name, 'Test Bill');
    });

    test('search finds bills by query', () async {
      final BillRead bill1 = BillRead(
        type: 'bills',
        id: 'test-2',
        attributes: BillProperties(
          name: 'Electric Bill',
          amountMin: '50.00',
          amountMax: '50.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
      );

      final BillRead bill2 = BillRead(
        type: 'bills',
        id: 'test-3',
        attributes: BillProperties(
          name: 'Water Bill',
          amountMin: '30.00',
          amountMax: '30.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
      );

      await repository.create(bill1);
      await repository.create(bill2);

      final List<BillRead> results = await repository.search('Electric');
      expect(results.length, 1);
      expect(results.first.id, 'test-2');
    });

    test('upsertFromSync creates new bill if not exists', () async {
      final BillRead bill = BillRead(
        type: 'bills',
        id: 'test-4',
        attributes: BillProperties(
          name: 'Synced Bill',
          amountMin: '75.00',
          amountMax: '75.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
      );

      await repository.upsertFromSync(bill);

      final BillRead? retrieved = await repository.getById('test-4');
      expect(retrieved, isNotNull);
    });
  });
}

