# Local Database Cache Implementation Plan

## Overview

This document outlines the implementation plan for transforming Waterfly III's local database from an offline-first storage system into a comprehensive **cache-first architecture**. The goal is to minimize API calls by serving data from the local Drift database whenever possible, only fetching from the Firefly III API when necessary (cache miss, expired data, or explicit refresh).

### Key Objectives

1. **Reduce API Load**: Minimize unnecessary API calls to improve performance and reduce server load
2. **Faster UI Response**: Serve cached data instantly while optionally refreshing in background
3. **Better UX**: Eliminate loading spinners for cached content
4. **Bandwidth Optimization**: Reduce mobile data usage for users
5. **Maintain Offline Support**: Preserve existing offline-first capabilities
6. **Smart Invalidation**: Keep cache fresh with intelligent invalidation strategies

### Philosophy

**Cache-First with Background Refresh**: Read from local database first, display immediately, then optionally refresh from API in background and update UI if data changed.

---

## Current State Analysis

### Existing Architecture

Waterfly III already has significant infrastructure in place:

✅ **Local Database (Drift)**
- SQLite with 9 main tables (transactions, accounts, budgets, categories, bills, piggy_banks, etc.)
- WAL mode for concurrency
- 24+ performance indexes
- Schema versioning with migrations

✅ **Repository Pattern**
- `BaseRepository<T>` with CRUD operations
- Repositories in `lib/data/repositories/`
- Already handle online/offline modes

✅ **Offline Mode System**
- Sync queue for pending operations
- Conflict resolution strategies
- ID mapping (local ↔ server IDs)
- Background sync via WorkManager

✅ **Connectivity Monitoring**
- `ConnectivityProvider` using `connectivity_plus` package
- Real-time network status tracking
- Internet connection verification via `internet_connection_checker_plus`

### Current Data Flow

**Online Mode (Current Behavior)**:
```
UI Request → Repository → API Call → Parse Response → Update Local DB → Return to UI
                                                    ↓
                                            Cache stored but not used
```

**Offline Mode (Current Behavior)**:
```
UI Request → Repository → Local DB → Return to UI
Operation → Sync Queue → (Wait for connectivity) → Sync to API
```

### Gap Analysis

**What's Missing for Cache-First**:

1. ❌ **Cache Metadata**: No timestamps, TTL, or freshness tracking
2. ❌ **Cache Strategy Logic**: No decision layer for "use cache vs fetch API"
3. ❌ **Staleness Detection**: No way to determine if cached data is "fresh enough"
4. ❌ **Smart Invalidation**: No automatic cache invalidation on related entity changes
5. ❌ **Background Refresh**: No mechanism to refresh cache while displaying stale data
6. ❌ **Cache Warming**: No preemptive cache population strategies
7. ❌ **Partial Updates**: Always fetch full entities, no delta updates

---

## Proposed Cache Architecture

### Cache Strategy: Stale-While-Revalidate

Implement the **stale-while-revalidate** pattern:

1. **Check cache first** (always)
2. **If cached & fresh**: Return immediately
3. **If cached & stale**: Return cached data immediately, fetch fresh data in background, update cache & UI
4. **If not cached**: Fetch from API, store in cache, return to UI
5. **If offline**: Serve from cache (existing behavior)

### Cache Metadata Schema

Add a new Drift table: `cache_metadata`

```dart
@DataClassName('CacheMetadata')
class CacheMetadataTable extends Table {
  /// Entity type (e.g., 'transaction', 'account', 'budget')
  TextColumn get entityType => text()();

  /// Entity ID (server ID or 'collection' for list queries)
  TextColumn get entityId => text()();

  /// Timestamp when data was cached
  DateTimeColumn get cachedAt => dateTime()();

  /// Timestamp when data was last accessed
  DateTimeColumn get lastAccessedAt => dateTime()();

  /// Time-to-live in seconds (how long until stale)
  IntColumn get ttlSeconds => integer()();

  /// Whether this cache entry is invalidated
  BoolColumn get isInvalidated => boolean().withDefault(const Constant(false))();

  /// Optional ETag for HTTP cache validation
  TextColumn get etag => text().nullable()();

  /// Optional query parameters hash (for collection queries)
  TextColumn get queryHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {entityType, entityId};
}
```

**Indexes for Performance**:
```dart
// Find entries by type
@override
List<Index> get customIndex => [
  Index('cache_by_type', [entityType]),
  Index('cache_by_invalidation', [isInvalidated, cachedAt]),
  Index('cache_by_staleness', [cachedAt, ttlSeconds]),
];
```

### Cache Service

Create a new service: `lib/services/cache/cache_service.dart`

**Key Packages to Use**:
- `drift` (^2.14.0) - Database operations (already integrated)
- `rxdart` (^0.28.0) - Reactive cache streams (already integrated)
- `synchronized` (^3.4.0) - Thread-safe cache operations (already integrated)
- `crypto` (SDK) - Hash query parameters for cache keys

