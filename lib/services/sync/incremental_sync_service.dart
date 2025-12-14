import 'dart:async';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';

import '../../models/sync_progress.dart';
import '../../models/conflict.dart';
import '../../exceptions/sync_exceptions.dart';
import '../api/firefly_api_client.dart';
import '../database/app_database.dart';
import 'sync_progress_tracker.dart';
import 'conflict_detector.dart';
import 'conflict_resolver.dart';
import 'entity_persistence_service.dart';
import 'metadata_service.dart';
import 'pagination_helper.dart';

/// Service for performing incremental synchronization from Firefly III server.
///
/// This service handles:
/// - Fetching only changes since last sync
/// - Merging server changes with local data
/// - Detecting and resolving conflicts
/// - Using ETags for efficient caching
/// - Minimizing data transfer
///
/// Uses the `dio` package with ETag support for optimal performance.
///
/// Example:
/// ```dart
/// final incrementalSync = IncrementalSyncService(
///   apiClient: fireflyClient,
///   database: appDatabase,
///   progressTracker: tracker,
///   conflictDetector: detector,
///   conflictResolver: resolver,
/// );
///
/// await incrementalSync.performIncrementalSync();
/// ```
class IncrementalSyncService {
  final Logger _logger = Logger('IncrementalSyncService');

  final FireflyApiClient _apiClient;
  final AppDatabase _database;
  final SyncProgressTracker _progressTracker;
  final ConflictDetector _conflictDetector;
  final ConflictResolver _conflictResolver;
  final EntityPersistenceService _persistence;
  final MetadataService _metadata;
  final PaginationHelper _pagination;

  /// Configuration
  final int batchSize;
  final int pageSize;
  final Duration timeout;
  final bool autoResolveConflicts;

  /// ETag cache for efficient requests
  final Map<String, String> _etagCache = {};

  IncrementalSyncService({
    required FireflyApiClient apiClient,
    required AppDatabase database,
    required SyncProgressTracker progressTracker,
    required ConflictDetector conflictDetector,
    required ConflictResolver conflictResolver,
    EntityPersistenceService? persistence,
    MetadataService? metadata,
    PaginationHelper? pagination,
    this.batchSize = 50,
    this.pageSize = 25,
    this.timeout = const Duration(minutes: 10),
    this.autoResolveConflicts = true,
  })  : _apiClient = apiClient,
        _database = database,
        _progressTracker = progressTracker,
        _conflictDetector = conflictDetector,
        _conflictResolver = conflictResolver,
        _persistence = persistence ?? EntityPersistenceService(database),
        _metadata = metadata ?? MetadataService(database),
        _pagination = pagination ?? PaginationHelper();

