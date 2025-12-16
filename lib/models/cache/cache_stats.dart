/// Cache Statistics Model
///
/// Comprehensive statistics about cache performance and usage.
/// Used for monitoring, debugging, and optimizing cache behavior.
///
/// These statistics help answer questions like:
/// - Is the cache working effectively? (hit rate)
/// - Are we caching too much data? (total size)
/// - Is stale-while-revalidate working? (stale served count)
/// - Which entity types benefit most from caching? (hits by type)
/// - Are background refreshes completing? (refresh count)
///
/// Statistics are cumulative since cache service initialization.
/// Reset when app restarts or cache service is recreated.
///
/// Example Usage:
/// ```dart
/// final stats = await cacheService.getStats();
///
/// print('Cache hit rate: ${stats.hitRatePercent.toStringAsFixed(1)}%');
/// print('Total requests: ${stats.totalRequests}');
/// print('Cache size: ${stats.totalCacheSizeMB} MB');
///
/// // Monitor performance
/// if (stats.hitRate < 0.75) {
///   log.warning('Cache hit rate below target: ${stats.hitRate}');
/// }
///
/// // Debug specific entity types
/// stats.hitsByEntityType.forEach((type, hits) {
///   print('$type: $hits hits');
/// });
/// ```
class CacheStats {
  /// Total number of cache requests
  ///
  /// Includes all cache operations:
  /// - Cache hits (fresh and stale)
  /// - Cache misses
  /// - Force refreshes (bypassing cache)
  ///
  /// This is the denominator for hit rate calculation.
  /// Incremented on every CacheService.get() call.
  ///
  /// Example: 1000 total requests in the current session
  final int totalRequests;

  /// Number of cache hits (fresh data returned)
  ///
  /// Count of requests where:
  /// - Cached entry exists
  /// - Entry is not invalidated
  /// - Entry is fresh (within TTL window)
  /// - Data returned immediately without API call
  ///
  /// This is the numerator for hit rate calculation.
  ///
  /// High cache hits = good cache performance
  /// Low cache hits = need to tune TTL or fix invalidation
  ///
  /// Example: 750 cache hits out of 1000 total requests
  final int cacheHits;

  /// Number of cache misses (API fetch required)
  ///
  /// Count of requests where:
  /// - No cached entry exists
  /// - Entry is invalidated
  /// - Force refresh requested
  /// - First time fetching entity
  ///
  /// High cache misses = need to improve caching strategy
  ///
  /// Example: 200 cache misses out of 1000 total requests
  final int cacheMisses;

  /// Number of times stale data was served
  ///
  /// Count of requests where:
  /// - Cached entry exists
  /// - Entry is stale (beyond TTL window)
  /// - Stale data returned immediately
  /// - Background refresh triggered
  ///
  /// This measures stale-while-revalidate effectiveness.
  /// High stale served = good UX (instant response with eventual consistency)
  ///
  /// Formula: staleServed = totalRequests - cacheHits - cacheMisses
  ///
  /// Example: 50 stale served out of 1000 total requests
  final int staleServed;

  /// Number of background refreshes completed
  ///
  /// Count of successful background refresh operations after serving stale data.
  ///
  /// Ideally: backgroundRefreshes ≈ staleServed (all refreshes succeed)
  /// If backgroundRefreshes << staleServed: network issues or API errors
  ///
  /// Used to monitor background refresh health.
  ///
  /// Example: 48 successful refreshes out of 50 stale served (96% success rate)
  final int backgroundRefreshes;

  /// Number of cache entries evicted (LRU eviction)
  ///
  /// Count of cache entries removed due to:
  /// - Cache size exceeding limit
  /// - LRU eviction (least recently used)
  /// - Manual cache clearing
  /// - Expired entry cleanup
  ///
  /// High evictions may indicate:
  /// - Cache size limit too low
  /// - Too much data being cached
  /// - Need to adjust TTL values
  ///
  /// Example: 25 evictions in the current session
  final int evictions;

