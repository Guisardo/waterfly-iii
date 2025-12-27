import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/repositories/tag_repository.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import '../../helpers/test_database.dart';

void main() {
  group('TagRepository', () {
    late Isar isar;
    late TagRepository repository;

    setUpAll(() async {
      isar = await TestDatabase.instance;
      await TestDatabase.clear();
    });

    setUp(() async {
      repository = TagRepository(isar);
      await TestDatabase.clear();
    });

    tearDownAll(() async {
      await TestDatabase.close();
    });

    test('getAll returns empty list when no tags', () async {
      final List<TagRead> result = await repository.getAll();
      expect(result, isEmpty);
    });

    test('getById returns null when tag not found', () async {
      final TagRead? result = await repository.getById('nonexistent');
      expect(result, isNull);
    });

    test('create stores tag', () async {
      final TagRead tag = TagRead(
        type: 'tags',
        id: '1',
        attributes: TagModel(
          tag: 'test-tag',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/tags/1'),
      );

      await repository.create(tag);

      final TagRead? retrieved = await repository.getById('1');
      expect(retrieved, isNotNull);
      expect(retrieved!.id, '1');
      expect(retrieved.attributes.tag, 'test-tag');
    });

    test('search finds tags by query', () async {
      final TagRead tag1 = TagRead(
        type: 'tags',
        id: '2',
        attributes: TagModel(
          tag: 'groceries',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/tags/2'),
      );

      final TagRead tag2 = TagRead(
        type: 'tags',
        id: '3',
        attributes: TagModel(
          tag: 'restaurant',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/tags/3'),
      );

      await repository.create(tag1);
      await repository.create(tag2);

      final List<TagRead> results = await repository.search('groceries');
      expect(results.length, 1);
      expect(results.first.id, '2');
    });

    test('upsertFromSync creates new tag if not exists', () async {
      final TagRead tag = TagRead(
        type: 'tags',
        id: '4',
        attributes: TagModel(
          tag: 'synced-tag',
        ),
        links: ObjectLink(self: 'https://example.com/api/v1/tags/4'),
      );

      await repository.upsertFromSync(tag);

      final TagRead? retrieved = await repository.getById('4');
      expect(retrieved, isNotNull);
    });
  });
}

