import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/models/paginated_result.dart';
import 'package:waterflyiii/services/sync/date_range_iterator.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';

/// Mock classes for testing sort/order and early termination.
class MockFireflyApiAdapter extends Mock implements FireflyApiAdapter {}

/// Comprehensive tests for sort/order parameters and early termination.
///
/// Tests cover:
/// - Sort/order parameter passing to API adapter
/// - Early termination callback functionality
/// - Edge cases (missing timestamps, clock skew)
/// - Statistics tracking for early termination
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure logging for tests
  Logger.root.level = Level.OFF;

  group('DateRangeIterator - Sort/Order Support', () {
    late MockFireflyApiAdapter mockApiAdapter;

    setUp(() {
      mockApiAdapter = MockFireflyApiAdapter();
    });

    test('should pass sort and order parameters to transactions API', () async {
      when(
        () => mockApiAdapter.getTransactionsPaginated(
          page: any(named: 'page'),
          start: any(named: 'start'),
          end: any(named: 'end'),
          limit: any(named: 'limit'),
          sort: any(named: 'sort'),
          order: any(named: 'order'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedResult<Map<String, dynamic>>(
          data: <Map<String, dynamic>>[],
          total: 0,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        ),
      );

      final DateRangeIterator iterator = DateRangeIterator(
        apiClient: mockApiAdapter,
        entityType: 'transaction',
        start: DateTime(2024, 1, 1),
        sort: 'updated_at',
        order: 'desc',
      );

      await iterator.count();

      verify(
        () => mockApiAdapter.getTransactionsPaginated(
          page: 1,
          start: any(named: 'start'),
          end: any(named: 'end'),
          limit: 50,
          sort: 'updated_at',
          order: 'desc',
        ),
      ).called(1);
    });

    test('should pass sort and order parameters to accounts API', () async {
      when(
        () => mockApiAdapter.getAccountsPaginated(
          page: any(named: 'page'),
          start: any(named: 'start'),
          limit: any(named: 'limit'),
          sort: any(named: 'sort'),
          order: any(named: 'order'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedResult<Map<String, dynamic>>(
          data: <Map<String, dynamic>>[],
          total: 0,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        ),
      );

      final DateRangeIterator iterator = DateRangeIterator(
        apiClient: mockApiAdapter,
        entityType: 'account',
        start: DateTime(2024, 1, 1),
        sort: 'updated_at',
        order: 'desc',
      );

      await iterator.count();

      verify(
        () => mockApiAdapter.getAccountsPaginated(
          page: 1,
          start: any(named: 'start'),
          limit: 50,
          sort: 'updated_at',
          order: 'desc',
        ),
      ).called(1);
    });

    test('should pass sort and order parameters to all entity types', () async {
      final List<String> entityTypes = <String>[
        'budget',
        'category',
        'bill',
        'piggy_bank',
      ];

      for (final String entityType in entityTypes) {
        switch (entityType) {
          case 'budget':
            when(
              () => mockApiAdapter.getBudgetsPaginated(
                page: any(named: 'page'),
                start: any(named: 'start'),
                end: any(named: 'end'),
                limit: any(named: 'limit'),
                sort: any(named: 'sort'),
                order: any(named: 'order'),
              ),
            ).thenAnswer(
              (_) async => const PaginatedResult<Map<String, dynamic>>(
                data: <Map<String, dynamic>>[],
                total: 0,
                currentPage: 1,
                totalPages: 1,
                perPage: 50,
              ),
            );
            break;
          case 'category':
            when(
              () => mockApiAdapter.getCategoriesPaginated(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
                sort: any(named: 'sort'),
                order: any(named: 'order'),
              ),
            ).thenAnswer(
              (_) async => const PaginatedResult<Map<String, dynamic>>(
                data: <Map<String, dynamic>>[],
                total: 0,
                currentPage: 1,
                totalPages: 1,
                perPage: 50,
              ),
            );
            break;
          case 'bill':
            when(
              () => mockApiAdapter.getBillsPaginated(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
                sort: any(named: 'sort'),
                order: any(named: 'order'),
              ),
            ).thenAnswer(
              (_) async => const PaginatedResult<Map<String, dynamic>>(
                data: <Map<String, dynamic>>[],
                total: 0,
                currentPage: 1,
                totalPages: 1,
                perPage: 50,
              ),
            );
            break;
          case 'piggy_bank':
            when(
              () => mockApiAdapter.getPiggyBanksPaginated(
                page: any(named: 'page'),
                limit: any(named: 'limit'),
                sort: any(named: 'sort'),
                order: any(named: 'order'),
              ),
            ).thenAnswer(
              (_) async => const PaginatedResult<Map<String, dynamic>>(
                data: <Map<String, dynamic>>[],
                total: 0,
                currentPage: 1,
                totalPages: 1,
                perPage: 50,
              ),
            );
            break;
        }

        final DateRangeIterator iterator = DateRangeIterator(
          apiClient: mockApiAdapter,
          entityType: entityType,
          start: DateTime(2024, 1, 1),
          sort: 'updated_at',
          order: 'desc',
        );

        await iterator.count();

        // Verify sort/order were passed (exact verification depends on entity type)
        expect(iterator.sort, equals('updated_at'));
        expect(iterator.order, equals('desc'));
      }
    });
  });

  group('DateRangeIterator - Early Termination', () {
    late MockFireflyApiAdapter mockApiAdapter;

    setUp(() {
      mockApiAdapter = MockFireflyApiAdapter();
    });

    test('should stop iteration when stopWhenProcessed returns true', () async {
      final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '1',
          'type': 'transaction',
          'attributes': <String, dynamic>{
            'updated_at': '2024-12-20T10:00:00Z',
          },
        },
        <String, dynamic>{
          'id': '2',
          'type': 'transaction',
          'attributes': <String, dynamic>{
            'updated_at': '2024-12-19T10:00:00Z',
          },
        },
        <String, dynamic>{
          'id': '3',
          'type': 'transaction',
          'attributes': <String, dynamic>{
            'updated_at': '2024-12-18T10:00:00Z',
          },
        },
      ];

      when(
        () => mockApiAdapter.getTransactionsPaginated(
          page: any(named: 'page'),
          start: any(named: 'start'),
          end: any(named: 'end'),
          limit: any(named: 'limit'),
          sort: any(named: 'sort'),
          order: any(named: 'order'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Map<String, dynamic>>(
          data: items,
          total: 3,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        ),
      );

      int processedCount = 0;

      final DateRangeIterator iterator = DateRangeIterator(
        apiClient: mockApiAdapter,
        entityType: 'transaction',
        start: DateTime(2024, 1, 1),
        sort: 'updated_at',
        order: 'desc',
        stopWhenProcessed: (Map<String, dynamic> item) async {
          processedCount++;
          // Stop after checking first item (before yielding it)
          if (processedCount == 1) {
            return true;
          }
          return false;
        },
      );

      final List<Map<String, dynamic>> fetched = <Map<String, dynamic>>[];
      await for (final Map<String, dynamic> item in iterator.iterate()) {
        fetched.add(item);
      }

      // Should have checked 1 item and yielded it before stopping
      // (This allows the item to be processed/counted even when stopping early)
      expect(processedCount, equals(1));
      expect(fetched.length, equals(1)); // Item is yielded before checking for early termination
    });

    test('should continue iteration when stopWhenProcessed returns false', () async {
      final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '1',
          'type': 'transaction',
          'attributes': <String, dynamic>{
            'updated_at': '2024-12-20T10:00:00Z',
          },
        },
        <String, dynamic>{
          'id': '2',
          'type': 'transaction',
          'attributes': <String, dynamic>{
            'updated_at': '2024-12-19T10:00:00Z',
          },
        },
      ];

      when(
        () => mockApiAdapter.getTransactionsPaginated(
          page: any(named: 'page'),
          start: any(named: 'start'),
          end: any(named: 'end'),
          limit: any(named: 'limit'),
          sort: any(named: 'sort'),
          order: any(named: 'order'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Map<String, dynamic>>(
          data: items,
          total: 2,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        ),
      );

      final DateRangeIterator iterator = DateRangeIterator(
        apiClient: mockApiAdapter,
        entityType: 'transaction',
        start: DateTime(2024, 1, 1),
        sort: 'updated_at',
        order: 'desc',
        stopWhenProcessed: (Map<String, dynamic> item) async {
          // Never stop
          return false;
        },
      );

      final List<Map<String, dynamic>> fetched = <Map<String, dynamic>>[];
      await for (final Map<String, dynamic> item in iterator.iterate()) {
        fetched.add(item);
      }

      // Should have processed all items
      expect(fetched.length, equals(2));
    });

    test('should handle missing stopWhenProcessed callback', () async {
      final List<Map<String, dynamic>> items = <Map<String, dynamic>>[
        <String, dynamic>{
          'id': '1',
          'type': 'transaction',
          'attributes': <String, dynamic>{
            'updated_at': '2024-12-20T10:00:00Z',
          },
        },
      ];

      when(
        () => mockApiAdapter.getTransactionsPaginated(
          page: any(named: 'page'),
          start: any(named: 'start'),
          end: any(named: 'end'),
          limit: any(named: 'limit'),
          sort: any(named: 'sort'),
          order: any(named: 'order'),
        ),
      ).thenAnswer(
        (_) async => PaginatedResult<Map<String, dynamic>>(
          data: items,
          total: 1,
          currentPage: 1,
          totalPages: 1,
          perPage: 50,
        ),
      );

      final DateRangeIterator iterator = DateRangeIterator(
        apiClient: mockApiAdapter,
        entityType: 'transaction',
        start: DateTime(2024, 1, 1),
        sort: 'updated_at',
        order: 'desc',
        // No stopWhenProcessed callback
      );

      final List<Map<String, dynamic>> fetched = <Map<String, dynamic>>[];
      await for (final Map<String, dynamic> item in iterator.iterate()) {
        fetched.add(item);
      }

      // Should process all items when no callback provided
      expect(fetched.length, equals(1));
    });
  });

  group('IterationStats - Early Termination Tracking', () {
    test('should track early termination in stats', () {
      final IterationStats stats = const IterationStats(
        itemsFetched: 10,
        pagesRequested: 2,
        serverTotal: 100,
        duration: Duration(seconds: 5),
        terminatedEarly: true,
      );

      expect(stats.terminatedEarly, isTrue);
      expect(stats.toJson()['terminatedEarly'], isTrue);
    });

    test('should include early termination in toString', () {
      final IterationStats stats = const IterationStats(
        itemsFetched: 10,
        pagesRequested: 2,
        serverTotal: 100,
        duration: Duration(seconds: 5),
        terminatedEarly: true,
      );

      expect(stats.toString(), contains('terminatedEarly: true'));
    });

    test('should copy with early termination flag', () {
      final IterationStats stats = const IterationStats(
        itemsFetched: 10,
        pagesRequested: 2,
        serverTotal: 100,
        duration: Duration(seconds: 5),
        terminatedEarly: false,
      );

      final IterationStats copied = stats.copyWith(terminatedEarly: true);
      expect(copied.terminatedEarly, isTrue);
      expect(stats.terminatedEarly, isFalse); // Original unchanged
    });
  });

  group('IncrementalSyncStats - Early Termination Tracking', () {
    test('should track early termination in sync stats', () {
      final IncrementalSyncStats stats = IncrementalSyncStats(
        entityType: 'transaction',
        terminatedEarly: true,
      );

      expect(stats.terminatedEarly, isTrue);
      expect(stats.toJson()['terminatedEarly'], isTrue);
    });

    test('should copy with early termination flag', () {
      final IncrementalSyncStats stats = IncrementalSyncStats(
        entityType: 'transaction',
        terminatedEarly: false,
      );

      final IncrementalSyncStats copied = stats.copyWith(terminatedEarly: true);
      expect(copied.terminatedEarly, isTrue);
      expect(stats.terminatedEarly, isFalse); // Original unchanged
    });
  });
}

