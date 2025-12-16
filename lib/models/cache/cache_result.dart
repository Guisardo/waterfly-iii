/// Cache Result Model
///
/// Represents the result of a cache operation, including the retrieved data,
/// its source (cache or API), and freshness status.
///
/// This model is returned by CacheService.get() operations and provides
/// comprehensive information about the cached data to enable:
/// - UI decisions (show refresh indicator for stale data)
/// - Performance monitoring (track cache hit rates)
/// - Debugging (understand cache behavior)
///
/// The model uses generics to support any data type while maintaining
/// type safety throughout the caching layer.
///
/// Example Usage:
/// ```dart
/// final result = await cacheService.get<Account>(
///   entityType: 'account',
///   entityId: '123',
///   fetcher: () => apiClient.getAccount('123'),
/// );
///
/// if (result.data != null) {
///   // Display account data
///   displayAccount(result.data!);
///
///   // Show refresh indicator if stale
///   if (!result.isFresh) {
///     showRefreshIndicator('Updating...');
///   }
///
///   // Log cache source for monitoring
///   log.fine('Account loaded from: ${result.source}');
/// }
/// ```
class CacheResult<T> {
  /// The cached or fetched data
  ///
  /// Nullable because:
  /// - Cache miss with failed API fetch returns null
  /// - Deleted entities may exist in cache metadata but not in data tables
  /// - Invalid/corrupted cache entries may return null
  ///
  /// When non-null, type T is guaranteed by generic constraints.
  final T? data;

  /// Source of the data (cache or API)
  ///
  /// Indicates where the data came from:
  /// - CacheSource.cache: Retrieved from local database (instant)
  /// - CacheSource.api: Fetched from Firefly III API (network latency)
  ///
  /// Used for:
  /// - Performance monitoring (cache hit rate)
  /// - UI feedback (show "cached" indicator)
  /// - Debugging cache behavior
  /// - Statistics tracking
  final CacheSource source;

  /// Whether the cached data is fresh or stale
  ///
  /// Fresh data: cachedAt + ttl > now
  /// - Returned immediately without background refresh
  /// - Guaranteed to be within TTL window
  /// - No API call needed
  ///
  /// Stale data: cachedAt + ttl < now
  /// - Returned immediately (instant UI)
  /// - Background refresh triggered automatically
  /// - UI updated when fresh data arrives
  ///
  /// This flag enables stale-while-revalidate pattern:
  /// - Always fast UI (return cached data immediately)
  /// - Always eventually consistent (background refresh)
  /// - Reduced perceived latency (no loading spinners for stale data)
  final bool isFresh;

  /// Timestamp when the data was cached
  ///
  /// Nullable for data sourced directly from API (not yet cached).
  ///
  /// Used for:
  /// - Displaying "Last updated: 5 minutes ago" in UI
  /// - Calculating cache age for monitoring
  /// - Debugging stale data issues
  /// - User transparency about data freshness
  ///
  /// Format: DateTime in local timezone
  /// Example: 2024-12-15 14:30:00.000
  final DateTime? cachedAt;

  /// Creates a cache result with the specified properties
  ///
  /// Parameters:
  /// - [data]: The cached or fetched data (nullable)
  /// - [source]: Where the data came from (cache or API)
  /// - [isFresh]: Whether the data is within TTL window
  /// - [cachedAt]: When the data was cached (optional)
  ///
  /// Example:
  /// ```dart
  /// // Fresh cache hit
  /// final result = CacheResult<Account>(
  ///   data: cachedAccount,
  ///   source: CacheSource.cache,
  ///   isFresh: true,
  ///   cachedAt: DateTime.now().subtract(Duration(minutes: 2)),
  /// );
  ///
  /// // API fetch (not yet cached)
  /// final result = CacheResult<Account>(
  ///   data: fetchedAccount,
  ///   source: CacheSource.api,
  ///   isFresh: true,
  ///   cachedAt: null,
  /// );
  /// ```
  const CacheResult({
    required this.data,
    required this.source,
    required this.isFresh,
    this.cachedAt,
  });

