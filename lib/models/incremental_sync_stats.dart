/// Statistics collected during incremental sync for a single entity type.
///
/// Tracks the number of items fetched, updated, and skipped during
/// incremental synchronization. Used for:
/// - Progress reporting during sync
/// - Calculating sync efficiency (skip rate)
/// - Storing historical statistics in `sync_statistics` table
/// - Displaying bandwidth/API savings to users
///
/// Example:
/// ```dart
/// final stats = IncrementalSyncStats(entityType: 'transaction');
///
/// for (final item in serverItems) {
///   stats.itemsFetched++;
///   if (await hasEntityChanged(item)) {
///     await updateEntity(item);
///     stats.itemsUpdated++;
///   } else {
///     stats.itemsSkipped++;
///   }
/// }
///
/// print(stats.summary); // "12 updated, 33 skipped"
/// print('${stats.skipRate.toStringAsFixed(1)}% skip rate'); // "73.3% skip rate"
/// ```
class IncrementalSyncStats {
  /// Entity type being synced (e.g., 'transaction', 'account').
  final String entityType;

  /// Total number of items fetched from the server.
  int itemsFetched;

  /// Number of items that had changes and were updated locally.
  int itemsUpdated;

  /// Number of items that were unchanged and skipped.
  int itemsSkipped;

  /// Estimated bandwidth saved in bytes.
  ///
  /// Calculated as: skippedItems * averageEntitySize
  /// where averageEntitySize is estimated based on entity type.
  int bandwidthSavedBytes;

  /// Number of API calls saved (for cached entities).
  int apiCallsSaved;

  /// Start time of the sync operation.
  final DateTime startTime;

  /// End time of the sync operation (set when complete).
  DateTime? endTime;

  /// Whether the sync completed successfully.
  bool? success;

  /// Error message if sync failed.
  String? error;

  /// Creates new sync statistics for an entity type.
  IncrementalSyncStats({
    required this.entityType,
    this.itemsFetched = 0,
    this.itemsUpdated = 0,
    this.itemsSkipped = 0,
    this.bandwidthSavedBytes = 0,
    this.apiCallsSaved = 0,
    DateTime? startTime,
  }) : startTime = startTime ?? DateTime.now();

  /// Human-readable summary of sync results.
  ///
  /// Example: "12 updated, 33 skipped"
  String get summary => '$itemsUpdated updated, $itemsSkipped skipped';

  /// Percentage of items that were skipped (0.0 to 100.0).
  ///
  /// High skip rate indicates effective incremental sync.
  double get skipRate =>
      itemsFetched > 0 ? (itemsSkipped / itemsFetched) * 100.0 : 0.0;

  /// Percentage of items that required updates (0.0 to 100.0).
  double get updateRate =>
      itemsFetched > 0 ? (itemsUpdated / itemsFetched) * 100.0 : 0.0;

  /// Duration of the sync operation.
  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Average time per item in milliseconds.
  double get averageTimePerItemMs {
    if (itemsFetched == 0) return 0.0;
    return duration.inMilliseconds / itemsFetched;
  }

  /// Mark the sync as complete.
  void complete({bool success = true, String? error}) {
    endTime = DateTime.now();
    this.success = success;
    this.error = error;
  }

  /// Estimate bandwidth saved based on entity type.
  ///
  /// Average entity sizes (estimated):
  /// - Transaction: 2KB
  /// - Account: 1KB
  /// - Budget: 0.5KB
  /// - Category: 0.3KB
  /// - Bill: 0.5KB
  /// - Piggy Bank: 0.5KB
  void calculateBandwidthSaved() {
    final int avgSize = _getAverageEntitySize(entityType);
    bandwidthSavedBytes = itemsSkipped * avgSize;
  }

  /// Get estimated average size in bytes for an entity type.
  int _getAverageEntitySize(String entityType) {
    switch (entityType) {
      case 'transaction':
        return 2048; // 2KB
      case 'account':
        return 1024; // 1KB
      case 'budget':
        return 512; // 0.5KB
      case 'category':
        return 307; // 0.3KB
      case 'bill':
        return 512; // 0.5KB
      case 'piggy_bank':
        return 512; // 0.5KB
      default:
        return 512; // Default 0.5KB
    }
  }

