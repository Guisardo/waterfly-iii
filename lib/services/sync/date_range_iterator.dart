import 'dart:async';

import 'package:logging/logging.dart';
import 'package:retry/retry.dart';
import 'package:waterflyiii/models/paginated_result.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';

/// Configuration for retry behavior during iteration.
///
/// Controls how failed API requests are retried with exponential backoff.
/// Uses the `retry` package for exponential backoff implementation.
///
/// The delay after each attempt is calculated as:
/// `pow(2, attempt) * initialDelay`, with optional randomization.
class RetryConfig {
  /// Maximum number of retry attempts.
  final int maxAttempts;

  /// Initial delay before first retry.
  ///
  /// This is the base delay factor used for exponential backoff.
  /// The actual delay is `pow(2, attempt) * initialDelay`.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Whether to add jitter to retry delays to prevent thundering herd.
  ///
  /// When true, adds ±25% randomization to delays.
  final bool randomizationFactor;

  /// Creates retry configuration.
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 200),
    this.maxDelay = const Duration(seconds: 30),
    this.randomizationFactor = true,
  });

  /// Default configuration for API operations.
  static const RetryConfig defaultConfig = RetryConfig();

  /// Aggressive retry configuration for critical operations.
  static const RetryConfig aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 60),
  );

  /// Light retry configuration for non-critical operations.
  static const RetryConfig light = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 200),
    maxDelay: Duration(seconds: 5),
  );
}

/// Configuration for batch processing during iteration.
///
/// Controls how items are processed in batches for improved performance.
class BatchConfig {
  /// Number of items to process in each batch.
  final int batchSize;

  /// Delay between batches to avoid overwhelming the server.
  final Duration batchDelay;

  /// Whether to process items in parallel within a batch.
  final bool parallelProcessing;

  /// Maximum concurrent operations when parallel processing is enabled.
  final int maxConcurrency;

  /// Creates batch configuration.
  const BatchConfig({
    this.batchSize = 50,
    this.batchDelay = Duration.zero,
    this.parallelProcessing = false,
    this.maxConcurrency = 5,
  });

  /// Default batch configuration.
  static const BatchConfig defaultConfig = BatchConfig();

  /// Configuration optimized for rate-limited APIs.
  static const BatchConfig rateLimited = BatchConfig(
    batchSize: 25,
    batchDelay: Duration(milliseconds: 200),
    parallelProcessing: false,
  );

  /// Configuration optimized for high-throughput scenarios.
  static const BatchConfig highThroughput = BatchConfig(
    batchSize: 100,
    batchDelay: Duration.zero,
    parallelProcessing: true,
    maxConcurrency: 10,
  );
}

