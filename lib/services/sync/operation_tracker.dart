import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/services/sync/metadata_service.dart';

/// Tracks the lifecycle and statistics of synchronization operations.
///
/// This service maintains a history of operation state changes and
/// provides analytics on sync performance, success rates, and timing.
///
/// Uses both the metadata service for history storage and direct database
/// access for efficient querying of sync queue statistics.
///
/// Example:
/// ```dart
/// final tracker = OperationTracker(database, metadata);
///
/// // Track operation lifecycle
/// await tracker.trackOperation('op_123', 'created');
/// await tracker.trackOperation('op_123', 'queued');
/// await tracker.trackOperation('op_123', 'processing');
/// await tracker.trackOperation('op_123', 'completed');
///
/// // Get statistics
/// final stats = await tracker.getOperationStatistics();
/// print('Success rate: ${stats.successRate}%');
/// ```
class OperationTracker {
  final AppDatabase _database;
  final MetadataService _metadata;
  final Logger _logger = Logger('OperationTracker');

  OperationTracker(this._database, {MetadataService? metadata})
    : _metadata = metadata ?? MetadataService(_database);

  /// Tracks an operation status change
  ///
  /// Records the operation ID, new status, and timestamp in the metadata table.
  /// Maintains a history of all status changes for each operation.
  ///
  /// Also updates the sync queue status in the database for operations
  /// that correspond to sync queue entries.
  ///
  /// Throws [SyncException] if tracking fails
  Future<void> trackOperation(String operationId, String status) async {
    _logger.fine('Tracking operation: $operationId -> $status');

    try {
      final DateTime timestamp = DateTime.now();
      final String historyKey = MetadataKeys.operationHistory(operationId);

      // Get existing history
      final String? existingHistory = await _metadata.get(historyKey);
      final List<Map<String, dynamic>> history =
          existingHistory != null
              ? List<Map<String, dynamic>>.from(
                jsonDecode(existingHistory) as List,
              )
              : <Map<String, dynamic>>[];

      // Add new entry
      history.add(<String, dynamic>{
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      });

      // Store updated history in metadata
      await _metadata.set(historyKey, jsonEncode(history));

      // Also update the sync queue status if this operation exists there
      await _updateSyncQueueStatus(operationId, status, timestamp);

      _logger.fine('Operation tracked: $operationId -> $status');
    } catch (e, stackTrace) {
      _logger.severe('Failed to track operation: $operationId', e, stackTrace);
      throw SyncException('Failed to track operation', <String, dynamic>{
        "error": e.toString(),
      });
    }
  }

  /// Updates the sync queue status for an operation.
  Future<void> _updateSyncQueueStatus(
    String operationId,
    String status,
    DateTime timestamp,
  ) async {
    try {
      // Map tracker status to sync queue status
      final String? queueStatus = _mapToQueueStatus(status);
      if (queueStatus == null) return;

      // Update sync queue entry if exists
      await (_database.update(_database.syncQueue)
        ..where(($SyncQueueTable t) => t.id.equals(operationId))).write(
        SyncQueueEntityCompanion(
          status: Value(queueStatus),
          lastAttemptAt: Value(timestamp),
        ),
      );

      _logger.fine('Updated sync queue status for $operationId: $queueStatus');
    } catch (e) {
      // Non-critical - operation may not be in sync queue
      _logger.fine('Could not update sync queue for $operationId: $e');
    }
  }

  /// Maps tracker status to sync queue status.
  String? _mapToQueueStatus(String trackerStatus) {
    switch (trackerStatus) {
      case 'created':
      case 'queued':
        return 'pending';
      case 'processing':
        return 'processing';
      case 'completed':
        return 'completed';
      case 'failed':
        return 'failed';
      default:
        return null;
    }
  }

