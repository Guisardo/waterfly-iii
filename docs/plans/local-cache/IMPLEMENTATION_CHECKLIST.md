# Cache Implementation Checklist

## Overview

This checklist provides a detailed, step-by-step guide for implementing the local database cache system in Waterfly III. Each phase includes concrete tasks with acceptance criteria to ensure thorough implementation.

---

## Pre-Implementation Setup

### Prerequisites

- [ ] Read `README.md` - Understand cache architecture and strategy
- [ ] Read `INVALIDATION_RULES.md` - Understand invalidation cascades
- [ ] Review existing codebase:
  - [ ] `lib/data/repositories/base_repository.dart` - Understand repository pattern
  - [ ] `lib/data/local/database/database.dart` - Understand Drift setup
  - [ ] `lib/services/sync/sync_manager.dart` - Understand sync system
  - [ ] `lib/providers/connectivity_provider.dart` - Understand network monitoring
- [ ] Set up development environment:
  - [ ] Flutter version: stable channel
  - [ ] Dependencies: `flutter pub get`
  - [ ] Code generation: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Create feature branch: `git checkout -b feature/local-cache-system`

---

## Phase 1: Foundation (Week 1)

### 1.1 Cache Metadata Table

**File**: `lib/data/local/database/cache_metadata_table.dart`

- [ ] Create Drift table definition:
  - [ ] `entityType` column (text, primary key part 1)
  - [ ] `entityId` column (text, primary key part 2)
  - [ ] `cachedAt` column (datetime)
  - [ ] `lastAccessedAt` column (datetime)
  - [ ] `ttlSeconds` column (integer)
  - [ ] `isInvalidated` column (boolean, default false)
  - [ ] `etag` column (text, nullable)
  - [ ] `queryHash` column (text, nullable)
  - [ ] Define composite primary key: `{entityType, entityId}`

- [ ] Add indexes:
  - [ ] Index on `entityType`
  - [ ] Index on `isInvalidated, cachedAt`
  - [ ] Index on `cachedAt, ttlSeconds`

- [ ] Add to AppDatabase in `lib/data/local/database/database.dart`:
  ```dart
  @DriftDatabase(tables: [
    // ... existing tables
    CacheMetadataTable,
  ])
  class AppDatabase extends _$AppDatabase {
    // ... existing code
  }
  ```

- [ ] Run code generation: `dart run build_runner build --delete-conflicting-outputs`
- [ ] Verify generated code in `lib/data/local/database/database.g.dart`

**Acceptance Criteria**:
- ✅ Table schema matches specification
- ✅ Indexes created successfully
- ✅ Code generation completes without errors
- ✅ App compiles and runs with new table

---

### 1.2 Database Migration

**File**: `lib/data/local/database/database.dart`

- [ ] Increment schema version:
  ```dart
  @override
  int get schemaVersion => 3; // Increment from current version
  ```

- [ ] Add migration in `onUpgrade`:
  ```dart
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 3) {
        // Create cache_metadata table
        await m.createTable(cacheMetadataTable);

        // Create indexes
        await m.createIndex(Index(
          'cache_by_type',
          'CREATE INDEX cache_by_type ON cache_metadata(entity_type)',
        ));
        // ... more indexes

        log.info('Database migrated from v$from to v$to: cache_metadata table added');
      }
    },
  );
  ```

- [ ] Test migration:
  - [ ] Fresh install (schema v3)
  - [ ] Upgrade from previous version (v2 → v3)
  - [ ] Verify table created successfully
  - [ ] Verify indexes created successfully

**Acceptance Criteria**:
- ✅ Migration runs successfully on fresh install
- ✅ Migration runs successfully on existing installs
- ✅ No data loss during migration
- ✅ Migration logged correctly

---

### 1.3 Cache TTL Configuration

**File**: `lib/config/cache_ttl_config.dart`

- [ ] Create configuration class with TTL constants:
  - [ ] Transaction TTL: 5 minutes
  - [ ] Transaction list TTL: 3 minutes
  - [ ] Account TTL: 15 minutes
  - [ ] Account list TTL: 10 minutes
  - [ ] Budget TTL: 15 minutes
  - [ ] Budget list TTL: 10 minutes
  - [ ] Category TTL: 1 hour
  - [ ] Category list TTL: 1 hour
  - [ ] Currency TTL: 24 hours
  - [ ] Currency list TTL: 24 hours
  - [ ] Piggy bank TTL: 2 hours
  - [ ] Bill TTL: 1 hour
  - [ ] User profile TTL: 12 hours
  - [ ] Dashboard TTL: 5 minutes
  - [ ] Chart TTL: 10 minutes

- [ ] Implement `getTtl(String entityType)` method
- [ ] Add comprehensive documentation explaining rationale for each TTL
- [ ] Add ability to override TTL per entity type (optional)

