import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/services/uuid/uuid_service.dart';

import 'package:waterflyiii/data/repositories/base_repository.dart';

/// Repository for managing budget data.
///
/// Handles CRUD operations for budgets, automatically routing to
/// local storage or remote API based on the current app mode.
class BudgetRepository implements BaseRepository<BudgetEntity, String> {
  /// Creates a budget repository.
  BudgetRepository({
    required AppDatabase database,
    UuidService? uuidService,
  })  : _database = database,
        _uuidService = uuidService ?? UuidService();

  final AppDatabase _database;
  final UuidService _uuidService;

  @override
  final Logger logger = Logger('BudgetRepository');

  @override
  Future<List<BudgetEntity>> getAll() async {
    try {
      logger.fine('Fetching all budgets');
      final List<BudgetEntity> budgets = await (_database.select(_database.budgets)
            ..orderBy(<OrderClauseGenerator<$BudgetsTable>>[($BudgetsTable b) => OrderingTerm.asc(b.name)]))
          .get();
      logger.info('Retrieved ${budgets.length} budgets');
      return budgets;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch budgets', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM budgets',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<List<BudgetEntity>> watchAll() {
    logger.fine('Watching all budgets');
    return (_database.select(_database.budgets)..orderBy(<OrderClauseGenerator<$BudgetsTable>>[($BudgetsTable b) => OrderingTerm.asc(b.name)]))
        .watch();
  }

  @override
  Future<BudgetEntity?> getById(String id) async {
    try {
      logger.fine('Fetching budget by ID: $id');
      final SimpleSelectStatement<$BudgetsTable, BudgetEntity> query = _database.select(_database.budgets)..where(($BudgetsTable b) => b.id.equals(id));
      final BudgetEntity? budget = await query.getSingleOrNull();

      if (budget != null) {
        logger.fine('Found budget: $id');
      } else {
        logger.fine('Budget not found: $id');
      }

      return budget;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch budget $id', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM budgets WHERE id = $id',
        error,
        stackTrace,
      );
    }
  }

  @override
  Stream<BudgetEntity?> watchById(String id) {
    logger.fine('Watching budget: $id');
    final SimpleSelectStatement<$BudgetsTable, BudgetEntity> query = _database.select(_database.budgets)..where(($BudgetsTable b) => b.id.equals(id));
    return query.watchSingleOrNull();
  }

  @override
  Future<BudgetEntity> create(BudgetEntity entity) async {
    try {
      logger.info('Creating budget');

      final String id = entity.id.isEmpty ? _uuidService.generateBudgetId() : entity.id;
      final DateTime now = DateTime.now();

      final BudgetEntityCompanion companion = BudgetEntityCompanion.insert(
        id: id,
        serverId: Value(entity.serverId),
        name: entity.name,
        active: Value(entity.active),
        autoBudgetType: Value(entity.autoBudgetType),
        autoBudgetAmount: Value(entity.autoBudgetAmount),
        autoBudgetPeriod: Value(entity.autoBudgetPeriod),
        createdAt: now,
        updatedAt: now,
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.into(_database.budgets).insert(companion);

      final BudgetEntity? created = await getById(id);
      if (created == null) {
        throw const DatabaseException('Failed to retrieve created budget');
      }

      logger.info('Budget created successfully: $id');
      return created;
    } catch (error, stackTrace) {
      logger.severe('Failed to create budget', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to create budget: $error');
    }
  }

  @override
  Future<BudgetEntity> update(String id, BudgetEntity entity) async {
    try {
      logger.info('Updating budget: $id');

      final BudgetEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Budget not found: $id');
      }

      final BudgetEntityCompanion companion = BudgetEntityCompanion(
        id: Value(id),
        serverId: Value(entity.serverId),
        name: Value(entity.name),
        active: Value(entity.active),
        autoBudgetType: Value(entity.autoBudgetType),
        autoBudgetAmount: Value(entity.autoBudgetAmount),
        autoBudgetPeriod: Value(entity.autoBudgetPeriod),
        updatedAt: Value(DateTime.now()),
        isSynced: const Value(false),
        syncStatus: const Value('pending'),
      );

      await _database.update(_database.budgets).replace(companion);

      final BudgetEntity? updated = await getById(id);
      if (updated == null) {
        throw const DatabaseException('Failed to retrieve updated budget');
      }

      logger.info('Budget updated successfully: $id');
      return updated;
    } catch (error, stackTrace) {
      logger.severe('Failed to update budget $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to update budget: $error');
    }
  }

  @override
  Future<void> delete(String id) async {
    try {
      logger.info('Deleting budget: $id');

      final BudgetEntity? existing = await getById(id);
      if (existing == null) {
        throw DatabaseException('Budget not found: $id');
      }

      await (_database.delete(_database.budgets)..where(($BudgetsTable b) => b.id.equals(id))).go();

      logger.info('Budget deleted successfully: $id');
    } catch (error, stackTrace) {
      logger.severe('Failed to delete budget $id', error, stackTrace);
      if (error is DatabaseException) rethrow;
      throw DatabaseException('Failed to delete budget: $error');
    }
  }

  @override
  Future<List<BudgetEntity>> getUnsynced() async {
    try {
      logger.fine('Fetching unsynced budgets');
      final SimpleSelectStatement<$BudgetsTable, BudgetEntity> query = _database.select(_database.budgets)
        ..where(($BudgetsTable b) => b.isSynced.equals(false));
      final List<BudgetEntity> budgets = await query.get();
      logger.info('Found ${budgets.length} unsynced budgets');
      return budgets;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch unsynced budgets', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM budgets WHERE is_synced = false',
        error,
        stackTrace,
      );
    }
  }

  @override
  Future<void> markAsSynced(String localId, String serverId) async {
    try {
      logger.info('Marking budget as synced: $localId -> $serverId');

      await (_database.update(_database.budgets)..where(($BudgetsTable b) => b.id.equals(localId))).write(
        BudgetEntityCompanion(
          serverId: Value(serverId),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
          updatedAt: Value(DateTime.now()),
        ),
      );

      logger.info('Budget marked as synced: $localId');
    } catch (error, stackTrace) {
      logger.severe('Failed to mark budget as synced: $localId', error, stackTrace);
      throw DatabaseException('Failed to mark budget as synced: $error');
    }
  }

  @override
  Future<String> getSyncStatus(String id) async {
    try {
      final BudgetEntity? budget = await getById(id);
      if (budget == null) {
        throw DatabaseException('Budget not found: $id');
      }
      return budget.syncStatus;
    } catch (error, stackTrace) {
      logger.severe('Failed to get sync status for budget $id', error, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> clearCache() async {
    try {
      logger.warning('Clearing all budgets from cache');
      await _database.delete(_database.budgets).go();
      logger.info('Budget cache cleared');
    } catch (error, stackTrace) {
      logger.severe('Failed to clear budget cache', error, stackTrace);
      throw DatabaseException('Failed to clear budget cache: $error');
    }
  }

  @override
  Future<int> count() async {
    try {
      logger.fine('Counting budgets');
      final int count = await _database.select(_database.budgets).get().then((List<BudgetEntity> list) => list.length);
      logger.fine('Budget count: $count');
      return count;
    } catch (error, stackTrace) {
      logger.severe('Failed to count budgets', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT COUNT(*) FROM budgets',
        error,
        stackTrace,
      );
    }
  }

  /// Get active budgets only.
  Future<List<BudgetEntity>> getActive() async {
    try {
      logger.fine('Fetching active budgets');
      final SimpleSelectStatement<$BudgetsTable, BudgetEntity> query = _database.select(_database.budgets)
        ..where(($BudgetsTable b) => b.active.equals(true))
        ..orderBy(<OrderClauseGenerator<$BudgetsTable>>[($BudgetsTable b) => OrderingTerm.asc(b.name)]);
      final List<BudgetEntity> budgets = await query.get();
      logger.info('Found ${budgets.length} active budgets');
      return budgets;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch active budgets', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM budgets WHERE active = true',
        error,
        stackTrace,
      );
    }
  }

  /// Get budgets with auto-budget enabled.
  Future<List<BudgetEntity>> getAutoBudgets() async {
    try {
      logger.fine('Fetching auto-budgets');
      final SimpleSelectStatement<$BudgetsTable, BudgetEntity> query = _database.select(_database.budgets)
        ..where(($BudgetsTable b) => b.autoBudgetType.isNotNull())
        ..orderBy(<OrderClauseGenerator<$BudgetsTable>>[($BudgetsTable b) => OrderingTerm.asc(b.name)]);
      final List<BudgetEntity> budgets = await query.get();
      logger.info('Found ${budgets.length} auto-budgets');
      return budgets;
    } catch (error, stackTrace) {
      logger.severe('Failed to fetch auto-budgets', error, stackTrace);
      throw DatabaseException.queryFailed(
        'SELECT * FROM budgets WHERE auto_budget_type IS NOT NULL',
        error,
        stackTrace,
      );
    }
  }

  /// Get spending for a budget in a date range.
  Future<double> getBudgetSpending({
    required String budgetId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      logger.fine('Calculating spending for budget: $budgetId from $startDate to $endDate');

      final List<TransactionEntity> transactions = await (_database.select(_database.transactions)
            ..where(($TransactionsTable t) =>
                t.budgetId.equals(budgetId) &
                t.type.equals('withdrawal') &
                t.date.isBiggerOrEqualValue(startDate) &
                t.date.isSmallerOrEqualValue(endDate)))
          .get();

      final double total = transactions.fold<double>(0.0, (double sum, TransactionEntity txn) => sum + txn.amount);

      logger.fine('Budget $budgetId spending: $total');
      return total;
    } catch (error, stackTrace) {
      logger.severe('Failed to calculate budget spending: $budgetId', error, stackTrace);
      throw DatabaseException('Failed to calculate budget spending: $error');
    }
  }
}
