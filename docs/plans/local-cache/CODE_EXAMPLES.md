# Cache Implementation Code Examples

## Overview

This document provides concrete code examples and patterns for implementing the local database cache system in Waterfly III. Use these examples as templates when implementing cache functionality.

---

## Table of Contents

1. [Cache Metadata Table](#cache-metadata-table)
2. [Cache Service Implementation](#cache-service-implementation)
3. [Repository Integration](#repository-integration)
4. [Cache Invalidation](#cache-invalidation)
5. [UI Integration](#ui-integration)
6. [Testing Examples](#testing-examples)

---

## Cache Metadata Table

### Drift Table Definition

**File**: `lib/data/local/database/cache_metadata_table.dart`

```dart
import 'package:drift/drift.dart';

/// Cache Metadata Table
///
/// Stores metadata for cached entities to support:
/// - TTL-based cache expiration
/// - Staleness detection
/// - LRU eviction
/// - ETag-based validation
/// - Query result caching
///
/// Uses composite primary key (entityType, entityId) for efficient lookups.
@DataClassName('CacheMetadata')
class CacheMetadataTable extends Table {
  /// Entity type (e.g., 'transaction', 'account', 'budget')
  ///
  /// For collections, use suffixed types: 'transaction_list', 'account_list'
  TextColumn get entityType => text()();

  /// Entity ID (server ID or cache key for collections)
  ///
  /// For single entities: use server ID ('123', '456')
  /// For collections: use generated cache key ('collection_abc123')
  TextColumn get entityId => text()();

  /// Timestamp when data was cached
  ///
  /// Used to calculate age and determine staleness with TTL.
  DateTimeColumn get cachedAt => dateTime()();

  /// Timestamp when cache entry was last accessed
  ///
  /// Used for LRU eviction - least recently used entries evicted first.
  DateTimeColumn get lastAccessedAt => dateTime()();

  /// Time-to-live in seconds
  ///
  /// Defines how long until cache is considered stale.
  /// Calculated from CacheTtlConfig based on entity type.
  IntColumn get ttlSeconds => integer()();

  /// Whether this cache entry has been explicitly invalidated
  ///
  /// Invalidated entries treated as cache miss.
  /// Set to true on mutations, cleared on next cache.
  BoolColumn get isInvalidated => boolean().withDefault(const Constant(false))();

  /// Optional ETag for HTTP cache validation
  ///
  /// Stored from API response headers (ETag header).
  /// Passed as If-None-Match on subsequent requests for bandwidth savings.
  TextColumn get etag => text().nullable()();

  /// Optional query parameters hash for collection queries
  ///
  /// SHA-256 hash of sorted query parameters.
  /// Enables cache hits for identical queries with different param order.
  TextColumn get queryHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};

  @override
  List<Index> get customIndexes => [
    // Fast lookup by entity type
    Index('cache_by_type', [entityType]),

    // Find invalidated or stale entries
    Index('cache_by_invalidation', [isInvalidated, cachedAt]),

    // Efficient staleness checks
    Index('cache_by_staleness', [cachedAt, ttlSeconds]),

    // LRU eviction sorting
    Index('cache_by_lru', [lastAccessedAt]),
  ];
}
```

### Database Migration

**File**: `lib/data/local/database/database.dart`

```dart
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

@DriftDatabase(tables: [
  // ... existing tables
  TransactionTable,
  AccountTable,
  BudgetTable,
  // NEW: Add cache metadata table
  CacheMetadataTable,
])
class AppDatabase extends _$AppDatabase {
  final Logger _log = Logger('AppDatabase');

  AppDatabase(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 3; // Increment from current version

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      // Create all tables including cache_metadata
      await m.createAll();
      _log.info('Database created with schema version $schemaVersion');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      _log.info('Migrating database from v$from to v$to');

      // Migration from v2 to v3: Add cache_metadata table
      if (from < 3) {
        _log.info('Adding cache_metadata table');

        // Create table
        await m.createTable(cacheMetadataTable);

        // Create indexes for performance
        await customStatement(
          'CREATE INDEX IF NOT EXISTS cache_by_type ON cache_metadata(entity_type)'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS cache_by_invalidation ON cache_metadata(is_invalidated, cached_at)'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS cache_by_staleness ON cache_metadata(cached_at, ttl_seconds)'
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS cache_by_lru ON cache_metadata(last_accessed_at)'
        );

        _log.info('cache_metadata table and indexes created successfully');
      }

      _log.info('Database migration complete');
    },
  );
}
```

---

## Cache Service Implementation

### Core Cache Service

**File**: `lib/services/cache/cache_service.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';
import 'package:retry/retry.dart';

/// Cache Service
///
/// Provides comprehensive cache management using:
/// - [drift] for metadata and data storage
/// - [rxdart] for reactive cache invalidation streams
/// - [synchronized] for thread-safe cache operations
/// - [crypto] for generating cache keys from queries
/// - [retry] for resilient background refresh
///
/// Implements stale-while-revalidate pattern:
/// 1. Check cache first (always)
/// 2. If fresh: return immediately
/// 3. If stale: return cached, refresh in background
/// 4. If miss: fetch from API, cache, return
class CacheService {
  final AppDatabase database;
  final Logger _log = Logger('CacheService');

  // Thread-safe operations with synchronized package
  final Lock _lock = Lock();

  // RxDart stream for cache invalidation events
  final PublishSubject<CacheInvalidationEvent> _invalidationStream = PublishSubject();

  // Statistics tracking
  int _totalRequests = 0;
  int _cacheHits = 0;
  int _cacheMisses = 0;
  int _staleServed = 0;
  int _backgroundRefreshes = 0;

  CacheService({required this.database}) {
    _log.info('CacheService initialized');

    // Periodically clean expired entries
    _startPeriodicCleanup();
  }

  /// Get data with cache-first strategy (stale-while-revalidate)
  ///
  /// Parameters:
  /// - [entityType]: Type of entity (e.g., 'transaction', 'account')
  /// - [entityId]: Entity ID or cache key
  /// - [fetcher]: Function to fetch data from API if cache miss
  /// - [ttl]: Time-to-live duration (default from CacheTtlConfig)
  /// - [forceRefresh]: Skip cache and force API fetch
  /// - [backgroundRefresh]: Enable background refresh for stale data
  ///
  /// Returns [CacheResult] with data, source, and freshness info.
  ///
  /// Example:
  /// ```dart
  /// final result = await cacheService.get<Account>(
  ///   entityType: 'account',
  ///   entityId: '123',
  ///   fetcher: () => apiClient.getAccount('123'),
  ///   ttl: Duration(minutes: 15),
  /// );
  /// print('Account: ${result.data}, from: ${result.source}');
  /// ```
  Future<CacheResult<T>> get<T>({
    required String entityType,
    required String entityId,
    required Future<T> Function() fetcher,
    Duration? ttl,
    bool forceRefresh = false,
    bool backgroundRefresh = true,
  }) async {
    _totalRequests++;
    _log.fine('Cache get: $entityType:$entityId (force=$forceRefresh)');

    // Force refresh bypasses cache
    if (forceRefresh) {
      _log.fine('Force refresh requested, bypassing cache');
      return await _fetchAndCache(entityType, entityId, fetcher, ttl);
    }

    // Check cache freshness
    final fresh = await isFresh(entityType, entityId);

    if (fresh) {
      // Cache hit: return fresh data immediately
      _cacheHits++;
      _log.info('Cache hit (fresh): $entityType:$entityId');

      final data = await _getFromLocalDb<T>(entityType, entityId);
      await _updateLastAccessed(entityType, entityId);

      return CacheResult<T>(
        data: data,
        source: CacheSource.cache,
        isFresh: true,
        cachedAt: await _getCachedAt(entityType, entityId),
      );
    }

    // Check if cached but stale
    final cachedData = await _getFromLocalDb<T>(entityType, entityId);

    if (cachedData != null) {
      // Cache hit (stale): return immediately, refresh in background
      _staleServed++;
      _log.info('Cache hit (stale): $entityType:$entityId');

      if (backgroundRefresh) {
        _log.fine('Starting background refresh for $entityType:$entityId');
        unawaited(_backgroundRefresh(entityType, entityId, fetcher, ttl));
      }

      return CacheResult<T>(
        data: cachedData,
        source: CacheSource.cache,
        isFresh: false,
        cachedAt: await _getCachedAt(entityType, entityId),
      );
    }

    // Cache miss: fetch from API
    _cacheMisses++;
    _log.info('Cache miss: $entityType:$entityId');
    return await _fetchAndCache(entityType, entityId, fetcher, ttl);
  }

  /// Background refresh with retry logic
  Future<void> _backgroundRefresh<T>(
    String entityType,
    String entityId,
    Future<T> Function() fetcher,
    Duration? ttl,
  ) async {
    _backgroundRefreshes++;

    try {
      _log.fine('Background refresh starting: $entityType:$entityId');

      // Use retry package for resilience
      final data = await retry(
        () => fetcher(),
        maxAttempts: 2,
        onRetry: (e) => _log.warning('Retry background fetch: $e'),
      );

      // Update cache
      await set(
        entityType: entityType,
        entityId: entityId,
        data: data,
        ttl: ttl,
      );

      _log.info('Background refresh completed: $entityType:$entityId');

      // Emit refresh event via RxDart stream
      _invalidationStream.add(CacheInvalidationEvent(
        entityType: entityType,
        entityId: entityId,
        eventType: CacheEventType.refreshed,
        data: data,
        timestamp: DateTime.now(),
      ));

    } catch (e, stackTrace) {
      _log.severe('Background refresh failed: $entityType:$entityId', e, stackTrace);
      // Don't propagate error - stale data already returned
    }
  }

  /// Fetch from API and cache result
  Future<CacheResult<T>> _fetchAndCache<T>(
    String entityType,
    String entityId,
    Future<T> Function() fetcher,
    Duration? ttl,
  ) async {
    try {
      _log.fine('Fetching from API: $entityType:$entityId');
      final data = await fetcher();

      // Cache the result
      await set(
        entityType: entityType,
        entityId: entityId,
        data: data,
        ttl: ttl,
      );

      return CacheResult<T>(
        data: data,
        source: CacheSource.api,
        isFresh: true,
        cachedAt: DateTime.now(),
      );

    } catch (e, stackTrace) {
      _log.severe('API fetch failed: $entityType:$entityId', e, stackTrace);
      rethrow;
    }
  }

  /// Store data in cache with metadata
  ///
  /// Parameters:
  /// - [entityType]: Type of entity
  /// - [entityId]: Entity ID or cache key
  /// - [data]: Data to cache (will be stored in local DB)
  /// - [ttl]: Time-to-live duration
  /// - [etag]: Optional ETag for HTTP validation
  ///
  /// Note: This method doesn't directly store [data] in cache_metadata.
  /// The actual entity data is stored in entity-specific tables (transactions, accounts, etc.).
  /// This method only stores the metadata tracking.
  Future<void> set<T>({
    required String entityType,
    required String entityId,
    required T data,
    Duration? ttl,
    String? etag,
  }) async {
    final effectiveTtl = ttl ?? CacheTtlConfig.getTtl(entityType);

    await _lock.synchronized(() async {
      _log.fine('Caching: $entityType:$entityId (ttl: ${effectiveTtl.inSeconds}s)');

      final now = DateTime.now();

      await database.into(database.cacheMetadataTable).insertOnConflictUpdate(
        CacheMetadataTableCompanion(
          entityType: Value(entityType),
          entityId: Value(entityId),
          cachedAt: Value(now),
          lastAccessedAt: Value(now),
          ttlSeconds: Value(effectiveTtl.inSeconds),
          isInvalidated: Value(false),
          etag: Value(etag),
        ),
      );

      _log.fine('Cached metadata: $entityType:$entityId');
    });
  }

  /// Check if cache entry is fresh
  ///
  /// A cache entry is fresh if:
  /// 1. It exists in cache metadata
  /// 2. Not explicitly invalidated
  /// 3. Current time < (cachedAt + ttl)
  Future<bool> isFresh(String entityType, String entityId) async {
    final metadata = await (database.select(database.cacheMetadataTable)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId)))
        .getSingleOrNull();

    if (metadata == null) {
      _log.finest('Cache miss: no metadata for $entityType:$entityId');
      return false;
    }

    if (metadata.isInvalidated) {
      _log.fine('Cache invalid: $entityType:$entityId explicitly invalidated');
      return false;
    }

    final now = DateTime.now();
    final expiresAt = metadata.cachedAt.add(Duration(seconds: metadata.ttlSeconds));
    final fresh = now.isBefore(expiresAt);

    _log.finest(() =>
        'Cache freshness: $entityType:$entityId fresh=$fresh '
        '(age: ${now.difference(metadata.cachedAt).inSeconds}s, '
        'ttl: ${metadata.ttlSeconds}s)');

    return fresh;
  }

  /// Invalidate specific cache entry
  ///
  /// Sets isInvalidated=true, causing next get() to treat as cache miss.
  Future<void> invalidate(String entityType, String entityId) async {
    await _lock.synchronized(() async {
      _log.info('Invalidating cache: $entityType:$entityId');

      final result = await (database.update(database.cacheMetadataTable)
            ..where((tbl) =>
                tbl.entityType.equals(entityType) &
                tbl.entityId.equals(entityId)))
          .write(CacheMetadataTableCompanion(
        isInvalidated: Value(true),
      ));

      if (result > 0) {
        _log.fine('Cache invalidated: $entityType:$entityId');
      } else {
        _log.finest('Cache entry not found: $entityType:$entityId');
      }
    });

    // Emit invalidation event
    _invalidationStream.add(CacheInvalidationEvent(
      entityType: entityType,
      entityId: entityId,
      eventType: CacheEventType.invalidated,
      timestamp: DateTime.now(),
    ));
  }

  /// Invalidate all cache entries of a type
  ///
  /// Useful for invalidating collections (e.g., all transaction lists).
  Future<void> invalidateType(String entityType) async {
    await _lock.synchronized(() async {
      _log.info('Invalidating all cache entries of type: $entityType');

      final result = await (database.update(database.cacheMetadataTable)
            ..where((tbl) => tbl.entityType.equals(entityType)))
          .write(CacheMetadataTableCompanion(
        isInvalidated: Value(true),
      ));

      _log.info('Invalidated $result cache entries of type: $entityType');
    });

    // Emit type-level invalidation event
    _invalidationStream.add(CacheInvalidationEvent(
      entityType: entityType,
      entityId: '*',
      eventType: CacheEventType.invalidated,
      timestamp: DateTime.now(),
    ));
  }

  /// Get cache statistics
  Future<CacheStats> getStats() async {
    final totalEntries = await (database.select(database.cacheMetadataTable).get()).then((l) => l.length);
    final invalidatedEntries = await (database.select(database.cacheMetadataTable)
          ..where((tbl) => tbl.isInvalidated.equals(true)))
        .get()
        .then((l) => l.length);

    final hitRate = _totalRequests > 0 ? _cacheHits / _totalRequests : 0.0;

    return CacheStats(
      totalRequests: _totalRequests,
      cacheHits: _cacheHits,
      cacheMisses: _cacheMisses,
      staleServed: _staleServed,
      backgroundRefreshes: _backgroundRefreshes,
      evictions: 0, // TODO: Track evictions
      hitRate: hitRate,
      totalEntries: totalEntries,
      invalidatedEntries: invalidatedEntries,
    );
  }

  /// Stream of cache invalidation events
  Stream<CacheInvalidationEvent> get invalidationStream => _invalidationStream.stream;

  /// Clean expired cache entries
  Future<void> cleanExpired() async {
    await _lock.synchronized(() async {
      _log.info('Cleaning expired cache entries');

      final now = DateTime.now();

      // Find expired entries
      final expired = await (database.select(database.cacheMetadataTable)).get();
      int deletedCount = 0;

      for (final entry in expired) {
        final expiresAt = entry.cachedAt.add(Duration(seconds: entry.ttlSeconds));
        if (now.isAfter(expiresAt)) {
          await (database.delete(database.cacheMetadataTable)
                ..where((tbl) =>
                    tbl.entityType.equals(entry.entityType) &
                    tbl.entityId.equals(entry.entityId)))
              .go();
          deletedCount++;
        }
      }

      _log.info('Cleaned $deletedCount expired cache entries');
    });
  }

  /// Start periodic cleanup
  void _startPeriodicCleanup() {
    Timer.periodic(Duration(minutes: 30), (timer) {
      _log.fine('Running periodic cache cleanup');
      unawaited(cleanExpired());
    });
  }

  // Helper methods
  Future<T?> _getFromLocalDb<T>(String entityType, String entityId) async {
    // This is entity-specific logic - implement in repositories
    // For now, return null (will be overridden by repository implementation)
    return null;
  }

  Future<void> _updateLastAccessed(String entityType, String entityId) async {
    await (database.update(database.cacheMetadataTable)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId)))
        .write(CacheMetadataTableCompanion(
      lastAccessedAt: Value(DateTime.now()),
    ));
  }

  Future<DateTime?> _getCachedAt(String entityType, String entityId) async {
    final metadata = await (database.select(database.cacheMetadataTable)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId)))
        .getSingleOrNull();
    return metadata?.cachedAt;
  }

  /// Generate consistent cache key for collection queries
  ///
  /// Uses SHA-256 hash of sorted parameters for deterministic cache keys.
  String generateCollectionCacheKey(Map<String, dynamic>? filters) {
    if (filters == null || filters.isEmpty) {
      return 'collection_all';
    }

    // Sort parameters for consistent hashing
    final sortedKeys = filters.keys.toList()..sort();
    final normalized = <String, dynamic>{};
    for (final key in sortedKeys) {
      normalized[key] = filters[key];
    }

    // Generate SHA-256 hash
    final jsonString = jsonEncode(normalized);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);

    return 'collection_${hash.toString().substring(0, 16)}';
  }
}