  /// Perform incremental synchronization from server.
  ///
  /// This will:
  /// 1. Get last sync timestamp
  /// 2. Fetch changes since last sync (using ETags when possible)
  /// 3. Merge with local data without overwriting pending changes
  /// 4. Detect and resolve conflicts
  /// 5. Update last_sync timestamp
  ///
  /// Returns:
  ///   SyncResult with statistics
  ///
  /// Throws:
  ///   NetworkError: If network connectivity fails
  ///   ServerError: If server returns error
  ///   TimeoutError: If operation exceeds timeout
  ///   ConflictError: If unresolvable conflicts detected
  Future<SyncResult> performIncrementalSync() async {
    final startTime = DateTime.now();

    try {
      _logger.info('Starting incremental synchronization from server');

      // Get last sync timestamp
      final lastSyncTime = await _getLastSyncTime();

      if (lastSyncTime == null) {
        _logger.warning('No previous sync found, cannot perform incremental sync');
        throw ConsistencyError(
          'No previous sync timestamp found',
          details: {'suggestion': 'Perform full sync first'},
        );
      }

      _logger.info('Last sync was at $lastSyncTime');

      _progressTracker.start(
        totalOperations: 1,
        phase: SyncPhase.pulling,
      );

      // Fetch changes since last sync
      final changes = await _fetchChangesSince(lastSyncTime);

      _logger.info(
        'Fetched ${changes['transactions']?.length ?? 0} transaction changes, '
        '${changes['accounts']?.length ?? 0} account changes, '
        '${changes['categories']?.length ?? 0} category changes, '
        '${changes['budgets']?.length ?? 0} budget changes, '
        '${changes['bills']?.length ?? 0} bill changes, '
        '${changes['piggy_banks']?.length ?? 0} piggy bank changes',
      );

      // Merge with local data
      _progressTracker.updatePhase(SyncPhase.syncing);
      final conflicts = await _mergeChanges(changes);

      // Resolve conflicts
      if (conflicts.isNotEmpty) {
        _progressTracker.updatePhase(SyncPhase.resolvingConflicts);
        await _resolveConflicts(conflicts);
      }

      // Update metadata
      _progressTracker.updatePhase(SyncPhase.finalizing);
      await _updateSyncMetadata();

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _logger.info(
        'Incremental synchronization completed successfully in ${duration.inSeconds}s',
      );

      final totalChanges = _calculateTotalChanges(changes);

      final result = SyncResult(
        success: true,
        totalOperations: totalChanges,
        completedOperations: totalChanges,
        failedOperations: 0,
        skippedOperations: 0,
        conflictsDetected: conflicts.length,
        conflictsResolved: conflicts.where((c) => c.isResolved).length,
        duration: duration,
        startTime: startTime,
        endTime: endTime,
        errors: const [],
        successRate: 1.0,
        throughput: totalChanges / duration.inSeconds,
        entityStats: _buildEntityStats(changes),
      );

      _progressTracker.complete(success: true);

      return result;
    } catch (e, stackTrace) {
      _logger.severe(
        'Incremental synchronization failed',
        e,
        stackTrace,
      );

      _progressTracker.complete(success: false);

      rethrow;
    }
  }

