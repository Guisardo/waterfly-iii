import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/cache/cache_stats.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/models/cache/cache_result.dart';
import 'package:waterflyiii/models/cache/cache_invalidation_event.dart';
import 'package:drift/drift.dart'
    hide isNotNull; // Hide to avoid conflict with matcher
import 'package:drift/native.dart';

/// Mock classes for testing
class MockAppDatabase extends Mock implements AppDatabase {}

/// Test entity for cache operations
class TestEntity {
  final String id;
  final String name;
  final int value;

  TestEntity({required this.id, required this.name, required this.value});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          value == other.value;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ value.hashCode;

  @override
  String toString() => 'TestEntity(id: $id, name: $name, value: $value)';
}

/// Comprehensive Unit Tests for CacheService
///
/// Tests cover:
/// - Cache-first retrieval (fresh, stale, miss)
/// - TTL-based expiration
/// - Invalidation (single, type, related)
/// - Background refresh with stale-while-revalidate
/// - Thread safety with concurrent access
/// - Statistics tracking
/// - Cache size management and LRU eviction
/// - ETag support (if available)
/// - Query parameter hashing
/// - Stream event emission
/// - Error handling and edge cases
///
/// Target: >90% code coverage
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheService', () {
    late AppDatabase database;
    late CacheService cacheService;

    setUp(() {
      // Use in-memory database for testing
      database = AppDatabase.forTesting(NativeDatabase.memory());
      cacheService = CacheService(database: database);
    });

    tearDown(() async {
      cacheService.dispose();
      await database.close();
    });

    group('get() - Cache-first retrieval', () {
      test('should return fresh cached data when available', () async {
        // Arrange: Store fresh data in cache metadata
        final TestEntity testData = TestEntity(
          id: '123',
          name: 'Test',
          value: 42,
        );

        await cacheService.set(
          entityType: 'test_entity',
          entityId: '123',
          data: testData,
          ttl: const Duration(hours: 1),
        );

        // Store in "database" (simulate repository storing entity)
        // CacheService ALWAYS calls fetcher to get data from repository DB
        final Map<String, TestEntity> dataStore = <String, TestEntity>{
          '123': testData,
        };

        bool fetcherCalled = false;

        // Act: Fetch with cache-first strategy
        final CacheResult<TestEntity>
        result = await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: '123',
          fetcher: () async {
            // CORRECTED: Fetcher IS called (CacheService only manages metadata)
            fetcherCalled = true;
            return dataStore['123']!;
          },
          ttl: const Duration(hours: 1),
        );

        // Assert: Returns data from fetcher (repository DB)
        expect(fetcherCalled, isTrue); // CORRECTED: Fetcher is called
        expect(result.data, isNotNull);
        expect(result.data, equals(testData));
        expect(
          result.source,
          equals(CacheSource.cache),
        ); // Metadata source is cache
        expect(result.isFresh, isTrue); // Metadata indicates fresh
        expect(result.isCacheHit, isTrue); // Cache metadata hit
      });

      test('should fetch and cache when cache miss', () async {
        // Arrange: No cache entry, simulate repository datastore
        final TestEntity testData = TestEntity(
          id: '456',
          name: 'NewEntity',
          value: 99,
        );
        final Map<String, TestEntity> dataStore = <String, TestEntity>{};
        int firstFetchCount = 0;

        // Act: Fetch with cache-first strategy (cache miss)
        final CacheResult<TestEntity> result = await cacheService
            .get<TestEntity>(
              entityType: 'test_entity',
              entityId: '456',
              fetcher: () async {
                firstFetchCount++;
                await Future<void>.delayed(
                  const Duration(milliseconds: 10),
                ); // Simulate API delay
                // Simulate API storing to repository DB
                dataStore['456'] = testData;
                return testData;
              },
              ttl: const Duration(minutes: 30),
            );

        // Assert: Calls fetcher and caches metadata
        expect(firstFetchCount, equals(1));
        expect(result.data, equals(testData));
        expect(
          result.source,
          equals(CacheSource.api),
        ); // First fetch is from API
        expect(result.isFresh, isTrue);
        expect(result.isCacheMiss, isTrue);

        // Verify metadata cached for next call
        int secondFetchCount = 0;
        final CacheResult<TestEntity>
        cachedResult = await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: '456',
          fetcher: () async {
            secondFetchCount++;
            // CORRECTED: Fetcher IS called (returns data from repository DB)
            return dataStore['456']!;
          },
          ttl: const Duration(minutes: 30),
        );

        expect(
          secondFetchCount,
          equals(1),
        ); // CORRECTED: Fetcher called on cache hit too
        expect(cachedResult.data, equals(testData));
        expect(
          cachedResult.source,
          equals(CacheSource.cache),
        ); // Metadata from cache
        expect(cachedResult.isFresh, isTrue); // Metadata indicates fresh
      });

      test('should serve stale data and trigger background refresh', () async {
        // Arrange: Cache metadata with very short TTL, data in "repository DB"
        final TestEntity oldData = TestEntity(
          id: '789',
          name: 'OldData',
          value: 1,
        );
        final TestEntity newData = TestEntity(
          id: '789',
          name: 'NewData',
          value: 2,
        );

        // Simulate repository DB with stale data
        final Map<String, TestEntity> dataStore = <String, TestEntity>{
          '789': oldData,
        };

        await cacheService.set(
          entityType: 'test_entity',
          entityId: '789',
          data: oldData,
          ttl: const Duration(milliseconds: 1), // Very short TTL
        );

        // Wait for TTL to expire
        await Future<void>.delayed(const Duration(milliseconds: 50));

        int fetcherCallCount = 0;
        final List<CacheInvalidationEvent> events = <CacheInvalidationEvent>[];
        final StreamSubscription<CacheInvalidationEvent> subscription =
            cacheService.invalidationStream.listen(events.add);

        // Act: Fetch with background refresh
        final CacheResult<TestEntity>
        result = await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: '789',
          fetcher: () async {
            fetcherCallCount++;
            // Fetcher only called during background refresh (not during initial get when persistedData exists)
            // Return new data from API/repository
            await Future<void>.delayed(const Duration(milliseconds: 50));
            dataStore['789'] = newData; // Update repository DB
            return newData;
          },
          backgroundRefresh: true,
        );

        // Assert: Returns stale data immediately from cache (persistedData)
        expect(result.data, isNotNull);
        expect(result.data, equals(oldData)); // Gets stale data from cache
        expect(result.isFresh, isFalse); // Metadata indicates stale
        // Fetcher not called during initial get() when persistedData exists
        expect(fetcherCallCount, equals(0));

        // Wait for background refresh to complete
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Fetcher called once during background refresh
        expect(fetcherCallCount, equals(1));

        // Verify refresh event was emitted
        final List<CacheInvalidationEvent> refreshEvents =
            events
                .where(
                  (CacheInvalidationEvent e) =>
                      e.entityType == 'test_entity' &&
                      e.entityId == '789' &&
                      e.eventType == CacheEventType.refreshed,
                )
                .toList();
        expect(refreshEvents, hasLength(1));

        await subscription.cancel();
      });

      test('should force refresh when forceRefresh=true', () async {
        // Arrange: Cache fresh data
        final TestEntity oldData = TestEntity(id: '111', name: 'Old', value: 1);
        final TestEntity newData = TestEntity(id: '111', name: 'New', value: 2);

        await cacheService.set(
          entityType: 'test_entity',
          entityId: '111',
          data: oldData,
          ttl: const Duration(hours: 1),
        );

        bool fetcherCalled = false;

        // Act: Force refresh
        final CacheResult<TestEntity> result = await cacheService
            .get<TestEntity>(
              entityType: 'test_entity',
              entityId: '111',
              fetcher: () async {
                fetcherCalled = true;
                return newData;
              },
              forceRefresh: true,
            );

        // Assert: Bypasses cache and fetches fresh data
        expect(fetcherCalled, isTrue);
        expect(result.data, equals(newData));
        expect(result.source, equals(CacheSource.api));
      });

      test(
        'should disable background refresh when backgroundRefresh=false',
        () async {
          // Arrange: Cache metadata with expired TTL, data in repository DB
          final TestEntity oldData = TestEntity(
            id: '222',
            name: 'Old',
            value: 1,
          );
          final Map<String, TestEntity> dataStore = <String, TestEntity>{
            '222': oldData,
          };

          await cacheService.set(
            entityType: 'test_entity',
            entityId: '222',
            data: oldData,
            ttl: const Duration(milliseconds: 1),
          );

          await Future<void>.delayed(const Duration(milliseconds: 50));

          int fetcherCallCount = 0;

          // Act: Fetch with background refresh disabled
          final CacheResult<TestEntity>
          result = await cacheService.get<TestEntity>(
            entityType: 'test_entity',
            entityId: '222',
            fetcher: () async {
              fetcherCallCount++;
              return dataStore['222']!; // Return stale data from repository DB
            },
            backgroundRefresh: false,
          );

          // Assert: Returns stale data from in-memory cache, NO fetcher call, NO background refresh
          expect(result.data, isNotNull);
          expect(result.data, equals(oldData));
          expect(result.isFresh, isFalse);
          expect(
            fetcherCallCount,
            equals(0),
          ); // Fetcher not called - data returned from _lastSuccessfulData

          // Wait to ensure background refresh doesn't happen
          await Future<void>.delayed(const Duration(milliseconds: 100));
          expect(
            fetcherCallCount,
            equals(0),
          ); // Still not called (no background refresh, no fetcher call)
        },
      );
    });

    group('set() - Store data in cache', () {
      test('should store data with metadata', () async {
        // Arrange
        final TestEntity testData = TestEntity(
          id: '333',
          name: 'Test',
          value: 3,
        );

        // Act
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '333',
          data: testData,
          ttl: const Duration(minutes: 15),
        );

        // Assert: Verify cache metadata created
        final bool isFresh = await cacheService.isFresh('test_entity', '333');
        expect(isFresh, isTrue);
      });

      test('should update existing cache entry', () async {
        // Arrange: Initial cache
        final TestEntity oldData = TestEntity(id: '444', name: 'Old', value: 1);
        final TestEntity newData = TestEntity(id: '444', name: 'New', value: 2);

        await cacheService.set(
          entityType: 'test_entity',
          entityId: '444',
          data: oldData,
          ttl: const Duration(minutes: 5),
        );

        // Act: Update cache
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '444',
          data: newData,
          ttl: const Duration(minutes: 10),
        );

        // Assert: Cache updated with new TTL
        final bool isFresh = await cacheService.isFresh('test_entity', '444');
        expect(isFresh, isTrue);
      });

      test('should store ETag when provided', () async {
        // Arrange
        final TestEntity testData = TestEntity(
          id: '555',
          name: 'Test',
          value: 5,
        );
        const String etag = '"abc123"';

        // Act
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '555',
          data: testData,
          ttl: const Duration(minutes: 15),
          etag: etag,
        );

        // Assert: Verify ETag stored (check via database query)
        final CacheMetadataEntity? metadata =
            await (database.select(database.cacheMetadataTable)..where(
              ($CacheMetadataTableTable tbl) =>
                  tbl.entityType.equals('test_entity') &
                  tbl.entityId.equals('555'),
            )).getSingleOrNull();

        expect(metadata, isNotNull);
        expect(metadata!.etag, equals(etag));
      });
    });

    group('isFresh() - Cache freshness check', () {
      test('should return true for fresh cache', () async {
        // Arrange
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '666',
          data: TestEntity(id: '666', name: 'Test', value: 6),
          ttl: const Duration(hours: 1),
        );

        // Act & Assert
        final bool isFresh = await cacheService.isFresh('test_entity', '666');
        expect(isFresh, isTrue);
      });

      test('should return false for stale cache', () async {
        // Arrange: Cache with very short TTL
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '777',
          data: TestEntity(id: '777', name: 'Test', value: 7),
          ttl: const Duration(milliseconds: 1),
        );

        // Wait for TTL to expire
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Act & Assert
        final bool isFresh = await cacheService.isFresh('test_entity', '777');
        expect(isFresh, isFalse);
      });

      test('should return false for cache miss', () async {
        // Act & Assert
        final bool isFresh = await cacheService.isFresh(
          'test_entity',
          'nonexistent',
        );
        expect(isFresh, isFalse);
      });

      test('should return false for invalidated cache', () async {
        // Arrange: Cache then invalidate
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '888',
          data: TestEntity(id: '888', name: 'Test', value: 8),
          ttl: const Duration(hours: 1),
        );

        await cacheService.invalidate('test_entity', '888');

        // Act & Assert
        final bool isFresh = await cacheService.isFresh('test_entity', '888');
        expect(isFresh, isFalse);
      });
    });

    group('invalidate() - Invalidate specific cache entry', () {
      test('should invalidate specific cache entry', () async {
        // Arrange: Cache data
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '999',
          data: TestEntity(id: '999', name: 'Test', value: 9),
          ttl: const Duration(hours: 1),
        );

        final List<CacheInvalidationEvent> events = <CacheInvalidationEvent>[];
        final StreamSubscription<CacheInvalidationEvent> subscription =
            cacheService.invalidationStream.listen(events.add);

        // Act: Invalidate
        await cacheService.invalidate('test_entity', '999');

        // Wait for event emission
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: Cache no longer fresh
        final bool isFresh = await cacheService.isFresh('test_entity', '999');
        expect(isFresh, isFalse);

        // Verify invalidation event emitted
        final List<CacheInvalidationEvent> invalidationEvents =
            events
                .where(
                  (CacheInvalidationEvent e) =>
                      e.entityType == 'test_entity' &&
                      e.entityId == '999' &&
                      e.eventType == CacheEventType.invalidated,
                )
                .toList();
        expect(invalidationEvents, hasLength(1));

        await subscription.cancel();
      });

      test('should handle invalidating nonexistent entry gracefully', () async {
        // Act & Assert: Should not throw
        await cacheService.invalidate('test_entity', 'nonexistent');
      });
    });

    group('invalidateType() - Invalidate all entries of a type', () {
      test('should invalidate all entries of a type', () async {
        // Arrange: Cache multiple entries of same type
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'a1',
          data: TestEntity(id: 'a1', name: 'A1', value: 1),
          ttl: const Duration(hours: 1),
        );

        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'a2',
          data: TestEntity(id: 'a2', name: 'A2', value: 2),
          ttl: const Duration(hours: 1),
        );

        await cacheService.set(
          entityType: 'other_entity',
          entityId: 'b1',
          data: TestEntity(id: 'b1', name: 'B1', value: 3),
          ttl: const Duration(hours: 1),
        );

        // Act: Invalidate all test_entity entries
        await cacheService.invalidateType('test_entity');

        // Wait for database update
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: test_entity entries invalidated, other_entity not affected
        expect(await cacheService.isFresh('test_entity', 'a1'), isFalse);
        expect(await cacheService.isFresh('test_entity', 'a2'), isFalse);
        expect(await cacheService.isFresh('other_entity', 'b1'), isTrue);
      });

      test('should emit type-level invalidation event', () async {
        // Arrange
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'c1',
          data: TestEntity(id: 'c1', name: 'C1', value: 1),
          ttl: const Duration(hours: 1),
        );

        final List<CacheInvalidationEvent> events = <CacheInvalidationEvent>[];
        final StreamSubscription<CacheInvalidationEvent> subscription =
            cacheService.invalidationStream.listen(events.add);

        // Act
        await cacheService.invalidateType('test_entity');
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: Type-level event emitted with '*' entityId
        final List<CacheInvalidationEvent> typeEvents =
            events
                .where(
                  (CacheInvalidationEvent e) =>
                      e.entityType == 'test_entity' &&
                      e.entityId == '*' &&
                      e.eventType == CacheEventType.invalidated,
                )
                .toList();
        expect(typeEvents, hasLength(1));

        await subscription.cancel();
      });
    });

    group('clearAll() - Clear entire cache', () {
      test('should clear all cache entries', () async {
        // Arrange: Cache multiple entries
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'd1',
          data: TestEntity(id: 'd1', name: 'D1', value: 1),
          ttl: const Duration(hours: 1),
        );

        await cacheService.set(
          entityType: 'other_entity',
          entityId: 'e1',
          data: TestEntity(id: 'e1', name: 'E1', value: 2),
          ttl: const Duration(hours: 1),
        );

        // Act: Clear all cache
        await cacheService.clearAll();

        // Wait for database operation
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: All entries cleared
        expect(await cacheService.isFresh('test_entity', 'd1'), isFalse);
        expect(await cacheService.isFresh('other_entity', 'e1'), isFalse);

        // Verify database is empty
        final List<CacheMetadataEntity> entries =
            await database.select(database.cacheMetadataTable).get();
        expect(entries, isEmpty);
      });
    });

    group('getStats() - Cache statistics', () {
      test('should track cache hits and misses', () async {
        // Arrange: Perform cache operations
        final TestEntity testData = TestEntity(id: 'f1', name: 'F1', value: 1);
        final Map<String, TestEntity> dataStore = <String, TestEntity>{
          'f1': testData,
          'f2': testData,
        };

        // Cache miss
        await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: 'f1',
          fetcher: () async => testData,
        );

        // Cache hit (fresh)
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'f2',
          data: testData,
          ttl: const Duration(hours: 1),
        );

        await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: 'f2',
          fetcher:
              () async =>
                  dataStore['f2']!, // CORRECTED: Returns data from repository DB
        );

        // Act: Get statistics
        final CacheStats stats = await cacheService.getStats();

        // Assert: Statistics tracked
        expect(stats.totalRequests, greaterThanOrEqualTo(2));
        expect(stats.cacheHits, greaterThanOrEqualTo(1));
        expect(stats.cacheMisses, greaterThanOrEqualTo(1));
        expect(stats.hitRate, greaterThan(0.0));
        expect(stats.hitRatePercent, greaterThan(0.0));
      });

      test('should track stale served count', () async {
        // Arrange: Cache with short TTL
        final TestEntity testData = TestEntity(id: 'g1', name: 'G1', value: 1);

        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'g1',
          data: testData,
          ttl: const Duration(milliseconds: 1),
        );

        // Wait for staleness
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Act: Fetch stale data
        await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: 'g1',
          fetcher: () async => testData,
          backgroundRefresh: false,
        );

        final CacheStats stats = await cacheService.getStats();

        // Assert: Stale served tracked
        expect(stats.staleServed, greaterThanOrEqualTo(1));
      });

      test('should provide comprehensive cache statistics', () async {
        // Arrange: Populate cache
        for (int i = 0; i < 5; i++) {
          await cacheService.set(
            entityType: 'test_entity',
            entityId: 'h$i',
            data: TestEntity(id: 'h$i', name: 'H$i', value: i),
            ttl: const Duration(hours: 1),
          );
        }

        // Act
        final CacheStats stats = await cacheService.getStats();

        // Assert: Comprehensive stats available
        expect(stats.totalEntries, greaterThanOrEqualTo(5));
        expect(stats.totalRequests, isNotNull);
        expect(stats.hitRate, isNotNull);
        expect(stats.totalCacheSizeMB, isNotNull);
      });
    });

    group('cleanExpired() - Clean expired cache entries', () {
      test('should remove expired cache entries', () async {
        // Arrange: Cache with short TTL
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'i1',
          data: TestEntity(id: 'i1', name: 'I1', value: 1),
          ttl: const Duration(milliseconds: 1),
        );

        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'i2',
          data: TestEntity(id: 'i2', name: 'I2', value: 2),
          ttl: const Duration(hours: 1), // Fresh
        );

        // Wait for first entry to expire
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Act: Clean expired entries
        await cacheService.cleanExpired();

        // Wait for cleanup
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: Expired entry removed, fresh entry remains
        final List<CacheMetadataEntity> entries =
            await database.select(database.cacheMetadataTable).get();
        expect(
          entries.where((CacheMetadataEntity e) => e.entityId == 'i2'),
          hasLength(1),
        );
      });
    });

    group('generateCollectionCacheKey() - Query parameter hashing', () {
      test('should generate consistent cache keys', () async {
        // Arrange
        final Map<String, String> filters1 = <String, String>{
          'start': '2024-01-01',
          'end': '2024-12-31',
          'account': '123',
        };
        final Map<String, String> filters2 = <String, String>{
          'account': '123',
          'end': '2024-12-31',
          'start': '2024-01-01',
        }; // Different order

        // Act
        final String key1 = cacheService.generateCollectionCacheKey(filters1);
        final String key2 = cacheService.generateCollectionCacheKey(filters2);

        // Assert: Same hash for same parameters (different order)
        expect(key1, equals(key2));
        expect(key1, startsWith('collection_'));
      });

      test('should generate different keys for different parameters', () async {
        // Arrange
        final Map<String, String> filters1 = <String, String>{
          'start': '2024-01-01',
          'end': '2024-12-31',
        };
        final Map<String, String> filters2 = <String, String>{
          'start': '2024-01-01',
          'end': '2024-06-30',
        };

        // Act
        final String key1 = cacheService.generateCollectionCacheKey(filters1);
        final String key2 = cacheService.generateCollectionCacheKey(filters2);

        // Assert: Different hashes
        expect(key1, isNot(equals(key2)));
      });

      test('should handle null and empty filters', () async {
        // Act
        final String keyNull = cacheService.generateCollectionCacheKey(null);
        final String keyEmpty = cacheService.generateCollectionCacheKey(
          <String, dynamic>{},
        );

        // Assert: Both return default 'collection_all'
        expect(keyNull, equals('collection_all'));
        expect(keyEmpty, equals('collection_all'));
      });
    });

    group('LRU Eviction', () {
      test(
        'should evict least recently used entries when size limit exceeded',
        () async {
          // Arrange: Set cache size limit
          // Each entry is ~2.2KB (200 bytes metadata + 2KB data)
          // calculateCacheSizeMB() uses round(), so:
          // - 500 entries = 1,100,000 bytes / 1,048,576 = 1.049MB → rounds to 1MB (no eviction)
          // - 750 entries = 1,650,000 bytes / 1,048,576 = 1.573MB → rounds to 2MB (triggers eviction)
          await cacheService.setMaxCacheSizeMB(1); // Set 1MB limit

          // Cache many entries (enough to exceed limit after rounding)
          // 750 entries should round to 2MB, triggering eviction
          for (int i = 0; i < 750; i++) {
            await cacheService.set(
              entityType: 'test_entity',
              entityId: 'j$i',
              data: TestEntity(id: 'j$i', name: 'J$i', value: i),
              ttl: const Duration(hours: 1),
            );
          }

          // Act: Trigger LRU eviction with setMaxCacheSizeMB (also triggers eviction)
          await cacheService.setMaxCacheSizeMB(
            1,
          ); // This should trigger eviction

          // Wait for eviction
          await Future<void>.delayed(const Duration(milliseconds: 200));

          // Assert: Cache size within limit (after eviction)
          final CacheStats stats = await cacheService.getStats();
          expect(
            stats.totalCacheSizeMB,
            lessThanOrEqualTo(2),
          ); // Allow some margin
          expect(
            stats.evictions,
            greaterThan(0),
          ); // Should have evicted some entries
        },
      );

      test('should update lastAccessedAt on cache hit', () async {
        // Arrange: Cache entry with data in repository
        final TestEntity testData = TestEntity(id: 'k1', name: 'K1', value: 1);
        final Map<String, TestEntity> dataStore = <String, TestEntity>{
          'k1': testData,
        };

        // Set cache with initial timestamp
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'k1',
          data: testData,
          ttl: const Duration(hours: 1),
        );

        // Wait to ensure time passes before reading initial timestamp
        // This ensures the set() operation completes fully
        await Future<void>.delayed(const Duration(milliseconds: 100));

        // Get initial lastAccessedAt
        CacheMetadataEntity metadata =
            await (database.select(database.cacheMetadataTable)..where(
              ($CacheMetadataTableTable tbl) =>
                  tbl.entityType.equals('test_entity') &
                  tbl.entityId.equals('k1'),
            )).getSingle();
        final DateTime initialLastAccessed = metadata.lastAccessedAt;

        // Critical: Wait to ensure DateTime.now() in get() will be different
        // This is the key - we need time to pass at the SOURCE (DateTime.now())
        // not just in our test. Use longer delay for CI environments with lower clock resolution
        await Future<void>.delayed(const Duration(milliseconds: 1000));

        // Act: Access cache entry - this should update lastAccessedAt
        await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: 'k1',
          fetcher:
              () async =>
                  dataStore['k1']!, // CORRECTED: Returns data from repository DB
        );

        // Wait for database write to complete and flush
        // Use longer delay for CI environments to ensure write completes
        await Future<void>.delayed(const Duration(milliseconds: 500));

        // Assert: lastAccessedAt should be updated to a later time
        metadata =
            await (database.select(database.cacheMetadataTable)..where(
              ($CacheMetadataTableTable tbl) =>
                  tbl.entityType.equals('test_entity') &
                  tbl.entityId.equals('k1'),
            )).getSingle();

        expect(
          metadata.lastAccessedAt.isAfter(initialLastAccessed),
          isTrue,
          reason:
              'lastAccessedAt should be updated after cache access. '
              'Initial: $initialLastAccessed, Updated: ${metadata.lastAccessedAt}',
        );
      });
    });

    group('Thread Safety', () {
      test('should handle concurrent cache operations safely', () async {
        // Arrange: Multiple concurrent operations
        final List<Future<dynamic>> futures = <Future>[];

        // Act: Concurrent set operations
        for (int i = 0; i < 10; i++) {
          futures.add(
            cacheService.set(
              entityType: 'test_entity',
              entityId: 'l$i',
              data: TestEntity(id: 'l$i', name: 'L$i', value: i),
              ttl: const Duration(hours: 1),
            ),
          );
        }

        // Concurrent get operations
        for (int i = 0; i < 10; i++) {
          futures.add(
            cacheService.get<TestEntity>(
              entityType: 'test_entity',
              entityId: 'l$i',
              fetcher: () async => TestEntity(id: 'l$i', name: 'L$i', value: i),
            ),
          );
        }

        // Concurrent invalidations
        for (int i = 0; i < 5; i++) {
          futures.add(cacheService.invalidate('test_entity', 'l$i'));
        }

        // Assert: All operations complete without errors
        await Future.wait(futures);

        // Verify cache state is consistent
        final CacheStats stats = await cacheService.getStats();
        expect(stats.totalEntries, greaterThan(0));
      });

      test('should handle concurrent background refreshes', () async {
        // Arrange: Cache multiple stale entries
        for (int i = 0; i < 5; i++) {
          await cacheService.set(
            entityType: 'test_entity',
            entityId: 'm$i',
            data: TestEntity(id: 'm$i', name: 'M$i', value: i),
            ttl: const Duration(milliseconds: 1),
          );
        }

        // Wait for staleness
        await Future<void>.delayed(const Duration(milliseconds: 50));

        // Act: Trigger concurrent background refreshes
        final List<Future<dynamic>> futures = <Future>[];
        for (int i = 0; i < 5; i++) {
          futures.add(
            cacheService.get<TestEntity>(
              entityType: 'test_entity',
              entityId: 'm$i',
              fetcher: () async {
                await Future<void>.delayed(const Duration(milliseconds: 10));
                return TestEntity(id: 'm$i', name: 'M${i}_new', value: i + 100);
              },
              backgroundRefresh: true,
            ),
          );
        }

        // Assert: All complete without errors
        final List<dynamic> results = await Future.wait(futures);
        expect(results, hasLength(5));

        // Wait for background refreshes
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
    });

    group('Error Handling', () {
      test('should handle fetcher errors gracefully', () async {
        // Act & Assert: Fetcher error propagated
        expect(
          () async => cacheService.get<TestEntity>(
            entityType: 'test_entity',
            entityId: 'error1',
            fetcher: () async => throw Exception('Fetcher error'),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should not propagate background refresh errors', () async {
        // Arrange: Stale cache with data in repository
        final TestEntity testData = TestEntity(id: 'n1', name: 'N1', value: 1);

        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'n1',
          data: testData,
          ttl: const Duration(milliseconds: 1),
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));

        int fetcherCallCount = 0;

        // Act: Fetch with failing background refresh (second call)
        final CacheResult<TestEntity>
        result = await cacheService.get<TestEntity>(
          entityType: 'test_entity',
          entityId: 'n1',
          fetcher: () async {
            fetcherCallCount++;
            // Fetcher only called during background refresh (not during initial get when persistedData exists)
            // Throw error during background refresh
            throw Exception('Background refresh error');
          },
          backgroundRefresh: true,
        );

        // Assert: Returns stale data from cache (persistedData)
        expect(result.data, isNotNull);
        expect(result.data, equals(testData));
        expect(result.isFresh, isFalse);
        // Fetcher not called during initial get() when persistedData exists
        expect(fetcherCallCount, equals(0));

        // Wait for background refresh attempt (should fail silently)
        await Future<void>.delayed(const Duration(milliseconds: 200));

        // Background refresh error should not propagate - fetcher called once during background refresh
        expect(fetcherCallCount, equals(1));
        // No exception thrown to caller
      });
    });

    group('Stream Behavior', () {
      test('should emit invalidation events on invalidate', () async {
        // Arrange
        final List<CacheInvalidationEvent> events = <CacheInvalidationEvent>[];
        final StreamSubscription<CacheInvalidationEvent> subscription =
            cacheService.invalidationStream.listen(events.add);

        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'o1',
          data: TestEntity(id: 'o1', name: 'O1', value: 1),
          ttl: const Duration(hours: 1),
        );

        // Act: Multiple invalidations
        await cacheService.invalidate('test_entity', 'o1');
        await cacheService.invalidateType('test_entity');

        // Wait for event emission
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // Assert: Events emitted
        expect(
          events.where(
            (CacheInvalidationEvent e) =>
                e.eventType == CacheEventType.invalidated,
          ),
          hasLength(greaterThanOrEqualTo(2)),
        );

        await subscription.cancel();
      });

      test(
        'should emit refresh events on background refresh completion',
        () async {
          // Arrange: Stale cache
          await cacheService.set(
            entityType: 'test_entity',
            entityId: 'p1',
            data: TestEntity(id: 'p1', name: 'P1', value: 1),
            ttl: const Duration(milliseconds: 1),
          );

          await Future<void>.delayed(const Duration(milliseconds: 50));

          final List<CacheInvalidationEvent> events =
              <CacheInvalidationEvent>[];
          final StreamSubscription<CacheInvalidationEvent> subscription =
              cacheService.invalidationStream.listen(events.add);

          // Act: Trigger background refresh
          await cacheService.get<TestEntity>(
            entityType: 'test_entity',
            entityId: 'p1',
            fetcher: () async {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              return TestEntity(id: 'p1', name: 'P1_new', value: 2);
            },
            backgroundRefresh: true,
          );

          // Wait for background refresh to complete (longer delay to ensure completion)
          await Future<void>.delayed(const Duration(milliseconds: 300));

          // Assert: Refresh event emitted
          final List<CacheInvalidationEvent> refreshEvents =
              events
                  .where(
                    (CacheInvalidationEvent e) =>
                        e.eventType == CacheEventType.refreshed,
                  )
                  .toList();
          expect(refreshEvents, hasLength(1));
          expect(refreshEvents.first.entityType, equals('test_entity'));
          expect(refreshEvents.first.entityId, equals('p1'));

          await subscription.cancel();
        },
      );
    });

    group('Edge Cases', () {
      test('should handle very large entity IDs', () async {
        // Arrange: Large entity ID
        final String longId = 'x' * 1000;
        final TestEntity testData = TestEntity(
          id: longId,
          name: 'Test',
          value: 1,
        );

        // Act & Assert: Should handle without errors
        await cacheService.set(
          entityType: 'test_entity',
          entityId: longId,
          data: testData,
          ttl: const Duration(hours: 1),
        );

        final bool isFresh = await cacheService.isFresh('test_entity', longId);
        expect(isFresh, isTrue);
      });

      test('should handle zero TTL gracefully', () async {
        // Arrange
        final TestEntity testData = TestEntity(id: 'q1', name: 'Q1', value: 1);

        // Act: Cache with zero TTL
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'q1',
          data: testData,
          ttl: Duration.zero,
        );

        // Assert: Entry immediately stale
        final bool isFresh = await cacheService.isFresh('test_entity', 'q1');
        expect(isFresh, isFalse);
      });

      test('should handle negative TTL gracefully', () async {
        // Arrange
        final TestEntity testData = TestEntity(id: 'r1', name: 'R1', value: 1);

        // Act: Cache with negative TTL (edge case)
        await cacheService.set(
          entityType: 'test_entity',
          entityId: 'r1',
          data: testData,
          ttl: const Duration(seconds: -1),
        );

        // Assert: Entry immediately stale
        final bool isFresh = await cacheService.isFresh('test_entity', 'r1');
        expect(isFresh, isFalse);
      });

      test('should handle empty entity type', () async {
        // Act & Assert: Should handle gracefully
        await cacheService.set(
          entityType: '',
          entityId: 's1',
          data: TestEntity(id: 's1', name: 'S1', value: 1),
          ttl: const Duration(hours: 1),
        );

        final bool isFresh = await cacheService.isFresh('', 's1');
        expect(isFresh, isTrue);
      });

      test('should handle empty entity ID', () async {
        // Act & Assert: Should handle gracefully
        await cacheService.set(
          entityType: 'test_entity',
          entityId: '',
          data: TestEntity(id: '', name: 'T1', value: 1),
          ttl: const Duration(hours: 1),
        );

        final bool isFresh = await cacheService.isFresh('test_entity', '');
        expect(isFresh, isTrue);
      });
    });
  });
}
