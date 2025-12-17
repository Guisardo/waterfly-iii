import 'package:logging/logging.dart';
import 'package:drift/drift.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/sync_operation.dart';

/// Manager for sync queue operations.
class SyncQueueManager {
  final Logger _logger = Logger('SyncQueueManager');
  final AppDatabase database;

  SyncQueueManager(this.database);

  /// Add operation to queue.
  Future<void> enqueue(SyncOperation operation) async {
    await database
        .into(database.syncQueue)
        .insert(
          SyncQueueEntityCompanion.insert(
            id: operation.id,
            entityType: operation.entityType,
            entityId: operation.entityId,
            operation: operation.operation.name,
            payload: '{}',
            createdAt: operation.createdAt,
            status: Value(operation.status.name),
            attempts: Value(operation.attempts),
            priority: Value(operation.priority.index),
          ),
        );
    _logger.fine('Enqueued operation: ${operation.id}');
  }

  /// Get all pending operations from queue.
  Future<List<SyncOperation>> getPendingOperations() async {
    final SimpleSelectStatement<$SyncQueueTable, SyncQueueEntity> query =
        database.select(database.syncQueue)
          ..where(($SyncQueueTable q) => q.status.equals('pending'))
          ..orderBy(<OrderClauseGenerator<$SyncQueueTable>>[
            ($SyncQueueTable q) =>
                OrderingTerm(expression: q.priority, mode: OrderingMode.desc),
          ]);

    final List<SyncQueueEntity> results = await query.get();

    return results
        .map(
          (SyncQueueEntity q) => SyncOperation(
            id: q.id,
            entityType: q.entityType,
            entityId: q.entityId,
            operation: SyncOperationType.values.firstWhere(
              (SyncOperationType t) => t.name == q.operation,
              orElse: () => SyncOperationType.create,
            ),
            payload: <String, dynamic>{}, // Would parse from q.payload JSON
            status: SyncOperationStatus.values.firstWhere(
              (SyncOperationStatus s) => s.name == q.status,
              orElse: () => SyncOperationStatus.pending,
            ),
            attempts: q.attempts,
            priority: SyncPriority.values[q.priority],
            createdAt: q.createdAt,
          ),
        )
        .toList();
  }

  /// Get count of pending operations in queue.
  ///
  /// Returns the number of operations with 'pending' status.
  /// This is more efficient than calling getPendingOperations().length
  /// as it only counts without loading all data.
  Future<int> getPendingCount() async {
    final JoinedSelectStatement<$SyncQueueTable, SyncQueueEntity> query =
        database.selectOnly(database.syncQueue)
          ..addColumns(<Expression<Object>>[database.syncQueue.id.count()])
          ..where(database.syncQueue.status.equals('pending'));

    final TypedResult result = await query.getSingle();
    final int count = result.read(database.syncQueue.id.count()) ?? 0;

    _logger.fine('Pending operations count: $count');
    return count;
  }

  /// Remove operation from queue.
  Future<void> removeOperation(String operationId) async {
    await (database.delete(database.syncQueue)
      ..where(($SyncQueueTable q) => q.id.equals(operationId))).go();
    _logger.fine('Removed operation from queue: $operationId');
  }

  /// Mark operation as completed.
  Future<void> markCompleted(String operationId) async {
    await (database.update(database.syncQueue)..where(
      ($SyncQueueTable q) => q.id.equals(operationId),
    )).write(const SyncQueueEntityCompanion(status: Value('completed')));
    _logger.fine('Marked operation as completed: $operationId');
  }

  /// Mark operation as failed.
  Future<void> markFailed(String operationId, String error) async {
    await (database.update(database.syncQueue)
      ..where(($SyncQueueTable q) => q.id.equals(operationId))).write(
      SyncQueueEntityCompanion(
        status: const Value('failed'),
        errorMessage: Value(error),
      ),
    );
    _logger.fine('Marked operation as failed: $operationId');
  }

  /// Remove operations by entity ID.
  Future<void> removeByEntityId(String entityType, String entityId) async {
    final int deleted =
        await (database.delete(database.syncQueue)..where(
          ($SyncQueueTable q) =>
              q.entityType.equals(entityType) & q.entityId.equals(entityId),
        )).go();
    _logger.fine('Removed $deleted operations for $entityType:$entityId');
  }
}
