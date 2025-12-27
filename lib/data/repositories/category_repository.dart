import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/categories.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class CategoryRepository {
  final Isar isar;

  CategoryRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<CategoryRead>> getAll() async {
    final List<Categories> rows = await isar.categories.where().findAll();
    rows.sort((a, b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((row) {
      return CategoryRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<CategoryRead?> getById(String id) async {
    final Categories? row = await isar.categories
        .filter()
        .categoryIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    return CategoryRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<List<CategoryRead>> search(String query) async {
    final List<CategoryRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((category) {
      // Search in category name directly (most common case)
      if (category.attributes.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(category.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<String>> autocomplete(String query) async {
    final List<CategoryRead> categories = await search(query);
    return categories.map((category) => category.attributes.name).toList();
  }

  Future<List<CategoryRead>> getByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    // Categories don't have date ranges, return all
    return getAll();
  }

  Future<void> create(CategoryRead category) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = category.attributes.updatedAt;

    final Categories row = Categories()
      ..categoryId = category.id
      ..data = jsonEncode(category.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.categories.put(row);
    });

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'categories'
      ..entityId = null
      ..operation = 'CREATE'
      ..data = jsonEncode(category.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(CategoryRead category) async {
    final DateTime now = _getNow();

    final Categories? existing = await isar.categories
        .filter()
        .categoryIdEqualTo(category.id)
        .findFirst();

    if (existing != null) {
      existing
        ..data = jsonEncode(category.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.categories.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'categories'
      ..entityId = category.id
      ..operation = 'UPDATE'
      ..data = jsonEncode(category.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final Categories? existing = await isar.categories
        .filter()
        .categoryIdEqualTo(id)
        .findFirst();

    if (existing != null) {
      existing..synced = false;

      await isar.writeTxn(() async {
        await isar.categories.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'categories'
      ..entityId = id
      ..operation = 'DELETE'
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> upsertFromSync(CategoryRead category) async {
    final DateTime? updatedAt = category.attributes.updatedAt;
    final DateTime now = _getNow();

    final Categories row = Categories()
      ..categoryId = category.id
      ..data = jsonEncode(category.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = true;

    await isar.writeTxn(() async {
      await isar.categories.put(row);
    });
  }
}