  /// Gets the complete history of an operation
  ///
  /// Returns a list of status changes with timestamps, ordered chronologically.
  /// Returns empty list if no history found.
  Future<List<OperationHistoryEntry>> getOperationHistory(
    String operationId,
  ) async {
    _logger.fine('Fetching operation history: $operationId');

    try {
      final String historyKey = MetadataKeys.operationHistory(operationId);
      final String? historyJson = await _metadata.get(historyKey);

      if (historyJson == null) {
        return <OperationHistoryEntry>[];
      }

      final List<Map<String, dynamic>> history =
          List<Map<String, dynamic>>.from(jsonDecode(historyJson) as List);

      return history
          .map(
            (Map<String, dynamic> entry) => OperationHistoryEntry(
              status: entry['status'] as String,
              timestamp: DateTime.parse(entry['timestamp'] as String),
            ),
          )
          .toList();
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to fetch operation history: $operationId',
        e,
        stackTrace,
      );
      throw SyncException(
        'Failed to fetch operation history',
        <String, dynamic>{"error": e.toString()},
      );
    }
  }

  /// Gets comprehensive statistics about sync operations
  ///
  /// Calculates statistics from both:
  /// 1. Operation history stored in metadata (for detailed timing)
  /// 2. Sync queue table (for current state counts)
  ///
  /// Returns [OperationStatistics] with all metrics
  Future<OperationStatistics> getOperationStatistics() async {
    _logger.fine('Calculating operation statistics');

    try {
      // Get counts directly from sync queue for current state
      final SyncQueueStatistics queueStats = await _getSyncQueueStatistics();

      // Get all operation histories for timing analysis
      final Map<String, String> allMetadata = await _metadata.getAll(
        prefix: MetadataKeys.operationHistoryPrefix,
      );
      final List<MapEntry<String, String>> historyEntries =
          allMetadata.entries.toList();

      // Calculate timing statistics from history
      int totalFromHistory = 0;
      int successfulFromHistory = 0;
      int failedFromHistory = 0;
      int retriedOperations = 0;
      final List<Duration> processingTimes = <Duration>[];

      for (final MapEntry<String, String> entry in historyEntries) {
        final List<Map<String, dynamic>> history =
            List<Map<String, dynamic>>.from(jsonDecode(entry.value) as List);

        if (history.isEmpty) continue;

        totalFromHistory++;

        // Check final status
        final String lastStatus = history.last['status'] as String;
        if (lastStatus == 'completed') {
          successfulFromHistory++;
        } else if (lastStatus == 'failed') {
          failedFromHistory++;
        }

        // Check for retries
        final int processingCount =
            history
                .where((Map<String, dynamic> h) => h['status'] == 'processing')
                .length;
        if (processingCount > 1) {
          retriedOperations++;
        }

        // Calculate processing time
        final Map<String, dynamic> createdEntry = history.firstWhere(
          (Map<String, dynamic> h) =>
              h['status'] == 'created' || h['status'] == 'queued',
          orElse: () => history.first,
        );
        final Map<String, dynamic> completedEntry = history.lastWhere(
          (Map<String, dynamic> h) =>
              h['status'] == 'completed' || h['status'] == 'failed',
          orElse: () => history.last,
        );

        final DateTime startTime = DateTime.parse(
          createdEntry['timestamp'] as String,
        );
        final DateTime endTime = DateTime.parse(
          completedEntry['timestamp'] as String,
        );
        processingTimes.add(endTime.difference(startTime));
      }

      // Use queue stats if available, otherwise use history stats
      final int totalOperations =
          queueStats.total > 0 ? queueStats.total : totalFromHistory;
      final int successfulOperations =
          queueStats.completed > 0
              ? queueStats.completed
              : successfulFromHistory;
      final int failedOperations =
          queueStats.failed > 0 ? queueStats.failed : failedFromHistory;

      // Calculate rates
      final double successRate =
          totalOperations > 0
              ? (successfulOperations / totalOperations * 100)
              : 0.0;

      final double failureRate =
          totalOperations > 0
              ? (failedOperations / totalOperations * 100)
              : 0.0;

      final double retryRate =
          totalFromHistory > 0
              ? (retriedOperations / totalFromHistory * 100)
              : 0.0;

      final Duration avgProcessingTime =
          processingTimes.isNotEmpty
              ? processingTimes.reduce((Duration a, Duration b) => a + b) ~/
                  processingTimes.length
              : Duration.zero;

      final OperationStatistics stats = OperationStatistics(
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        retriedOperations: retriedOperations,
        pendingOperations: queueStats.pending,
        processingOperations: queueStats.processing,
        successRate: successRate,
        failureRate: failureRate,
        retryRate: retryRate,
        averageProcessingTime: avgProcessingTime,
      );

      _logger.info('Operation statistics calculated: $stats');
      return stats;
    } catch (e, stackTrace) {
      _logger.severe('Failed to calculate operation statistics', e, stackTrace);
      throw SyncException(
        'Failed to calculate operation statistics',
        <String, dynamic>{"error": e.toString()},
      );
    }
  }

  /// Gets statistics directly from the sync queue table.
  Future<SyncQueueStatistics> _getSyncQueueStatistics() async {
    try {
      // Count by status
      final Expression<int> countAll = _database.syncQueue.id.count();

      // Get total count
      final int total =
          await (_database.selectOnly(_database.syncQueue)..addColumns(
            <Expression<Object>>[countAll],
          )).map((TypedResult row) => row.read(countAll) ?? 0).getSingle();

      // Get pending count
      final int pending =
          await (_database.selectOnly(_database.syncQueue)
                ..addColumns(<Expression<Object>>[countAll])
                ..where(_database.syncQueue.status.equals('pending')))
              .map((TypedResult row) => row.read(countAll) ?? 0)
              .getSingle();

      // Get processing count
      final int processing =
          await (_database.selectOnly(_database.syncQueue)
                ..addColumns(<Expression<Object>>[countAll])
                ..where(_database.syncQueue.status.equals('processing')))
              .map((TypedResult row) => row.read(countAll) ?? 0)
              .getSingle();

      // Get completed count
      final int completed =
          await (_database.selectOnly(_database.syncQueue)
                ..addColumns(<Expression<Object>>[countAll])
                ..where(_database.syncQueue.status.equals('completed')))
              .map((TypedResult row) => row.read(countAll) ?? 0)
              .getSingle();

      // Get failed count
      final int failed =
          await (_database.selectOnly(_database.syncQueue)
                ..addColumns(<Expression<Object>>[countAll])
                ..where(_database.syncQueue.status.equals('failed')))
              .map((TypedResult row) => row.read(countAll) ?? 0)
              .getSingle();

      return SyncQueueStatistics(
        total: total,
        pending: pending,
        processing: processing,
        completed: completed,
        failed: failed,
      );
    } catch (e, stackTrace) {
      _logger.warning('Failed to get sync queue statistics', e, stackTrace);
      return SyncQueueStatistics.empty();
    }
  }

  /// Gets pending operations from the sync queue.
  ///
  /// Returns a list of operation IDs that are pending sync.
  Future<List<String>> getPendingOperations() async {
    try {
      final List<SyncQueueEntity> entries =
          await (_database.select(_database.syncQueue)
                ..where(($SyncQueueTable t) => t.status.equals('pending'))
                ..orderBy(<OrderClauseGenerator<$SyncQueueTable>>[
                  ($SyncQueueTable t) => OrderingTerm(
                    expression: t.priority,
                    mode: OrderingMode.asc,
                  ),
                  ($SyncQueueTable t) => OrderingTerm(
                    expression: t.createdAt,
                    mode: OrderingMode.asc,
                  ),
                ]))
              .get();

      return entries.map((SyncQueueEntity e) => e.id).toList();
    } catch (e, stackTrace) {
      _logger.severe('Failed to get pending operations', e, stackTrace);
      return <String>[];
    }
  }

  /// Gets failed operations from the sync queue.
  ///
  /// Returns a list of operation IDs that failed sync.
  Future<List<String>> getFailedOperations() async {
    try {
      final List<SyncQueueEntity> entries =
          await (_database.select(_database.syncQueue)
            ..where(($SyncQueueTable t) => t.status.equals('failed'))).get();

      return entries.map((SyncQueueEntity e) => e.id).toList();
    } catch (e, stackTrace) {
      _logger.severe('Failed to get failed operations', e, stackTrace);
      return <String>[];
    }
  }

  /// Requeues a failed operation for retry.
  Future<void> requeueOperation(String operationId) async {
    _logger.info('Requeuing operation: $operationId');

    try {
      await (_database.update(_database.syncQueue)
        ..where(($SyncQueueTable t) => t.id.equals(operationId))).write(
        SyncQueueEntityCompanion(
          status: const Value('pending'),
          attempts: const Value(0),
          lastAttemptAt: Value(DateTime.now()),
        ),
      );

      // Track the requeue
      await trackOperation(operationId, 'queued');

      _logger.info('Operation requeued: $operationId');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to requeue operation: $operationId',
        e,
        stackTrace,
      );
      throw SyncException('Failed to requeue operation', <String, dynamic>{
        "error": e.toString(),
      });
    }
  }

  /// Clears operation history older than specified days
  ///
  /// Removes history entries to prevent unbounded growth.
  /// Default retention is 30 days.
  Future<void> clearOldHistory({int retentionDays = 30}) async {
    _logger.info('Clearing operation history older than $retentionDays days');

    try {
      final DateTime cutoffDate = DateTime.now().subtract(
        Duration(days: retentionDays),
      );
      final Map<String, String> allMetadata = await _metadata.getAll(
        prefix: MetadataKeys.operationHistoryPrefix,
      );
      int clearedCount = 0;

      for (final MapEntry<String, String> entry in allMetadata.entries) {
        final List<Map<String, dynamic>> history =
            List<Map<String, dynamic>>.from(jsonDecode(entry.value) as List);

        if (history.isEmpty) continue;

        // Check if last entry is older than cutoff
        final DateTime lastTimestamp = DateTime.parse(
          history.last['timestamp'] as String,
        );

        if (lastTimestamp.isBefore(cutoffDate)) {
          await _metadata.delete(entry.key);
          clearedCount++;
        }
      }

      // Also clear old completed/failed entries from sync queue
      final int queueCleared = await _clearOldQueueEntries(cutoffDate);

      _logger.info(
        'Cleared $clearedCount old operation histories and $queueCleared queue entries',
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear old history', e, stackTrace);
      throw SyncException('Failed to clear old history', <String, dynamic>{
        "error": e.toString(),
      });
    }
  }

  /// Clears old completed/failed entries from the sync queue.
  Future<int> _clearOldQueueEntries(DateTime cutoffDate) async {
    try {
      final int deleted =
          await (_database.delete(_database.syncQueue)
                ..where(
                  ($SyncQueueTable t) =>
                      t.status.isIn(<String>['completed', 'failed']),
                )
                ..where(
                  ($SyncQueueTable t) =>
                      t.createdAt.isSmallerThanValue(cutoffDate),
                ))
              .go();

      return deleted;
    } catch (e) {
      _logger.warning('Failed to clear old queue entries: $e');
      return 0;
    }
  }
}

