import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/tags.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class TagRepository {
  final Isar isar;

  TagRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<TagRead>> getAll() async {
    final List<Tags> allRows = await isar.tags.where().findAll();
    final List<Tags> rows = allRows
        .where((Tags r) => r.deletedAt == null)
        .toList();
    rows.sort((Tags a, Tags b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((Tags row) {
      return TagRead.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
    }).toList();
  }

  Future<TagRead?> getById(String id) async {
    final Tags? row = await isar.tags.filter().tagIdEqualTo(id).findFirst();
    if (row == null) {
      return null;
    }
    if (row.deletedAt != null) return null;
    final TagRead tag = TagRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
    return tag;
  }

  Future<List<TagRead>> search(String query) async {
    final List<TagRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((TagRead tag) {
      // Search in tag name directly (most common case)
      if (tag.attributes.tag.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(tag.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<TagRead>> getByDateRange(DateTime start, DateTime end) {
    return getAll();
  }

  Future<void> create(TagRead tag) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = tag.attributes.updatedAt;

    final Tags row = Tags()
      ..tagId = tag.id
      ..data = jsonEncode(tag.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = false;

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'tags'
      ..entityId = null
      ..operation = PendingChangeOperation.create.name
      ..data = jsonEncode(tag.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.tags.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(TagRead tag) async {
    final DateTime now = _getNow();

    final Tags? existing = await isar.tags
        .filter()
        .tagIdEqualTo(tag.id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'tags'
      ..entityId = tag.id
      ..operation = PendingChangeOperation.update.name
      ..data = jsonEncode(tag.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(tag.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.tags.put(existing);
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

    final Tags? existing = await isar.tags
        .filter()
        .tagIdEqualTo(id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'tags'
      ..entityId = id
      ..operation = PendingChangeOperation.delete.name
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.tags.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertFromSync(TagRead tag) async {
    final DateTime? updatedAt = tag.attributes.updatedAt;
    final DateTime now = _getNow();

    final Tags? existing = await isar.tags
        .filter()
        .tagIdEqualTo(tag.id)
        .findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final Tags row;
    if (existing != null) {
      row = existing
        ..data = jsonEncode(tag.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;
    } else {
      row = Tags()
        ..tagId = tag.id
        ..data = jsonEncode(tag.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.tags.put(row);
    });
  }
}
