import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../exceptions/offline_exceptions.dart';
import '../../models/sync_operation.dart';
import '../../services/cache/query_cache.dart';
import '../../services/sync/sync_queue_manager.dart';
import '../../services/uuid/uuid_service.dart';
import '../../validators/transaction_validator.dart';
import '../local/database/app_database.dart';
import 'base_repository.dart';

/// Repository for managing transaction data.
///
/// Handles CRUD operations for transactions, automatically routing to
/// local storage or remote API based on the current app mode.
///
/// Features:
/// - Comprehensive validation before storage
/// - Automatic sync queue integration
/// - Query result caching
/// - Offline-first design
///
/// Example:
/// ```dart
/// final repository = TransactionRepository(
///   database: database,
///   syncQueueManager: syncQueueManager,
///   queryCache: queryCache,
/// );
///
/// // Create transaction offline
/// final transaction = await repository.createTransactionOffline(data);
///
/// // Query with caching
/// final recent = await repository.getRecentTransactions(limit: 50);
/// ```
class TransactionRepository
    implements BaseRepository<TransactionEntity, String> {
  /// Creates a transaction repository.
  TransactionRepository({
    required AppDatabase database,
    SyncQueueManager? syncQueueManager,
    QueryCache? queryCache,
    UuidService? uuidService,
    TransactionValidator? validator,
  })  : _database = database,
        _syncQueueManager = syncQueueManager,
        _queryCache = queryCache,
        _uuidService = uuidService ?? UuidService(),
        _validator = validator ?? TransactionValidator();

  final AppDatabase _database;
  final SyncQueueManager? _syncQueueManager;
  final QueryCache? _queryCache;
  final UuidService _uuidService;
  final TransactionValidator _validator;

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
      
      // Add to sync queue for offline sync
      if (_syncQueueManager != null) {
        await _syncQueueManager!.addOperation(
          SyncOperation(
            id: _uuidService.generate(),
            entityType: 'transaction',
            entityId: id,
            operationType: OperationType.create,
            data: <String, dynamic>{
              'type': entity.type,
              'date': entity.date.toIso8601String(),
              'amount': entity.amount,
              'description': entity.description,
              'source_account_id': entity.sourceAccountId,
              'destination_account_id': entity.destinationAccountId,
              'category_id': entity.categoryId,
              'budget_id': entity.budgetId,
              'currency_code': entity.currencyCode,
              'foreign_amount': entity.foreignAmount,
              'foreign_currency_code': entity.foreignCurrencyCode,
              'notes': entity.notes,
              'tags': entity.tags,
            },
            createdAt: DateTime.now(),
            priority: 5,
          ),
        );
        logger.fine('Added transaction to sync queue: $id');
      }
      
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
      
      // Add to sync queue for offline sync
      if (_syncQueueManager != null) {
        await _syncQueueManager!.addOperation(
          SyncOperation(
            id: _uuidService.generate(),
            entityType: 'transaction',
            entityId: id,
            operationType: OperationType.update,
            data: <String, dynamic>{
              'type': updated.type,
              'date': updated.date.toIso8601String(),
              'amount': updated.amount,
              'description': updated.description,
              'source_account_id': updated.sourceAccountId,
              'destination_account_id': updated.destinationAccountId,
              'category_id': updated.categoryId,
              'budget_id': updated.budgetId,
              'currency_code': updated.currencyCode,
              'foreign_amount': updated.foreignAmount,
              'foreign_currency_code': updated.foreignCurrencyCode,
              'notes': updated.notes,
              'tags': updated.tags,
            },
            createdAt: DateTime.now(),
            priority: 5,
          ),
        );
        logger.fine('Added transaction update to sync queue: $id');
      }
      
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
      
      // Add to sync queue if transaction was synced (has serverId)
      if (_syncQueueManager != null && existing.serverId != null) {
        await _syncQueueManager!.addOperation(
          SyncOperation(
            id: _uuidService.generate(),
            entityType: 'transaction',
            entityId: id,
            operationType: OperationType.delete,
            data: <String, dynamic>{
              'server_id': existing.serverId,
            },
            createdAt: DateTime.now(),
            priority: 5,
          ),
        );
        logger.fine('Added transaction deletion to sync queue: $id');
      }
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
      final query = _database.select(_database.transactions)
        ..where((t) => t.categoryId.equals(categoryId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]);
      final transactions = await query.get();
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

  // ========================================================================
  // OFFLINE CRUD OPERATIONS
  // ========================================================================

  /// Creates a transaction in offline mode
  ///
  /// Steps:
  /// 1. Validate transaction data
  /// 2. Generate UUID for new transaction
  /// 3. Set sync flags (is_synced = false, sync_status = 'pending')
  /// 4. Insert into local database
  /// 5. Add to sync queue
  /// 6. Invalidate cache
  ///
  /// Throws [ValidationException] if data is invalid
  /// Throws [DatabaseException] if insert fails
  Future<TransactionEntity> createTransactionOffline(
    Map<String, dynamic> data,
  ) async {
    logger.info('Creating transaction offline');

    try {
      // Step 1: Validate data
      final validationResult = _validator.validate(data);
      validationResult.throwIfInvalid();

      // Validate account references if provided
      if (data.containsKey('source_id') || data.containsKey('destination_id')) {
        final accountValidation = await _validator.validateAccountReferences(
          data,
          (accountId) async {
            final account = await _database
                .select(_database.accounts)
                .where((t) => t.id.equals(accountId))
                .getSingleOrNull();
            return account != null;
          },
        );
        accountValidation.throwIfInvalid();
      }

      // Step 2: Generate UUID
      final id = _uuidService.generateTransactionId();
      final now = DateTime.now();

      // Step 3 & 4: Insert with sync flags
      final companion = TransactionEntityCompanion.insert(
        id: id,
        type: data['type'] as String,
        date: data['date'] is DateTime
            ? data['date'] as DateTime
            : DateTime.parse(data['date'] as String),
        amount: (data['amount'] is double
            ? data['amount']
            : double.parse(data['amount'].toString())) as double,
        description: data['description'] as String,
        sourceAccountId: Value(data['source_id'] as String?),
        destinationAccountId: Value(data['destination_id'] as String?),
        categoryId: Value(data['category_id'] as String?),
        budgetId: Value(data['budget_id'] as String?),
        currencyCode: data['currency_code'] as String? ?? 'USD',
        foreignAmount: Value(data['foreign_amount'] as double?),
        foreignCurrencyCode: Value(data['foreign_currency_code'] as String?),
        notes: Value(data['notes'] as String?),
        tags: Value(data['tags'] as String?),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.into(_database.transactions).insert(companion);

      logger.info('Transaction inserted into database: $id');

      // Step 5: Add to sync queue
      if (_syncQueueManager != null) {
        final operation = SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'transaction',
          entityId: id,
          operation: SyncOperationType.create,
          payload: data,
          priority: SyncPriority.normal,
          createdAt: now,
        );

        await _syncQueueManager!.enqueue(operation);
        logger.info('Transaction added to sync queue: $id');
      }

      // Step 6: Invalidate cache
      _queryCache?.invalidatePattern('transactions_');

      // Retrieve and return created transaction
      final created = await getById(id);
      if (created == null) {
        throw const DatabaseException('Failed to retrieve created transaction');
      }

      logger.info('Transaction created successfully offline: $id');
      return created;
    } catch (e, stackTrace) {
      logger.severe('Failed to create transaction offline', e, stackTrace);
      if (e is ValidationException || e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to create transaction offline',
        {"error": e.toString()},
      );
    }
  }

  /// Updates a transaction in offline mode
  ///
  /// Steps:
  /// 1. Verify transaction exists
  /// 2. Validate updated data
  /// 3. Update timestamps and sync flags
  /// 4. Update in database
  /// 5. Add update operation to sync queue
  /// 6. Invalidate cache
  ///
  /// Throws [ValidationException] if data is invalid
  /// Throws [DatabaseException] if transaction not found or update fails
  Future<TransactionEntity> updateTransactionOffline(
    String id,
    Map<String, dynamic> data,
  ) async {
    logger.info('Updating transaction offline: $id');

    try {
      // Step 1: Verify exists
      final existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Transaction not found: $id');
      }

      // Step 2: Validate data
      final validationResult = _validator.validate(data);
      validationResult.throwIfInvalid();

      // Validate account references if changed
      if (data.containsKey('source_id') || data.containsKey('destination_id')) {
        final accountValidation = await _validator.validateAccountReferences(
          data,
          (accountId) async {
            final account = await _database
                .select(_database.accounts)
                .where((t) => t.id.equals(accountId))
                .getSingleOrNull();
            return account != null;
          },
        );
        accountValidation.throwIfInvalid();
      }

      // Step 3 & 4: Update with sync flags
      final companion = TransactionEntityCompanion(
        type: Value(data['type'] as String),
        date: Value(data['date'] is DateTime
            ? data['date'] as DateTime
            : DateTime.parse(data['date'] as String)),
        amount: Value((data['amount'] is double
            ? data['amount']
            : double.parse(data['amount'].toString())) as double),
        description: Value(data['description'] as String),
        sourceAccountId: Value(data['source_id'] as String?),
        destinationAccountId: Value(data['destination_id'] as String?),
        categoryId: Value(data['category_id'] as String?),
        budgetId: Value(data['budget_id'] as String?),
        currencyCode: Value(data['currency_code'] as String? ?? 'USD'),
        foreignAmount: Value(data['foreign_amount'] as double?),
        foreignCurrencyCode: Value(data['foreign_currency_code'] as String?),
        notes: Value(data['notes'] as String?),
        tags: Value(data['tags'] as String?),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      final updateQuery = _database.update(_database.transactions)
        ..where((t) => t.id.equals(id));
      await updateQuery.write(companion);

      logger.info('Transaction updated in database: $id');

      // Step 5: Add to sync queue
      if (_syncQueueManager != null) {
        final operation = SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'transaction',
          entityId: id,
          operation: SyncOperationType.update,
          payload: data,
          priority: SyncPriority.normal,
          createdAt: DateTime.now(),
        );

        await _syncQueueManager!.enqueue(operation);
        logger.info('Transaction update added to sync queue: $id');
      }

      // Step 6: Invalidate cache
      _queryCache?.invalidatePattern('transactions_');

      // Retrieve and return updated transaction
      final updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated transaction');
      }

      logger.info('Transaction updated successfully offline: $id');
      return updated;
    } catch (e, stackTrace) {
      logger.severe('Failed to update transaction offline: $id', e, stackTrace);
      if (e is ValidationException || e is DatabaseException) rethrow;
      throw DatabaseException(
        'Failed to update transaction offline',
        {"error": e.toString()},
      );
    }
  }

  /// Deletes a transaction in offline mode
  ///
  /// Steps:
  /// 1. Verify transaction exists
  /// 2. Check if transaction was synced (has server_id)
  /// 3. If synced: mark as deleted and add to sync queue
  /// 4. If not synced: remove from database and sync queue
  /// 5. Invalidate cache
  ///
  /// Throws [DatabaseException] if delete fails
  Future<void> deleteTransactionOffline(String id) async {
    logger.info('Deleting transaction offline: $id');

    try {
      // Step 1: Verify exists
      final existing = await getById(id);
      if (existing == null) {
        logger.warning('Transaction not found for deletion: $id');
        return;
      }

      // Step 2 & 3: Check sync status
      final wasSynced = existing.serverId != null && existing.serverId!.isNotEmpty;

      if (wasSynced) {
        // Mark as deleted, will be synced later
        logger.info('Transaction was synced, marking as deleted: $id');

        final companion = TransactionEntityCompanion(
          syncStatus: const Value('deleted'),
          isSynced: const Value(false),
          updatedAt: Value(DateTime.now()),
        );

        final updateQuery = _database.update(_database.transactions)
          ..where((t) => t.id.equals(id));
        await updateQuery.write(companion);

        // Add delete operation to sync queue
        if (_syncQueueManager != null) {
          final operation = SyncOperation(
            id: _uuidService.generateOperationId(),
            entityType: 'transaction',
            entityId: id,
            operation: SyncOperationType.delete,
            payload: {'server_id': existing.serverId},
            priority: SyncPriority.high, // DELETE has high priority
            createdAt: DateTime.now(),
          );

          await _syncQueueManager!.enqueue(operation);
          logger.info('Transaction delete added to sync queue: $id');
        }
      } else {
        // Step 4: Not synced, remove completely
        logger.info('Transaction not synced, removing from database: $id');

        final deleteQuery = _database.delete(_database.transactions)
          ..where((t) => t.id.equals(id));
        await deleteQuery.go();

        // Remove from sync queue if present
        if (_syncQueueManager != null) {
          await _syncQueueManager!.removeByEntityId('transaction', id);
          logger.fine('Removed transaction from sync queue: $id');
        }
      }

      // Step 5: Invalidate cache
      _queryCache?.invalidatePattern('transactions_');

      logger.info('Transaction deleted successfully offline: $id');
    } catch (e, stackTrace) {
      logger.severe('Failed to delete transaction offline: $id', e, stackTrace);
      throw DatabaseException(
        'Failed to delete transaction offline',
        {"error": e.toString()},
      );
    }
  }

  /// Gets transactions with filters and pagination
  ///
  /// Supports:
  /// - Date range filtering
  /// - Account filtering
  /// - Category filtering
  /// - Search by description
  /// - Pagination (limit/offset)
  /// - Caching
  ///
  /// Returns sorted results (newest first)
  Future<List<TransactionEntity>> getTransactionsOffline({
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? categoryId,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    logger.fine('Fetching transactions offline with filters');

    try {
      // Build cache key
      final cacheKey = 'transactions_'
          '${startDate?.toIso8601String() ?? 'all'}_'
          '${endDate?.toIso8601String() ?? 'all'}_'
          '${accountId ?? 'all'}_'
          '${categoryId ?? 'all'}_'
          '${searchQuery ?? 'all'}_'
          '${limit}_$offset';

      // Check cache
      final cached = _queryCache?.get<List<TransactionEntity>>(cacheKey);
      if (cached != null) {
        logger.fine('Returning cached transactions');
        return cached;
      }

      // Build query
      var query = _database.select(_database.transactions);

      // Apply filters
      if (startDate != null) {
        query = query..where((t) => t.date.isBiggerOrEqualValue(startDate));
      }

      if (endDate != null) {
        query = query..where((t) => t.date.isSmallerOrEqualValue(endDate));
      }

      if (accountId != null) {
        query = query
          ..where((t) =>
              t.sourceAccountId.equals(accountId) |
              t.destinationAccountId.equals(accountId));
      }

      if (categoryId != null) {
        query = query..where((t) => t.categoryId.equals(categoryId));
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query
          ..where((t) => t.description.contains(searchQuery) |
              (t.notes.isNotNull() & t.notes.contains(searchQuery)));
      }

      // Exclude deleted transactions
      query = query..where((t) => t.syncStatus.equals('deleted').not());

      // Order by date (newest first)
      query = query..orderBy([(t) => OrderingTerm.desc(t.date)]);

      // Apply pagination
      query = query
        ..limit(limit, offset: offset);

      final transactions = await query.get();

      logger.info('Found ${transactions.length} transactions with filters');

      // Cache results
      _queryCache?.put(cacheKey, transactions, ttl: const Duration(minutes: 5));

      return transactions;
    } catch (e, stackTrace) {
      logger.severe('Failed to fetch transactions offline', e, stackTrace);
      throw DatabaseException(
        'Failed to fetch transactions offline',
        {"error": e.toString()},
      );
    }
  }

  /// Gets recent transactions (last 30 days)
  ///
  /// Convenience method with caching
  Future<List<TransactionEntity>> getRecentTransactions({
    int limit = 50,
  }) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 30));

    return getTransactionsOffline(
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Searches transactions by description or notes
  ///
  /// Case-insensitive search with caching
  Future<List<TransactionEntity>> searchTransactions(
    String query, {
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    return getTransactionsOffline(
      searchQuery: query.trim(),
      limit: limit,
    );
  }
}
