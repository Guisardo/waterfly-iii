import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';

import 'package:waterflyiii/data/repositories/base_repository.dart';

/// Repository for managing transaction data.
///
/// Handles CRUD operations for transactions, automatically routing to
/// local storage or remote API based on the current app mode.
class TransactionRepository
    implements BaseRepository<TransactionEntity, String> {
  /// Creates a transaction repository.
  TransactionRepository({
    required AppDatabase database,
    UuidService? uuidService,
  })  : _database = database,
        _uuidService = uuidService ?? UuidService();

  final AppDatabase _database;
  final UuidService _uuidService;

  @override
  final Logger logger = Logger('TransactionRepository');

  @override
  Future<List<TransactionEntity>> getAll() async {
    try {
      logger.fine('Fetching all transactions');
      final List<TransactionEntity> transactions = await _database.select(_database.transactions).get();
      logger.info('Retrieved ${transactions.length} transactions');
      return transactions;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch transactions', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM transactions',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<TransactionEntity>> watchAll() {
    logger.fine('Watching all transactions');
    return _database.select(_database.transactions).watch();
  }

  @override
  Future<TransactionEntity?> getById(String id) async {
    try {
      logger.fine('Fetching transaction by ID: $id');
      final SimpleSelectStatement<$TransactionsTable, TransactionEntity> query = _database.select(_database.transactions)
        ..where(($TransactionsTable t) => t.id.equals(id));
      final TransactionEntity? transaction = await query.getSingleOrNull();
      
      if (transaction != null) {
        logger.fine('Found transaction: $id');
      } else {
        logger.fine('Transaction not found: $id');
      }
      
      return transaction;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch transaction $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM transactions WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<TransactionEntity?> watchById(String id) {
    logger.fine('Watching transaction: $id');
    final SimpleSelectStatement<$TransactionsTable, TransactionEntity> query = _database.select(_database.transactions)
      ..where(($TransactionsTable t) => t.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<TransactionEntity> create(TransactionEntity entity) async {
    try {
      logger.info('Creating transaction');

      // Generate ID if not provided
      final String id = entity.id.isEmpty ? _uuidService.generateTransactionId() : entity.id;
      
      final DateTime now = DateTime.now();
      final TransactionEntityCompanion companion = TransactionEntityCompanion.insert(
        id: id,
        serverId: Value(entity.serverId),
        type: entity.type,
        date: entity.date,
        amount: entity.amount,
        description: entity.description,
        sourceAccountId: entity.sourceAccountId,
        destinationAccountId: entity.destinationAccountId,
        categoryId: Value(entity.categoryId),
        budgetId: Value(entity.budgetId),
        currencyCode: entity.currencyCode,
        foreignAmount: Value(entity.foreignAmount),
        foreignCurrencyCode: Value(entity.foreignCurrencyCode),
        notes: Value(entity.notes),
        tags: Value(entity.tags),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
        lastSyncAttempt: const Value.absent(),
        syncError: const Value.absent(),
      );

      await _database.into(_database.transactions).insert(companion);
      
      final TransactionEntity? created = await getById(id);
      if (created == null) {
        throw const DatabaseException('Failed to retrieve created transaction');
      }

      logger.info('Transaction created successfully: $id');
      
      // TODO: Add to sync queue if in offline mode
      
      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create transaction', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to create transaction: $error');
    }
  }

  @override
  Future<TransactionEntity> update(String id, TransactionEntity entity) async {
    try {
      logger.info('Updating transaction: $id');

      final TransactionEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Transaction not found: $id');
      }

      final TransactionEntityCompanion companion = TransactionEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        type: Value(entity.type),
        date: Value(entity.date),
        amount: Value(entity.amount),
        description: Value(entity.description),
        sourceAccountId: Value(entity.sourceAccountId),
        destinationAccountId: Value(entity.destinationAccountId),
        categoryId: Value(entity.categoryId),
        budgetId: Value(entity.budgetId),
        currencyCode: Value(entity.currencyCode),
        foreignAmount: Value(entity.foreignAmount),
        foreignCurrencyCode: Value(entity.foreignCurrencyCode),
        notes: Value(entity.notes),
        tags: Value(entity.tags),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      final UpdateStatement<$TransactionsTable, TransactionEntity> query = _database.update(_database.transactions)
        ..where(($TransactionsTable t) => t.id.equals(id));
      await query.write(companion);

      final TransactionEntity? updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated transaction');
      }

      logger.info('Transaction updated successfully: $id');
      
      // TODO: Add to sync queue if in offline mode
      
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update transaction $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to update transaction: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting transaction: $id');

      final TransactionEntity? existing = await getById(id);
      if (existing == null) {
        logger.warning('Transaction not found for deletion: $id');
        return;
      }

      final DeleteStatement<$TransactionsTable, TransactionEntity> query = _database.delete(_database.transactions)
        ..where(($TransactionsTable t) => t.id.equals(id));
      await query.go();

      logger.info('Transaction deleted successfully: $id');
      
      // TODO: Add to sync queue if transaction was synced
    } catch (error, stackTrace) {
      logger.severe('Failed to delete transaction $id', error, stackTrace);
      throw DatabaseException('Failed to delete transaction: $error');
    }
  }

  @override
  Future<List<TransactionEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced transactions');
      final SimpleSelectStatement<$TransactionsTable, TransactionEntity> query = _database.select(_database.transactions)
        ..where(($TransactionsTable t) => t.isSynced.equals(false));
      final List<TransactionEntity> transactions = await query.get();
      logger.info('Found ${transactions.length} unsynced transactions');
      return transactions;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced transactions', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM transactions WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking transaction as synced: $localId -> $serverId');

      final TransactionEntityCompanion companion = TransactionEntityCompanion(
        serverId: Value(serverId),
        isSynced: const Value(true),
        syncStatus: const Value('synced'),
        lastSyncAttempt: Value(DateTime.now()),
        syncError: const Value.absent(),
      );

      final UpdateStatement<$TransactionsTable, TransactionEntity> query = _database.update(_database.transactions)
        ..where(($TransactionsTable t) => t.id.equals(localId));
      await query.write(companion);

      logger.info('Transaction marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to mark transaction as synced: $localId',
        error,
        stackTrace,
      );
      throw DatabaseException('Failed to mark transaction as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final TransactionEntity? transaction = await getById(id);
      if (transaction == null) {
        throw DatabaseException('Transaction not found: $id');
      }
      return transaction.syncStatus;
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to get sync status for transaction $id',
        error,
        stackTrace,
      );
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to get sync status: $error');
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all transactions from cache');
      await _database.delete(_database.transactions).go();
      logger.info('Transaction cache cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear transaction cache', error, stackTrace);
      throw DatabaseException('Failed to clear cache: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      final Expression<int> countExp = _database.transactions.id.count();
      final JoinedSelectStatement<$TransactionsTable, TransactionEntity> query = _database.selectOnly(_database.transactions)
        ..addColumns(<Expression<Object>>[countExp]);
      final TypedResult result = await query.getSingle();
      final int count = result.read(countExp) ?? 0;
      logger.fine('Transaction count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count transactions', error, stackTrace);
      throw DatabaseException('Failed to count transactions: $error');
    }
  }

  /// Gets transactions within a date range.
  ///
  /// [startDate] - Start of the date range (inclusive).
  /// [endDate] - End of the date range (inclusive).
  Future<List<TransactionEntity>> getByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      logger.fine('Fetching transactions from $startDate to $endDate');
      final SimpleSelectStatement<$TransactionsTable, TransactionEntity> query = _database.select(_database.transactions)
        ..where(($TransactionsTable t) => t.date.isBiggerOrEqualValue(startDate))
        ..where(($TransactionsTable t) => t.date.isSmallerOrEqualValue(endDate))
        ..orderBy(<OrderClauseGenerator<$TransactionsTable>>[($TransactionsTable t) => OrderingTerm.desc(t.date)]);
      final List<TransactionEntity> transactions = await query.get();
      logger.info('Found ${transactions.length} transactions in date range');
      return transactions;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch transactions by date range', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM transactions WHERE date BETWEEN $startDate AND $endDate',
        error,
        stackTrace,
      );
    }
  }

  /// Gets transactions for a specific account.
  ///
  /// [accountId] - The account ID (source or destination).
  Future<List<TransactionEntity>> getByAccount(String accountId) async {
    try {
      logger.fine('Fetching transactions for account: $accountId');
      final SimpleSelectStatement<$TransactionsTable, TransactionEntity> query = _database.select(_database.transactions)
        ..where(($TransactionsTable t) =>
            t.sourceAccountId.equals(accountId) |
            t.destinationAccountId.equals(accountId))
        ..orderBy(<OrderClauseGenerator<$TransactionsTable>>[($TransactionsTable t) => OrderingTerm.desc(t.date)]);
      final List<TransactionEntity> transactions = await query.get();
      logger.info('Found ${transactions.length} transactions for account');
      return transactions;
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to fetch transactions for account $accountId',
        error,
        stackTrace,
      );
      throw DatabaseException.queryFailed(
        'SELECT * FROM transactions WHERE source_account_id = $accountId OR destination_account_id = $accountId',
        error,
        stackTrace,
      );
    }
  }

  /// Gets transactions for a specific category.
  ///
  /// [categoryId] - The category ID.
  Future<List<TransactionEntity>> getByCategory(String categoryId) async {
    try {
      logger.fine('Fetching transactions for category: $categoryId');
      final SimpleSelectStatement<$TransactionsTable, TransactionEntity> query = _database.select(_database.transactions)
        ..where(($TransactionsTable t) => t.categoryId.equals(categoryId))
        ..orderBy(<OrderClauseGenerator<$TransactionsTable>>[($TransactionsTable t) => OrderingTerm.desc(t.date)]);
      final List<TransactionEntity> transactions = await query.get();
      logger.info('Found ${transactions.length} transactions for category');
      return transactions;
    } catch (error, stackTrace) {
      logger.severe(
        'Failed to fetch transactions for category $categoryId',
        error,
        stackTrace,
      );
      throw DatabaseException.queryFailed(
        'SELECT * FROM transactions WHERE category_id = $categoryId',
        error,
        stackTrace,
      );
    }
  }
}