  /// Check if this is a cache hit (data came from cache)
  ///
  /// Convenience getter for readability and statistics tracking.
  ///
  /// Returns true if source is CacheSource.cache, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (result.isCacheHit) {
  ///   metrics.incrementCacheHits();
  /// } else {
  ///   metrics.incrementCacheMisses();
  /// }
  /// ```
  bool get isCacheHit => source == CacheSource.cache;

  /// Check if this is a cache miss (data came from API)
  ///
  /// Convenience getter for readability and statistics tracking.
  ///
  /// Returns true if source is CacheSource.api, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// if (result.isCacheMiss) {
  ///   log.info('Cache miss for ${entityType}:${entityId}');
  /// }
  /// ```
  bool get isCacheMiss => source == CacheSource.api;

  /// Get cache age in seconds
  ///
  /// Returns the number of seconds since data was cached.
  /// Returns null if cachedAt is null (not yet cached).
  ///
  /// Useful for:
  /// - UI display ("Updated 5 minutes ago")
  /// - Monitoring cache performance
  /// - Debugging staleness issues
  ///
  /// Example:
  /// ```dart
  /// final age = result.cacheAgeSeconds;
  /// if (age != null && age > 300) {
  ///   showStaleDataWarning('Data is ${age ~/ 60} minutes old');
  /// }
  /// ```
  int? get cacheAgeSeconds {
    if (cachedAt == null) return null;
    return DateTime.now().difference(cachedAt!).inSeconds;
  }

  /// Get human-readable cache age string
  ///
  /// Formats cache age as a user-friendly string.
  /// Returns null if cachedAt is null.
  ///
  /// Format examples:
  /// - "just now" (< 30 seconds)
  /// - "2 minutes ago"
  /// - "1 hour ago"
  /// - "5 hours ago"
  ///
  /// Example:
  /// ```dart
  /// final ageStr = result.cacheAgeFormatted;
  /// showSubtitle('Last updated: $ageStr'); // "Last updated: 5 minutes ago"
  /// ```
  String? get cacheAgeFormatted {
    final age = cacheAgeSeconds;
    if (age == null) return null;

    if (age < 30) {
      return 'just now';
    } else if (age < 60) {
      return '$age seconds ago';
    } else if (age < 3600) {
      final minutes = age ~/ 60;
      return '${minutes} ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      final hours = age ~/ 3600;
      return '${hours} ${hours == 1 ? 'hour' : 'hours'} ago';
    }
  }

  /// Convert to string for debugging
  ///
  /// Provides detailed information about the cache result.
  ///
  /// Example output:
  /// ```
  /// CacheResult<Account>(
  ///   source: cache,
  ///   isFresh: false,
  ///   hasData: true,
  ///   cachedAt: 2024-12-15 14:30:00.000,
  ///   age: 300s
  /// )
  /// ```
  @override
  String toString() {
    return 'CacheResult<$T>('
        'source: ${source.name}, '
        'isFresh: $isFresh, '
        'hasData: ${data != null}, '
        'cachedAt: $cachedAt, '
        'age: ${cacheAgeSeconds}s'
        ')';
  }
}

/// Source of cached data
///
/// Indicates whether data was retrieved from local cache or remote API.
///
/// Used for:
/// - Performance monitoring (cache hit rate calculation)
/// - UI feedback (show "cached" badge)
/// - Debugging cache behavior
/// - Statistics tracking
///
/// Values:
/// - cache: Data retrieved from local Drift database (instant, offline-capable)
/// - api: Data fetched from Firefly III API (network latency, requires connectivity)
enum CacheSource {
  /// Data retrieved from local cache (Drift database)
  ///
  /// Benefits:
  /// - Instant response (no network latency)
  /// - Works offline
  /// - Reduced API load
  /// - Better user experience (no loading spinners)
  cache,

  /// Data fetched from remote API (Firefly III server)
  ///
  /// Occurs when:
  /// - Cache miss (no cached data)
  /// - Cache invalidated
  /// - Force refresh requested
  /// - First time fetching entity
  ///
  /// Characteristics:
  /// - Network latency (hundreds of milliseconds)
  /// - Requires internet connectivity
  /// - Fresh data guaranteed
  /// - Higher battery/data usage
  api,
}