**Acceptance Criteria**:
- ✅ All entity types have defined TTL
- ✅ TTL values are reasonable (not too short, not too long)
- ✅ Documentation explains TTL choices
- ✅ Method returns correct TTL for each entity type

---

### 1.4 Cache Service Implementation

**File**: `lib/services/cache/cache_service.dart`

- [ ] Create CacheService class:
  - [ ] Constructor with `AppDatabase` dependency
  - [ ] Logger instance
  - [ ] Synchronized lock for thread safety
  - [ ] RxDart PublishSubject for invalidation streams

- [ ] Implement core methods:
  - [ ] `get<T>()` - Cache-first retrieval with stale-while-revalidate
  - [ ] `set<T>()` - Store data with metadata
  - [ ] `invalidate()` - Invalidate specific entry
  - [ ] `invalidateType()` - Invalidate all entries of a type
  - [ ] `invalidateRelated()` - Cascade invalidation
  - [ ] `isFresh()` - Check cache freshness
  - [ ] `getStats()` - Cache statistics
  - [ ] `cleanExpired()` - Clean expired entries
  - [ ] `clearAll()` - Nuclear option

- [ ] Implement cache key generation:
  - [ ] Hash query parameters with `crypto` package
  - [ ] Sort parameters for consistent hashing
  - [ ] Handle null/empty filters

- [ ] Implement background refresh:
  - [ ] Fire-and-forget async refresh
  - [ ] Use `retry` package for resilience
  - [ ] Emit RxDart events on completion
  - [ ] Handle errors gracefully

- [ ] Add comprehensive logging:
  - [ ] Log cache hits/misses (INFO level)
  - [ ] Log freshness checks (FINE level)
  - [ ] Log invalidations (INFO level)
  - [ ] Log background refreshes (INFO level)
  - [ ] Log errors (SEVERE level with stack traces)

**Acceptance Criteria**:
- ✅ All methods implemented with full error handling
- ✅ Thread-safe with `synchronized` package
- ✅ Comprehensive logging throughout
- ✅ RxDart streams emit events correctly
- ✅ Background refresh works without blocking

**Test Coverage**:
- [ ] Unit tests in `test/services/cache/cache_service_test.dart`:
  - [ ] Test cache hit (fresh data)
  - [ ] Test cache miss (no data)
  - [ ] Test stale data with background refresh
  - [ ] Test invalidation
  - [ ] Test type invalidation
  - [ ] Test freshness check
  - [ ] Test TTL expiration
  - [ ] Test thread safety (concurrent access)
  - [ ] Test cache statistics
  - [ ] Target: >90% coverage

---

### 1.5 Cache Invalidation Rules

**File**: `lib/services/cache/cache_invalidation_rules.dart`

- [ ] Create CacheInvalidationRules static class
- [ ] Implement invalidation methods:
  - [ ] `onTransactionMutation()` - Comprehensive transaction invalidation
  - [ ] `onAccountMutation()` - Account invalidation with cascade
  - [ ] `onBudgetMutation()` - Budget invalidation
  - [ ] `onCategoryMutation()` - Category invalidation
  - [ ] `onBillMutation()` - Bill invalidation
  - [ ] `onPiggyBankMutation()` - Piggy bank invalidation
  - [ ] `onCurrencyMutation()` - Nuclear currency invalidation
  - [ ] `onTagMutation()` - Tag invalidation
  - [ ] `onSyncComplete()` - Post-sync invalidation

- [ ] Implement entity dependency graph logic
- [ ] Add comprehensive logging for each invalidation
- [ ] Add batch invalidation support

**Acceptance Criteria**:
- ✅ All entity types have invalidation rules
- ✅ Cascade invalidation works correctly
- ✅ Logging shows invalidation cascades
- ✅ Performance is acceptable (use batch operations)

**Test Coverage**:
- [ ] Unit tests in `test/services/cache/cache_invalidation_rules_test.dart`:
  - [ ] Test transaction invalidation cascades
  - [ ] Test account deletion invalidation
  - [ ] Test budget invalidation
  - [ ] Test category invalidation
  - [ ] Test sync-triggered invalidation
  - [ ] Target: >85% coverage

---

### 1.6 Cache Models

**File**: `lib/models/cache/cache_result.dart`

- [ ] Create `CacheResult<T>` model:
  ```dart
  class CacheResult<T> {
    final T? data;
    final CacheSource source; // enum: cache, api
    final bool isFresh;
    final DateTime? cachedAt;
  }
  ```

**File**: `lib/models/cache/cache_stats.dart`

- [ ] Create `CacheStats` model:
  ```dart
  class CacheStats {
    final int totalRequests;
    final int cacheHits;
    final int cacheMisses;
    final int staleServed;
    final int backgroundRefreshes;
    final int evictions;
    final double hitRate;
    final int averageAgeSeconds;
    final int totalCacheSizeMB;
    final Map<String, int> hitsByEntityType;
  }
  ```

**File**: `lib/models/cache/cache_invalidation_event.dart`

