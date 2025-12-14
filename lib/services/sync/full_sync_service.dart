import 'dart:async';
import 'package:logging/logging.dart';
import 'package:dio/dio.dart';

import '../../models/sync_progress.dart';
import '../../exceptions/sync_exceptions.dart';
import '../api/firefly_api_client.dart';
import '../database/app_database.dart';
import 'sync_progress_tracker.dart';
import 'entity_persistence_service.dart';
import 'metadata_service.dart';
import 'pagination_helper.dart';

/// Service for performing full synchronization from Firefly III server.
///
/// This service handles:
/// - Fetching all data from server with pagination
/// - Clearing local database safely
/// - Inserting server data in batches
/// - Marking all entities as synced
/// - Updating sync metadata
///
/// Uses EntityPersistenceService for all entity operations.
///
/// Example:
/// ```dart
/// final fullSync = FullSyncService(
///   apiClient: fireflyClient,
///   database: appDatabase,
///   progressTracker: tracker,
/// );
///
/// await fullSync.performFullSync();
/// ```
class FullSyncService {
  final Logger _logger = Logger('FullSyncService');

  final FireflyApiClient _apiClient;
  final AppDatabase _database;
  final SyncProgressTracker _progressTracker;
  final EntityPersistenceService _persistence;
  final MetadataService _metadata;
  final PaginationHelper _pagination;

  /// Configuration
  final int batchSize;
  final int pageSize;
  final Duration timeout;
  final bool clearLocalData;

  FullSyncService({
    required FireflyApiClient apiClient,
    required AppDatabase database,
    required SyncProgressTracker progressTracker,
    EntityPersistenceService? persistence,
    MetadataService? metadata,
    PaginationHelper? pagination,
    this.batchSize = 100,
    this.pageSize = 50,
    this.timeout = const Duration(minutes: 30),
    this.clearLocalData = true,
  })  : _apiClient = apiClient,
        _database = database,
        _progressTracker = progressTracker,
        _persistence = persistence ?? EntityPersistenceService(database),
        _metadata = metadata ?? MetadataService(database),
        _pagination = pagination ?? PaginationHelper();

  /// Perform full synchronization from server.
  ///
  /// This will:
  /// 1. Fetch all data from server (transactions, accounts, categories, etc.)
  /// 2. Clear local database (if clearLocalData is true)
  /// 3. Insert server data in batches
  /// 4. Mark all as synced with server IDs
  /// 5. Update last_full_sync timestamp
  ///
  /// Returns:
  ///   SyncResult with statistics
  ///
  /// Throws:
  ///   NetworkError: If network connectivity fails
  ///   ServerError: If server returns error
  ///   TimeoutError: If operation exceeds timeout
  ///   ConsistencyError: If data validation fails
  Future<SyncResult> performFullSync() async {
    final startTime = DateTime.now();

    try {
      _logger.info('Starting full synchronization from server');

      _progressTracker.start(
        totalOperations: 1,
        phase: SyncPhase.pulling,
      );

      // Fetch all entity types
      final entities = await _fetchAllEntities();

      _logger.info(
        'Fetched ${entities['transactions']?.length ?? 0} transactions, '
        '${entities['accounts']?.length ?? 0} accounts, '
        '${entities['categories']?.length ?? 0} categories, '
        '${entities['budgets']?.length ?? 0} budgets, '
        '${entities['bills']?.length ?? 0} bills, '
        '${entities['piggy_banks']?.length ?? 0} piggy banks',
      );

      // Clear local database if configured
      if (clearLocalData) {
        _progressTracker.updatePhase(SyncPhase.preparing);
        await _clearLocalDatabase();
      }

      // Insert server data
      _progressTracker.updatePhase(SyncPhase.syncing);
      await _insertServerData(entities);

      // Update metadata
      _progressTracker.updatePhase(SyncPhase.finalizing);
      await _updateSyncMetadata();

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      _logger.info(
        'Full synchronization completed successfully in ${duration.inSeconds}s',
      );

      final result = SyncResult(
        success: true,
        totalOperations: _calculateTotalEntities(entities),
        completedOperations: _calculateTotalEntities(entities),
        failedOperations: 0,
        skippedOperations: 0,
        conflictsDetected: 0,
        conflictsResolved: 0,
        duration: duration,
        startTime: startTime,
        endTime: endTime,
        errors: const [],
        successRate: 1.0,
        throughput: _calculateTotalEntities(entities) / duration.inSeconds,
        entityStats: _buildEntityStats(entities),
      );

      _progressTracker.complete(success: true);

      return result;
    } catch (e, stackTrace) {
      _logger.severe(
        'Full synchronization failed',
        e,
        stackTrace,
      );

      _progressTracker.complete(success: false);

      rethrow;
    }
  }

