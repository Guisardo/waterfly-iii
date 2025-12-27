import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class TransactionRepository {
  final Isar isar;

  TransactionRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  Future<List<TransactionRead>> getAll() async {
    final List<Transactions> rows = await isar.transactions.where().findAll();
    rows.sort((a, b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    return rows.map((row) {
      return TransactionRead.fromJson(
        jsonDecode(row.data) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<TransactionRead?> getById(String id) async {
    final Transactions? row = await isar.transactions
        .filter()
        .transactionIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    return TransactionRead.fromJson(
      jsonDecode(row.data) as Map<String, dynamic>,
    );
  }

  Future<List<TransactionRead>> search(String query) async {
    final List<TransactionRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((transaction) {
      // Search in transaction descriptions directly (most common case)
      for (final TransactionSplit split in transaction.attributes.transactions) {
        if (split.description.toLowerCase().contains(queryLower)) {
          return true;
        }
      }
      // Also search in JSON representation for other fields
      final String json = jsonEncode(transaction.toJson());
      return json.toLowerCase().contains(queryLower);
    }).toList();
  }

  Future<List<TransactionRead>> getByDateRange(
    DateTime start,
    DateTime end, {
    int? page,
    int? limit,
  }) async {
    final List<TransactionRead> all = await getAll();
    final List<TransactionRead> filtered = all.where((transaction) {
      final DateTime? date = transaction.attributes.transactions.firstOrNull?.date;
      if (date == null) {
        return false;
      }
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();

    // Sort by date descending (newest first)
    filtered.sort((a, b) {
      final DateTime? dateA = a.attributes.transactions.firstOrNull?.date;
      final DateTime? dateB = b.attributes.transactions.firstOrNull?.date;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    // Apply pagination
    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= filtered.length) {
        return <TransactionRead>[];
      }
      return filtered.sublist(
        startIndex,
        endIndex > filtered.length ? filtered.length : endIndex,
      );
    }

    return filtered;
  }

  Future<List<TransactionRead>> getByAccount(
    String accountId,
    DateTime? start,
    DateTime? end, {
    int? page,
    int? limit,
  }) async {
    final List<TransactionRead> all = await getAll();
    final List<TransactionRead> filtered = all.where((transaction) {
      // Check if transaction involves this account
      bool involvesAccount = false;
      for (final TransactionSplit split in transaction.attributes.transactions) {
        if (split.sourceId == accountId || split.destinationId == accountId) {
          involvesAccount = true;
          break;
        }
      }

      if (!involvesAccount) {
        return false;
      }

      // Apply date filter if provided
      if (start != null || end != null) {
        final DateTime? date = transaction.attributes.transactions.firstOrNull?.date;
        if (date == null) {
          return false;
        }
        if (start != null && date.isBefore(start.subtract(const Duration(days: 1)))) {
          return false;
        }
        if (end != null && date.isAfter(end.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date descending
    filtered.sort((a, b) {
      final DateTime? dateA = a.attributes.transactions.firstOrNull?.date;
      final DateTime? dateB = b.attributes.transactions.firstOrNull?.date;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    // Apply pagination
    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= filtered.length) {
        return <TransactionRead>[];
      }
      return filtered.sublist(
        startIndex,
        endIndex > filtered.length ? filtered.length : endIndex,
      );
    }

    return filtered;
  }

  Future<List<TransactionRead>> searchWithFilters({
    String? text,
    String? accountId,
    String? currencyCode,
    String? categoryId,
    String? categoryName,
    String? budgetId,
    String? budgetName,
    String? billId,
    String? billName,
    List<String>? tags,
    DateTime? startDate,
    DateTime? endDate,
    int? page,
    int? limit,
  }) async {
    final List<TransactionRead> all = await getAll();
    final List<TransactionRead> filtered = all.where((transaction) {
      // Text search
      if (text != null && text.isNotEmpty) {
        final String json = jsonEncode(transaction.toJson()).toLowerCase();
        if (!json.contains(text.toLowerCase())) {
          return false;
        }
      }

      // Account filter
      if (accountId != null) {
        bool hasAccount = false;
        for (final TransactionSplit split in transaction.attributes.transactions) {
          if (split.sourceId == accountId || split.destinationId == accountId) {
            hasAccount = true;
            break;
          }
        }
        if (!hasAccount) {
          return false;
        }
      }

      // Currency filter
      if (currencyCode != null) {
        bool hasCurrency = false;
        for (final TransactionSplit split in transaction.attributes.transactions) {
          if (split.currencyCode == currencyCode) {
            hasCurrency = true;
            break;
          }
        }
        if (!hasCurrency) {
          return false;
        }
      }

      // Category filter
      if (categoryId != null) {
        if (categoryId == "-1") {
          // No category
          if (transaction.attributes.transactions.firstOrNull?.categoryId != null) {
            return false;
          }
        } else {
          bool hasCategory = false;
          for (final TransactionSplit split in transaction.attributes.transactions) {
            if (split.categoryId == categoryId) {
              hasCategory = true;
              break;
            }
          }
          if (!hasCategory) {
            return false;
          }
        }
      } else if (categoryName != null) {
        bool hasCategory = false;
        for (final TransactionSplit split in transaction.attributes.transactions) {
          if (split.categoryName == categoryName) {
            hasCategory = true;
            break;
          }
        }
        if (!hasCategory) {
          return false;
        }
      }

      // Budget filter
      if (budgetId != null) {
        if (budgetId == "-1") {
          // No budget
          if (transaction.attributes.transactions.firstOrNull?.budgetId != null) {
            return false;
          }
        } else {
          bool hasBudget = false;
          for (final TransactionSplit split in transaction.attributes.transactions) {
            if (split.budgetId == budgetId) {
              hasBudget = true;
              break;
            }
          }
          if (!hasBudget) {
            return false;
          }
        }
      } else if (budgetName != null) {
        bool hasBudget = false;
        for (final TransactionSplit split in transaction.attributes.transactions) {
          if (split.budgetName == budgetName) {
            hasBudget = true;
            break;
          }
        }
        if (!hasBudget) {
          return false;
        }
      }

      // Bill filter
      if (billId != null) {
        if (billId == "-1") {
          // No bill
          if (transaction.attributes.transactions.firstOrNull?.billId != null) {
            return false;
          }
        } else {
          bool hasBill = false;
          for (final TransactionSplit split in transaction.attributes.transactions) {
            if (split.billId == billId) {
              hasBill = true;
              break;
            }
          }
          if (!hasBill) {
            return false;
          }
        }
      } else if (billName != null) {
        bool hasBill = false;
        for (final TransactionSplit split in transaction.attributes.transactions) {
          if (split.billName == billName) {
            hasBill = true;
            break;
          }
        }
        if (!hasBill) {
          return false;
        }
      }

      // Tags filter
      if (tags != null && tags.isNotEmpty) {
        // Collect all tags from all transaction splits
        final List<String> transactionTags = <String>[];
        for (final TransactionSplit split in transaction.attributes.transactions) {
          if (split.tags != null) {
            transactionTags.addAll(split.tags!);
          }
        }
        if (transactionTags.isEmpty) {
          return false;
        }
        bool hasAllTags = true;
        for (final String tag in tags) {
          if (!transactionTags.contains(tag)) {
            hasAllTags = false;
            break;
          }
        }
        if (!hasAllTags) {
          return false;
        }
      }

      // Date filter
      if (startDate != null || endDate != null) {
        final DateTime? date = transaction.attributes.transactions.firstOrNull?.date;
        if (date == null) {
          return false;
        }
        if (startDate != null && date.isBefore(startDate.subtract(const Duration(days: 1)))) {
          return false;
        }
        if (endDate != null && date.isAfter(endDate.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date descending
    filtered.sort((a, b) {
      final DateTime? dateA = a.attributes.transactions.firstOrNull?.date;
      final DateTime? dateB = b.attributes.transactions.firstOrNull?.date;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    // Apply pagination
    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= filtered.length) {
        return <TransactionRead>[];
      }
      return filtered.sublist(
        startIndex,
        endIndex > filtered.length ? filtered.length : endIndex,
      );
    }

    return filtered;
  }

  Future<void> create(TransactionRead transaction) async {
    final DateTime now = _getNow();
    final DateTime? updatedAt = transaction.attributes.updatedAt;

    final Transactions row = Transactions()
      ..transactionId = transaction.id
      ..data = jsonEncode(transaction.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
    });

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId = null
      ..operation = 'CREATE'
      ..data = jsonEncode(transaction.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(TransactionRead transaction) async {
    final DateTime now = _getNow();

    final Transactions? existing = await isar.transactions
        .filter()
        .transactionIdEqualTo(transaction.id)
        .findFirst();

    if (existing != null) {
      existing
        ..data = jsonEncode(transaction.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.transactions.put(existing);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId = transaction.id
      ..operation = 'UPDATE'
      ..data = jsonEncode(transaction.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> delete(String id) async {
    final DateTime now = _getNow();

    final Transactions? existing = await isar.transactions
        .filter()
        .transactionIdEqualTo(id)
        .findFirst();

    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.transactions.delete(existing.id);
      });
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
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

  // Sync methods - called by sync service
  Future<void> upsertFromSync(TransactionRead transaction) async {
    final DateTime? updatedAt = transaction.attributes.updatedAt;
    final DateTime now = _getNow();

    final Transactions row = Transactions()
      ..transactionId = transaction.id
      ..data = jsonEncode(transaction.toJson())
      ..updatedAt = updatedAt
      ..localUpdatedAt = now
      ..synced = true;

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
    });
  }
}
