import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';

/// Statistics about synchronization operations.
class SyncStatistics {
  /// Total number of syncs performed
  final int totalSyncs;

  /// Number of successful syncs
  final int successfulSyncs;

  /// Number of failed syncs
  final int failedSyncs;

  /// Success rate (0.0 to 1.0)
  final double successRate;

  /// Average sync duration
  final Duration averageDuration;

  /// Total operations synced
  final int totalOperations;

  /// Total conflicts detected
  final int conflictsDetected;

  /// Total conflicts resolved
  final int conflictsResolved;

  /// Last sync time
  final DateTime? lastSyncTime;

  /// Last full sync time
  final DateTime? lastFullSyncTime;

  /// Next scheduled sync time
  final DateTime? nextScheduledSync;

  /// Total data transferred (bytes)
  final int totalDataTransferred;

  /// Average throughput (operations per second)
  final double averageThroughput;

  const SyncStatistics({
    required this.totalSyncs,
    required this.successfulSyncs,
    required this.failedSyncs,
    required this.successRate,
    required this.averageDuration,
    required this.totalOperations,
    required this.conflictsDetected,
    required this.conflictsResolved,
    this.lastSyncTime,
    this.lastFullSyncTime,
    this.nextScheduledSync,
    required this.totalDataTransferred,
    required this.averageThroughput,
  });

  @override
  String toString() {
    return 'SyncStatistics('
        'total: $totalSyncs, '
        'success: $successfulSyncs, '
        'failed: $failedSyncs, '
        'rate: ${(successRate * 100).toStringAsFixed(1)}%, '
        'avg_duration: ${averageDuration.inSeconds}s, '
        'operations: $totalOperations, '
        'conflicts: $conflictsDetected/$conflictsResolved'
        ')';
  }
}

/// Service for tracking and managing sync statistics.
class SyncStatisticsService {
  final Logger _logger = Logger('SyncStatisticsService');
  final AppDatabase _database;

  SyncStatisticsService(this._database);

  // In-memory cache
  int _totalSyncs = 0;
  int _successfulSyncs = 0;
  int _failedSyncs = 0;
  final List<Duration> _syncDurations = <Duration>[];
  int _totalOperations = 0;
  int _conflictsDetected = 0;
  int _conflictsResolved = 0;
  DateTime? _lastSyncTime;
  DateTime? _lastFullSyncTime;
  DateTime? _nextScheduledSync;
  int _totalDataTransferred = 0;
  final List<double> _throughputSamples = <double>[];

  static const int _maxSamples = 100;

  /// Get current statistics.
  Future<SyncStatistics> getStatistics() async {
    return SyncStatistics(
      totalSyncs: _totalSyncs,
      successfulSyncs: _successfulSyncs,
      failedSyncs: _failedSyncs,
      successRate: _calculateSuccessRate(),
      averageDuration: _calculateAverageDuration(),
      totalOperations: _totalOperations,
      conflictsDetected: _conflictsDetected,
      conflictsResolved: _conflictsResolved,
      lastSyncTime: _lastSyncTime,
      lastFullSyncTime: _lastFullSyncTime,
      nextScheduledSync: _nextScheduledSync,
      totalDataTransferred: _totalDataTransferred,
      averageThroughput: _calculateAverageThroughput(),
    );
  }

  /// Record a completed sync.
  Future<void> recordSync({
    required bool success,
    required Duration duration,
    required int operationsProcessed,
    required int conflictsDetected,
    required int conflictsResolved,
    required int dataTransferred,
    required double throughput,
  }) async {
    _totalSyncs++;
    
    if (success) {
      _successfulSyncs++;
    } else {
      _failedSyncs++;
    }

    _syncDurations.add(duration);
    if (_syncDurations.length > _maxSamples) {
      _syncDurations.removeAt(0);
    }

    _totalOperations += operationsProcessed;
    _conflictsDetected += conflictsDetected;
    _conflictsResolved += conflictsResolved;
    _lastSyncTime = DateTime.now();
    _totalDataTransferred += dataTransferred;

    _throughputSamples.add(throughput);
    if (_throughputSamples.length > _maxSamples) {
      _throughputSamples.removeAt(0);
    }

    _logger.info(
      'Recorded sync: success=$success, duration=${duration.inSeconds}s, '
      'operations=$operationsProcessed, conflicts=$conflictsDetected',
    );

    await _persistStatistics();
  }

