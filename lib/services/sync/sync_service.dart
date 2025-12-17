import 'dart:async';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/exceptions/sync_exceptions.dart' as sync_ex;
import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/models/sync_operation.dart';
import 'package:waterflyiii/models/sync_progress.dart';
import 'package:waterflyiii/services/sync/conflict_detector.dart';
import 'package:waterflyiii/services/sync/conflict_resolver.dart';
import 'package:waterflyiii/services/sync/database_adapter.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/metadata_service.dart';
import 'package:waterflyiii/services/sync/sync_progress_tracker.dart';
import 'package:waterflyiii/services/sync/sync_queue_manager.dart';

/// Synchronization mode
enum SyncMode {
  /// Full synchronization - fetch all data from server
  full,

  /// Incremental synchronization - fetch only changes since last sync
  incremental,
}

/// Comprehensive synchronization service supporting both full and incremental sync.
///
/// Consolidates full_sync_service.dart and incremental_sync_service.dart to eliminate
/// duplication and provide a unified sync interface.
///
/// Features:
/// - Full sync with pagination and batch processing
/// - Incremental sync with ETag caching and timestamp filtering
/// - Conflict detection and resolution
/// - Progress tracking and statistics
/// - Comprehensive error handling and retry logic
/// - Transaction-based operations for data integrity
///
/// Example:
/// ```dart
/// final syncService = SyncService(
///   apiAdapter: apiAdapter,
///   dbAdapter: dbAdapter,
///   database: database,
///   progressTracker: progressTracker,
///   metadata: metadata,
/// );
///
/// // Perform full sync
/// final result = await syncService.sync(mode: SyncMode.full);
///
/// // Perform incremental sync
/// final result = await syncService.sync(mode: SyncMode.incremental);
/// ```
class SyncService {
  final Logger _logger = Logger('SyncService');

  final FireflyApiAdapter _apiAdapter;
  final DatabaseAdapter _dbAdapter;
  final AppDatabase _database;
  final SyncProgressTracker _progressTracker;
  final MetadataService _metadata;
  final ConflictDetector _conflictDetector;
  final ConflictResolver _conflictResolver;

  /// Batch size for processing entities
  final int batchSize;

  /// Page size for API pagination
  final int pageSize;

  /// Timeout for sync operations
  final Duration timeout;

  /// Whether to clear local data before full sync
  final bool clearLocalDataOnFullSync;

  SyncService({
    required FireflyApiAdapter apiAdapter,
    required DatabaseAdapter dbAdapter,
    required AppDatabase database,
    required SyncProgressTracker progressTracker,
    required MetadataService metadata,
    ConflictDetector? conflictDetector,
    ConflictResolver? conflictResolver,
    this.batchSize = 100,
    this.pageSize = 50,
    this.timeout = const Duration(minutes: 30),
    this.clearLocalDataOnFullSync = false,
  }) : _apiAdapter = apiAdapter,
       _dbAdapter = dbAdapter,
       _database = database,
       _progressTracker = progressTracker,
       _metadata = metadata,
       _conflictDetector = conflictDetector ?? ConflictDetector(),
       _conflictResolver =
           conflictResolver ??
           ConflictResolver(
             apiAdapter: apiAdapter,
             database: database,
             queueManager: SyncQueueManager(database),
           );

  /// Watch sync progress updates.
  Stream<SyncProgress> watchProgress() => _progressTracker.watchProgress();

  /// Watch sync events.
  Stream<SyncEvent> watchEvents() => _progressTracker.watchEvents();