- [ ] Create `CacheInvalidationEvent` model for RxDart streams:
  ```dart
  class CacheInvalidationEvent {
    final String entityType;
    final String entityId;
    final CacheEventType eventType; // enum: invalidated, refreshed
    final dynamic data;
    final DateTime timestamp;
  }
  ```

**Acceptance Criteria**:
- ✅ Models are immutable
- ✅ Models have comprehensive documentation
- ✅ Models are serializable if needed

---

### Phase 1 Milestone

**Deliverables**:
- ✅ Cache metadata table created and migrated
- ✅ CacheService fully implemented with >90% test coverage
- ✅ Cache invalidation rules implemented with >85% test coverage
- ✅ TTL configuration defined
- ✅ Cache models created

**Validation**:
- [ ] Run all tests: `flutter test`
- [ ] Verify test coverage: `flutter test --coverage`
- [ ] Code generation successful: `dart run build_runner build --delete-conflicting-outputs`
- [ ] App compiles: `flutter run`
- [ ] Code analysis passes: `flutter analyze`

---

## Phase 2: Repository Integration (Week 2)

### 2.1 Update BaseRepository

**File**: `lib/data/repositories/base_repository.dart`

- [ ] Add `CacheService` dependency:
  ```dart
  abstract class BaseRepository<T> {
    final FireflyService apiService;
    final AppDatabase database;
    final CacheService cacheService; // NEW
    final Logger log;

    BaseRepository({
      required this.apiService,
      required this.database,
      required this.cacheService,
    });
  }
  ```

- [ ] Add abstract cache configuration getters:
  ```dart
  String get _entityType; // e.g., 'transaction'
  Duration get _cacheTtl; // e.g., Duration(minutes: 5)
  Duration get _collectionCacheTtl;
  ```

- [ ] Modify `getById()` method:
  - [ ] Use `cacheService.get()` with stale-while-revalidate
  - [ ] Pass entity type, ID, fetcher function, TTL
  - [ ] Support `forceRefresh` parameter
  - [ ] Support `backgroundRefresh` parameter
  - [ ] Add comprehensive logging

- [ ] Modify `getAll()` method:
  - [ ] Generate cache key from filters/parameters
  - [ ] Use `cacheService.get()` for collection query
  - [ ] Support `forceRefresh` parameter
  - [ ] Handle pagination (cache pages separately)
  - [ ] Add comprehensive logging

- [ ] Modify `create()` method:
  - [ ] Create entity via API
  - [ ] Store in local DB
  - [ ] Store in cache with metadata
  - [ ] Trigger invalidation via `CacheInvalidationRules`
  - [ ] Add comprehensive logging

- [ ] Modify `update()` method:
  - [ ] Update entity via API
  - [ ] Update in local DB
  - [ ] Update in cache
  - [ ] Trigger invalidation via `CacheInvalidationRules`
  - [ ] Add comprehensive logging

- [ ] Modify `delete()` method:
  - [ ] Delete entity via API
  - [ ] Delete from local DB
  - [ ] Invalidate cache entry
  - [ ] Trigger cascade invalidation via `CacheInvalidationRules`
  - [ ] Add comprehensive logging

- [ ] Add helper method `_generateCollectionCacheKey()`:
  - [ ] Use `crypto` package to hash filters
  - [ ] Sort parameters for consistent hashing
  - [ ] Return stable cache key

**Acceptance Criteria**:
- ✅ BaseRepository uses cache-first strategy
- ✅ All CRUD operations integrate with cache
- ✅ Comprehensive logging throughout
- ✅ Cache invalidation triggers correctly

**Test Coverage**:
- [ ] Update tests in `test/data/repositories/base_repository_test.dart`:
  - [ ] Test cache hit on getById
  - [ ] Test cache miss on getById
  - [ ] Test cache hit on getAll
  - [ ] Test cache invalidation on create
  - [ ] Test cache invalidation on update
  - [ ] Test cache invalidation on delete
  - [ ] Test force refresh bypasses cache
  - [ ] Target: >85% coverage

---

### 2.2 Update TransactionRepository

**File**: `lib/data/repositories/transaction_repository.dart`

- [ ] Add CacheService to constructor
- [ ] Implement abstract cache configuration:
  ```dart
  @override
  String get _entityType => 'transaction';

  @override
  Duration get _cacheTtl => CacheTtlConfig.transactions;

  @override
  Duration get _collectionCacheTtl => CacheTtlConfig.transactionsList;
  ```

- [ ] Implement `_invalidateRelatedCaches()`:
  ```dart
  @override
  Future<void> _invalidateRelatedCaches(Transaction transaction) async {
    await CacheInvalidationRules.onTransactionMutation(
      cacheService,
      transaction,
      MutationType.create, // or update/delete
    );
  }
  ```

