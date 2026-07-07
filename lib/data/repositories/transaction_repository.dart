import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/extensions.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class TransactionRepository {
  final Isar isar;

  TransactionRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  AccountTypeProperty _pendingSourceType(TransactionTypeProperty type) {
    switch (type) {
      case TransactionTypeProperty.deposit:
        return AccountTypeProperty.revenueAccount;
      case TransactionTypeProperty.transfer:
      case TransactionTypeProperty.withdrawal:
      case TransactionTypeProperty.openingBalance:
      case TransactionTypeProperty.reconciliation:
        return AccountTypeProperty.assetAccount;
      case TransactionTypeProperty.swaggerGeneratedUnknown:
        return AccountTypeProperty.swaggerGeneratedUnknown;
    }
  }

  AccountTypeProperty _pendingDestinationType(TransactionTypeProperty type) {
    switch (type) {
      case TransactionTypeProperty.withdrawal:
        return AccountTypeProperty.expenseAccount;
      case TransactionTypeProperty.deposit:
      case TransactionTypeProperty.transfer:
      case TransactionTypeProperty.openingBalance:
      case TransactionTypeProperty.reconciliation:
        return AccountTypeProperty.assetAccount;
      case TransactionTypeProperty.swaggerGeneratedUnknown:
        return AccountTypeProperty.swaggerGeneratedUnknown;
    }
  }

  String _pendingCurrencyId(TransactionSplitStore split) =>
      split.currencyId ??
      split.foreignCurrencyId ??
      split.currencyCode ??
      split.foreignCurrencyCode ??
      '0';

  String _pendingCurrencyCode(TransactionSplitStore split) =>
      split.currencyCode ?? split.foreignCurrencyCode ?? '';

  TransactionSplitStore _mergePendingSplit(
    TransactionSplitStore? existingSplit,
    TransactionSplitUpdate splitUpdate,
    int index,
    DateTime now,
  ) {
    final bool clearsForeignCurrency = splitUpdate.foreignAmount == '0';

    return TransactionSplitStore(
      type:
          splitUpdate.type ??
          existingSplit?.type ??
          TransactionTypeProperty.withdrawal,
      date: splitUpdate.date ?? existingSplit?.date ?? now,
      amount: splitUpdate.amount ?? existingSplit?.amount ?? '0',
      description: splitUpdate.description ?? existingSplit?.description ?? '',
      order: splitUpdate.order ?? existingSplit?.order ?? index,
      currencyId: splitUpdate.currencyId ?? existingSplit?.currencyId,
      currencyCode: splitUpdate.currencyCode ?? existingSplit?.currencyCode,
      foreignAmount: clearsForeignCurrency
          ? null
          : splitUpdate.foreignAmount ?? existingSplit?.foreignAmount,
      foreignCurrencyId: clearsForeignCurrency
          ? null
          : splitUpdate.foreignCurrencyId ?? existingSplit?.foreignCurrencyId,
      foreignCurrencyCode: clearsForeignCurrency
          ? null
          : splitUpdate.foreignCurrencyCode ??
                existingSplit?.foreignCurrencyCode,
      budgetId: splitUpdate.budgetId ?? existingSplit?.budgetId,
      budgetName: splitUpdate.budgetName ?? existingSplit?.budgetName,
      categoryId: splitUpdate.categoryId ?? existingSplit?.categoryId,
      categoryName: splitUpdate.categoryName ?? existingSplit?.categoryName,
      sourceId: splitUpdate.sourceId ?? existingSplit?.sourceId,
      sourceName: splitUpdate.sourceName ?? existingSplit?.sourceName,
      destinationId: splitUpdate.destinationId ?? existingSplit?.destinationId,
      destinationName:
          splitUpdate.destinationName ?? existingSplit?.destinationName,
      reconciled: splitUpdate.reconciled ?? existingSplit?.reconciled,
      billId: splitUpdate.billId ?? existingSplit?.billId,
      billName: splitUpdate.billName ?? existingSplit?.billName,
      tags: splitUpdate.tags ?? existingSplit?.tags,
      notes: splitUpdate.notes ?? existingSplit?.notes,
      internalReference:
          splitUpdate.internalReference ?? existingSplit?.internalReference,
      externalUrl: splitUpdate.externalUrl ?? existingSplit?.externalUrl,
      sepaCc: splitUpdate.sepaCc ?? existingSplit?.sepaCc,
      sepaCtOp: splitUpdate.sepaCtOp ?? existingSplit?.sepaCtOp,
      sepaCtId: splitUpdate.sepaCtId ?? existingSplit?.sepaCtId,
      sepaDb: splitUpdate.sepaDb ?? existingSplit?.sepaDb,
      sepaCountry: splitUpdate.sepaCountry ?? existingSplit?.sepaCountry,
      sepaEp: splitUpdate.sepaEp ?? existingSplit?.sepaEp,
      sepaCi: splitUpdate.sepaCi ?? existingSplit?.sepaCi,
      sepaBatchId: splitUpdate.sepaBatchId ?? existingSplit?.sepaBatchId,
      interestDate: splitUpdate.interestDate ?? existingSplit?.interestDate,
      bookDate: splitUpdate.bookDate ?? existingSplit?.bookDate,
      processDate: splitUpdate.processDate ?? existingSplit?.processDate,
      dueDate: splitUpdate.dueDate ?? existingSplit?.dueDate,
      paymentDate: splitUpdate.paymentDate ?? existingSplit?.paymentDate,
      invoiceDate: splitUpdate.invoiceDate ?? existingSplit?.invoiceDate,
    );
  }

  TransactionStore _mergePendingStore(
    TransactionStore existingStore,
    TransactionUpdate update,
    DateTime now,
  ) {
    final List<TransactionSplitUpdate> updateSplits =
        update.transactions ?? <TransactionSplitUpdate>[];
    final int splitCount =
        existingStore.transactions.length > updateSplits.length
        ? existingStore.transactions.length
        : updateSplits.length;

    final List<TransactionSplitStore> updatedSplits = <TransactionSplitStore>[];
    for (int i = 0; i < splitCount; i++) {
      final TransactionSplitStore? existingSplit = existingStore.transactions
          .elementAtOrNull(i);
      final TransactionSplitUpdate? splitUpdate = updateSplits.elementAtOrNull(
        i,
      );
      if (splitUpdate == null) {
        if (existingSplit != null) updatedSplits.add(existingSplit);
        continue;
      }
      updatedSplits.add(_mergePendingSplit(existingSplit, splitUpdate, i, now));
    }

    return TransactionStore(
      groupTitle: update.groupTitle ?? existingStore.groupTitle,
      transactions: updatedSplits,
      applyRules: existingStore.applyRules,
      fireWebhooks: existingStore.fireWebhooks,
      errorIfDuplicateHash: existingStore.errorIfDuplicateHash,
    );
  }

  TransactionSplit _mergeSyncedSplit(
    TransactionSplit existingSplit,
    TransactionSplitUpdate splitUpdate,
  ) {
    final bool clearsForeignCurrency =
        splitUpdate.foreignAmount == '0' &&
        splitUpdate.foreignCurrencyId == null;

    return existingSplit.copyWithWrapped(
      type: splitUpdate.type == null
          ? null
          : Wrapped<TransactionTypeProperty>.value(splitUpdate.type!),
      date: splitUpdate.date == null
          ? null
          : Wrapped<DateTime>.value(splitUpdate.date!),
      order: splitUpdate.order == null
          ? null
          : Wrapped<int?>.value(splitUpdate.order),
      amount: splitUpdate.amount == null
          ? null
          : Wrapped<String>.value(splitUpdate.amount!),
      description: splitUpdate.description == null
          ? null
          : Wrapped<String>.value(splitUpdate.description!),
      foreignAmount: clearsForeignCurrency
          ? const Wrapped<String?>.value(null)
          : splitUpdate.foreignAmount == null
          ? null
          : Wrapped<String?>.value(splitUpdate.foreignAmount),
      foreignCurrencyId: clearsForeignCurrency
          ? const Wrapped<String?>.value(null)
          : splitUpdate.foreignCurrencyId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.foreignCurrencyId),
      foreignCurrencyCode: clearsForeignCurrency
          ? const Wrapped<String?>.value(null)
          : splitUpdate.foreignCurrencyCode == null
          ? null
          : Wrapped<String?>.value(splitUpdate.foreignCurrencyCode),
      budgetId: splitUpdate.budgetId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.budgetId),
      budgetName: splitUpdate.budgetName == null
          ? null
          : Wrapped<String?>.value(splitUpdate.budgetName),
      categoryId: splitUpdate.categoryId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.categoryId),
      categoryName: splitUpdate.categoryName == null
          ? null
          : Wrapped<String?>.value(splitUpdate.categoryName),
      sourceId: splitUpdate.sourceId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sourceId),
      sourceName: splitUpdate.sourceName == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sourceName),
      destinationId: splitUpdate.destinationId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.destinationId),
      destinationName: splitUpdate.destinationName == null
          ? null
          : Wrapped<String?>.value(splitUpdate.destinationName),
      reconciled: splitUpdate.reconciled == null
          ? null
          : Wrapped<bool?>.value(splitUpdate.reconciled),
      billId: splitUpdate.billId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.billId),
      billName: splitUpdate.billName == null
          ? null
          : Wrapped<String?>.value(splitUpdate.billName),
      tags: splitUpdate.tags == null
          ? null
          : Wrapped<List<String>?>.value(splitUpdate.tags),
      notes: splitUpdate.notes == null
          ? null
          : Wrapped<String?>.value(splitUpdate.notes),
      internalReference: splitUpdate.internalReference == null
          ? null
          : Wrapped<String?>.value(splitUpdate.internalReference),
      externalId: splitUpdate.externalId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.externalId),
      externalUrl: splitUpdate.externalUrl == null
          ? null
          : Wrapped<String?>.value(splitUpdate.externalUrl),
      sepaCc: splitUpdate.sepaCc == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaCc),
      sepaCtOp: splitUpdate.sepaCtOp == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaCtOp),
      sepaCtId: splitUpdate.sepaCtId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaCtId),
      sepaDb: splitUpdate.sepaDb == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaDb),
      sepaCountry: splitUpdate.sepaCountry == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaCountry),
      sepaEp: splitUpdate.sepaEp == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaEp),
      sepaCi: splitUpdate.sepaCi == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaCi),
      sepaBatchId: splitUpdate.sepaBatchId == null
          ? null
          : Wrapped<String?>.value(splitUpdate.sepaBatchId),
      interestDate: splitUpdate.interestDate == null
          ? null
          : Wrapped<DateTime?>.value(splitUpdate.interestDate),
      bookDate: splitUpdate.bookDate == null
          ? null
          : Wrapped<DateTime?>.value(splitUpdate.bookDate),
      processDate: splitUpdate.processDate == null
          ? null
          : Wrapped<DateTime?>.value(splitUpdate.processDate),
      dueDate: splitUpdate.dueDate == null
          ? null
          : Wrapped<DateTime?>.value(splitUpdate.dueDate),
      paymentDate: splitUpdate.paymentDate == null
          ? null
          : Wrapped<DateTime?>.value(splitUpdate.paymentDate),
      invoiceDate: splitUpdate.invoiceDate == null
          ? null
          : Wrapped<DateTime?>.value(splitUpdate.invoiceDate),
    );
  }

  TransactionRead _mergeSyncedTransactionRead(
    TransactionRead existingTransaction,
    TransactionUpdate update,
  ) {
    final List<TransactionSplitUpdate> updateSplits =
        update.transactions ?? <TransactionSplitUpdate>[];
    final List<TransactionSplit> updatedSplits = existingTransaction
        .attributes
        .transactions
        .mapIndexed((int index, TransactionSplit existingSplit) {
          final TransactionSplitUpdate? splitUpdate = updateSplits
              .elementAtOrNull(index);
          if (splitUpdate == null) return existingSplit;
          return _mergeSyncedSplit(existingSplit, splitUpdate);
        })
        .toList();

    return existingTransaction.copyWith(
      attributes: existingTransaction.attributes.copyWith(
        groupTitle:
            update.groupTitle ?? existingTransaction.attributes.groupTitle,
        transactions: updatedSplits,
      ),
    );
  }

  Future<PendingChanges?> _findPendingCreate(String pendingId) async {
    final List<PendingChanges> changes = await isar.pendingChanges
        .where()
        .findAll();
    for (final PendingChanges change in changes) {
      if (change.entityType == 'transactions' &&
          change.operation == PendingChangeOperation.create.name &&
          !change.synced &&
          change.localPendingId == pendingId) {
        return change;
      }
    }
    return null;
  }

  /// Converts a TransactionStore (API request format) to TransactionRead (API response format)
  /// for displaying pending transactions in the UI
  TransactionRead? _convertStoreToRead(
    TransactionStore store,
    String transactionId,
  ) {
    try {
      // Convert TransactionSplitStore to TransactionSplit
      final List<TransactionSplit> transactionSplits = store.transactions.map((
        TransactionSplitStore splitStore,
      ) {
        return TransactionSplit(
          transactionJournalId:
              null, // Pending transactions don't have journal IDs yet
          type: splitStore.type,
          date: splitStore.date,
          order: splitStore.order,
          currencyId: _pendingCurrencyId(splitStore),
          currencyCode: _pendingCurrencyCode(splitStore),
          currencySymbol: _pendingCurrencyCode(splitStore),
          currencyName: _pendingCurrencyCode(splitStore),
          currencyDecimalPlaces: 2,
          amount: splitStore.amount,
          description: splitStore.description,
          sourceId: splitStore.sourceId,
          sourceName: splitStore.sourceName,
          sourceIban: null,
          sourceType: _pendingSourceType(splitStore.type),
          destinationId: splitStore.destinationId,
          destinationName: splitStore.destinationName,
          destinationIban: null,
          destinationType: _pendingDestinationType(splitStore.type),
          billId: splitStore.billId != null && splitStore.billId != "0"
              ? splitStore.billId
              : null,
          billName: splitStore.billName,
          categoryId: splitStore.categoryId,
          categoryName: (splitStore.categoryName?.isNotEmpty ?? false)
              ? splitStore.categoryName
              : null,
          budgetId: splitStore.budgetId,
          budgetName: (splitStore.budgetName?.isNotEmpty ?? false)
              ? splitStore.budgetName
              : null,
          tags: (splitStore.tags?.isNotEmpty ?? false) ? splitStore.tags : null,
          notes: (splitStore.notes?.isNotEmpty ?? false)
              ? splitStore.notes
              : null,
          internalReference: splitStore.internalReference,
          externalUrl: splitStore.externalUrl,
          originalSource: null,
          reconciled: splitStore.reconciled ?? false,
          hasAttachments: false,
          foreignAmount:
              splitStore.foreignAmount != null &&
                  splitStore.foreignAmount != "0"
              ? splitStore.foreignAmount
              : null,
          foreignCurrencyId: splitStore.foreignCurrencyId,
          foreignCurrencyCode: splitStore.foreignCurrencyCode,
          foreignCurrencySymbol: splitStore.foreignCurrencyCode,
          foreignCurrencyDecimalPlaces: splitStore.foreignCurrencyCode == null
              ? null
              : 2,
          sepaCc: splitStore.sepaCc,
          sepaCtOp: splitStore.sepaCtOp,
          sepaCtId: splitStore.sepaCtId,
          sepaDb: splitStore.sepaDb,
          sepaCountry: splitStore.sepaCountry,
          sepaEp: splitStore.sepaEp,
          sepaCi: splitStore.sepaCi,
          sepaBatchId: splitStore.sepaBatchId,
          interestDate: splitStore.interestDate,
          bookDate: splitStore.bookDate,
          processDate: splitStore.processDate,
          dueDate: splitStore.dueDate,
          paymentDate: splitStore.paymentDate,
          invoiceDate: splitStore.invoiceDate,
        );
      }).toList();

      // Create Transaction attributes
      final Transaction transactionAttributes = Transaction(
        createdAt: null,
        updatedAt: null,
        user: null,
        groupTitle: store.groupTitle,
        transactions: transactionSplits,
      );

      // Create ObjectLink (minimal, just for structure)
      const ObjectLink links = ObjectLink(self: null);

      // Create TransactionRead
      return TransactionRead(
        type: "transactions",
        id: transactionId,
        attributes: transactionAttributes,
        links: links,
      );
    } catch (e) {
      // If conversion fails, return null
      return null;
    }
  }

  /// Deserializes a single Transactions row to TransactionRead.
  /// Returns null if the row is soft-deleted or cannot be parsed.
  TransactionRead? _deserializeRow(Transactions row) {
    if (row.deletedAt != null) return null;
    try {
      final Map<String, dynamic> jsonData =
          jsonDecode(row.data) as Map<String, dynamic>;
      if (row.transactionId.startsWith('pending-')) {
        final TransactionStore store = TransactionStore.fromJson(jsonData);
        return _convertStoreToRead(store, row.transactionId);
      }
      if (jsonData.containsKey('type') &&
          jsonData.containsKey('id') &&
          jsonData.containsKey('attributes') &&
          jsonData.containsKey('links')) {
        return TransactionRead.fromJson(jsonData);
      }
    } catch (e) {
      // Parsing error, return null
    }
    return null;
  }

  Future<List<TransactionRead>> getAll() async {
    final List<Transactions> rows = await isar.transactions
        .filter()
        .deletedAtIsNull()
        .findAll();
    rows.sort((Transactions a, Transactions b) {
      final DateTime? dateA = a.updatedAt ?? a.localUpdatedAt;
      final DateTime? dateB = b.updatedAt ?? b.localUpdatedAt;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    final List<TransactionRead> result = <TransactionRead>[];
    for (final Transactions row in rows) {
      final TransactionRead? tx = _deserializeRow(row);
      if (tx != null) result.add(tx);
    }
    return result;
  }

  Future<TransactionRead?> getById(String id) async {
    final Transactions? row = await isar.transactions
        .filter()
        .transactionIdEqualTo(id)
        .findFirst();
    if (row == null) {
      return null;
    }
    if (row.deletedAt != null) return null;
    // Handle pending transactions (they have TransactionStore format, not TransactionRead)
    if (row.transactionId.startsWith('pending-')) {
      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(row.data) as Map<String, dynamic>;
        final TransactionStore store = TransactionStore.fromJson(jsonData);
        return _convertStoreToRead(store, row.transactionId);
      } catch (e) {
        return null;
      }
    }
    try {
      final Map<String, dynamic> jsonData =
          jsonDecode(row.data) as Map<String, dynamic>;
      // Verify it's a TransactionRead format
      if (jsonData.containsKey('type') &&
          jsonData.containsKey('id') &&
          jsonData.containsKey('attributes') &&
          jsonData.containsKey('links')) {
        return TransactionRead.fromJson(jsonData);
      }
    } catch (e) {
      // Invalid transaction data
      return null;
    }
    return null;
  }

  Future<List<TransactionRead>> search(String query) async {
    final List<TransactionRead> all = await getAll();
    final String queryLower = query.toLowerCase();
    return all.where((TransactionRead transaction) {
      // Search in transaction descriptions directly (most common case)
      for (final TransactionSplit split
          in transaction.attributes.transactions) {
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
    final List<Transactions> rows = await isar.transactions
        .filter()
        .deletedAtIsNull()
        .dateBetween(start, end)
        .findAll();

    final List<TransactionRead> filtered = <TransactionRead>[];
    for (final Transactions row in rows) {
      final TransactionRead? tx = _deserializeRow(row);
      if (tx != null) filtered.add(tx);
    }

    filtered.sort((TransactionRead a, TransactionRead b) {
      final DateTime? dateA = a.attributes.transactions.firstOrNull?.date;
      final DateTime? dateB = b.attributes.transactions.firstOrNull?.date;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= filtered.length) return <TransactionRead>[];
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
    final QueryBuilder<Transactions, Transactions, QAfterFilterCondition>
    query = isar.transactions.filter().deletedAtIsNull().group(
      (QueryBuilder<Transactions, Transactions, QFilterCondition> q) => q
          .sourceAccountIdEqualTo(accountId)
          .or()
          .destinationAccountIdEqualTo(accountId),
    );

    final List<Transactions> rows = await query.findAll();

    final List<TransactionRead> filtered = <TransactionRead>[];
    for (final Transactions row in rows) {
      final TransactionRead? tx = _deserializeRow(row);
      if (tx == null) continue;

      if (start != null || end != null) {
        final DateTime? date = tx.attributes.transactions.firstOrNull?.date;
        if (date == null) continue;
        if (start != null &&
            date.isBefore(start.subtract(const Duration(days: 1)))) {
          continue;
        }
        if (end != null && date.isAfter(end.add(const Duration(days: 1)))) {
          continue;
        }
      }

      filtered.add(tx);
    }

    filtered.sort((TransactionRead a, TransactionRead b) {
      final DateTime? dateA = a.attributes.transactions.firstOrNull?.date;
      final DateTime? dateB = b.attributes.transactions.firstOrNull?.date;
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });

    if (page != null && limit != null) {
      final int startIndex = (page - 1) * limit;
      final int endIndex = startIndex + limit;
      if (startIndex >= filtered.length) return <TransactionRead>[];
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
    final List<TransactionRead> filtered = all.where((
      TransactionRead transaction,
    ) {
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
        for (final TransactionSplit split
            in transaction.attributes.transactions) {
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
        for (final TransactionSplit split
            in transaction.attributes.transactions) {
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
          if (transaction.attributes.transactions.firstOrNull?.categoryId !=
              null) {
            return false;
          }
        } else {
          bool hasCategory = false;
          for (final TransactionSplit split
              in transaction.attributes.transactions) {
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
        for (final TransactionSplit split
            in transaction.attributes.transactions) {
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
          if (transaction.attributes.transactions.firstOrNull?.budgetId !=
              null) {
            return false;
          }
        } else {
          bool hasBudget = false;
          for (final TransactionSplit split
              in transaction.attributes.transactions) {
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
        for (final TransactionSplit split
            in transaction.attributes.transactions) {
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
          for (final TransactionSplit split
              in transaction.attributes.transactions) {
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
        for (final TransactionSplit split
            in transaction.attributes.transactions) {
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
        for (final TransactionSplit split
            in transaction.attributes.transactions) {
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
        final DateTime? date =
            transaction.attributes.transactions.firstOrNull?.date;
        if (date == null) {
          return false;
        }
        if (startDate != null &&
            date.isBefore(startDate.subtract(const Duration(days: 1)))) {
          return false;
        }
        if (endDate != null &&
            date.isAfter(endDate.add(const Duration(days: 1)))) {
          return false;
        }
      }

      return true;
    }).toList();

    // Sort by date descending
    filtered.sort((TransactionRead a, TransactionRead b) {
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
      ..synced = false
      ..date = transaction.attributes.transactions.firstOrNull?.date
      ..sourceAccountId =
          transaction.attributes.transactions.firstOrNull?.sourceId
      ..destinationAccountId =
          transaction.attributes.transactions.firstOrNull?.destinationId;

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId = null
      ..operation = PendingChangeOperation.create.name
      ..data = jsonEncode(transaction.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
      await isar.pendingChanges.put(pendingChange);
    });
  }

  Future<void> update(TransactionRead transaction) async {
    final DateTime now = _getNow();

    final Transactions? existing = await isar.transactions
        .filter()
        .transactionIdEqualTo(transaction.id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId = transaction.id
      ..operation = PendingChangeOperation.update.name
      ..data = jsonEncode(transaction.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing
        ..data = jsonEncode(transaction.toJson())
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.transactions.put(existing);
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

    final Transactions? existing = await isar.transactions
        .filter()
        .transactionIdEqualTo(id)
        .findFirst();

    if (id.startsWith('pending-')) {
      final PendingChanges? pendingCreate = await _findPendingCreate(id);
      if (existing == null || pendingCreate == null) {
        throw StateError(
          'Cannot cancel pending transaction $id without its pending CREATE',
        );
      }
      await isar.writeTxn(() async {
        await isar.transactions.delete(existing.id);
        await isar.pendingChanges.delete(pendingCreate.id);
      });
      return;
    }

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId = id
      ..operation = PendingChangeOperation.delete.name
      ..data = null
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      existing.deletedAt = _getNow();
      await isar.writeTxn(() async {
        await isar.transactions.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  /// Creates a new transaction from a TransactionStore.
  /// Used when creating new transactions from the UI.
  /// The transaction is stored locally with a pending- prefix and queued for sync.
  /// Returns the local transaction ID for UI reference.
  Future<String> createNew(TransactionStore transaction) async {
    final DateTime now = _getNow();
    final String pendingId = 'pending-${now.millisecondsSinceEpoch}';

    final Transactions row = Transactions()
      ..transactionId = pendingId
      ..data = jsonEncode(transaction.toJson())
      ..updatedAt = null
      ..localUpdatedAt = now
      ..synced = false
      ..date = transaction.transactions.firstOrNull?.date.clearTime()
      ..sourceAccountId = transaction.transactions.firstOrNull?.sourceId
      ..destinationAccountId =
          transaction.transactions.firstOrNull?.destinationId;

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId =
          null // null for CREATE operations
      ..operation = PendingChangeOperation.create.name
      ..data = jsonEncode(transaction.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false
      ..localPendingId = pendingId;

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
      await isar.pendingChanges.put(pendingChange);
    });

    return pendingId;
  }

  /// Updates an existing transaction with a TransactionUpdate.
  /// Used when editing transactions from the UI.
  /// The changes are stored locally and queued for sync.
  Future<void> updateExisting(String id, TransactionUpdate update) async {
    final DateTime now = _getNow();

    // For pending transactions, we need to merge the update into the stored TransactionStore
    if (id.startsWith('pending-')) {
      final Transactions? existing = await isar.transactions
          .filter()
          .transactionIdEqualTo(id)
          .findFirst();
      if (existing != null) {
        try {
          final Map<String, dynamic> existingData =
              jsonDecode(existing.data) as Map<String, dynamic>;
          final TransactionStore existingStore = TransactionStore.fromJson(
            existingData,
          );

          final TransactionStore updatedStore = _mergePendingStore(
            existingStore,
            update,
            now,
          );
          if (updatedStore.transactions.isEmpty) {
            throw StateError('Pending transaction $id cannot have no splits');
          }
          final PendingChanges? existingPending = await _findPendingCreate(id);
          if (existingPending == null) {
            throw StateError(
              'Cannot update pending transaction $id without its pending CREATE',
            );
          }

          existing
            ..data = jsonEncode(updatedStore.toJson())
            ..localUpdatedAt = now
            ..synced = false
            ..date = updatedStore.transactions.firstOrNull?.date.clearTime()
            ..sourceAccountId = updatedStore.transactions.firstOrNull?.sourceId
            ..destinationAccountId =
                updatedStore.transactions.firstOrNull?.destinationId;

          existingPending
            ..data = jsonEncode(updatedStore.toJson())
            ..createdAt = now;

          await isar.writeTxn(() async {
            await isar.transactions.put(existing);
            await isar.pendingChanges.put(existingPending);
          });
        } catch (e) {
          rethrow;
        }
      }
      return;
    }

    // For synced transactions, store the update and queue for sync
    final Transactions? existing = await isar.transactions
        .filter()
        .transactionIdEqualTo(id)
        .findFirst();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transactions'
      ..entityId = id
      ..operation = PendingChangeOperation.update.name
      ..data = jsonEncode(update.toJson())
      ..createdAt = now
      ..retryCount = 0
      ..synced = false;

    if (existing != null) {
      final TransactionRead existingTransaction = TransactionRead.fromJson(
        jsonDecode(existing.data) as Map<String, dynamic>,
      );
      final TransactionRead updatedTransaction = _mergeSyncedTransactionRead(
        existingTransaction,
        update,
      );

      existing
        ..data = jsonEncode(updatedTransaction.toJson())
        ..localUpdatedAt = now
        ..synced = false
        ..date = updatedTransaction.attributes.transactions.firstOrNull?.date
        ..sourceAccountId =
            updatedTransaction.attributes.transactions.firstOrNull?.sourceId
        ..destinationAccountId = updatedTransaction
            .attributes
            .transactions
            .firstOrNull
            ?.destinationId;

      await isar.writeTxn(() async {
        await isar.transactions.put(existing);
        await isar.pendingChanges.put(pendingChange);
      });
    } else {
      await isar.writeTxn(() async {
        await isar.pendingChanges.put(pendingChange);
      });
    }
  }

  /// Deletes a transaction split (journal) by its ID.
  /// Used when removing splits from split transactions.
  /// The deletion is queued for sync.
  Future<void> deleteSplit(String journalId) async {
    final DateTime now = _getNow();

    final PendingChanges pendingChange = PendingChanges()
      ..entityType = 'transaction_journals'
      ..entityId = journalId
      ..operation = PendingChangeOperation.delete.name
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

    // Check if transaction already exists
    final Transactions? existing = await isar.transactions
        .filter()
        .transactionIdEqualTo(transaction.id)
        .findFirst();

    if (existing?.deletedAt != null) return; // locally deleted, keep tombstone

    final Transactions row;
    if (existing != null) {
      // Update existing transaction
      row = existing
        ..data = jsonEncode(transaction.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true
        ..date = transaction.attributes.transactions.firstOrNull?.date
        ..sourceAccountId =
            transaction.attributes.transactions.firstOrNull?.sourceId
        ..destinationAccountId =
            transaction.attributes.transactions.firstOrNull?.destinationId;
    } else {
      // Create new transaction
      row = Transactions()
        ..transactionId = transaction.id
        ..data = jsonEncode(transaction.toJson())
        ..updatedAt = updatedAt
        ..localUpdatedAt = now
        ..synced = true
        ..date = transaction.attributes.transactions.firstOrNull?.date
        ..sourceAccountId =
            transaction.attributes.transactions.firstOrNull?.sourceId
        ..destinationAccountId =
            transaction.attributes.transactions.firstOrNull?.destinationId;
    }

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
    });
  }

  Future<int> deleteSyncedMissingFromServer(
    Set<String> serverTransactionIds,
  ) async {
    final List<Transactions> localRows = await isar.transactions
        .where()
        .findAll();
    final List<PendingChanges> pendingChanges = await isar.pendingChanges
        .where()
        .findAll();
    final Set<String> pendingTransactionIds = pendingChanges
        .where(
          (PendingChanges change) =>
              change.entityType == 'transactions' &&
              !change.synced &&
              change.entityId != null,
        )
        .map((PendingChanges change) => change.entityId!)
        .toSet();

    final List<Id> idsToDelete = <Id>[];
    for (final Transactions row in localRows) {
      if (!row.synced) continue;
      if (row.deletedAt != null) continue;
      if (row.transactionId.startsWith('pending-')) continue;
      if (serverTransactionIds.contains(row.transactionId)) continue;
      if (pendingTransactionIds.contains(row.transactionId)) continue;
      idsToDelete.add(row.id);
    }

    if (idsToDelete.isEmpty) {
      return 0;
    }

    return isar.writeTxn<int>(() {
      return isar.transactions.deleteAll(idsToDelete);
    });
  }
}
