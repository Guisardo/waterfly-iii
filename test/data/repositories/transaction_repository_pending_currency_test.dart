import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/account_repository.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart'
    as enums;
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

import '../../helpers/test_database.dart';

TransactionStore _store({
  required enums.TransactionTypeProperty type,
  String? sourceId,
  String? destinationId,
  String? currencyCode,
}) => TransactionStore(
  transactions: <TransactionSplitStore>[
    TransactionSplitStore(
      type: type,
      date: DateTime(2026, 5, 1, 12, 30),
      amount: '98617.22',
      description: 'Pending row',
      currencyCode: currencyCode,
      sourceId: sourceId,
      sourceName: 'Source',
      destinationId: destinationId,
      destinationName: 'Destination',
    ),
  ],
  applyRules: true,
  fireWebhooks: true,
  errorIfDuplicateHash: true,
);

Future<void> _createAsset(Isar isar, String id) async {
  await AccountRepository(isar).create(
    AccountRead(
      type: 'accounts',
      id: id,
      attributes: AccountProperties(
        name: 'Amex',
        type: enums.ShortAccountTypeProperty.asset,
        currencyId: '7',
        currencyCode: 'ARS',
        currencyName: 'Argentine Peso',
        currencySymbol: r'$',
        currencyDecimalPlaces: 2,
      ),
    ),
  );
}

void main() {
  group('TransactionRepository pending currency', () {
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

    Future<TransactionSplit> listedSplit() async {
      final List<TransactionRead> rows = await repository.getByDateRange(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 2),
      );
      expect(rows, hasLength(1));
      return rows.first.attributes.transactions.first;
    }

    test('withdrawal row takes the currency of the source account', () async {
      await _createAsset(isar, 'acc-1');
      await repository.createNew(
        _store(
          type: enums.TransactionTypeProperty.withdrawal,
          sourceId: 'acc-1',
        ),
      );
      final TransactionSplit split = await listedSplit();
      expect(split.currencySymbol, r'$');
      expect(split.currencyCode, 'ARS');
      expect(split.currencyId, '7');
      expect(split.currencyDecimalPlaces, 2);
    });

    test('deposit row takes the currency of the destination account', () async {
      await _createAsset(isar, 'acc-1');
      await repository.createNew(
        _store(
          type: enums.TransactionTypeProperty.deposit,
          sourceId: 'revenue-1',
          destinationId: 'acc-1',
        ),
      );
      final TransactionSplit split = await listedSplit();
      expect(split.currencySymbol, r'$');
      expect(split.currencyCode, 'ARS');
    });

    test('getAll also resolves the currency of pending rows', () async {
      await _createAsset(isar, 'acc-1');
      await repository.createNew(
        _store(
          type: enums.TransactionTypeProperty.withdrawal,
          sourceId: 'acc-1',
        ),
      );
      final List<TransactionRead> rows = await repository.getAll();
      expect(rows, hasLength(1));
      expect(rows.first.attributes.transactions.first.currencySymbol, r'$');
    });

    test('keeps current behavior when the account is unknown', () async {
      await repository.createNew(
        _store(
          type: enums.TransactionTypeProperty.withdrawal,
          sourceId: 'missing',
        ),
      );
      final TransactionSplit split = await listedSplit();
      expect(split.currencySymbol, '');
    });

    test('does not override a currency already present in the store', () async {
      await _createAsset(isar, 'acc-1');
      await repository.createNew(
        _store(
          type: enums.TransactionTypeProperty.withdrawal,
          sourceId: 'acc-1',
          currencyCode: 'USD',
        ),
      );
      final TransactionSplit split = await listedSplit();
      expect(split.currencyCode, 'USD');
    });
  });
}