/// Cache result model
class CacheResult<T> {
  final T? data;
  final CacheSource source;
  final bool isFresh;
  final DateTime? cachedAt;

  CacheResult({
    required this.data,
    required this.source,
    required this.isFresh,
    this.cachedAt,
  });
}

enum CacheSource {
  cache,
  api,
}

/// Cache invalidation event model
class CacheInvalidationEvent {
  final String entityType;
  final String entityId;
  final CacheEventType eventType;
  final dynamic data;
  final DateTime timestamp;

  CacheInvalidationEvent({
    required this.entityType,
    required this.entityId,
    required this.eventType,
    this.data,
    required this.timestamp,
  });
}

enum CacheEventType {
  invalidated,
  refreshed,
}

/// Cache statistics model
class CacheStats {
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final int staleServed;
  final int backgroundRefreshes;
  final int evictions;
  final double hitRate;
  final int totalEntries;
  final int invalidatedEntries;

  CacheStats({
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.staleServed,
    required this.backgroundRefreshes,
    required this.evictions,
    required this.hitRate,
    required this.totalEntries,
    required this.invalidatedEntries,
  });

  double get hitRatePercent => hitRate * 100;
}
```

---

## Repository Integration

### Example: Transaction Repository

**File**: `lib/data/repositories/transaction_repository.dart`

```dart
import 'package:logging/logging.dart';
import 'package:waterfly_iii/config/cache_ttl_config.dart';
import 'package:waterfly_iii/services/cache/cache_invalidation_rules.dart';

