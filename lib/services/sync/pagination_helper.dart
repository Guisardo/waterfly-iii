import 'package:logging/logging.dart';

/// Helper service for handling API pagination.
///
/// Provides utilities for:
/// - Parsing pagination metadata from API responses
/// - Determining if more pages exist
/// - Rate limiting between page requests
/// - Logging pagination progress
///
/// Eliminates duplication between full_sync_service and incremental_sync_service.
class PaginationHelper {
  final Logger _logger = Logger('PaginationHelper');

  /// Rate limiting delay between page requests.
  final Duration rateLimitDelay;

  PaginationHelper({
    this.rateLimitDelay = const Duration(milliseconds: 100),
  });

  /// Parse pagination metadata from API response.
  ///
  /// Returns PaginationInfo with current page, total pages, and hasMore flag.
  PaginationInfo parsePagination(Map<String, dynamic> responseData) {
    final meta = responseData['meta'] as Map<String, dynamic>?;
    final pagination = meta?['pagination'] as Map<String, dynamic>?;

    if (pagination == null) {
      return PaginationInfo(
        currentPage: 1,
        totalPages: 1,
        hasMore: false,
      );
    }

    final currentPage = pagination['current_page'] as int? ?? 1;
    final totalPages = pagination['total_pages'] as int? ?? 1;
    final hasMore = currentPage < totalPages;

    return PaginationInfo(
      currentPage: currentPage,
      totalPages: totalPages,
      hasMore: hasMore,
      totalCount: pagination['total'] as int?,
      perPage: pagination['per_page'] as int?,
      count: pagination['count'] as int?,
    );
  }

  /// Log pagination progress.
  void logProgress(
    PaginationInfo info,
    String entityType,
    int currentBatchSize,
    int totalFetched,
  ) {
    _logger.fine(
      'Fetched page ${info.currentPage}/${info.totalPages} of $entityType '
      '($currentBatchSize items, $totalFetched total)',
    );
  }

  /// Apply rate limiting delay if more pages exist.
  Future<void> applyRateLimit(bool hasMore) async {
    if (hasMore) {
      await Future.delayed(rateLimitDelay);
    }
  }

  /// Fetch all pages using a fetcher function.
  ///
  /// Automatically handles pagination, rate limiting, and progress logging.
  ///
  /// Example:
  /// ```dart
  /// final allEntities = await paginationHelper.fetchAllPages(
  ///   entityType: 'transactions',
  ///   fetcher: (page) => apiClient.getTransactions(page: page),
  ///   dataExtractor: (response) => response['data'] as List,
  /// );
  /// ```
  Future<List<T>> fetchAllPages<T>({
    required String entityType,
    required Future<Map<String, dynamic>> Function(int page) fetcher,
    required List<T> Function(Map<String, dynamic> response) dataExtractor,
    void Function(PaginationInfo info, int totalFetched)? onProgress,
  }) async {
    final allItems = <T>[];
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      _logger.fine('Fetching page $page of $entityType');

      final response = await fetcher(page);
      final items = dataExtractor(response);
      allItems.addAll(items);

      final paginationInfo = parsePagination(response);
      hasMore = paginationInfo.hasMore;

      logProgress(paginationInfo, entityType, items.length, allItems.length);

      if (onProgress != null) {
        onProgress(paginationInfo, allItems.length);
      }

      page++;
      await applyRateLimit(hasMore);
    }

    _logger.info('Fetched ${allItems.length} $entityType across ${page - 1} pages');
    return allItems;
  }

  /// Fetch pages with custom control flow.
  ///
  /// Provides more control than fetchAllPages for complex scenarios.
  ///
  /// Example:
  /// ```dart
  /// await paginationHelper.fetchPagesWithControl(
  ///   entityType: 'transactions',
  ///   onPage: (page) async {
  ///     final response = await apiClient.getTransactions(page: page);
  ///     final items = response['data'] as List;
  ///     await processItems(items);
  ///     return response;
  ///   },
  /// );
  /// ```
  Future<void> fetchPagesWithControl({
    required String entityType,
    required Future<Map<String, dynamic>> Function(int page) onPage,
    bool Function(PaginationInfo info)? shouldContinue,
  }) async {
    int page = 1;
    bool hasMore = true;

    while (hasMore) {
      _logger.fine('Fetching page $page of $entityType');

      final response = await onPage(page);
      final paginationInfo = parsePagination(response);
      hasMore = paginationInfo.hasMore;

      if (shouldContinue != null && !shouldContinue(paginationInfo)) {
        _logger.info('Stopping pagination early at page $page');
        break;
      }

      page++;
      await applyRateLimit(hasMore);
    }

    _logger.info('Completed pagination for $entityType (${page - 1} pages)');
  }
}

/// Pagination information extracted from API response.
class PaginationInfo {
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final int? totalCount;
  final int? perPage;
  final int? count;

  PaginationInfo({
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    this.totalCount,
    this.perPage,
    this.count,
  });

  @override
  String toString() {
    return 'PaginationInfo('
        'page: $currentPage/$totalPages, '
        'hasMore: $hasMore'
        '${totalCount != null ? ', total: $totalCount' : ''}'
        ')';
  }
}
