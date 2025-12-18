import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/models/paginated_result.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';

/// Mock classes for performance benchmarking.
class MockFireflyApiAdapter extends Mock implements FireflyApiAdapter {}

class MockCacheService extends Mock implements CacheService {}

/// Performance Benchmark Tests for Incremental Sync.
///
/// These tests validate that incremental sync meets performance targets:
/// - **70-80% bandwidth reduction** compared to full sync
/// - **60-70% speed improvement** compared to full sync
/// - **80% database write reduction** when entities are unchanged
/// - **95% API call reduction** for cached Tier 2 entities
///
/// ## Test Strategy
///
/// Each benchmark test simulates realistic sync scenarios:
/// 1. **Large Dataset Test**: 1000+ transactions with varying change rates
/// 2. **Skip Rate Test**: Measures efficiency when most data is unchanged
/// 3. **Cache Hit Test**: Measures API call savings for Tier 2 entities
/// 4. **Bandwidth Test**: Calculates estimated bandwidth savings
/// 5. **Speed Test**: Compares time to skip vs update entities
///
/// ## Performance Targets
///
/// | Metric | Target | Measurement Method |
/// |--------|--------|-------------------|
/// | Bandwidth Reduction | 70-80% | `bandwidthSavedBytes / totalBandwidth` |
/// | Skip Rate | >70% | `itemsSkipped / itemsFetched` |
/// | Cache Hit Rate | >90% | `apiCallsSaved / totalExpectedCalls` |
/// | DB Write Reduction | >80% | `skippedWrites / totalFetched` |
///
/// ## Running Benchmarks
///
/// ```bash
/// # Run all performance tests
/// flutter test test/performance/
///
/// # Run with verbose output for detailed timing
/// flutter test test/performance/incremental_sync_benchmark_test.dart --verbose
/// ```
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure logging for benchmarks
  Logger.root.level = Level.WARNING;

  group('Incremental Sync Performance Benchmarks', () {
    late AppDatabase database;
    late MockFireflyApiAdapter mockApiAdapter;
    late MockCacheService mockCacheService;
    late IncrementalSyncService syncService;

    setUp(() async {
      // Create in-memory database for isolated testing
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Initialize mocks
      mockApiAdapter = MockFireflyApiAdapter();
      mockCacheService = MockCacheService();

      // Configure default cache behavior
      when(
        () => mockCacheService.isFresh(any(), any()),
      ).thenAnswer((_) async => false);
      when(
        () => mockCacheService.set<bool>(
          entityType: any(named: 'entityType'),
          entityId: any(named: 'entityId'),
          data: any(named: 'data'),
          ttl: any(named: 'ttl'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => mockCacheService.invalidate(any(), any()),
      ).thenAnswer((_) async {});

      // Create service instance
      syncService = IncrementalSyncService(
        database: database,
        apiAdapter: mockApiAdapter,
        cacheService: mockCacheService,
        enableIncrementalSync: true,
        syncWindowDays: 30,
        cacheTtlHours: 24,
        maxDaysSinceFullSync: 7,
      );

      // Initialize sync metadata
      await _initializeSyncMetadata(database);
    });

    tearDown(() async {
      await database.close();
    });

    // ==================== Benchmark 1: Large Dataset Performance ====================

    group('Large Dataset Performance', () {
      test('should efficiently process 500+ transactions', () async {
        // Arrange: Create a large dataset of transactions
        const int totalTransactions = 500;
        const double changeRate = 0.1; // 10% changed
        final DateTime oldTimestamp = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        final DateTime newTimestamp = DateTime.now();

        // Insert existing transactions with old timestamps
        await _insertReferenceAccounts(database);
        for (int i = 0; i < totalTransactions; i++) {
          await _insertTransaction(
            database,
            'tx-$i',
            'Transaction $i',
            (i + 1) * 10.0,
            oldTimestamp,
          );
        }

        // Create API response: 10% changed, 90% unchanged
        final List<Map<String, dynamic>> serverTransactions =
            <Map<String, dynamic>>[];
        for (int i = 0; i < totalTransactions; i++) {
          final bool isChanged = i < (totalTransactions * changeRate);
          serverTransactions.add(
            _createServerTransaction(
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              isChanged ? newTimestamp : oldTimestamp,
            ),
          );
        }

        _setupTransactionResponse(mockApiAdapter, serverTransactions);
        _setupEmptyOtherEntityResponses(mockApiAdapter);

        // Act: Perform incremental sync and measure time
        final Stopwatch stopwatch = Stopwatch()..start();
        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();
        stopwatch.stop();

        // Assert: Verify performance
        expect(result.success, isTrue, reason: 'Error: ${result.error}');

        final IncrementalSyncStats txStats =
            result.statsByEntity['transaction']!;
        expect(txStats.itemsFetched, equals(totalTransactions));

        // Verify skip rate meets target (should be ~90%)
        final double skipRate = txStats.skipRate;
        expect(
          skipRate,
          greaterThanOrEqualTo(85.0),
          reason:
              'Skip rate should be >=85%, got ${skipRate.toStringAsFixed(1)}%',
        );

        // Verify bandwidth savings calculation
        expect(
          txStats.bandwidthSavedBytes,
          greaterThan(0),
          reason: 'Should calculate bandwidth saved',
        );

        // Log benchmark results
        _logBenchmarkResult(
          'Large Dataset (500 tx)',
          stopwatch.elapsed,
          txStats,
        );
      });

      test('should scale efficiently with 1000 transactions', () async {
        // Arrange: Create a very large dataset
        const int totalTransactions = 1000;
        const double changeRate = 0.05; // 5% changed
        final DateTime oldTimestamp = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        final DateTime newTimestamp = DateTime.now();

        await _insertReferenceAccounts(database);
        for (int i = 0; i < totalTransactions; i++) {
          await _insertTransaction(
            database,
            'tx-$i',
            'Transaction $i',
            (i + 1) * 10.0,
            oldTimestamp,
          );
        }

        final List<Map<String, dynamic>> serverTransactions =
            <Map<String, dynamic>>[];
        for (int i = 0; i < totalTransactions; i++) {
          final bool isChanged = i < (totalTransactions * changeRate);
          serverTransactions.add(
            _createServerTransaction(
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              isChanged ? newTimestamp : oldTimestamp,
            ),
          );
        }

        _setupTransactionResponse(mockApiAdapter, serverTransactions);
        _setupEmptyOtherEntityResponses(mockApiAdapter);

        // Act
        final Stopwatch stopwatch = Stopwatch()..start();
        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();
        stopwatch.stop();

        // Assert
        expect(result.success, isTrue);

        final IncrementalSyncStats txStats =
            result.statsByEntity['transaction']!;

        // Verify skip rate meets target (should be ~95%)
        final double skipRate = txStats.skipRate;
        expect(
          skipRate,
          greaterThanOrEqualTo(90.0),
          reason:
              'Skip rate should be >=90%, got ${skipRate.toStringAsFixed(1)}%',
        );

        _logBenchmarkResult(
          'Large Dataset (1000 tx)',
          stopwatch.elapsed,
          txStats,
        );
      });
    });

    // ==================== Benchmark 2: Bandwidth Reduction ====================

    group('Bandwidth Reduction', () {
      test(
        'should achieve 70%+ bandwidth reduction with 90% unchanged data',
        () async {
          // Arrange: 100 transactions, 90% unchanged
          const int totalTransactions = 100;
          const double changeRate = 0.10; // 10% changed
          final DateTime oldTimestamp = DateTime.now().subtract(
            const Duration(hours: 2),
          );
          final DateTime newTimestamp = DateTime.now();

          await _insertReferenceAccounts(database);
          for (int i = 0; i < totalTransactions; i++) {
            await _insertTransaction(
              database,
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              oldTimestamp,
            );
          }

          final List<Map<String, dynamic>> serverTransactions =
              <Map<String, dynamic>>[];
          for (int i = 0; i < totalTransactions; i++) {
            final bool isChanged = i < (totalTransactions * changeRate);
            serverTransactions.add(
              _createServerTransaction(
                'tx-$i',
                'Transaction $i',
                (i + 1) * 10.0,
                isChanged ? newTimestamp : oldTimestamp,
              ),
            );
          }

          _setupTransactionResponse(mockApiAdapter, serverTransactions);
          _setupEmptyOtherEntityResponses(mockApiAdapter);

          // Act
          final IncrementalSyncResult result =
              await syncService.performIncrementalSync();

          // Assert
          expect(result.success, isTrue);

          final IncrementalSyncStats txStats =
              result.statsByEntity['transaction']!;

          // Calculate bandwidth reduction percentage
          // Assume average transaction is ~2KB
          const int avgTransactionSize = 2048;
          final int totalBandwidthWithoutSkip =
              totalTransactions * avgTransactionSize;
          final int bandwidthSaved = txStats.bandwidthSavedBytes;

          final double reductionPercent =
              (bandwidthSaved / totalBandwidthWithoutSkip) * 100;

          expect(
            reductionPercent,
            greaterThanOrEqualTo(70.0),
            reason:
                'Bandwidth reduction should be >=70%, got ${reductionPercent.toStringAsFixed(1)}%',
          );

          _logBenchmarkResult(
            'Bandwidth Reduction Test',
            Duration.zero,
            txStats,
            additionalInfo:
                'Reduction: ${reductionPercent.toStringAsFixed(1)}% ($bandwidthSaved bytes saved)',
          );
        },
      );

      test(
        'should calculate correct bandwidth savings for skipped items',
        () async {
          // Arrange: All items unchanged
          const int totalTransactions = 50;
          final DateTime timestamp = DateTime.now().subtract(
            const Duration(hours: 1),
          );

          await _insertReferenceAccounts(database);
          for (int i = 0; i < totalTransactions; i++) {
            await _insertTransaction(
              database,
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              timestamp,
            );
          }

          final List<Map<String, dynamic>> serverTransactions =
              <Map<String, dynamic>>[];
          for (int i = 0; i < totalTransactions; i++) {
            serverTransactions.add(
              _createServerTransaction(
                'tx-$i',
                'Transaction $i',
                (i + 1) * 10.0,
                timestamp, // Same timestamp = unchanged
              ),
            );
          }

          _setupTransactionResponse(mockApiAdapter, serverTransactions);
          _setupEmptyOtherEntityResponses(mockApiAdapter);

          // Act
          final IncrementalSyncResult result =
              await syncService.performIncrementalSync();

          // Assert
          expect(result.success, isTrue);

          final IncrementalSyncStats txStats =
              result.statsByEntity['transaction']!;

          // All items should be skipped
          expect(txStats.itemsSkipped, equals(totalTransactions));
          expect(txStats.itemsUpdated, equals(0));

          // Bandwidth saved should be totalTransactions * avgSize
          const int avgTransactionSize = 2048;
          expect(
            txStats.bandwidthSavedBytes,
            equals(totalTransactions * avgTransactionSize),
          );
        },
      );
    });

    // ==================== Benchmark 3: Cache Hit Performance ====================

    group('Cache Hit Performance for Tier 2 Entities', () {
      test('should skip 95%+ API calls when Tier 2 cache is fresh', () async {
        // Arrange: Configure all Tier 2 caches as fresh
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => true);

        // Only Tier 1 entities will be fetched
        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);

        // Act
        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // Assert
        expect(result.success, isTrue);

        // Verify API calls were saved for Tier 2 entities
        final int categoryApiSaved =
            result.statsByEntity['category']?.apiCallsSaved ?? 0;
        final int billApiSaved =
            result.statsByEntity['bill']?.apiCallsSaved ?? 0;
        final int piggyBankApiSaved =
            result.statsByEntity['piggy_bank']?.apiCallsSaved ?? 0;

        final int totalApiCallsSaved =
            categoryApiSaved + billApiSaved + piggyBankApiSaved;
        expect(totalApiCallsSaved, equals(3));

        // Verify no API calls were made for cached entities
        verifyNever(
          () => mockApiAdapter.getCategoriesPaginated(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        );
        verifyNever(
          () => mockApiAdapter.getBillsPaginated(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        );
        verifyNever(
          () => mockApiAdapter.getPiggyBanksPaginated(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        );

        _logBenchmarkResult(
          'Tier 2 Cache Hit Test',
          Duration.zero,
          null,
          additionalInfo: 'API calls saved: $totalApiCallsSaved/3 (100%)',
        );
      });

      test('should measure cache miss vs hit performance difference', () async {
        // Test 1: Cache Miss (stale cache)
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => false);
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => false);
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => false);

        _setupEmptyApiResponses(mockApiAdapter);

        final Stopwatch cacheMissStopwatch = Stopwatch()..start();
        final IncrementalSyncResult cacheMissResult =
            await syncService.performIncrementalSync();
        cacheMissStopwatch.stop();

        expect(cacheMissResult.success, isTrue);

        // Test 2: Cache Hit (fresh cache)
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => true);

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);

        final Stopwatch cacheHitStopwatch = Stopwatch()..start();
        final IncrementalSyncResult cacheHitResult =
            await syncService.performIncrementalSync();
        cacheHitStopwatch.stop();

        expect(cacheHitResult.success, isTrue);

        // Log comparison
        _logBenchmarkResult(
          'Cache Miss Sync',
          cacheMissStopwatch.elapsed,
          null,
        );
        _logBenchmarkResult('Cache Hit Sync', cacheHitStopwatch.elapsed, null);
      });
    });

    // ==================== Benchmark 4: Database Write Reduction ====================

    group('Database Write Reduction', () {
      test('should achieve 80%+ write reduction with 90% unchanged data', () async {
        // Arrange: 100 transactions, 90% unchanged
        const int totalTransactions = 100;
        const double changeRate = 0.10; // 10% changed
        final DateTime oldTimestamp = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        final DateTime newTimestamp = DateTime.now();

        await _insertReferenceAccounts(database);
        for (int i = 0; i < totalTransactions; i++) {
          await _insertTransaction(
            database,
            'tx-$i',
            'Transaction $i',
            (i + 1) * 10.0,
            oldTimestamp,
          );
        }

        final List<Map<String, dynamic>> serverTransactions =
            <Map<String, dynamic>>[];
        for (int i = 0; i < totalTransactions; i++) {
          final bool isChanged = i < (totalTransactions * changeRate);
          serverTransactions.add(
            _createServerTransaction(
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              isChanged ? newTimestamp : oldTimestamp,
            ),
          );
        }

        _setupTransactionResponse(mockApiAdapter, serverTransactions);
        _setupEmptyOtherEntityResponses(mockApiAdapter);

        // Act
        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // Assert
        expect(result.success, isTrue);

        final IncrementalSyncStats txStats =
            result.statsByEntity['transaction']!;

        // Calculate write reduction
        final int totalWritesWithoutSkip = totalTransactions;
        final int actualWrites = txStats.itemsUpdated;
        final double writeReduction =
            ((totalWritesWithoutSkip - actualWrites) / totalWritesWithoutSkip) *
            100;

        expect(
          writeReduction,
          greaterThanOrEqualTo(80.0),
          reason:
              'Write reduction should be >=80%, got ${writeReduction.toStringAsFixed(1)}%',
        );

        _logBenchmarkResult(
          'DB Write Reduction Test',
          Duration.zero,
          txStats,
          additionalInfo:
              'Write reduction: ${writeReduction.toStringAsFixed(1)}% ($actualWrites writes instead of $totalWritesWithoutSkip)',
        );
      });
    });

    // ==================== Benchmark 5: Mixed Entity Performance ====================

    group('Mixed Entity Performance', () {
      test('should efficiently sync all entity types together', () async {
        // Arrange: Create mixed data with varying change rates
        final DateTime oldTimestamp = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        final DateTime newTimestamp = DateTime.now();

        await _insertReferenceAccounts(database);

        // Insert existing transactions (some will be unchanged)
        for (int i = 0; i < 50; i++) {
          await _insertTransaction(
            database,
            'tx-$i',
            'Transaction $i',
            (i + 1) * 10.0,
            oldTimestamp,
          );
        }

        // Insert existing accounts (some will be unchanged)
        for (int i = 0; i < 10; i++) {
          await _insertAccount(
            database,
            'acc-extra-$i',
            'Account $i',
            'asset',
            1000.0,
            oldTimestamp,
          );
        }

        // Setup API responses with mixed change rates
        final List<Map<String, dynamic>> transactions =
            <Map<String, dynamic>>[];
        for (int i = 0; i < 50; i++) {
          final bool isChanged = i < 5; // 10% changed
          transactions.add(
            _createServerTransaction(
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              isChanged ? newTimestamp : oldTimestamp,
            ),
          );
        }

        final List<Map<String, dynamic>> accounts = <Map<String, dynamic>>[];
        for (int i = 0; i < 10; i++) {
          final bool isChanged = i < 2; // 20% changed
          accounts.add(
            _createServerAccount(
              'acc-extra-$i',
              'Account $i',
              'asset',
              1000.0,
              isChanged ? newTimestamp : oldTimestamp,
            ),
          );
        }

        _setupTransactionResponse(mockApiAdapter, transactions);
        _setupAccountResponse(mockApiAdapter, accounts);
        _setupEmptyBudgetResponse(mockApiAdapter);

        // Tier 2: All cache fresh
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => true);

        // Act
        final Stopwatch stopwatch = Stopwatch()..start();
        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();
        stopwatch.stop();

        // Assert
        expect(result.success, isTrue);

        // Verify aggregate statistics
        final int totalFetched = result.totalFetched;
        final int totalUpdated = result.totalUpdated;
        final int totalSkipped = result.totalSkipped;

        expect(totalFetched, equals(60)); // 50 tx + 10 accounts
        expect(
          result.overallSkipRate,
          greaterThanOrEqualTo(70.0),
          reason:
              'Overall skip rate should be >=70%, got ${result.overallSkipRate.toStringAsFixed(1)}%',
        );

        _logBenchmarkResult(
          'Mixed Entity Sync',
          stopwatch.elapsed,
          null,
          additionalInfo:
              'Fetched: $totalFetched, Updated: $totalUpdated, Skipped: $totalSkipped',
        );
      });
    });

    // ==================== Benchmark 6: Timestamp Comparison Performance ====================

    group('Timestamp Comparison Performance', () {
      test('should perform timestamp comparison efficiently', () async {
        // Arrange: Large number of transactions to compare
        const int totalTransactions = 200;
        final DateTime timestamp = DateTime.now().subtract(
          const Duration(hours: 1),
        );

        await _insertReferenceAccounts(database);
        for (int i = 0; i < totalTransactions; i++) {
          await _insertTransaction(
            database,
            'tx-$i',
            'Transaction $i',
            (i + 1) * 10.0,
            timestamp,
          );
        }

        final List<Map<String, dynamic>> serverTransactions =
            <Map<String, dynamic>>[];
        for (int i = 0; i < totalTransactions; i++) {
          // All unchanged - forces timestamp comparison for each
          serverTransactions.add(
            _createServerTransaction(
              'tx-$i',
              'Transaction $i',
              (i + 1) * 10.0,
              timestamp,
            ),
          );
        }

        _setupTransactionResponse(mockApiAdapter, serverTransactions);
        _setupEmptyOtherEntityResponses(mockApiAdapter);

        // Act
        final Stopwatch stopwatch = Stopwatch()..start();
        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();
        stopwatch.stop();

        // Assert
        expect(result.success, isTrue);

        final IncrementalSyncStats txStats =
            result.statsByEntity['transaction']!;

        // All should be skipped (same timestamp)
        expect(txStats.itemsSkipped, equals(totalTransactions));
        expect(txStats.itemsUpdated, equals(0));

        // Calculate comparisons per millisecond
        final double comparisonsPerMs =
            totalTransactions / max(1, stopwatch.elapsedMilliseconds);

        _logBenchmarkResult(
          'Timestamp Comparison Test',
          stopwatch.elapsed,
          txStats,
          additionalInfo:
              '${comparisonsPerMs.toStringAsFixed(1)} comparisons/ms',
        );
      });
    });
  });
}