**Responsibilities**:
```dart
/// Cache Service
///
/// Provides comprehensive cache management using:
/// - [drift] for metadata and data storage
/// - [rxdart] for reactive cache invalidation streams
/// - [synchronized] for thread-safe cache operations
/// - [crypto] for generating cache keys from queries
///
/// Key Features:
/// - TTL-based cache expiration
/// - Stale-while-revalidate pattern
/// - Smart invalidation on related entity changes
/// - Background refresh with RxDart streams
/// - LRU eviction for memory management
/// - ETag support for HTTP cache validation
///
/// Example:
/// ```dart
/// final cacheService = CacheService(database: db);
///
/// // Check cache with stale-while-revalidate
/// final result = await cacheService.get<Account>(
///   entityType: 'account',
///   entityId: '123',
///   fetcher: () => apiClient.getAccount('123'),
///   ttl: Duration(minutes: 30),
/// );
/// ```
class CacheService {
  final AppDatabase database;
  final Logger _log = Logger('CacheService');

  // Synchronized lock for thread-safe cache operations
  final Lock _lock = Lock();

  // RxDart streams for cache invalidation events
  final PublishSubject<CacheInvalidationEvent> _invalidationStream = PublishSubject();

  /// Get data with cache-first strategy (stale-while-revalidate)
  Future<CacheResult<T>> get<T>({
    required String entityType,
    required String entityId,
    required Future<T> Function() fetcher,
    Duration ttl = const Duration(minutes: 30),
    bool forceRefresh = false,
    bool backgroundRefresh = true,
  });

  /// Store data in cache with metadata
  Future<void> set<T>({
    required String entityType,
    required String entityId,
    required T data,
    Duration ttl = const Duration(minutes: 30),
    String? etag,
  });

  /// Invalidate specific cache entry
  Future<void> invalidate(String entityType, String entityId);

  /// Invalidate all entries of a type
  Future<void> invalidateType(String entityType);

  /// Invalidate related entities (e.g., invalidate accounts when transaction created)
  Future<void> invalidateRelated(String entityType, String entityId);

  /// Check if cache entry is fresh
  Future<bool> isFresh(String entityType, String entityId);

  /// Get cache statistics
  Future<CacheStats> getStats();

  /// Clean expired cache entries
  Future<void> cleanExpired();

  /// Stream of cache invalidation events
  Stream<CacheInvalidationEvent> get invalidationStream => _invalidationStream.stream;
}
```

### Cache-Aware Repository Pattern

Modify `BaseRepository<T>` to integrate caching:

```dart
abstract class BaseRepository<T> {
  final FireflyService apiService;
  final AppDatabase database;
  final CacheService cacheService; // NEW
  final Logger log;

  /// Get entity by ID with cache-first strategy
  Future<T?> getById(
    String id, {
    bool forceRefresh = false,
    bool backgroundRefresh = true,
  }) async {
    log.fine('Getting $T by ID: $id (forceRefresh: $forceRefresh)');

    // Use cache service with stale-while-revalidate
    final result = await cacheService.get<T>(
      entityType: _entityType,
      entityId: id,
      fetcher: () => _fetchFromApi(id),
      ttl: _cacheTtl,
      forceRefresh: forceRefresh,
      backgroundRefresh: backgroundRefresh,
    );

    return result.data;
  }

  /// Get all entities with cache-first strategy
  Future<List<T>> getAll({
    bool forceRefresh = false,
    Map<String, dynamic>? filters,
  }) async {
    log.fine('Getting all $T (forceRefresh: $forceRefresh, filters: $filters)');

    // Generate cache key from filters
    final cacheKey = _generateCollectionCacheKey(filters);

    final result = await cacheService.get<List<T>>(
      entityType: _entityType,
      entityId: cacheKey,
      fetcher: () => _fetchAllFromApi(filters),
      ttl: _collectionCacheTtl,
      forceRefresh: forceRefresh,
    );

    return result.data ?? [];
  }

  /// Create entity and invalidate related caches
  Future<T> create(T entity) async {
    log.fine('Creating $T');

    // Create via API
    final created = await _createViaApi(entity);

    // Store in local DB
    await _storeLocally(created);

    // Store in cache
    await cacheService.set(
      entityType: _entityType,
      entityId: _getEntityId(created),
      data: created,
      ttl: _cacheTtl,
    );

    // Invalidate related caches (e.g., collections, related entities)
    await _invalidateRelatedCaches(created);

    return created;
  }

  // Abstract methods to implement in concrete repositories
  String get _entityType;
  Duration get _cacheTtl;
  Duration get _collectionCacheTtl;
  Future<T> _fetchFromApi(String id);
  Future<List<T>> _fetchAllFromApi(Map<String, dynamic>? filters);
  Future<void> _invalidateRelatedCaches(T entity);
}
```

---

## Cache Configuration Strategy

### TTL Policies by Entity Type

Different entities have different data volatility - configure TTL accordingly:

```dart
/// Cache TTL Configuration
///
/// Defines Time-To-Live (TTL) for each entity type based on:
/// - Data volatility (how often it changes)
/// - User expectations (how fresh data needs to be)
/// - API cost (expensive queries get longer TTL)
class CacheTtlConfig {
  /// Highly volatile data - short TTL
  static const Duration transactions = Duration(minutes: 5);
  static const Duration transactionsList = Duration(minutes: 3);

