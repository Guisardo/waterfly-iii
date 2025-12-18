import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:matcher/matcher.dart' as matcher;
import 'package:mocktail/mocktail.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/models/paginated_result.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';
import 'package:waterflyiii/services/sync/sync_progress_tracker.dart';

/// Mock classes for testing IncrementalSyncService.
///
/// These mocks allow comprehensive testing of the three-tier sync strategy
/// without requiring a live Firefly III server or actual network calls.
class MockFireflyApiAdapter extends Mock implements FireflyApiAdapter {}

class MockCacheService extends Mock implements CacheService {}

class MockSyncProgressTracker extends Mock implements SyncProgressTracker {}

/// Comprehensive test suite for IncrementalSyncService.
///
/// Tests cover:
/// - Three-tier sync strategy validation
/// - Timestamp comparison logic with clock skew handling
/// - Entity merging for all 6 entity types
/// - Cache integration for Tier 2 entities
/// - Statistics tracking and bandwidth savings calculation
/// - Error handling and recovery scenarios
/// - Sync window management and fallback to full sync
/// - Force sync functionality
/// - Progress tracking integration
///
/// Test organization:
/// 1. Setup and configuration tests
/// 2. Tier 1: Date-range filtered entity tests (transactions, accounts, budgets)
/// 3. Tier 2: Extended cache entity tests (categories, bills, piggy banks)
/// 4. Tier 3: Sync window management tests
/// 5. Statistics and metrics tests
/// 6. Error handling tests
/// 7. Integration scenarios
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure logging for tests
  Logger.root.level = Level.OFF;

  group('IncrementalSyncService', () {
    late AppDatabase database;
    late MockFireflyApiAdapter mockApiAdapter;
    late MockCacheService mockCacheService;
    late MockSyncProgressTracker mockProgressTracker;
    late IncrementalSyncService syncService;

    /// Create a fresh in-memory database for each test.
    ///
    /// This ensures test isolation and prevents state leakage between tests.
    setUp(() async {
      // Create in-memory database for isolated testing
      database = AppDatabase.forTesting(NativeDatabase.memory());

      // Initialize mocks
      mockApiAdapter = MockFireflyApiAdapter();
      mockCacheService = MockCacheService();
      mockProgressTracker = MockSyncProgressTracker();

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

      // Configure progress tracker behavior
      when(
        () => mockProgressTracker.incrementCompleted(
          operationId: any(named: 'operationId'),
        ),
      ).thenReturn(null);

      // Create service instance with test configuration
      syncService = IncrementalSyncService(
        database: database,
        apiAdapter: mockApiAdapter,
        cacheService: mockCacheService,
        progressTracker: mockProgressTracker,
        enableIncrementalSync: true,
        syncWindowDays: 30,
        cacheTtlHours: 24,
        maxDaysSinceFullSync: 7,
        clockSkewToleranceMinutes: 5,
      );

      // Initialize sync metadata for incremental sync
      await _initializeSyncMetadata(database);
    });

    /// Close database connection after each test.
    tearDown(() async {
      await database.close();
    });

    // ==================== Configuration Tests ====================

    group('Configuration', () {
      test('should use default configuration values', () {
        final IncrementalSyncService defaultService = IncrementalSyncService(
          database: database,
          apiAdapter: mockApiAdapter,
          cacheService: mockCacheService,
        );

        expect(defaultService.enableIncrementalSync, isTrue);
        expect(defaultService.syncWindowDays, equals(30));
        expect(defaultService.cacheTtlHours, equals(24));
        expect(defaultService.maxDaysSinceFullSync, equals(7));
        expect(defaultService.clockSkewToleranceMinutes, equals(5));
      });

      test('should accept custom configuration values', () {
        final IncrementalSyncService customService = IncrementalSyncService(
          database: database,
          apiAdapter: mockApiAdapter,
          cacheService: mockCacheService,
          enableIncrementalSync: false,
          syncWindowDays: 14,
          cacheTtlHours: 12,
          maxDaysSinceFullSync: 3,
          clockSkewToleranceMinutes: 10,
        );

        expect(customService.enableIncrementalSync, isFalse);
        expect(customService.syncWindowDays, equals(14));
        expect(customService.cacheTtlHours, equals(12));
        expect(customService.maxDaysSinceFullSync, equals(3));
        expect(customService.clockSkewToleranceMinutes, equals(10));
      });
    });

    // ==================== Incremental Sync Eligibility Tests ====================

    group('Incremental Sync Eligibility', () {
      test(
        'should require full sync when incremental sync is disabled',
        () async {
          final IncrementalSyncService disabledService = IncrementalSyncService(
            database: database,
            apiAdapter: mockApiAdapter,
            cacheService: mockCacheService,
            enableIncrementalSync: false,
          );

          final IncrementalSyncResult result =
              await disabledService.performIncrementalSync();

          expect(result.isIncremental, isFalse);
          expect(result.success, isFalse);
          expect(result.error, equals('Full sync required'));
        },
      );

      test(
        'should require full sync when no previous full sync exists',
        () async {
          // Clear sync metadata to simulate first-time sync
          await _clearSyncMetadata(database);

          final IncrementalSyncResult result =
              await syncService.performIncrementalSync();

          expect(result.isIncremental, isFalse);
          expect(result.success, isFalse);
          expect(result.error, equals('Full sync required'));
        },
      );

      test('should require full sync when last full sync is too old', () async {
        // Set last full sync to 10 days ago (exceeds maxDaysSinceFullSync of 7)
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 10)),
        );

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.isIncremental, isFalse);
        expect(result.success, isFalse);
        expect(result.error, equals('Full sync required'));
      });

      test('should allow incremental sync when full sync is recent', () async {
        // Set last full sync to 3 days ago (within maxDaysSinceFullSync of 7)
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 3)),
        );

        // Setup empty responses for all entity types
        _setupEmptyApiResponses(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.isIncremental, isTrue);
        expect(result.success, isTrue);
      });

      test(
        'should force full sync when forceFullSync parameter is true',
        () async {
          final IncrementalSyncResult result = await syncService
              .performIncrementalSync(forceFullSync: true);

          expect(result.isIncremental, isFalse);
          expect(result.success, isFalse);
          expect(result.error, equals('Full sync required'));
        },
      );
    });

    // ==================== Tier 1: Date-Range Filtered Tests ====================

    group('Tier 1: Transactions Sync', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Insert reference accounts required by transaction foreign keys
        await _insertReferenceAccounts(database);
      });

      test('should fetch transactions with date filter', () async {
        // Setup mock response with slightly different timestamps to avoid early termination
        final DateTime serverTimestamp1 = DateTime.now();
        final DateTime serverTimestamp2 = serverTimestamp1.add(const Duration(seconds: 1));
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction(
            '1',
            'Test Transaction 1',
            100.0,
            serverTimestamp1,
          ),
          _createServerTransaction(
            '2',
            'Test Transaction 2',
            200.0,
            serverTimestamp2,
          ),
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue, reason: 'Error: ${result.error}');
        expect(result.statsByEntity['transaction'], matcher.isNotNull);
        expect(result.statsByEntity['transaction']!.itemsFetched, equals(2));
        expect(result.statsByEntity['transaction']!.itemsUpdated, equals(2));
      });

      test('should skip unchanged transactions based on timestamp', () async {
        // First, insert an existing transaction with same timestamp
        final DateTime timestamp = DateTime.now().subtract(
          const Duration(hours: 1),
        );
        await _insertTransaction(
          database,
          '1',
          'Existing Transaction',
          100.0,
          timestamp,
        );

        // Setup API response with same timestamp (should be skipped)
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction(
            '1',
            'Existing Transaction',
            100.0,
            timestamp,
          ),
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['transaction']!.itemsFetched, equals(1));
        expect(result.statsByEntity['transaction']!.itemsSkipped, equals(1));
        expect(result.statsByEntity['transaction']!.itemsUpdated, equals(0));
      });

      test('should update transactions with newer server timestamp', () async {
        // Insert existing transaction with old timestamp
        final DateTime oldTimestamp = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        await _insertTransaction(
          database,
          '1',
          'Old Transaction',
          100.0,
          oldTimestamp,
        );

        // Setup API response with newer timestamp
        final DateTime newTimestamp = DateTime.now();
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction(
            '1',
            'Updated Transaction',
            150.0,
            newTimestamp,
          ),
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['transaction']!.itemsUpdated, equals(1));
        expect(result.statsByEntity['transaction']!.itemsSkipped, equals(0));

        // Verify database was updated
        final TransactionEntity? updatedTx =
            await (database.select(database.transactions)..where(
              ($TransactionsTable t) => t.serverId.equals('1'),
            )).getSingleOrNull();

        expect(updatedTx, matcher.isNotNull);
        expect(updatedTx!.description, equals('Updated Transaction'));
        expect(updatedTx.amount, equals(150.0));
      });

      test('should handle clock skew within tolerance', () async {
        // Insert transaction with timestamp
        final DateTime localTimestamp = DateTime.now();
        await _insertTransaction(
          database,
          '1',
          'Transaction',
          100.0,
          localTimestamp,
        );

        // Setup API response with timestamp within 5-minute tolerance
        final DateTime serverTimestamp = localTimestamp.add(
          const Duration(minutes: 3),
        );
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction('1', 'Transaction', 100.0, serverTimestamp),
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // Within tolerance, should be skipped
        expect(result.statsByEntity['transaction']!.itemsSkipped, equals(1));
      });

      test('should detect and handle clock skew beyond tolerance', () async {
        // Insert transaction with timestamp
        final DateTime localTimestamp = DateTime.now();
        await _insertTransaction(
          database,
          '1',
          'Transaction',
          100.0,
          localTimestamp,
        );

        // Setup API response with timestamp beyond tolerance
        final DateTime serverTimestamp = localTimestamp.add(
          const Duration(minutes: 10),
        );
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction('1', 'Transaction', 100.0, serverTimestamp),
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // Beyond tolerance, should be updated
        expect(result.statsByEntity['transaction']!.itemsUpdated, equals(1));
      });
    });

    group('Tier 1: Accounts Sync', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
      });

      test('should fetch and sync accounts', () async {
        final DateTime serverTimestamp = DateTime.now();

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupAccountResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerAccount(
            'acc-1',
            'Checking Account',
            'asset',
            1000.0,
            serverTimestamp,
          ),
          _createServerAccount(
            'acc-2',
            'Savings Account',
            'asset',
            5000.0,
            serverTimestamp,
          ),
        ]);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['account']!.itemsFetched, equals(2));
        expect(result.statsByEntity['account']!.itemsUpdated, equals(2));
      });

      test('should skip unchanged accounts', () async {
        final DateTime timestamp = DateTime.now().subtract(
          const Duration(hours: 1),
        );
        await _insertAccount(
          database,
          'acc-1',
          'Checking',
          'asset',
          1000.0,
          timestamp,
        );

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupAccountResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerAccount('acc-1', 'Checking', 'asset', 1000.0, timestamp),
        ]);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.statsByEntity['account']!.itemsSkipped, equals(1));
      });
    });

    group('Tier 1: Budgets Sync', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
      });

      test('should fetch and sync budgets', () async {
        final DateTime serverTimestamp = DateTime.now();

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupBudgetResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerBudget('bud-1', 'Groceries', serverTimestamp),
          _createServerBudget('bud-2', 'Entertainment', serverTimestamp),
        ]);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['budget']!.itemsFetched, equals(2));
        expect(result.statsByEntity['budget']!.itemsUpdated, equals(2));
      });
    });

    // ==================== Tier 2: Extended Cache Tests ====================

    group('Tier 2: Categories Sync with Cache', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
      });

      test('should skip sync when cache is fresh', () async {
        // Configure cache as fresh
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => true);

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['category']!.apiCallsSaved, equals(1));

        // Verify no API call was made for categories
        verifyNever(
          () => mockApiAdapter.getCategoriesPaginated(
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        );
      });

      test('should fetch categories when cache is stale', () async {
        // Configure cache as stale
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => false);

        final DateTime serverTimestamp = DateTime.now();
        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupCategoryResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerCategory('cat-1', 'Food', serverTimestamp),
          _createServerCategory('cat-2', 'Transport', serverTimestamp),
        ]);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['category']!.itemsFetched, equals(2));
        expect(result.statsByEntity['category']!.itemsUpdated, equals(2));

        // Verify cache was updated
        verify(
          () => mockCacheService.set<bool>(
            entityType: 'category_list',
            entityId: 'all',
            data: true,
            ttl: any(named: 'ttl'),
          ),
        ).called(1);
      });
    });

    group('Tier 2: Bills Sync with Cache', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
      });

      test('should skip sync when cache is fresh', () async {
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => true);

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['bill']!.apiCallsSaved, equals(1));
      });

      test('should fetch bills when cache is stale', () async {
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => false);

        final DateTime serverTimestamp = DateTime.now();
        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupBillResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerBill('bill-1', 'Rent', 1000.0, serverTimestamp),
        ]);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.statsByEntity['bill']!.itemsFetched, equals(1));
        expect(result.statsByEntity['bill']!.itemsUpdated, equals(1));
      });
    });

    group('Tier 2: Piggy Banks Sync with Cache', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Insert reference accounts required by piggy bank foreign keys
        await _insertReferenceAccounts(database);
      });

      test('should skip sync when cache is fresh', () async {
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => true);

        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        expect(result.statsByEntity['piggy_bank']!.apiCallsSaved, equals(1));
      });

      test('should fetch piggy banks when cache is stale', () async {
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => false);

        final DateTime serverTimestamp = DateTime.now();
        _setupEmptyTransactionResponse(mockApiAdapter);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupPiggyBankResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerPiggyBank(
            'pb-1',
            'Vacation',
            'acc-1',
            500.0,
            serverTimestamp,
          ),
        ]);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.statsByEntity['piggy_bank']!.itemsFetched, equals(1));
        expect(result.statsByEntity['piggy_bank']!.itemsUpdated, equals(1));
      });
    });

    // ==================== Statistics and Metrics Tests ====================

    group('Statistics and Metrics', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Insert reference accounts required by transaction foreign keys
        await _insertReferenceAccounts(database);
      });

      test('should calculate bandwidth saved correctly', () async {
        final DateTime timestamp = DateTime.now().subtract(
          const Duration(hours: 1),
        );

        // Insert existing transactions that will be skipped
        await _insertTransaction(database, '1', 'T1', 100.0, timestamp);
        await _insertTransaction(database, '2', 'T2', 200.0, timestamp);
        await _insertTransaction(database, '3', 'T3', 300.0, timestamp);

        // Setup response with same timestamps (will be skipped)
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction('1', 'T1', 100.0, timestamp),
          _createServerTransaction('2', 'T2', 200.0, timestamp),
          _createServerTransaction('3', 'T3', 300.0, timestamp),
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        final IncrementalSyncStats stats = result.statsByEntity['transaction']!;
        expect(stats.itemsSkipped, equals(3));
        // 3 skipped transactions * 2048 bytes each = 6144 bytes saved
        expect(stats.bandwidthSavedBytes, equals(3 * 2048));
      });

      test('should calculate overall skip rate', () async {
        _setupEmptyApiResponses(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // With no items, skip rate should be 0
        expect(result.overallSkipRate, equals(0.0));
      });

      test('should track sync statistics in database', () async {
        _setupEmptyApiResponses(mockApiAdapter);

        await syncService.performIncrementalSync();

        // Verify statistics were saved to database
        final List<SyncStatisticsEntity> stats =
            await database.select(database.syncStatistics).get();
        expect(stats, isNotEmpty);
      });

      test('should update last incremental sync time', () async {
        _setupEmptyApiResponses(mockApiAdapter);

        final DateTime beforeSync = DateTime.now();
        await syncService.performIncrementalSync();
        final DateTime afterSync = DateTime.now();

        // Check last incremental sync was updated
        final SyncMetadataEntity? metadata =
            await (database.select(database.syncMetadata)..where(
              ($SyncMetadataTable m) => m.key.equals('last_incremental_sync'),
            )).getSingleOrNull();

        expect(metadata, matcher.isNotNull);
        final DateTime syncTime = DateTime.parse(metadata!.value);
        expect(
          syncTime.isAfter(beforeSync.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        expect(
          syncTime.isBefore(afterSync.add(const Duration(seconds: 1))),
          isTrue,
        );
      });
    });

    // ==================== Force Sync Tests ====================

    group('Force Sync Entity Type', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Insert reference accounts required by transaction foreign keys
        await _insertReferenceAccounts(database);
      });

      test('should force sync transactions bypassing cache', () async {
        final DateTime serverTimestamp = DateTime.now();
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction(
            '1',
            'Forced Transaction',
            100.0,
            serverTimestamp,
          ),
        ]);

        final IncrementalSyncStats stats = await syncService
            .forceSyncEntityType('transaction');

        expect(stats.itemsFetched, equals(1));
        expect(stats.itemsUpdated, equals(1));

        // Verify cache was invalidated
        verify(
          () => mockCacheService.invalidate('transaction_list', 'all'),
        ).called(1);
      });

      test('should force sync categories bypassing cache', () async {
        final DateTime serverTimestamp = DateTime.now();
        _setupCategoryResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerCategory('cat-1', 'Forced Category', serverTimestamp),
        ]);

        final IncrementalSyncStats stats = await syncService
            .forceSyncEntityType('category');

        expect(stats.itemsFetched, equals(1));
        expect(stats.itemsUpdated, equals(1));

        verify(
          () => mockCacheService.invalidate('category_list', 'all'),
        ).called(1);
      });

      test('should throw error for unknown entity type', () {
        expect(
          () => syncService.forceSyncEntityType('unknown'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    // ==================== Error Handling Tests ====================

    group('Error Handling', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Insert reference accounts required by transaction foreign keys
        await _insertReferenceAccounts(database);
      });

      test('should handle API errors gracefully', () async {
        // Setup API to throw error
        when(
          () => mockApiAdapter.getTransactionsPaginated(
            page: any(named: 'page'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
            order: any(named: 'order'),
          ),
        ).thenThrow(Exception('API Error'));

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // Sync fails overall when any entity fails
        expect(result.success, isFalse);
        // The aggregate error message indicates which entities failed
        expect(result.error, contains('transaction'));
        // The individual entity stats contain the specific error
        expect(
          result.statsByEntity['transaction']?.error,
          contains('API Error'),
        );
      });

      test('should include error details in stats', () async {
        when(
          () => mockApiAdapter.getTransactionsPaginated(
            page: any(named: 'page'),
            start: any(named: 'start'),
            end: any(named: 'end'),
            limit: any(named: 'limit'),
            sort: any(named: 'sort'),
            order: any(named: 'order'),
          ),
        ).thenThrow(Exception('Transaction fetch failed'));

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isFalse);
        expect(result.statsByEntity['transaction']?.success, isFalse);
        expect(
          result.statsByEntity['transaction']?.error,
          contains('Transaction fetch failed'),
        );
      });

      test('should handle null updated_at timestamps', () async {
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          <String, dynamic>{
            'id': '1',
            'type': 'transactions',
            'attributes': <String, dynamic>{
              'transactions': <Map<String, dynamic>>[
                <String, dynamic>{
                  'type': 'withdrawal',
                  'amount': '100.00',
                  'description': 'No timestamp',
                  'date': DateTime.now().toIso8601String(),
                  'source_id': 'acc-1',
                  'destination_id': 'acc-2',
                  'currency_code': 'USD',
                },
              ],
              'updated_at': null, // No timestamp
            },
          },
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        // Should update (not skip) when timestamp is null
        expect(result.success, isTrue);
        expect(result.statsByEntity['transaction']!.itemsUpdated, equals(1));
      });
    });

    // ==================== Integration Scenario Tests ====================

    group('Integration Scenarios', () {
      setUp(() async {
        await _setLastFullSyncTime(
          database,
          DateTime.now().subtract(const Duration(days: 1)),
        );
        // Insert reference accounts required by transaction foreign keys
        await _insertReferenceAccounts(database);
      });

      test('should sync all entity types in order', () async {
        final DateTime serverTimestamp = DateTime.now();

        // Use account 'acc-new' which doesn't conflict with the reference accounts
        // (acc-1, acc-2 are created by _insertReferenceAccounts for transaction FK constraints)
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction(
            'tx-1',
            'Transaction',
            100.0,
            serverTimestamp,
          ),
        ]);
        _setupAccountResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerAccount(
            'acc-new',
            'New Account',
            'asset',
            1000.0,
            serverTimestamp,
          ),
        ]);
        _setupBudgetResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerBudget('bud-1', 'Budget', serverTimestamp),
        ]);
        _setupCategoryResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerCategory('cat-1', 'Category', serverTimestamp),
        ]);
        _setupBillResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerBill('bill-1', 'Bill', 100.0, serverTimestamp),
        ]);
        _setupPiggyBankResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerPiggyBank(
            'pb-1',
            'PiggyBank',
            'acc-1',
            500.0,
            serverTimestamp,
          ),
        ]);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue, reason: 'Error: ${result.error}');
        expect(
          result.statsByEntity.length,
          equals(6),
          reason: 'Entities: ${result.statsByEntity.keys.toList()}',
        );
        expect(result.totalFetched, equals(6));
        expect(result.totalUpdated, equals(6));
      });

      test('should handle mixed updates and skips', () async {
        final DateTime oldTimestamp = DateTime.now().subtract(
          const Duration(hours: 2),
        );
        final DateTime newTimestamp = DateTime.now();

        // Insert existing data
        await _insertTransaction(database, '1', 'Old', 100.0, oldTimestamp);
        await _insertTransaction(database, '2', 'Same', 200.0, oldTimestamp);

        // Setup API response: one updated, one unchanged
        _setupTransactionResponse(mockApiAdapter, <Map<String, dynamic>>[
          _createServerTransaction(
            '1',
            'Updated',
            150.0,
            newTimestamp,
          ), // Updated
          _createServerTransaction('2', 'Same', 200.0, oldTimestamp), // Same
        ]);
        _setupEmptyAccountResponse(mockApiAdapter);
        _setupEmptyBudgetResponse(mockApiAdapter);
        _setupEmptyCategoryResponse(mockApiAdapter);
        _setupEmptyBillResponse(mockApiAdapter);
        _setupEmptyPiggyBankResponse(mockApiAdapter);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);
        final IncrementalSyncStats txStats =
            result.statsByEntity['transaction']!;
        expect(txStats.itemsFetched, equals(2));
        expect(txStats.itemsUpdated, equals(1));
        expect(txStats.itemsSkipped, equals(1));
      });

      test('should calculate correct aggregate statistics', () async {
        _setupEmptyApiResponses(mockApiAdapter);
        when(
          () => mockCacheService.isFresh('category_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('bill_list', 'all'),
        ).thenAnswer((_) async => true);
        when(
          () => mockCacheService.isFresh('piggy_bank_list', 'all'),
        ).thenAnswer((_) async => true);

        final IncrementalSyncResult result =
            await syncService.performIncrementalSync();

        expect(result.success, isTrue);

        // Verify aggregate statistics
        final int totalApiCallsSaved = result.statsByEntity.values.fold<int>(
          0,
          (int sum, IncrementalSyncStats stats) => sum + stats.apiCallsSaved,
        );

        expect(totalApiCallsSaved, equals(3)); // 3 cached entity types
      });
    });

    // ==================== IncrementalSyncStats Model Tests ====================

    group('IncrementalSyncStats Model', () {
      test('should calculate skip rate correctly', () {
        final IncrementalSyncStats stats = IncrementalSyncStats(
          entityType: 'transaction',
          itemsFetched: 100,
          itemsUpdated: 30,
          itemsSkipped: 70,
        );

        expect(stats.skipRate, equals(70.0));
        expect(stats.updateRate, equals(30.0));
      });

      test('should format bandwidth saved correctly', () {
        final IncrementalSyncStats bytesStats = IncrementalSyncStats(
          entityType: 'transaction',
          bandwidthSavedBytes: 500,
        );
        expect(bytesStats.bandwidthSavedFormatted, equals('500 B'));

        final IncrementalSyncStats kbStats = IncrementalSyncStats(
          entityType: 'transaction',
          bandwidthSavedBytes: 2048,
        );
        expect(kbStats.bandwidthSavedFormatted, equals('2.0 KB'));

        final IncrementalSyncStats mbStats = IncrementalSyncStats(
          entityType: 'transaction',
          bandwidthSavedBytes: 2 * 1024 * 1024,
        );
        expect(mbStats.bandwidthSavedFormatted, equals('2.0 MB'));
      });

      test('should serialize to JSON correctly', () {
        final IncrementalSyncStats stats = IncrementalSyncStats(
          entityType: 'transaction',
          itemsFetched: 10,
          itemsUpdated: 3,
          itemsSkipped: 7,
        );

        final Map<String, dynamic> json = stats.toJson();

        expect(json['entityType'], equals('transaction'));
        expect(json['itemsFetched'], equals(10));
        expect(json['itemsUpdated'], equals(3));
        expect(json['itemsSkipped'], equals(7));
        expect(json['skipRate'], equals(70.0));
      });
    });

    // ==================== IncrementalSyncResult Model Tests ====================

    group('IncrementalSyncResult Model', () {
      test('should aggregate statistics from all entities', () {
        final IncrementalSyncResult result = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 10),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 30,
              itemsSkipped: 70,
              bandwidthSavedBytes: 70 * 2048,
            ),
            'account': IncrementalSyncStats(
              entityType: 'account',
              itemsFetched: 10,
              itemsUpdated: 2,
              itemsSkipped: 8,
              bandwidthSavedBytes: 8 * 1024,
            ),
          },
        );

        expect(result.totalFetched, equals(110));
        expect(result.totalUpdated, equals(32));
        expect(result.totalSkipped, equals(78));
        expect(result.totalBandwidthSaved, equals(70 * 2048 + 8 * 1024));
        expect(result.overallSkipRate, closeTo(70.9, 0.1));
      });

      test('should serialize to JSON correctly', () {
        final IncrementalSyncResult result = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 5),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(entityType: 'transaction'),
          },
        );

        final Map<String, dynamic> json = result.toJson();

        expect(json['isIncremental'], isTrue);
        expect(json['success'], isTrue);
        expect(json['durationMs'], equals(5000));
        expect(json['statsByEntity'], isNotEmpty);
      });
    });
  });
}