/// Efficiently iterates through paginated API results for a date range.
///
/// This class handles pagination automatically, fetching all pages
/// for the specified entity type and date range. It yields entities
/// one by one as a stream for memory-efficient processing.
///
/// This is a core component of the incremental sync system, enabling
/// efficient fetching of large datasets without loading everything
/// into memory at once.
///
/// ## Supported Entity Types
///
/// - `transaction`: Uses date-range filtering via start/end parameters
/// - `account`: Uses date filtering for balance calculations
/// - `budget`: Uses date-range filtering for budget periods
/// - `category`: No date filtering (fetches all, filter locally)
/// - `bill`: No date filtering (fetches all, filter locally)
/// - `piggy_bank`: No date filtering (fetches all, filter locally)
///
/// ## Example Usage
///
/// ```dart
/// final iterator = DateRangeIterator(
///   apiClient: adapter,
///   entityType: 'transaction',
///   start: DateTime(2024, 12, 1),
///   end: DateTime(2024, 12, 31),
/// );
///
/// // Stream-based iteration (memory efficient)
/// await for (final transaction in iterator.iterate()) {
///   print('Processing transaction: ${transaction['id']}');
/// }
///
/// // Or fetch all at once (loads into memory)
/// final allTransactions = await iterator.fetchAll();
/// ```
///
/// ## Advanced Features
///
/// ### Retry Logic with Exponential Backoff
///
/// ```dart
/// final iterator = DateRangeIterator(
///   apiClient: adapter,
///   entityType: 'transaction',
///   start: DateTime.now().subtract(Duration(days: 30)),
///   retryConfig: RetryConfig(
///     maxAttempts: 5,
///     initialDelay: Duration(seconds: 1),
///   ),
/// );
/// ```
///
/// ### Batch Processing
///
/// ```dart
/// final iterator = DateRangeIterator(
///   apiClient: adapter,
///   entityType: 'transaction',
///   start: DateTime.now().subtract(Duration(days: 30)),
///   batchConfig: BatchConfig(
///     batchSize: 100,
///     batchDelay: Duration(milliseconds: 100),
///   ),
/// );
///
/// // Process items in batches
/// await for (final batch in iterator.iterateBatches(size: 50)) {
///   await processItemsBatch(batch);
/// }
/// ```
///
/// ## Error Handling
///
/// Errors during pagination are logged and retried according to [retryConfig].
/// If all retries fail, the error is propagated to the caller.
/// The caller can catch the error and decide whether to skip or abort.
///
/// ## Progress Tracking
///
/// Use [iterateWithProgress] to receive progress callbacks during iteration:
///
/// ```dart
/// await for (final item in iterator.iterateWithProgress(
///   onProgress: (fetched, total) => print('Fetched $fetched of $total'),
/// )) {
///   // Process item
/// }
/// ```
class DateRangeIterator {
  /// API client for making requests.
  final FireflyApiAdapter apiClient;

  /// Entity type to fetch.
  ///
  /// Valid values: 'transaction', 'account', 'budget', 'category', 'bill', 'piggy_bank'
  final String entityType;

  /// Start of date range for filtering.
  ///
  /// For transactions, accounts, budgets: filters by entity date.
  /// For categories, bills, piggy banks: ignored (API doesn't support date filtering).
  final DateTime start;

  /// End of date range for filtering.
  ///
  /// Optional. If not provided, defaults to current date.
  final DateTime? end;

  /// Items per page for API requests.
  final int pageSize;

  /// Field to sort by (e.g., 'updated_at', 'date', 'created_at').
  ///
  /// If provided, results will be sorted by this field.
  /// Used for incremental sync optimization (sort by updated_at desc).
  final String? sort;

  /// Sort order ('asc' or 'desc').
  ///
  /// Defaults to 'desc' for incremental sync (newest first).
  final String? order;

  /// Callback to determine if iteration should stop early.
  ///
  /// Called for each item. If returns `true`, iteration stops immediately.
  /// Used to stop when finding already-processed items during incremental sync.
  final Future<bool> Function(Map<String, dynamic> item)? stopWhenProcessed;

  /// Retry configuration for failed API requests.
  final RetryConfig retryConfig;

  /// Batch processing configuration.
  final BatchConfig batchConfig;

  /// Logger for this iterator.
  final Logger _logger = Logger('DateRangeIterator');

  /// Internal retry helper using the retry package.
  late final RetryOptions _retryOptions;

