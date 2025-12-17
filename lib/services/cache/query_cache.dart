import 'dart:collection';

import 'package:logging/logging.dart';

/// LRU (Least Recently Used) cache for database query results.
///
/// Caches frequently accessed queries to improve performance.
/// Automatically evicts least recently used entries when size limit reached.
///
/// Example:
/// ```dart
/// final cache = QueryCache(maxSizeBytes: 50 * 1024 * 1024); // 50MB
///
/// // Store query result
/// cache.put('transactions_recent', transactions);
///
/// // Retrieve cached result
/// final cached = cache.get<List<Transaction>>('transactions_recent');
/// ```
class QueryCache {
  final Logger _logger = Logger('QueryCache');

  /// Maximum cache size in bytes
  final int maxSizeBytes;

  /// Current cache size in bytes
  int _currentSizeBytes = 0;

  /// Cache storage (key -> entry)
  final LinkedHashMap<String, _CacheEntry> _cache = LinkedHashMap();

  /// Cache hit count for metrics
  int _hitCount = 0;

  /// Cache miss count for metrics
  int _missCount = 0;

  /// Cache eviction count for metrics
  int _evictionCount = 0;

  QueryCache({this.maxSizeBytes = 50 * 1024 * 1024}); // Default 50MB

  /// Retrieves a cached value by key
  ///
  /// Returns null if key not found or entry expired.
  /// Updates access time for LRU ordering.
  T? get<T>(String key) {
    final _CacheEntry? entry = _cache[key];

    if (entry == null) {
      _missCount++;
      _logger.fine('Cache miss: $key');
      return null;
    }

    // Check if expired
    if (entry.isExpired) {
      _logger.fine('Cache entry expired: $key');
      remove(key);
      _missCount++;
      return null;
    }

    // Update access time (move to end for LRU)
    _cache.remove(key);
    entry.lastAccessTime = DateTime.now();
    _cache[key] = entry;

    _hitCount++;
    _logger.fine('Cache hit: $key');

    return entry.value as T;
  }

  /// Stores a value in the cache
  ///
  /// If cache is full, evicts least recently used entries.
  /// Optionally specify TTL (time to live) for the entry.
  void put<T>(String key, T value, {Duration? ttl}) {
    _logger.fine('Caching: $key');

    // Estimate size (simplified - actual size calculation would be more complex)
    final int estimatedSize = _estimateSize(value);

    // Remove existing entry if present
    if (_cache.containsKey(key)) {
      remove(key);
    }

    // Evict entries if necessary
    while (_currentSizeBytes + estimatedSize > maxSizeBytes &&
        _cache.isNotEmpty) {
      _evictLRU();
    }

    // Add new entry
    final _CacheEntry entry = _CacheEntry(
      value: value,
      sizeBytes: estimatedSize,
      createdAt: DateTime.now(),
      lastAccessTime: DateTime.now(),
      ttl: ttl,
    );

    _cache[key] = entry;
    _currentSizeBytes += estimatedSize;

    _logger.fine(
      'Cached: $key (size: $estimatedSize bytes, '
      'total: $_currentSizeBytes/$maxSizeBytes bytes)',
    );
  }

  /// Removes an entry from the cache
  void remove(String key) {
    final _CacheEntry? entry = _cache.remove(key);

    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      _logger.fine('Removed from cache: $key');
    }
  }

  /// Clears all entries from the cache
  void clear() {
    _logger.info('Clearing cache (${_cache.length} entries)');

    _cache.clear();
    _currentSizeBytes = 0;
    _hitCount = 0;
    _missCount = 0;
    _evictionCount = 0;
  }

  /// Invalidates cache entries matching a pattern
  ///
  /// Useful for invalidating related queries when data changes.
  /// Example: invalidatePattern('transactions_') clears all transaction queries
  void invalidatePattern(String pattern) {
    _logger.fine('Invalidating cache pattern: $pattern');

    final List<String> keysToRemove =
        _cache.keys.where((String key) => key.contains(pattern)).toList();

    for (final String key in keysToRemove) {
      remove(key);
    }

    _logger.info('Invalidated ${keysToRemove.length} cache entries');
  }

  /// Gets cache statistics
  CacheStatistics getStatistics() {
    final int totalRequests = _hitCount + _missCount;
    final double hitRate =
        totalRequests > 0 ? (_hitCount / totalRequests * 100) : 0.0;

    return CacheStatistics(
      entryCount: _cache.length,
      sizeBytes: _currentSizeBytes,
      maxSizeBytes: maxSizeBytes,
      hitCount: _hitCount,
      missCount: _missCount,
      evictionCount: _evictionCount,
      hitRate: hitRate,
    );
  }

  /// Removes expired entries from the cache
  void cleanupExpired() {
    _logger.fine('Cleaning up expired cache entries');

    final List<String> keysToRemove = <String>[];

    for (final MapEntry<String, _CacheEntry> entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final String key in keysToRemove) {
      remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      _logger.info('Removed ${keysToRemove.length} expired cache entries');
    }
  }

  // Private helper methods

  void _evictLRU() {
    if (_cache.isEmpty) return;

    // Remove first entry (least recently used)
    final String firstKey = _cache.keys.first;
    final _CacheEntry? entry = _cache.remove(firstKey);

    if (entry != null) {
      _currentSizeBytes -= entry.sizeBytes;
      _evictionCount++;
      _logger.fine('Evicted LRU entry: $firstKey');
    }
  }

  int _estimateSize(dynamic value) {
    // Simplified size estimation
    // Real implementation would need more sophisticated size calculation

    if (value == null) return 0;

    if (value is String) {
      return value.length * 2; // UTF-16 encoding
    }

    if (value is List) {
      return value.length * 100; // Rough estimate
    }

    if (value is Map) {
      return value.length * 200; // Rough estimate
    }

    // Default estimate
    return 1024; // 1KB
  }
}

/// Internal cache entry
class _CacheEntry {
  final dynamic value;
  final int sizeBytes;
  final DateTime createdAt;
  DateTime lastAccessTime;
  final Duration? ttl;

  _CacheEntry({
    required this.value,
    required this.sizeBytes,
    required this.createdAt,
    required this.lastAccessTime,
    this.ttl,
  });

  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }
}

/// Cache statistics
class CacheStatistics {
  final int entryCount;
  final int sizeBytes;
  final int maxSizeBytes;
  final int hitCount;
  final int missCount;
  final int evictionCount;
  final double hitRate;

  const CacheStatistics({
    required this.entryCount,
    required this.sizeBytes,
    required this.maxSizeBytes,
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
    required this.hitRate,
  });

  double get utilizationPercent => (sizeBytes / maxSizeBytes * 100);

  @override
  String toString() {
    return 'CacheStatistics('
        'entries: $entryCount, '
        'size: ${(sizeBytes / 1024 / 1024).toStringAsFixed(2)}MB / '
        '${(maxSizeBytes / 1024 / 1024).toStringAsFixed(2)}MB, '
        'hitRate: ${hitRate.toStringAsFixed(1)}%, '
        'hits: $hitCount, '
        'misses: $missCount, '
        'evictions: $evictionCount)';
  }
}