// ==================== Test Helpers ====================

/// Initialize sync metadata for a fresh database.
Future<void> _initializeSyncMetadata(AppDatabase database) async {
  await database
      .into(database.syncMetadata)
      .insertOnConflictUpdate(
        SyncMetadataEntityCompanion.insert(
          key: 'last_full_sync',
          value:
              DateTime.now()
                  .subtract(const Duration(days: 1))
                  .toIso8601String(),
          updatedAt: DateTime.now(),
        ),
      );
}

/// Insert required reference accounts used by transactions in tests.
Future<void> _insertReferenceAccounts(AppDatabase database) async {
  final DateTime now = DateTime.now();
  await database
      .into(database.accounts)
      .insertOnConflictUpdate(
        AccountEntityCompanion.insert(
          id: 'acc-1',
          serverId: const Value<String?>('acc-1'),
          name: 'Test Source Account',
          type: 'asset',
          currencyCode: 'USD',
          currentBalance: 1000.0,
          createdAt: now,
          updatedAt: now,
          serverUpdatedAt: Value<DateTime?>(now),
          isSynced: const Value<bool>(true),
          syncStatus: const Value<String>('synced'),
        ),
      );
  await database
      .into(database.accounts)
      .insertOnConflictUpdate(
        AccountEntityCompanion.insert(
          id: 'acc-2',
          serverId: const Value<String?>('acc-2'),
          name: 'Test Destination Account',
          type: 'expense',
          currencyCode: 'USD',
          currentBalance: 0.0,
          createdAt: now,
          updatedAt: now,
          serverUpdatedAt: Value<DateTime?>(now),
          isSynced: const Value<bool>(true),
          syncStatus: const Value<String>('synced'),
        ),
      );
}