  /// Creates a new date range iterator.
  ///
  /// Parameters:
  /// - [apiClient]: The API adapter to use for requests
  /// - [entityType]: Type of entity to fetch ('transaction', 'account', etc.)
  /// - [start]: Start of date range
  /// - [end]: Optional end of date range (defaults to now)
  /// - [pageSize]: Number of items per page (default: 50)
  /// - [sort]: Optional field to sort by (e.g., 'updated_at', 'date', 'created_at')
  /// - [order]: Optional sort order ('asc' or 'desc', default: 'desc')
  /// - [stopWhenProcessed]: Optional callback to stop iteration early when finding already-processed items
  /// - [retryConfig]: Configuration for retry behavior (default: [RetryConfig.defaultConfig])
  /// - [batchConfig]: Configuration for batch processing (default: [BatchConfig.defaultConfig])
  DateRangeIterator({
    required this.apiClient,
    required this.entityType,
    required this.start,
    this.end,
    this.pageSize = 50,
    this.sort,
    this.order,
    this.stopWhenProcessed,
    this.retryConfig = RetryConfig.defaultConfig,
    this.batchConfig = BatchConfig.defaultConfig,
  }) {
    _retryOptions = RetryOptions(
      maxAttempts: retryConfig.maxAttempts,
      delayFactor: retryConfig.initialDelay,
      maxDelay: retryConfig.maxDelay,
      randomizationFactor: retryConfig.randomizationFactor ? 0.25 : 0.0,
    );
  }

  /// Iterate through all pages, yielding entities one by one.
  ///
  /// This stream handles pagination automatically and provides
  /// memory-efficient processing by not loading all entities into memory.
  ///
  /// Yields each entity as a `Map<String, dynamic>` containing:
  /// - `id`: Server ID of the entity
  /// - `type`: Entity type string
  /// - `attributes`: Map of entity attributes
  ///
  /// Example:
  /// ```dart
  /// await for (final entity in iterator.iterate()) {
  ///   final serverId = entity['id'] as String;
  ///   final attributes = entity['attributes'] as Map<String, dynamic>;
  ///   final updatedAt = attributes['updated_at'] as String;
  ///   // Process entity...
  /// }
  /// ```
  Stream<Map<String, dynamic>> iterate() async* {
    _logger.fine(
      'Starting iteration for $entityType (start: $start, end: $end, sort: $sort, order: $order)',
    );

    int page = 1;
    int totalFetched = 0;
    int consecutiveErrors = 0;
    bool terminatedEarly = false;

    while (true) {
      PaginatedResult<Map<String, dynamic>> result;

      try {
        // Use retry logic for resilient page fetching
        result = await _fetchPageWithRetry(page);
        consecutiveErrors = 0; // Reset error counter on success

        for (final Map<String, dynamic> item in result.data) {
          // Check if should stop early (for incremental sync optimization)
          if (stopWhenProcessed != null) {
            final bool shouldStop = await stopWhenProcessed!(item);
            if (shouldStop) {
              _logger.info(
                'Early termination: found already-processed item at position $totalFetched',
              );
              terminatedEarly = true;
              break;
            }
          }

          yield item;
          totalFetched++;
        }

        // Break if terminated early
        if (terminatedEarly) {
          break;
        }

        _logger.fine(
          'Fetched page $page: ${result.data.length} items '
          '(${result.currentPage}/${result.totalPages})',
        );

        if (!result.hasMore) {
          _logger.info(
            'Completed iteration for $entityType: $totalFetched total items fetched'
            '${terminatedEarly ? ' (terminated early)' : ''}',
          );
          break;
        }

        // Apply batch delay if configured
        if (batchConfig.batchDelay > Duration.zero) {
          await Future<void>.delayed(batchConfig.batchDelay);
        }

        page++;
      } catch (e, stackTrace) {
        consecutiveErrors++;
        _logger.severe(
          'Error fetching page $page for $entityType (attempt $consecutiveErrors after retries)',
          e,
          stackTrace,
        );
        rethrow;
      }
    }
  }

  /// Fetch a page with retry logic.
  ///
  /// Uses exponential backoff to retry failed API requests.
  Future<PaginatedResult<Map<String, dynamic>>> _fetchPageWithRetry(
    int page,
  ) {
    int attemptCount = 0;

    return _retryOptions.retry(
      () {
        attemptCount++;
        if (attemptCount > 1) {
          _logger.fine('Retry attempt $attemptCount for page $page');
        }
        return _fetchPage(page);
      },
      retryIf: (Exception e) => _isRetryableError(e),
      onRetry: (Exception e) {
        _logger.warning(
          'Retrying page $page fetch for $entityType after error: $e',
        );
      },
    );
  }

