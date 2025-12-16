import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';

/// Base repository interface for data access operations with cache-first architecture.
///
/// This abstract base class provides a consistent API for accessing data with
/// integrated cache support. All repositories should extend this class to benefit
/// from the cache-first pattern with stale-while-revalidate strategy.
///
/// **Cache-First Architecture**:
/// 1. Check cache for fresh data → return immediately (cache hit)
/// 2. Check cache for stale data → return stale, refresh in background
/// 3. No cache → fetch from database/API, cache result, return
///
/// **Key Features**:
/// - **Stale-While-Revalidate**: Returns stale data instantly while refreshing
/// - **TTL-Based Expiration**: Configurable cache lifetime per entity type
/// - **Smart Invalidation**: Cascading cache invalidation for related entities
/// - **Thread Safety**: All cache operations use synchronized locks
/// - **Background Refresh**: Non-blocking refresh for improved UX
/// - **Optional Cache**: CacheService is optional for backward compatibility
///
/// Type parameter [T] represents the entity type (e.g., TransactionEntity, AccountEntity).
/// Type parameter [ID] represents the identifier type (typically String).
///
/// Example:
/// ```dart
/// class TransactionRepository extends BaseRepository<TransactionEntity, String> {
///   TransactionRepository({
///     required AppDatabase database,
///     CacheService? cacheService,
///   }) : super(database: database, cacheService: cacheService);
///
///   @override
///   String get entityType => 'transaction';
///
///   @override
///   Duration get cacheTtl => CacheTtlConfig.transactions;
///
///   @override
///   Duration get collectionCacheTtl => CacheTtlConfig.transactionsList;
///
///   @override
///   Future<TransactionEntity?> getById(String id) async {
///     // Implementation with cache integration
///   }
/// }
/// ```
///
/// See also:
/// - [CacheService] for cache management
/// - [CacheTtlConfig] for TTL configuration
/// - [CacheInvalidationRules] for invalidation strategies
abstract class BaseRepository<T, ID> {
  /// Creates a base repository with database and optional cache service.
  ///
  /// Parameters:
  /// - [database]: Drift database instance for local storage
  /// - [cacheService]: Optional cache service for metadata-based caching
  ///
  /// The cache service is optional to maintain backward compatibility with
  /// repositories that haven't been migrated to the cache-first pattern yet.
  BaseRepository({
    required AppDatabase database,
    CacheService? cacheService,
  })  : _database = database,
        _cacheService = cacheService;

  /// Drift database instance for local storage operations
  final AppDatabase _database;

  /// Optional cache service for metadata-based caching
  ///
  /// If null, repository operates without cache (direct database access).
  /// If provided, repository uses cache-first strategy with stale-while-revalidate.
  final CacheService? _cacheService;

  /// Logger instance for the repository.
  ///
  /// Each repository should override this with their own logger name.
  Logger get logger;

  /// Protected getter for database access
  ///
  /// Allows subclasses to access database for complex queries.
  AppDatabase get database => _database;

  /// Protected getter for cache service access
  ///
  /// Allows subclasses to check cache availability and perform cache operations.
  CacheService? get cacheService => _cacheService;

  // ========================================================================
  // CACHE CONFIGURATION (Abstract Getters)
  // ========================================================================

  /// Entity type identifier for cache keys
  ///
  /// Used to namespace cache entries and organize invalidation.
  /// Examples: 'transaction', 'account', 'budget', 'category'
  ///
  /// Must be overridden by subclass:
  /// ```dart
  /// @override
  /// String get entityType => 'transaction';
  /// ```
  String get entityType;

  /// Cache time-to-live for individual entities
  ///
  /// Defines how long a cached entity is considered fresh.
  /// After TTL expires, data is stale and triggers background refresh.
  ///
  /// Must be overridden by subclass:
  /// ```dart
  /// @override
  /// Duration get cacheTtl => CacheTtlConfig.transactions; // 5 minutes
  /// ```
  Duration get cacheTtl;

