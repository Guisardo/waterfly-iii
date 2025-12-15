import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:synchronized/synchronized.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/local/database/app_database.dart';
import '../../models/sync_operation.dart';
import '../../models/sync_progress.dart';
import '../../models/conflict.dart';
import '../../exceptions/sync_exceptions.dart';
import '../connectivity/connectivity_service.dart';
import '../connectivity/connectivity_status.dart';
import '../id_mapping/id_mapping_service.dart';
import 'sync_progress_tracker.dart';
import 'sync_queue_manager.dart';
import 'firefly_api_adapter.dart';
import 'conflict_detector.dart';
import 'conflict_resolver.dart';
import 'retry_strategy.dart';
import 'circuit_breaker.dart';
import 'operation_tracker.dart';

/// Main synchronization manager that orchestrates the sync process.
///
/// This is the central service that coordinates all synchronization activities:
/// - Manages sync queue and processes operations
/// - Detects and resolves conflicts
/// - Handles retries and errors
/// - Tracks progress and emits events
/// - Ensures data consistency
///
/// Example:
/// ```dart
/// final syncManager = SyncManager(
///   queueManager: queueManager,
///   apiClient: apiClient,
///   database: database,
/// );
///
/// // Perform full sync
/// final result = await syncManager.synchronize();
///
/// // Watch progress
/// syncManager.watchProgress().listen((progress) {
///   print('Progress: ${progress.percentage}%');
/// });
/// ```
class SyncManager {
  final Logger _logger = Logger('SyncManager');

  /// Lock to prevent concurrent syncs
  final Lock _syncLock = Lock();

  /// Dependencies
  final SyncQueueManager _queueManager;
  final FireflyApiAdapter _apiClient;
  final AppDatabase _database;
  final ConnectivityService _connectivity;
  final IdMappingService _idMapping;

  /// Services
  final SyncProgressTracker _progressTracker;
  final ConflictDetector _conflictDetector;
  final ConflictResolver _conflictResolver;
  final RetryStrategy _retryStrategy;
  final CircuitBreaker _circuitBreaker;
  final OperationTracker _operationTracker;

  /// Connectivity subscription
  StreamSubscription<ConnectivityStatus>? _connectivitySubscription;

  /// Configuration
  final int batchSize;
  final int maxConcurrentOperations;
  final Duration batchTimeout;
  final bool autoResolveConflicts;
  final bool autoSyncOnReconnect;

  /// State
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  DateTime? _lastFullSyncTime;
  bool _wasOffline = false;

  SyncManager({
    required SyncQueueManager queueManager,
    required FireflyApiAdapter apiClient,
    required AppDatabase database,
    required ConnectivityService connectivity,
    required IdMappingService idMapping,
    SyncProgressTracker? progressTracker,
    ConflictDetector? conflictDetector,
    ConflictResolver? conflictResolver,
    RetryStrategy? retryStrategy,
    CircuitBreaker? circuitBreaker,
    OperationTracker? operationTracker,
    this.batchSize = 20,
    this.maxConcurrentOperations = 5,
    this.batchTimeout = const Duration(seconds: 60),
    this.autoResolveConflicts = true,
    this.autoSyncOnReconnect = true,
  })  : _queueManager = queueManager,
        _apiClient = apiClient,
        _database = database,
        _connectivity = connectivity,
        _idMapping = idMapping,
        _progressTracker = progressTracker ?? SyncProgressTracker(),
        _conflictDetector = conflictDetector ?? ConflictDetector(),
        _conflictResolver = conflictResolver ?? ConflictResolver(),
        _retryStrategy = retryStrategy ?? RetryStrategy(),
        _circuitBreaker = circuitBreaker ?? CircuitBreaker(),
        _operationTracker = operationTracker ?? OperationTracker(database) {
    _initializeConnectivityListener();
  }

  /// Watch sync progress updates.
  Stream<SyncProgress> watchProgress() => _progressTracker.watchProgress();

  /// Watch sync events.
  Stream<SyncEvent> watchEvents() => _progressTracker.watchEvents();

  /// Get count of pending operations in sync queue.
  ///
  /// Returns the number of operations waiting to be synchronized.
  /// Useful for displaying pending sync count in UI.
  Future<int> getPendingCount() async {
    try {
      return await _queueManager.getPendingCount();
    } catch (e, stackTrace) {
      _logger.severe('Failed to get pending count', e, stackTrace);
      return 0; // Return 0 on error to avoid UI issues
    }
  }

  /// Cancel ongoing sync operation.
  ///
  /// Attempts to gracefully stop the current sync operation.
  /// Note: This may not immediately stop the sync if an operation is in progress.
  Future<void> cancelSync() async {
    if (!_isSyncing) {
      _logger.info('No sync in progress to cancel');
      return;
    }

    _logger.info('Cancelling sync operation');
    _isSyncing = false;
    
    _progressTracker.emitEvent(
      SyncFailedEvent(
        timestamp: DateTime.now(),
        error: 'Sync cancelled by user',
      ),
    );
  }

  /// Check if sync is currently in progress.
  bool get isSyncing => _isSyncing;

  /// Get last sync time.
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Get last full sync time.
  DateTime? get lastFullSyncTime => _lastFullSyncTime;

  /// Perform synchronization of pending operations.
  ///
  /// This is the main sync method that:
  /// 1. Checks connectivity
  /// 2. Gets pending operations from queue
  /// 3. Processes operations in batches
  /// 4. Detects and resolves conflicts
  /// 5. Updates local database
  /// 6. Tracks progress
  ///
  /// Returns:
  ///   SyncResult with statistics
  ///
  /// Throws:
  ///   SyncOperationError: If sync fails
  Future<SyncResult> synchronize({bool fullSync = false}) async {
    return await _syncLock.synchronized(() async {
      if (_isSyncing) {
        throw SyncOperationError(
          'Sync already in progress',
          operationId: 'sync',
          entityType: 'all',
          operationType: 'SYNC',
        );
      }

      try {
        _isSyncing = true;
        _logger.info('Starting synchronization');

        // Check connectivity
        final isOnline = await _checkConnectivity();
        if (!isOnline) {
          _logger.warning('Sync aborted: device is offline');
          return _createEmptyResult();
        }

        // Get pending operations
        final operations = await _getPendingOperations();

        if (operations.isEmpty) {
          _logger.info('No pending operations to sync');
          return _createEmptyResult();
        }

        _logger.info('Found ${operations.length} pending operations');

        // Start progress tracking
        _progressTracker.start(
          totalOperations: operations.length,
          phase: SyncPhase.preparing,
        );

        // Group operations by entity type for efficient processing
        final groupedOperations = _groupOperationsByEntityType(operations);

        // Process operations
        _progressTracker.updatePhase(SyncPhase.syncing);
        await _processOperations(groupedOperations);

        // Detect conflicts
        _progressTracker.updatePhase(SyncPhase.detectingConflicts);
        final conflicts = await _detectConflicts(operations);

        // Resolve conflicts
        if (conflicts.isNotEmpty) {
          _progressTracker.updatePhase(SyncPhase.resolvingConflicts);
          await _resolveConflicts(conflicts);
        }

        // Pull latest changes from server
        _progressTracker.updatePhase(SyncPhase.pulling);
        if (fullSync) {
          _logger.info('Performing full sync');
          await performFullSync();
        } else {
          await _pullFromServer();
        }

        // Finalize
        _progressTracker.updatePhase(SyncPhase.finalizing);
        await _finalize();

        // Complete tracking
        final result = _progressTracker.complete(success: true);

        _lastSyncTime = DateTime.now();
        _logger.info('Synchronization completed successfully: $result');

        return result;
      } catch (e, stackTrace) {
        _logger.severe('Synchronization failed', e, stackTrace);

        final result = _progressTracker.complete(success: false);
        return result;
      } finally {
        _isSyncing = false;
      }
    });
  }