  /// Check if an error is retryable.
  ///
  /// Returns true for transient errors like network issues or rate limiting.
  bool _isRetryableError(Exception e) {
    final String errorMessage = e.toString().toLowerCase();

    // Retry on network-related errors
    if (errorMessage.contains('socket') ||
        errorMessage.contains('timeout') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('network')) {
      return true;
    }

    // Retry on rate limiting (429)
    if (errorMessage.contains('429') ||
        errorMessage.contains('rate limit') ||
        errorMessage.contains('too many requests')) {
      return true;
    }

    // Retry on server errors (5xx)
    if (errorMessage.contains('500') ||
        errorMessage.contains('502') ||
        errorMessage.contains('503') ||
        errorMessage.contains('504')) {
      return true;
    }

    // Don't retry on client errors (4xx except 429)
    if (errorMessage.contains('400') ||
        errorMessage.contains('401') ||
        errorMessage.contains('403') ||
        errorMessage.contains('404')) {
      return false;
    }

    // Default: retry on unknown errors
    return true;
  }

  /// Iterate with progress callbacks.
  ///
  /// Similar to [iterate], but calls [onProgress] after each page is fetched.
  ///
  /// Parameters:
  /// - [onProgress]: Callback with (itemsFetched, totalItems) parameters
  ///
  /// Example:
  /// ```dart
  /// await for (final item in iterator.iterateWithProgress(
  ///   onProgress: (fetched, total) {
  ///     final percent = total > 0 ? (fetched / total * 100).toStringAsFixed(1) : '0.0';
  ///     print('Progress: $percent% ($fetched/$total)');
  ///   },
  /// )) {
  ///   // Process item...
  /// }
  /// ```
  Stream<Map<String, dynamic>> iterateWithProgress({
    required void Function(int itemsFetched, int totalItems) onProgress,
  }) async* {
    _logger.fine('Starting iteration with progress for $entityType');

    int page = 1;
    int totalFetched = 0;
    int? totalItems;

    while (true) {
      PaginatedResult<Map<String, dynamic>> result;

      try {
        result = await _fetchPage(page);
        totalItems ??= result.total;

        for (final Map<String, dynamic> item in result.data) {
          yield item;
          totalFetched++;
        }

        // Report progress after each page
        onProgress(totalFetched, totalItems);

        if (!result.hasMore) {
          _logger.info(
            'Completed iteration for $entityType: $totalFetched total items',
          );
          break;
        }

        page++;
      } catch (e, stackTrace) {
        _logger.severe(
          'Error fetching page $page for $entityType',
          e,
          stackTrace,
        );
        rethrow;
      }
    }
  }

  /// Fetch all entities at once (loads into memory).
  ///
  /// Use [iterate] instead for memory-efficient processing of large datasets.
  /// This method is convenient for smaller datasets or when all data is needed
  /// in memory for processing.
  ///
  /// Returns a list of all entities matching the date range filter.
  ///
  /// Example:
  /// ```dart
  /// final categories = await DateRangeIterator(
  ///   apiClient: adapter,
  ///   entityType: 'category',
  ///   start: DateTime.now(),
  /// ).fetchAll();
  /// ```
  Future<List<Map<String, dynamic>>> fetchAll() async {
    final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
    await for (final Map<String, dynamic> item in iterate()) {
      results.add(item);
    }
    return results;
  }

