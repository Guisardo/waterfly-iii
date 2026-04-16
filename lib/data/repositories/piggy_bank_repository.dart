import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/piggy_banks.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class PiggyBankRepository {
  final Isar isar;

  PiggyBankRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<PiggyBankRead>> getAll() async {
    final List<PiggyBanks> allRows = await isar.piggyBanks.where().findAll();
    final List<PiggyBanks> rows =
        allRows.where((PiggyBanks r) => r.deletedAt == null).toList();
    rows.sort((PiggyBanks a, PiggyBanks b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((PiggyBanks row) {
      return PiggyBankRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<PiggyBankRead?> getById(String id) async {
    final PiggyBanks? row =
        await isar.piggyBanks.filter().piggyBankIdEqualTo(id).findFirst();
    if (row == null) {
      return null;
    }
    if (row.deletedAt != null) return null;
    final PiggyBankRead piggyBank = PiggyBankRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
    return piggyBank;
  }

  Future<List<PiggyBankRead>> search(String query) async {
    final List<PiggyBankRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((PiggyBankRead piggyBank) {
      // Search in piggy bank name directly (most common case)
      if (piggyBank.attributes.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(piggyBank.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<PiggyBankRead>> getByDateRange(DateTime start, DateTime end) {
    return getAll();
  }

  Future<void> create(PiggyBankRead piggyBank) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = piggyBank.attributes.updatedAt;

    final PiggyBanks row =
        PiggyBanks()
          ..piggyBankId = piggyBank.id
          ..data = jsonEncode(piggyBank.toJson())
          ..updatedAt = updatedAt
          ..localUpdatedAt = now
          ..synced = false;

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'piggy_banks'
          ..entityId = null
          ..operation = PendingChangeOperation.create.name
          ..data = jsonEncode(piggyBank.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.piggyBanks.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(PiggyBankRead piggyBank) async {
    final DateTime now = _getNow();

    final PiggyBanks? existing =
        await isar.piggyBanks
            .filter()
            .piggyBankIdEqualTo(piggyBank.id)
            .findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'piggy_banks'
          ..entityId = piggyBank.id
          ..operation = PendingChangeOperation.update.name
          ..data = jsonEncode(piggyBank.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(piggyBank.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.piggyBanks.put(existing);
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

    final PiggyBanks? existing =
        await isar.piggyBanks.filter().piggyBankIdEqualTo(id).findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'piggy_banks'
          ..entityId = id
          ..operation = PendingChangeOperation.delete.name
          ..data = null
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.piggyBanks.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertFromSync(PiggyBankRead piggyBank) async {
    final DateTime? updatedAt = piggyBank.attributes.updatedAt;
    final DateTime now = _getNow();

    final PiggyBanks? existing =
        await isar.piggyBanks
            .filter()
            .piggyBankIdEqualTo(piggyBank.id)
            .findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final PiggyBanks row;
    if (existing != null) {
      row =
          existing
            ..data = jsonEncode(piggyBank.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    } else {
      row =
          PiggyBanks()
            ..piggyBankId = piggyBank.id
            ..data = jsonEncode(piggyBank.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.piggyBanks.put(row);
    });
  }
}