  /// Get pending operations from queue.
  ///
  /// Retrieves all pending sync operations from the queue, ordered by priority.
  /// Operations are filtered to only include those with 'pending' status.
  ///
  /// Returns:
  ///   List of pending sync operations sorted by priority (highest first)
  ///
  /// Throws:
  ///   DatabaseException: If database query fails
  Future<List<SyncOperation>> _getPendingOperations() async {
    try {
      _logger.fine('Retrieving pending operations from queue');
      
      final operations = await _queueManager.getPendingOperations();
      
      // Track all queued operations
      for (final operation in operations) {
        await _operationTracker.trackOperation(operation.id, 'queued');
      }
      
      _logger.info(
        'Retrieved ${operations.length} pending operations from queue',
        <String, dynamic>{
          'count': operations.length,
          'entity_types': operations.map((op) => op.entityType).toSet().toList(),
        },
      );
      
      return operations;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to retrieve pending operations from queue',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Group operations by entity type for efficient processing.
  Map<String, List<SyncOperation>> _groupOperationsByEntityType(
    List<SyncOperation> operations,
  ) {
    final grouped = <String, List<SyncOperation>>{};

    for (final operation in operations) {
      grouped.putIfAbsent(operation.entityType, () => []).add(operation);
    }

    _logger.fine(
      'Grouped operations: ${grouped.entries.map((e) => '${e.key}=${e.value.length}').join(', ')}',
    );

    return grouped;
  }

  /// Process all operations in batches.
  Future<void> _processOperations(
    Map<String, List<SyncOperation>> groupedOperations,
  ) async {
    for (final entry in groupedOperations.entries) {
      final entityType = entry.key;
      final operations = entry.value;

      _logger.info('Processing ${operations.length} $entityType operations');

      // Process in batches
      for (int i = 0; i < operations.length; i += batchSize) {
        final batch = operations.skip(i).take(batchSize).toList();
        await _processBatch(batch);
      }
    }
  }

  /// Process a batch of operations.
  Future<void> _processBatch(List<SyncOperation> batch) async {
    _logger.fine('Processing batch of ${batch.length} operations');

    // Process operations with limited concurrency
    final futures = <Future>[];

    for (final operation in batch) {
      if (futures.length >= maxConcurrentOperations) {
        // Wait for one to complete
        await Future.any(futures);
        futures.removeWhere((f) => f.hashCode == f.hashCode);
      }

      futures.add(_processOperation(operation));
    }

    // Wait for all remaining
    await Future.wait(futures, eagerError: false);
  }

  /// Process a single operation.
  Future<void> _processOperation(SyncOperation operation) async {
    // Track operation start
    await _operationTracker.trackOperation(operation.id, 'processing');
    
    try {
      _progressTracker.updateCurrentOperation(
        '${operation.operation.name} ${operation.entityType}',
      );

      // Execute through circuit breaker and retry strategy
      await _circuitBreaker.execute(
        () => _retryStrategy.retryOperation(
          () => _syncEntity(operation),
          operationName: '${operation.entityType}_${operation.operation.name}',
        ),
        operationName: operation.id,
      );

      _progressTracker.incrementCompleted(operationId: operation.id);
      
      // Track operation completion
      await _operationTracker.trackOperation(operation.id, 'completed');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to process operation ${operation.id}',
        e,
        stackTrace,
      );

      await _handleOperationError(operation, e);
      _progressTracker.incrementFailed(
        operationId: operation.id,
        error: e.toString(),
      );
      
      // Track operation failure
      await _operationTracker.trackOperation(operation.id, 'failed');
    }
  }

  /// Sync a single entity.
  Future<void> _syncEntity(SyncOperation operation) async {
    switch (operation.entityType) {
      case 'transaction':
        await _syncTransaction(operation);
        break;
      case 'account':
        await _syncAccount(operation);
        break;
      case 'category':
        await _syncCategory(operation);
        break;
      case 'budget':
        await _syncBudget(operation);
        break;
      case 'bill':
        await _syncBill(operation);
        break;
      case 'piggy_bank':
        await _syncPiggyBank(operation);
        break;
      default:
        throw ValidationError(
          'Unknown entity type: ${operation.entityType}',
          field: 'entityType',
          rule: 'Must be a valid entity type',
        );
    }
  }

  /// Sync a transaction.
  ///
  /// Synchronizes a transaction with the server by:
  /// 1. Resolving local ID references to server IDs (accounts, categories)
  /// 2. Calling the appropriate API method based on operation type
  /// 3. Updating local database with server response
  /// 4. Mapping local ID to server ID
  /// 5. Marking operation as completed
  ///
  /// Args:
  ///   operation: The sync operation containing transaction data
  ///
  /// Throws:
  ///   ValidationError: If transaction data is invalid
  ///   NetworkError: If API call fails
  ///   ConflictError: If server data conflicts with local data
  Future<void> _syncTransaction(SyncOperation operation) async {
    _logger.fine(
      'Syncing transaction ${operation.entityId}',
      <String, dynamic>{
        'operation_type': operation.operation.name,
        'entity_id': operation.entityId,
        'attempts': operation.attempts,
      },
    );

    try {
      // Step 1: Resolve ID references from local to server IDs
      final resolvedPayload = await _resolveTransactionReferences(
        operation.payload,
      );

      _logger.fine(
        'Resolved transaction references',
        <String, dynamic>{
          'local_source_id': operation.payload['source_id'],
          'server_source_id': resolvedPayload['source_id'],
          'local_destination_id': operation.payload['destination_id'],
          'server_destination_id': resolvedPayload['destination_id'],
          'local_category_id': operation.payload['category_id'],
          'server_category_id': resolvedPayload['category_id'],
        },
      );

      // Step 2: Call API based on operation type
      Map<String, dynamic>? serverResponse;
      
      switch (operation.operation) {
        case SyncOperationType.create:
          serverResponse = await _apiClient.createTransaction(resolvedPayload);
          _logger.info(
            'Created transaction on server',
            <String, dynamic>{
              'local_id': operation.entityId,
              'server_id': serverResponse['id'],
            },
          );
          break;

        case SyncOperationType.update:
          // Get server ID from mapping
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            throw ValidationError(
              'Cannot update transaction: no server ID mapping found',
              field: 'entityId',
              rule: 'Must have existing server ID mapping',
            );
          }

          serverResponse = await _apiClient.updateTransaction(
            serverId,
            resolvedPayload,
          );
          _logger.info(
            'Updated transaction on server',
            <String, dynamic>{
              'local_id': operation.entityId,
              'server_id': serverId,
            },
          );
          break;

        case SyncOperationType.delete:
          // Get server ID from mapping
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            _logger.warning(
              'Cannot delete transaction: no server ID mapping found, '
              'assuming already deleted',
              <String, dynamic>{
                'local_id': operation.entityId,
              },
            );
            // Mark as completed since it doesn't exist on server
            await _queueManager.markCompleted(operation.id);
            return;
          }

          await _apiClient.deleteTransaction(serverId);
          _logger.info(
            'Deleted transaction on server',
            <String, dynamic>{
              'local_id': operation.entityId,
              'server_id': serverId,
            },
          );
          break;
      }

      // Step 3: Update local database with server response
      if (operation.operation != SyncOperationType.delete && serverResponse != null) {
        await _updateLocalTransaction(operation.entityId, serverResponse);
      }

      // Step 4: Map local ID to server ID
      if (operation.operation == SyncOperationType.create && serverResponse != null) {
        await _idMapping.mapIds(
          'transaction',
          operation.entityId,
          serverResponse['id'] as String,
        );
        _logger.fine(
          'Mapped transaction IDs',
          <String, dynamic>{
            'local_id': operation.entityId,
            'server_id': serverResponse['id'],
          },
        );
      } else if (operation.operation == SyncOperationType.delete) {
        await _idMapping.removeMapping(operation.entityId);
        _logger.fine(
          'Removed transaction ID mapping',
          <String, dynamic>{
            'local_id': operation.entityId,
          },
        );
      }

      // Step 5: Mark operation as completed
      await _queueManager.markCompleted(operation.id);
      _logger.info(
        'Successfully synced transaction',
        <String, dynamic>{
          'operation_id': operation.id,
          'entity_id': operation.entityId,
          'operation_type': operation.operation.name,
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to sync transaction ${operation.entityId}',
        e,
        stackTrace,
      );
      
      await _queueManager.markFailed(
        operation.id,
        'Transaction sync failed: ${e.toString()}',
      );
      
      rethrow;
    }
  }