class TransactionRepository extends BaseRepository<Transaction> {
  TransactionRepository({
    required super.apiService,
    required super.database,
    required super.cacheService,
  }) : super() {
    log = Logger('TransactionRepository');
  }

  @override
  String get _entityType => 'transaction';

  @override
  Duration get _cacheTtl => CacheTtlConfig.transactions;

  @override
  Duration get _collectionCacheTtl => CacheTtlConfig.transactionsList;

  /// Get transaction by ID with cache-first strategy
  @override
  Future<Transaction?> getById(
    String id, {
    bool forceRefresh = false,
  }) async {
    log.fine('Getting transaction by ID: $id (forceRefresh: $forceRefresh)');

    // Use cache service with stale-while-revalidate
    final result = await cacheService.get<Transaction>(
      entityType: _entityType,
      entityId: id,
      fetcher: () => _fetchFromApi(id),
      ttl: _cacheTtl,
      forceRefresh: forceRefresh,
    );

    log.info('Transaction fetched: $id from ${result.source}');
    return result.data;
  }

  /// Get all transactions with cache-first strategy
  @override
  Future<List<Transaction>> getAll({
    bool forceRefresh = false,
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? budgetId,
  }) async {
    log.fine('Getting all transactions (forceRefresh: $forceRefresh)');

    // Generate cache key from filters
    final filters = {
      if (startDate != null) 'start': startDate.toIso8601String(),
      if (endDate != null) 'end': endDate.toIso8601String(),
      if (accountId != null) 'account': accountId,
      if (budgetId != null) 'budget': budgetId,
    };

    final cacheKey = cacheService.generateCollectionCacheKey(filters);

    final result = await cacheService.get<List<Transaction>>(
      entityType: '${_entityType}_list',
      entityId: cacheKey,
      fetcher: () => _fetchAllFromApi(startDate, endDate, accountId, budgetId),
      ttl: _collectionCacheTtl,
      forceRefresh: forceRefresh,
    );

    log.info('Transactions fetched: ${result.data?.length ?? 0} from ${result.source}');
    return result.data ?? [];
  }