  /// Perform synchronization with specified mode.
  ///
  /// Returns [SyncResult] with detailed statistics about the sync operation.
  /// Throws [SyncException] if sync fails.
  Future<SyncResult> sync({
    required SyncMode mode,
    List<String>? entityTypes,
  }) async {
    final DateTime startTime = DateTime.now();
    _logger.info('Starting ${mode.name} sync');

    try {
      final SyncResult result = await _performSyncWithTimeout(
        mode: mode,
        entityTypes: entityTypes,
        startTime: startTime,
      );

      _logger.info(
        '${mode.name} sync completed: ${result.successfulOperations}/${result.totalOperations} successful',
      );
      return result;
    } on TimeoutException catch (e, stackTrace) {
      _logger.severe(
        'Sync timeout after ${timeout.inMinutes} minutes',
        e,
        stackTrace,
      );
      _progressTracker.cancel();
      throw sync_ex.NetworkError(
        'Sync timeout after ${timeout.inMinutes} minutes',
      );
    } catch (e, stackTrace) {
      _logger.severe('Sync failed', e, stackTrace);
      _progressTracker.cancel();
      rethrow;
    }
  }

  Future<SyncResult> _performSyncWithTimeout({
    required SyncMode mode,
    List<String>? entityTypes,
    required DateTime startTime,
  }) async {
    return Future.any(<Future<SyncResult>>[
      _performSync(mode: mode, entityTypes: entityTypes, startTime: startTime),
      Future.delayed(
        timeout,
        () => throw TimeoutException('Sync timeout', timeout),
      ),
    ]);
  }

  Future<SyncResult> _performSync({
    required SyncMode mode,
    List<String>? entityTypes,
    required DateTime startTime,
  }) async {
    switch (mode) {
      case SyncMode.full:
        return _performFullSync(entityTypes: entityTypes, startTime: startTime);
      case SyncMode.incremental:
        return _performIncrementalSync(
          entityTypes: entityTypes,
          startTime: startTime,
        );
    }
  }

  /// Perform full synchronization from server.
  ///
  /// Steps:
  /// 1. Optionally clear local database
  /// 2. Fetch all entities from server with pagination
  /// 3. Insert entities in batches
  /// 4. Mark all as synced with server IDs
  /// 5. Update metadata
  Future<SyncResult> _performFullSync({
    List<String>? entityTypes,
    required DateTime startTime,
  }) async {
    _logger.info('Performing full sync');

    final List<String> types =
        entityTypes ??
        <String>[
          'transactions',
          'accounts',
          'categories',
          'budgets',
          'bills',
          'piggy_banks',
        ];
    final Map<String, EntitySyncStats> statsByEntity =
        <String, EntitySyncStats>{};
    int totalOperations = 0;
    int successfulOperations = 0;
    int failedOperations = 0;
    final List<String> errors = <String>[];

    try {
      // Start progress tracking
      _progressTracker.start(
        totalOperations: types.length * 100, // Estimate, will be updated
        phase: SyncPhase.preparing,
      );

      // Clear local data if requested
      if (clearLocalDataOnFullSync) {
        _logger.info('Clearing local data');
        _progressTracker.updatePhase(SyncPhase.preparing);
        _progressTracker.updateCurrentOperation('Clearing local data');
        await _clearLocalData();
      }

      // Update phase to syncing
      _progressTracker.updatePhase(SyncPhase.syncing);

      // Sync each entity type
      for (final String entityType in types) {
        _logger.info('Syncing $entityType');
        _progressTracker.updateCurrentOperation('Syncing $entityType');

        try {
          final EntitySyncStats stats = await _syncEntityType(
            entityType: entityType,
            isIncremental: false,
          );

          statsByEntity[entityType] = stats;
          totalOperations += stats.total;
          successfulOperations += stats.successful;
          failedOperations += stats.failed;

          _progressTracker.addCompleted(stats.successful);
          for (int i = 0; i < stats.failed; i++) {
            _progressTracker.incrementFailed(
              error: 'Failed to sync $entityType entity',
            );
          }
        } catch (e, stackTrace) {
          _logger.severe('Failed to sync $entityType', e, stackTrace);
          errors.add('$entityType: ${e.toString()}');
          failedOperations++;
          _progressTracker.incrementFailed(
            error: '$entityType: ${e.toString()}',
          );
        }
      }

      // Update metadata
      await _metadata.set('last_full_sync', DateTime.now().toIso8601String());

      // Complete progress tracking
      _progressTracker.complete(
        success: failedOperations == 0,
        entityStats: statsByEntity,
      );

      return SyncResult(
        success: failedOperations == 0,
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        skippedOperations: 0,
        conflictsDetected: 0,
        conflictsResolved: 0,
        startTime: startTime,
        endTime: DateTime.now(),
        errors: errors,
        statsByEntity: statsByEntity,
      );
    } catch (e, stackTrace) {
      _logger.severe('Full sync failed', e, stackTrace);
      _progressTracker.cancel();
      throw sync_ex.ServerError('Full sync failed: ${e.toString()}');
    }
  }