  /// Cache hit rate (0.0 - 1.0)
  ///
  /// Ratio of cache hits to total requests.
  /// Primary metric for cache performance.
  ///
  /// Formula: hitRate = cacheHits / totalRequests
  ///
  /// Target hit rates:
  /// - Excellent: > 0.80 (80%+)
  /// - Good: 0.70 - 0.80 (70-80%)
  /// - Acceptable: 0.60 - 0.70 (60-70%)
  /// - Poor: < 0.60 (< 60%, needs investigation)
  ///
  /// A hit rate of 0.75 means 75% of requests served from cache (instant),
  /// resulting in 75% reduction in API calls.
  ///
  /// Example: 0.75 (75% hit rate)
  final double hitRate;

  /// Average age of cached entries in seconds
  ///
  /// Measures how long data stays in cache on average.
  ///
  /// High average age may indicate:
  /// - TTL values too long (stale data risk)
  /// - Low cache churn (good if hit rate high)
  ///
  /// Low average age may indicate:
  /// - TTL values too short (poor performance)
  /// - High cache churn (frequent invalidations)
  ///
  /// Ideal: average age ≈ 50-70% of average TTL
  ///
  /// Example: 450 seconds (7.5 minutes average age)
  final int averageAgeSeconds;

  /// Total size of cache in megabytes
  ///
  /// Estimated size of all cached data (metadata + entity data).
  ///
  /// Used for:
  /// - LRU eviction decisions
  /// - User transparency (show cache size in settings)
  /// - Storage management
  /// - Performance monitoring
  ///
  /// Calculation includes:
  /// - cache_metadata table size
  /// - Entity table rows with is_cached=true
  /// - Estimated overhead (indexes, etc.)
  ///
  /// Warning thresholds:
  /// - < 50 MB: Normal
  /// - 50-100 MB: Monitor
  /// - 100-200 MB: High (consider eviction)
  /// - > 200 MB: Very high (aggressive eviction needed)
  ///
  /// Example: 45 MB total cache size
  final int totalCacheSizeMB;

  /// Total number of cache entries
  ///
  /// Count of rows in cache_metadata table.
  ///
  /// Includes all cache entries (fresh, stale, invalidated).
  /// Used for monitoring cache growth.
  ///
  /// Example: 523 total cache entries
  final int totalEntries;

  /// Number of invalidated cache entries
  ///
  /// Count of cache entries with is_invalidated = true.
  ///
  /// High invalidated count may indicate:
  /// - Recent bulk invalidation (sync, account switch)
  /// - Invalidation cascade from entity mutations
  /// - Need to run cleanup (remove invalidated entries)
  ///
  /// These entries are treated as cache misses but preserved for
  /// potential stale-while-revalidate if API fetch fails.
  ///
  /// Example: 47 invalidated entries out of 523 total
  final int invalidatedEntries;

  /// Cache hits broken down by entity type
  ///
  /// Map of entity type to hit count.
  ///
  /// Used to identify:
  /// - Which entity types benefit most from caching
  /// - Which entity types have poor cache performance
  /// - Where to focus optimization efforts
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'transaction': 350,
  ///   'account': 200,
  ///   'budget': 150,
  ///   'category': 50,
  /// }
  /// ```
  ///
  /// Analysis:
  /// - Transactions are most cached (optimize TTL)
  /// - Categories have few hits (consider longer TTL)
  final Map<String, int> hitsByEntityType;