  /// Format bandwidth as human-readable string.
  String get bandwidthSavedFormatted {
    if (bandwidthSavedBytes < 1024) {
      return '$bandwidthSavedBytes B';
    } else if (bandwidthSavedBytes < 1024 * 1024) {
      return '${(bandwidthSavedBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bandwidthSavedBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Create a copy with updated values.
  IncrementalSyncStats copyWith({
    String? entityType,
    int? itemsFetched,
    int? itemsUpdated,
    int? itemsSkipped,
    int? bandwidthSavedBytes,
    int? apiCallsSaved,
    DateTime? startTime,
    DateTime? endTime,
    bool? success,
    String? error,
  }) {
    return IncrementalSyncStats(
      entityType: entityType ?? this.entityType,
      itemsFetched: itemsFetched ?? this.itemsFetched,
      itemsUpdated: itemsUpdated ?? this.itemsUpdated,
      itemsSkipped: itemsSkipped ?? this.itemsSkipped,
      bandwidthSavedBytes: bandwidthSavedBytes ?? this.bandwidthSavedBytes,
      apiCallsSaved: apiCallsSaved ?? this.apiCallsSaved,
      startTime: startTime ?? this.startTime,
    )
      ..endTime = endTime ?? this.endTime
      ..success = success ?? this.success
      ..error = error ?? this.error;
  }

  /// Convert to JSON for storage/logging.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'entityType': entityType,
        'itemsFetched': itemsFetched,
        'itemsUpdated': itemsUpdated,
        'itemsSkipped': itemsSkipped,
        'bandwidthSavedBytes': bandwidthSavedBytes,
        'apiCallsSaved': apiCallsSaved,
        'skipRate': skipRate,
        'updateRate': updateRate,
        'durationMs': duration.inMilliseconds,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'success': success,
        'error': error,
      };

  @override
  String toString() => 'IncrementalSyncStats('
      'entityType: $entityType, '
      '$summary, '
      'skipRate: ${skipRate.toStringAsFixed(1)}%, '
      'duration: ${duration.inMilliseconds}ms'
      ')';
}

/// Aggregate statistics for a complete incremental sync operation.
///
/// Combines statistics from all entity types synced during
/// a single incremental sync run.
class IncrementalSyncResult {
  /// Whether the sync was incremental (vs full).
  final bool isIncremental;

  /// Whether the sync completed successfully.
  final bool success;

  /// Total duration of the sync.
  final Duration duration;

  /// Statistics per entity type.
  final Map<String, IncrementalSyncStats> statsByEntity;

  /// Error message if sync failed.
  final String? error;

  /// Creates aggregate sync result.
  const IncrementalSyncResult({
    required this.isIncremental,
    required this.success,
    required this.duration,
    required this.statsByEntity,
    this.error,
  });

  /// Total items fetched across all entities.
  int get totalFetched =>
      statsByEntity.values.fold(0, (sum, s) => sum + s.itemsFetched);

  /// Total items updated across all entities.
  int get totalUpdated =>
      statsByEntity.values.fold(0, (sum, s) => sum + s.itemsUpdated);

  /// Total items skipped across all entities.
  int get totalSkipped =>
      statsByEntity.values.fold(0, (sum, s) => sum + s.itemsSkipped);

  /// Total bandwidth saved across all entities.
  int get totalBandwidthSaved =>
      statsByEntity.values.fold(0, (sum, s) => sum + s.bandwidthSavedBytes);

  /// Overall skip rate across all entities.
  double get overallSkipRate =>
      totalFetched > 0 ? (totalSkipped / totalFetched) * 100.0 : 0.0;

  /// Format total bandwidth saved as human-readable string.
  String get bandwidthSavedFormatted {
    if (totalBandwidthSaved < 1024) {
      return '$totalBandwidthSaved B';
    } else if (totalBandwidthSaved < 1024 * 1024) {
      return '${(totalBandwidthSaved / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(totalBandwidthSaved / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Convert to JSON for storage/logging.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'isIncremental': isIncremental,
        'success': success,
        'durationMs': duration.inMilliseconds,
        'totalFetched': totalFetched,
        'totalUpdated': totalUpdated,
        'totalSkipped': totalSkipped,
        'totalBandwidthSaved': totalBandwidthSaved,
        'overallSkipRate': overallSkipRate,
        'error': error,
        'statsByEntity':
            statsByEntity.map((k, v) => MapEntry(k, v.toJson())),
      };

  @override
  String toString() => 'IncrementalSyncResult('
      'success: $success, '
      'incremental: $isIncremental, '
      'fetched: $totalFetched, '
      'updated: $totalUpdated, '
      'skipped: $totalSkipped, '
      'skipRate: ${overallSkipRate.toStringAsFixed(1)}%, '
      'bandwidth saved: $bandwidthSavedFormatted, '
      'duration: ${duration.inMilliseconds}ms'
      ')';
}