/// Represents a single entry in an operation's history
class OperationHistoryEntry {
  final String status;
  final DateTime timestamp;

  const OperationHistoryEntry({required this.status, required this.timestamp});

  @override
  String toString() => '$status at ${timestamp.toIso8601String()}';
}

/// Statistics from the sync queue table.
class SyncQueueStatistics {
  final int total;
  final int pending;
  final int processing;
  final int completed;
  final int failed;

  const SyncQueueStatistics({
    required this.total,
    required this.pending,
    required this.processing,
    required this.completed,
    required this.failed,
  });

  factory SyncQueueStatistics.empty() {
    return const SyncQueueStatistics(
      total: 0,
      pending: 0,
      processing: 0,
      completed: 0,
      failed: 0,
    );
  }
}

/// Statistics about synchronization operations
class OperationStatistics {
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final int retriedOperations;
  final int pendingOperations;
  final int processingOperations;
  final double successRate;
  final double failureRate;
  final double retryRate;
  final Duration averageProcessingTime;

  const OperationStatistics({
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.retriedOperations,
    this.pendingOperations = 0,
    this.processingOperations = 0,
    required this.successRate,
    required this.failureRate,
    required this.retryRate,
    required this.averageProcessingTime,
  });

  factory OperationStatistics.empty() {
    return const OperationStatistics(
      totalOperations: 0,
      successfulOperations: 0,
      failedOperations: 0,
      retriedOperations: 0,
      pendingOperations: 0,
      processingOperations: 0,
      successRate: 0.0,
      failureRate: 0.0,
      retryRate: 0.0,
      averageProcessingTime: Duration.zero,
    );
  }

  @override
  String toString() {
    return 'OperationStatistics('
        'total: $totalOperations, '
        'successful: $successfulOperations, '
        'failed: $failedOperations, '
        'pending: $pendingOperations, '
        'successRate: ${successRate.toStringAsFixed(1)}%, '
        'avgTime: ${averageProcessingTime.inSeconds}s)';
  }
}