  /// Creates cache statistics with the specified values
  ///
  /// Parameters:
  /// - [totalRequests]: Total cache requests
  /// - [cacheHits]: Number of cache hits
  /// - [cacheMisses]: Number of cache misses
  /// - [staleServed]: Number of stale data served
  /// - [backgroundRefreshes]: Number of background refreshes
  /// - [evictions]: Number of cache evictions
  /// - [hitRate]: Cache hit rate (0.0 - 1.0)
  /// - [averageAgeSeconds]: Average cache entry age
  /// - [totalCacheSizeMB]: Total cache size in MB
  /// - [totalEntries]: Total number of cache entries
  /// - [invalidatedEntries]: Number of invalidated entries
  /// - [hitsByEntityType]: Hit counts by entity type
  ///
  /// Example:
  /// ```dart
  /// final stats = CacheStats(
  ///   totalRequests: 1000,
  ///   cacheHits: 750,
  ///   cacheMisses: 200,
  ///   staleServed: 50,
  ///   backgroundRefreshes: 48,
  ///   evictions: 25,
  ///   hitRate: 0.75,
  ///   averageAgeSeconds: 450,
  ///   totalCacheSizeMB: 45,
  ///   totalEntries: 523,
  ///   invalidatedEntries: 47,
  ///   hitsByEntityType: {'transaction': 350, 'account': 200},
  /// );
  /// ```
  const CacheStats({
    required this.totalRequests,
    required this.cacheHits,
    required this.cacheMisses,
    required this.staleServed,
    required this.backgroundRefreshes,
    required this.evictions,
    required this.hitRate,
    required this.averageAgeSeconds,
    required this.totalCacheSizeMB,
    required this.totalEntries,
    required this.invalidatedEntries,
    required this.hitsByEntityType,
  });

  /// Get hit rate as percentage (0-100)
  ///
  /// Convenience getter for display purposes.
  ///
  /// Example:
  /// ```dart
  /// print('Hit rate: ${stats.hitRatePercent.toStringAsFixed(1)}%');
  /// // Output: "Hit rate: 75.0%"
  /// ```
  double get hitRatePercent => hitRate * 100;

  /// Get cache miss rate (0.0 - 1.0)
  ///
  /// Inverse of hit rate.
  ///
  /// Formula: missRate = cacheMisses / totalRequests
  ///
  /// Example:
  /// ```dart
  /// if (stats.missRate > 0.3) {
  ///   log.warning('Cache miss rate high: ${stats.missRate}');
  /// }
  /// ```
  double get missRate {
    if (totalRequests == 0) return 0.0;
    return cacheMisses / totalRequests;
  }

  /// Get stale serve rate (0.0 - 1.0)
  ///
  /// Ratio of stale data served to total requests.
  ///
  /// Formula: staleRate = staleServed / totalRequests
  ///
  /// Target: 5-15% (stale-while-revalidate working effectively)
  /// Too high (> 20%): TTL values may be too short
  /// Too low (< 5%): TTL values may be too long or cache not filling
  ///
  /// Example:
  /// ```dart
  /// print('Stale rate: ${stats.staleRate * 100}%'); // 5.0%
  /// ```
  double get staleRate {
    if (totalRequests == 0) return 0.0;
    return staleServed / totalRequests;
  }

  /// Get background refresh success rate (0.0 - 1.0)
  ///
  /// Ratio of successful background refreshes to stale served.
  ///
  /// Formula: refreshRate = backgroundRefreshes / staleServed
  ///
  /// Target: > 0.95 (95%+ success rate)
  /// Low success rate indicates network issues or API errors.
  ///
  /// Example:
  /// ```dart
  /// if (stats.refreshSuccessRate < 0.90) {
  ///   log.warning('Background refresh failing: ${stats.refreshSuccessRate}');
  /// }
  /// ```
  double get refreshSuccessRate {
    if (staleServed == 0) return 1.0; // No stale served = 100% success (vacuous)
    return backgroundRefreshes / staleServed;
  }

  /// Get invalidation rate (0.0 - 1.0)
  ///
  /// Ratio of invalidated entries to total entries.
  ///
  /// Formula: invalidationRate = invalidatedEntries / totalEntries
  ///
  /// High invalidation rate (> 0.30) may indicate:
  /// - Recent bulk invalidation event
  /// - Excessive cache churn
  /// - Need to run cleanup
  ///
  /// Example:
  /// ```dart
  /// if (stats.invalidationRate > 0.30) {
  ///   await cacheService.cleanExpired(); // Clean up
  /// }
  /// ```
  double get invalidationRate {
    if (totalEntries == 0) return 0.0;
    return invalidatedEntries / totalEntries;
  }