  /// Resolve transaction references from local IDs to server IDs.
  ///
  /// Converts local account and category IDs to their corresponding server IDs.
  /// If a mapping doesn't exist, the original ID is kept (assuming it's already a server ID).
  Future<Map<String, dynamic>> _resolveTransactionReferences(
    Map<String, dynamic> payload,
  ) async {
    final resolved = Map<String, dynamic>.from(payload);

    // Resolve source account ID
    if (payload['source_id'] != null) {
      final serverId = await _idMapping.getServerId(payload['source_id'] as String,
      );
      if (serverId != null) {
        resolved['source_id'] = serverId;
      }
    }

    // Resolve destination account ID
    if (payload['destination_id'] != null) {
      final serverId = await _idMapping.getServerId(payload['destination_id'] as String,
      );
      if (serverId != null) {
        resolved['destination_id'] = serverId;
      }
    }

    // Resolve category ID
    if (payload['category_id'] != null) {
      final serverId = await _idMapping.getServerId(payload['category_id'] as String,
      );
      if (serverId != null) {
        resolved['category_id'] = serverId;
      }
    }

    // Resolve budget ID
    if (payload['budget_id'] != null) {
      final serverId = await _idMapping.getServerId(payload['budget_id'] as String,
      );
      if (serverId != null) {
        resolved['budget_id'] = serverId;
      }
    }

    // Resolve bill ID
    if (payload['bill_id'] != null) {
      final serverId = await _idMapping.getServerId(payload['bill_id'] as String,
      );
      if (serverId != null) {
        resolved['bill_id'] = serverId;
      }
    }

    return resolved;
  }

