import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/cache/cache_stats.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';

/// Cache Debug Page
///
/// **DEBUG MODE ONLY**
///
/// Comprehensive cache debugging and management interface for developers.
/// Provides detailed insights into cache performance, entries, and
/// manual cache management capabilities.
///
/// Features:
/// - Real-time cache statistics (hit rate, size, entries, etc.)
/// - Complete list of all cache entries with metadata
/// - Search and filter cache entries
/// - Manual cache invalidation (single entry or type-level)
/// - Manual LRU eviction trigger
/// - Nuclear cache clear option
/// - Cache size limit configuration
/// - Refresh statistics button
/// - Entry freshness indicators (fresh/stale/invalidated)
/// - Age and TTL display for each entry
///
/// Access:
/// This page should only be accessible in debug mode:
/// - Check kDebugMode before navigation
/// - Hide from release builds
/// - Add to settings page under "Developer Options"
///
/// Architecture:
/// - Stateful widget with periodic stats refresh
/// - Uses Provider to access CacheService and AppDatabase
/// - Real-time cache metadata queries from Drift database
/// - Comprehensive error handling and logging
///
/// Example Navigation:
/// ```dart
/// if (kDebugMode) {
///   Navigator.push(
///     context,
///     MaterialPageRoute(builder: (context) => const CacheDebugPage()),
///   );
/// }
/// ```
///
/// UI Structure:
/// - AppBar with refresh and clear all buttons
/// - Statistics card at top (hit rate, size, entries)
/// - Search bar for filtering entries
/// - Scrollable list of cache entries
/// - Each entry shows: type, ID, age, TTL, freshness, actions
/// - Bottom action bar with bulk operations
class CacheDebugPage extends StatefulWidget {
  const CacheDebugPage({super.key});

  @override
  State<CacheDebugPage> createState() => _CacheDebugPageState();
}

class _CacheDebugPageState extends State<CacheDebugPage> {
  final Logger _log = Logger('CacheDebugPage');

  /// Cache statistics (refreshed periodically)
  CacheStats? _stats;

  /// All cache metadata entries (from database)
  List<CacheMetadataEntity> _entries = <CacheMetadataEntity>[];

  /// Filtered cache entries (after search/filter applied)
  List<CacheMetadataEntity> _filteredEntries = <CacheMetadataEntity>[];

  /// Search query for filtering entries
  String _searchQuery = '';

  /// Selected entity type filter (null = all types)
  String? _selectedTypeFilter;

  /// Loading state for async operations
  bool _isLoading = true;

