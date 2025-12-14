import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import '../../data/local/database/app_database.dart';
import '../../exceptions/offline_exceptions.dart';
import 'metadata_service.dart';

/// Tracks the lifecycle and statistics of synchronization operations.
///
/// This service maintains a history of operation state changes and
/// provides analytics on sync performance, success rates, and timing.
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

  OperationTracker(
    this._database, {
    MetadataService? metadata,
  }) : _metadata = metadata ?? MetadataService(_database);

  /// Tracks an operation status change
  ///
  /// Records the operation ID, new status, and timestamp in the metadata table.
  /// Maintains a history of all status changes for each operation.
  ///
  /// Throws [SyncException] if tracking fails
  Future<void> trackOperation(String operationId, String status) async {
    _logger.fine('Tracking operation: $operationId -> $status');

    try {
      final timestamp = DateTime.now();
      final historyKey = MetadataKeys.operationHistory(operationId);

      // Get existing history
      final existingHistory = await _metadata.get(historyKey);
      final history = existingHistory != null
          ? List<Map<String, dynamic>>.from(
              jsonDecode(existingHistory) as List,
            )
          : <Map<String, dynamic>>[];

      // Add new entry
      history.add({
        'status': status,
        'timestamp': timestamp.toIso8601String(),
      });

      // Store updated history
      await _metadata.set(historyKey, jsonEncode(history));

      _logger.fine('Operation tracked: $operationId -> $status');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to track operation: $operationId',
        e,
        stackTrace,
      );
      throw SyncException(
        'Failed to track operation',
        {"error": e.toString()},
      );
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
      final historyKey = MetadataKeys.operationHistory(operationId);
      final historyJson = await _metadata.get(historyKey);

      if (historyJson == null) {
        return [];
      }

      final history = List<Map<String, dynamic>>.from(
        jsonDecode(historyJson) as List,
      );

      return history
          .map((entry) => OperationHistoryEntry(
                status: entry['status'] as String,
                timestamp: DateTime.parse(entry['timestamp'] as String),
              ))
          .toList();
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to fetch operation history: $operationId',
        e,
        stackTrace,
      );
      throw SyncException(
        'Failed to fetch operation history',
        {"error": e.toString()},
      );
    }
  }

  /// Gets comprehensive statistics about sync operations
  ///
  /// Calculates:
  /// - Total operations processed
  /// - Success rate (percentage)
  /// - Average processing time
  /// - Failure rate
  /// - Retry rate
  ///
  /// Returns [OperationStatistics] with all metrics
  Future<OperationStatistics> getOperationStatistics() async {
    _logger.fine('Calculating operation statistics');

    try {
      // Get all operation histories
      final allMetadata = await _metadata.getAll(
        prefix: MetadataKeys.operationHistoryPrefix,
      );
      final historyEntries = allMetadata.entries.toList();

      if (historyEntries.isEmpty) {
        return OperationStatistics.empty();
      }

      int totalOperations = 0;
      int successfulOperations = 0;
      int failedOperations = 0;
      int retriedOperations = 0;
      final List<Duration> processingTimes = [];

      for (final entry in historyEntries) {
        final history = List<Map<String, dynamic>>.from(
          jsonDecode(entry.value) as List,
        );

        if (history.isEmpty) continue;

        totalOperations++;

        // Check final status
        final lastStatus = history.last['status'] as String;
        if (lastStatus == 'completed') {
          successfulOperations++;
        } else if (lastStatus == 'failed') {
          failedOperations++;
        }

        // Check for retries
        final processingCount =
            history.where((h) => h['status'] == 'processing').length;
        if (processingCount > 1) {
          retriedOperations++;
        }

        // Calculate processing time
        final createdEntry = history.firstWhere(
          (h) => h['status'] == 'created' || h['status'] == 'queued',
          orElse: () => history.first,
        );
        final completedEntry = history.lastWhere(
          (h) => h['status'] == 'completed' || h['status'] == 'failed',
          orElse: () => history.last,
        );

        final startTime = DateTime.parse(createdEntry['timestamp'] as String);
        final endTime = DateTime.parse(completedEntry['timestamp'] as String);
        processingTimes.add(endTime.difference(startTime));
      }

      // Calculate averages
      final successRate = totalOperations > 0
          ? (successfulOperations / totalOperations * 100)
          : 0.0;

      final failureRate = totalOperations > 0
          ? (failedOperations / totalOperations * 100)
          : 0.0;

      final retryRate = totalOperations > 0
          ? (retriedOperations / totalOperations * 100)
          : 0.0;

      final avgProcessingTime = processingTimes.isNotEmpty
          ? processingTimes.reduce((a, b) => a + b) ~/ processingTimes.length
          : Duration.zero;

      final stats = OperationStatistics(
        totalOperations: totalOperations,
        successfulOperations: successfulOperations,
        failedOperations: failedOperations,
        retriedOperations: retriedOperations,
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
        {"error": e.toString()},
      );
    }
  }

  /// Clears operation history older than specified days
  ///
  /// Removes history entries to prevent unbounded growth.
  /// Default retention is 30 days.
  Future<void> clearOldHistory({int retentionDays = 30}) async {
    _logger.info('Clearing operation history older than $retentionDays days');

    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final allMetadata = await _metadata.getAll(
        prefix: MetadataKeys.operationHistoryPrefix,
      );
      int clearedCount = 0;

      for (final entry in allMetadata.entries) {
        final history = List<Map<String, dynamic>>.from(
          jsonDecode(entry.value) as List,
        );

        if (history.isEmpty) continue;

        // Check if last entry is older than cutoff
        final lastTimestamp = DateTime.parse(
          history.last['timestamp'] as String,
        );

        if (lastTimestamp.isBefore(cutoffDate)) {
          await _metadata.delete(entry.key);
          clearedCount++;
        }
      }

      _logger.info('Cleared $clearedCount old operation histories');
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear old history', e, stackTrace);
      throw SyncException(
        'Failed to clear old history',
        {"error": e.toString()},
      );
    }
  }

}

/// Represents a single entry in an operation's history
class OperationHistoryEntry {
  final String status;
  final DateTime timestamp;

  const OperationHistoryEntry({
    required this.status,
    required this.timestamp,
  });

  @override
  String toString() => '$status at ${timestamp.toIso8601String()}';
}

/// Statistics about synchronization operations
class OperationStatistics {
  final int totalOperations;
  final int successfulOperations;
  final int failedOperations;
  final int retriedOperations;
  final double successRate;
  final double failureRate;
  final double retryRate;
  final Duration averageProcessingTime;

  const OperationStatistics({
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.retriedOperations,
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
        'successRate: ${successRate.toStringAsFixed(1)}%, '
        'avgTime: ${averageProcessingTime.inSeconds}s)';
  }
}