  /// Moderately volatile - medium TTL
  static const Duration accounts = Duration(minutes: 15);
  static const Duration accountsList = Duration(minutes: 10);

  static const Duration budgets = Duration(minutes: 15);
  static const Duration budgetsList = Duration(minutes: 10);

  /// Low volatility - long TTL
  static const Duration categories = Duration(hours: 1);
  static const Duration categoriesList = Duration(hours: 1);

  static const Duration currencies = Duration(hours: 24);
  static const Duration currenciesList = Duration(hours: 24);

  /// Rarely changes - very long TTL
  static const Duration piggyBanks = Duration(hours: 2);
  static const Duration bills = Duration(hours: 1);

  /// User profile - changes only on explicit update
  static const Duration userProfile = Duration(hours: 12);

  /// Dashboard/summary data - balance between freshness and performance
  static const Duration dashboard = Duration(minutes: 5);
  static const Duration charts = Duration(minutes: 10);

  /// Get TTL for entity type
  static Duration getTtl(String entityType) {
    switch (entityType) {
      case 'transaction':
        return transactions;
      case 'transaction_list':
        return transactionsList;
      case 'account':
        return accounts;
      case 'account_list':
        return accountsList;
      case 'budget':
        return budgets;
      case 'budget_list':
        return budgetsList;
      case 'category':
        return categories;
      case 'category_list':
        return categoriesList;
      case 'currency':
        return currencies;
      case 'currency_list':
        return currenciesList;
      case 'piggy_bank':
        return piggyBanks;
      case 'bill':
        return bills;
      case 'user':
        return userProfile;
      case 'dashboard':
        return dashboard;
      case 'chart':
        return charts;
      default:
        return const Duration(minutes: 15); // Default TTL
    }
  }
}
```

### Cache Invalidation Rules

Define smart invalidation rules to maintain cache consistency:

```dart
/// Cache Invalidation Rules
///
/// Defines which caches to invalidate when entities are created/updated/deleted.
/// Uses a dependency graph to cascade invalidations to related entities.
///
/// Example:
/// - When a transaction is created → invalidate account balance, budget spent, transaction lists
/// - When a category is deleted → invalidate all transactions with that category
class CacheInvalidationRules {
  static final Logger _log = Logger('CacheInvalidationRules');

  /// Invalidate caches after transaction mutation
  static Future<void> onTransactionMutation(
    CacheService cache,
    Transaction transaction,
    MutationType mutationType,
  ) async {
    _log.fine('Invalidating caches after transaction $mutationType');

    // Invalidate the transaction itself
    await cache.invalidate('transaction', transaction.id);

    // Invalidate transaction lists (all variations)
    await cache.invalidateType('transaction_list');

    // Invalidate source account
    if (transaction.sourceId != null) {
      await cache.invalidate('account', transaction.sourceId!);
    }

    // Invalidate destination account
    if (transaction.destinationId != null) {
      await cache.invalidate('account', transaction.destinationId!);
    }

    // Invalidate all account lists
    await cache.invalidateType('account_list');

    // Invalidate budget if transaction has budget
    if (transaction.budgetId != null) {
      await cache.invalidate('budget', transaction.budgetId!);
      await cache.invalidateType('budget_list');
    }

    // Invalidate category
    if (transaction.categoryId != null) {
      await cache.invalidate('category', transaction.categoryId!);
    }

    // Invalidate dashboard (summary data affected)
    await cache.invalidateType('dashboard');
    await cache.invalidateType('chart');
  }

  /// Invalidate caches after account mutation
  static Future<void> onAccountMutation(
    CacheService cache,
    Account account,
    MutationType mutationType,
  ) async {
    _log.fine('Invalidating caches after account $mutationType');

    await cache.invalidate('account', account.id);
    await cache.invalidateType('account_list');

    // If account deleted, invalidate all transactions with this account
    if (mutationType == MutationType.delete) {
      await cache.invalidateType('transaction');
      await cache.invalidateType('transaction_list');
    }

    await cache.invalidateType('dashboard');
  }

  /// Invalidate caches after budget mutation
  static Future<void> onBudgetMutation(
    CacheService cache,
    Budget budget,
    MutationType mutationType,
  ) async {
    _log.fine('Invalidating caches after budget $mutationType');

    await cache.invalidate('budget', budget.id);
    await cache.invalidateType('budget_list');
    await cache.invalidateType('dashboard');
  }

  /// Invalidate caches after category mutation
  static Future<void> onCategoryMutation(
    CacheService cache,
    Category category,
    MutationType mutationType,
  ) async {
    _log.fine('Invalidating caches after category $mutationType');

    await cache.invalidate('category', category.id);
    await cache.invalidateType('category_list');

    // Category changes might affect transaction display
    await cache.invalidateType('transaction_list');
  }

