import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/currencies.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class CurrencyRepository {
  final Isar isar;

  CurrencyRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<CurrencyRead>> getAll() async {
    final List<Currencies> allRows = await isar.currencies.where().findAll();
    final List<Currencies> rows = allRows
        .where((Currencies r) => r.deletedAt == null)
        .toList();
    rows.sort((Currencies a, Currencies b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((Currencies row) {
      return CurrencyRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<CurrencyRead?> getById(String id) async {
    final Currencies? row = await isar.currencies
        .filter()
        .currencyIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    if (row.deletedAt != null) return null;
    final CurrencyRead currency = CurrencyRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
    return currency;
  }

  Future<List<CurrencyRead>> search(String query) async {
    final List<CurrencyRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((CurrencyRead currency) {
      // Search in currency name and code directly (most common case)
      if (currency.attributes.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      if (currency.attributes.code.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(currency.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<CurrencyRead>> getByDateRange(DateTime start, DateTime end) {
    return getAll();
  }

  Future<void> create(CurrencyRead currency) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = currency.attributes.updatedAt;

    final Currencies row = Currencies()
      ..currencyId = currency.id
      ..data = jsonEncode(currency.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = false;

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'currencies'
      ..entityId = null
      ..operation = PendingChangeOperation.create.name
      ..data = jsonEncode(currency.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.currencies.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(CurrencyRead currency) async {
    final DateTime now = _getNow();

    final Currencies? existing = await isar.currencies
        .filter()
        .currencyIdEqualTo(currency.id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'currencies'
      ..entityId = currency.id
      ..operation = PendingChangeOperation.update.name
      ..data = jsonEncode(currency.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(currency.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.currencies.put(existing);
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

    final Currencies? existing = await isar.currencies
        .filter()
        .currencyIdEqualTo(id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'currencies'
      ..entityId = id
      ..operation = PendingChangeOperation.delete.name
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.currencies.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertFromSync(CurrencyRead currency) async {
    final DateTime? updatedAt = currency.attributes.updatedAt;
    final DateTime now = _getNow();

    // Check if currency already exists
    final Currencies? existing = await isar.currencies
        .filter()
        .currencyIdEqualTo(currency.id)
        .findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final Currencies row;
    if (existing != null) {
      // Update existing currency
      row = existing
        ..data = jsonEncode(currency.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;
    } else {
      // Create new currency
      row = Currencies()
        ..currencyId = currency.id
        ..data = jsonEncode(currency.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.currencies.put(row);
    });
  }
}