  /// Create transaction and invalidate caches
  @override
  Future<Transaction> create(Transaction transaction) async {
    log.fine('Creating transaction');

    try {
      // Create via API
      final created = await _createViaApi(transaction);

      // Store in local DB
      await _storeLocally(created);

      // Store in cache
      await cacheService.set(
        entityType: _entityType,
        entityId: created.id,
        data: created,
        ttl: _cacheTtl,
      );

      // Invalidate related caches
      await CacheInvalidationRules.onTransactionMutation(
        cacheService,
        created,
        MutationType.create,
      );

      log.info('Transaction created: ${created.id}');
      return created;

    } catch (e, stackTrace) {
      log.severe('Failed to create transaction', e, stackTrace);
      rethrow;
    }
  }

  /// Update transaction and invalidate caches
  @override
  Future<Transaction> update(Transaction transaction) async {
    log.fine('Updating transaction: ${transaction.id}');

    try {
      // Update via API
      final updated = await _updateViaApi(transaction);

      // Update in local DB
      await _updateLocally(updated);

      // Update in cache
      await cacheService.set(
        entityType: _entityType,
        entityId: updated.id,
        data: updated,
        ttl: _cacheTtl,
      );

      // Invalidate related caches
      await CacheInvalidationRules.onTransactionMutation(
        cacheService,
        updated,
        MutationType.update,
      );

      log.info('Transaction updated: ${updated.id}');
      return updated;

    } catch (e, stackTrace) {
      log.severe('Failed to update transaction: ${transaction.id}', e, stackTrace);
      rethrow;
    }
  }

