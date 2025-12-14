import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/models/sync_operation.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';
import 'package:waterflyiii/validators/piggy_bank_validator.dart';
import 'package:waterflyiii/validators/transaction_validator.dart';

import 'package:waterflyiii/data/repositories/base_repository.dart';

/// Repository for managing piggy bank data with full offline support.
///
/// Provides comprehensive CRUD operations for piggy banks with:
/// - Automatic sync queue integration
/// - Data validation
/// - Balance tracking and validation
/// - Money add/remove operations
/// - Comprehensive error handling and logging
class PiggyBankRepository implements BaseRepository<PiggyBankEntity, String> {
  /// Creates a piggy bank repository with required dependencies.
  PiggyBankRepository({
    required AppDatabase database,
    UuidService? uuidService,
    SyncQueueManager? syncQueueManager,
    PiggyBankValidator? validator,
  })  : _database = database,
        _uuidService = uuidService ?? UuidService(),
        _syncQueueManager = syncQueueManager ?? SyncQueueManager(database),
        _validator = validator ?? PiggyBankValidator();

  final AppDatabase _database;
  final UuidService _uuidService;
  final SyncQueueManager _syncQueueManager;
  final PiggyBankValidator _validator;

  @override
  final Logger logger = Logger('PiggyBankRepository');