  /// Cache time-to-live for entity collections (lists)
  ///
  /// Typically shorter than individual entity TTL since lists change more frequently.
  ///
  /// Must be overridden by subclass:
  /// ```dart
  /// @override
  /// Duration get collectionCacheTtl => CacheTtlConfig.transactionsList; // 3 minutes
  /// ```
  Duration get collectionCacheTtl;

  // ========================================================================
  // CRUD OPERATIONS (Abstract Methods)
  // ========================================================================

  /// Retrieves all entities.
  ///
  /// Returns a list of all entities. In offline mode, returns locally stored
  /// entities. In online mode, fetches from the server and updates local cache.
  ///
  /// **Implementation should use cache-first strategy**:
  /// ```dart
  /// @override
  /// Future<List<T>> getAll() async {
  ///   if (cacheService != null) {
  ///     final cacheKey = generateCollectionCacheKey(filters: {});
  ///     final result = await cacheService!.get<List<T>>(
  ///       entityType: '${entityType}_list',
  ///       entityId: cacheKey,
  ///       fetcher: () => _fetchAllFromDb(),
  ///       ttl: collectionCacheTtl,
  ///     );
  ///     return result.data ?? [];
  ///   }
  ///   return _fetchAllFromDb();
  /// }
  /// ```
  ///
  /// Throws [DatabaseException] if local database access fails.
  /// Throws [ConnectivityException] if online mode and server is unreachable.
  Future<List<T>> getAll();

  /// Retrieves a stream of all entities.
  ///
  /// Returns a stream that emits the current list of entities and updates
  /// whenever the data changes. Useful for reactive UI updates.
  Stream<List<T>> watchAll();

  /// Retrieves an entity by its ID with cache-first strategy.
  ///
  /// **Parameters**:
  /// - [id]: Entity ID to retrieve
  /// - [forceRefresh]: If true, bypass cache and fetch fresh data (default: false)
  /// - [backgroundRefresh]: If true and data is stale, refresh in background (default: true)
  ///
  /// **Returns**: Entity if found, null otherwise.
  ///
  /// **Implementation should use cache-first strategy**:
  /// ```dart
  /// @override
  /// Future<T?> getById(
  ///   ID id, {
  ///   bool forceRefresh = false,
  ///   bool backgroundRefresh = true,
  /// }) async {
  ///   if (cacheService != null) {
  ///     final result = await cacheService!.get<T>(
  ///       entityType: entityType,
  ///       entityId: id.toString(),
  ///       fetcher: () => _fetchFromDb(id),
  ///       ttl: cacheTtl,
  ///       forceRefresh: forceRefresh,
  ///       backgroundRefresh: backgroundRefresh,
  ///     );
  ///     return result.data;
  ///   }
  ///   return _fetchFromDb(id);
  /// }
  /// ```
  ///
  /// Throws [DatabaseException] if local database access fails.
  /// Throws [ConnectivityException] if online mode and server is unreachable.
  Future<T?> getById(
    ID id, {
    bool forceRefresh = false,
    bool backgroundRefresh = true,
  });

  /// Retrieves a stream of an entity by its ID.
  ///
  /// Returns a stream that emits the entity and updates whenever it changes.
  Stream<T?> watchById(ID id);