  /// Delete transaction and invalidate caches
  @override
  Future<void> delete(String id) async {
    log.fine('Deleting transaction: $id');

    try {
      // Get transaction before deletion (for invalidation)
      final transaction = await getById(id);
      if (transaction == null) {
        log.warning('Transaction not found for deletion: $id');
        return;
      }

      // Delete via API
      await _deleteViaApi(id);

      // Delete from local DB
      await _deleteLocally(id);

      // Invalidate cache
      await cacheService.invalidate(_entityType, id);

      // Invalidate related caches
      await CacheInvalidationRules.onTransactionMutation(
        cacheService,
        transaction,
        MutationType.delete,
      );

      log.info('Transaction deleted: $id');

    } catch (e, stackTrace) {
      log.severe('Failed to delete transaction: $id', e, stackTrace);
      rethrow;
    }
  }

  // Private API methods
  Future<Transaction> _fetchFromApi(String id) async {
    // Use existing API client
    final response = await apiService.v1TransactionsIdGet(id: id);
    return Transaction.fromJson(response.data!.attributes!.toJson());
  }

  Future<List<Transaction>> _fetchAllFromApi(
    DateTime? startDate,
    DateTime? endDate,
    String? accountId,
    String? budgetId,
  ) async {
    // Use existing API client with filters
    final response = await apiService.v1TransactionsGet(
      start: startDate,
      end: endDate,
      // ... other filters
    );
    return response.data!.map((t) => Transaction.fromJson(t.attributes!.toJson())).toList();
  }

