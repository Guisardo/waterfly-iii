import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/budgets.dart';
import 'package:waterflyiii/data/local/database/tables/budget_limits.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart'
    show BudgetRead, AutocompleteBudget, BudgetLimitRead;

class BudgetRepository {
  final Isar isar;

  BudgetRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<BudgetRead>> getAll() async {
    final List<Budgets> allRows = await isar.budgets.where().findAll();
    final List<Budgets> rows =
        allRows.where((Budgets r) => r.deletedAt == null).toList();
    rows.sort((Budgets a, Budgets b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((Budgets row) {
      return BudgetRead.fromJson(jsonDecode(row.data) as Map<String, dynamic>);
    }).toList();
  }

  Future<BudgetRead?> getById(String id) async {
    final Budgets? row =
        await isar.budgets.filter().budgetIdEqualTo(id).findFirst();
    if (row == null) {
      return null;
    }
    if (row.deletedAt != null) return null;
    final BudgetRead budget = BudgetRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
    return budget;
  }

  Future<List<BudgetRead>> search(String query) async {
    final List<BudgetRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((BudgetRead budget) {
      // Search in budget name directly (most common case)
      if (budget.attributes.name.toLowerCase().contains(queryLower)) {
        return true;
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(budget.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<AutocompleteBudget>> autocomplete(String query) async {
    final List<BudgetRead> budgets = await search(query);
    return budgets.map((BudgetRead budget) {
      return AutocompleteBudget(id: budget.id, name: budget.attributes.name);
    }).toList();
  }

  Future<List<BudgetRead>> getByDateRange(DateTime start, DateTime end) {
    return getAll();
  }

  Future<void> create(BudgetRead budget) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = budget.attributes.updatedAt;

    final Budgets row =
        Budgets()
          ..budgetId = budget.id
          ..data = jsonEncode(budget.toJson())
          ..updatedAt = updatedAt
          ..localUpdatedAt = now
          ..synced = false;

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'budgets'
          ..entityId = null
          ..operation = PendingChangeOperation.create.name
          ..data = jsonEncode(budget.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.budgets.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(BudgetRead budget) async {
    final DateTime now = _getNow();

    final Budgets? existing =
        await isar.budgets.filter().budgetIdEqualTo(budget.id).findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'budgets'
          ..entityId = budget.id
          ..operation = PendingChangeOperation.update.name
          ..data = jsonEncode(budget.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(budget.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.budgets.put(existing);
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

    final Budgets? existing =
        await isar.budgets.filter().budgetIdEqualTo(id).findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'budgets'
          ..entityId = id
          ..operation = PendingChangeOperation.delete.name
          ..data = null
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.budgets.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertFromSync(BudgetRead budget) async {
    final DateTime? updatedAt = budget.attributes.updatedAt;
    final DateTime now = _getNow();

    final Budgets? existing =
        await isar.budgets.filter().budgetIdEqualTo(budget.id).findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final Budgets row;
    if (existing != null) {
      row =
          existing
            ..data = jsonEncode(budget.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    } else {
      row =
          Budgets()
            ..budgetId = budget.id
            ..data = jsonEncode(budget.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.budgets.put(row);
    });
  }

  // Budget Limits methods
  Future<List<BudgetLimitRead>> getAllBudgetLimits() async {
    final List<BudgetLimits> rows = await isar.budgetLimits.where().findAll();
    rows.sort((BudgetLimits a, BudgetLimits b) {
      final DateTime dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime dateB = b.updatedAt ?? b.localUpdatedAt;
      return dateB.compareTo(dateA);
    });

    return rows.map((BudgetLimits row) {
      return BudgetLimitRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<List<BudgetLimitRead>> getBudgetLimitsByBudgetId(
    String budgetId,
  ) async {
    final List<BudgetLimitRead> all = await getAllBudgetLimits();
    return all
        .where((BudgetLimitRead limit) => limit.attributes.budgetId == budgetId)
        .toList();
  }

  Future<List<BudgetLimitRead>> getBudgetLimitsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final List<BudgetLimitRead> all = await getAllBudgetLimits();
    return all.where((BudgetLimitRead limit) {
      final DateTime? limitStart = limit.attributes.start;
      final DateTime? limitEnd = limit.attributes.end;
      if (limitStart == null || limitEnd == null) {
        return false;
      }
      // Check if limit overlaps with the date range
      return (limitStart.isBefore(end) || limitStart.isAtSameMomentAs(end)) &&
          (limitEnd.isAfter(start) || limitEnd.isAtSameMomentAs(start));
    }).toList();
  }

  Future<BudgetLimitRead?> getBudgetLimitById(String id) async {
    final BudgetLimits? row =
        await isar.budgetLimits.filter().budgetLimitIdEqualTo(id).findFirst();
    if (row == null) {
      return null;
    }
    return BudgetLimitRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<void> createBudgetLimit(BudgetLimitRead budgetLimit) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = budgetLimit.attributes.updatedAt;

    final BudgetLimits row =
        BudgetLimits()
          ..budgetLimitId = budgetLimit.id
          ..data = jsonEncode(budgetLimit.toJson())
          ..updatedAt = updatedAt
          ..localUpdatedAt = now
          ..synced = false;

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'budget_limits'
          ..entityId = null
          ..operation = PendingChangeOperation.create.name
          ..data = jsonEncode(budgetLimit.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.budgetLimits.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> updateBudgetLimit(BudgetLimitRead budgetLimit) async {
    final DateTime now = _getNow();

    final BudgetLimits? existing =
        await isar.budgetLimits
            .filter()
            .budgetLimitIdEqualTo(budgetLimit.id)
            .findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'budget_limits'
          ..entityId = budgetLimit.id
          ..operation = PendingChangeOperation.update.name
          ..data = jsonEncode(budgetLimit.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(budgetLimit.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.budgetLimits.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> deleteBudgetLimit(String id) async {
    final DateTime now = _getNow();

    final BudgetLimits? existing =
        await isar.budgetLimits.filter().budgetLimitIdEqualTo(id).findFirst();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'budget_limits'
          ..entityId = id
          ..operation = PendingChangeOperation.delete.name
          ..data = null
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    if (existing != null) {
      existing.synced = false;

      await isar.writeTxn(() async {
        await isar.budgetLimits.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  Future<void> upsertBudgetLimitFromSync(BudgetLimitRead budgetLimit) async {
    final DateTime? updatedAt = budgetLimit.attributes.updatedAt;
    final DateTime now = _getNow();

    final BudgetLimits row =
        BudgetLimits()
          ..budgetLimitId = budgetLimit.id
          ..data = jsonEncode(budgetLimit.toJson())
          ..updatedAt = updatedAt
          ..localUpdatedAt = now
          ..synced = true;

    await isar.writeTxn(() async {
      await isar.budgetLimits.put(row);
    });
  }
}