  @override
  Future<List<PiggyBankEntity>> getAll() async {
    try {
      logger.fine('Fetching all piggy banks');
      final List<PiggyBankEntity> piggyBanks = await (_database.select(_database.piggyBanks)
            ..orderBy(<OrderClauseGenerator<$PiggyBanksTable>>[($PiggyBanksTable p) => OrderingTerm.asc(p.name)]))
          .get();
      logger.info('Retrieved ${piggyBanks.length} piggy banks');
      return piggyBanks;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch piggy banks', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM piggy_banks',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<PiggyBankEntity>> watchAll() {
    logger.fine('Watching all piggy banks');
    return (_database.select(_database.piggyBanks)..orderBy(<OrderClauseGenerator<$PiggyBanksTable>>[($PiggyBanksTable p) => OrderingTerm.asc(p.name)])).watch();
  }

  @override
  Future<PiggyBankEntity?> getById(String id) async {
    try {
      logger.fine('Fetching piggy bank by ID: $id');
      final SimpleSelectStatement<$PiggyBanksTable, PiggyBankEntity> query = _database.select(_database.piggyBanks)
        ..where(($PiggyBanksTable p) => p.id.equals(id));
      final PiggyBankEntity? piggyBank = await query.getSingleOrNull();

      if (piggyBank != null) {
        logger.fine('Found piggy bank: $id');
      } else {
        logger.fine('Piggy bank not found: $id');
      }

      return piggyBank;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch piggy bank $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM piggy_banks WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<PiggyBankEntity?> watchById(String id) {
    logger.fine('Watching piggy bank: $id');
    final SimpleSelectStatement<$PiggyBanksTable, PiggyBankEntity> query = _database.select(_database.piggyBanks)
      ..where(($PiggyBanksTable p) => p.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<PiggyBankEntity> create(PiggyBankEntity entity) async {
    try {
      logger.info('Creating piggy bank: ${entity.name}');

      final Map<String, dynamic> entityMap = {
        'id': entity.id,
        'serverId': entity.serverId,
        'name': entity.name,
        'accountId': entity.accountId,
        'targetAmount': entity.targetAmount,
        'currentAmount': entity.currentAmount,
        'startDate': entity.startDate?.toIso8601String(),
        'targetDate': entity.targetDate?.toIso8601String(),
        'notes': entity.notes,
      };

      final ValidationResult validationResult = await _validator.validate(entityMap);
      if (!validationResult.isValid) {
        final String errorMessage = 'Piggy bank validation failed: ${validationResult.errors.join(', ')}';
        logger.warning(errorMessage);
        throw ValidationException(errorMessage, {'errors': validationResult.errors});
      }

      final String id = entity.id.isEmpty ? _uuidService.generatePiggyBankId() : entity.id;
      final DateTime now = DateTime.now();

      final PiggyBankEntityCompanion companion = PiggyBankEntityCompanion.insert(
        id: id,
        serverId: Value.ofNullable(entity.serverId),
        name: entity.name,
        accountId: entity.accountId,
        targetAmount: Value.ofNullable(entity.targetAmount),
        currentAmount: Value(entity.currentAmount),
        startDate: Value.ofNullable(entity.startDate),
        targetDate: Value.ofNullable(entity.targetDate),
        notes: Value.ofNullable(entity.notes),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.into(_database.piggyBanks).insert(companion);

      final PiggyBankEntity? created = await getById(id);
      if (created == null) {
        throw const DatabaseException('Failed to retrieve created piggy bank');
      }

      // Add to sync queue
      await _syncQueueManager.enqueue(
        SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'piggy_bank',
          entityId: id,
          operation: SyncOperationType.create,
          payload: <String, dynamic>{
            'name': entity.name,
            'account_id': entity.accountId,
            'target_amount': entity.targetAmount,
            'current_amount': entity.currentAmount,
            'start_date': entity.startDate?.toIso8601String(),
            'target_date': entity.targetDate?.toIso8601String(),
            'notes': entity.notes,
          },
          createdAt: now,
          attempts: 0,
          status: SyncOperationStatus.pending,
          priority: SyncPriority.normal,
        ),
      );

      logger.info('Piggy bank created successfully: $id');
      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create piggy bank', error, stackTrace);
      if (error is DatabaseException || error is ValidationException) rethrow;
      throw DatabaseException('Failed to create piggy bank: $error');
    }
  }

  @override
  Future<PiggyBankEntity> update(String id, PiggyBankEntity entity) async {
    try {
      logger.info('Updating piggy bank: $id');

      final PiggyBankEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Piggy bank not found: $id');
      }

      final Map<String, dynamic> entityMap = {
        'id': entity.id,
        'serverId': entity.serverId,
        'name': entity.name,
        'accountId': entity.accountId,
        'targetAmount': entity.targetAmount,
        'currentAmount': entity.currentAmount,
        'startDate': entity.startDate?.toIso8601String(),
        'targetDate': entity.targetDate?.toIso8601String(),
        'notes': entity.notes,
      };

      final ValidationResult validationResult = await _validator.validate(entityMap);
      if (!validationResult.isValid) {
        final String errorMessage = 'Piggy bank validation failed: ${validationResult.errors.join(', ')}';
        logger.warning(errorMessage);
        throw ValidationException(errorMessage, {'errors': validationResult.errors});
      }

      final DateTime now = DateTime.now();

      final PiggyBankEntityCompanion companion = PiggyBankEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        name: Value(entity.name),
        accountId: Value(entity.accountId),
        targetAmount: Value(entity.targetAmount),
        currentAmount: Value(entity.currentAmount),
        startDate: Value(entity.startDate),
        targetDate: Value(entity.targetDate),
        notes: Value(entity.notes),
        updatedAt: Value(now),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.update(_database.piggyBanks).replace(companion);

      final PiggyBankEntity? updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated piggy bank');
      }

      // Add to sync queue
      await _syncQueueManager.enqueue(
        SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'piggy_bank',
          entityId: id,
          operation: SyncOperationType.update,
          payload: <String, dynamic>{
            'name': entity.name,
            'account_id': entity.accountId,
            'target_amount': entity.targetAmount,
            'current_amount': entity.currentAmount,
            'start_date': entity.startDate?.toIso8601String(),
            'target_date': entity.targetDate?.toIso8601String(),
            'notes': entity.notes,
          },
          createdAt: now,
          attempts: 0,
          status: SyncOperationStatus.pending,
          priority: SyncPriority.normal,
        ),
      );

      logger.info('Piggy bank updated successfully: $id');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update piggy bank $id', error, stackTrace);
      if (error is DatabaseException || error is ValidationException) rethrow;
      throw DatabaseException('Failed to update piggy bank: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting piggy bank: $id');

      final PiggyBankEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Piggy bank not found: $id');
      }

      // Check if piggy bank has server ID (was synced)
      final bool wasSynced = existing.serverId != null && existing.serverId!.isNotEmpty;

      if (wasSynced) {
        // Mark as deleted and add to sync queue
        await (_database.update(_database.piggyBanks)..where(($PiggyBanksTable p) => p.id.equals(id))).write(
          PiggyBankEntityCompanion(
            isSynced: const Value(false),
            syncStatus: const Value('pending_delete'),
            updatedAt: Value(DateTime.now()),
          ),
        );

        await _syncQueueManager.enqueue(
          SyncOperation(
            id: _uuidService.generateOperationId(),
            entityType: 'piggy_bank',
            entityId: id,
            operation: SyncOperationType.delete,
            payload: <String, dynamic>{'server_id': existing.serverId},
            createdAt: DateTime.now(),
            attempts: 0,
            status: SyncOperationStatus.pending,
            priority: SyncPriority.high, // High priority for deletes
          ),
        );
      } else {
        // Not synced, just delete locally
        await (_database.delete(_database.piggyBanks)..where(($PiggyBanksTable p) => p.id.equals(id))).go();
      }

      logger.info('Piggy bank deleted successfully: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete piggy bank $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete piggy bank: $error');
    }
  }

  @override
  Future<List<PiggyBankEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced piggy banks');
      final SimpleSelectStatement<$PiggyBanksTable, PiggyBankEntity> query = _database.select(_database.piggyBanks)
        ..where(($PiggyBanksTable p) => p.isSynced.equals(false));
      final List<PiggyBankEntity> piggyBanks = await query.get();
      logger.info('Found ${piggyBanks.length} unsynced piggy banks');
      return piggyBanks;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced piggy banks', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM piggy_banks WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking piggy bank as synced: $localId -> $serverId');

      await (_database.update(_database.piggyBanks)..where(($PiggyBanksTable p) => p.id.equals(localId))).write(
        PiggyBankEntityCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      logger.info('Piggy bank marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe('Failed to mark piggy bank as synced: $localId', error, stackTrace);
      throw DatabaseException('Failed to mark piggy bank as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final PiggyBankEntity? piggyBank = await getById(id);
      if (piggyBank == null) {
        throw DatabaseException('Piggy bank not found: $id');
      }
      return piggyBank.syncStatus;
    } catch (error, stackTrace) {
      logger.severe('Failed to get sync status for piggy bank $id', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all piggy banks from cache');
      await _database.delete(_database.piggyBanks).go();
      logger.info('Piggy bank cache cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear piggy bank cache', error, stackTrace);
      throw DatabaseException('Failed to clear piggy bank cache: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting piggy banks');
      final int count = await _database.select(_database.piggyBanks).get().then((List<PiggyBankEntity> list) => list.length);
      logger.fine('Piggy bank count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count piggy banks', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM piggy_banks',
        error,
        stackTrace,
      );
    }
  }

  /// Add money to a piggy bank.
  Future<PiggyBankEntity> addMoney(String id, double amount) async {
    try {
      logger.info('Adding $amount to piggy bank: $id');

      if (amount <= 0) {
        throw ValidationException('Amount must be positive', {'amount': 'must be > 0'});
      }

      final PiggyBankEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Piggy bank not found: $id');
      }

      final double newAmount = existing.currentAmount + amount;
      final double? target = existing.targetAmount;

      if (target != null && newAmount > target) {
        logger.warning('Adding $amount would exceed target amount');
        throw ValidationException(
          'Amount would exceed target',
          {'current': existing.currentAmount, 'adding': amount, 'target': target},
        );
      }

      final DateTime now = DateTime.now();

      await (_database.update(_database.piggyBanks)..where(($PiggyBanksTable p) => p.id.equals(id))).write(
        PiggyBankEntityCompanion(
          currentAmount: Value(newAmount),
          updatedAt: Value(now),
          isSynced: const Value(false),
          syncStatus: const Value('pending'),
        ),
      );

      final PiggyBankEntity? updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated piggy bank');
      }

      await _syncQueueManager.enqueue(
        SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'piggy_bank',
          entityId: id,
          operation: SyncOperationType.update,
          payload: <String, dynamic>{
            'amount': amount,
            'new_total': newAmount,
          },
          createdAt: now,
          attempts: 0,
          status: SyncOperationStatus.pending,
          priority: SyncPriority.normal,
        ),
      );

      logger.info('Added $amount to piggy bank $id, new balance: $newAmount');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to add money to piggy bank $id', error, stackTrace);
      if (error is DatabaseException || error is ValidationException) rethrow;
      throw DatabaseException('Failed to add money to piggy bank: $error');
    }
  }