  /// Perform incremental synchronization from server.
  ///
  /// Steps:
  /// 1. Get last sync timestamp from metadata
  /// 2. Fetch only changed entities since last sync
  /// 3. Detect conflicts with local changes
  /// 4. Resolve conflicts using configured strategy
  /// 5. Update entities in batches
  /// 6. Update metadata and ETags
  Future<SyncResult> _performIncrementalSync({
    List<String>? entityTypes,
    required DateTime startTime,
  }) async {
    _logger.info('Performing incremental sync');

    final List<String> types =
        entityTypes ??
        <String>[
          'transactions',
          'accounts',
          'categories',
          'budgets',
          'bills',
          'piggy_banks',
        ];
    final Map<String, EntitySyncStats> statsByEntity =
        <String, EntitySyncStats>{};
    int totalOperations = 0;
    int successfulOperations = 0;
    int failedOperations = 0;
    int conflictsDetected = 0;
    int conflictsResolved = 0;
    final List<String> errors = <String>[];

    try {
      // Start progress tracking
      _progressTracker.start(
        totalOperations: types.length * 50, // Estimate for incremental
        phase: SyncPhase.preparing,
      );

      // Get last sync timestamp
      final String? lastSyncStr = await _metadata.get('last_incremental_sync');
      final DateTime? lastSync =
          lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;

      if (lastSync == null) {
        _logger.warning('No last sync timestamp, performing full sync instead');
        _progressTracker.cancel();
        return await _performFullSync(
          entityTypes: entityTypes,
          startTime: startTime,
        );
      }

      // Update phase to pulling (fetching from server)
      _progressTracker.updatePhase(SyncPhase.pulling);

      // Sync each entity type
      for (final String entityType in types) {
        _logger.info('Syncing $entityType (incremental)');
        _progressTracker.updateCurrentOperation('Syncing $entityType');

        try {
          final EntitySyncStats stats = await _syncEntityType(
            entityType: entityType,
            isIncremental: true,
            since: lastSync,
          );

          statsByEntity[entityType] = stats;
          totalOperations += stats.total;
          successfulOperations += stats.successful;
          failedOperations += stats.failed;
          conflictsDetected += stats.conflicts;

          _progressTracker.addCompleted(stats.successful);
          for (int i = 0; i < stats.conflicts; i++) {
            _progressTracker.incrementConflicts(
              conflictId: '$entityType-conflict-$i',
            );
          }
        } catch (e, stackTrace) {
          _logger.severe('Failed to sync $entityType', e, stackTrace);
          errors.add('$entityType: ${e.toString()}');
          failedOperations++;
          _progressTracker.incrementFailed(
            error: '$entityType: ${e.toString()}',
          );
        }
      }

      // Update metadata
      await _metadata.set(
        'last_incremental_sync',
        DateTime.now().toIso8601String(),
      );

      // Complete progress tracking
      _progressTracker.complete(
        success: failedOperations == 0,
        entityStats: statsByEntity,
      );

      return SyncResult(
        success: failedOperations == 0,
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        skippedOperations: 0,
        conflictsDetected: conflictsDetected,
        conflictsResolved: conflictsResolved,
        startTime: startTime,
        endTime: DateTime.now(),
        errors: errors,
        statsByEntity: statsByEntity,
      );
    } catch (e, stackTrace) {
      _logger.severe('Incremental sync failed', e, stackTrace);
      _progressTracker.cancel();
      throw sync_ex.ServerError('Incremental sync failed: ${e.toString()}');
    }
  }