  /// Creates a new entity with cache integration.
  ///
  /// In offline mode, stores the entity locally and adds to sync queue.
  /// In online mode, creates on the server and updates local cache.
  ///
  /// **Implementation should invalidate related caches**:
  /// ```dart
  /// @override
  /// Future<T> create(T entity) async {
  ///   // Validate
  ///   await validator.validate(entity);
  ///
  ///   // Store in database
  ///   final created = await _storeInDb(entity);
  ///
  ///   // Cache the created entity
  ///   if (cacheService != null) {
  ///     await cacheService!.set(
  ///       entityType: entityType,
  ///       entityId: created.id,
  ///       data: created,
  ///       ttl: cacheTtl,
  ///     );
  ///
  ///     // Trigger cascade invalidation
  ///     await CacheInvalidationRules.onTransactionMutation(
  ///       cacheService: cacheService!,
  ///       transaction: created,
  ///       mutationType: MutationType.create,
  ///     );
  ///   }
  ///
  ///   return created;
  /// }
  /// ```
  ///
  /// Returns the created entity with its assigned ID.
  ///
  /// Throws [ValidationException] if entity data is invalid.
  /// Throws [DatabaseException] if local storage fails.
  /// Throws [SyncException] if online mode and server creation fails.
  Future<T> create(T entity);

  /// Updates an existing entity with cache integration.
  ///
  /// In offline mode, updates locally and adds to sync queue.
  /// In online mode, updates on the server and updates local cache.
  ///
  /// **Implementation should update cache and invalidate related caches**:
  /// ```dart
  /// @override
  /// Future<T> update(ID id, T entity) async {
  ///   // Validate
  ///   await validator.validate(entity);
  ///
  ///   // Update in database
  ///   final updated = await _updateInDb(id, entity);
  ///
  ///   // Update cache
  ///   if (cacheService != null) {
  ///     await cacheService!.set(
  ///       entityType: entityType,
  ///       entityId: id.toString(),
  ///       data: updated,
  ///       ttl: cacheTtl,
  ///     );
  ///
  ///     // Trigger cascade invalidation
  ///     await CacheInvalidationRules.onTransactionMutation(
  ///       cacheService: cacheService!,
  ///       transaction: updated,
  ///       mutationType: MutationType.update,
  ///     );
  ///   }
  ///
  ///   return updated;
  /// }
  /// ```
  ///
  /// Returns the updated entity.
  ///
  /// Throws [ValidationException] if entity data is invalid.
  /// Throws [DatabaseException] if local storage fails.
  /// Throws [SyncException] if online mode and server update fails.
  Future<T> update(ID id, T entity);

  /// Deletes an entity by its ID with cache integration.
  ///
  /// In offline mode, marks as deleted locally and adds to sync queue.
  /// In online mode, deletes from the server and removes from local cache.
  ///
  /// **Implementation should invalidate cache and related caches**:
  /// ```dart
  /// @override
  /// Future<void> delete(ID id) async {
  ///   // Delete from database
  ///   await _deleteFromDb(id);
  ///
  ///   // Invalidate cache
  ///   if (cacheService != null) {
  ///     await cacheService!.invalidate(
  ///       entityType: entityType,
  ///       entityId: id.toString(),
  ///     );
  ///
  ///     // Trigger cascade invalidation
  ///     await CacheInvalidationRules.onTransactionMutation(
  ///       cacheService: cacheService!,
  ///       transactionId: id.toString(),
  ///       mutationType: MutationType.delete,
  ///     );
  ///   }
  /// }
  /// ```
  ///
  /// Throws [DatabaseException] if local storage fails.
  /// Throws [SyncException] if online mode and server deletion fails.
  Future<void> delete(ID id);

  /// Retrieves all entities that haven't been synced with the server.
  ///
  /// Returns a list of entities where [isSynced] is false.
  /// Used by the sync manager to determine what needs to be synchronized.
  Future<List<T>> getUnsynced();

  /// Marks an entity as synced with the server.
  ///
  /// Updates the entity's sync status and stores the server-assigned ID.
  /// Called by the sync manager after successful synchronization.
  ///
  /// [localId] - The local ID of the entity.
  /// [serverId] - The server-assigned ID.
  Future<void> markAsSynced(ID localId, String serverId);

  /// Gets the sync status of an entity.
  ///
  /// Returns the current sync status: 'pending', 'syncing', 'synced', or 'error'.
  Future<String> getSyncStatus(ID id);