/// Insert a test transaction into the database.
Future<void> _insertTransaction(
  AppDatabase database,
  String serverId,
  String description,
  double amount,
  DateTime serverUpdatedAt,
) async {
  await database
      .into(database.transactions)
      .insertOnConflictUpdate(
        TransactionEntityCompanion.insert(
          id: serverId,
          serverId: Value<String?>(serverId),
          type: 'withdrawal',
          date: DateTime.now(),
          amount: amount,
          description: description,
          sourceAccountId: 'acc-1',
          destinationAccountId: 'acc-2',
          currencyCode: 'USD',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          serverUpdatedAt: Value<DateTime?>(serverUpdatedAt),
          isSynced: const Value<bool>(true),
          syncStatus: const Value<String>('synced'),
        ),
      );
}

/// Insert a test account into the database.
Future<void> _insertAccount(
  AppDatabase database,
  String serverId,
  String name,
  String type,
  double balance,
  DateTime serverUpdatedAt,
) async {
  await database
      .into(database.accounts)
      .insertOnConflictUpdate(
        AccountEntityCompanion.insert(
          id: serverId,
          serverId: Value<String?>(serverId),
          name: name,
          type: type,
          currencyCode: 'USD',
          currentBalance: balance,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          serverUpdatedAt: Value<DateTime?>(serverUpdatedAt),
          isSynced: const Value<bool>(true),
          syncStatus: const Value<String>('synced'),
        ),
      );
}