  // ... more invalidation rules for other entity types
}

enum MutationType {
  create,
  update,
  delete,
}
```

---

## Implementation Phases

### Phase 1: Foundation (Week 1)

**Goal**: Establish cache infrastructure

**Tasks**:
1. ✅ Create `cache_metadata` Drift table
   - Schema definition in `lib/data/local/database/cache_metadata_table.dart`
   - Add to `AppDatabase` in `lib/data/local/database/database.dart`
   - Generate code: `dart run build_runner build --delete-conflicting-outputs`
   - Create migration for existing installs

2. ✅ Implement `CacheService`
   - Create `lib/services/cache/cache_service.dart`
   - Implement core methods: `get`, `set`, `invalidate`
   - Add thread safety with `synchronized` package
   - Add comprehensive logging
   - Add unit tests in `test/services/cache/cache_service_test.dart`

3. ✅ Create `CacheTtlConfig`
   - Define TTL constants in `lib/config/cache_ttl_config.dart`
   - Document rationale for each TTL value
   - Make configurable via settings (optional)

4. ✅ Create `CacheInvalidationRules`
   - Define invalidation logic in `lib/services/cache/cache_invalidation_rules.dart`
   - Implement dependency graph
   - Add comprehensive logging

**Deliverables**:
- Cache metadata table schema
- CacheService with full implementation
- TTL configuration
- Invalidation rules framework
- Unit tests for cache service (>90% coverage)

### Phase 2: Repository Integration (Week 2)

**Goal**: Modify repositories to use cache

**Tasks**:
1. ✅ Update `BaseRepository<T>`
   - Add `cacheService` dependency
   - Modify `getById` to use cache-first strategy
   - Modify `getAll` to use cache-first strategy
   - Add cache invalidation to `create`, `update`, `delete`
   - Add comprehensive logging
   - Update tests in `test/data/repositories/base_repository_test.dart`

2. ✅ Update concrete repositories (one by one)
   - `TransactionRepository` (start here - most used)
   - `AccountRepository`
   - `BudgetRepository`
   - `CategoryRepository`
   - `BillRepository`
   - `PiggyBankRepository`
   - Each with invalidation rules implementation
   - Each with updated tests

3. ✅ Add cache statistics
   - Cache hit rate tracking
   - Cache size monitoring
   - Staleness metrics
   - Expose via `CacheService.getStats()`

**Deliverables**:
- Updated BaseRepository with caching
- All repositories using cache-first pattern
- Cache statistics tracking
- Updated repository tests

### Phase 3: Background Refresh (Week 3)

**Goal**: Implement stale-while-revalidate with background refresh

**Tasks**:
1. ✅ Implement background refresh in `CacheService`
   - When serving stale data, trigger background fetch
   - Use RxDart streams to notify UI of updates
   - Implement with `synchronized` for thread safety
   - Add retry logic with `retry` package

2. ✅ Update UI widgets to subscribe to cache updates
   - Create `CacheStreamBuilder` widget
   - Automatically refresh UI when background fetch completes
   - Show subtle indicator for background refresh (optional)
   - Example: `lib/widgets/cache_stream_builder.dart`

3. ✅ Implement cache warming strategies
   - Pre-fetch frequently accessed data on app start
   - Pre-fetch related data (e.g., when viewing account, pre-fetch transactions)
   - Implement in `lib/services/cache/cache_warming_service.dart`

**Deliverables**:
- Background refresh mechanism
- RxDart stream integration
- CacheStreamBuilder widget
- Cache warming service
- Updated widget tests

### Phase 4: Advanced Features (Week 4)

**Goal**: Add optimizations and advanced caching features

**Tasks**:
1. ✅ Implement ETag support
   - Store ETags in cache metadata
   - Use HTTP conditional requests (If-None-Match)
   - Handle 304 Not Modified responses
   - Reduces bandwidth for unchanged data

2. ✅ Implement query parameter hashing
   - Hash filters/parameters for collection queries
   - Store in `queryHash` column
   - Enable cache hits for identical queries with different parameter order

3. ✅ Implement LRU eviction
   - Track `lastAccessedAt` in metadata
   - Automatically evict least-recently-used entries when cache size exceeds limit
   - Configurable cache size limit (default: 100MB)

4. ✅ Add cache debugging tools
   - Cache inspector UI (debug mode only)
   - Show cache entries, freshness, hit rates
   - Manual cache clearing
   - Add to settings page: `lib/pages/settings/cache_debug.dart`

**Deliverables**:
- ETag support in CacheService
- Query parameter hashing
- LRU eviction mechanism
- Cache debugging UI
- Performance benchmarks

### Phase 5: Testing & Optimization (Week 5)

**Goal**: Comprehensive testing and performance validation

**Tasks**:
1. ✅ Unit tests for all cache components
   - `CacheService` tests (>90% coverage)
   - `CacheInvalidationRules` tests
   - `CacheTtlConfig` tests
   - Repository integration tests

2. ✅ Widget tests for UI components
   - `CacheStreamBuilder` tests
   - Cache debug UI tests

3. ✅ Integration tests for cache flows
   - End-to-end cache-first scenarios
   - Background refresh validation
   - Invalidation cascade tests
   - Offline-to-online transition tests

4. ✅ Performance benchmarking
   - Measure API call reduction (target: 70-80% reduction)
   - Measure UI response time improvement
   - Measure bandwidth usage reduction
   - Compare with/without cache

5. ✅ Load testing
   - Test with large datasets (1000+ transactions)
   - Test cache eviction under memory pressure
   - Test concurrent access with `synchronized`

**Deliverables**:
- Comprehensive test suite (>85% coverage)
- Performance benchmarks with metrics
- Load test results
- Optimization recommendations

### Phase 6: Migration & Rollout (Week 6)

**Goal**: Safe migration and gradual rollout

**Tasks**:
1. ✅ Create database migration
   - Add `cache_metadata` table to schema
   - Handle existing installations gracefully
   - Test migration on various schema versions

2. ✅ Implement feature flag
   - Add `enableCaching` setting (default: true)
   - Allow users to disable if issues occur
   - Add to `SettingsProvider`

3. ✅ Add cache metrics to analytics
   - Track cache hit rate
   - Track API call reduction
   - Track user-reported issues

4. ✅ Documentation
   - Update CLAUDE.md with caching architecture
   - Document cache configuration options
   - Create user-facing FAQ for cache behavior

5. ✅ Beta testing
   - Release to beta channel first
   - Monitor crash reports and bug reports
   - Gather user feedback on performance

6. ✅ Production rollout
   - Gradual rollout (10% → 50% → 100%)
   - Monitor metrics closely
   - Have rollback plan ready

**Deliverables**:
- Database migration tested and ready
- Feature flag implementation
- Updated documentation
- Beta release
- Production release plan

---

## Technical Implementation Details

### Cache Key Generation

Generate consistent cache keys for collections:

```dart
/// Generate cache key for collection queries
///
/// Uses [crypto] package to create stable hash of query parameters.
/// This ensures identical queries (regardless of parameter order) hit the same cache entry.
String _generateCollectionCacheKey(Map<String, dynamic>? filters) {
  if (filters == null || filters.isEmpty) {
    return 'collection_all';
  }

  // Sort parameters for consistent hashing
  final sortedKeys = filters.keys.toList()..sort();
  final normalized = <String, dynamic>{};
  for (final key in sortedKeys) {
    normalized[key] = filters[key];
  }

  // Generate hash using crypto package
  final jsonString = jsonEncode(normalized);
  final bytes = utf8.encode(jsonString);
  final hash = sha256.convert(bytes);

  return 'collection_${hash.toString().substring(0, 16)}';
}
```

### Cache Freshness Check

Determine if cache entry is fresh:

```dart
/// Check if cache entry is fresh
///
/// A cache entry is considered fresh if:
/// 1. It exists in cache metadata
/// 2. It's not explicitly invalidated
/// 3. Current time < (cachedAt + ttl)
Future<bool> isFresh(String entityType, String entityId) async {
  final metadata = await (database.select(database.cacheMetadataTable)
        ..where((tbl) =>
            tbl.entityType.equals(entityType) &
            tbl.entityId.equals(entityId)))
      .getSingleOrNull();

  if (metadata == null) {
    _log.fine('Cache miss: no metadata for $entityType:$entityId');
    return false;
  }

  if (metadata.isInvalidated) {
    _log.fine('Cache invalid: $entityType:$entityId explicitly invalidated');
    return false;
  }

  final now = DateTime.now();
  final expiresAt = metadata.cachedAt.add(Duration(seconds: metadata.ttlSeconds));

  final fresh = now.isBefore(expiresAt);
  _log.fine('Cache freshness check: $entityType:$entityId fresh=$fresh '
      '(age: ${now.difference(metadata.cachedAt).inSeconds}s, ttl: ${metadata.ttlSeconds}s)');

  return fresh;
}
```

### Background Refresh Implementation

Implement stale-while-revalidate with RxDart:

```dart
/// Get data with stale-while-revalidate pattern
///
/// Strategy:
/// 1. Check cache freshness
/// 2. If fresh: return cached data immediately
/// 3. If stale: return cached data immediately, start background refresh
/// 4. If miss: fetch from API, cache, return
/// 5. Emit cache updates via RxDart stream for UI refresh
Future<CacheResult<T>> get<T>({
  required String entityType,
  required String entityId,
  required Future<T> Function() fetcher,
  Duration ttl = const Duration(minutes: 30),
  bool forceRefresh = false,
  bool backgroundRefresh = true,
}) async {
  _log.fine('Cache get: $entityType:$entityId (force=$forceRefresh)');

  // Check if force refresh requested
  if (forceRefresh) {
    _log.fine('Force refresh requested, bypassing cache');
    return await _fetchAndCache(entityType, entityId, fetcher, ttl);
  }

  // Check cache freshness
  final fresh = await isFresh(entityType, entityId);

  if (fresh) {
    // Cache hit: return immediately
    _log.fine('Cache hit (fresh): $entityType:$entityId');
    final data = await _getFromCache<T>(entityType, entityId);

    // Update last accessed timestamp
    await _updateLastAccessed(entityType, entityId);

    return CacheResult<T>(
      data: data,
      source: CacheSource.cache,
      isFresh: true,
    );
  }

  // Cache exists but stale
  final cachedData = await _getFromCache<T>(entityType, entityId);

  if (cachedData != null) {
    _log.fine('Cache hit (stale): $entityType:$entityId');

    // Return stale data immediately
    if (backgroundRefresh) {
      // Start background refresh (fire-and-forget with error handling)
      _log.fine('Starting background refresh for $entityType:$entityId');
      unawaited(_backgroundRefresh(entityType, entityId, fetcher, ttl));
    }

    return CacheResult<T>(
      data: cachedData,
      source: CacheSource.cache,
      isFresh: false,
    );
  }

  // Cache miss: fetch from API
  _log.fine('Cache miss: $entityType:$entityId');
  return await _fetchAndCache(entityType, entityId, fetcher, ttl);
}