  /// Remove money from a piggy bank.
  Future<PiggyBankEntity> removeMoney(String id, double amount) async {
    try {
      logger.info('Removing $amount from piggy bank: $id');

      if (amount <= 0) {
        throw ValidationException('Amount must be positive', {'amount': 'must be > 0'});
      }

      final PiggyBankEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Piggy bank not found: $id');
      }

      final double newAmount = existing.currentAmount - amount;

      if (newAmount < 0) {
        logger.warning('Removing $amount would result in negative balance');
        throw ValidationException(
          'Insufficient funds',
          {'current': existing.currentAmount, 'removing': amount},
        );
      }

      final DateTime now = DateTime.now();

      await (_database.update(_database.piggyBanks)..where(($PiggyBanksTable p) => p.id.equals(id))).write(
        PiggyBankEntityCompanion(
          currentAmount: Value(newAmount),
          updatedAt: Value(now),
          isSynced: const Value(false),
          syncStatus: const Value('pending'),
        ),
      );

      final PiggyBankEntity? updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated piggy bank');
      }

      await _syncQueueManager.enqueue(
        SyncOperation(
          id: _uuidService.generateOperationId(),
          entityType: 'piggy_bank',
          entityId: id,
          operation: SyncOperationType.update,
          payload: <String, dynamic>{
            'amount': amount,
            'new_total': newAmount,
          },
          createdAt: now,
          attempts: 0,
          status: SyncOperationStatus.pending,
          priority: SyncPriority.normal,
        ),
      );