  /// Record a full sync.
  Future<void> recordFullSync() async {
    _lastFullSyncTime = DateTime.now();
    _logger.info('Recorded full sync at $_lastFullSyncTime');
    await _persistStatistics();
  }

  /// Set next scheduled sync time.
  Future<void> setNextScheduledSync(DateTime time) async {
    _nextScheduledSync = time;
    _logger.fine('Next scheduled sync: $time');
    await _persistStatistics();
  }

  /// Reset all statistics.
  Future<void> resetStatistics() async {
    _logger.warning('Resetting all sync statistics');
    
    _totalSyncs = 0;
    _successfulSyncs = 0;
    _failedSyncs = 0;
    _syncDurations.clear();
    _totalOperations = 0;
    _conflictsDetected = 0;
    _conflictsResolved = 0;
    _lastSyncTime = null;
    _lastFullSyncTime = null;
    _nextScheduledSync = null;
    _totalDataTransferred = 0;
    _throughputSamples.clear();

    await _clearFromDatabase();
  }

  /// Calculate success rate.
  double _calculateSuccessRate() {
    if (_totalSyncs == 0) return 0.0;
    return _successfulSyncs / _totalSyncs;
  }

  /// Calculate average sync duration.
  Duration _calculateAverageDuration() {
    if (_syncDurations.isEmpty) return Duration.zero;
    
    final int totalMs = _syncDurations.fold<int>(
      0,
      (int sum, Duration duration) => sum + duration.inMilliseconds,
    );
    
    return Duration(milliseconds: totalMs ~/ _syncDurations.length);
  }

  /// Calculate average throughput.
  double _calculateAverageThroughput() {
    if (_throughputSamples.isEmpty) return 0.0;
    
    final double sum = _throughputSamples.fold<double>(0.0, (double a, double b) => a + b);
    return sum / _throughputSamples.length;
  }

  /// Persist statistics to database using syncMetadata table.
  Future<void> _persistStatistics() async {
    try {
      final DateTime now = DateTime.now();
      await _database.into(_database.syncMetadata).insertOnConflictUpdate(
        SyncMetadataEntityCompanion.insert(
          key: 'stats_total_syncs',
          value: _totalSyncs.toString(),
          updatedAt: now,
        ),
      );
      await _database.into(_database.syncMetadata).insertOnConflictUpdate(
        SyncMetadataEntityCompanion.insert(
          key: 'stats_successful_syncs',
          value: _successfulSyncs.toString(),
          updatedAt: now,
        ),
      );
      await _database.into(_database.syncMetadata).insertOnConflictUpdate(
        SyncMetadataEntityCompanion.insert(
          key: 'stats_failed_syncs',
          value: _failedSyncs.toString(),
          updatedAt: now,
        ),
      );
      if (_lastSyncTime != null) {
        await _database.into(_database.syncMetadata).insertOnConflictUpdate(
          SyncMetadataEntityCompanion.insert(
            key: 'stats_last_sync_time',
            value: _lastSyncTime!.toIso8601String(),
            updatedAt: now,
          ),
        );
      }
      if (_lastFullSyncTime != null) {
        await _database.into(_database.syncMetadata).insertOnConflictUpdate(
          SyncMetadataEntityCompanion.insert(
            key: 'stats_last_full_sync_time',
            value: _lastFullSyncTime!.toIso8601String(),
            updatedAt: now,
          ),
        );
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to persist statistics', e, stackTrace);
    }
  }

  /// Clear statistics from database.
  Future<void> _clearFromDatabase() async {
    try {
      // Delete stats-related keys from syncMetadata
      final List<String> keysToDelete = <String>[
        'stats_total_syncs',
        'stats_successful_syncs',
        'stats_failed_syncs',
        'stats_last_sync_time',
        'stats_last_full_sync_time',
      ];
      for (final String key in keysToDelete) {
        await (_database.delete(_database.syncMetadata)
              ..where(($SyncMetadataTable t) => t.key.equals(key)))
            .go();
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to clear statistics', e, stackTrace);
    }
  }
}