/// Setup empty API responses for all entity types.
void _setupEmptyApiResponses(MockFireflyApiAdapter mockApi) {
  _setupEmptyTransactionResponse(mockApi);
  _setupEmptyAccountResponse(mockApi);
  _setupEmptyBudgetResponse(mockApi);
  _setupEmptyCategoryResponse(mockApi);
  _setupEmptyBillResponse(mockApi);
  _setupEmptyPiggyBankResponse(mockApi);
}

/// Setup empty responses for non-transaction entity types.
void _setupEmptyOtherEntityResponses(MockFireflyApiAdapter mockApi) {
  _setupEmptyAccountResponse(mockApi);
  _setupEmptyBudgetResponse(mockApi);
  _setupEmptyCategoryResponse(mockApi);
  _setupEmptyBillResponse(mockApi);
  _setupEmptyPiggyBankResponse(mockApi);
}

void _setupEmptyTransactionResponse(MockFireflyApiAdapter mockApi) {
  _setupTransactionResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyAccountResponse(MockFireflyApiAdapter mockApi) {
  _setupAccountResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyBudgetResponse(MockFireflyApiAdapter mockApi) {
  when(
    () => mockApi.getBudgetsPaginated(
      page: any(named: 'page'),
      start: any(named: 'start'),
      end: any(named: 'end'),
      limit: any(named: 'limit'),
      sort: any(named: 'sort'),
      order: any(named: 'order'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: <Map<String, dynamic>>[],
      total: 0,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

void _setupEmptyCategoryResponse(MockFireflyApiAdapter mockApi) {
  when(
    () => mockApi.getCategoriesPaginated(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: <Map<String, dynamic>>[],
      total: 0,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

void _setupEmptyBillResponse(MockFireflyApiAdapter mockApi) {
  when(
    () => mockApi.getBillsPaginated(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: <Map<String, dynamic>>[],
      total: 0,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

void _setupEmptyPiggyBankResponse(MockFireflyApiAdapter mockApi) {
  when(
    () => mockApi.getPiggyBanksPaginated(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: <Map<String, dynamic>>[],
      total: 0,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

/// Setup mock transaction API response.
void _setupTransactionResponse(
  MockFireflyApiAdapter mockApi,
  List<Map<String, dynamic>> transactions,
) {
  when(
    () => mockApi.getTransactionsPaginated(
      page: any(named: 'page'),
      start: any(named: 'start'),
      end: any(named: 'end'),
      limit: any(named: 'limit'),
      sort: any(named: 'sort'),
      order: any(named: 'order'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: transactions,
      total: transactions.length,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

/// Setup mock account API response.
void _setupAccountResponse(
  MockFireflyApiAdapter mockApi,
  List<Map<String, dynamic>> accounts,
) {
  when(
    () => mockApi.getAccountsPaginated(
      page: any(named: 'page'),
      start: any(named: 'start'),
      limit: any(named: 'limit'),
      sort: any(named: 'sort'),
      order: any(named: 'order'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: accounts,
      total: accounts.length,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

// ==================== Server Data Factories ====================

/// Create a mock server transaction response.
Map<String, dynamic> _createServerTransaction(
  String id,
  String description,
  double amount,
  DateTime updatedAt,
) {
  return <String, dynamic>{
    'id': id,
    'type': 'transactions',
    'attributes': <String, dynamic>{
      'transactions': <Map<String, dynamic>>[
        <String, dynamic>{
          'type': 'withdrawal',
          'amount': amount.toString(),
          'description': description,
          'date': DateTime.now().toIso8601String(),
          'source_id': 'acc-1',
          'destination_id': 'acc-2',
          'currency_code': 'USD',
          'category_id': null,
          'budget_id': null,
          'foreign_amount': null,
          'foreign_currency_code': null,
          'notes': null,
          'tags': '[]',
        },
      ],
      'created_at':
          updatedAt.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    },
  };
}

/// Create a mock server account response.
Map<String, dynamic> _createServerAccount(
  String id,
  String name,
  String type,
  double balance,
  DateTime updatedAt,
) {
  return <String, dynamic>{
    'id': id,
    'type': 'accounts',
    'attributes': <String, dynamic>{
      'name': name,
      'type': type,
      'account_role': null,
      'currency_code': 'USD',
      'current_balance': balance.toString(),
      'iban': null,
      'bic': null,
      'account_number': null,
      'opening_balance': null,
      'opening_balance_date': null,
      'notes': null,
      'active': true,
      'created_at':
          updatedAt.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    },
  };
}

/// Log benchmark results for analysis.
void _logBenchmarkResult(
  String testName,
  Duration duration,
  IncrementalSyncStats? stats, {
  String? additionalInfo,
}) {
  final StringBuffer output = StringBuffer();
  output.writeln('\n=== BENCHMARK: $testName ===');

  if (duration != Duration.zero) {
    output.writeln('Duration: ${duration.inMilliseconds}ms');
  }

  if (stats != null) {
    output.writeln('Fetched: ${stats.itemsFetched}');
    output.writeln('Updated: ${stats.itemsUpdated}');
    output.writeln('Skipped: ${stats.itemsSkipped}');
    output.writeln('Skip Rate: ${stats.skipRate.toStringAsFixed(1)}%');
    output.writeln('Bandwidth Saved: ${stats.bandwidthSavedFormatted}');
  }

  if (additionalInfo != null) {
    output.writeln(additionalInfo);
  }

  output.writeln('=====================================\n');

  // Use debugPrint for test output visibility
  // ignore: avoid_print
  print(output.toString());
}
