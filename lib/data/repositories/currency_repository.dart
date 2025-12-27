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
    final List<Currencies> rows = await isar.currencies.where().findAll();
    rows.sort((a, b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((row) {
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
    return CurrencyRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<List<CurrencyRead>> search(String query) async {
    final List<CurrencyRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((currency) {
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

  Future<List<CurrencyRead>> getByDateRange(DateTime start, DateTime end) async {
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

    await isar.writeTxn(() async {
      await isar.currencies.put(row);
    });

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'currencies'
      ..entityId = null
      ..operation = 'CREATE'
      ..data = jsonEncode(currency.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(CurrencyRead currency) async {
    final DateTime now = _getNow();

    final Currencies? existing = await isar.currencies
        .filter()
        .currencyIdEqualTo(currency.id)
        .findFirst();

    if (existing != null) {
      existing
        ..data = jsonEncode(currency.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.currencies.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'currencies'
      ..entityId = currency.id
      ..operation = 'UPDATE'
      ..data = jsonEncode(currency.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final Currencies? existing = await isar.currencies
        .filter()
        .currencyIdEqualTo(id)
        .findFirst();

    if (existing != null) {
      existing..synced = false;

      await isar.writeTxn(() async {
        await isar.currencies.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'currencies'
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

  Future<void> upsertFromSync(CurrencyRead currency) async {
    final DateTime? updatedAt = currency.attributes.updatedAt;
    final DateTime now = _getNow();

    final Currencies row = Currencies()
      ..currencyId = currency.id
      ..data = jsonEncode(currency.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = true;

    await isar.writeTxn(() async {
      await isar.currencies.put(row);
    });
  }
}
