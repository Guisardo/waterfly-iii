import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/bills.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class BillRepository {
  final Isar isar;

  BillRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<BillRead>> getAll() async {
    final List<Bills> allRows = await isar.bills.where().findAll();
    final List<Bills> rows =
        allRows.where((Bills r) => r.deletedAt == null).toList();
    rows.sort((Bills a, Bills b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((Bills row) {
      return BillRead.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
    }).toList();
  }

  Future<BillRead?> getById(String id) async {
    final Bills? row = await isar.bills.filter().billIdEqualTo(id).findFirst();
    if (row == null) {
      return null;
    }
    if (row.deletedAt != null) return null;
    return BillRead.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
  }

  Future<List<BillRead>> search(String query) async {
    final List<BillRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((BillRead bill) {
      // Search in bill name directly (most common case)
      if (bill.attributes.name?.toLowerCase().contains(queryLower) ?? false) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(bill.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<BillRead>> getByDateRange(DateTime start, DateTime end) {
    return getAll();
  }

  Future<void> create(BillRead bill) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = bill.attributes.updatedAt;

    final Bills row =
        Bills()
          ..billId = bill.id
          ..data = jsonEncode(bill.toJson())
          ..updatedAt = updatedAt
          ..localUpdatedAt = now
          ..synced = false;

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'bills'
          ..entityId = null
          ..operation = PendingChangeOperation.create.name
          ..data = jsonEncode(bill.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.bills.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(BillRead bill) async {
    final DateTime now = _getNow();

    final Bills? existing =
        await isar.bills.filter().billIdEqualTo(bill.id).findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'bills'
          ..entityId = bill.id
          ..operation = PendingChangeOperation.update.name
          ..data = jsonEncode(bill.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(bill.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.bills.put(existing);
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

    final Bills? existing =
        await isar.bills.filter().billIdEqualTo(id).findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'bills'
          ..entityId = id
          ..operation = PendingChangeOperation.delete.name
          ..data = null
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.bills.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertFromSync(BillRead bill) async {
    final DateTime? updatedAt = bill.attributes.updatedAt;
    final DateTime now = _getNow();

    final Bills? existing =
        await isar.bills.filter().billIdEqualTo(bill.id).findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final Bills row;
    if (existing != null) {
      row =
          existing
            ..data = jsonEncode(bill.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    } else {
      row =
          Bills()
            ..billId = bill.id
            ..data = jsonEncode(bill.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.bills.put(row);
    });
  }
}
