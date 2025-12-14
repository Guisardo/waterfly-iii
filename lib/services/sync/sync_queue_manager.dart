import 'package:logging/logging.dart';
import 'package:drift/drift.dart';
import '../../data/local/database/app_database.dart';
import '../../models/sync_operation.dart';

/// Manager for sync queue operations.
class SyncQueueManager {
  final Logger _logger = Logger('SyncQueueManager');
  final AppDatabase database;

  SyncQueueManager(this.database);

  /// Get all pending operations from queue.
  Future<List<SyncOperation>> getPendingOperations() async {
    final query = database.select(database.syncQueue)
      ..where((q) => q.status.equals('pending'))
      ..orderBy([(q) => OrderingTerm(expression: q.priority, mode: OrderingMode.desc)]);

    final results = await query.get();
    
    return results.map((q) => SyncOperation(
      id: q.id,
      entityType: q.entityType,
      entityId: q.entityId,
      operation: SyncOperationType.values.firstWhere(
        (t) => t.name == q.operation,
        orElse: () => SyncOperationType.create,
      ),
      payload: {}, // Would parse from q.payload JSON
      status: SyncOperationStatus.values.firstWhere(
        (s) => s.name == q.status,
        orElse: () => SyncOperationStatus.pending,
      ),
      attempts: q.attempts,
      priority: SyncPriority.values[q.priority],
      createdAt: q.createdAt,
    )).toList();
  }

  /// Remove operation from queue.
  Future<void> removeOperation(String operationId) async {
    await (database.delete(database.syncQueue)
      ..where((q) => q.id.equals(operationId))).go();
    _logger.fine('Removed operation from queue: $operationId');
  }

  /// Mark operation as completed.
  Future<void> markCompleted(String operationId) async {
    await (database.update(database.syncQueue)
      ..where((q) => q.id.equals(operationId)))
      .write(const SyncQueueCompanion(status: Value('completed')));
    _logger.fine('Marked operation as completed: $operationId');
  }

  /// Mark operation as failed.
  Future<void> markFailed(String operationId, String error) async {
    await (database.update(database.syncQueue)
      ..where((q) => q.id.equals(operationId)))
      .write(SyncQueueCompanion(
        status: const Value('failed'),
        errorMessage: Value(error),
      ));
    _logger.fine('Marked operation as failed: $operationId');
  }
}