- [ ] Test thoroughly:
  - [ ] Test transaction creation invalidates accounts, budgets, categories
  - [ ] Test transaction update refreshes cache
  - [ ] Test transaction deletion cascades properly
  - [ ] Test transaction list caching with filters

**Acceptance Criteria**:
- ✅ TransactionRepository uses cache-first
- ✅ Invalidation cascades to related entities
- ✅ Tests pass with >85% coverage

---

### 2.3 Update AccountRepository

**File**: `lib/data/repositories/account_repository.dart`

- [ ] Add CacheService to constructor
- [ ] Implement cache configuration (TTL: 15 min)
- [ ] Implement invalidation rules
- [ ] Test thoroughly

**Acceptance Criteria**:
- ✅ AccountRepository uses cache-first
- ✅ Tests pass with >85% coverage

---

### 2.4 Update BudgetRepository

**File**: `lib/data/repositories/budget_repository.dart`

- [ ] Add CacheService to constructor
- [ ] Implement cache configuration (TTL: 15 min)
- [ ] Implement invalidation rules
- [ ] Test thoroughly

**Acceptance Criteria**:
- ✅ BudgetRepository uses cache-first
- ✅ Tests pass with >85% coverage

---

### 2.5 Update CategoryRepository

**File**: `lib/data/repositories/category_repository.dart`

- [ ] Add CacheService to constructor
- [ ] Implement cache configuration (TTL: 1 hour)
- [ ] Implement invalidation rules
- [ ] Test thoroughly

**Acceptance Criteria**:
- ✅ CategoryRepository uses cache-first
- ✅ Tests pass with >85% coverage

---

### 2.6 Update BillRepository

**File**: `lib/data/repositories/bill_repository.dart`

- [ ] Add CacheService to constructor
- [ ] Implement cache configuration (TTL: 1 hour)
- [ ] Implement invalidation rules
- [ ] Test thoroughly

**Acceptance Criteria**:
- ✅ BillRepository uses cache-first
- ✅ Tests pass with >85% coverage

---

### 2.7 Update PiggyBankRepository

**File**: `lib/data/repositories/piggy_bank_repository.dart`

- [ ] Add CacheService to constructor
- [ ] Implement cache configuration (TTL: 2 hours)
- [ ] Implement invalidation rules
- [ ] Test thoroughly

**Acceptance Criteria**:
- ✅ PiggyBankRepository uses cache-first
- ✅ Tests pass with >85% coverage

---

### 2.8 Update App Initialization

**File**: `lib/app.dart`

- [ ] Initialize CacheService in MultiProvider:
  ```dart
  MultiProvider(
    providers: [
      // ... existing providers
      Provider<CacheService>(
        create: (context) => CacheService(
          database: context.read<AppDatabase>(),
        ),
      ),
      // Repositories now get CacheService
      Provider<TransactionRepository>(
        create: (context) => TransactionRepository(
          apiService: context.read<FireflyService>(),
          database: context.read<AppDatabase>(),
          cacheService: context.read<CacheService>(),
        ),
      ),
      // ... more repositories
    ],
  )
  ```

- [ ] Verify dependency injection works correctly

**Acceptance Criteria**:
- ✅ CacheService available throughout app
- ✅ All repositories receive CacheService
- ✅ App starts without errors

---

### 2.9 Cache Statistics Tracking

**File**: `lib/services/cache/cache_service.dart`

- [ ] Implement statistics tracking:
  - [ ] Count cache hits
  - [ ] Count cache misses
  - [ ] Count stale served
  - [ ] Count background refreshes
  - [ ] Calculate hit rate
  - [ ] Track hits by entity type

- [ ] Implement `getStats()` method:
  ```dart
  Future<CacheStats> getStats() async {
    // Query cache metadata
    // Calculate statistics
    // Return CacheStats model
  }
  ```

**Acceptance Criteria**:
- ✅ Statistics tracked accurately
- ✅ getStats() returns correct data
- ✅ Statistics logged periodically (INFO level)

---

### Phase 2 Milestone

**Deliverables**:
- ✅ BaseRepository updated with caching
- ✅ All 6 repositories using cache-first strategy
- ✅ Cache statistics tracking implemented
- ✅ All repository tests updated and passing

**Validation**:
- [ ] Run all tests: `flutter test`
- [ ] Verify cache hit rate in logs
- [ ] Manually test app - verify data loads from cache
- [ ] Check performance improvement (faster load times)

---

## Phase 3: Background Refresh (Week 3)

### 3.1 RxDart Stream Integration

**File**: `lib/services/cache/cache_service.dart`

- [ ] Verify RxDart streams work correctly:
  - [ ] PublishSubject emits events
  - [ ] Subscribers receive events
  - [ ] Events have correct data

- [ ] Test stream subscription/unsubscription:
  - [ ] No memory leaks
  - [ ] Streams cleaned up properly

**Acceptance Criteria**:
- ✅ RxDart streams emit cache events
- ✅ No memory leaks from unclosed streams

---

