import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/budget_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

void main() {
  group('BudgetRepository', () {
    late Isar isar;
    late BudgetRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = BudgetRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no budgets', () async {
      final List<BudgetRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when budget not found', () async {
      final BudgetRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores budget', () async {
      final BudgetRead budget = BudgetRead(
        type: 'budgets',
        id: 'test-1',
        attributes: BudgetProperties(
          name: 'Test Budget',
        ),
      );

      await repository.create(budget);

      final BudgetRead? retrieved = await repository.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');
      expect(retrieved.attributes.name, 'Test Budget');
    });

    test('search finds budgets by query', () async {
      final BudgetRead budget1 = BudgetRead(
        type: 'budgets',
        id: 'test-2',
        attributes: BudgetProperties(
          name: 'Groceries Budget',
        ),
      );

      final BudgetRead budget2 = BudgetRead(
        type: 'budgets',
        id: 'test-3',
        attributes: BudgetProperties(
          name: 'Entertainment Budget',
        ),
      );

      await repository.create(budget1);
      await repository.create(budget2);

      final List<BudgetRead> results = await repository.search('Groceries');
      expect(results.length, 1);
      expect(results.first.id, 'test-2');
    });

    test('autocomplete returns AutocompleteBudget list', () async {
      final BudgetRead budget = BudgetRead(
        type: 'budgets',
        id: 'test-4',
        attributes: BudgetProperties(
          name: 'Test Budget',
        ),
      );

      await repository.create(budget);

      final List<AutocompleteBudget> results = await repository.autocomplete('Test');
      expect(results.length, 1);
      expect(results.first.id, 'test-4');
      expect(results.first.name, 'Test Budget');
    });

    test('upsertFromSync creates new budget if not exists', () async {
      final BudgetRead budget = BudgetRead(
        type: 'budgets',
        id: 'test-5',
        attributes: BudgetProperties(
          name: 'Synced Budget',
        ),
      );

      await repository.upsertFromSync(budget);

      final BudgetRead? retrieved = await repository.getById('test-5');
      expect(retrieved, isNotNull);
    });
  });
}