      logger.info('Removed $amount from piggy bank $id, new balance: $newAmount');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to remove money from piggy bank $id', error, stackTrace);
      if (error is DatabaseException || error is ValidationException) rethrow;
      throw DatabaseException('Failed to remove money from piggy bank: $error');
    }
  }

  /// Get piggy banks by account.
  Future<List<PiggyBankEntity>> getByAccount(String accountId) async {
    try {
      logger.fine('Fetching piggy banks for account: $accountId');
      final SimpleSelectStatement<$PiggyBanksTable, PiggyBankEntity> query = _database.select(_database.piggyBanks)
        ..where(($PiggyBanksTable p) => p.accountId.equals(accountId))
        ..orderBy(<OrderClauseGenerator<$PiggyBanksTable>>[($PiggyBanksTable p) => OrderingTerm.asc(p.name)]);
      final List<PiggyBankEntity> piggyBanks = await query.get();
      logger.info('Found ${piggyBanks.length} piggy banks for account: $accountId');
      return piggyBanks;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch piggy banks for account: $accountId', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM piggy_banks WHERE account_id = $accountId',
        error,
        stackTrace,
      );
    }
  }

  /// Calculate progress percentage for a piggy bank.
  double calculateProgress(PiggyBankEntity piggyBank) {
    final double? target = piggyBank.targetAmount;
    if (target == null || target <= 0) {
      return 0.0;
    }
    final double progress = (piggyBank.currentAmount / target) * 100;
    return progress.clamp(0.0, 100.0);
  }

  /// Check if piggy bank has reached its target.
  bool hasReachedTarget(PiggyBankEntity piggyBank) {
    final double? target = piggyBank.targetAmount;
    if (target == null) return false;
    return piggyBank.currentAmount >= target;
  }

  /// Get piggy banks that have reached their target.
  Future<List<PiggyBankEntity>> getCompleted() async {
    try {
      logger.fine('Fetching completed piggy banks');
      final List<PiggyBankEntity> allPiggyBanks = await getAll();
      final List<PiggyBankEntity> completed = allPiggyBanks.where((PiggyBankEntity p) => hasReachedTarget(p)).toList();
      logger.info('Found ${completed.length} completed piggy banks');
      return completed;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch completed piggy banks', error, stackTrace);
      rethrow;
    }
  }
}