  /// Get last sync timestamp from metadata.
  Future<DateTime?> _getLastSyncTime() async {
    try {
      final result = await (_database.select(_database.metadata)
            ..where((m) => m.key.equals('last_sync')))
          .getSingleOrNull();

      if (result == null) {
        return null;
      }

      return DateTime.tryParse(result.value);
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to get last sync time',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Fetch changes since last sync with ETag support.
  Future<Map<String, List<Map<String, dynamic>>>> _fetchChangesSince(
    DateTime since,
  ) async {
    try {
      final changes = <String, List<Map<String, dynamic>>>{};

      // Fetch transaction changes
      _logger.info('Fetching transaction changes since $since');
      changes['transactions'] = await _fetchChangesForEntity(
        endpoint: '/api/v1/transactions',
        entityType: 'transactions',
        since: since,
      );

      // Fetch account changes
      _logger.info('Fetching account changes since $since');
      changes['accounts'] = await _fetchChangesForEntity(
        endpoint: '/api/v1/accounts',
        entityType: 'accounts',
        since: since,
      );

      // Fetch category changes
      _logger.info('Fetching category changes since $since');
      changes['categories'] = await _fetchChangesForEntity(
        endpoint: '/api/v1/categories',
        entityType: 'categories',
        since: since,
      );

      // Fetch budget changes
      _logger.info('Fetching budget changes since $since');
      changes['budgets'] = await _fetchChangesForEntity(
        endpoint: '/api/v1/budgets',
        entityType: 'budgets',
        since: since,
      );

      // Fetch bill changes
      _logger.info('Fetching bill changes since $since');
      changes['bills'] = await _fetchChangesForEntity(
        endpoint: '/api/v1/bills',
        entityType: 'bills',
        since: since,
      );

      // Fetch piggy bank changes
      _logger.info('Fetching piggy bank changes since $since');
      changes['piggy_banks'] = await _fetchChangesForEntity(
        endpoint: '/api/v1/piggy_banks',
        entityType: 'piggy_banks',
        since: since,
      );

      return changes;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to fetch changes from server',
        e,
        stackTrace,
      );

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw TimeoutError(
            'Request timed out while fetching changes',
            timeout: timeout,
          );
        } else if (e.type == DioExceptionType.connectionError) {
          throw NetworkError('Network connection failed');
        } else if (e.response?.statusCode != null) {
          final statusCode = e.response!.statusCode!;
          if (statusCode >= 500) {
            throw ServerError(
              'Server error: ${e.response?.statusMessage}',
              statusCode: statusCode,
            );
          } else if (statusCode >= 400) {
            throw ClientError(
              'Client error: ${e.response?.statusMessage}',
              statusCode: statusCode,
            );
          }
        }
      }

      rethrow;
    }
  }

  /// Fetch changes for a specific entity type with ETag support.
  Future<List<Map<String, dynamic>>> _fetchChangesForEntity({
    required String endpoint,
    required String entityType,
    required DateTime since,
  }) async {
    final allChanges = <Map<String, dynamic>>[];
    int page = 1;
    bool hasMore = true;

    // Get cached ETag if available
    final cachedETag = _etagCache[entityType];

    while (hasMore) {
      try {
        _logger.fine('Fetching $entityType changes page $page');

        // Build headers with ETag if available
        final headers = <String, dynamic>{};
        if (cachedETag != null) {
          headers['If-None-Match'] = cachedETag;
        }

        final response = await _apiClient.get(
          endpoint,
          queryParameters: {
            'page': page,
            'limit': pageSize,
            'start': since.toIso8601String(),
          },
          options: Options(headers: headers),
        );

        // Check for 304 Not Modified
        if (response.statusCode == 304) {
          _logger.info('$entityType not modified (ETag match)');
          hasMore = false;
          continue;
        }

        // Cache new ETag
        final newETag = response.headers.value('etag');
        if (newETag != null) {
          _etagCache[entityType] = newETag;
          _logger.fine('Cached ETag for $entityType: $newETag');
        }

        final data = response.data as Map<String, dynamic>;
        final entities = (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        allChanges.addAll(entities);

        // Check pagination
        final paginationInfo = _pagination.parsePagination(data);
        hasMore = paginationInfo.hasMore;

        _pagination.logProgress(
          paginationInfo,
          entityType,
          entities.length,
          allChanges.length,
        );

        page++;

        // Add small delay to avoid rate limiting
        await _pagination.applyRateLimit(hasMore);
      } catch (e, stackTrace) {
        _logger.severe(
          'Failed to fetch $entityType changes page $page',
          e,
          stackTrace,
        );
        rethrow;
      }
    }

    _logger.info('Fetched ${allChanges.length} $entityType changes from server');

    return allChanges;
  }

  /// Merge server changes with local data and detect conflicts.
  Future<List<Conflict>> _mergeChanges(
    Map<String, List<Map<String, dynamic>>> changes,
  ) async {
    final allConflicts = <Conflict>[];

    try {
      _logger.info('Merging server changes with local data');

      // Merge each entity type
      for (final entry in changes.entries) {
        final entityType = entry.key;
        final entities = entry.value;

        if (entities.isEmpty) {
          continue;
        }

        _logger.info('Merging ${entities.length} $entityType');

        final conflicts = await _mergeEntitiesInBatches(entityType, entities);
        allConflicts.addAll(conflicts);
      }

      _logger.info(
        'Merged changes successfully, detected ${allConflicts.length} conflicts',
      );

      return allConflicts;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to merge changes',
        e,
        stackTrace,
      );

      throw ConsistencyError(
        'Failed to merge server changes: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Merge entities in batches and detect conflicts.
  Future<List<Conflict>> _mergeEntitiesInBatches(
    String entityType,
    List<Map<String, dynamic>> entities,
  ) async {
    final conflicts = <Conflict>[];

    for (int i = 0; i < entities.length; i += batchSize) {
      final batch = entities.skip(i).take(batchSize).toList();

      await _database.transaction(() async {
        for (final entity in batch) {
          final conflict = await _mergeEntity(entityType, entity);
          if (conflict != null) {
            conflicts.add(conflict);
          }
        }
      });

      _logger.fine(
        'Merged batch ${(i / batchSize).floor() + 1}/${(entities.length / batchSize).ceil()} '
        'of $entityType',
      );
    }

    return conflicts;
  }

  /// Merge a single entity and detect conflicts.
  Future<Conflict?> _mergeEntity(
    String entityType,
    Map<String, dynamic> serverEntity,
  ) async {
    final serverId = serverEntity['id']?.toString();

    if (serverId == null) {
      _logger.warning('Server entity missing ID, skipping: $serverEntity');
      return null;
    }

    // Check if entity exists locally
    final localEntity = await _persistence.getEntityByServerId(entityType, serverId);

    if (localEntity == null) {
      // New entity from server, insert it
      await _persistence.insertEntity(entityType, serverEntity);
      return null;
    }

    // Check if local entity has pending changes
    final hasPendingChanges = await _hasPendingChanges(entityType, serverId);

    if (!hasPendingChanges) {
      // No local changes, safe to update
      await _persistence.updateEntity(entityType, serverId, serverEntity);
      return null;
    }

    // Detect conflict
    _logger.info('Detected conflict for $entityType/$serverId');

    final conflict = await _conflictDetector.detectConflict(
      entityType: entityType,
      entityId: serverId,
      localData: localEntity,
      remoteData: serverEntity,
    );

    if (conflict != null) {
      // Store conflict in database
      await _storeConflict(conflict);
    }

    return conflict;
  }

  /// Check if entity has pending changes in sync queue.
  Future<bool> _hasPendingChanges(String entityType, String entityId) async {
    final result = await (_database.select(_database.syncQueue)
          ..where((q) =>
              q.entityType.equals(entityType) &
              q.entityId.equals(entityId) &
              q.status.equals('pending')))
        .getSingleOrNull();

    return result != null;
  }

  /// Store conflict in database.
  Future<void> _storeConflict(Conflict conflict) async {
    await _database.into(_database.conflicts).insert(
          ConflictsCompanion.insert(
            id: conflict.id,
            operationId: Value(conflict.operationId),
            entityType: conflict.entityType,
            entityId: conflict.entityId,
            conflictType: conflict.conflictType.name,
            localData: Value(conflict.localData.toString()),
            remoteData: Value(conflict.remoteData.toString()),
            conflictingFields: Value(conflict.conflictingFields.join(',')),
            severity: conflict.severity.name,
            detectedAt: conflict.detectedAt,
          ),
        );

    _logger.info('Stored conflict ${conflict.id} in database');
  }

  /// Resolve detected conflicts.
  Future<void> _resolveConflicts(List<Conflict> conflicts) async {
    if (!autoResolveConflicts) {
      _logger.info('Auto-resolution disabled, ${conflicts.length} conflicts require manual resolution');
      return;
    }

    _logger.info('Auto-resolving ${conflicts.length} conflicts');

    final resolutions = await _conflictResolver.autoResolveConflicts(conflicts);

    _logger.info('Auto-resolved ${resolutions.length} out of ${conflicts.length} conflicts');
  }

  /// Update sync metadata after successful incremental sync.
  Future<void> _updateSyncMetadata() async {
    try {
      final now = DateTime.now().toIso8601String();

      await _metadata.setMany({
        MetadataKeys.lastIncrementalSync: now,
        MetadataKeys.lastSuccessfulSync: now,
      });

      _logger.info('Updated sync metadata');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to update sync metadata',
        e,
        stackTrace,
      );
      // Don't throw, this is not critical
    }
  }

  /// Calculate total number of changes.
  int _calculateTotalChanges(Map<String, List<Map<String, dynamic>>> changes) {
    return changes.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Build entity statistics.
  Map<String, EntitySyncStats> _buildEntityStats(
    Map<String, List<Map<String, dynamic>>> changes,
  ) {
    return changes.map((type, list) {
      return MapEntry(
        type,
        EntitySyncStats(
          entityType: type,
          totalOperations: list.length,
          completedOperations: list.length,
          failedOperations: 0,
          skippedOperations: 0,
        ),
      );
    });
  }

  /// Clear ETag cache.
  void clearETagCache() {
    _etagCache.clear();
    _logger.info('Cleared ETag cache');
  }
}
