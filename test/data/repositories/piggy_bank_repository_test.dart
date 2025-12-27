import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/piggy_bank_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

void main() {
  group('PiggyBankRepository', () {
    late Isar isar;
    late PiggyBankRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = PiggyBankRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no piggy banks', () async {
      final List<PiggyBankRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when piggy bank not found', () async {
      final PiggyBankRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores piggy bank', () async {
      final PiggyBankRead piggyBank = PiggyBankRead(
        type: 'piggy_banks',
        id: 'test-1',
        attributes: PiggyBankProperties(
          name: 'Test Piggy Bank',
          targetAmount: '1000.00',
          currentAmount: '500.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/piggy_banks/test-1'),
      );

      await repository.create(piggyBank);

      final PiggyBankRead? retrieved = await repository.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');
      expect(retrieved.attributes.name, 'Test Piggy Bank');
    });

    test('search finds piggy banks by query', () async {
      final PiggyBankRead piggyBank1 = PiggyBankRead(
        type: 'piggy_banks',
        id: 'test-2',
        attributes: PiggyBankProperties(
          name: 'Vacation Fund',
          targetAmount: '5000.00',
          currentAmount: '2000.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/piggy_banks/test-2'),
      );

      final PiggyBankRead piggyBank2 = PiggyBankRead(
        type: 'piggy_banks',
        id: 'test-3',
        attributes: PiggyBankProperties(
          name: 'Emergency Fund',
          targetAmount: '10000.00',
          currentAmount: '7500.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/piggy_banks/test-3'),
      );

      await repository.create(piggyBank1);
      await repository.create(piggyBank2);

      final List<PiggyBankRead> results = await repository.search('Vacation');
      expect(results.length, 1);
      expect(results.first.id, 'test-2');
    });

    test('upsertFromSync creates new piggy bank if not exists', () async {
      final PiggyBankRead piggyBank = PiggyBankRead(
        type: 'piggy_banks',
        id: 'test-4',
        attributes: PiggyBankProperties(
          name: 'Synced Piggy Bank',
          targetAmount: '2000.00',
          currentAmount: '1000.00',
          currencyId: '1',
          currencyCode: 'USD',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/piggy_banks/test-4'),
      );

      await repository.upsertFromSync(piggyBank);

      final PiggyBankRead? retrieved = await repository.getById('test-4');
      expect(retrieved, isNotNull);
    });
  });
}

