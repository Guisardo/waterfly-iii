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
    final List<PiggyBanks> rows = await isar.piggyBanks.where().findAll();
    rows.sort((a, b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((row) {
      return PiggyBankRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<PiggyBankRead?> getById(String id) async {
    final PiggyBanks? row = await isar.piggyBanks
        .filter()
        .piggyBankIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    return PiggyBankRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<List<PiggyBankRead>> search(String query) async {
    final List<PiggyBankRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((piggyBank) {
      // Search in piggy bank name directly (most common case)
      if (piggyBank.attributes.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(piggyBank.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<PiggyBankRead>> getByDateRange(DateTime start, DateTime end) async {
    return getAll();
  }

  Future<void> create(PiggyBankRead piggyBank) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = piggyBank.attributes.updatedAt;

    final PiggyBanks row = PiggyBanks()
      ..piggyBankId = piggyBank.id
      ..data = jsonEncode(piggyBank.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.piggyBanks.put(row);
    });

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'piggy_banks'
      ..entityId = null
      ..operation = 'CREATE'
      ..data = jsonEncode(piggyBank.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(PiggyBankRead piggyBank) async {
    final DateTime now = _getNow();

    final PiggyBanks? existing = await isar.piggyBanks
        .filter()
        .piggyBankIdEqualTo(piggyBank.id)
        .findFirst();

    if (existing != null) {
      existing
        ..data = jsonEncode(piggyBank.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.piggyBanks.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'piggy_banks'
      ..entityId = piggyBank.id
      ..operation = 'UPDATE'
      ..data = jsonEncode(piggyBank.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final PiggyBanks? existing = await isar.piggyBanks
        .filter()
        .piggyBankIdEqualTo(id)
        .findFirst();

    if (existing != null) {
      existing..synced = false;

      await isar.writeTxn(() async {
        await isar.piggyBanks.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'piggy_banks'
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

  Future<void> upsertFromSync(PiggyBankRead piggyBank) async {
    final DateTime? updatedAt = piggyBank.attributes.updatedAt;
    final DateTime now = _getNow();

    final PiggyBanks row = PiggyBanks()
      ..piggyBankId = piggyBank.id
      ..data = jsonEncode(piggyBank.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = true;

    await isar.writeTxn(() async {
      await isar.piggyBanks.put(row);
    });
  }
}