### 3.2 CacheStreamBuilder Widget

**File**: `lib/widgets/cache_stream_builder.dart`

- [ ] Create stateful widget that:
  - [ ] Takes fetcher function
  - [ ] Takes builder function
  - [ ] Subscribes to cache invalidation stream
  - [ ] Rebuilds UI on cache updates
  - [ ] Handles loading states
  - [ ] Handles error states
  - [ ] Shows staleness indicator (optional)

- [ ] Implement lifecycle management:
  - [ ] Subscribe in `initState()`
  - [ ] Unsubscribe in `dispose()`
  - [ ] Handle widget updates

- [ ] Add comprehensive documentation with examples

**Acceptance Criteria**:
- ✅ Widget rebuilds on cache refresh
- ✅ No memory leaks
- ✅ Handles errors gracefully
- ✅ Comprehensive documentation

**Test Coverage**:
- [ ] Widget tests in `test/widgets/cache_stream_builder_test.dart`:
  - [ ] Test initial load
  - [ ] Test cache update triggers rebuild
  - [ ] Test error handling
  - [ ] Test loading states
  - [ ] Target: >80% coverage

---

### 3.3 Update UI Pages

**Example: Account Detail Page** (`lib/pages/accounts/account_detail.dart`)

- [ ] Replace existing data fetching with CacheStreamBuilder:
  ```dart
  CacheStreamBuilder<Account>(
    entityType: 'account',
    entityId: accountId,
    fetcher: () => accountRepository.getById(accountId),
    builder: (context, account, isFresh) {
      if (account == null) {
        return LoadingWidget();
      }

      return Column(
        children: [
          if (!isFresh)
            Text('Refreshing...', style: TextStyle(color: Colors.orange)),
          AccountCard(account: account),
        ],
      );
    },
  )
  ```

- [ ] Test:
  - [ ] Initial load shows data instantly (if cached)
  - [ ] Background refresh updates UI smoothly
  - [ ] No flickering or jarring transitions

**Acceptance Criteria**:
- ✅ UI uses CacheStreamBuilder
- ✅ Background refresh updates UI
- ✅ Smooth user experience

---

### 3.4 Cache Warming Service

**File**: `lib/services/cache/cache_warming_service.dart`

- [ ] Create cache warming service:
  - [ ] Pre-fetch frequently accessed data on app start
  - [ ] Pre-fetch related data (e.g., when viewing account, pre-fetch transactions)
  - [ ] Use background threads to avoid blocking UI
  - [ ] Respect network conditions (WiFi vs cellular)

- [ ] Implement warming strategies:
  - [ ] `warmOnStartup()` - Pre-fetch dashboard, accounts, recent transactions
  - [ ] `warmRelated()` - Pre-fetch related entities
  - [ ] `warmOnIdle()` - Pre-fetch during idle periods

- [ ] Add comprehensive logging

**Acceptance Criteria**:
- ✅ Cache warming happens in background
- ✅ Doesn't block UI
- ✅ Improves perceived performance

**Test Coverage**:
- [ ] Unit tests in `test/services/cache/cache_warming_service_test.dart`:
  - [ ] Test startup warming
  - [ ] Test related entity warming
  - [ ] Test network condition awareness
  - [ ] Target: >80% coverage

---

### 3.5 Integrate Cache Warming

**File**: `lib/main.dart`

- [ ] Initialize cache warming on app start:
  ```dart
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();

    // ... existing initialization

    // Warm cache in background
    final cacheWarming = CacheWarmingService(
      cacheService: cacheService,
      repositories: repositories,
    );

    // Fire-and-forget warming
    unawaited(cacheWarming.warmOnStartup());

    runApp(MyApp());
  }
  ```

**Acceptance Criteria**:
- ✅ Cache warming runs on startup
- ✅ Doesn't delay app startup
- ✅ Logs warming progress

---

### Phase 3 Milestone

**Deliverables**:
- ✅ Background refresh fully functional
- ✅ CacheStreamBuilder widget created and tested
- ✅ UI pages updated to use cache streams
- ✅ Cache warming service implemented

**Validation**:
- [ ] Run all tests: `flutter test`
- [ ] Manually test background refresh in app
- [ ] Verify UI updates smoothly on cache refresh
- [ ] Check cache warming logs on startup

---

## Phase 4: Advanced Features (Week 4)

### 4.1 ETag Support

**File**: `lib/services/cache/cache_service.dart`

- [ ] Add ETag handling to `get()` method:
  - [ ] Pass ETag to API request (If-None-Match header)
  - [ ] Handle 304 Not Modified response
  - [ ] Update `lastAccessedAt` on 304 (cache still valid)
  - [ ] Log ETag hits for metrics

- [ ] Store ETags in cache metadata:
  - [ ] Extract ETag from API response headers
  - [ ] Store in `etag` column
  - [ ] Pass ETag on subsequent requests

