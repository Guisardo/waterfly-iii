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
    final List<Categories> allRows = await isar.categories.where().findAll();
    final List<Categories> rows = allRows
        .where((Categories r) => r.deletedAt == null)
        .toList();
    rows.sort((Categories a, Categories b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((Categories row) {
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
    if (row.deletedAt != null) return null;
    return CategoryRead.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
  }

  Future<List<CategoryRead>> search(String query) async {
    final List<CategoryRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((CategoryRead category) {
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
    return categories
        .map((CategoryRead category) => category.attributes.name)
        .toList();
  }

  Future<List<CategoryRead>> getByDateRange(DateTime start, DateTime end) {
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

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'categories'
      ..entityId = null
      ..operation = PendingChangeOperation.create.name
      ..data = jsonEncode(category.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false
      ..localPendingId = category.id.startsWith('pending-')
          ? category.id
          : null;

    await isar.writeTxn(() async {
      await isar.categories.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(CategoryRead category) async {
    final DateTime now = _getNow();

    final Categories? existing = await isar.categories
        .filter()
        .categoryIdEqualTo(category.id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'categories'
      ..entityId = category.id
      ..operation = PendingChangeOperation.update.name
      ..data = jsonEncode(category.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(category.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.categories.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final Categories? existing = await isar.categories
        .filter()
        .categoryIdEqualTo(id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'categories'
      ..entityId = id
      ..operation = PendingChangeOperation.delete.name
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.categories.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertFromSync(CategoryRead category) async {
    final DateTime? updatedAt = category.attributes.updatedAt;
    final DateTime now = _getNow();

    final Categories? existing = await isar.categories
        .filter()
        .categoryIdEqualTo(category.id)
        .findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final Categories row;
    if (existing != null) {
      row = existing
        ..data = jsonEncode(category.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;
    } else {
      row = Categories()
        ..categoryId = category.id
        ..data = jsonEncode(category.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.categories.put(row);
    });
  }
}
