import 'package:logging/logging.dart';
import '../../models/sync_operation.dart';
import 'sync_manager.dart';
import 'firefly_api_adapter.dart';
import 'database_adapter.dart';

/// Sync manager with real Firefly III API and database integration.
class SyncManagerWithApi extends SyncManager {
  final Logger _logger = Logger('SyncManagerWithApi');
  
  final FireflyApiAdapter apiAdapter;
  final DatabaseAdapter databaseAdapter;
  
  SyncManagerWithApi({
    required this.apiAdapter,
    required this.databaseAdapter,
    super.progressTracker,
    super.conflictDetector,
    super.conflictResolver,
    super.retryStrategy,
    super.circuitBreaker,
  });
  
  /// Sync transaction with real Firefly III API and database
  Future<void> syncTransactionWithApi(SyncOperation operation) async {
    _logger.fine('Syncing transaction ${operation.entityId} with real API and database');
    
    try {
      switch (operation.operation) {
        case SyncOperationType.create:
          final response = await apiAdapter.createTransaction(operation.payload);
          await databaseAdapter.upsertTransaction(response);
          _logger.info('Created transaction: ${response['id']}');
          break;
          
        case SyncOperationType.update:
          final serverId = operation.payload['server_id'] as String?;
          if (serverId == null) {
            throw Exception('Missing server_id for update');
          }
          final response = await apiAdapter.updateTransaction(
            serverId,
            operation.payload,
          );
          await databaseAdapter.upsertTransaction(response);
          _logger.info('Updated transaction: $serverId');
          break;
          
        case SyncOperationType.delete:
          final serverId = operation.payload['server_id'] as String?;
          if (serverId == null) {
            throw Exception('Missing server_id for delete');
          }
          await apiAdapter.deleteTransaction(serverId);
          await databaseAdapter.deleteTransaction(operation.entityId);
          _logger.info('Deleted transaction: $serverId');
          break;
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync transaction with API and database', e, stackTrace);
      rethrow;
    }
  }
}
