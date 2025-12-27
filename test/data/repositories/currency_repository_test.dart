import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/currency_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

void main() {
  group('CurrencyRepository', () {
    late Isar isar;
    late CurrencyRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = CurrencyRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no currencies', () async {
      final List<CurrencyRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when currency not found', () async {
      final CurrencyRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores currency', () async {
      final CurrencyRead currency = CurrencyRead(
        type: 'currencies',
        id: '1',
        attributes: CurrencyProperties(
          name: 'US Dollar',
          code: 'USD',
          symbol: '\$',
          decimalPlaces: 2,
        ),
      );

      await repository.create(currency);

      final CurrencyRead? retrieved = await repository.getById('1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, '1');
      expect(retrieved.attributes.code, 'USD');
    });

    test('search finds currencies by query', () async {
      final CurrencyRead currency1 = CurrencyRead(
        type: 'currencies',
        id: '2',
        attributes: CurrencyProperties(
          name: 'Euro',
          code: 'EUR',
          symbol: '€',
          decimalPlaces: 2,
        ),
      );

      final CurrencyRead currency2 = CurrencyRead(
        type: 'currencies',
        id: '3',
        attributes: CurrencyProperties(
          name: 'British Pound',
          code: 'GBP',
          symbol: '£',
          decimalPlaces: 2,
        ),
      );

      await repository.create(currency1);
      await repository.create(currency2);

      final List<CurrencyRead> results = await repository.search('Euro');
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('upsertFromSync creates new currency if not exists', () async {
      final CurrencyRead currency = CurrencyRead(
        type: 'currencies',
        id: '4',
        attributes: CurrencyProperties(
          name: 'Synced Currency',
          code: 'SYN',
          symbol: 'S',
          decimalPlaces: 2,
        ),
      );

      await repository.upsertFromSync(currency);

      final CurrencyRead? retrieved = await repository.getById('4');
      expect(retrieved, isNotNull);
    });
  });
}