  /// Error message (if any)
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCacheData();
  }

  /// Load cache statistics and entries
  ///
  /// Fetches:
  /// - Cache statistics from CacheService
  /// - All cache metadata entries from database
  ///
  /// Updates UI state and handles errors comprehensively.
  Future<void> _loadCacheData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _log.fine('Loading cache debug data');

      final CacheService cacheService = context.read<CacheService>();
      final AppDatabase database = context.read<AppDatabase>();

      // Fetch statistics
      final CacheStats stats = await cacheService.getStats();

      // Fetch all cache entries from database
      final List<CacheMetadataEntity> entries = await database.select(database.cacheMetadataTable).get();

      // Sort by last accessed (most recent first)
      entries.sort((CacheMetadataEntity a, CacheMetadataEntity b) => b.lastAccessedAt.compareTo(a.lastAccessedAt));

      _log.info('Loaded cache data: ${entries.length} entries');

      if (!mounted) return;

      setState(() {
        _stats = stats;
        _entries = entries;
        _filteredEntries = entries;
        _isLoading = false;
      });

      // Apply current filters
      _applyFilters();
    } catch (e, stackTrace) {
      _log.severe('Failed to load cache data', e, stackTrace);

      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load cache data: $e';
        _isLoading = false;
      });
    }
  }

  /// Apply search and type filters to entries
  ///
  /// Filters entries based on:
  /// - Search query (matches entity type or ID)
  /// - Selected type filter (if any)
  ///
  /// Updates _filteredEntries with matching entries.
  void _applyFilters() {
    List<CacheMetadataEntity> filtered = _entries;

    // Apply type filter
    if (_selectedTypeFilter != null) {
      filtered = filtered
          .where((CacheMetadataEntity entry) => entry.entityType == _selectedTypeFilter)
          .toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final String query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((CacheMetadataEntity entry) =>
              entry.entityType.toLowerCase().contains(query) ||
              entry.entityId.toLowerCase().contains(query))
          .toList();
    }

    setState(() {
      _filteredEntries = filtered;
    });

    _log.fine(
      'Filters applied: ${_filteredEntries.length}/${_entries.length} entries shown',
    );
  }

  /// Clear all cache (nuclear option)
  ///
  /// Shows confirmation dialog before clearing.
  /// Clears all cache metadata and reloads UI.
  Future<void> _clearAllCache() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Clear All Cache?'),
        content: const Text(
          'This will clear all cache metadata. '
          'Entity data will remain but be treated as uncached.\n\n'
          'This action cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      _log.warning('Clearing all cache (user requested)');

      final CacheService cacheService = context.read<CacheService>();
      await cacheService.clearAll();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache cleared successfully')),
      );

      // Reload data
      await _loadCacheData();
    } catch (e, stackTrace) {
      _log.severe('Failed to clear cache', e, stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to clear cache: $e')),
      );
    }
  }

  /// Invalidate specific cache entry
  ///
  /// Parameters:
  /// - [entry]: Cache metadata entry to invalidate
  ///
  /// Invalidates the entry and reloads UI.
  Future<void> _invalidateEntry(CacheMetadataEntity entry) async {
    try {
      _log.info('Invalidating cache entry: ${entry.entityType}:${entry.entityId}');

      final CacheService cacheService = context.read<CacheService>();
      await cacheService.invalidate(entry.entityType, entry.entityId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalidated ${entry.entityType}:${entry.entityId}'),
        ),
      );

      // Reload data
      await _loadCacheData();
    } catch (e, stackTrace) {
      _log.severe('Failed to invalidate entry', e, stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invalidate: $e')),
      );
    }
  }

  /// Invalidate all entries of a specific type
  ///
  /// Parameters:
  /// - [entityType]: Entity type to invalidate (e.g., 'transaction')
  ///
  /// Shows confirmation dialog and invalidates all entries of type.
  Future<void> _invalidateType(String entityType) async {
    final int count =
        _entries.where((CacheMetadataEntity e) => e.entityType == entityType).length;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Invalidate All $entityType?'),
        content: Text(
          'This will invalidate $count cache entries of type "$entityType".\n\n'
          'Data will be refetched from API on next access.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Invalidate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      _log.info('Invalidating all cache entries of type: $entityType');

      final CacheService cacheService = context.read<CacheService>();
      await cacheService.invalidateType(entityType);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalidated $count entries of type $entityType')),
      );

      // Reload data
      await _loadCacheData();
    } catch (e, stackTrace) {
      _log.severe('Failed to invalidate type', e, stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invalidate type: $e')),
      );
    }
  }

  /// Trigger manual LRU eviction
  ///
  /// Shows dialog to enter target size and triggers eviction.
  Future<void> _triggerLruEviction() async {
    final CacheService cacheService = context.read<CacheService>();
    final int currentLimit = cacheService.maxCacheSizeMB;

    final int? targetSizeMB = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int targetSize = currentLimit ~/ 2;

        return AlertDialog(
          title: const Text('Manual LRU Eviction'),
          content: StatefulBuilder(
            builder: (BuildContext context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Current limit: ${currentLimit}MB'),
                Text('Current size: ${_stats?.totalCacheSizeMB ?? 0}MB'),
                const SizedBox(height: 16),
                const Text('Target size (MB):'),
                Slider(
                  value: targetSize.toDouble(),
                  min: 1,
                  max: currentLimit.toDouble(),
                  divisions: currentLimit,
                  label: '${targetSize}MB',
                  onChanged: (double value) {
                    setState(() {
                      targetSize = value.round();
                    });
                  },
                ),
                Text('Will evict down to ${targetSize}MB'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, targetSize),
              child: const Text('Evict'),
            ),
          ],
        );
      },
    );

    if (targetSizeMB == null || !mounted) return;

    try {
      _log.info('Triggering manual LRU eviction to ${targetSizeMB}MB');

      await cacheService.evictLru(targetSizeMB: targetSizeMB);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('LRU eviction complete (target: ${targetSizeMB}MB)')),
      );

      // Reload data
      await _loadCacheData();
    } catch (e, stackTrace) {
      _log.severe('Failed to trigger LRU eviction', e, stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to evict: $e')),
      );
    }
  }

  /// Configure cache size limit
  ///
  /// Shows dialog to enter new size limit and updates CacheService.
  Future<void> _configureSizeLimit() async {
    final CacheService cacheService = context.read<CacheService>();
    final int currentLimit = cacheService.maxCacheSizeMB;

    final int? newLimit = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        int limit = currentLimit;

        return AlertDialog(
          title: const Text('Configure Cache Size Limit'),
          content: StatefulBuilder(
            builder: (BuildContext context, setState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Current limit: ${currentLimit}MB'),
                Text('Current size: ${_stats?.totalCacheSizeMB ?? 0}MB'),
                const SizedBox(height: 16),
                const Text('New limit (MB):'),
                Slider(
                  value: limit.toDouble(),
                  min: 10,
                  max: 500,
                  divisions: 49,
                  label: '${limit}MB',
                  onChanged: (double value) {
                    setState(() {
                      limit = value.round();
                    });
                  },
                ),
                Text('New limit: ${limit}MB'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, limit),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newLimit == null || !mounted) return;

    try {
      _log.info('Setting cache size limit to ${newLimit}MB');

      await cacheService.setMaxCacheSizeMB(newLimit);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cache size limit set to ${newLimit}MB')),
      );

      // Reload data
      await _loadCacheData();
    } catch (e, stackTrace) {
      _log.severe('Failed to set cache size limit', e, stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to set limit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cache Debug'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _clearAllCache,
            tooltip: 'Clear All Cache',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadCacheData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: <Widget>[
                    // Statistics Card
                    _buildStatisticsCard(),

                    // Search and Filter Bar
                    _buildSearchBar(),

                    // Entry List
                    Expanded(
                      child: _filteredEntries.isEmpty
                          ? Center(
                              child: Text(
                                _searchQuery.isNotEmpty ||
                                        _selectedTypeFilter != null
                                    ? 'No entries match filters'
                                    : 'Cache is empty',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredEntries.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _buildEntryCard(_filteredEntries[index]);
                              },
                            ),
                    ),

                    // Bottom Action Bar
                    _buildBottomActionBar(),
                  ],
                ),
    );
  }

  /// Build statistics card
  ///
  /// Shows:
  /// - Total entries, invalidated entries
  /// - Cache hit rate percentage
  /// - Total cache size and limit
  /// - Cache hits, misses, stale served
  /// - Background refreshes
  Widget _buildStatisticsCard() {
    if (_stats == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Cache Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Hit Rate', '${_stats!.hitRatePercent.toStringAsFixed(1)}%'),
            _buildStatRow('Total Entries', '${_stats!.totalEntries}'),
            _buildStatRow('Invalidated', '${_stats!.invalidatedEntries}'),
            _buildStatRow(
              'Cache Size',
              '${_stats!.totalCacheSizeMB}MB / ${context.read<CacheService>().maxCacheSizeMB}MB',
            ),
            const Divider(),
            _buildStatRow('Cache Hits', '${_stats!.cacheHits}'),
            _buildStatRow('Cache Misses', '${_stats!.cacheMisses}'),
            _buildStatRow('Stale Served', '${_stats!.staleServed}'),
            _buildStatRow('Background Refreshes', '${_stats!.backgroundRefreshes}'),
            _buildStatRow('Evictions', '${_stats!.evictions}'),
            if (_stats!.etagRequests > 0) ...<Widget>[
              const Divider(),
              const Text(
                'ETag Statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildStatRow('ETag Requests', '${_stats!.etagRequests}'),
              _buildStatRow(
                'ETag Hits (304)',
                '${_stats!.etagHits} (${_stats!.etagHitRatePercent.toStringAsFixed(1)}%)',
              ),
              _buildStatRow(
                'Bandwidth Saved',
                '${_stats!.etagBandwidthSavedMB.toStringAsFixed(2)} MB',
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build stat row
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Build search and filter bar
  Widget _buildSearchBar() {
    // Get unique entity types for filter
    final List<String> entityTypes = _entries.map((CacheMetadataEntity e) => e.entityType).toSet().toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: <Widget>[
          // Search field
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Filter by type or ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (String value) {
                setState(() {
                  _searchQuery = value;
                });
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 8),
          // Type filter dropdown
          DropdownButton<String?>(
            value: _selectedTypeFilter,
            hint: const Text('All Types'),
            items: <DropdownMenuItem<String?>>[
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Types'),
              ),
              ...entityTypes.map((String type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  )),
            ],
            onChanged: (String? value) {
              setState(() {
                _selectedTypeFilter = value;
              });
              _applyFilters();
            },
          ),
        ],
      ),
    );
  }

  /// Build cache entry card
  ///
  /// Shows:
  /// - Entity type and ID
  /// - Freshness indicator (fresh/stale/invalidated)
  /// - Age and TTL
  /// - Last accessed timestamp
  /// - ETag (if present)
  /// - Actions: Invalidate button
  Widget _buildEntryCard(CacheMetadataEntity entry) {
    final DateTime now = DateTime.now();
    final Duration age = now.difference(entry.cachedAt);
    final DateTime expiresAt = entry.cachedAt.add(Duration(seconds: entry.ttlSeconds));
    final bool isFresh = now.isBefore(expiresAt) && !entry.isInvalidated;

    Color freshnessColor;
    String freshnessLabel;
    IconData freshnessIcon;

    if (entry.isInvalidated) {
      freshnessColor = Colors.grey;
      freshnessLabel = 'INVALIDATED';
      freshnessIcon = Icons.block;
    } else if (isFresh) {
      freshnessColor = Colors.green;
      freshnessLabel = 'FRESH';
      freshnessIcon = Icons.check_circle;
    } else {
      freshnessColor = Colors.orange;
      freshnessLabel = 'STALE';
      freshnessIcon = Icons.warning;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ExpansionTile(
        leading: Icon(freshnessIcon, color: freshnessColor),
        title: Text(
          '${entry.entityType}:${entry.entityId}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          freshnessLabel,
          style: TextStyle(color: freshnessColor, fontWeight: FontWeight.bold),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildInfoRow('Cached At', _formatDateTime(entry.cachedAt)),
                _buildInfoRow('Age', _formatDuration(age)),
                _buildInfoRow('TTL', '${entry.ttlSeconds}s'),
                _buildInfoRow('Expires At', _formatDateTime(expiresAt)),
                _buildInfoRow('Last Accessed', _formatDateTime(entry.lastAccessedAt)),
                if (entry.etag != null) _buildInfoRow('ETag', entry.etag!),
                if (entry.queryHash != null)
                  _buildInfoRow('Query Hash', entry.queryHash!),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    TextButton.icon(
                      onPressed: () => _invalidateEntry(entry),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Invalidate'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build info row for entry details
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  /// Build bottom action bar
  ///
  /// Contains bulk operation buttons:
  /// - Trigger LRU eviction
  /// - Configure size limit
  /// - Invalidate type
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton.icon(
            onPressed: _triggerLruEviction,
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Evict LRU'),
          ),
          ElevatedButton.icon(
            onPressed: _configureSizeLimit,
            icon: const Icon(Icons.settings),
            label: const Text('Size Limit'),
          ),
          if (_selectedTypeFilter != null)
            ElevatedButton.icon(
              onPressed: () => _invalidateType(_selectedTypeFilter!),
              icon: const Icon(Icons.delete_sweep),
              label: Text('Invalidate $_selectedTypeFilter'),
            ),
        ],
      ),
    );
  }

  /// Format DateTime for display
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  /// Format Duration for display
  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}
