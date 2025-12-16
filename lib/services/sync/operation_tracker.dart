import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/services/sync/metadata_service.dart';

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
  // TODO: Use _database to persist operation tracking data
  // ignore: unused_field
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
      final DateTime timestamp = DateTime.now();
      final String historyKey = MetadataKeys.operationHistory(operationId);

      // Get existing history
      final String? existingHistory = await _metadata.get(historyKey);
      final List<Map<String, dynamic>> history = existingHistory != null
          ? List<Map<String, dynamic>>.from(
              jsonDecode(existingHistory) as List,
            )
          : <Map<String, dynamic>>[];

      // Add new entry
      history.add(<String, dynamic>{
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
        <String, dynamic>{"error": e.toString()},
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
      final String historyKey = MetadataKeys.operationHistory(operationId);
      final String? historyJson = await _metadata.get(historyKey);

      if (historyJson == null) {
        return <OperationHistoryEntry>[];
      }

      final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(
        jsonDecode(historyJson) as List,
      );

      return history
          .map((Map<String, dynamic> entry) => OperationHistoryEntry(
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
        <String, dynamic>{"error": e.toString()},
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
      final Map<String, String> allMetadata = await _metadata.getAll(
        prefix: MetadataKeys.operationHistoryPrefix,
      );
      final List<MapEntry<String, String>> historyEntries = allMetadata.entries.toList();

      if (historyEntries.isEmpty) {
        return OperationStatistics.empty();
      }

      int totalOperations = 0;
      int successfulOperations = 0;
      int failedOperations = 0;
      int retriedOperations = 0;
      final List<Duration> processingTimes = <Duration>[];

      for (final MapEntry<String, String> entry in historyEntries) {
        final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(
          jsonDecode(entry.value) as List,
        );

        if (history.isEmpty) continue;

        totalOperations++;

        // Check final status
        final String lastStatus = history.last['status'] as String;
        if (lastStatus == 'completed') {
          successfulOperations++;
        } else if (lastStatus == 'failed') {
          failedOperations++;
        }

        // Check for retries
        final int processingCount =
            history.where((Map<String, dynamic> h) => h['status'] == 'processing').length;
        if (processingCount > 1) {
          retriedOperations++;
        }

        // Calculate processing time
        final Map<String, dynamic> createdEntry = history.firstWhere(
          (Map<String, dynamic> h) => h['status'] == 'created' || h['status'] == 'queued',
          orElse: () => history.first,
        );
        final Map<String, dynamic> completedEntry = history.lastWhere(
          (Map<String, dynamic> h) => h['status'] == 'completed' || h['status'] == 'failed',
          orElse: () => history.last,
        );

        final DateTime startTime = DateTime.parse(createdEntry['timestamp'] as String);
        final DateTime endTime = DateTime.parse(completedEntry['timestamp'] as String);
        processingTimes.add(endTime.difference(startTime));
      }

      // Calculate averages
      final double successRate = totalOperations > 0
          ? (successfulOperations / totalOperations * 100)
          : 0.0;

      final double failureRate = totalOperations > 0
          ? (failedOperations / totalOperations * 100)
          : 0.0;

      final double retryRate = totalOperations > 0
          ? (retriedOperations / totalOperations * 100)
          : 0.0;

      final Duration avgProcessingTime = processingTimes.isNotEmpty
          ? processingTimes.reduce((Duration a, Duration b) => a + b) ~/ processingTimes.length
          : Duration.zero;

      final OperationStatistics stats = OperationStatistics(
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
        <String, dynamic>{"error": e.toString()},
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
      final DateTime cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
      final Map<String, String> allMetadata = await _metadata.getAll(
        prefix: MetadataKeys.operationHistoryPrefix,
      );
      int clearedCount = 0;

      for (final MapEntry<String, String> entry in allMetadata.entries) {
        final List<Map<String, dynamic>> history = List<Map<String, dynamic>>.from(
          jsonDecode(entry.value) as List,
        );

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

      _logger.info('Cleared $clearedCount old operation histories');
    } catch (e, stackTrace) {
      _logger.severe('Failed to clear old history', e, stackTrace);
      throw SyncException(
        'Failed to clear old history',
        <String, dynamic>{"error": e.toString()},
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