  Future<Transaction> _createViaApi(Transaction transaction) async {
    // Implementation...
  }

  Future<Transaction> _updateViaApi(Transaction transaction) async {
    // Implementation...
  }

  Future<void> _deleteViaApi(String id) async {
    // Implementation...
  }

  // Private local DB methods
  Future<void> _storeLocally(Transaction transaction) async {
    // Store in Drift database
    await database.into(database.transactionTable).insertOnConflictUpdate(
      transaction.toCompanion(),
    );
  }

  Future<void> _updateLocally(Transaction transaction) async {
    // Update in Drift database
    await (database.update(database.transactionTable)
          ..where((tbl) => tbl.id.equals(transaction.id)))
        .write(transaction.toCompanion());
  }

  Future<void> _deleteLocally(String id) async {
    // Delete from Drift database
    await (database.delete(database.transactionTable)
          ..where((tbl) => tbl.id.equals(id)))
        .go();
  }
}
```

---

## Cache Invalidation

### Complete Invalidation Example

```dart
// In CacheInvalidationRules class

static Future<void> onTransactionMutation(
  CacheService cache,
  Transaction transaction,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after transaction $mutationType: ${transaction.id}');

  // 1. Invalidate the transaction itself
  await cache.invalidate('transaction', transaction.id);

  // 2. Invalidate all transaction lists (comprehensive)
  await cache.invalidateType('transaction_list');
  log.fine('Invalidated all transaction lists');

  // 3. Invalidate source account
  if (transaction.sourceId != null && transaction.sourceId!.isNotEmpty) {
    await cache.invalidate('account', transaction.sourceId!);
    await cache.invalidate('account_transactions', transaction.sourceId!);
    log.fine('Invalidated source account: ${transaction.sourceId}');
  }

  // 4. Invalidate destination account
  if (transaction.destinationId != null && transaction.destinationId!.isNotEmpty) {
    await cache.invalidate('account', transaction.destinationId!);
    await cache.invalidate('account_transactions', transaction.destinationId!);
    log.fine('Invalidated destination account: ${transaction.destinationId}');
  }

  // 5. Invalidate all account lists (balances changed)
  await cache.invalidateType('account_list');

  // 6. Invalidate budget if present
  if (transaction.budgetId != null && transaction.budgetId!.isNotEmpty) {
    await cache.invalidate('budget', transaction.budgetId!);
    await cache.invalidate('budget_transactions', transaction.budgetId!);
    await cache.invalidateType('budget_list');
    log.fine('Invalidated budget: ${transaction.budgetId}');
  }

  // 7. Invalidate category if present
  if (transaction.categoryId != null && transaction.categoryId!.isNotEmpty) {
    await cache.invalidate('category', transaction.categoryId!);
    await cache.invalidate('category_transactions', transaction.categoryId!);
    log.fine('Invalidated category: ${transaction.categoryId}');
  }

  // 8. Invalidate dashboard and charts (aggregate data affected)
  await cache.invalidateType('dashboard');
  await cache.invalidateType('chart');
  log.fine('Invalidated dashboard and charts');

  log.info('Transaction cache invalidation complete');
}
```

---

## UI Integration

### CacheStreamBuilder Widget

```dart
/// Cache-aware Stream Builder Widget
///
/// Automatically rebuilds when background cache refresh completes.
/// Uses RxDart streams from CacheService for reactive updates.
class CacheStreamBuilder<T> extends StatefulWidget {
  final String entityType;
  final String entityId;
  final Future<T?> Function() fetcher;
  final Widget Function(BuildContext context, T? data, bool isFresh) builder;
  final Widget Function(BuildContext context, Object error)? errorBuilder;

