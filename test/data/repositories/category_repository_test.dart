import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/category_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

void main() {
  group('CategoryRepository', () {
    late Isar isar;
    late CategoryRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = CategoryRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no categories', () async {
      final List<CategoryRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when category not found', () async {
      final CategoryRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores category', () async {
      final CategoryRead category = CategoryRead(
        type: 'categories',
        id: 'test-1',
        attributes: CategoryProperties(
          name: 'Test Category',
        ),
      );

      await repository.create(category);

      final CategoryRead? retrieved = await repository.getById('test-1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, 'test-1');
      expect(retrieved.attributes.name, 'Test Category');
    });

    test('search finds categories by query', () async {
      final CategoryRead category1 = CategoryRead(
        type: 'categories',
        id: 'test-2',
        attributes: CategoryProperties(
          name: 'Food',
        ),
      );

      final CategoryRead category2 = CategoryRead(
        type: 'categories',
        id: 'test-3',
        attributes: CategoryProperties(
          name: 'Transport',
        ),
      );

      await repository.create(category1);
      await repository.create(category2);

      final List<CategoryRead> results = await repository.search('Food');
      expect(results.length, 1);
      expect(results.first.id, 'test-2');
    });

    test('autocomplete returns matching category names', () async {
      final CategoryRead category1 = CategoryRead(
        type: 'categories',
        id: 'test-4',
        attributes: CategoryProperties(
          name: 'Food & Dining',
        ),
      );

      final CategoryRead category2 = CategoryRead(
        type: 'categories',
        id: 'test-5',
        attributes: CategoryProperties(
          name: 'Transportation',
        ),
      );

      await repository.create(category1);
      await repository.create(category2);

      final List<String> results = await repository.autocomplete('Food');
      expect(results, contains('Food & Dining'));
    });
  });
}