  /// Fetch all entities from server with pagination.
  Future<Map<String, List<Map<String, dynamic>>>> _fetchAllEntities() async {
    try {
      final entities = <String, List<Map<String, dynamic>>>{};

      // Fetch transactions
      _logger.info('Fetching transactions from server');
      entities['transactions'] = await _fetchPaginated(
        endpoint: '/api/v1/transactions',
        entityType: 'transactions',
      );

      // Fetch accounts
      _logger.info('Fetching accounts from server');
      entities['accounts'] = await _fetchPaginated(
        endpoint: '/api/v1/accounts',
        entityType: 'accounts',
      );

      // Fetch categories
      _logger.info('Fetching categories from server');
      entities['categories'] = await _fetchPaginated(
        endpoint: '/api/v1/categories',
        entityType: 'categories',
      );

      // Fetch budgets
      _logger.info('Fetching budgets from server');
      entities['budgets'] = await _fetchPaginated(
        endpoint: '/api/v1/budgets',
        entityType: 'budgets',
      );

      // Fetch bills
      _logger.info('Fetching bills from server');
      entities['bills'] = await _fetchPaginated(
        endpoint: '/api/v1/bills',
        entityType: 'bills',
      );

      // Fetch piggy banks
      _logger.info('Fetching piggy banks from server');
      entities['piggy_banks'] = await _fetchPaginated(
        endpoint: '/api/v1/piggy_banks',
        entityType: 'piggy_banks',
      );

      return entities;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to fetch entities from server',
        e,
        stackTrace,
      );

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          throw TimeoutError(
            'Request timed out while fetching entities',
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

  /// Fetch entities with pagination support.
  Future<List<Map<String, dynamic>>> _fetchPaginated({
    required String endpoint,
    required String entityType,
  }) async {
    final allEntities = <Map<String, dynamic>>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      try {
        _logger.fine('Fetching $entityType page $page');

        final response = await _apiClient.get(
          endpoint,
          queryParameters: {
            'page': page,
            'limit': pageSize,
          },
        );

        final data = response.data as Map<String, dynamic>;
        final entities = (data['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

        allEntities.addAll(entities);

        // Check pagination metadata
        final paginationInfo = _pagination.parsePagination(data);
        hasMore = paginationInfo.hasMore;

        _pagination.logProgress(
          paginationInfo,
          entityType,
          entities.length,
          allEntities.length,
        );

        page++;

        // Add small delay to avoid rate limiting
        await _pagination.applyRateLimit(hasMore);
      } catch (e, stackTrace) {
        _logger.severe(
          'Failed to fetch $entityType page $page',
          e,
          stackTrace,
        );
        rethrow;
      }
    }

    _logger.info('Fetched ${allEntities.length} $entityType from server');

    return allEntities;
  }

  /// Clear local database safely.
  Future<void> _clearLocalDatabase() async {
    try {
      _logger.info('Clearing local database');

      await _database.transaction(() async {
        // Clear in reverse dependency order to avoid foreign key violations
        await _database.delete(_database.transactions).go();
        await _database.delete(_database.piggyBanks).go();
        await _database.delete(_database.bills).go();
        await _database.delete(_database.budgets).go();
        await _database.delete(_database.categories).go();
        await _database.delete(_database.accounts).go();

        // Clear sync queue
        await _database.delete(_database.syncQueue).go();

        // Clear conflicts
        await _database.delete(_database.conflicts).go();

        _logger.info('Local database cleared successfully');
      });
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to clear local database',
        e,
        stackTrace,
      );

      throw ConsistencyError(
        'Failed to clear local database: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Insert server data into local database in batches.
  Future<void> _insertServerData(
    Map<String, List<Map<String, dynamic>>> entities,
  ) async {
    try {
      _logger.info('Inserting server data into local database');

      // Insert in dependency order
      await _insertEntitiesInBatches('accounts', entities['accounts'] ?? []);
      await _insertEntitiesInBatches('categories', entities['categories'] ?? []);
      await _insertEntitiesInBatches('budgets', entities['budgets'] ?? []);
      await _insertEntitiesInBatches('bills', entities['bills'] ?? []);
      await _insertEntitiesInBatches('piggy_banks', entities['piggy_banks'] ?? []);
      await _insertEntitiesInBatches('transactions', entities['transactions'] ?? []);

      _logger.info('Server data inserted successfully');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to insert server data',
        e,
        stackTrace,
      );

      throw ConsistencyError(
        'Failed to insert server data: $e',
        details: {'error': e.toString()},
      );
    }
  }

  /// Insert entities in batches for better performance.
  Future<void> _insertEntitiesInBatches(
    String entityType,
    List<Map<String, dynamic>> entities,
  ) async {
    if (entities.isEmpty) {
      _logger.fine('No $entityType to insert');
      return;
    }

    _logger.info('Inserting ${entities.length} $entityType in batches of $batchSize');

    for (int i = 0; i < entities.length; i += batchSize) {
      final batch = entities.skip(i).take(batchSize).toList();

      await _database.transaction(() async {
        for (final entity in batch) {
          await _persistence.insertEntity(entityType, entity);
        }
      });

      _logger.fine(
        'Inserted batch ${(i / batchSize).floor() + 1}/${(entities.length / batchSize).ceil()} '
        'of $entityType',
      );
    }

    _logger.info('Inserted ${entities.length} $entityType successfully');
  }

  /// Update sync metadata after successful full sync.
  Future<void> _updateSyncMetadata() async {
    try {
      final now = DateTime.now().toIso8601String();

      await _metadata.setMany({
        MetadataKeys.lastFullSync: now,
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

  /// Parse datetime from various formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        _logger.warning('Failed to parse datetime: $value');
        return null;
      }
    }
    return null;
  }

  /// Calculate total number of entities.
  int _calculateTotalEntities(Map<String, List<Map<String, dynamic>>> entities) {
    return entities.values.fold(0, (sum, list) => sum + list.length);
  }

  /// Build entity statistics.
  Map<String, EntitySyncStats> _buildEntityStats(
    Map<String, List<Map<String, dynamic>>> entities,
  ) {
    return entities.map((type, list) {
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
}