**Acceptance Criteria**:
- ✅ ETags stored correctly
- ✅ 304 responses handled properly
- ✅ Bandwidth savings measurable

**Test Coverage**:
- [ ] Unit tests for ETag handling:
  - [ ] Test 304 Not Modified
  - [ ] Test ETag storage
  - [ ] Test ETag passing to API
  - [ ] Target: >85% coverage

---

### 4.2 Query Parameter Hashing

**File**: `lib/services/cache/cache_service.dart`

- [ ] Implement robust query hashing:
  - [ ] Sort parameters alphabetically
  - [ ] Handle nested objects/arrays
  - [ ] Use SHA-256 from `crypto` package
  - [ ] Store hash in `queryHash` column

- [ ] Test hash consistency:
  - [ ] Same parameters → same hash (different order)
  - [ ] Different parameters → different hash

**Acceptance Criteria**:
- ✅ Hash generation is deterministic
- ✅ Cache hits work for identical queries with different param order
- ✅ Comprehensive tests

---

### 4.3 LRU Eviction

**File**: `lib/services/cache/cache_service.dart`

- [ ] Implement cache size calculation:
  - [ ] Query total cache size from database
  - [ ] Calculate size of cached data

- [ ] Implement LRU eviction:
  - [ ] Sort by `lastAccessedAt` (ascending)
  - [ ] Evict oldest entries first
  - [ ] Stop when under size limit
  - [ ] Log eviction metrics

- [ ] Add configurable cache size limit:
  - [ ] Default: 100MB
  - [ ] Settable via settings

- [ ] Run eviction:
  - [ ] Periodically (e.g., every 30 minutes)
  - [ ] When cache size exceeds limit
  - [ ] On low memory warning (if possible)

**Acceptance Criteria**:
- ✅ LRU eviction keeps cache under limit
- ✅ Least recently used entries evicted first
- ✅ Eviction logged comprehensively

**Test Coverage**:
- [ ] Unit tests for LRU eviction:
  - [ ] Test eviction when limit exceeded
  - [ ] Test eviction order (oldest first)
  - [ ] Test eviction stops at limit
  - [ ] Target: >85% coverage

---

### 4.4 Cache Debug UI

**File**: `lib/pages/settings/cache_debug.dart`

- [ ] Create debug page (only in debug mode):
  - [ ] Show cache statistics (hit rate, size, entries)
  - [ ] List all cache entries with details:
    - Entity type, ID, cached time, TTL, staleness
  - [ ] Search/filter cache entries
  - [ ] Button to clear specific entry
  - [ ] Button to clear all cache
  - [ ] Button to manually trigger eviction

- [ ] Add navigation to debug page:
  - [ ] In settings page, add "Cache Debug" option (debug mode only)

**Acceptance Criteria**:
- ✅ Debug UI shows accurate cache info
- ✅ Clear buttons work correctly
- ✅ Only accessible in debug mode

---

### Phase 4 Milestone

**Deliverables**:
- ✅ ETag support implemented
- ✅ Query parameter hashing implemented
- ✅ LRU eviction implemented
- ✅ Cache debug UI created

**Validation**:
- [ ] Test ETag bandwidth savings
- [ ] Test query hash consistency
- [ ] Test LRU eviction with large cache
- [ ] Manually test debug UI

---

## Phase 5: Testing & Optimization (Week 5)

### 5.1 Comprehensive Unit Tests

- [ ] CacheService tests (>90% coverage):
  - [ ] All public methods tested
  - [ ] Edge cases covered
  - [ ] Error scenarios tested
  - [ ] Thread safety tested

- [ ] CacheInvalidationRules tests (>85% coverage):
  - [ ] All entity types tested
  - [ ] Cascade invalidation tested
  - [ ] Sync invalidation tested

- [ ] Repository tests (>85% coverage):
  - [ ] Cache integration tested for all repos
  - [ ] CRUD operations with cache tested

**Target**: Overall >85% test coverage for cache components

---

### 5.2 Widget Tests

- [ ] CacheStreamBuilder tests (>80% coverage):
  - [ ] Initial load
  - [ ] Cache update
  - [ ] Error handling
  - [ ] Loading states

- [ ] Cache debug UI tests (>80% coverage):
  - [ ] UI rendering
  - [ ] Button actions
  - [ ] Data display

**Target**: >80% coverage for cache widgets

---

### 5.3 Integration Tests

**File**: `integration_test/cache_flow_test.dart`

- [ ] Test complete cache flows:
  - [ ] Fresh install → fetch → cache → re-fetch (cache hit)
  - [ ] Offline → cached data served → online → background refresh
  - [ ] Create transaction → invalidation → re-fetch (cache miss)
  - [ ] Force refresh → bypass cache → new data

- [ ] Test sync integration:
  - [ ] Sync completes → cache invalidated → UI updated

- [ ] Test cache warming:
  - [ ] App start → cache warmed → data instantly available

**Target**: >70% integration test coverage

---