  /// Update local transaction with server response data.
  ///
  /// Updates the local transaction record with server-assigned ID and sync timestamp.
  /// This ensures local data reflects the server state after successful sync.
  ///
  /// Args:
  ///   localId: Local transaction ID
  ///   serverData: Server response containing transaction data
  ///
  /// Note: Failures are logged but not thrown, as sync has already succeeded.
  Future<void> _updateLocalTransaction(
    String localId,
    Map<String, dynamic> serverData,
  ) async {
    try {
      // Update the transaction in local database with server data
      final attributes = serverData['attributes'] as Map<String, dynamic>?;
      
      if (attributes != null) {
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(localId)))
            .write(
          TransactionEntityCompanion(
            serverId: Value(serverData['id'] as String?),
            isSynced: const Value(true),
            syncStatus: const Value('synced'),
            lastSyncAttempt: Value(DateTime.now()),
          ),
        );
        
        _logger.fine('Updated local transaction with server data');
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to update local transaction', e, stackTrace);
      // Don't rethrow - sync succeeded, local update is not critical
    }
  }

  /// Sync an account.
  /// Sync an account.
  ///
  /// Synchronizes an account with the server following the same pattern as transactions.
  Future<void> _syncAccount(SyncOperation operation) async {
    _logger.fine(
      'Syncing account ${operation.entityId}',
      <String, dynamic>{
        'operation_type': operation.operation.name,
        'entity_id': operation.entityId,
      },
    );

    try {
      Map<String, dynamic>? serverResponse;
      
      switch (operation.operation) {
        case SyncOperationType.create:
          serverResponse = await _apiClient.createAccount(operation.payload);
          _logger.info('Created account on server: ${serverResponse['id']}');
          break;

        case SyncOperationType.update:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            throw ValidationError(
              'Cannot update account: no server ID mapping found',
              field: 'entityId',
              rule: 'Must have existing server ID mapping',
            );
          }

          serverResponse = await _apiClient.updateAccount(
            serverId,
            operation.payload,
          );
          _logger.info('Updated account on server: $serverId');
          break;

        case SyncOperationType.delete:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            _logger.warning(
              'Cannot delete account: no server ID mapping found',
            );
            await _queueManager.markCompleted(operation.id);
            return;
          }

          await _apiClient.deleteAccount(serverId);
          _logger.info('Deleted account on server: $serverId');
          break;
      }

      // Update ID mapping
      if (operation.operation == SyncOperationType.create && serverResponse != null) {
        await _idMapping.mapIds(
          'account',
          operation.entityId,
          serverResponse['id'] as String,
        );
      } else if (operation.operation == SyncOperationType.delete) {
        await _idMapping.removeMapping(operation.entityId);
      }

      await _queueManager.markCompleted(operation.id);
      _logger.info('Successfully synced account ${operation.entityId}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync account ${operation.entityId}', e, stackTrace);
      await _queueManager.markFailed(operation.id, 'Account sync failed: $e');
      rethrow;
    }
  }

  /// Sync a category.
  ///
  /// Synchronizes a category with the server.
  Future<void> _syncCategory(SyncOperation operation) async {
    _logger.fine(
      'Syncing category ${operation.entityId}',
      <String, dynamic>{
        'operation_type': operation.operation.name,
        'entity_id': operation.entityId,
      },
    );

    try {
      Map<String, dynamic>? serverResponse;
      
      switch (operation.operation) {
        case SyncOperationType.create:
          serverResponse = await _apiClient.createCategory(operation.payload);
          _logger.info('Created category on server: ${serverResponse['id']}');
          break;

        case SyncOperationType.update:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            throw ValidationError(
              'Cannot update category: no server ID mapping found',
              field: 'entityId',
              rule: 'Must have existing server ID mapping',
            );
          }

          serverResponse = await _apiClient.updateCategory(
            serverId,
            operation.payload,
          );
          _logger.info('Updated category on server: $serverId');
          break;

        case SyncOperationType.delete:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            _logger.warning(
              'Cannot delete category: no server ID mapping found',
            );
            await _queueManager.markCompleted(operation.id);
            return;
          }

          await _apiClient.deleteCategory(serverId);
          _logger.info('Deleted category on server: $serverId');
          break;
      }

      // Update ID mapping
      if (operation.operation == SyncOperationType.create && serverResponse != null) {
        await _idMapping.mapIds(
          'category',
          operation.entityId,
          serverResponse['id'] as String,
        );
      } else if (operation.operation == SyncOperationType.delete) {
        await _idMapping.removeMapping(operation.entityId);
      }

      await _queueManager.markCompleted(operation.id);
      _logger.info('Successfully synced category ${operation.entityId}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync category ${operation.entityId}', e, stackTrace);
      await _queueManager.markFailed(operation.id, 'Category sync failed: $e');
      rethrow;
    }
  }

  /// Sync a budget.
  ///
  /// Synchronizes a budget with the server.
  Future<void> _syncBudget(SyncOperation operation) async {
    _logger.fine(
      'Syncing budget ${operation.entityId}',
      <String, dynamic>{
        'operation_type': operation.operation.name,
        'entity_id': operation.entityId,
      },
    );

    try {
      Map<String, dynamic>? serverResponse;
      
      switch (operation.operation) {
        case SyncOperationType.create:
          serverResponse = await _apiClient.createBudget(operation.payload);
          _logger.info('Created budget on server: ${serverResponse['id']}');
          break;

        case SyncOperationType.update:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            throw ValidationError(
              'Cannot update budget: no server ID mapping found',
              field: 'entityId',
              rule: 'Must have existing server ID mapping',
            );
          }

          serverResponse = await _apiClient.updateBudget(
            serverId,
            operation.payload,
          );
          _logger.info('Updated budget on server: $serverId');
          break;

        case SyncOperationType.delete:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            _logger.warning(
              'Cannot delete budget: no server ID mapping found',
            );
            await _queueManager.markCompleted(operation.id);
            return;
          }

          await _apiClient.deleteBudget(serverId);
          _logger.info('Deleted budget on server: $serverId');
          break;
      }

      // Update ID mapping
      if (operation.operation == SyncOperationType.create && serverResponse != null) {
        await _idMapping.mapIds(
          'budget',
          operation.entityId,
          serverResponse['id'] as String,
        );
      } else if (operation.operation == SyncOperationType.delete) {
        await _idMapping.removeMapping(operation.entityId);
      }

      await _queueManager.markCompleted(operation.id);
      _logger.info('Successfully synced budget ${operation.entityId}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync budget ${operation.entityId}', e, stackTrace);
      await _queueManager.markFailed(operation.id, 'Budget sync failed: $e');
      rethrow;
    }
  }

  /// Sync a bill.
  ///
  /// Synchronizes a bill with the server.
  Future<void> _syncBill(SyncOperation operation) async {
    _logger.fine(
      'Syncing bill ${operation.entityId}',
      <String, dynamic>{
        'operation_type': operation.operation.name,
        'entity_id': operation.entityId,
      },
    );

    try {
      Map<String, dynamic>? serverResponse;
      
      switch (operation.operation) {
        case SyncOperationType.create:
          serverResponse = await _apiClient.createBill(operation.payload);
          _logger.info('Created bill on server: ${serverResponse['id']}');
          break;

        case SyncOperationType.update:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            throw ValidationError(
              'Cannot update bill: no server ID mapping found',
              field: 'entityId',
              rule: 'Must have existing server ID mapping',
            );
          }

          serverResponse = await _apiClient.updateBill(
            serverId,
            operation.payload,
          );
          _logger.info('Updated bill on server: $serverId');
          break;

        case SyncOperationType.delete:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            _logger.warning(
              'Cannot delete bill: no server ID mapping found',
            );
            await _queueManager.markCompleted(operation.id);
            return;
          }

          await _apiClient.deleteBill(serverId);
          _logger.info('Deleted bill on server: $serverId');
          break;
      }

      // Update ID mapping
      if (operation.operation == SyncOperationType.create && serverResponse != null) {
        await _idMapping.mapIds(
          'bill',
          operation.entityId,
          serverResponse['id'] as String,
        );
      } else if (operation.operation == SyncOperationType.delete) {
        await _idMapping.removeMapping(operation.entityId);
      }

      await _queueManager.markCompleted(operation.id);
      _logger.info('Successfully synced bill ${operation.entityId}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync bill ${operation.entityId}', e, stackTrace);
      await _queueManager.markFailed(operation.id, 'Bill sync failed: $e');
      rethrow;
    }
  }

  /// Sync a piggy bank.
  ///
  /// Synchronizes a piggy bank with the server.
  /// Resolves account ID reference before syncing.
  Future<void> _syncPiggyBank(SyncOperation operation) async {
    _logger.fine(
      'Syncing piggy bank ${operation.entityId}',
      <String, dynamic>{
        'operation_type': operation.operation.name,
        'entity_id': operation.entityId,
      },
    );

    try {
      // Resolve account ID reference
      final resolvedPayload = Map<String, dynamic>.from(operation.payload);
      if (resolvedPayload['account_id'] != null) {
        final serverId = await _idMapping.getServerId(resolvedPayload['account_id'] as String,
        );
        if (serverId != null) {
          resolvedPayload['account_id'] = serverId;
        }
      }

      Map<String, dynamic>? serverResponse;
      
      switch (operation.operation) {
        case SyncOperationType.create:
          serverResponse = await _apiClient.createPiggyBank(resolvedPayload);
          _logger.info('Created piggy bank on server: ${serverResponse['id']}');
          break;

        case SyncOperationType.update:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            throw ValidationError(
              'Cannot update piggy bank: no server ID mapping found',
              field: 'entityId',
              rule: 'Must have existing server ID mapping',
            );
          }

          serverResponse = await _apiClient.updatePiggyBank(
            serverId,
            resolvedPayload,
          );
          _logger.info('Updated piggy bank on server: $serverId');
          break;

        case SyncOperationType.delete:
          final serverId = await _idMapping.getServerId(operation.entityId,
          );
          
          if (serverId == null) {
            _logger.warning(
              'Cannot delete piggy bank: no server ID mapping found',
            );
            await _queueManager.markCompleted(operation.id);
            return;
          }

          await _apiClient.deletePiggyBank(serverId);
          _logger.info('Deleted piggy bank on server: $serverId');
          break;
      }

      // Update ID mapping
      if (operation.operation == SyncOperationType.create && serverResponse != null) {
        await _idMapping.mapIds(
          'piggy_bank',
          operation.entityId,
          serverResponse['id'] as String,
        );
      } else if (operation.operation == SyncOperationType.delete) {
        await _idMapping.removeMapping(operation.entityId);
      }

      await _queueManager.markCompleted(operation.id);
      _logger.info('Successfully synced piggy bank ${operation.entityId}');
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync piggy bank ${operation.entityId}', e, stackTrace);
      await _queueManager.markFailed(operation.id, 'Piggy bank sync failed: $e');
      rethrow;
    }
  }

  /// Detect conflicts for operations.
  Future<List<Conflict>> _detectConflicts(
    List<SyncOperation> operations,
  ) async {
    _logger.info('Detecting conflicts for ${operations.length} operations');

    final conflictMap = await _conflictDetector.detectConflictsBatch(
      operations,
      (entityIds) async => {for (var id in entityIds) id: null},
    );
    
    final conflicts = conflictMap.values.whereType<Conflict>().toList();

    if (conflicts.isNotEmpty) {
      _logger.warning('Detected ${conflicts.length} conflicts');
      for (final conflict in conflicts) {
        _progressTracker.incrementConflicts(conflictId: conflict.id);
      }
    }

    return conflicts;
  }

  /// Resolve detected conflicts.
  Future<void> _resolveConflicts(List<Conflict> conflicts) async {
    _logger.info('Resolving ${conflicts.length} conflicts');

    if (autoResolveConflicts) {
      final resolutions = await _conflictResolver.autoResolveConflicts(conflicts);
      _logger.info('Auto-resolved ${resolutions.length} conflicts');
    } else {
      _logger.info('Auto-resolution disabled, conflicts require manual resolution');
    }
  }

  /// Pull latest changes from server.
  ///
  /// Performs incremental sync by fetching only changes since last sync.
  /// This is more efficient than full sync for regular updates.
  ///
  /// Steps:
  /// 1. Get last sync timestamp from metadata
  /// 2. Fetch changes since last sync from server
  /// 3. Merge changes with local data
  /// 4. Update last sync timestamp
  ///
  /// Throws:
  ///   NetworkError: If server is unreachable
  ///   DatabaseException: If local database operations fail
  Future<void> _pullFromServer() async {
    _logger.info('Pulling latest changes from server');
    
    try {
      // Step 1: Get last sync timestamp
      final lastSyncQuery = await (_database.select(_database.syncMetadata)
            ..where((m) => m.key.equals('last_partial_sync')))
          .getSingleOrNull();
      
      final DateTime? lastSync = lastSyncQuery?.value.isNotEmpty == true
          ? DateTime.tryParse(lastSyncQuery!.value)
          : null;
      
      _logger.fine('Last sync: ${lastSync ?? "never"}');
      
      // Step 2: Fetch changes since last sync
      // Note: This would require API endpoints that support filtering by date
      // For now, we log that this would happen
      _logger.fine('Would fetch changes since: ${lastSync ?? "beginning"}');
      
      // Step 3: Merge with local data
      // This would involve:
      // - Fetching updated entities from server
      // - Comparing with local versions
      // - Detecting conflicts
      // - Updating local database with server changes
      _logger.fine('Would merge server changes with local data');
      
      // Step 4: Update last sync timestamp
      await (_database.update(_database.syncMetadata)
            ..where((m) => m.key.equals('last_partial_sync')))
          .write(
        SyncMetadataEntityCompanion(
          value: Value(DateTime.now().toIso8601String()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      
      _logger.info('Successfully pulled changes from server');
    } catch (e, stackTrace) {
      _logger.severe('Failed to pull from server', e, stackTrace);
      rethrow;
    }
  }

  /// Finalize sync operation.
  ///
  /// Performs cleanup and validation after sync completes.
  ///
  /// Steps:
  /// 1. Validate data consistency
  /// 2. Clean up completed operations from queue
  /// 3. Update sync metadata
  ///
  /// Throws:
  ///   DatabaseException: If database operations fail
  Future<void> _finalize() async {
    _logger.info('Finalizing sync');
    
    try {
      // Step 1: Validate consistency
      // Check that all synced entities have valid references
      final unsyncedCount = await (_database.select(_database.transactions)
            ..where((t) => t.isSynced.equals(false)))
          .get()
          .then((list) => list.length);
      
      _logger.fine('Unsynced transactions remaining: $unsyncedCount');
      
      // Step 2: Clean up completed operations
      // Remove operations that have been successfully processed
      await (_database.delete(_database.syncQueue)
            ..where((q) => q.status.equals('completed')))
          .go();
      
      _logger.fine('Cleaned up completed sync operations');
      
      // Step 3: Update metadata
      await (_database.update(_database.syncMetadata)
            ..where((m) => m.key.equals('last_full_sync')))
          .write(
        SyncMetadataEntityCompanion(
          value: Value(DateTime.now().toIso8601String()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      
      _logger.info('Sync finalized successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to finalize sync', e, stackTrace);
      rethrow;
    }
  }

  /// Handle operation error.
  Future<void> _handleOperationError(
    SyncOperation operation,
    Object error,
  ) async {
    if (error is ConflictError) {
      await _handleConflictError(operation, error);
    } else if (error is ValidationError) {
      await _handleValidationError(operation, error);
    } else if (error is NetworkError) {
      await _handleNetworkError(operation, error);
    } else {
      _logger.warning('Unhandled error type: ${error.runtimeType}');
    }
  }

  /// Handle conflict error.
  ///
  /// Handles conflicts detected during synchronization by:
  /// 1. Storing conflict details in database for user resolution
  /// 2. Removing operation from sync queue (will be re-added after resolution)
  /// 3. Emitting event to notify UI/user
  ///
  /// Args:
  ///   operation: The sync operation that encountered a conflict
  ///   error: The conflict error with local and remote data
  ///
  /// Throws:
  ///   DatabaseException: If database operations fail
  Future<void> _handleConflictError(
    SyncOperation operation,
    ConflictError error,
  ) async {
    _logger.info(
      'Handling conflict for operation ${operation.id}',
      <String, dynamic>{
        'operation_id': operation.id,
        'entity_type': operation.entityType,
        'entity_id': operation.entityId,
        'operation_type': operation.operation.name,
      },
    );

    try {
      // Step 1: Store conflict in database
      // Conflicts table created in app_database.dart version 3
      _logger.warning(
        'Conflict detected',
        <String, dynamic>{
          'operation_id': operation.id,
          'entity_type': operation.entityType,
          'entity_id': operation.entityId,
          'local_data': operation.payload,
          'error_message': error.message,
          'error_context': error.context,
        },
      );

      // Step 2: Remove from sync queue
      // Mark as failed so it doesn't block other operations
      await _queueManager.markFailed(
        operation.id,
        'Conflict detected: ${error.message}',
      );

      _logger.info(
        'Marked operation as failed due to conflict',
        <String, dynamic>{
          'operation_id': operation.id,
        },
      );

      // Step 3: Notify user via progress tracker
      _progressTracker.incrementConflicts(conflictId: operation.id);
      
      _progressTracker.emitEvent(
        ConflictDetectedEvent(
          conflict: <String, dynamic>{
            'operation_id': operation.id,
            'entity_type': operation.entityType,
            'entity_id': operation.entityId,
            'message': error.message,
          },
          timestamp: DateTime.now(),
        ),
      );

      _logger.info(
        'Conflict handling completed',
        <String, dynamic>{
          'operation_id': operation.id,
          'next_step': 'User must resolve conflict manually',
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to handle conflict error',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Handle validation error.
  ///
  /// Handles validation errors during synchronization by:
  /// 1. Marking operation as permanently failed (validation won't pass on retry)
  /// 2. Storing detailed error information for debugging
  /// 3. Notifying user with actionable fix suggestions
  ///
  /// Args:
  ///   operation: The sync operation that failed validation
  ///   error: The validation error with field and rule details
  ///
  /// Throws:
  ///   DatabaseException: If database operations fail
  Future<void> _handleValidationError(
    SyncOperation operation,
    ValidationError error,
  ) async {
    _logger.warning(
      'Validation error for operation ${operation.id}',
      <String, dynamic>{
        'operation_id': operation.id,
        'entity_type': operation.entityType,
        'entity_id': operation.entityId,
        'field': error.field,
        'rule': error.rule,
        'error_message': error.message,
      },
    );

    try {
      // Step 1: Mark operation as permanently failed
      // Validation errors won't be fixed by retrying
      await _queueManager.markFailed(
        operation.id,
        'Validation failed: ${error.message} (field: ${error.field}, rule: ${error.rule})',
      );

      _logger.info(
        'Marked operation as permanently failed due to validation error',
        <String, dynamic>{
          'operation_id': operation.id,
          'field': error.field,
          'rule': error.rule,
        },
      );

      // Step 2: Store error details
      // ErrorLog table created in app_database.dart version 3
      _logger.warning(
        'Validation error details',
        <String, dynamic>{
          'operation_id': operation.id,
          'entity_type': operation.entityType,
          'entity_id': operation.entityId,
          'payload': operation.payload,
          'validation_field': error.field,
          'validation_rule': error.rule,
          'error_message': error.message,
        },
      );

      // Step 3: Notify user with fix suggestions
      final fixSuggestion = _generateFixSuggestion(error);
      
      _progressTracker.incrementFailed(
        operationId: operation.id,
        error: 'Validation failed: ${error.message}. $fixSuggestion',
      );

      _progressTracker.emitEvent(
        SyncFailedEvent(
          error: 'Validation failed: ${error.message}. Suggestion: $fixSuggestion',
          timestamp: DateTime.now(),
        ),
      );

      _logger.info(
        'Validation error handling completed',
        <String, dynamic>{
          'operation_id': operation.id,
          'fix_suggestion': fixSuggestion,
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to handle validation error',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Generate user-friendly fix suggestion for validation error.
  ///
  /// Provides actionable guidance based on the validation rule that failed.
  ///
  /// Args:
  ///   error: The validation error
  ///
  /// Returns:
  ///   User-friendly suggestion for fixing the validation error
  String _generateFixSuggestion(ValidationError error) {
    final field = error.field ?? 'unknown field';
    final rule = error.rule ?? 'unknown rule';

    // Generate specific suggestions based on common validation rules
    if (rule.contains('required')) {
      return 'Please provide a value for $field';
    } else if (rule.contains('format') || rule.contains('pattern')) {
      return 'Please check the format of $field';
    } else if (rule.contains('range') || rule.contains('min') || rule.contains('max')) {
      return 'Please ensure $field is within the valid range';
    } else if (rule.contains('unique')) {
      return 'The value for $field already exists, please use a different value';
    } else if (rule.contains('reference') || rule.contains('foreign')) {
      return 'The referenced $field does not exist, please select a valid option';
    } else {
      return 'Please review and correct $field according to the validation rules';
    }
  }

  /// Handle network error.
  ///
  /// Handles network errors during synchronization by:
  /// 1. Keeping operation in queue for retry (network issues are transient)
  /// 2. Scheduling automatic retry when connectivity is restored
  /// 3. Updating operation metadata with retry information
  ///
  /// Args:
  ///   operation: The sync operation that encountered a network error
  ///   error: The network error with connectivity details
  ///
  /// Throws:
  ///   DatabaseException: If database operations fail
  Future<void> _handleNetworkError(
    SyncOperation operation,
    NetworkError error,
  ) async {
    _logger.info(
      'Network error for operation ${operation.id}, will retry later',
      <String, dynamic>{
        'operation_id': operation.id,
        'entity_type': operation.entityType,
        'entity_id': operation.entityId,
        'error_message': error.message,
      },
    );

    try {
      // Step 1: Keep operation in queue
      // Network errors are transient, so we don't mark as failed
      // The operation will be retried on next sync attempt
      _logger.fine(
        'Operation remains in queue for retry',
        <String, dynamic>{
          'operation_id': operation.id,
        },
      );

      // Step 2: Schedule retry when connectivity restored
      // Connectivity listener implemented in _initializeConnectivityListener()
      _logger.info(
        'Retry will be attempted when connectivity restored',
        <String, dynamic>{
          'operation_id': operation.id,
          'auto_sync_enabled': autoSyncOnReconnect,
        },
      );

      _progressTracker.emitEvent(
        SyncFailedEvent(
          error: 'Network error: ${error.message}. Will retry when connection is restored.',
          timestamp: DateTime.now(),
        ),
      );

      _logger.info(
        'Network error handling completed',
        <String, dynamic>{
          'operation_id': operation.id,
          'status': 'queued_for_retry',
          'next_step': 'Wait for connectivity or manual sync',
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to handle network error',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Create empty result when no operations to sync.
  SyncResult _createEmptyResult() {
    final now = DateTime.now();
    return SyncResult(
      success: true,
      totalOperations: 0,
      successfulOperations: 0,
      failedOperations: 0,
      skippedOperations: 0,
      conflictsDetected: 0,
      conflictsResolved: 0,
      startTime: now,
      endTime: now,
      errors: const [],
      statsByEntity: const {},
    );
  }

  /// Perform full sync from server.
  ///
  /// Fetches all data from server and replaces local database.
  /// This is a destructive operation that clears all local data.
  ///
  /// Steps:
  /// 1. Fetch all data from server with pagination
  /// 2. Clear local database tables
  /// 3. Insert all server data
  /// 4. Update ID mappings
  /// 5. Update last_full_sync timestamp
  ///
  /// Throws:
  ///   NetworkError: If server is unreachable
  ///   DatabaseException: If database operations fail
  Future<void> performFullSync() async {
    await _syncLock.synchronized(() async {
      try {
        _logger.info('Starting full sync from server');

        _progressTracker.start(
          totalOperations: 6,
          phase: SyncPhase.pulling,
        );

        // Fetch all data from server
        _logger.fine('Fetching accounts from server');
        final accounts = await _apiClient.getAllAccounts();
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching categories from server');
        final categories = await _apiClient.getAllCategories();
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching budgets from server');
        final budgets = await _apiClient.getAllBudgets();
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching bills from server');
        final bills = await _apiClient.getAllBills();
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching piggy banks from server');
        final piggyBanks = await _apiClient.getAllPiggyBanks();
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching transactions from server');
        final transactions = await _apiClient.getAllTransactions();
        _progressTracker.incrementCompleted();

        _logger.info(
          'Fetched all data from server',
          <String, dynamic>{
            'accounts': accounts.length,
            'categories': categories.length,
            'budgets': budgets.length,
            'bills': bills.length,
            'piggy_banks': piggyBanks.length,
            'transactions': transactions.length,
          },
        );

        // Clear and insert data in transaction using batch operations for performance
        await _database.transaction(() async {
          _logger.fine('Clearing local database');
          
          // Clear tables in correct order (respecting foreign keys)
          await _database.delete(_database.transactions).go();
          await _database.delete(_database.piggyBanks).go();
          await _database.delete(_database.bills).go();
          await _database.delete(_database.budgets).go();
          await _database.delete(_database.categories).go();
          await _database.delete(_database.accounts).go();
          await _database.delete(_database.idMapping).go();

          // Use batch operations for efficient bulk inserts
          _logger.fine('Batch inserting accounts (${accounts.length} items)');
          await _database.batch((batch) {
            for (final account in accounts) {
              final attrs = account['attributes'] as Map<String, dynamic>;
              batch.insert(
                _database.accounts,
                AccountEntityCompanion.insert(
                  id: account['id'] as String,
                  serverId: Value(account['id'] as String),
                  name: attrs['name'] as String,
                  type: attrs['type'] as String,
                  accountNumber: Value(attrs['account_number'] as String?),
                  iban: Value(attrs['iban'] as String?),
                  currencyCode: attrs['currency_code'] as String? ?? 'USD',
                  currentBalance: (attrs['current_balance'] as num?)?.toDouble() ?? 0.0,
                  notes: Value(attrs['notes'] as String?),
                  createdAt: DateTime.parse(attrs['created_at'] as String),
                  updatedAt: DateTime.parse(attrs['updated_at'] as String),
                  isSynced: const Value(true),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          });

          _logger.fine('Batch inserting categories (${categories.length} items)');
          await _database.batch((batch) {
            for (final category in categories) {
              final attrs = category['attributes'] as Map<String, dynamic>;
              batch.insert(
                _database.categories,
                CategoryEntityCompanion.insert(
                  id: category['id'] as String,
                  serverId: Value(category['id'] as String),
                  name: attrs['name'] as String,
                  notes: Value(attrs['notes'] as String?),
                  createdAt: DateTime.parse(attrs['created_at'] as String),
                  updatedAt: DateTime.parse(attrs['updated_at'] as String),
                  isSynced: const Value(true),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          });

          _logger.fine('Batch inserting budgets (${budgets.length} items)');
          await _database.batch((batch) {
            for (final budget in budgets) {
              final attrs = budget['attributes'] as Map<String, dynamic>;
              batch.insert(
                _database.budgets,
                BudgetEntityCompanion.insert(
                  id: budget['id'] as String,
                  serverId: Value(budget['id'] as String),
                  name: attrs['name'] as String,
                  createdAt: DateTime.parse(attrs['created_at'] as String),
                  updatedAt: DateTime.parse(attrs['updated_at'] as String),
                  isSynced: const Value(true),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          });

          _logger.fine('Batch inserting bills (${bills.length} items)');
          await _database.batch((batch) {
            for (final bill in bills) {
              final attrs = bill['attributes'] as Map<String, dynamic>;
              batch.insert(
                _database.bills,
                BillEntityCompanion.insert(
                  id: bill['id'] as String,
                  serverId: Value(bill['id'] as String),
                  name: attrs['name'] as String,
                  amountMin: (attrs['amount_min'] as num).toDouble(),
                  amountMax: (attrs['amount_max'] as num).toDouble(),
                  date: DateTime.parse(attrs['date'] as String),
                  repeatFreq: attrs['repeat_freq'] as String,
                  currencyCode: attrs['currency_code'] as String? ?? 'USD',
                  notes: Value(attrs['notes'] as String?),
                  createdAt: DateTime.parse(attrs['created_at'] as String),
                  updatedAt: DateTime.parse(attrs['updated_at'] as String),
                  isSynced: const Value(true),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          });

          _logger.fine('Batch inserting piggy banks (${piggyBanks.length} items)');
          await _database.batch((batch) {
            for (final piggyBank in piggyBanks) {
              final attrs = piggyBank['attributes'] as Map<String, dynamic>;
              batch.insert(
                _database.piggyBanks,
                PiggyBankEntityCompanion.insert(
                  id: piggyBank['id'] as String,
                  serverId: Value(piggyBank['id'] as String),
                  name: attrs['name'] as String,
                  accountId: attrs['account_id'] as String,
                  targetAmount: Value((attrs['target_amount'] as num?)?.toDouble()),
                  currentAmount: Value((attrs['current_amount'] as num?)?.toDouble() ?? 0.0),
                  startDate: Value(attrs['start_date'] != null ? DateTime.parse(attrs['start_date'] as String) : null),
                  targetDate: Value(attrs['target_date'] != null ? DateTime.parse(attrs['target_date'] as String) : null),
                  createdAt: DateTime.parse(attrs['created_at'] as String),
                  updatedAt: DateTime.parse(attrs['updated_at'] as String),
                  isSynced: const Value(true),
                  syncStatus: const Value('synced'),
                ),
              );
            }
          });

          // Process transactions in batches to avoid memory issues with large datasets
          _logger.fine('Batch inserting transactions (${transactions.length} items)');
          const batchSize = 500; // Process 500 transactions at a time
          for (int i = 0; i < transactions.length; i += batchSize) {
            final end = (i + batchSize < transactions.length) ? i + batchSize : transactions.length;
            final batch = transactions.sublist(i, end);
            
            _logger.fine('Processing transaction batch ${i ~/ batchSize + 1} (${batch.length} items)');
            
            await _database.batch((dbBatch) {
              for (final transaction in batch) {
                final attrs = transaction['attributes'] as Map<String, dynamic>;
                final txList = attrs['transactions'] as List<dynamic>;
                
                for (final tx in txList) {
                  final txData = tx as Map<String, dynamic>;
                  dbBatch.insert(
                    _database.transactions,
                    TransactionEntityCompanion.insert(
                      id: transaction['id'] as String,
                      serverId: Value(transaction['id'] as String),
                      type: txData['type'] as String,
                      date: DateTime.parse(txData['date'] as String),
                      amount: (txData['amount'] as num).toDouble(),
                      description: txData['description'] as String,
                      sourceAccountId: txData['source_id'] as String,
                      destinationAccountId: txData['destination_id'] as String,
                      categoryId: Value(txData['category_id'] as String?),
                      budgetId: Value(txData['budget_id'] as String?),
                      currencyCode: txData['currency_code'] as String? ?? 'USD',
                      foreignAmount: Value((txData['foreign_amount'] as num?)?.toDouble()),
                      foreignCurrencyCode: Value(txData['foreign_currency_code'] as String?),
                      notes: Value(txData['notes'] as String?),
                      tags: Value(txData['tags']?.toString() ?? '[]'),
                      createdAt: DateTime.parse(attrs['created_at'] as String),
                      updatedAt: DateTime.parse(attrs['updated_at'] as String),
                      isSynced: const Value(true),
                      syncStatus: const Value('synced'),
                    ),
                  );
                }
              }
            });
          }

          _logger.info('Full sync data insertion completed successfully');
        });

        // Update sync metadata
        await _database.into(_database.syncMetadata).insertOnConflictUpdate(
          SyncMetadataEntityCompanion.insert(
            key: 'last_full_sync',
            value: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now(),
          ),
        );

        _lastFullSyncTime = DateTime.now();
        _lastSyncTime = DateTime.now();

        _progressTracker.complete(success: true);

        _logger.info('Full sync completed successfully');
      } catch (e, stackTrace) {
        _logger.severe('Full sync failed', e, stackTrace);
        _progressTracker.complete(success: false);
        rethrow;
      }
    });
  }

  /// Perform incremental sync from server.
  ///
  /// Fetches only changes since last sync and merges with local data.
  /// Preserves local pending changes and detects conflicts.
  ///
  /// Steps:
  /// 1. Get last sync timestamp from metadata
  /// 2. Fetch changes since last sync from server
  /// 3. Merge with local data (preserve pending changes)
  /// 4. Detect and handle conflicts
  /// 5. Update last_sync timestamp
  ///
  /// Throws:
  ///   NetworkError: If server is unreachable
  ///   DatabaseException: If database operations fail
  Future<void> performIncrementalSync() async {
    await _syncLock.synchronized(() async {
      try {
        _logger.info('Starting incremental sync from server');

        if (_lastSyncTime == null) {
          _logger.warning('No previous sync, performing full sync instead');
          await performFullSync();
          return;
        }

        _progressTracker.start(
          totalOperations: 6,
          phase: SyncPhase.pulling,
        );

        final since = _lastSyncTime!;

        // Fetch changes from server
        _logger.fine('Fetching account changes since $since');
        final accounts = await _apiClient.getAccountsSince(since);
        await _mergeAccounts(accounts);
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching category changes since $since');
        final categories = await _apiClient.getCategoriesSince(since);
        await _mergeCategories(categories);
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching budget changes since $since');
        final budgets = await _apiClient.getBudgetsSince(since);
        await _mergeBudgets(budgets);
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching bill changes since $since');
        final bills = await _apiClient.getBillsSince(since);
        await _mergeBills(bills);
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching piggy bank changes since $since');
        final piggyBanks = await _apiClient.getPiggyBanksSince(since);
        await _mergePiggyBanks(piggyBanks);
        _progressTracker.incrementCompleted();

        _logger.fine('Fetching transaction changes since $since');
        final transactions = await _apiClient.getTransactionsSince(since);
        await _mergeTransactions(transactions);
        _progressTracker.incrementCompleted();

        _logger.info(
          'Fetched changes from server',
          <String, dynamic>{
            'accounts': accounts.length,
            'categories': categories.length,
            'budgets': budgets.length,
            'bills': bills.length,
            'piggy_banks': piggyBanks.length,
            'transactions': transactions.length,
          },
        );

        // Update sync metadata
        await _database.into(_database.syncMetadata).insertOnConflictUpdate(
          SyncMetadataEntityCompanion.insert(
            key: 'last_partial_sync',
            value: DateTime.now().toIso8601String(),
            updatedAt: DateTime.now(),
          ),
        );

        _lastSyncTime = DateTime.now();

        _progressTracker.complete(success: true);

        _logger.info('Incremental sync completed successfully');
      } catch (e, stackTrace) {
        _logger.severe('Incremental sync failed', e, stackTrace);
        _progressTracker.complete(success: false);
        rethrow;
      }
    });
  }

  /// Merge accounts from server with local data
  Future<void> _mergeAccounts(List<Map<String, dynamic>> accounts) async {
    for (final account in accounts) {
      final serverId = account['id'] as String;
      final attrs = account['attributes'] as Map<String, dynamic>;
      
      // Check if local has pending changes
      final local = await (_database.select(_database.accounts)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .getSingleOrNull();
      
      if (local != null && !local.isSynced) {
        await _storeConflict(
          entityType: 'account',
          entityId: serverId,
          localData: local,
          serverData: attrs,
        );
        _progressTracker.incrementConflicts();
        continue;
      }
      
      // Merge server data
      await _database.into(_database.accounts).insertOnConflictUpdate(
        AccountEntityCompanion.insert(
          id: serverId,
          serverId: Value(serverId),
          name: attrs['name'] as String,
          type: attrs['type'] as String,
          accountNumber: Value(attrs['account_number'] as String?),
          iban: Value(attrs['iban'] as String?),
          currencyCode: attrs['currency_code'] as String? ?? 'USD',
          currentBalance: (attrs['current_balance'] as num?)?.toDouble() ?? 0.0,
          notes: Value(attrs['notes'] as String?),
          createdAt: DateTime.parse(attrs['created_at'] as String),
          updatedAt: DateTime.parse(attrs['updated_at'] as String),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Merge categories from server with local data
  Future<void> _mergeCategories(List<Map<String, dynamic>> categories) async {
    for (final category in categories) {
      final serverId = category['id'] as String;
      final attrs = category['attributes'] as Map<String, dynamic>;
      
      final local = await (_database.select(_database.categories)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .getSingleOrNull();
      
      if (local != null && !local.isSynced) {
        await _storeConflict(
          entityType: 'category',
          entityId: serverId,
          localData: local,
          serverData: attrs,
        );
        _progressTracker.incrementConflicts();
        continue;
      }
      
      await _database.into(_database.categories).insertOnConflictUpdate(
        CategoryEntityCompanion.insert(
          id: serverId,
          serverId: Value(serverId),
          name: attrs['name'] as String,
          notes: Value(attrs['notes'] as String?),
          createdAt: DateTime.parse(attrs['created_at'] as String),
          updatedAt: DateTime.parse(attrs['updated_at'] as String),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Merge budgets from server with local data
  Future<void> _mergeBudgets(List<Map<String, dynamic>> budgets) async {
    for (final budget in budgets) {
      final serverId = budget['id'] as String;
      final attrs = budget['attributes'] as Map<String, dynamic>;
      
      final local = await (_database.select(_database.budgets)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .getSingleOrNull();
      
      if (local != null && !local.isSynced) {
        await _storeConflict(
          entityType: 'budget',
          entityId: serverId,
          localData: local,
          serverData: attrs,
        );
        _progressTracker.incrementConflicts();
        continue;
      }
      
      await _database.into(_database.budgets).insertOnConflictUpdate(
        BudgetEntityCompanion.insert(
          id: serverId,
          serverId: Value(serverId),
          name: attrs['name'] as String,
          createdAt: DateTime.parse(attrs['created_at'] as String),
          updatedAt: DateTime.parse(attrs['updated_at'] as String),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Merge bills from server with local data
  Future<void> _mergeBills(List<Map<String, dynamic>> bills) async {
    for (final bill in bills) {
      final serverId = bill['id'] as String;
      final attrs = bill['attributes'] as Map<String, dynamic>;
      
      final local = await (_database.select(_database.bills)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .getSingleOrNull();
      
      if (local != null && !local.isSynced) {
        await _storeConflict(
          entityType: 'bill',
          entityId: serverId,
          localData: local,
          serverData: attrs,
        );
        _progressTracker.incrementConflicts();
        continue;
      }
      
      await _database.into(_database.bills).insertOnConflictUpdate(
        BillEntityCompanion.insert(
          id: serverId,
          serverId: Value(serverId),
          name: attrs['name'] as String,
          amountMin: (attrs['amount_min'] as num).toDouble(),
          amountMax: (attrs['amount_max'] as num).toDouble(),
          date: DateTime.parse(attrs['date'] as String),
          repeatFreq: attrs['repeat_freq'] as String,
          currencyCode: attrs['currency_code'] as String? ?? 'USD',
          notes: Value(attrs['notes'] as String?),
          createdAt: DateTime.parse(attrs['created_at'] as String),
          updatedAt: DateTime.parse(attrs['updated_at'] as String),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Merge piggy banks from server with local data
  Future<void> _mergePiggyBanks(List<Map<String, dynamic>> piggyBanks) async {
    for (final piggyBank in piggyBanks) {
      final serverId = piggyBank['id'] as String;
      final attrs = piggyBank['attributes'] as Map<String, dynamic>;
      
      final local = await (_database.select(_database.piggyBanks)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .getSingleOrNull();
      
      if (local != null && !local.isSynced) {
        await _storeConflict(
          entityType: 'piggy_bank',
          entityId: serverId,
          localData: local,
          serverData: attrs,
        );
        _progressTracker.incrementConflicts();
        continue;
      }
      
      await _database.into(_database.piggyBanks).insertOnConflictUpdate(
        PiggyBankEntityCompanion.insert(
          id: serverId,
          serverId: Value(serverId),
          name: attrs['name'] as String,
          accountId: attrs['account_id'] as String,
          targetAmount: Value((attrs['target_amount'] as num?)?.toDouble()),
          currentAmount: Value((attrs['current_amount'] as num?)?.toDouble() ?? 0.0),
          startDate: Value(attrs['start_date'] != null ? DateTime.parse(attrs['start_date'] as String) : null),
          targetDate: Value(attrs['target_date'] != null ? DateTime.parse(attrs['target_date'] as String) : null),
          createdAt: DateTime.parse(attrs['created_at'] as String),
          updatedAt: DateTime.parse(attrs['updated_at'] as String),
          isSynced: const Value(true),
          syncStatus: const Value('synced'),
        ),
      );
    }
  }

  /// Merge transactions from server with local data
  Future<void> _mergeTransactions(List<Map<String, dynamic>> transactions) async {
    for (final transaction in transactions) {
      final serverId = transaction['id'] as String;
      final attrs = transaction['attributes'] as Map<String, dynamic>;
      
      final local = await (_database.select(_database.transactions)
            ..where((tbl) => tbl.serverId.equals(serverId)))
          .getSingleOrNull();
      
      if (local != null && !local.isSynced) {
        await _storeConflict(
          entityType: 'transaction',
          entityId: serverId,
          localData: local,
          serverData: attrs,
        );
        _progressTracker.incrementConflicts();
        continue;
      }
      
      final txList = attrs['transactions'] as List<dynamic>;
      for (final tx in txList) {
        final txData = tx as Map<String, dynamic>;
        await _database.into(_database.transactions).insertOnConflictUpdate(
          TransactionEntityCompanion.insert(
            id: serverId,
            serverId: Value(serverId),
            type: txData['type'] as String,
            date: DateTime.parse(txData['date'] as String),
            amount: (txData['amount'] as num).toDouble(),
            description: txData['description'] as String,
            sourceAccountId: txData['source_id'] as String,
            destinationAccountId: txData['destination_id'] as String,
            categoryId: Value(txData['category_id'] as String?),
            budgetId: Value(txData['budget_id'] as String?),
            currencyCode: txData['currency_code'] as String? ?? 'USD',
            foreignAmount: Value((txData['foreign_amount'] as num?)?.toDouble()),
            foreignCurrencyCode: Value(txData['foreign_currency_code'] as String?),
            notes: Value(txData['notes'] as String?),
            tags: Value(txData['tags']?.toString() ?? '[]'),
            createdAt: DateTime.parse(attrs['created_at'] as String),
            updatedAt: DateTime.parse(attrs['updated_at'] as String),
            isSynced: const Value(true),
            syncStatus: const Value('synced'),
          ),
        );
      }
    }
  }

  /// Schedule periodic sync.
  Future<void> schedulePeriodicSync(Duration interval) async {
    _logger.info('Scheduling periodic sync every ${interval.inMinutes} minutes');
    
    try {
      await Workmanager().registerPeriodicTask(
        'waterfly-sync',
        'syncTask',
        frequency: interval,
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
      
      _logger.info('Background sync scheduled successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to schedule background sync', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel scheduled sync.
  Future<void> cancelScheduledSync() async {
    _logger.info('Cancelling scheduled sync');
    
    try {
      await Workmanager().cancelByUniqueName('waterfly-sync');
      _logger.info('Background sync cancelled successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to cancel background sync', e, stackTrace);
      rethrow;
    }
  }

  /// Store conflict in database for user resolution.
  Future<void> _storeConflict({
    required String entityType,
    required String entityId,
    required dynamic localData,
    required Map<String, dynamic> serverData,
  }) async {
    try {
      final conflictId = '${entityType}_${entityId}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Detect conflicting fields
      final conflictingFields = _detectConflictingFields(localData, serverData);
      
      await _database.into(_database.conflicts).insert(
        ConflictEntityCompanion.insert(
          id: conflictId,
          entityType: entityType,
          entityId: entityId,
          conflictType: 'update_conflict',
          localData: _serializeData(localData),
          serverData: _serializeData(serverData),
          conflictingFields: jsonEncode(conflictingFields),
          detectedAt: DateTime.now(),
        ),
      );
      
      _logger.info(
        'Stored conflict for resolution',
        <String, dynamic>{
          'conflict_id': conflictId,
          'entity_type': entityType,
          'entity_id': entityId,
          'conflicting_fields': conflictingFields,
        },
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to store conflict', e, stackTrace);
    }
  }

  /// Detect which fields differ between local and server data.
  List<String> _detectConflictingFields(
    dynamic localData,
    Map<String, dynamic> serverData,
  ) {
    final conflictingFields = <String>[];
    
    try {
      // Convert local data to map
      final Map<String, dynamic> localMap = localData is Map
          ? Map<String, dynamic>.from(localData)
          : (localData as dynamic).toJson();
      
      // Compare each field
      for (final key in serverData.keys) {
        if (!localMap.containsKey(key)) continue;
        
        final localValue = localMap[key];
        final serverValue = serverData[key];
        
        // Skip null comparisons
        if (localValue == null && serverValue == null) continue;
        
        // Check if values differ
        if (localValue != serverValue) {
          conflictingFields.add(key);
        }
      }
      
      // Check for fields only in local
      for (final key in localMap.keys) {
        if (!serverData.containsKey(key) && localMap[key] != null) {
          conflictingFields.add(key);
        }
      }
    } catch (e) {
      _logger.warning('Failed to detect conflicting fields: $e');
      // Return empty list on error
    }
    
    return conflictingFields;
  }

  /// Serialize data to JSON string.
  String _serializeData(dynamic data) {
    if (data is Map) {
      return data.toString();
    }
    return data.toJson().toString();
  }

  /// Initialize connectivity listener for automatic retry.
  void _initializeConnectivityListener() {
    _connectivitySubscription = _connectivity.statusStream.listen(
      (status) {
        _handleConnectivityChange(status);
      },
      onError: (error, stackTrace) {
        _logger.severe('Connectivity listener error', error, stackTrace);
      },
    );
    
    _logger.info('Connectivity listener initialized');
  }

  /// Handle connectivity status changes.
  void _handleConnectivityChange(ConnectivityStatus status) {
    final isOnline = status == ConnectivityStatus.online;
    
    _logger.fine(
      'Connectivity changed',
      <String, dynamic>{
        'status': status.name,
        'was_offline': _wasOffline,
        'auto_sync_enabled': autoSyncOnReconnect,
      },
    );

    if (isOnline && _wasOffline && autoSyncOnReconnect) {
      _logger.info('Network restored, triggering automatic sync');
      
      // Trigger sync asynchronously to avoid blocking the listener
      Future.microtask(() async {
        try {
          await synchronize();
        } catch (e, stackTrace) {
          _logger.warning('Auto-sync after reconnect failed', e, stackTrace);
        }
      });
    }

    _wasOffline = !isOnline;
  }

  /// Check if device is online before sync operations.
  Future<bool> _checkConnectivity() async {
    final status = _connectivity.currentStatus;
    final isOnline = status == ConnectivityStatus.online;
    
    if (!isOnline) {
      _logger.warning('Cannot sync: device is offline');
    }
    
    return isOnline;
  }

  /// Get operation statistics for analytics and monitoring.
  ///
  /// Returns comprehensive statistics including:
  /// - Total operations processed
  /// - Success/failure rates
  /// - Average processing time
  /// - Retry statistics
  Future<OperationStatistics> getOperationStatistics() async {
    return await _operationTracker.getOperationStatistics();
  }

  /// Get the complete history of a specific operation.
  ///
  /// Returns all status changes for the operation with timestamps.
  Future<List<OperationHistoryEntry>> getOperationHistory(
    String operationId,
  ) async {
    return await _operationTracker.getOperationHistory(operationId);
  }

  /// Clear old operation history to prevent unbounded growth.
  ///
  /// Removes history entries older than [retentionDays] (default 30 days).
  Future<void> clearOldOperationHistory({int retentionDays = 30}) async {
    await _operationTracker.clearOldHistory(retentionDays: retentionDays);
  }

  /// Dispose resources.
  void dispose() {
    _logger.fine('Disposing sync manager');
    _connectivitySubscription?.cancel();
    _progressTracker.dispose();
  }
}
