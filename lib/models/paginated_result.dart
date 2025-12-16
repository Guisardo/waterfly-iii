/// Pagination metadata and data from Firefly III API responses.
///
/// This class wraps paginated API responses and provides convenient
/// methods for checking if more pages are available and iterating
/// through results. It is a core component of the incremental sync
/// system, enabling efficient fetching of large datasets.
///
/// The Firefly III API returns pagination metadata in the format:
/// ```json
/// {
///   "meta": {
///     "pagination": {
///       "total": 1523,
///       "count": 50,
///       "per_page": 50,
///       "current_page": 1,
///       "total_pages": 31
///     }
///   }
/// }
/// ```
///
/// Example usage:
/// ```dart
/// final result = await apiAdapter.getTransactionsPaginated(page: 1);
/// print('Fetched ${result.data.length} of ${result.total} transactions');
///
/// if (result.hasMore) {
///   print('More pages available: page ${result.currentPage} of ${result.totalPages}');
/// }
///
/// // Iterate through all pages
/// while (result.hasMore) {
///   result = await apiAdapter.getTransactionsPaginated(page: result.currentPage + 1);
///   // Process result.data
/// }
/// ```
class PaginatedResult<T> {
  /// Data items for the current page.
  ///
  /// Contains the actual entities returned by the API for this page.
  /// The length should equal or be less than [perPage].
  final List<T> data;

  /// Total number of items across all pages.
  ///
  /// This value represents the complete dataset size on the server,
  /// regardless of pagination. Used for progress tracking and
  /// determining when all data has been fetched.
  final int total;

  /// Current page number (1-indexed).
  ///
  /// Firefly III API uses 1-indexed pages, so the first page is 1.
  /// This matches the value passed in the API request.
  final int currentPage;

  /// Total number of pages available.
  ///
  /// Calculated by the server as `ceil(total / perPage)`.
  /// Used to determine when pagination is complete.
  final int totalPages;

  /// Number of items per page.
  ///
  /// This is the requested page size. The actual number of items
  /// returned in [data] may be less on the last page.
  final int perPage;

  /// Creates a new paginated result.
  ///
  /// All parameters are required:
  /// - [data]: List of items for this page
  /// - [total]: Total items across all pages
  /// - [currentPage]: Current page number (1-indexed)
  /// - [totalPages]: Total number of pages
  /// - [perPage]: Items per page
  const PaginatedResult({
    required this.data,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.perPage,
  });

  /// Whether there are more pages to fetch.
  ///
  /// Returns `true` if [currentPage] is less than [totalPages].
  /// Used to control pagination loops.
  ///
  /// Example:
  /// ```dart
  /// int page = 1;
  /// while (true) {
  ///   final result = await api.getTransactionsPaginated(page: page);
  ///   processData(result.data);
  ///   if (!result.hasMore) break;
  ///   page++;
  /// }
  /// ```
  bool get hasMore => currentPage < totalPages;

  /// Percentage of data fetched so far (0.0 to 100.0).
  ///
  /// Calculated as `(currentPage / totalPages) * 100`.
  /// Useful for progress indicators.
  ///
  /// Returns 100.0 if [totalPages] is 0 to avoid division by zero.
  double get progressPercent =>
      totalPages > 0 ? (currentPage / totalPages) * 100.0 : 100.0;

  /// Number of items fetched so far across all processed pages.
  ///
  /// Calculated as `(currentPage - 1) * perPage + data.length`.
  /// Useful for "Fetched X of Y items" progress messages.
  int get itemsFetchedSoFar => (currentPage - 1) * perPage + data.length;

  /// Whether this is the first page.
  bool get isFirstPage => currentPage == 1;

  /// Whether this is the last page.
  bool get isLastPage => currentPage >= totalPages;

  /// Whether there is only one page of data.
  bool get isSinglePage => totalPages <= 1;

  /// Number of pages remaining after this one.
  int get remainingPages => totalPages > currentPage ? totalPages - currentPage : 0;

  /// Creates a copy with different data but same pagination metadata.
  ///
  /// Useful for transforming the data type while preserving pagination info.
  ///
  /// Example:
  /// ```dart
  /// final rawResult = await api.getTransactionsPaginated(page: 1);
  /// final entityResult = rawResult.copyWith(
  ///   data: rawResult.data.map((json) => Transaction.fromJson(json)).toList(),
  /// );
  /// ```
  PaginatedResult<R> copyWith<R>({
    List<R>? data,
    int? total,
    int? currentPage,
    int? totalPages,
    int? perPage,
  }) {
    return PaginatedResult<R>(
      data: data ?? (this.data as List<R>),
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      perPage: perPage ?? this.perPage,
    );
  }

  /// Creates an empty result (no data, no pages).
  ///
  /// Useful as a default value or when no data is found.
  factory PaginatedResult.empty() {
    return PaginatedResult<T>(
      data: <T>[],
      total: 0,
      currentPage: 1,
      totalPages: 0,
      perPage: 50,
    );
  }

  /// Creates a result from a list (single page, all data).
  ///
  /// Useful for wrapping a complete list as a paginated result.
  ///
  /// Example:
  /// ```dart
  /// final allCategories = await api.getAllCategories();
  /// final result = PaginatedResult.fromList(allCategories);
  /// ```
  factory PaginatedResult.fromList(List<T> items, {int perPage = 50}) {
    return PaginatedResult<T>(
      data: items,
      total: items.length,
      currentPage: 1,
      totalPages: 1,
      perPage: perPage,
    );
  }

  @override
  String toString() => 'PaginatedResult('
      'page $currentPage/$totalPages, '
      '${data.length} items, '
      '$total total'
      ')';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaginatedResult<T> &&
        other.total == total &&
        other.currentPage == currentPage &&
        other.totalPages == totalPages &&
        other.perPage == perPage &&
        _listEquals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(
        data.hashCode,
        total,
        currentPage,
        totalPages,
        perPage,
      );

  /// Deep equality check for lists.
  static bool _listEquals<E>(List<E>? a, List<E>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