### 5.4 Performance Benchmarking

**File**: `test/performance/cache_benchmark_test.dart`

- [ ] Benchmark scenarios:
  - [ ] Cold start (no cache) vs warm start (cached)
  - [ ] List load with 100 items (cached vs not)
  - [ ] Detail view navigation (cached vs not)
  - [ ] API call count (with cache vs without)
  - [ ] Bandwidth usage (with cache vs without)

- [ ] Measure metrics:
  - [ ] Load time (milliseconds)
  - [ ] API call count
  - [ ] Bandwidth (bytes)
  - [ ] Memory usage
  - [ ] Database query time

- [ ] Document results in `docs/plans/local-cache/BENCHMARK_RESULTS.md`

**Target Metrics**:
- ✅ 70-80% API call reduction
- ✅ 50-70% load time improvement
- ✅ 60-70% bandwidth reduction
- ✅ Cache hit rate >75%

---

### 5.5 Load Testing

**File**: `test/performance/cache_load_test.dart`

- [ ] Test with large datasets:
  - [ ] 1000+ transactions
  - [ ] 50+ accounts
  - [ ] 20+ budgets

- [ ] Test concurrent access:
  - [ ] Multiple widgets requesting same data
  - [ ] Concurrent invalidations
  - [ ] Thread safety validation

- [ ] Test memory pressure:
  - [ ] Cache eviction under memory constraints
  - [ ] No memory leaks during extended use

**Acceptance Criteria**:
- ✅ Handles large datasets efficiently
- ✅ No crashes under load
- ✅ Memory usage within acceptable limits

---

### 5.6 Code Review & Optimization

- [ ] Code review checklist:
  - [ ] All code follows Dart style guide
  - [ ] Comprehensive documentation
  - [ ] No TODOs or FIXMEs
  - [ ] Logging appropriate (not too verbose, not too quiet)
  - [ ] Error handling comprehensive
  - [ ] Performance optimized (no N+1 queries, batch operations)

- [ ] Performance optimization:
  - [ ] Optimize database queries
  - [ ] Use Drift batch operations where possible
  - [ ] Minimize redundant invalidations
  - [ ] Optimize RxDart stream subscriptions

---

### Phase 5 Milestone

**Deliverables**:
- ✅ Comprehensive test suite (>85% coverage)
- ✅ Integration tests passing
- ✅ Performance benchmarks documented
- ✅ Load tests passing
- ✅ Code optimized and reviewed

**Validation**:
- [ ] Run full test suite: `flutter test`
- [ ] Generate coverage report: `flutter test --coverage`
- [ ] Verify coverage >85%
- [ ] Run benchmarks and verify targets met
- [ ] Code analysis passes: `flutter analyze`

---

## Phase 6: Migration & Rollout (Week 6)

### 6.1 Database Migration Testing

- [ ] Test migration scenarios:
  - [ ] Fresh install (new users)
  - [ ] Upgrade from previous version (existing users)
  - [ ] Migration with large database (1000+ transactions)
  - [ ] Migration failure recovery

- [ ] Verify:
  - [ ] No data loss
  - [ ] Schema version updated correctly
  - [ ] Indexes created successfully
  - [ ] App works after migration

**Acceptance Criteria**:
- ✅ Migration successful in all scenarios
- ✅ Zero data loss
- ✅ Comprehensive migration logging

---

### 6.2 Feature Flag Implementation

**File**: `lib/providers/settings_provider.dart`

- [ ] Add cache enable/disable setting:
  ```dart
  bool _enableCaching = true;

  bool get enableCaching => _enableCaching;

  Future<void> setEnableCaching(bool value) async {
    _enableCaching = value;
    await _prefs.setBool('enable_caching', value);
    notifyListeners();

    if (!value) {
      await _cacheService.clearAll();
    }
  }
  ```

- [ ] Add to settings UI:
  - [ ] Toggle switch in developer settings
  - [ ] Description explaining feature
  - [ ] Warning when disabling

- [ ] Integrate in repositories:
  - [ ] Check `enableCaching` before using cache
  - [ ] Fall back to direct API if disabled

**Acceptance Criteria**:
- ✅ Feature flag works correctly
- ✅ Cache can be disabled via settings
- ✅ Disabling cache clears all cached data
- ✅ App works correctly with cache disabled

---

### 6.3 Documentation Updates

**Files to Update**:

- [ ] `CLAUDE.md`:
  - [ ] Add cache architecture section
  - [ ] Document CacheService usage
  - [ ] Update repository pattern documentation
  - [ ] Add cache debugging guide
  - [ ] Update package list with `crypto`

- [ ] `README.md` (user-facing):
  - [ ] Mention cache for better performance
  - [ ] Explain offline + cache benefits (brief)

- [ ] `FAQ.md`:
  - [ ] Q: "Why is data sometimes stale?"
  - [ ] Q: "How do I clear the cache?"
  - [ ] Q: "Does caching use more storage?"
  - [ ] Q: "Why is data not updating?"