/// Background refresh with stream notification
Future<void> _backgroundRefresh<T>(
  String entityType,
  String entityId,
  Future<T> Function() fetcher,
  Duration ttl,
) async {
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

    // Emit cache update event via RxDart stream
    _invalidationStream.add(CacheInvalidationEvent(
      entityType: entityType,
      entityId: entityId,
      eventType: CacheEventType.refreshed,
      data: data,
    ));

  } catch (e, stackTrace) {
    _log.severe('Background refresh failed: $entityType:$entityId', e, stackTrace);
    // Don't propagate error - stale data already returned
  }
}
```

### CacheStreamBuilder Widget

Widget that automatically refreshes on cache updates:

```dart
/// Cache-aware Stream Builder
///
/// Automatically rebuilds UI when background cache refresh completes.
/// Uses RxDart streams from [CacheService] for reactive updates.
///
/// Example:
/// ```dart
/// CacheStreamBuilder<Account>(
///   entityType: 'account',
///   entityId: accountId,
///   fetcher: () => accountRepository.getById(accountId),
///   builder: (context, account, isFresh) {
///     if (account == null) return CircularProgressIndicator();
///
///     return Column(
///       children: [
///         if (!isFresh) Text('Refreshing...', style: TextStyle(color: Colors.orange)),
///         AccountCard(account: account),
///       ],
///     );
///   },
/// )
/// ```
class CacheStreamBuilder<T> extends StatefulWidget {
  final String entityType;
  final String entityId;
  final Future<T?> Function() fetcher;
  final Widget Function(BuildContext context, T? data, bool isFresh) builder;

