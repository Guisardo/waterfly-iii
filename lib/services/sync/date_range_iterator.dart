import 'package:logging/logging.dart';
import 'package:waterflyiii/models/paginated_result.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';

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
/// ## Error Handling
///
/// Errors during pagination are logged and rethrown. If an error occurs
/// mid-pagination, the iterator stops and propagates the error to the caller.
/// The caller can catch the error and decide whether to retry, skip, or abort.
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

  /// Logger for this iterator.
  final Logger _logger = Logger('DateRangeIterator');

  /// Creates a new date range iterator.
  ///
  /// Parameters:
  /// - [apiClient]: The API adapter to use for requests
  /// - [entityType]: Type of entity to fetch ('transaction', 'account', etc.)
  /// - [start]: Start of date range
  /// - [end]: Optional end of date range (defaults to now)
  /// - [pageSize]: Number of items per page (default: 50)
  DateRangeIterator({
    required this.apiClient,
    required this.entityType,
    required this.start,
    this.end,
    this.pageSize = 50,
  });

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
    _logger.fine('Starting iteration for $entityType (start: $start, end: $end)');

    int page = 1;
    int totalFetched = 0;

    while (true) {
      PaginatedResult<Map<String, dynamic>> result;

      try {
        result = await _fetchPage(page);

        for (final Map<String, dynamic> item in result.data) {
          yield item;
          totalFetched++;
        }

        _logger.fine(
          'Fetched page $page: ${result.data.length} items '
          '(${result.currentPage}/${result.totalPages})',
        );

        if (!result.hasMore) {
          _logger.info('Completed iteration for $entityType: $totalFetched total items fetched');
          break;
        }

        page++;
      } catch (e, stackTrace) {
        _logger.severe('Error fetching page $page for $entityType', e, stackTrace);
        rethrow;
      }
    }
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
          _logger.info('Completed iteration for $entityType: $totalFetched total items');
          break;
        }

        page++;
      } catch (e, stackTrace) {
        _logger.severe('Error fetching page $page for $entityType', e, stackTrace);
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
    await for (final Map<String, dynamic> item
        in iterateWithProgress(onProgress: onProgress)) {
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
    final PaginatedResult<Map<String, dynamic>> result = await _fetchPage(1);
    return result.total;
  }

  /// Fetch a single page of results.
  ///
  /// Internal method that dispatches to the appropriate API method
  /// based on [entityType].
  Future<PaginatedResult<Map<String, dynamic>>> _fetchPage(int page) async {
    switch (entityType) {
      case 'transaction':
        return apiClient.getTransactionsPaginated(
          page: page,
          start: start,
          end: end,
          limit: pageSize,
        );
      case 'account':
        return apiClient.getAccountsPaginated(
          page: page,
          start: start,
          limit: pageSize,
        );
      case 'budget':
        return apiClient.getBudgetsPaginated(
          page: page,
          start: start,
          end: end,
          limit: pageSize,
        );
      case 'category':
        return apiClient.getCategoriesPaginated(
          page: page,
          limit: pageSize,
        );
      case 'bill':
        return apiClient.getBillsPaginated(
          page: page,
          limit: pageSize,
        );
      case 'piggy_bank':
        return apiClient.getPiggyBanksPaginated(
          page: page,
          limit: pageSize,
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

  /// Creates iteration statistics.
  const IterationStats({
    required this.itemsFetched,
    required this.pagesRequested,
    required this.serverTotal,
    required this.duration,
  });

  /// Average items per page.
  double get averagePerPage =>
      pagesRequested > 0 ? itemsFetched / pagesRequested : 0.0;

  /// Average time per page in milliseconds.
  double get averageTimePerPageMs =>
      pagesRequested > 0 ? duration.inMilliseconds / pagesRequested : 0.0;

  @override
  String toString() => 'IterationStats('
      'fetched: $itemsFetched, '
      'pages: $pagesRequested, '
      'serverTotal: $serverTotal, '
      'duration: ${duration.inMilliseconds}ms'
      ')';
}