  /// Get average cache entry age formatted as string
  ///
  /// Human-readable format for UI display.
  ///
  /// Format examples:
  /// - "7 minutes"
  /// - "1 hour 15 minutes"
  /// - "2 hours"
  ///
  /// Example:
  /// ```dart
  /// print('Average age: ${stats.averageAgeFormatted}');
  /// // Output: "Average age: 7 minutes"
  /// ```
  String get averageAgeFormatted {
    if (averageAgeSeconds < 60) {
      return '$averageAgeSeconds seconds';
    } else if (averageAgeSeconds < 3600) {
      final minutes = averageAgeSeconds ~/ 60;
      return '${minutes} ${minutes == 1 ? 'minute' : 'minutes'}';
    } else {
      final hours = averageAgeSeconds ~/ 3600;
      final remainingMinutes = (averageAgeSeconds % 3600) ~/ 60;
      if (remainingMinutes == 0) {
        return '${hours} ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '${hours} ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes ${remainingMinutes == 1 ? 'minute' : 'minutes'}';
    }
  }

  /// Check if cache performance is healthy
  ///
  /// Returns true if all key metrics meet targets:
  /// - Hit rate > 0.70 (70%+)
  /// - Refresh success rate > 0.90 (90%+)
  /// - Cache size < 150 MB
  ///
  /// Used for automated health checks and monitoring.
  ///
  /// Example:
  /// ```dart
  /// if (!stats.isHealthy) {
  ///   log.warning('Cache performance degraded');
  ///   analytics.trackCacheHealth(stats);
  /// }
  /// ```
  bool get isHealthy {
    return hitRate > 0.70 &&
        refreshSuccessRate > 0.90 &&
        totalCacheSizeMB < 150;
  }

  /// Convert to map for serialization
  ///
  /// Useful for:
  /// - Logging statistics
  /// - Analytics tracking
  /// - Debugging output
  /// - JSON serialization
  ///
  /// Example:
  /// ```dart
  /// final statsMap = stats.toMap();
  /// log.info('Cache stats: $statsMap');
  /// analytics.trackEvent('cache_stats', statsMap);
  /// ```
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'totalRequests': totalRequests,
      'cacheHits': cacheHits,
      'cacheMisses': cacheMisses,
      'staleServed': staleServed,
      'backgroundRefreshes': backgroundRefreshes,
      'evictions': evictions,
      'hitRate': hitRate,
      'hitRatePercent': hitRatePercent,
      'missRate': missRate,
      'staleRate': staleRate,
      'refreshSuccessRate': refreshSuccessRate,
      'averageAgeSeconds': averageAgeSeconds,
      'averageAgeFormatted': averageAgeFormatted,
      'totalCacheSizeMB': totalCacheSizeMB,
      'totalEntries': totalEntries,
      'invalidatedEntries': invalidatedEntries,
      'invalidationRate': invalidationRate,
      'isHealthy': isHealthy,
      'hitsByEntityType': hitsByEntityType,
    };
  }

  /// Convert to string for debugging
  ///
  /// Provides detailed statistics summary.
  ///
  /// Example output:
  /// ```
  /// CacheStats(
  ///   requests: 1000,
  ///   hits: 750 (75.0%),
  ///   misses: 200 (20.0%),
  ///   stale: 50 (5.0%),
  ///   refreshes: 48/50 (96.0%),
  ///   size: 45 MB,
  ///   entries: 523,
  ///   healthy: true
  /// )
  /// ```
  @override
  String toString() {
    return 'CacheStats(\n'
        '  requests: $totalRequests,\n'
        '  hits: $cacheHits (${hitRatePercent.toStringAsFixed(1)}%),\n'
        '  misses: $cacheMisses (${(missRate * 100).toStringAsFixed(1)}%),\n'
        '  stale: $staleServed (${(staleRate * 100).toStringAsFixed(1)}%),\n'
        '  refreshes: $backgroundRefreshes/$staleServed (${(refreshSuccessRate * 100).toStringAsFixed(1)}%),\n'
        '  evictions: $evictions,\n'
        '  avgAge: $averageAgeFormatted,\n'
        '  size: $totalCacheSizeMB MB,\n'
        '  entries: $totalEntries (${invalidatedEntries} invalidated),\n'
        '  healthy: $isHealthy\n'
        ')';
  }
}