// ==================== Test Helpers ====================

/// Initialize sync metadata for a fresh database.
///
/// Sets up the last_full_sync timestamp to enable incremental sync testing.
/// Uses insertOnConflictUpdate to handle cases where migration already created entries.
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

/// Clear all sync metadata from database.
Future<void> _clearSyncMetadata(AppDatabase database) async {
  await database.delete(database.syncMetadata).go();
}

/// Set the last full sync time in database.
Future<void> _setLastFullSyncTime(AppDatabase database, DateTime time) async {
  await database
      .into(database.syncMetadata)
      .insertOnConflictUpdate(
        SyncMetadataEntityCompanion.insert(
          key: 'last_full_sync',
          value: time.toIso8601String(),
          updatedAt: DateTime.now(),
        ),
      );
}

/// Insert required reference accounts used by transactions in tests.
///
/// Creates accounts 'acc-1' and 'acc-2' which are referenced by test transactions.
/// This is needed because the transactions table has foreign key constraints
/// referencing the accounts table.
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
      .insert(
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
      .insert(
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

void _setupEmptyTransactionResponse(MockFireflyApiAdapter mockApi) {
  _setupTransactionResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyAccountResponse(MockFireflyApiAdapter mockApi) {
  _setupAccountResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyBudgetResponse(MockFireflyApiAdapter mockApi) {
  _setupBudgetResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyCategoryResponse(MockFireflyApiAdapter mockApi) {
  _setupCategoryResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyBillResponse(MockFireflyApiAdapter mockApi) {
  _setupBillResponse(mockApi, <Map<String, dynamic>>[]);
}

void _setupEmptyPiggyBankResponse(MockFireflyApiAdapter mockApi) {
  _setupPiggyBankResponse(mockApi, <Map<String, dynamic>>[]);
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

/// Setup mock budget API response.
void _setupBudgetResponse(
  MockFireflyApiAdapter mockApi,
  List<Map<String, dynamic>> budgets,
) {
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
      data: budgets,
      total: budgets.length,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

/// Setup mock category API response.
void _setupCategoryResponse(
  MockFireflyApiAdapter mockApi,
  List<Map<String, dynamic>> categories,
) {
  when(
    () => mockApi.getCategoriesPaginated(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: categories,
      total: categories.length,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

/// Setup mock bill API response.
void _setupBillResponse(
  MockFireflyApiAdapter mockApi,
  List<Map<String, dynamic>> bills,
) {
  when(
    () => mockApi.getBillsPaginated(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: bills,
      total: bills.length,
      currentPage: 1,
      totalPages: 1,
      perPage: 50,
    ),
  );
}

/// Setup mock piggy bank API response.
void _setupPiggyBankResponse(
  MockFireflyApiAdapter mockApi,
  List<Map<String, dynamic>> piggyBanks,
) {
  when(
    () => mockApi.getPiggyBanksPaginated(
      page: any(named: 'page'),
      limit: any(named: 'limit'),
    ),
  ).thenAnswer(
    (_) async => PaginatedResult<Map<String, dynamic>>(
      data: piggyBanks,
      total: piggyBanks.length,
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

/// Create a mock server budget response.
Map<String, dynamic> _createServerBudget(
  String id,
  String name,
  DateTime updatedAt,
) {
  return <String, dynamic>{
    'id': id,
    'type': 'budgets',
    'attributes': <String, dynamic>{
      'name': name,
      'active': true,
      'auto_budget_type': null,
      'auto_budget_amount': null,
      'auto_budget_period': null,
      'created_at':
          updatedAt.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    },
  };
}

/// Create a mock server category response.
Map<String, dynamic> _createServerCategory(
  String id,
  String name,
  DateTime updatedAt,
) {
  return <String, dynamic>{
    'id': id,
    'type': 'categories',
    'attributes': <String, dynamic>{
      'name': name,
      'notes': null,
      'created_at':
          updatedAt.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    },
  };
}

/// Create a mock server bill response.
Map<String, dynamic> _createServerBill(
  String id,
  String name,
  double amount,
  DateTime updatedAt,
) {
  return <String, dynamic>{
    'id': id,
    'type': 'bills',
    'attributes': <String, dynamic>{
      'name': name,
      'amount_min': amount.toString(),
      'amount_max': amount.toString(),
      'currency_code': 'USD',
      'date': DateTime.now().toIso8601String(),
      'repeat_freq': 'monthly',
      'skip': 0,
      'active': true,
      'notes': null,
      'created_at':
          updatedAt.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    },
  };
}

/// Create a mock server piggy bank response.
Map<String, dynamic> _createServerPiggyBank(
  String id,
  String name,
  String accountId,
  double currentAmount,
  DateTime updatedAt,
) {
  return <String, dynamic>{
    'id': id,
    'type': 'piggy_banks',
    'attributes': <String, dynamic>{
      'name': name,
      'account_id': accountId,
      'target_amount': '1000.00',
      'current_amount': currentAmount.toString(),
      'start_date': null,
      'target_date': null,
      'notes': null,
      'created_at':
          updatedAt.subtract(const Duration(days: 1)).toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    },
  };
}
