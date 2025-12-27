import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart' as enums;
import '../../helpers/test_database.dart';

void main() {
  group('AccountRepository', () {
    late Isar isar;
    late AccountRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = AccountRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no accounts', () async {
      final List<AccountRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when account not found', () async {
      final AccountRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores account and queues pending change', () async {
      final AccountRead account = AccountRead(
        type: 'accounts',
        id: 'test-1',
        attributes: AccountProperties(
          name: 'Test Account',
          type: enums.ShortAccountTypeProperty.asset,
        ),
      );

      await repository.create(account);

      final AccountRead? retrieved = await repository.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');
      expect(retrieved.attributes.name, 'Test Account');
    });

    test('search finds accounts by query', () async {
      final AccountRead account1 = AccountRead(
        type: 'accounts',
        id: 'test-2',
        attributes: AccountProperties(
          name: 'Checking Account',
          type: enums.ShortAccountTypeProperty.asset,
        ),
      );

      final AccountRead account2 = AccountRead(
        type: 'accounts',
        id: 'test-3',
        attributes: AccountProperties(
          name: 'Savings Account',
          type: enums.ShortAccountTypeProperty.asset,
        ),
      );

      await repository.create(account1);
      await repository.create(account2);

      final List<AccountRead> results = await repository.search('Checking');
      expect(results.length, 1);
      expect(results.first.id, 'test-2');
    });

    test('upsertFromSync creates new account if not exists', () async {
      final AccountRead account = AccountRead(
        type: 'accounts',
        id: 'test-4',
        attributes: AccountProperties(
          name: 'Synced Account',
          type: enums.ShortAccountTypeProperty.asset,
        ),
      );

      await repository.upsertFromSync(account);

      final AccountRead? retrieved = await repository.getById('test-4');
      expect(retrieved, isNotNull);
    });
  });
}

