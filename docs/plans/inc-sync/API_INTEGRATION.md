# API Integration Guide for Incremental Sync

This document provides comprehensive details on integrating with the Firefly III API for incremental synchronization.

## Table of Contents

- [Firefly III API Capabilities](#firefly-iii-api-capabilities)
- [API Endpoints for Incremental Sync](#api-endpoints-for-incremental-sync)
- [Pagination Implementation](#pagination-implementation)
- [Date Filtering Strategies](#date-filtering-strategies)
- [Timestamp Handling](#timestamp-handling)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)
- [Performance Optimization](#performance-optimization)

## Firefly III API Capabilities

### Supported Features

**✅ Available:**
- Date range filtering via `start` and `end` parameters (YYYY-MM-DD format)
- Pagination with comprehensive metadata (`page`, `limit`)
- Timestamp fields in responses (`created_at`, `updated_at`)
- Type filtering (transaction types, account types)

**❌ Not Available:**
- Timestamp-based filtering (`updated_after`, `modified_since`)
- Delta/changes endpoints (`/api/v1/changes`)
- ETag support on list endpoints (only on single-entity GET)
- Cursor-based pagination (offset-based only)
- Field selection/sparse fieldsets

### API Limitations

| Entity Type | Date Filtering | Notes |
|-------------|----------------|-------|
| Transactions | ✅ Yes | `start`/`end` parameters filter by transaction date |
| Accounts | ✅ Yes | `start`/`end` parameters for balance calculations |
| Budgets | ✅ Yes | `start`/`end` parameters available |
| Categories | ❌ No | Must fetch all, filter locally |
| Bills | ❌ No | Must fetch all, filter locally |
| Piggy Banks | ❌ No | Must fetch all, filter locally |

## API Endpoints for Incremental Sync

### Transactions

**Endpoint:** `GET /api/v1/transactions`

**Parameters:**
```
page: int           // Page number (1-indexed)
limit: int          // Items per page (default: 50, max: usually 100)
start: string       // Start date in YYYY-MM-DD format
end: string         // End date in YYYY-MM-DD format
type: string        // Filter by type: withdrawal, deposit, transfer
```

**Example Request:**
```http
GET /api/v1/transactions?page=1&limit=50&start=2024-12-01&end=2024-12-16
Authorization: Bearer {token}
Accept: application/json
```

**Example Response:**
```json
{
  "data": [
    {
      "type": "transactions",
      "id": "123",
      "attributes": {
        "created_at": "2024-12-10T14:30:00+00:00",
        "updated_at": "2024-12-15T09:00:00+00:00",
        "user": "1",
        "group_title": null,
        "transactions": [
          {
            "description": "Grocery shopping",
            "date": "2024-12-10T00:00:00+00:00",
            "amount": "-45.67",
            "currency_code": "USD",
            "type": "withdrawal",
            "source_name": "Checking Account",
            "destination_name": "Grocery Store"
          }
        ]
      }
    }
  ],
  "meta": {
    "pagination": {
      "total": 1523,
      "count": 50,
      "per_page": 50,
      "current_page": 1,
      "total_pages": 31
    }
  },
  "links": {
    "self": "https://firefly.example.com/api/v1/transactions?page=1",
    "first": "https://firefly.example.com/api/v1/transactions?page=1",
    "next": "https://firefly.example.com/api/v1/transactions?page=2",
    "last": "https://firefly.example.com/api/v1/transactions?page=31"
  }
}
```

### Accounts

**Endpoint:** `GET /api/v1/accounts`

**Parameters:**
```
page: int           // Page number
limit: int          // Items per page
start: string       // Start date for balance calculation
end: string         // End date for balance calculation
date: string        // Specific date for balance snapshot
type: string        // Filter by type: asset, expense, revenue, liability
```

**Example Request:**
```http
GET /api/v1/accounts?page=1&limit=50&type=asset&start=2024-12-01
Authorization: Bearer {token}
Accept: application/json
```

**Example Response:**
```json
{
  "data": [
    {
      "type": "accounts",
      "id": "456",
      "attributes": {
        "created_at": "2024-01-15T10:00:00+00:00",
        "updated_at": "2024-12-10T15:30:00+00:00",
        "active": true,
        "name": "Checking Account",
        "type": "asset",
        "account_role": "defaultAsset",
        "currency_code": "USD",
        "current_balance": "1234.56",
        "iban": "US1234567890"
      }
    }
  ],
  "meta": {
    "pagination": {
      "total": 25,
      "count": 25,
      "per_page": 50,
      "current_page": 1,
      "total_pages": 1
    }
  }
}
```

### Budgets

**Endpoint:** `GET /api/v1/budgets`

**Parameters:**
```
page: int           // Page number
start: string       // Start date for budget period
end: string         // End date for budget period
```

**Implementation Note:** Budget limits are queried separately via `/api/v1/budgets/{id}/limits`.

### Categories, Bills, Piggy Banks

**Endpoints:**
- `GET /api/v1/categories`
- `GET /api/v1/bills`
- `GET /api/v1/piggy-banks`

**No Date Filtering Available** - These endpoints do not support `start`/`end` parameters. Must fetch all entities and filter locally by comparing timestamps.

## Pagination Implementation

### PaginatedResult Class

```dart
/// Wraps paginated API responses with metadata.
class PaginatedResult<T> {
  final List<T> data;
  final int total;              // Total items across all pages
  final int currentPage;        // Current page number (1-indexed)
  final int totalPages;         // Total number of pages
  final int perPage;            // Items per page

  bool get hasMore => currentPage < totalPages;
  double get progressPercent => (currentPage / totalPages) * 100;

  PaginatedResult({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
  });
}
```

### Fetching Multiple Pages

**Strategy 1: Sequential Fetching** (Memory Efficient)

```dart
Future<List<Map<String, dynamic>>> fetchAllTransactions({
  DateTime? start,
  DateTime? end,
}) async {
  final allData = <Map<String, dynamic>>[];
  int page = 1;

  while (true) {
    final result = await apiClient.getTransactionsPaginated(
      page: page,
      start: start,
      end: end,
    );

    allData.addAll(result.data);

    _logger.fine('Fetched page $page/${result.totalPages}: ${result.data.length} items');

    if (!result.hasMore) break;
    page++;
  }

  return allData;
}
```

**Strategy 2: Stream-Based Iteration** (Recommended)

```dart
Stream<Map<String, dynamic>> iterateTransactions({
  DateTime? start,
  DateTime? end,
}) async* {
  int page = 1;

  while (true) {
    final result = await apiClient.getTransactionsPaginated(
      page: page,
      start: start,
      end: end,
    );

    for (final item in result.data) {
      yield item;
    }

    if (!result.hasMore) break;
    page++;
  }
}

// Usage:
await for (final transaction in iterateTransactions(start: since)) {
  // Process transaction one at a time (memory efficient)
  await processTransaction(transaction);
}
```

### Handling Pagination Metadata

**Extract metadata from API response:**

```dart
Future<PaginatedResult<Map<String, dynamic>>> getTransactionsPaginated({
  required int page,
  DateTime? start,
  DateTime? end,
}) async {
  final response = await _apiClient.v1TransactionsGet(
    page: page,
    start: start?.toIso8601String().split('T')[0],
    end: end?.toIso8601String().split('T')[0],
  );

  if (!response.isSuccessful || response.body == null) {
    throw ApiException('Failed to fetch transactions: ${response.error}');
  }

  final meta = response.body!.meta.pagination;

  // Handle null metadata gracefully
  return PaginatedResult(
    data: response.body!.data.map((t) => {
      'id': t.id,
      'attributes': t.attributes.toJson(),
    }).toList(),
    total: meta?.total ?? response.body!.data.length,
    currentPage: meta?.currentPage ?? page,
    totalPages: meta?.totalPages ?? 1,
    perPage: meta?.perPage ?? 50,
  );
}
```

## Date Filtering Strategies

### Strategy 1: Date-Range Filtering (Tier 1 Entities)

**Applies to:** Transactions, Accounts, Budgets

**Implementation:**

```dart
Future<void> syncTransactionsIncremental(DateTime since) async {
  // Calculate date range
  final start = since;
  final end = DateTime.now();

  // Fetch entities within date range
  await for (final transaction in iterateTransactions(start: start, end: end)) {
    final serverUpdatedAt = DateTime.parse(
      transaction['attributes']['updated_at'] as String,
    );

    // Compare timestamps to detect actual changes
    if (await _hasEntityChanged(transaction['id'], serverUpdatedAt)) {
      await _updateLocalEntity(transaction);
    }
  }
}
```

**Date Format:** Firefly III expects `YYYY-MM-DD` format.

```dart
String formatDateForApi(DateTime date) {
  return date.toIso8601String().split('T')[0];
}

// Example: DateTime(2024, 12, 16) → "2024-12-16"
```

### Strategy 2: Fetch All + Local Filtering (Tier 2 Entities)

**Applies to:** Categories, Bills, Piggy Banks

**Implementation:**

```dart
Future<void> syncCategoriesIncremental() async {
  // Check cache first (24-hour TTL)
  if (await _isCacheFresh('category_list', Duration(hours: 24))) {
    _logger.info('Categories cache fresh, skipping sync');
    return;
  }

  // Fetch all categories (no date filtering available)
  final categories = await _apiClient.getAllCategories();

  // Filter by comparing timestamps locally
  for (final category in categories) {
    final serverUpdatedAt = DateTime.parse(
      category['attributes']['updated_at'] as String,
    );

    if (await _hasEntityChanged(category['id'], serverUpdatedAt)) {
      await _updateLocalEntity(category);
    }
  }

  // Update cache timestamp
  await _updateCacheTimestamp('category_list');
}
```

## Timestamp Handling

### Parsing Timestamps

**Firefly III timestamp format:** ISO 8601 with timezone

```dart
DateTime parseFireflyTimestamp(String timestamp) {
  // Example: "2024-12-16T14:30:00+00:00"
  return DateTime.parse(timestamp);
}
```

**Handle nullable timestamps:**

```dart
DateTime? parseNullableTimestamp(String? timestamp) {
  if (timestamp == null || timestamp.isEmpty) return null;
  try {
    return DateTime.parse(timestamp);
  } catch (e) {
    _logger.warning('Failed to parse timestamp: $timestamp', e);
    return null;
  }
}
```

### Comparing Timestamps

**Server wins strategy with tolerance:**

```dart
bool isServerNewer(DateTime local, DateTime server) {
  // Add 5-minute tolerance for clock skew
  const tolerance = Duration(minutes: 5);

  return server.isAfter(local.add(tolerance));
}
```

**Detect significant clock skew:**

```dart
void detectClockSkew(DateTime local, DateTime server) {
  final diff = server.difference(local).abs();

  if (diff > const Duration(hours: 1)) {
    _logger.warning(
      'Significant clock skew detected: ${diff.inMinutes} minutes '
      '(local: $local, server: $server)',
    );
  }
}
```

## Error Handling

### Common API Errors

| HTTP Status | Error Type | Handling Strategy |
|-------------|------------|-------------------|
| 401 | Unauthorized | Re-authenticate, refresh token |
| 403 | Forbidden | Check permissions, log error |
| 404 | Not Found | Entity deleted, remove locally |
| 422 | Validation Error | Log details, skip entity |
| 429 | Rate Limited | Exponential backoff, retry |
| 500 | Server Error | Retry with backoff |
| 503 | Service Unavailable | Retry with backoff |

### Retry Logic

**Use `retry` package for transient errors:**

```dart
import 'package:retry/retry.dart';

Future<PaginatedResult<Map<String, dynamic>>> fetchWithRetry({
  required int page,
  DateTime? start,
}) async {
  const maxAttempts = 3;
  const retryDelayBase = Duration(seconds: 2);

  return await retry(
    () => apiClient.getTransactionsPaginated(page: page, start: start),
    retryIf: (e) => e is NetworkException || e is TimeoutException,
    maxAttempts: maxAttempts,
    delayFactor: retryDelayBase,
    onRetry: (e) {
      _logger.warning('Retrying API request after error: $e');
    },
  );
}
```

### Pagination Error Recovery

**Continue from last successful page:**

```dart
Future<List<Map<String, dynamic>>> fetchAllPagesWithRecovery({
  DateTime? start,
}) async {
  final allData = <Map<String, dynamic>>[];
  int page = 1;
  int consecutiveFailures = 0;
  const maxFailures = 3;

  while (true) {
    try {
      final result = await fetchWithRetry(page: page, start: start);
      allData.addAll(result.data);
      consecutiveFailures = 0; // Reset on success

      if (!result.hasMore) break;
      page++;
    } catch (e) {
      consecutiveFailures++;
      _logger.severe('Failed to fetch page $page (attempt $consecutiveFailures)', e);

      if (consecutiveFailures >= maxFailures) {
        // Return partial data if we got some
        if (allData.isNotEmpty) {
          _logger.warning('Returning partial data: ${allData.length} items');
          break;
        }
        rethrow;
      }

      // Wait before retrying
      await Future.delayed(Duration(seconds: consecutiveFailures * 2));
    }
  }

  return allData;
}
```

## Rate Limiting

### Firefly III Rate Limits

**Typical limits:**
- API calls: 60 per minute per user (varies by server configuration)
- Concurrent connections: Usually limited to 10

### Detection and Handling

```dart
class ApiRateLimiter {
  static const maxCallsPerMinute = 60;
  static const callWindow = Duration(minutes: 1);

  final List<DateTime> _recentCalls = [];

  Future<void> waitIfNeeded() async {
    _cleanOldCalls();

    if (_recentCalls.length >= maxCallsPerMinute) {
      // Calculate wait time
      final oldestCall = _recentCalls.first;
      final waitUntil = oldestCall.add(callWindow);
      final waitDuration = waitUntil.difference(DateTime.now());

      if (waitDuration.isNegative) {
        _logger.warning('Rate limit reached, waiting ${waitDuration.inSeconds}s');
        await Future.delayed(waitDuration);
        _cleanOldCalls();
      }
    }

    _recentCalls.add(DateTime.now());
  }

  void _cleanOldCalls() {
    final cutoff = DateTime.now().subtract(callWindow);
    _recentCalls.removeWhere((call) => call.isBefore(cutoff));
  }
}

// Usage:
final rateLimiter = ApiRateLimiter();

await rateLimiter.waitIfNeeded();
final result = await apiClient.getTransactionsPaginated(page: page);
```

### Handle 429 Responses

```dart
Future<PaginatedResult<Map<String, dynamic>>> fetchWithRateLimitHandling({
  required int page,
}) async {
  try {
    return await apiClient.getTransactionsPaginated(page: page);
  } on ApiException catch (e) {
    if (e.statusCode == 429) {
      // Extract Retry-After header if available
      final retryAfter = e.headers?['retry-after'];
      final waitSeconds = retryAfter != null ? int.parse(retryAfter) : 60;

      _logger.warning('Rate limited, waiting $waitSeconds seconds');
      await Future.delayed(Duration(seconds: waitSeconds));

      // Retry once
      return await apiClient.getTransactionsPaginated(page: page);
    }
    rethrow;
  }
}
```

## Performance Optimization

### Parallel Requests

**Fetch multiple pages concurrently** (with caution for rate limits):

```dart
Future<List<Map<String, dynamic>>> fetchPagesConcurrently({
  required int startPage,
  required int endPage,
  DateTime? start,
}) async {
  const maxConcurrency = 5; // Don't exceed rate limits

  final futures = <Future<PaginatedResult<Map<String, dynamic>>>>[];

  for (int page = startPage; page <= endPage; page++) {
    futures.add(apiClient.getTransactionsPaginated(page: page, start: start));

    // Batch requests to respect concurrency limit
    if (futures.length >= maxConcurrency || page == endPage) {
      final results = await Future.wait(futures);
      futures.clear();

      for (final result in results) {
        allData.addAll(result.data);
      }
    }
  }

  return allData;
}
```

**Warning:** Only use parallel requests if you know the total number of pages upfront and your Firefly III server can handle concurrent requests.

### Request Batching

**Batch size optimization:**

```dart
// Optimal batch size depends on:
// - Network latency
// - Server response time
// - Rate limits

const optimalLimit = 50; // 50 items per page is usually good balance

Future<PaginatedResult<Map<String, dynamic>>> fetchPage(int page) {
  return apiClient.getTransactionsPaginated(
    page: page,
    limit: optimalLimit, // Explicitly set limit
  );
}
```

### Bandwidth Optimization

**Minimize data transfer:**

```dart
// Request only necessary fields (if API supports field selection)
// Note: Firefly III doesn't currently support sparse fieldsets,
// but this is how you'd implement it if available:

Future<PaginatedResult<Map<String, dynamic>>> fetchTransactionsMinimal({
  required int page,
}) async {
  // Hypothetical implementation:
  return await apiClient.getTransactionsPaginated(
    page: page,
    fields: ['id', 'updated_at', 'description', 'amount'], // Not supported yet
  );
}
```

**Compress responses** (if server supports):

```http
GET /api/v1/transactions?page=1
Authorization: Bearer {token}
Accept: application/json
Accept-Encoding: gzip, deflate  // Request compressed response
```

## Example: Complete Integration

**Putting it all together:**

```dart
class IncrementalSyncApiClient {
  final FireflyApiClient _apiClient;
  final ApiRateLimiter _rateLimiter;
  final Logger _logger;

  IncrementalSyncApiClient({
    required FireflyApiClient apiClient,
  })  : _apiClient = apiClient,
        _rateLimiter = ApiRateLimiter(),
        _logger = Logger('IncrementalSyncApiClient');

  /// Fetch all transactions since [since] date with full error handling.
  Stream<Map<String, dynamic>> fetchTransactionsSince(DateTime since) async* {
    _logger.info('Fetching transactions since $since');

    int page = 1;
    int totalFetched = 0;

    while (true) {
      try {
        // Rate limiting
        await _rateLimiter.waitIfNeeded();

        // Fetch page with retry logic
        final result = await retry(
          () => _apiClient.getTransactionsPaginated(
            page: page,
            start: since,
          ),
          retryIf: (e) => e is NetworkException,
          maxAttempts: 3,
        );

        // Yield transactions one by one
        for (final transaction in result.data) {
          yield transaction;
          totalFetched++;
        }

        _logger.fine(
          'Fetched page $page/${result.totalPages}: '
          '${result.data.length} items (total: $totalFetched)',
        );

        // Check if more pages available
        if (!result.hasMore) {
          _logger.info('Completed fetch: $totalFetched transactions');
          break;
        }

        page++;
      } catch (e, stackTrace) {
        _logger.severe('Error fetching page $page', e, stackTrace);

        // Return partial results if we got some
        if (totalFetched > 0) {
          _logger.warning('Returning partial results: $totalFetched transactions');
          break;
        }

        rethrow;
      }
    }
  }
}
```

## Testing API Integration

### Mock API Responses

```dart
class MockFireflyApiClient extends Mock implements FireflyApiClient {}

test('should handle pagination correctly', () async {
  final mockClient = MockFireflyApiClient();

  // Mock page 1 response
  when(() => mockClient.v1TransactionsGet(page: 1))
      .thenAnswer((_) async => Response.success(
            TransactionArray(
              data: [mockTransaction('1'), mockTransaction('2')],
              meta: Meta(
                pagination: Pagination(
                  total: 150,
                  currentPage: 1,
                  totalPages: 3,
                  perPage: 50,
                ),
              ),
            ),
          ));

  final adapter = FireflyApiAdapter(apiClient: mockClient);
  final result = await adapter.getTransactionsPaginated(page: 1);

  expect(result.hasMore, true);
  expect(result.totalPages, 3);
});
```

### Integration Tests

Test against real Firefly III API (test server):

```dart
integration_test('fetch transactions from real API', () async {
  final apiClient = FireflyApiClient(
    baseUrl: 'https://test.firefly.example.com',
    token: testToken,
  );

  final adapter = FireflyApiAdapter(apiClient: apiClient);

  final result = await adapter.getTransactionsPaginated(
    page: 1,
    start: DateTime(2024, 12, 1),
  );

  expect(result.data, isNotEmpty);
  expect(result.total, greaterThan(0));
});
```

## References

- [Firefly III API Documentation](https://api-docs.firefly-iii.org/)
- [Chopper HTTP Client](https://pub.dev/packages/chopper)
- [Retry Package](https://pub.dev/packages/retry)
- [Drift Database](https://drift.simonbinder.eu/)