  /// Fetch all entities with progress callbacks.
  ///
  /// Combines [fetchAll] with progress reporting.
  ///
  /// Parameters:
  /// - [onProgress]: Callback with (itemsFetched, totalItems) parameters
  Future<List<Map<String, dynamic>>> fetchAllWithProgress({
    required void Function(int itemsFetched, int totalItems) onProgress,
  }) async {
    final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];
    await for (final Map<String, dynamic> item in iterateWithProgress(
      onProgress: onProgress,
    )) {
      results.add(item);
    }
    return results;
  }

  /// Count total entities without fetching all data.
  ///
  /// Makes a single API request to get the total count.
  /// Useful for progress estimation or deciding pagination strategy.
  ///
  /// Returns the total number of entities matching the filter.
  Future<int> count() async {
    final PaginatedResult<Map<String, dynamic>> result =
        await _fetchPageWithRetry(1);
    return result.total;
  }

  /// Iterate through entities in batches.
  ///
  /// Instead of yielding one item at a time, this method yields lists
  /// of items in batches of the specified size. This is useful for:
  /// - Bulk database operations (batch inserts/updates)
  /// - Rate-limited processing
  /// - Memory management with controlled batch sizes
  ///
  /// Parameters:
  /// - [size]: Number of items per batch (default: [batchConfig.batchSize])
  ///
  /// Example:
  /// ```dart
  /// await for (final batch in iterator.iterateBatches(size: 100)) {
  ///   await database.batchInsert(batch);
  ///   print('Inserted ${batch.length} items');
  /// }
  /// ```
  Stream<List<Map<String, dynamic>>> iterateBatches({int? size}) async* {
    final int batchSize = size ?? batchConfig.batchSize;
    List<Map<String, dynamic>> currentBatch = <Map<String, dynamic>>[];

    _logger.fine(
      'Starting batch iteration for $entityType (batch size: $batchSize)',
    );

    await for (final Map<String, dynamic> item in iterate()) {
      currentBatch.add(item);

      if (currentBatch.length >= batchSize) {
        yield currentBatch;
        currentBatch = <Map<String, dynamic>>[];

        // Apply batch delay if configured
        if (batchConfig.batchDelay > Duration.zero) {
          await Future<void>.delayed(batchConfig.batchDelay);
        }
      }
    }

    // Yield remaining items if any
    if (currentBatch.isNotEmpty) {
      yield currentBatch;
    }
  }

  /// Iterate through entities in batches with progress tracking.
  ///
  /// Combines batch iteration with progress callbacks.
  ///
  /// Parameters:
  /// - [size]: Number of items per batch
  /// - [onBatchComplete]: Callback after each batch is yielded
  /// - [onProgress]: Callback with (itemsFetched, totalItems) after each batch
  ///
  /// Example:
  /// ```dart
  /// await for (final batch in iterator.iterateBatchesWithProgress(
  ///   size: 50,
  ///   onBatchComplete: (batchNum, totalBatches) {
  ///     print('Completed batch $batchNum of ~$totalBatches');
  ///   },
  ///   onProgress: (fetched, total) {
  ///     updateProgressBar(fetched / total);
  ///   },
  /// )) {
  ///   await processBatch(batch);
  /// }
  /// ```
  Stream<List<Map<String, dynamic>>> iterateBatchesWithProgress({
    int? size,
    void Function(int batchNumber, int estimatedTotalBatches)? onBatchComplete,
    void Function(int itemsFetched, int totalItems)? onProgress,
  }) async* {
    final int batchSize = size ?? batchConfig.batchSize;
    List<Map<String, dynamic>> currentBatch = <Map<String, dynamic>>[];
    int totalFetched = 0;
    int batchNumber = 0;
    int? totalItems;
    int? estimatedBatches;

    _logger.fine('Starting batch iteration with progress for $entityType');

    // Get total count for progress tracking
    try {
      totalItems = await count();
      estimatedBatches = (totalItems / batchSize).ceil();
      _logger.fine(
        'Total items: $totalItems, estimated batches: $estimatedBatches',
      );
    } catch (e) {
      _logger.warning('Could not get total count for progress tracking: $e');
    }

    await for (final Map<String, dynamic> item in iterate()) {
      currentBatch.add(item);
      totalFetched++;

      if (currentBatch.length >= batchSize) {
        batchNumber++;
        yield currentBatch;

        // Invoke callbacks
        onBatchComplete?.call(batchNumber, estimatedBatches ?? batchNumber);
        onProgress?.call(totalFetched, totalItems ?? totalFetched);

        currentBatch = <Map<String, dynamic>>[];

        if (batchConfig.batchDelay > Duration.zero) {
          await Future<void>.delayed(batchConfig.batchDelay);
        }
      }
    }

    // Yield remaining items
    if (currentBatch.isNotEmpty) {
      batchNumber++;
      yield currentBatch;
      onBatchComplete?.call(batchNumber, estimatedBatches ?? batchNumber);
      onProgress?.call(totalFetched, totalItems ?? totalFetched);
    }

    _logger.info(
      'Batch iteration complete: $totalFetched items in $batchNumber batches',
    );
  }

  /// Process items in parallel batches.
  ///
  /// Fetches all items and processes them in parallel using the specified
  /// processor function. Useful for CPU-bound processing or when items
  /// are independent and can be processed concurrently.
  ///
  /// Parameters:
  /// - [processor]: Function to process each item
  /// - [batchSize]: Number of items per parallel batch (default: [batchConfig.batchSize])
  /// - [maxConcurrency]: Maximum concurrent processors (default: [batchConfig.maxConcurrency])
  /// - [onProgress]: Optional progress callback
  ///
  /// Returns a list of results from all processed items.
  ///
  /// Example:
  /// ```dart
  /// final results = await iterator.processInParallel(
  ///   processor: (item) async {
  ///     final id = item['id'] as String;
  ///     return await enrichItem(item);
  ///   },
  ///   batchSize: 20,
  ///   maxConcurrency: 5,
  /// );
  /// ```
  Future<List<T>> processInParallel<T>({
    required Future<T> Function(Map<String, dynamic> item) processor,
    int? batchSize,
    int? maxConcurrency,
    void Function(int processed, int total)? onProgress,
  }) async {
    final int effectiveBatchSize = batchSize ?? batchConfig.batchSize;
    final int effectiveConcurrency =
        maxConcurrency ?? batchConfig.maxConcurrency;
    final List<T> results = <T>[];
    int processed = 0;
    int? total;

    _logger.fine(
      'Starting parallel processing for $entityType '
      '(batch: $effectiveBatchSize, concurrency: $effectiveConcurrency)',
    );

    // Get total count for progress
    try {
      total = await count();
    } catch (e) {
      _logger.warning('Could not get total count: $e');
    }

    await for (final List<Map<String, dynamic>> batch in iterateBatches(
      size: effectiveBatchSize,
    )) {
      // Process batch in parallel with limited concurrency
      final List<T> batchResults = await _processWithConcurrencyLimit<T>(
        items: batch,
        processor: processor,
        maxConcurrency: effectiveConcurrency,
      );

      results.addAll(batchResults);
      processed += batch.length;
      onProgress?.call(processed, total ?? processed);
    }

    _logger.info('Parallel processing complete: $processed items');
    return results;
  }

  /// Process items with a concurrency limit.
  Future<List<T>> _processWithConcurrencyLimit<T>({
    required List<Map<String, dynamic>> items,
    required Future<T> Function(Map<String, dynamic> item) processor,
    required int maxConcurrency,
  }) async {
    final List<T> results = <T>[];
    final List<Future<T>> pending = <Future<T>>[];

    for (final Map<String, dynamic> item in items) {
      if (pending.length >= maxConcurrency) {
        // Wait for one to complete before adding more
        final T result = await Future.any(pending);
        results.add(result);
        pending.removeWhere(
          (Future<T> future) => false,
        ); // Clean up completed futures
      }

      pending.add(processor(item));
    }

    // Wait for remaining futures
    final List<T> remaining = await Future.wait(pending);
    results.addAll(remaining);

    return results;
  }

  /// Iterate with detailed statistics collection.
  ///
  /// Returns an [IterationResult] containing both the items and detailed
  /// statistics about the iteration process.
  ///
  /// Example:
  /// ```dart
  /// final result = await iterator.iterateWithStats();
  /// print('Fetched ${result.items.length} items in ${result.stats.duration}');
  /// print('Average time per page: ${result.stats.averageTimePerPageMs}ms');
  /// ```
  Future<IterationResult> iterateWithStats() async {
    final DateTime startTime = DateTime.now();
    final List<Map<String, dynamic>> items = <Map<String, dynamic>>[];
    int pagesRequested = 0;
    int? serverTotal;

    _logger.fine('Starting iteration with stats for $entityType');

    int page = 1;
    while (true) {
      final DateTime pageStartTime = DateTime.now();
      final PaginatedResult<Map<String, dynamic>> result =
          await _fetchPageWithRetry(page);
      final Duration pageTime = DateTime.now().difference(pageStartTime);

      pagesRequested++;
      serverTotal ??= result.total;

      items.addAll(result.data);

      _logger.finest(
        () =>
            'Page $page fetched in ${pageTime.inMilliseconds}ms '
            '(${result.data.length} items)',
      );

      if (!result.hasMore) {
        break;
      }

      if (batchConfig.batchDelay > Duration.zero) {
        await Future<void>.delayed(batchConfig.batchDelay);
      }

      page++;
    }

    final Duration totalDuration = DateTime.now().difference(startTime);

    final IterationStats stats = IterationStats(
      itemsFetched: items.length,
      pagesRequested: pagesRequested,
      // serverTotal is guaranteed to be set after at least 1 iteration of the while loop
      serverTotal: serverTotal,
      duration: totalDuration,
    );

    _logger.info('Iteration complete: ${stats.toString()}');

    return IterationResult(items: items, stats: stats);
  }

  /// Fetch a single page of results.
  ///
  /// Internal method that dispatches to the appropriate API method
  /// based on [entityType]. Passes sort/order parameters if provided.
  Future<PaginatedResult<Map<String, dynamic>>> _fetchPage(int page) {
    switch (entityType) {
      case 'transaction':
        return apiClient.getTransactionsPaginated(
          page: page,
          start: start,
          end: end,
          limit: pageSize,
          sort: sort,
          order: order,
        );
      case 'account':
        return apiClient.getAccountsPaginated(
          page: page,
          start: start,
          limit: pageSize,
          sort: sort,
          order: order,
        );
      case 'budget':
        return apiClient.getBudgetsPaginated(
          page: page,
          start: start,
          end: end,
          limit: pageSize,
          sort: sort,
          order: order,
        );
      case 'category':
        return apiClient.getCategoriesPaginated(
          page: page,
          limit: pageSize,
          sort: sort,
          order: order,
        );
      case 'bill':
        return apiClient.getBillsPaginated(
          page: page,
          limit: pageSize,
          sort: sort,
          order: order,
        );
      case 'piggy_bank':
        return apiClient.getPiggyBanksPaginated(
          page: page,
          limit: pageSize,
          sort: sort,
          order: order,
        );
      default:
        throw ArgumentError('Unknown entity type: $entityType');
    }
  }
}