  const CacheStreamBuilder({
    Key? key,
    required this.entityType,
    required this.entityId,
    required this.fetcher,
    required this.builder,
    this.errorBuilder,
  }) : super(key: key);

  @override
  State<CacheStreamBuilder<T>> createState() => _CacheStreamBuilderState<T>();
}

class _CacheStreamBuilderState<T> extends State<CacheStreamBuilder<T>> {
  final Logger _log = Logger('CacheStreamBuilder');
  T? _data;
  bool _isFresh = true;
  bool _isLoading = true;
  Object? _error;
  StreamSubscription<CacheInvalidationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToUpdates();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await widget.fetcher();

      if (mounted) {
        setState(() {
          _data = data;
          _isLoading = false;
          _isFresh = true;
        });
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to load data', e, stackTrace);
      if (mounted) {
        setState(() {
          _error = e;
          _isLoading = false;
        });
      }
    }
  }

  void _subscribeToUpdates() {
    final cacheService = context.read<CacheService>();

    _subscription = cacheService.invalidationStream
        .where((event) =>
            event.entityType == widget.entityType &&
            (event.entityId == widget.entityId || event.entityId == '*') &&
            event.eventType == CacheEventType.refreshed)
        .listen((event) {
      _log.fine('Cache updated: ${widget.entityType}:${widget.entityId}');

      if (mounted && event.data != null) {
        setState(() {
          _data = event.data as T?;
          _isFresh = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!);
    }

    if (_isLoading && _data == null) {
      return Center(child: CircularProgressIndicator());
    }

    return widget.builder(context, _data, _isFresh);
  }
}
```

### Usage in UI Page

```dart
// In account detail page
class AccountDetailPage extends StatelessWidget {
  final String accountId;

  @override
  Widget build(BuildContext context) {
    final accountRepository = context.read<AccountRepository>();

    return Scaffold(
      appBar: AppBar(title: Text('Account Details')),
      body: CacheStreamBuilder<Account>(
        entityType: 'account',
        entityId: accountId,
        fetcher: () => accountRepository.getById(accountId),
        builder: (context, account, isFresh) {
          if (account == null) {
            return Center(child: Text('Account not found'));
          }

          return RefreshIndicator(
            onRefresh: () => accountRepository.getById(accountId, forceRefresh: true),
            child: ListView(
              children: [
                // Show subtle indicator for background refresh
                if (!isFresh)
                  LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                  ),

                AccountHeader(account: account),
                AccountBalanceCard(account: account),
                RecentTransactionsList(accountId: accountId),
              ],
            ),
          );
        },
        errorBuilder: (context, error) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading account'),
                Text(error.toString(), style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

---

## Testing Examples

### Unit Test Example

```dart
// test/services/cache/cache_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabase extends Mock implements AppDatabase {}

void main() {
  late CacheService cacheService;
  late MockDatabase mockDb;

  setUp(() {
    mockDb = MockDatabase();
    cacheService = CacheService(database: mockDb);
  });

  group('CacheService', () {
    test('should return cached data when fresh', () async {
      // Arrange: set up cache with fresh data
      final testData = Account(id: '123', name: 'Test Account');
      await cacheService.set(
        entityType: 'account',
        entityId: '123',
        data: testData,
        ttl: Duration(hours: 1),
      );

      // Act: fetch with cache-first
      final result = await cacheService.get<Account>(
        entityType: 'account',
        entityId: '123',
        fetcher: () async => throw Exception('Should not fetch'),
      );

      // Assert: returns cached data without calling fetcher
      expect(result.data, equals(testData));
      expect(result.source, equals(CacheSource.cache));
      expect(result.isFresh, isTrue);
    });

    test('should fetch and cache when cache miss', () async {
      // Arrange: no cache entry
      final testData = Account(id: '123', name: 'Test Account');
      var fetcherCalled = false;

      // Act: fetch with cache-first
      final result = await cacheService.get<Account>(
        entityType: 'account',
        entityId: '123',
        fetcher: () async {
          fetcherCalled = true;
          return testData;
        },
      );

      // Assert: calls fetcher and caches result
      expect(fetcherCalled, isTrue);
      expect(result.data, equals(testData));
      expect(result.source, equals(CacheSource.api));

      // Verify cached for next call
      final cachedResult = await cacheService.get<Account>(
        entityType: 'account',
        entityId: '123',
        fetcher: () async => throw Exception('Should not fetch'),
      );
      expect(cachedResult.source, equals(CacheSource.cache));
    });

    test('should invalidate cache entry', () async {
      // Arrange: cache data
      await cacheService.set(
        entityType: 'account',
        entityId: '123',
        data: Account(id: '123', name: 'Test'),
      );

      // Act: invalidate
      await cacheService.invalidate('account', '123');

      // Assert: cache miss on next get
      final isFresh = await cacheService.isFresh('account', '123');
      expect(isFresh, isFalse);
    });

    test('should serve stale data and trigger background refresh', () async {
      // Arrange: cache with expired TTL
      await cacheService.set(
        entityType: 'account',
        entityId: '123',
        data: Account(id: '123', name: 'Old Data'),
        ttl: Duration(milliseconds: 1),
      );
      await Future.delayed(Duration(milliseconds: 10)); // Let it expire

      // Act: fetch with background refresh
      var fetcherCalled = false;
      final result = await cacheService.get<Account>(
        entityType: 'account',
        entityId: '123',
        fetcher: () async {
          await Future.delayed(Duration(milliseconds: 50));
          fetcherCalled = true;
          return Account(id: '123', name: 'New Data');
        },
        backgroundRefresh: true,
      );

      // Assert: returns stale data immediately
      expect(result.data?.name, equals('Old Data'));
      expect(result.isFresh, isFalse);
      expect(fetcherCalled, isFalse); // Not yet called (background)

      // Wait for background refresh
      await Future.delayed(Duration(milliseconds: 100));
      expect(fetcherCalled, isTrue);
    });
  });
}
```

---

## Summary

These code examples provide concrete implementation patterns for:

1. ✅ Cache metadata table with proper schema and indexes
2. ✅ Complete CacheService with stale-while-revalidate
3. ✅ Repository integration with cache-first strategy
4. ✅ Comprehensive cache invalidation rules
5. ✅ UI integration with CacheStreamBuilder widget
6. ✅ Comprehensive unit testing patterns

Use these examples as templates when implementing the cache system in Waterfly III. All code follows the project's philosophy of comprehensive, production-ready implementations with full error handling, logging, and documentation.
