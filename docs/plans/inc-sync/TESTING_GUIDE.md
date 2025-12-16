# Testing Guide for Incremental Sync

This document provides comprehensive testing strategies for the incremental sync feature in Waterfly III.

## Table of Contents

- [Testing Philosophy](#testing-philosophy)
- [Unit Tests](#unit-tests)
- [Integration Tests](#integration-tests)
- [Widget Tests](#widget-tests)
- [Performance Tests](#performance-tests)
- [Edge Case Testing](#edge-case-testing)
- [Manual Testing Checklist](#manual-testing-checklist)
- [Test Data Generation](#test-data-generation)

## Testing Philosophy

### Coverage Targets

- **Unit Tests:** >90% coverage for sync logic
- **Integration Tests:** >70% coverage for full sync flows
- **Widget Tests:** >80% coverage for UI components
- **Performance Tests:** Verify targets (70% bandwidth, 60% speed reduction)

### Testing Principles

1. **Test Behavior, Not Implementation:** Focus on what the code does, not how
2. **Test Edge Cases:** Clock skew, pagination errors, network failures
3. **Use Realistic Data:** Mirror production data volumes and patterns
4. **Isolate Tests:** Each test should be independent and repeatable
5. **Fast Tests:** Unit tests should run in milliseconds, integration in seconds

## Unit Tests

### Test Structure

**Location:** `test/services/sync/incremental_sync_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:waterfly_iii/services/sync/sync_manager.dart';
import 'package:waterfly_iii/data/local/database/app_database.dart';

// Mocks
class MockAppDatabase extends Mock implements AppDatabase {}
class MockFireflyApiAdapter extends Mock implements FireflyApiAdapter {}
class MockCacheService extends Mock implements CacheService {}

void main() {
  group('IncrementalSync', () {
    late SyncManager syncManager;
    late MockAppDatabase mockDb;
    late MockFireflyApiAdapter mockApi;
    late MockCacheService mockCache;

    setUp(() {
      mockDb = MockAppDatabase();
      mockApi = MockFireflyApiAdapter();
      mockCache = MockCacheService();

      syncManager = SyncManager(
        database: mockDb,
        apiAdapter: mockApi,
        cacheService: mockCache,
      );
    });

    // Tests go here
  });
}
```

### Critical Test Cases

#### 1. Timestamp Comparison Logic

```dart
group('Timestamp Comparison', () {
  test('should detect new entities', () async {
    // Arrange: Entity doesn't exist locally
    when(() => mockDb.getTransaction('123'))
        .thenAnswer((_) async => null);

    // Act
    final hasChanged = await syncManager.hasEntityChanged(
      '123',
      DateTime(2024, 12, 16),
      'transaction',
    );

    // Assert
    expect(hasChanged, true);
  });

  test('should detect entities without timestamp', () async {
    // Arrange: Entity exists but has no serverUpdatedAt
    when(() => mockDb.getTransaction('123'))
        .thenAnswer((_) async => TransactionEntity(
          id: '123',
          serverUpdatedAt: null,
        ));

    // Act
    final hasChanged = await syncManager.hasEntityChanged(
      '123',
      DateTime(2024, 12, 16),
      'transaction',
    );

    // Assert
    expect(hasChanged, true);
  });

  test('should detect newer server timestamp', () async {
    // Arrange: Local older, server newer
    final localTime = DateTime(2024, 12, 10);
    final serverTime = DateTime(2024, 12, 15);

    when(() => mockDb.getTransaction('123'))
        .thenAnswer((_) async => TransactionEntity(
          id: '123',
          serverUpdatedAt: localTime,
        ));

    // Act
    final hasChanged = await syncManager.hasEntityChanged(
      '123',
      serverTime,
      'transaction',
    );

    // Assert
    expect(hasChanged, true);
  });

  test('should skip unchanged entities (same timestamp)', () async {
    // Arrange: Same timestamp
    final timestamp = DateTime(2024, 12, 10);

    when(() => mockDb.getTransaction('123'))
        .thenAnswer((_) async => TransactionEntity(
          id: '123',
          serverUpdatedAt: timestamp,
        ));

    // Act
    final hasChanged = await syncManager.hasEntityChanged(
      '123',
      timestamp,
      'transaction',
    );

    // Assert
    expect(hasChanged, false);
  });

  test('should handle clock skew with tolerance', () async {
    // Arrange: 3-minute difference (within 5-minute tolerance)
    final localTime = DateTime(2024, 12, 10, 14, 0);
    final serverTime = DateTime(2024, 12, 10, 14, 3);

    when(() => mockDb.getTransaction('123'))
        .thenAnswer((_) async => TransactionEntity(
          id: '123',
          serverUpdatedAt: localTime,
        ));

    // Act
    final hasChanged = await syncManager.hasEntityChanged(
      '123',
      serverTime,
      'transaction',
    );

    // Assert
    expect(hasChanged, false); // Within tolerance
  });

  test('should detect change beyond tolerance', () async {
    // Arrange: 10-minute difference (beyond 5-minute tolerance)
    final localTime = DateTime(2024, 12, 10, 14, 0);
    final serverTime = DateTime(2024, 12, 10, 14, 10);

    when(() => mockDb.getTransaction('123'))
        .thenAnswer((_) async => TransactionEntity(
          id: '123',
          serverUpdatedAt: localTime,
        ));

    // Act
    final hasChanged = await syncManager.hasEntityChanged(
      '123',
      serverTime,
      'transaction',
    );

    // Assert
    expect(hasChanged, true); // Beyond tolerance
  });
});
```

#### 2. Incremental Sync Logic

```dart
group('Incremental Sync Logic', () {
  test('should fetch only transactions in date range', () async {
    // Arrange
    final since = DateTime(2024, 12, 1);
    final mockTransactions = [
      _mockTransaction('1', updatedAt: DateTime(2024, 12, 5)),
      _mockTransaction('2', updatedAt: DateTime(2024, 12, 10)),
    ];

    when(() => mockApi.getTransactionsSince(since))
        .thenAnswer((_) async => mockTransactions);

    when(() => mockDb.getTransaction(any()))
        .thenAnswer((_) async => null); // All new

    // Act
    await syncManager.syncTransactionsIncremental(since);

    // Assert
    verify(() => mockApi.getTransactionsSince(since)).called(1);
    verify(() => mockDb.insertTransaction(any())).called(2);
  });

  test('should skip unchanged transactions', () async {
    // Arrange: Server transactions with same timestamps as local
    final since = DateTime(2024, 12, 1);
    final timestamp = DateTime(2024, 12, 5);

    final mockTransactions = [
      _mockTransaction('1', updatedAt: timestamp),
    ];

    when(() => mockApi.getTransactionsSince(since))
        .thenAnswer((_) async => mockTransactions);

    when(() => mockDb.getTransaction('1'))
        .thenAnswer((_) async => TransactionEntity(
          id: '1',
          serverUpdatedAt: timestamp, // Same timestamp
        ));

    // Act
    final result = await syncManager.syncTransactionsIncremental(since);

    // Assert
    expect(result.itemsSkipped, 1);
    expect(result.itemsUpdated, 0);
    verifyNever(() => mockDb.updateTransaction(any()));
  });

  test('should update only changed transactions', () async {
    // Arrange: Mix of changed and unchanged
    final since = DateTime(2024, 12, 1);

    final mockTransactions = [
      _mockTransaction('1', updatedAt: DateTime(2024, 12, 10)), // Changed
      _mockTransaction('2', updatedAt: DateTime(2024, 12, 5)),  // Unchanged
    ];

    when(() => mockApi.getTransactionsSince(since))
        .thenAnswer((_) async => mockTransactions);

    when(() => mockDb.getTransaction('1'))
        .thenAnswer((_) async => TransactionEntity(
          id: '1',
          serverUpdatedAt: DateTime(2024, 12, 5), // Older
        ));

    when(() => mockDb.getTransaction('2'))
        .thenAnswer((_) async => TransactionEntity(
          id: '2',
          serverUpdatedAt: DateTime(2024, 12, 5), // Same
        ));

    // Act
    final result = await syncManager.syncTransactionsIncremental(since);

    // Assert
    expect(result.itemsUpdated, 1);
    expect(result.itemsSkipped, 1);
    verify(() => mockDb.updateTransaction(any())).called(1);
  });

  test('should track statistics accurately', () async {
    // Arrange
    final since = DateTime(2024, 12, 1);
    final mockTransactions = List.generate(
      100,
      (i) => _mockTransaction('$i', updatedAt: DateTime(2024, 12, i % 15 + 1)),
    );

    when(() => mockApi.getTransactionsSince(since))
        .thenAnswer((_) async => mockTransactions);

    // 50 unchanged, 50 changed
    when(() => mockDb.getTransaction(any()))
        .thenAnswer((invocation) async {
      final id = invocation.positionalArguments[0] as String;
      final index = int.parse(id);
      return TransactionEntity(
        id: id,
        serverUpdatedAt: index < 50
            ? DateTime(2024, 12, index % 15 + 1) // Same
            : DateTime(2024, 12, 1), // Older
      );
    });

    // Act
    final result = await syncManager.syncTransactionsIncremental(since);

    // Assert
    expect(result.itemsFetched, 100);
    expect(result.itemsUpdated, 50);
    expect(result.itemsSkipped, 50);
  });
});
```

#### 3. Cache Strategy Tests

```dart
group('Cache Strategy', () {
  test('should skip categories sync if cache is fresh', () async {
    // Arrange: Fresh cache (within 24 hours)
    final cachedAt = DateTime.now().subtract(Duration(hours: 12));

    when(() => mockCache.getCacheMetadata('category_list', 'all'))
        .thenAnswer((_) async => CacheMetadataEntity(
          entityType: 'category_list',
          entityId: 'all',
          cachedAt: cachedAt,
          ttlSeconds: 86400, // 24 hours
          isInvalidated: false,
        ));

    // Act
    await syncManager.syncCategoriesIncremental();

    // Assert
    verifyNever(() => mockApi.getAllCategories());
  });

  test('should fetch categories if cache is stale', () async {
    // Arrange: Stale cache (>24 hours)
    final cachedAt = DateTime.now().subtract(Duration(hours: 25));

    when(() => mockCache.getCacheMetadata('category_list', 'all'))
        .thenAnswer((_) async => CacheMetadataEntity(
          entityType: 'category_list',
          entityId: 'all',
          cachedAt: cachedAt,
          ttlSeconds: 86400,
          isInvalidated: false,
        ));

    when(() => mockApi.getAllCategories())
        .thenAnswer((_) async => [_mockCategory('1')]);

    // Act
    await syncManager.syncCategoriesIncremental();

    // Assert
    verify(() => mockApi.getAllCategories()).called(1);
  });

  test('should fetch categories if cache is invalidated', () async {
    // Arrange: Fresh cache but invalidated
    final cachedAt = DateTime.now().subtract(Duration(hours: 12));

    when(() => mockCache.getCacheMetadata('category_list', 'all'))
        .thenAnswer((_) async => CacheMetadataEntity(
          entityType: 'category_list',
          entityId: 'all',
          cachedAt: cachedAt,
          ttlSeconds: 86400,
          isInvalidated: true, // Manually invalidated
        ));

    when(() => mockApi.getAllCategories())
        .thenAnswer((_) async => [_mockCategory('1')]);

    // Act
    await syncManager.syncCategoriesIncremental();

    // Assert
    verify(() => mockApi.getAllCategories()).called(1);
  });

  test('should force sync categories (bypass cache)', () async {
    // Arrange: Fresh cache
    final cachedAt = DateTime.now().subtract(Duration(hours: 1));

    when(() => mockCache.getCacheMetadata('category_list', 'all'))
        .thenAnswer((_) async => CacheMetadataEntity(
          entityType: 'category_list',
          entityId: 'all',
          cachedAt: cachedAt,
          ttlSeconds: 86400,
          isInvalidated: false,
        ));

    when(() => mockCache.invalidate(
          entityType: 'category_list',
          entityId: 'all',
        )).thenAnswer((_) async => {});

    when(() => mockApi.getAllCategories())
        .thenAnswer((_) async => [_mockCategory('1')]);

    // Act
    await syncManager.forceSyncCategories();

    // Assert
    verify(() => mockCache.invalidate(
          entityType: 'category_list',
          entityId: 'all',
        )).called(1);
    verify(() => mockApi.getAllCategories()).called(1);
  });
});
```

#### 4. Sync Window Management

```dart
group('Sync Window Management', () {
  test('should use incremental sync if last full sync < 7 days ago', () async {
    // Arrange
    final lastFullSync = DateTime.now().subtract(Duration(days: 5));

    when(() => mockDb.getLastFullSyncTime())
        .thenAnswer((_) async => lastFullSync);

    when(() => mockDb.getLastIncrementalSyncTime())
        .thenAnswer((_) async => DateTime.now().subtract(Duration(hours: 2)));

    // Act
    final canUseIncremental = await syncManager.canUseIncrementalSync();

    // Assert
    expect(canUseIncremental, true);
  });

  test('should fall back to full sync if last full sync > 7 days ago', () async {
    // Arrange
    final lastFullSync = DateTime.now().subtract(Duration(days: 8));

    when(() => mockDb.getLastFullSyncTime())
        .thenAnswer((_) async => lastFullSync);

    // Act
    final canUseIncremental = await syncManager.canUseIncrementalSync();

    // Assert
    expect(canUseIncremental, false);
  });

  test('should require full sync for first sync', () async {
    // Arrange: No previous sync
    when(() => mockDb.getLastFullSyncTime())
        .thenAnswer((_) async => null);

    // Act
    final canUseIncremental = await syncManager.canUseIncrementalSync();

    // Assert
    expect(canUseIncremental, false);
  });

  test('should respect user setting for incremental sync', () async {
    // Arrange: User disabled incremental sync
    when(() => mockSettings.enableIncrementalSync)
        .thenReturn(false);

    when(() => mockDb.getLastFullSyncTime())
        .thenAnswer((_) async => DateTime.now().subtract(Duration(days: 1)));

    // Act
    final canUseIncremental = await syncManager.canUseIncrementalSync();

    // Assert
    expect(canUseIncremental, false);
  });
});
```

## Integration Tests

### Test Structure

**Location:** `test/services/sync/incremental_sync_integration_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:waterfly_iii/data/local/database/app_database.dart';
import 'package:waterfly_iii/services/sync/sync_manager.dart';

void main() {
  group('Incremental Sync Integration', () {
    late AppDatabase database;
    late SyncManager syncManager;

    setUp() async {
      // Create in-memory database
      database = AppDatabase(NativeDatabase.memory());

      // Create sync manager with real database
      syncManager = SyncManager(
        database: database,
        // ... other dependencies
      );
    });

    tearDown() async {
      await database.close();
    });

    // Tests go here
  });
}
```

### Critical Integration Tests

```dart
test('end-to-end incremental sync flow', () async {
  // 1. Perform initial full sync
  await syncManager.performFullSync();

  final initialTransactions = await database.select(database.transactions).get();
  expect(initialTransactions.length, greaterThan(0));

  // 2. Simulate server changes
  // (Mock API to return updated transactions)

  // 3. Perform incremental sync
  final result = await syncManager.performIncrementalSync();

  // 4. Verify only changed transactions were updated
  expect(result.isIncremental, true);
  expect(result.itemsSkipped, greaterThan(0));
  expect(result.itemsUpdated, lessThan(result.itemsFetched));

  // 5. Verify database consistency
  final finalTransactions = await database.select(database.transactions).get();
  expect(finalTransactions.length, initialTransactions.length);
});

test('incremental sync with pagination', () async {
  // Test pagination behavior with 500+ transactions
  // Verify all pages are fetched correctly
});

test('incremental sync performance vs full sync', () async {
  // Measure time and bandwidth for both sync types
  final fullSyncTime = await _measureSyncTime(() => syncManager.performFullSync());
  final incrementalSyncTime = await _measureSyncTime(() => syncManager.performIncrementalSync());

  expect(incrementalSyncTime, lessThan(fullSyncTime * 0.4)); // 60% faster
});
```

## Widget Tests

### Sync Settings Page

**Location:** `test/pages/settings/sync_settings_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:waterfly_iii/pages/settings/sync_settings.dart';

void main() {
  group('SyncSettingsPage', () {
    testWidgets('should display incremental sync toggle', (tester) async {
      await tester.pumpWidget(_createTestApp(SyncSettingsPage()));

      expect(find.text('Incremental Sync'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('should display sync statistics', (tester) async {
      // Test statistics display
    });

    testWidgets('should trigger force full sync on button press', (tester) async {
      await tester.pumpWidget(_createTestApp(SyncSettingsPage()));

      final button = find.text('Force Full Sync');
      expect(button, findsOneWidget);

      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appears
      expect(find.text('Are you sure?'), findsOneWidget);
    });

    testWidgets('should display per-entity force sync buttons', (tester) async {
      await tester.pumpWidget(_createTestApp(SyncSettingsPage()));

      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Bills'), findsOneWidget);
      expect(find.text('Piggy Banks'), findsOneWidget);
    });
  });
}
```

## Performance Tests

### Bandwidth Measurement

```dart
test('incremental sync reduces bandwidth by 70%', () async {
  // Measure bandwidth for full sync
  int fullSyncBytes = 0;
  mockApi.interceptor = (request) {
    fullSyncBytes += request.body?.length ?? 0;
  };

  await syncManager.performFullSync();

  // Measure bandwidth for incremental sync
  int incrementalSyncBytes = 0;
  mockApi.interceptor = (request) {
    incrementalSyncBytes += request.body?.length ?? 0;
  };

  await syncManager.performIncrementalSync();

  // Verify 70% reduction
  expect(incrementalSyncBytes, lessThan(fullSyncBytes * 0.3));
});
```

### Speed Measurement

```dart
test('incremental sync is 60% faster than full sync', () async {
  final fullSyncTime = await _measureSyncTime(() => syncManager.performFullSync());
  final incrementalSyncTime = await _measureSyncTime(() => syncManager.performIncrementalSync());

  expect(incrementalSyncTime, lessThan(fullSyncTime * 0.4));
});

Duration _measureSyncTime(Future<void> Function() syncFn) async {
  final stopwatch = Stopwatch()..start();
  await syncFn();
  stopwatch.stop();
  return stopwatch.elapsed;
}
```

### Database Write Reduction

```dart
test('incremental sync reduces database writes by 80%', () async {
  int fullSyncWrites = 0;
  database.interceptor = (operation) {
    if (operation.isInsert || operation.isUpdate) {
      fullSyncWrites++;
    }
  };

  await syncManager.performFullSync();

  int incrementalSyncWrites = 0;
  database.interceptor = (operation) {
    if (operation.isInsert || operation.isUpdate) {
      incrementalSyncWrites++;
    }
  };

  await syncManager.performIncrementalSync();

  expect(incrementalSyncWrites, lessThan(fullSyncWrites * 0.2));
});
```

## Edge Case Testing

### Clock Skew

```dart
test('handles clock skew between client and server', () async {
  // Local time: 2024-12-16 14:00:00
  // Server time: 2024-12-16 13:55:00 (5 minutes behind)

  final localTime = DateTime(2024, 12, 16, 14, 0);
  final serverTime = DateTime(2024, 12, 16, 13, 55);

  when(() => mockDb.getTransaction('123'))
      .thenAnswer((_) async => TransactionEntity(
        id: '123',
        serverUpdatedAt: localTime,
      ));

  final hasChanged = await syncManager.hasEntityChanged('123', serverTime, 'transaction');

  // Should not mark as changed (within 5-minute tolerance)
  expect(hasChanged, false);
});
```

### Missed Updates

```dart
test('catches missed updates with 7-day full sync fallback', () async {
  // Simulate scenario where transaction was updated outside sync window

  // Last full sync: 10 days ago
  final lastFullSync = DateTime.now().subtract(Duration(days: 10));
  when(() => mockDb.getLastFullSyncTime())
      .thenAnswer((_) async => lastFullSync);

  // Attempt incremental sync
  final result = await syncManager.synchronize(fullSync: false);

  // Should fall back to full sync
  expect(result.isIncremental, false);
  verify(() => syncManager.performFullSync()).called(1);
});
```

### Network Errors

```dart
test('handles network errors during pagination', () async {
  // Simulate network error on page 3
  when(() => mockApi.getTransactionsPaginated(page: any(named: 'page')))
      .thenAnswer((invocation) async {
    final page = invocation.namedArguments[#page] as int;
    if (page == 3) {
      throw NetworkException('Connection timeout');
    }
    return _mockPaginatedResult(page);
  });

  // Should retry with exponential backoff
  await expectLater(
    syncManager.syncTransactionsIncremental(DateTime.now().subtract(Duration(days: 30))),
    completes,
  );
});
```

## Manual Testing Checklist

### Pre-Release Testing

- [ ] Fresh install incremental sync
- [ ] Upgrade from v5 to v6 (migration test)
- [ ] Full sync → Incremental sync transition
- [ ] Incremental sync → Full sync fallback
- [ ] Force sync each entity type
- [ ] Offline → Online sync
- [ ] Background sync with WorkManager
- [ ] Sync with large datasets (10k+ transactions)
- [ ] Sync with slow network
- [ ] Sync with intermittent network
- [ ] Battery usage during sync
- [ ] Memory usage during sync

### UI Testing

- [ ] Sync settings page displays correctly
- [ ] Statistics update in real-time
- [ ] Force sync buttons work
- [ ] Progress indicator shows incremental mode
- [ ] Bandwidth saved displays correctly
- [ ] Cache age indicators accurate

### Cross-Platform Testing

- [ ] Android sync behavior
- [ ] iOS sync behavior
- [ ] Background sync on Android
- [ ] App lifecycle handling (backgrounding during sync)

## Test Data Generation

### Mock Transaction Generator

```dart
Map<String, dynamic> mockTransaction(
  String id, {
  DateTime? updatedAt,
  double amount = 100.0,
  String description = 'Test Transaction',
}) {
  return {
    'id': id,
    'attributes': {
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': (updatedAt ?? DateTime.now()).toIso8601String(),
      'description': description,
      'amount': amount.toString(),
      'date': DateTime.now().toIso8601String(),
      'type': 'withdrawal',
    },
  };
}
```

### Large Dataset Generation

```dart
List<Map<String, dynamic>> generateLargeDataset(int count) {
  return List.generate(
    count,
    (i) => mockTransaction(
      '$i',
      updatedAt: DateTime.now().subtract(Duration(days: count - i)),
      amount: (i * 10).toDouble(),
      description: 'Transaction $i',
    ),
  );
}

// Usage:
final transactions = generateLargeDataset(10000); // 10k transactions
```

## Continuous Integration

### Test Commands

```bash
# Run all tests
flutter test

# Run unit tests only
flutter test test/services/

# Run integration tests
flutter test integration_test/

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# Run performance tests
flutter test test/performance/
```

### CI Pipeline

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test --coverage
      - run: flutter test integration_test/
```

## Debugging Tests

### Verbose Logging

```dart
setUpAll(() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
});
```

### Test-Specific Logging

```dart
test('sync transactions incremental', () async {
  final log = Logger('Test');
  log.info('Starting test: sync transactions incremental');

  // Test code with detailed logging
  await syncManager.syncTransactionsIncremental(since);

  log.info('Test completed');
});
```

## References

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mocktail Package](https://pub.dev/packages/mocktail)
- [Integration Testing in Flutter](https://docs.flutter.dev/testing/integration-tests)
- [Test Coverage Best Practices](https://dart.dev/guides/testing)
