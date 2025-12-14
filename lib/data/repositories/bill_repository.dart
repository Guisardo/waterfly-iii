import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/models/sync_operation.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';
import 'package:waterflyiii/validators/bill_validator.dart';
import 'package:waterflyiii/validators/transaction_validator.dart';

import 'package:waterflyiii/data/repositories/base_repository.dart';

/// Repository for managing bill data with full offline support.
///
/// Provides comprehensive CRUD operations for bills with:
/// - Automatic sync queue integration
/// - Data validation
/// - Recurrence calculations
/// - Comprehensive error handling and logging
class BillRepository implements BaseRepository<BillEntity, String> {
  /// Creates a bill repository with required dependencies.
  BillRepository({
    required AppDatabase database,
    UuidService? uuidService,
    SyncQueueManager? syncQueueManager,
    BillValidator? validator,
  })  : _database = database,
        _uuidService = uuidService ?? UuidService(),
        _syncQueueManager = syncQueueManager ?? SyncQueueManager(database),
        _validator = validator ?? BillValidator();

  final AppDatabase _database;
  final UuidService _uuidService;
  final SyncQueueManager _syncQueueManager;
  final BillValidator _validator;

  @override
  final Logger logger = Logger('BillRepository');

  @override
  Future<List<BillEntity>> getAll() async {
    try {
      logger.fine('Fetching all bills');
      final List<BillEntity> bills = await (_database.select(_database.bills)
            ..orderBy(<OrderClauseGenerator<$BillsTable>>[($BillsTable b) => OrderingTerm.asc(b.name)]))
          .get();
      logger.info('Retrieved ${bills.length} bills');
      return bills;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch bills', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM bills',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<BillEntity>> watchAll() {
    logger.fine('Watching all bills');
    return (_database.select(_database.bills)..orderBy(<OrderClauseGenerator<$BillsTable>>[($BillsTable b) => OrderingTerm.asc(b.name)])).watch();
  }

  @override
  Future<BillEntity?> getById(String id) async {
    try {
      logger.fine('Fetching bill by ID: $id');
      final SimpleSelectStatement<$BillsTable, BillEntity> query = _database.select(_database.bills)
        ..where(($BillsTable b) => b.id.equals(id));
      final BillEntity? bill = await query.getSingleOrNull();

      if (bill != null) {
        logger.fine('Found bill: $id');
      } else {
        logger.fine('Bill not found: $id');
      }

      return bill;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch bill $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM bills WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<BillEntity?> watchById(String id) {
    logger.fine('Watching bill: $id');
    final SimpleSelectStatement<$BillsTable, BillEntity> query = _database.select(_database.bills)
      ..where(($BillsTable b) => b.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<BillEntity> create(BillEntity entity) async {
    try {
      logger.info('Creating bill: ${entity.name}');

      // Validate bill data
      final ValidationResult validationResult = await _validator.validate({
        'name': entity.name,
        'amount_min': entity.amountMin,
        'amount_max': entity.amountMax,
        'currency_code': entity.currencyCode,
        'date': entity.date.toIso8601String(),
        'repeat_freq': entity.repeatFreq,
      });
      if (!validationResult.isValid) {
        final String errorMessage = 'Bill validation failed: ${validationResult.errors.join(', ')}';
        logger.warning(errorMessage);
        throw ValidationException(errorMessage);
      }

      final String id = entity.id.isEmpty ? _uuidService.generateBillId() : entity.id;
      final DateTime now = DateTime.now();

      final BillEntityCompanion companion = BillEntityCompanion.insert(
        id: id,
        serverId: Value(entity.serverId),
        name: entity.name,
        amountMin: entity.amountMin,
        amountMax: entity.amountMax,
        currencyCode: entity.currencyCode,
        date: entity.date,
        repeatFreq: entity.repeatFreq,
        skip: Value(entity.skip),
        active: Value(entity.active),
        notes: Value(entity.notes),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.into(_database.bills).insert(companion);

      final BillEntity? created = await getById(id);
      if (created == null) {
        throw const DatabaseException('Failed to retrieve created bill');
      }

      // Add to sync queue
      await _syncQueueManager.enqueue(
        SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'bill',
          entityId: id,
          operation: SyncOperationType.create,
          payload: <String, dynamic>{
            'name': entity.name,
            'amount_min': entity.amountMin,
            'amount_max': entity.amountMax,
            'currency_code': entity.currencyCode,
            'date': entity.date.toIso8601String(),
            'repeat_freq': entity.repeatFreq,
            'skip': entity.skip,
            'active': entity.active,
            'notes': entity.notes,
          },
          createdAt: now,
          attempts: 0,
          status: SyncOperationStatus.pending,
          priority: SyncPriority.normal,
        ),
      );

      logger.info('Bill created successfully: $id');
      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create bill', error, stackTrace);
      if (error is DatabaseException || error is ValidationException) rethrow;
      throw DatabaseException('Failed to create bill: $error');
    }
  }

  @override
  Future<BillEntity> update(String id, BillEntity entity) async {
    try {
      logger.info('Updating bill: $id');

      final BillEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Bill not found: $id');
      }

      // Validate bill data
      final ValidationResult validationResult = await _validator.validate({
        'name': entity.name,
        'amount_min': entity.amountMin,
        'amount_max': entity.amountMax,
        'currency_code': entity.currencyCode,
        'date': entity.date.toIso8601String(),
        'repeat_freq': entity.repeatFreq,
      });
      if (!validationResult.isValid) {
        final String errorMessage = 'Bill validation failed: ${validationResult.errors.join(', ')}';
        logger.warning(errorMessage);
        throw ValidationException(errorMessage);
      }

      final DateTime now = DateTime.now();

      final BillEntityCompanion companion = BillEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        name: Value(entity.name),
        amountMin: Value(entity.amountMin),
        amountMax: Value(entity.amountMax),
        currencyCode: Value(entity.currencyCode),
        date: Value(entity.date),
        repeatFreq: Value(entity.repeatFreq),
        skip: Value(entity.skip),
        active: Value(entity.active),
        notes: Value(entity.notes),
        updatedAt: Value(now),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.update(_database.bills).replace(companion);

      final BillEntity? updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated bill');
      }

      // Add to sync queue
      await _syncQueueManager.enqueue(
        SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'bill',
          entityId: id,
          operation: SyncOperationType.update,
          payload: <String, dynamic>{
            'name': entity.name,
            'amount_min': entity.amountMin,
            'amount_max': entity.amountMax,
            'currency_code': entity.currencyCode,
            'date': entity.date.toIso8601String(),
            'repeat_freq': entity.repeatFreq,
            'skip': entity.skip,
            'active': entity.active,
            'notes': entity.notes,
          },
          createdAt: now,
          attempts: 0,
          status: SyncOperationStatus.pending,
          priority: SyncPriority.normal,
        ),
      );

      logger.info('Bill updated successfully: $id');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update bill $id', error, stackTrace);
      if (error is DatabaseException || error is ValidationException) rethrow;
      throw DatabaseException('Failed to update bill: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting bill: $id');

      final BillEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Bill not found: $id');
      }

      // Check if bill has server ID (was synced)
      final bool wasSynced = existing.serverId != null && existing.serverId!.isNotEmpty;

      if (wasSynced) {
        // Mark as deleted and add to sync queue
        await (_database.update(_database.bills)..where(($BillsTable b) => b.id.equals(id))).write(
          BillEntityCompanion(
            isSynced: const Value(false),
            syncStatus: const Value('pending_delete'),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await _syncQueueManager.enqueue(
          SyncOperation(
            id: _uuidService.generateOperationId(),
            entityType: 'bill',
            entityId: id,
            operation: SyncOperationType.delete,
            payload: <String, dynamic>{'server_id': existing.serverId},
            createdAt: DateTime.now(),
            attempts: 0,
            status: SyncOperationStatus.pending,
            priority: SyncPriority.high,
          ),
        );
      } else {
        // Not synced, just delete locally
        await (_database.delete(_database.bills)..where(($BillsTable b) => b.id.equals(id))).go();
      }

      logger.info('Bill deleted successfully: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete bill $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete bill: $error');
    }
  }

  @override
  Future<List<BillEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced bills');
      final SimpleSelectStatement<$BillsTable, BillEntity> query = _database.select(_database.bills)
        ..where(($BillsTable b) => b.isSynced.equals(false));
      final List<BillEntity> bills = await query.get();
      logger.info('Found ${bills.length} unsynced bills');
      return bills;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced bills', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM bills WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking bill as synced: $localId -> $serverId');

      await (_database.update(_database.bills)..where(($BillsTable b) => b.id.equals(localId))).write(
        BillEntityCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      logger.info('Bill marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe('Failed to mark bill as synced: $localId', error, stackTrace);
      throw DatabaseException('Failed to mark bill as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final BillEntity? bill = await getById(id);
      if (bill == null) {
        throw DatabaseException('Bill not found: $id');
      }
      return bill.syncStatus;
    } catch (error, stackTrace) {
      logger.severe('Failed to get sync status for bill $id', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all bills from cache');
      await _database.delete(_database.bills).go();
      logger.info('Bill cache cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear bill cache', error, stackTrace);
      throw DatabaseException('Failed to clear bill cache: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting bills');
      final int count = await _database.select(_database.bills).get().then((List<BillEntity> list) => list.length);
      logger.fine('Bill count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count bills', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM bills',
        error,
        stackTrace,
      );
    }
  }

  /// Get active bills only.
  Future<List<BillEntity>> getActive() async {
    try {
      logger.fine('Fetching active bills');
      final SimpleSelectStatement<$BillsTable, BillEntity> query = _database.select(_database.bills)
        ..where(($BillsTable b) => b.active.equals(true))
        ..orderBy(<OrderClauseGenerator<$BillsTable>>[($BillsTable b) => OrderingTerm.asc(b.name)]);
      final List<BillEntity> bills = await query.get();
      logger.info('Found ${bills.length} active bills');
      return bills;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch active bills', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM bills WHERE active = true',
        error,
        stackTrace,
      );
    }
  }

  /// Get bills by repeat frequency.
  Future<List<BillEntity>> getByFrequency(String frequency) async {
    try {
      logger.fine('Fetching bills by frequency: $frequency');
      final SimpleSelectStatement<$BillsTable, BillEntity> query = _database.select(_database.bills)
        ..where(($BillsTable b) => b.repeatFreq.equals(frequency))
        ..orderBy(<OrderClauseGenerator<$BillsTable>>[($BillsTable b) => OrderingTerm.asc(b.name)]);
      final List<BillEntity> bills = await query.get();
      logger.info('Found ${bills.length} bills with frequency: $frequency');
      return bills;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch bills by frequency: $frequency', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM bills WHERE repeat_freq = $frequency',
        error,
        stackTrace,
      );
    }
  }

  /// Calculate next due date for a bill based on its recurrence.
  DateTime calculateNextDueDate(BillEntity bill) {
    logger.fine('Calculating next due date for bill: ${bill.id}');
    
    final DateTime baseDate = bill.date;
    final DateTime now = DateTime.now();
    
    // If bill date is in the future, return it
    if (baseDate.isAfter(now)) {
      return baseDate;
    }
    
    // Calculate next occurrence based on frequency
    DateTime nextDate = baseDate;
    switch (bill.repeatFreq.toLowerCase()) {
      case 'daily':
        while (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 1));
        }
        break;
      case 'weekly':
        while (nextDate.isBefore(now)) {
          nextDate = nextDate.add(const Duration(days: 7));
        }
        break;
      case 'monthly':
        while (nextDate.isBefore(now)) {
          nextDate = DateTime(nextDate.year, nextDate.month + 1, nextDate.day);
        }
        break;
      case 'quarterly':
        while (nextDate.isBefore(now)) {
          nextDate = DateTime(nextDate.year, nextDate.month + 3, nextDate.day);
        }
        break;
      case 'yearly':
        while (nextDate.isBefore(now)) {
          nextDate = DateTime(nextDate.year + 1, nextDate.month, nextDate.day);
        }
        break;
      default:
        logger.warning('Unknown repeat frequency: ${bill.repeatFreq}');
        return baseDate;
    }
    
    logger.fine('Next due date for bill ${bill.id}: $nextDate');
    return nextDate;
  }
}