- [ ] `test/README.md`:
  - [ ] Add cache testing guidelines
  - [ ] Example cache test patterns

**Acceptance Criteria**:
- ✅ All documentation updated
- ✅ Documentation accurate and comprehensive
- ✅ User-facing documentation clear and helpful

---

### 6.4 Beta Release Preparation

- [ ] Create release notes:
  - [ ] New cache system
  - [ ] Performance improvements
  - [ ] Known limitations
  - [ ] How to report issues

- [ ] Prepare rollback plan:
  - [ ] Document rollback steps
  - [ ] Test rollback procedure
  - [ ] Feature flag for quick disable

- [ ] Beta testing checklist:
  - [ ] Fresh install testing
  - [ ] Upgrade testing
  - [ ] Performance testing
  - [ ] Crash monitoring setup

**Acceptance Criteria**:
- ✅ Release notes comprehensive
- ✅ Rollback plan documented and tested
- ✅ Beta testing plan ready

---

### 6.5 Beta Testing

- [ ] Release to beta channel:
  - [ ] Google Play Beta
  - [ ] TestFlight (if iOS)
  - [ ] GitHub pre-release

- [ ] Monitor metrics:
  - [ ] Crash rate
  - [ ] Cache hit rate
  - [ ] API call reduction
  - [ ] User feedback

- [ ] Gather feedback:
  - [ ] Performance improvements
  - [ ] Any issues with stale data
  - [ ] Cache-related bugs

- [ ] Duration: 1-2 weeks

**Acceptance Criteria**:
- ✅ Beta release successful
- ✅ Crash rate acceptable (<1%)
- ✅ Positive user feedback
- ✅ Cache metrics meet targets

---

### 6.6 Production Rollout

- [ ] Gradual rollout strategy:
  - [ ] Week 1: 10% of users
  - [ ] Week 2: 50% of users (if no issues)
  - [ ] Week 3: 100% of users (if no issues)

- [ ] Monitor metrics closely:
  - [ ] Crash reports
  - [ ] Cache performance
  - [ ] User complaints
  - [ ] API server load

- [ ] Be ready to:
  - [ ] Rollback if critical issues
  - [ ] Disable cache via feature flag
  - [ ] Hotfix if needed

**Acceptance Criteria**:
- ✅ Production rollout successful
- ✅ Metrics within targets
- ✅ No critical issues
- ✅ Positive user feedback

---

### Phase 6 Milestone

**Deliverables**:
- ✅ Database migration tested and ready
- ✅ Feature flag implemented
- ✅ Documentation updated
- ✅ Beta release completed
- ✅ Production rollout in progress/complete

**Final Validation**:
- [ ] Cache system fully operational
- [ ] Performance targets met
- [ ] User satisfaction high
- [ ] No critical bugs
- [ ] Documentation complete

---

## Post-Implementation

### Monitoring & Maintenance

- [ ] Set up monitoring:
  - [ ] Cache hit rate alerts
  - [ ] Cache size alerts
  - [ ] Crash rate monitoring

- [ ] Regular maintenance:
  - [ ] Review cache metrics monthly
  - [ ] Adjust TTL values based on usage patterns
  - [ ] Optimize invalidation rules if needed

- [ ] User support:
  - [ ] Respond to cache-related issues
  - [ ] Update FAQ based on common questions

### Future Enhancements

- [ ] Consider implementing:
  - [ ] Image/attachment caching (Phase 7)
  - [ ] Push notifications for real-time updates
  - [ ] User-configurable TTL profiles
  - [ ] Cache preloading based on usage patterns
  - [ ] Differential sync (fetch only changed data)

---

## Success Criteria

### Technical Metrics

- ✅ API call reduction: 70-80%
- ✅ UI response time improvement: 50-70%
- ✅ Cache hit rate: >75%
- ✅ Bandwidth reduction: 60-70%
- ✅ Test coverage: >85% for cache components
- ✅ Zero cache-related crashes

### User Experience Metrics

- ✅ Positive user feedback on performance
- ✅ Reduced loading spinners (qualitative)
- ✅ Faster app feel (user surveys)
- ✅ Lower mobile data usage (user reports)

### Code Quality Metrics

- ✅ Code analysis passes: `flutter analyze`
- ✅ All tests pass: `flutter test`
- ✅ Documentation complete and accurate
- ✅ Code reviewed and approved

---

## Conclusion

This checklist provides a comprehensive, step-by-step guide for implementing the local database cache system. By following this checklist systematically, you'll ensure:

1. ✅ Thorough implementation with no missed steps
2. ✅ High code quality with comprehensive testing
3. ✅ Smooth rollout with minimal risk
4. ✅ Measurable performance improvements
5. ✅ Excellent user experience

**Estimated Timeline**: 6 weeks

**Next Step**: Begin Phase 1 - Foundation implementation