  const CacheStreamBuilder({
    Key? key,
    required this.entityType,
    required this.entityId,
    required this.fetcher,
    required this.builder,
  }) : super(key: key);

  @override
  State<CacheStreamBuilder<T>> createState() => _CacheStreamBuilderState<T>();
}

class _CacheStreamBuilderState<T> extends State<CacheStreamBuilder<T>> {
  final Logger _log = Logger('CacheStreamBuilder');
  T? _data;
  bool _isFresh = true;
  StreamSubscription<CacheInvalidationEvent>? _subscription;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeToUpdates();
  }

  Future<void> _loadData() async {
    try {
      final data = await widget.fetcher();
      if (mounted) {
        setState(() {
          _data = data;
        });
      }
    } catch (e, stackTrace) {
      _log.severe('Failed to load data', e, stackTrace);
    }
  }

  void _subscribeToUpdates() {
    final cacheService = context.read<CacheService>();

    _subscription = cacheService.invalidationStream
        .where((event) =>
            event.entityType == widget.entityType &&
            event.entityId == widget.entityId &&
            event.eventType == CacheEventType.refreshed)
        .listen((event) {
      _log.fine('Cache updated: ${widget.entityType}:${widget.entityId}');

      if (mounted) {
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
    return widget.builder(context, _data, _isFresh);
  }
}
```

---

## Performance Considerations

### Expected Improvements

**Metrics to Track**:
1. **API Call Reduction**: Target 70-80% reduction in API calls
2. **UI Response Time**: Target 50-70% faster load times for cached screens
3. **Bandwidth Usage**: Target 60-70% reduction in mobile data usage
4. **User Experience**: Eliminate loading spinners for cached content

**Benchmark Scenarios**:
- Cold start (no cache) vs warm start (cached)
- List refresh with pagination
- Detail view navigation
- Offline-to-online transition
- Background sync with cache invalidation

### Memory Management

**Cache Size Limits**:
- Default max cache size: 100MB
- Configurable via settings
- LRU eviction when limit exceeded
- Monitor with `CacheService.getStats()`

**Eviction Strategy**:
```dart
/// LRU Cache Eviction
///
/// When cache size exceeds limit:
/// 1. Calculate total cache size
/// 2. Sort by lastAccessedAt (ascending)
/// 3. Evict oldest entries until under limit
/// 4. Log eviction metrics
Future<void> evictLru() async {
  _log.fine('Running LRU eviction');

  final cacheSize = await _calculateCacheSize();
  final maxSize = _getCacheSizeLimit();

  if (cacheSize <= maxSize) {
    _log.fine('Cache size OK: ${cacheSize}MB / ${maxSize}MB');
    return;
  }

  _log.warning('Cache size exceeded: ${cacheSize}MB / ${maxSize}MB, evicting...');

  // Get all cache entries sorted by last access (oldest first)
  final entries = await (database.select(database.cacheMetadataTable)
        ..orderBy([(tbl) => OrderingTerm.asc(tbl.lastAccessedAt)]))
      .get();

  int evictedCount = 0;
  int freedSpace = 0;

  for (final entry in entries) {
    if (cacheSize - freedSpace <= maxSize) {
      break; // Target reached
    }

    // Calculate entry size and evict
    final entrySize = await _getEntrySize(entry.entityType, entry.entityId);
    await _evictEntry(entry.entityType, entry.entityId);

    freedSpace += entrySize;
    evictedCount++;
  }

  _log.info('LRU eviction complete: evicted $evictedCount entries, freed ${freedSpace}MB');
}
```

### Database Performance

**Optimizations**:
1. **Indexes**: Already have 24+ indexes for performance
2. **WAL Mode**: Already enabled for concurrent reads/writes
3. **Batch Operations**: Use Drift batch operations for bulk invalidations
4. **Prepared Statements**: Drift automatically uses prepared statements

**Query Optimization**:
```dart
// Use Drift's query builder for optimized SQL
Future<List<CacheMetadata>> getStaleEntries() async {
  final now = DateTime.now();

  return await (database.select(database.cacheMetadataTable)
        ..where((tbl) {
          // Efficient SQL: WHERE cachedAt + ttl < NOW()
          return tbl.cachedAt.isSmallerThan(Variable(now));
        }))
      .get();
}
```

---

## Testing Strategy

### Unit Tests

**CacheService Tests** (`test/services/cache/cache_service_test.dart`):
```dart
group('CacheService', () {
  late CacheService cacheService;
  late MockDatabase mockDb;

  setUp(() {
    mockDb = MockDatabase();
    cacheService = CacheService(database: mockDb);
  });

  test('should return cached data when fresh', () async {
    // Arrange: populate cache with fresh data
    final testData = Account(id: '123', name: 'Test');
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

    // Assert: returns cached data without fetching
    expect(result.data, equals(testData));
    expect(result.source, equals(CacheSource.cache));
    expect(result.isFresh, isTrue);
  });

  test('should fetch and cache when cache miss', () async {
    // Arrange: no cache entry
    final testData = Account(id: '123', name: 'Test');
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

  test('should trigger background refresh for stale data', () async {
    // Arrange: cache with expired TTL
    await cacheService.set(
      entityType: 'account',
      entityId: '123',
      data: Account(id: '123', name: 'Old'),
      ttl: Duration(milliseconds: 1),
    );
    await Future.delayed(Duration(milliseconds: 10)); // Let it expire

    // Act: fetch with background refresh
    var fetcherCalled = false;
    final result = await cacheService.get<Account>(
      entityType: 'account',
      entityId: '123',
      fetcher: () async {
        fetcherCalled = true;
        return Account(id: '123', name: 'New');
      },
      backgroundRefresh: true,
    );

    // Assert: returns stale data immediately
    expect(result.data?.name, equals('Old'));
    expect(result.isFresh, isFalse);

    // Wait for background refresh
    await Future.delayed(Duration(milliseconds: 100));
    expect(fetcherCalled, isTrue);
  });

  // ... more comprehensive tests for all cache operations
});
```

### Integration Tests

**Cache Flow Tests** (`integration_test/cache_flow_test.dart`):
```dart
patrol('Cache integration flow', (PatrolTester $) async {
  // Test: Navigate to accounts list, verify cache hit on second visit
  await $.pumpWidgetAndSettle(MyApp());

  // First visit: API call expected
  await $.tap(find.text('Accounts'));
  await $.waitForText('Checking Account');

  // Verify API called (check logs or mock)
  expect(find.byType(AccountCard), findsWidgets);

  // Navigate away and back
  await $.tap(find.byIcon(Icons.arrow_back));
  await $.tap(find.text('Accounts'));

  // Second visit: should be instant (cached)
  // No loading spinner expected
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byType(AccountCard), findsWidgets);
});
```

---

## Rollback Plan

### If Issues Arise

**Immediate Actions**:
1. Disable caching via feature flag in settings
2. Clear all cache metadata (`cache_metadata` table)
3. Monitor crash reports for cache-related errors
4. Rollback to previous version if critical

**Feature Flag Implementation**:
```dart
// In SettingsProvider
class SettingsProvider extends ChangeNotifier {
  bool _enableCaching = true;

  bool get enableCaching => _enableCaching;

  Future<void> setEnableCaching(bool value) async {
    _enableCaching = value;
    await _prefs.setBool('enable_caching', value);
    notifyListeners();

    if (!value) {
      // Clear all cache when disabled
      await _cacheService.clearAll();
    }
  }
}

// In Repository
Future<T?> getById(String id) async {
  final settings = context.read<SettingsProvider>();

  if (settings.enableCaching) {
    // Use cache-first strategy
    return await _getWithCache(id);
  } else {
    // Direct API call (original behavior)
    return await _getFromApi(id);
  }
}
```

---

## Success Metrics

### Key Performance Indicators (KPIs)

**Technical Metrics**:
- ✅ API call reduction: Target 70-80%
- ✅ UI response time: Target 50-70% improvement
- ✅ Cache hit rate: Target >75%
- ✅ Bandwidth reduction: Target 60-70%

**User Experience Metrics**:
- ✅ Reduced loading spinners (qualitative)
- ✅ Faster app feel (user surveys)
- ✅ Lower mobile data usage (user reports)
- ✅ Improved offline experience (cache available immediately on reconnect)

**Quality Metrics**:
- ✅ Test coverage: >85% for cache components
- ✅ Zero cache-related crashes
- ✅ No data inconsistency issues
- ✅ Successful background refresh rate: >95%

### Monitoring & Analytics

**Metrics to Track**:
```dart
class CacheStats {
  final int totalRequests;
  final int cacheHits;
  final int cacheMisses;
  final int staleServed;
  final int backgroundRefreshes;
  final int evictions;
  final double hitRate; // cacheHits / totalRequests
  final int averageAgeSeconds;
  final int totalCacheSizeMB;
  final Map<String, int> hitsByEntityType;

  double get hitRatePercent => hitRate * 100;
}
```

**Logging for Analysis**:
- Log cache hits/misses (INFO level)
- Log background refresh completions (INFO level)
- Log cache evictions (WARNING level)
- Log cache-related errors (SEVERE level)

---

## Documentation Updates

### Files to Update

1. **CLAUDE.md**
   - Add cache architecture section
   - Document cache service usage
   - Update repository pattern with caching
   - Add cache configuration guide

2. **README.md** (user-facing)
   - Explain cache behavior (brief, user-friendly)
   - Mention offline + cache benefits

3. **FAQ.md**
   - Q: "Why is data sometimes stale?"
   - Q: "How do I clear the cache?"
   - Q: "Does caching use more storage?"

4. **test/README.md**
   - Add cache testing guidelines
   - Example cache test patterns

---

## Open Questions & Considerations

### Questions to Resolve

1. **Should cache survive app restarts?**
   - ✅ Yes: Persistent cache in SQLite
   - ❌ No: In-memory cache only
   - **Decision**: Yes (persistent) - Better UX, works with existing Drift infrastructure

2. **Should users be able to configure TTL?**
   - ✅ Yes: Add settings for "Aggressive/Balanced/Conservative" cache profiles
   - ❌ No: Fixed TTL values
   - **Decision**: No initially, can add later if requested

3. **Should we cache images/attachments?**
   - ✅ Yes: Cache transaction attachments
   - ❌ No: Too much storage
   - **Decision**: Phase 2 feature - start with entity data only

4. **How to handle sync conflicts with cached data?**
   - Use existing conflict resolution system
   - Invalidate affected caches after sync
   - **Decision**: Integrate with existing `ConflictResolver`

5. **Should cache be user-specific?**
   - Yes: Cache is tied to authenticated user
   - Separate cache per Firefly III instance
   - **Decision**: Clear cache on logout/account switch

### Edge Cases to Handle

1. **Large list queries** (e.g., 1000+ transactions)
   - Implement pagination-aware caching
   - Cache pages separately
   - Consider query parameter hashing

2. **Rapidly changing data** (e.g., account balances)
   - Use shorter TTL for volatile data
   - Implement push notifications for real-time updates (future)

3. **Multi-device sync**
   - Current cache is device-local
   - May be stale if user edits on web
   - Accept as trade-off (background refresh will update)

4. **Storage limits on low-end devices**
   - Implement LRU eviction
   - Make cache size configurable
   - Monitor and warn if storage critically low

---

## Conclusion

This plan transforms Waterfly III from an **offline-first** architecture to a **cache-first** architecture, significantly improving performance and user experience while maintaining robust offline support. The implementation uses existing packages (`drift`, `rxdart`, `synchronized`, `retry`) and follows the project's philosophy of comprehensive, production-ready implementations.

**Key Benefits**:
- ✅ 70-80% reduction in API calls
- ✅ 50-70% faster UI response times
- ✅ Better offline experience (cache available immediately)
- ✅ Reduced bandwidth usage
- ✅ Maintains all existing offline functionality
- ✅ Graceful degradation (falls back to API if cache issues)

**Timeline**: 6 weeks for full implementation and testing

**Next Steps**: Begin Phase 1 - Foundation implementation
