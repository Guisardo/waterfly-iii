import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

class TransactionRepository {
  final Isar isar;

  TransactionRepository(this.isar);

  DateTime _getNow() => DateTime.now().toUtc();

  /// Converts a TransactionStore (API request format) to TransactionRead (API response format)
  /// for displaying pending transactions in the UI
  TransactionRead? _convertStoreToRead(
    TransactionStore store,
    String transactionId,
  ) {
    try {
      // Convert TransactionSplitStore to TransactionSplit
      final List<TransactionSplit> transactionSplits =
          store.transactions.map((TransactionSplitStore splitStore) {
            return TransactionSplit(
              transactionJournalId:
                  null, // Pending transactions don't have journal IDs yet
              type: splitStore.type,
              date: splitStore.date,
              order: splitStore.order,
              amount: splitStore.amount,
              description: splitStore.description,
              sourceId: null, // Will be resolved by sync service
              sourceName: splitStore.sourceName,
              sourceIban: null,
              sourceType: null,
              destinationId: null, // Will be resolved by sync service
              destinationName: splitStore.destinationName,
              destinationIban: null,
              destinationType: null,
              billId:
                  splitStore.billId != null && splitStore.billId != "0"
                      ? splitStore.billId
                      : null,
              billName: null,
              categoryId: null,
              categoryName:
                  (splitStore.categoryName?.isNotEmpty ?? false)
                      ? splitStore.categoryName
                      : null,
              budgetId: null,
              budgetName:
                  (splitStore.budgetName?.isNotEmpty ?? false)
                      ? splitStore.budgetName
                      : null,
              tags:
                  (splitStore.tags?.isNotEmpty ?? false)
                      ? splitStore.tags
                      : null,
              notes:
                  (splitStore.notes?.isNotEmpty ?? false)
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
              foreignCurrencySymbol: null,
              foreignCurrencyDecimalPlaces: null,
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

  Future<List<TransactionRead>> getAll() async {
    final List<Transactions> rows = await isar.transactions.where().findAll();
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
      try {
        final Map<String, dynamic> jsonData =
            jsonDecode(row.data) as Map<String, dynamic>;

        // Check if it's a pending transaction (TransactionStore format)
        if (row.transactionId.startsWith('pending-')) {
          // Try to convert TransactionStore to TransactionRead
          try {
            final TransactionStore store = TransactionStore.fromJson(jsonData);
            final TransactionRead? converted = _convertStoreToRead(
              store,
              row.transactionId,
            );
            if (converted != null) {
              result.add(converted);
            }
          } catch (e) {
            // Skip if conversion fails
            continue;
          }
        } else {
          // It's a regular TransactionRead format
          // Verify it's a TransactionRead format (has 'type', 'id', 'attributes', 'links')
          if (jsonData.containsKey('type') &&
              jsonData.containsKey('id') &&
              jsonData.containsKey('attributes') &&
              jsonData.containsKey('links')) {
            result.add(TransactionRead.fromJson(jsonData));
          }
        }
      } catch (e) {
        // Skip invalid transaction data
        continue;
      }
    }
    return result;
  }

  Future<TransactionRead?> getById(String id) async {
    final Transactions? row =
        await isar.transactions.filter().transactionIdEqualTo(id).findFirst();
    if (row == null) {
      return null;
    }
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
    final List<TransactionRead> all = await getAll();
    final List<TransactionRead> filtered =
        all.where((TransactionRead transaction) {
          final DateTime? date =
              transaction.attributes.transactions.firstOrNull?.date;
          if (date == null) {
            return false;
          }
          return date.isAfter(start.subtract(const Duration(days: 1))) &&
              date.isBefore(end.add(const Duration(days: 1)));
        }).toList();

    // Sort by date descending (newest first)
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

  Future<List<TransactionRead>> getByAccount(
    String accountId,
    DateTime? start,
    DateTime? end, {
    int? page,
    int? limit,
  }) async {
    final List<TransactionRead> all = await getAll();
    final List<TransactionRead> filtered =
        all.where((TransactionRead transaction) {
          // Check if transaction involves this account
          bool involvesAccount = false;
          for (final TransactionSplit split
              in transaction.attributes.transactions) {
            if (split.sourceId == accountId ||
                split.destinationId == accountId) {
              involvesAccount = true;
              break;
            }
          }

          if (!involvesAccount) {
            return false;
          }

          // Apply date filter if provided
          if (start != null || end != null) {
            final DateTime? date =
                transaction.attributes.transactions.firstOrNull?.date;
            if (date == null) {
              return false;
            }
            if (start != null &&
                date.isBefore(start.subtract(const Duration(days: 1)))) {
              return false;
            }
            if (end != null && date.isAfter(end.add(const Duration(days: 1)))) {
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
    final List<TransactionRead> filtered =
        all.where((TransactionRead transaction) {
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
              if (split.sourceId == accountId ||
                  split.destinationId == accountId) {
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
              if (transaction.attributes.transactions.firstOrNull?.billId !=
                  null) {
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

    final Transactions row =
        Transactions()
          ..transactionId = transaction.id
          ..data = jsonEncode(transaction.toJson())
          ..updatedAt = updatedAt
          ..localUpdatedAt = now
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
    });

    final PendingChanges pendingChange =
        PendingChanges()
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

    final Transactions? existing =
        await isar.transactions
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

    final PendingChanges pendingChange =
        PendingChanges()
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

    final Transactions? existing =
        await isar.transactions.filter().transactionIdEqualTo(id).findFirst();

    if (existing != null) {
      await isar.writeTxn(() async {
        await isar.transactions.delete(existing.id);
      });
    }

    final PendingChanges pendingChange =
        PendingChanges()
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

  /// Creates a new transaction from a TransactionStore.
  /// Used when creating new transactions from the UI.
  /// The transaction is stored locally with a pending- prefix and queued for sync.
  /// Returns the local transaction ID for UI reference.
  Future<String> createNew(TransactionStore transaction) async {
    final DateTime now = _getNow();
    final String pendingId = 'pending-${now.millisecondsSinceEpoch}';

    final Transactions row =
        Transactions()
          ..transactionId = pendingId
          ..data = jsonEncode(transaction.toJson())
          ..updatedAt = null
          ..localUpdatedAt = now
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
    });

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'transactions'
          ..entityId = null // null for CREATE operations
          ..operation = 'CREATE'
          ..data = jsonEncode(transaction.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    await isar.writeTxn(() async {
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
      final Transactions? existing =
          await isar.transactions.filter().transactionIdEqualTo(id).findFirst();
      if (existing != null) {
        try {
          final Map<String, dynamic> existingData =
              jsonDecode(existing.data) as Map<String, dynamic>;
          final TransactionStore existingStore =
              TransactionStore.fromJson(existingData);

          // Merge update into existing store
          final List<TransactionSplitStore> updatedSplits =
              <TransactionSplitStore>[];
          for (int i = 0; i < (update.transactions?.length ?? 0); i++) {
            final TransactionSplitUpdate splitUpdate = update.transactions![i];
            final TransactionSplitStore? existingSplit =
                existingStore.transactions.elementAtOrNull(i);

            updatedSplits.add(
              TransactionSplitStore(
                type:
                    splitUpdate.type ??
                    existingSplit?.type ??
                    TransactionTypeProperty.withdrawal,
                date: splitUpdate.date ?? existingSplit?.date ?? now,
                amount: splitUpdate.amount ?? existingSplit?.amount ?? '0',
                description:
                    splitUpdate.description ??
                    existingSplit?.description ??
                    '',
                sourceName:
                    splitUpdate.sourceName ?? existingSplit?.sourceName,
                sourceId: splitUpdate.sourceId ?? existingSplit?.sourceId,
                destinationName:
                    splitUpdate.destinationName ??
                    existingSplit?.destinationName,
                destinationId:
                    splitUpdate.destinationId ?? existingSplit?.destinationId,
                categoryName:
                    splitUpdate.categoryName ?? existingSplit?.categoryName,
                categoryId: splitUpdate.categoryId ?? existingSplit?.categoryId,
                budgetName: splitUpdate.budgetName ?? existingSplit?.budgetName,
                budgetId: splitUpdate.budgetId ?? existingSplit?.budgetId,
                billId: splitUpdate.billId ?? existingSplit?.billId,
                billName: splitUpdate.billName ?? existingSplit?.billName,
                tags: splitUpdate.tags ?? existingSplit?.tags,
                notes: splitUpdate.notes ?? existingSplit?.notes,
                foreignAmount:
                    splitUpdate.foreignAmount ?? existingSplit?.foreignAmount,
                foreignCurrencyId:
                    splitUpdate.foreignCurrencyId ??
                    existingSplit?.foreignCurrencyId,
                foreignCurrencyCode:
                    splitUpdate.foreignCurrencyCode ??
                    existingSplit?.foreignCurrencyCode,
                reconciled:
                    splitUpdate.reconciled ?? existingSplit?.reconciled,
                order: splitUpdate.order ?? existingSplit?.order ?? i,
              ),
            );
          }

          final TransactionStore updatedStore = TransactionStore(
            groupTitle: update.groupTitle ?? existingStore.groupTitle,
            transactions: updatedSplits,
            applyRules: existingStore.applyRules,
            fireWebhooks: existingStore.fireWebhooks,
            errorIfDuplicateHash: existingStore.errorIfDuplicateHash,
          );

          existing
            ..data = jsonEncode(updatedStore.toJson())
            ..localUpdatedAt = now
            ..synced = false;

          await isar.writeTxn(() async {
            await isar.transactions.put(existing);
          });

          // Update the pending change if it exists
          final PendingChanges? existingPending =
              await isar.pendingChanges
                  .filter()
                  .entityTypeEqualTo('transactions')
                  .entityIdIsNull()
                  .dataContains(id)
                  .findFirst();

          if (existingPending != null) {
            existingPending
              ..data = jsonEncode(updatedStore.toJson())
              ..createdAt = now;

            await isar.writeTxn(() async {
              await isar.pendingChanges.put(existingPending);
            });
          }
        } catch (e) {
          // If merge fails, just store the update as is
        }
      }
      return;
    }

    // For synced transactions, store the update and queue for sync
    final Transactions? existing =
        await isar.transactions.filter().transactionIdEqualTo(id).findFirst();

    if (existing != null) {
      // We store the TransactionUpdate directly - the sync service will handle it
      existing
        ..localUpdatedAt = now
        ..synced = false;

      await isar.writeTxn(() async {
        await isar.transactions.put(existing);
      });
    }

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'transactions'
          ..entityId = id
          ..operation = 'UPDATE'
          ..data = jsonEncode(update.toJson())
          ..createdAt = now
          ..retryCount = 0
          ..synced = false;

    await isar.writeTxn(() async {
      await isar.pendingChanges.put(pendingChange);
    });
  }

  /// Deletes a transaction split (journal) by its ID.
  /// Used when removing splits from split transactions.
  /// The deletion is queued for sync.
  Future<void> deleteSplit(String journalId) async {
    final DateTime now = _getNow();

    final PendingChanges pendingChange =
        PendingChanges()
          ..entityType = 'transaction_journals'
          ..entityId = journalId
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

    // Check if transaction already exists
    final Transactions? existing =
        await isar.transactions
            .filter()
            .transactionIdEqualTo(transaction.id)
            .findFirst();

    final Transactions row;
    if (existing != null) {
      // Update existing transaction
      row =
          existing
            ..data = jsonEncode(transaction.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    } else {
      // Create new transaction
      row =
          Transactions()
            ..transactionId = transaction.id
            ..data = jsonEncode(transaction.toJson())
            ..updatedAt = updatedAt
            ..localUpdatedAt = now
            ..synced = true;
    }

    await isar.writeTxn(() async {
      await isar.transactions.put(row);
    });
  }
}