/// Statistics collected during iteration.
///
/// Returned by [DateRangeIterator.iterateWithStats] to provide
/// insights into the pagination process.
class IterationStats {
  /// Total number of items fetched.
  final int itemsFetched;

  /// Total number of pages requested.
  final int pagesRequested;

  /// Total number of items reported by the server.
  final int serverTotal;

  /// Duration of the entire iteration.
  final Duration duration;

  /// Number of retry attempts made during iteration.
  final int retryAttempts;

  /// Number of failed requests (after all retries).
  final int failedRequests;

  /// Whether iteration terminated early (due to stopWhenProcessed callback).
  final bool terminatedEarly;

  /// Creates iteration statistics.
  const IterationStats({
    required this.itemsFetched,
    required this.pagesRequested,
    required this.serverTotal,
    required this.duration,
    this.retryAttempts = 0,
    this.failedRequests = 0,
    this.terminatedEarly = false,
  });

  /// Average items per page.
  double get averagePerPage =>
      pagesRequested > 0 ? itemsFetched / pagesRequested : 0.0;

  /// Average time per page in milliseconds.
  double get averageTimePerPageMs =>
      pagesRequested > 0 ? duration.inMilliseconds / pagesRequested : 0.0;

  /// Throughput in items per second.
  double get itemsPerSecond =>
      duration.inMilliseconds > 0
          ? itemsFetched / (duration.inMilliseconds / 1000.0)
          : 0.0;