  /// Clears all locally cached data.
  ///
  /// Removes all entities from local storage. Use with caution.
  /// Typically called when logging out or resetting the app.
  ///
  /// **Should also clear cache service entries**:
  /// ```dart
  /// @override
  /// Future<void> clearCache() async {
  ///   await _clearDbCache();
  ///   if (cacheService != null) {
  ///     await cacheService!.invalidateType(entityType);
  ///   }
  /// }
  /// ```
  Future<void> clearCache();

  /// Gets the count of entities.
  ///
  /// Returns the total number of entities stored locally.
  Future<int> count();

  // ========================================================================
  // CACHE HELPER METHODS (Protected)
  // ========================================================================

  /// Generate consistent cache key for collection queries
  ///
  /// Creates deterministic cache keys for collection queries with filters.
  /// Uses SHA-256 hash of sorted parameters to ensure:
  /// - Identical queries hit same cache (regardless of param order)
  /// - Different queries get different cache entries
  ///
  /// Parameters:
  /// - [filters]: Map of query parameters (nullable, empty = 'collection_all')
  ///
  /// Returns:
  /// Cache key string, format: 'collection_{hash}' or 'collection_all'
  ///
  /// Example:
  /// ```dart
  /// final key1 = generateCollectionCacheKey(filters: {
  ///   'start': '2024-01-01',
  ///   'end': '2024-01-31',
  ///   'account': '123',
  /// });
  /// // Returns: 'collection_abc123def456'
  ///
  /// final key2 = generateCollectionCacheKey(filters: {
  ///   'account': '123', // Different order
  ///   'end': '2024-01-31',
  ///   'start': '2024-01-01',
  /// });
  /// // Returns: 'collection_abc123def456' (same hash!)
  /// ```
  ///
  /// Implementation:
  /// 1. Handle null/empty filters → return 'collection_all'
  /// 2. Sort parameters alphabetically by key
  /// 3. Create canonical string representation
  /// 4. Generate SHA-256 hash
  /// 5. Return 'collection_{hash}'
  String generateCollectionCacheKey({Map<String, dynamic>? filters}) {
    // No filters = all entities
    if (filters == null || filters.isEmpty) {
      return 'collection_all';
    }

    // Sort keys alphabetically for consistent hashing
    final List<String> sortedKeys = filters.keys.toList()..sort();

    // Build canonical string representation
    final StringBuffer buffer = StringBuffer();
    for (final String key in sortedKeys) {
      final value = filters[key];
      buffer.write('$key=$value;');
    }

    // Generate SHA-256 hash
    final Uint8List bytes = utf8.encode(buffer.toString());
    final Digest digest = sha256.convert(bytes);
    final String hash = digest.toString().substring(0, 16); // First 16 chars

    return 'collection_$hash';
  }

  /// Check if cache service is available
  ///
  /// Returns true if cache service is configured and available.
  /// Use this before attempting cache operations.
  ///
  /// Example:
  /// ```dart
  /// if (isCacheAvailable) {
  ///   final result = await cacheService!.get(...);
  /// } else {
  ///   final result = await _fetchDirectly();
  /// }
  /// ```
  bool get isCacheAvailable => _cacheService != null;

  /// Log cache hit for debugging
  ///
  /// Helper method for consistent cache hit logging.
  void logCacheHit(String operation, ID id, {bool isFresh = true}) {
    logger.fine(
      'Cache ${isFresh ? "hit (fresh)" : "hit (stale)"}: '
      '$entityType:$id [$operation]',
    );
  }

  /// Log cache miss for debugging
  ///
  /// Helper method for consistent cache miss logging.
  void logCacheMiss(String operation, ID id) {
    logger.fine('Cache miss: $entityType:$id [$operation]');
  }

  /// Log cache invalidation for debugging
  ///
  /// Helper method for consistent cache invalidation logging.
  void logCacheInvalidation(String operation, ID id) {
    logger.info('Cache invalidated: $entityType:$id [$operation]');
  }
}