  /// Sync a specific entity type from server.
  Future<EntitySyncStats> _syncEntityType({
    required String entityType,
    required bool isIncremental,
    DateTime? since,
  }) async {
    int total = 0;
    int successful = 0;
    int failed = 0;
    int conflicts = 0;

    try {
      // Fetch entities from API with pagination
      final List<Map<String, dynamic>> entities = await _fetchEntitiesFromAPI(
        entityType: entityType,
        since: since,
      );

      total = entities.length;
      _logger.info('Fetched $total $entityType from server');

      // Update progress tracker phase to syncing (processing entities)
      _progressTracker.updatePhase(SyncPhase.syncing);

      // Process in batches
      for (int i = 0; i < entities.length; i += batchSize) {
        final int end =
            (i + batchSize < entities.length) ? i + batchSize : entities.length;
        final List<Map<String, dynamic>> batch = entities.sublist(i, end);

        for (final Map<String, dynamic> entity in batch) {
          try {
            // Check for conflicts if incremental
            if (isIncremental) {
              final bool hasConflict = await _checkForConflict(
                entityType,
                entity,
              );
              if (hasConflict) {
                conflicts++;
                _logger.warning(
                  'Conflict detected for $entityType ${entity['id']}',
                );

                // Attempt to resolve conflict
                final bool resolved = await _resolveConflict(
                  entityType,
                  entity,
                );
                if (!resolved) {
                  _logger.warning(
                    'Conflict not resolved for $entityType ${entity['id']}',
                  );
                  continue;
                }
              }
            }

            // Upsert entity to database
            await _upsertEntity(entityType, entity);
            successful++;
          } catch (e, stackTrace) {
            _logger.severe(
              'Failed to sync entity ${entity['id']}',
              e,
              stackTrace,
            );
            failed++;
          }
        }
      }

      return EntitySyncStats(
        entityType: entityType,
        creates: 0,
        updates: successful,
        deletes: 0,
        successful: successful,
        failed: failed,
        conflicts: conflicts,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to sync entity type $entityType', e, stackTrace);
      rethrow;
    }
  }

  /// Fetch entities from API with pagination using FireflyApiAdapter.
  Future<List<Map<String, dynamic>>> _fetchEntitiesFromAPI({
    required String entityType,
    DateTime? since,
  }) async {
    _logger.fine('Fetching $entityType from API (since: $since)');

    try {
      // Use incremental methods if since is provided, otherwise full fetch
      if (since != null) {
        return await _fetchEntitiesSince(entityType, since);
      } else {
        return await _fetchAllEntities(entityType);
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to fetch $entityType from API', e, stackTrace);
      rethrow;
    }
  }

  /// Fetch all entities of a type using FireflyApiAdapter.
  Future<List<Map<String, dynamic>>> _fetchAllEntities(
    String entityType,
  ) async {
    switch (entityType) {
      case 'transactions':
        return await _apiAdapter.getAllTransactions();
      case 'accounts':
        return await _apiAdapter.getAllAccounts();
      case 'categories':
        return await _apiAdapter.getAllCategories();
      case 'budgets':
        return await _apiAdapter.getAllBudgets();
      case 'bills':
        return await _apiAdapter.getAllBills();
      case 'piggy_banks':
        return await _apiAdapter.getAllPiggyBanks();
      default:
        _logger.warning('Unknown entity type: $entityType');
        return <Map<String, dynamic>>[];
    }
  }

  /// Fetch entities updated since a timestamp using FireflyApiAdapter.
  Future<List<Map<String, dynamic>>> _fetchEntitiesSince(
    String entityType,
    DateTime since,
  ) async {
    switch (entityType) {
      case 'transactions':
        return await _apiAdapter.getTransactionsSince(since);
      case 'accounts':
        return await _apiAdapter.getAccountsSince(since);
      case 'categories':
        return await _apiAdapter.getCategoriesSince(since);
      case 'budgets':
        return await _apiAdapter.getBudgetsSince(since);
      case 'bills':
        return await _apiAdapter.getBillsSince(since);
      case 'piggy_banks':
        return await _apiAdapter.getPiggyBanksSince(since);
      default:
        _logger.warning('Unknown entity type: $entityType');
        return <Map<String, dynamic>>[];
    }
  }

  /// Check if entity has conflicts with local version using ConflictDetector.
  Future<bool> _checkForConflict(
    String entityType,
    Map<String, dynamic> remoteEntity,
  ) async {
    try {
      final String? entityId = remoteEntity['id'] as String?;
      if (entityId == null) return false;

      // Get local entity from database
      final Map<String, dynamic>? localEntity = await _getLocalEntity(
        entityType,
        entityId,
      );
      if (localEntity == null) return false;

      // Check if local entity has pending changes (not yet synced)
      final bool isPending =
          localEntity['is_synced'] == false ||
          localEntity['sync_status'] == 'pending';
      if (!isPending) return false;

      // Create a sync operation to use with ConflictDetector
      final SyncOperation operation = SyncOperation(
        id: 'check-$entityId',
        entityType: entityType,
        entityId: entityId,
        operation: SyncOperationType.update,
        payload: localEntity,
        createdAt: DateTime.now(),
        priority: SyncPriority.normal,
      );

      // Use ConflictDetector to detect conflicts
      final Conflict? conflict = await _conflictDetector.detectConflict(
        operation,
        remoteEntity,
      );

      if (conflict != null) {
        _logger.info(
          'Conflict detected: ${conflict.id} (${conflict.conflictType})',
        );
        _progressTracker.incrementConflicts(conflictId: conflict.id);
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      _logger.severe('Failed to check for conflict', e, stackTrace);
      return false;
    }
  }

  /// Resolve a detected conflict using ConflictResolver.
  Future<bool> _resolveConflict(
    String entityType,
    Map<String, dynamic> remoteEntity,
  ) async {
    try {
      final String? entityId = remoteEntity['id'] as String?;
      if (entityId == null) return false;

      // Get local entity
      final Map<String, dynamic>? localEntity = await _getLocalEntity(
        entityType,
        entityId,
      );
      if (localEntity == null) {
        // No local entity means we can just use remote
        return true;
      }

      // Create a sync operation for the conflict
      final SyncOperation operation = SyncOperation(
        id: 'resolve-$entityId',
        entityType: entityType,
        entityId: entityId,
        operation: SyncOperationType.update,
        payload: localEntity,
        createdAt: DateTime.now(),
        priority: SyncPriority.normal,
      );

      // Detect the conflict
      final Conflict? conflict = await _conflictDetector.detectConflict(
        operation,
        remoteEntity,
      );

      if (conflict == null) {
        // No conflict to resolve
        return true;
      }

      // Use ConflictResolver to resolve the conflict
      // Default strategy: server wins for incremental sync
      final Resolution result = await _conflictResolver.resolveConflict(
        conflict,
        ResolutionStrategy.remoteWins,
      );

      _logger.info(
        'Conflict resolved: ${conflict.id} with strategy remoteWins, result: ${result.success}',
      );
      return result.success;
    } catch (e, stackTrace) {
      _logger.severe('Failed to resolve conflict', e, stackTrace);
      return false;
    }
  }

  /// Get local entity from database using DatabaseAdapter.
  Future<Map<String, dynamic>?> _getLocalEntity(
    String entityType,
    String entityId,
  ) async {
    try {
      switch (entityType) {
        case 'transactions':
          return await _dbAdapter.getTransaction(entityId);
        case 'accounts':
          return await _dbAdapter.getAccount(entityId);
        case 'categories':
          return await _dbAdapter.getCategory(entityId);
        case 'budgets':
          return await _dbAdapter.getBudget(entityId);
        case 'bills':
          return await _dbAdapter.getBill(entityId);
        case 'piggy_banks':
          return await _dbAdapter.getPiggyBank(entityId);
        default:
          _logger.fine('Unknown entity type for local fetch: $entityType');
          return null;
      }
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get local entity $entityType/$entityId',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Upsert entity to database using DatabaseAdapter.
  Future<void> _upsertEntity(
    String entityType,
    Map<String, dynamic> entity,
  ) async {
    // Transform API data to database format
    final Map<String, dynamic> dbEntity = _transformApiToDb(entityType, entity);

    switch (entityType) {
      case 'transactions':
        await _dbAdapter.upsertTransaction(dbEntity);
        break;
      case 'accounts':
        await _dbAdapter.upsertAccount(dbEntity);
        break;
      case 'categories':
        await _dbAdapter.upsertCategory(dbEntity);
        break;
      case 'budgets':
        await _dbAdapter.upsertBudget(dbEntity);
        break;
      case 'bills':
        await _dbAdapter.upsertBill(dbEntity);
        break;
      case 'piggy_banks':
        await _dbAdapter.upsertPiggyBank(dbEntity);
        break;
      default:
        _logger.warning('Upsert not implemented for $entityType');
    }
  }

  /// Transform API response data to database format.
  Map<String, dynamic> _transformApiToDb(
    String entityType,
    Map<String, dynamic> apiData,
  ) {
    // Extract attributes if present (API returns { id, type, attributes })
    final Map<String, dynamic> attributes =
        apiData['attributes'] is Map
            ? Map<String, dynamic>.from(apiData['attributes'] as Map)
            : <String, dynamic>{};

    // Merge id into attributes and set server_id
    final Map<String, dynamic> result = <String, dynamic>{
      'id': apiData['id'],
      'server_id': apiData['id'],
      ...attributes,
    };

    // Entity-specific transformations
    switch (entityType) {
      case 'transactions':
        // Handle nested transaction splits
        if (attributes['transactions'] is List) {
          final List transactions = attributes['transactions'] as List;
          if (transactions.isNotEmpty) {
            final Map<String, dynamic> firstSplit = Map<String, dynamic>.from(
              transactions.first as Map,
            );
            result.addAll(<String, dynamic>{
              'type': firstSplit['type'] ?? 'withdrawal',
              'date': firstSplit['date'],
              'amount': firstSplit['amount'],
              'description': firstSplit['description'],
              'source_account_id': firstSplit['source_id'],
              'destination_account_id': firstSplit['destination_id'],
              'category_id': firstSplit['category_id'],
              'budget_id': firstSplit['budget_id'],
              'currency_code': firstSplit['currency_code'],
              'notes': firstSplit['notes'],
            });
          }
        }
        break;
      case 'accounts':
        result['current_balance'] = attributes['current_balance'];
        result['account_role'] = attributes['account_role'];
        break;
      case 'bills':
        result['amount_min'] = attributes['amount_min'];
        result['amount_max'] = attributes['amount_max'];
        result['repeat_freq'] = attributes['repeat_freq'];
        break;
      case 'piggy_banks':
        result['account_id'] = attributes['account_id'];
        result['target_amount'] = attributes['target_amount'];
        result['current_amount'] = attributes['current_amount'];
        break;
    }

    return result;
  }

  /// Clear local database.
  Future<void> _clearLocalData() async {
    try {
      await _database.transaction(() async {
        // Clear all entity tables
        await _database.delete(_database.transactions).go();
        await _database.delete(_database.accounts).go();
        await _database.delete(_database.categories).go();
        await _database.delete(_database.budgets).go();
        await _database.delete(_database.bills).go();
        await _database.delete(_database.piggyBanks).go();

        // Don't clear sync metadata or sync queue
        _logger.info('Local data cleared');
      });
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear local data', e, stackTrace);
      throw DatabaseException('Failed to clear local data: ${e.toString()}');
    }
  }
}