  /// Success rate (1.0 if no failed requests).
  double get successRate =>
      pagesRequested > 0
          ? (pagesRequested - failedRequests) / pagesRequested
          : 1.0;

  /// Create a copy with updated values.
  IterationStats copyWith({
    int? itemsFetched,
    int? pagesRequested,
    int? serverTotal,
    Duration? duration,
    int? retryAttempts,
    int? failedRequests,
    bool? terminatedEarly,
  }) {
    return IterationStats(
      itemsFetched: itemsFetched ?? this.itemsFetched,
      pagesRequested: pagesRequested ?? this.pagesRequested,
      serverTotal: serverTotal ?? this.serverTotal,
      duration: duration ?? this.duration,
      retryAttempts: retryAttempts ?? this.retryAttempts,
      failedRequests: failedRequests ?? this.failedRequests,
      terminatedEarly: terminatedEarly ?? this.terminatedEarly,
    );
  }

  /// Convert to JSON for logging/storage.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'itemsFetched': itemsFetched,
    'pagesRequested': pagesRequested,
    'serverTotal': serverTotal,
    'durationMs': duration.inMilliseconds,
    'retryAttempts': retryAttempts,
    'failedRequests': failedRequests,
    'terminatedEarly': terminatedEarly,
    'averagePerPage': averagePerPage,
    'averageTimePerPageMs': averageTimePerPageMs,
    'itemsPerSecond': itemsPerSecond,
    'successRate': successRate,
  };

  @override
  String toString() =>
      'IterationStats('
      'fetched: $itemsFetched, '
      'pages: $pagesRequested, '
      'serverTotal: $serverTotal, '
      'duration: ${duration.inMilliseconds}ms, '
      'throughput: ${itemsPerSecond.toStringAsFixed(1)} items/s'
      '${terminatedEarly ? ', terminatedEarly: true' : ''}'
      ')';
}

/// Result of iteration with statistics.
///
/// Contains both the fetched items and detailed statistics about
/// the iteration process.
class IterationResult {
  /// All items fetched during iteration.
  final List<Map<String, dynamic>> items;

  /// Statistics about the iteration process.
  final IterationStats stats;

  /// Creates an iteration result.
  const IterationResult({required this.items, required this.stats});

  /// Whether the iteration was successful (all items fetched).
  bool get isComplete => items.length == stats.serverTotal;

  /// Percentage of items fetched relative to server total.
  double get completionPercent =>
      stats.serverTotal > 0
          ? (items.length / stats.serverTotal) * 100.0
          : 100.0;

  @override
  String toString() =>
      'IterationResult('
      'items: ${items.length}, '
      'complete: $isComplete, '
      'stats: $stats'
      ')';
}

/// Callback type for progress reporting.
typedef ProgressCallback = void Function(int itemsFetched, int totalItems);

/// Callback type for batch completion reporting.
typedef BatchCompleteCallback =
    void Function(int batchNumber, int estimatedTotalBatches);

/// Callback type for error handling during iteration.
typedef ErrorCallback =
    void Function(int page, Object error, StackTrace stackTrace);
