import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';
import 'package:waterflyiii/models/sync_operation.dart';

/// Service for detecting and handling duplicate synchronization operations.
///
/// Prevents the same operation from being queued multiple times by:
/// - Detecting duplicates based on entity, operation type, and payload
/// - Merging duplicate operations when appropriate
/// - Using payload hashing for efficient comparison
///
/// Example:
/// ```dart
/// final deduplicationService = DeduplicationService(database);
///
/// // Check if operation is duplicate
/// final isDupe = await deduplicationService.isDuplicate(operation);
/// if (isDupe) {
///   print('Operation already queued');
/// }
///
/// // Merge duplicates in queue
/// await deduplicationService.mergeDuplicates(operations);
/// ```
class DeduplicationService {
  final AppDatabase _database;
  final Logger _logger = Logger('DeduplicationService');

  /// Time window for considering operations as duplicates (5 minutes)
  static const Duration deduplicationWindow = Duration(minutes: 5);

  DeduplicationService(this._database);

  /// Checks if an operation is a duplicate of an existing queued operation
  ///
  /// An operation is considered a duplicate if:
  /// - Same entity type and entity ID
  /// - Same operation type (CREATE/UPDATE/DELETE)
  /// - Created within the deduplication window
  /// - Payload hash matches (for CREATE/UPDATE operations)
  ///
  /// Returns true if duplicate found, false otherwise
  Future<bool> isDuplicate(SyncOperation operation) async {
    _logger.fine('Checking for duplicate: ${operation.id}');

    try {
      final DateTime cutoffTime = DateTime.now().subtract(deduplicationWindow);

      final SimpleSelectStatement<$SyncQueueTable, SyncQueueEntity> query = _database.select(_database.syncQueue)
        ..where(
          ($SyncQueueTable tbl) =>
              tbl.entityType.equals(operation.entityType) &
              tbl.entityId.equals(operation.entityId) &
              tbl.operation.equals(operation.operation.name) &
              tbl.createdAt.isBiggerThanValue(cutoffTime) &
              (tbl.status.equals(SyncOperationStatus.pending.name) |
                  tbl.status.equals(SyncOperationStatus.processing.name)),
        );

      final List<SyncQueueEntity> results = await query.get();

      if (results.isEmpty) {
        _logger.fine('No duplicates found for: ${operation.id}');
        return false;
      }

      if (operation.operation == SyncOperationType.delete) {
        _logger.info('Duplicate DELETE operation found: ${operation.id}');
        return true;
      }

      final String operationHash = _hashPayload(operation.payload);

      for (final SyncQueueEntity row in results) {
        final Map<String, dynamic> existingPayload = jsonDecode(row.payload) as Map<String, dynamic>;
        final String existingHash = _hashPayload(existingPayload);

        if (operationHash == existingHash) {
          _logger.info('Duplicate operation found: ${operation.id} '
              '(matches ${row.id})');
          return true;
        }
      }

      _logger.fine('No exact payload match found for: ${operation.id}');
      return false;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to check for duplicates: ${operation.id}',
        e,
        stackTrace,
      );
      throw SyncException(
        'Failed to check for duplicates',
        {'error': e.toString()},
      );
    }
  }

  /// Finds and merges duplicate operations in a list
  ///
  /// Groups operations by entity and operation type, then:
  /// - Keeps the most recent operation
  /// - Merges payloads if beneficial
  /// - Returns deduplicated list
  ///
  /// This is useful for batch processing where duplicates may exist.
  Future<List<SyncOperation>> mergeDuplicates(
    List<SyncOperation> operations,
  ) async {
    _logger.info('Merging duplicates in ${operations.length} operations');

    try {
      final Map<String, List<SyncOperation>> grouped = {};

      // Group by entity + operation type
      for (final operation in operations) {
        final key = '${operation.entityType}:${operation.entityId}:'
            '${operation.operation.name}';

        grouped.putIfAbsent(key, () => []);
        grouped[key]!.add(operation);
      }

      final List<SyncOperation> deduplicated = [];
      int mergedCount = 0;

      // Process each group
      for (final group in grouped.values) {
        if (group.length == 1) {
          // No duplicates
          deduplicated.add(group.first);
          continue;
        }

        // Sort by creation time (newest first)
        group.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Keep the newest operation
        final newest = group.first;

        // For UPDATE operations, merge payloads
        if (newest.operation == SyncOperationType.update) {
          final mergedPayload = _mergePayloads(
            group.map((op) => op.payload).toList(),
          );

          deduplicated.add(newest.copyWith(payload: mergedPayload));
        } else {
          deduplicated.add(newest);
        }

        mergedCount += group.length - 1;

        _logger.fine('Merged ${group.length} duplicates for '
            '${newest.entityType}:${newest.entityId}');
      }

      _logger.info('Merged $mergedCount duplicate operations. '
          'Result: ${deduplicated.length} operations');

      return deduplicated;
    } catch (e, stackTrace) {
      _logger.severe('Failed to merge duplicates', e, stackTrace);
      throw SyncException(
        'Failed to merge duplicates',
        {'error': e.toString()},
      );
    }
  }

  /// Removes duplicate operations from the database queue
  ///
  /// Scans the queue for duplicates and removes older ones,
  /// keeping only the most recent operation for each entity.
  ///
  /// Returns the number of duplicates removed.
  Future<int> removeDuplicatesFromQueue() async {
    _logger.info('Removing duplicates from queue');

    try {
      final SimpleSelectStatement<$SyncQueueTable, SyncQueueEntity> query = _database.select(_database.syncQueue)
        ..where(
          ($SyncQueueTable tbl) =>
              tbl.status.equals(SyncOperationStatus.pending.name) |
              tbl.status.equals(SyncOperationStatus.processing.name),
        )
        ..orderBy([
          ($SyncQueueTable tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.desc),
        ]);

      final List<SyncQueueEntity> operations = await query.get();

      if (operations.length < 2) {
        _logger.fine('No duplicates to remove (queue size: ${operations.length})');
        return 0;
      }

      final Set<String> seen = {};
      final List<String> toDelete = [];

      for (final SyncQueueEntity operation in operations) {
        final String key = '${operation.entityType}:${operation.entityId}:'
            '${operation.operation}';

        if (seen.contains(key)) {
          toDelete.add(operation.id);
          _logger.fine('Marking duplicate for deletion: ${operation.id}');
        } else {
          seen.add(key);
        }
      }

      if (toDelete.isNotEmpty) {
        final DeleteStatement<$SyncQueueTable, SyncQueueEntity> delete = _database.delete(_database.syncQueue)
          ..where(($SyncQueueTable tbl) => tbl.id.isIn(toDelete));

        await delete.go();
      }

      _logger.info('Removed ${toDelete.length} duplicate operations from queue');
      return toDelete.length;
    } catch (e, stackTrace) {
      _logger.severe('Failed to remove duplicates from queue', e, stackTrace);
      throw SyncException(
        'Failed to remove duplicates from queue',
        {'error': e.toString()},
      );
    }
  }

  // Private helper methods

  /// Generates a hash of the payload for comparison
  String _hashPayload(Map<String, dynamic> payload) {
    // Sort keys for consistent hashing
    final sortedKeys = payload.keys.toList()..sort();
    final sortedPayload = Map.fromEntries(
      sortedKeys.map((key) => MapEntry(key, payload[key])),
    );

    final payloadString = jsonEncode(sortedPayload);
    final bytes = utf8.encode(payloadString);
    final digest = sha256.convert(bytes);

    return digest.toString();
  }

  /// Merges multiple payloads, keeping the most recent values
  Map<String, dynamic> _mergePayloads(List<Map<String, dynamic>> payloads) {
    if (payloads.isEmpty) return {};
    if (payloads.length == 1) return payloads.first;

    // Start with the newest payload
    final merged = Map<String, dynamic>.from(payloads.first);

    // Merge in values from older payloads (only if not present)
    for (int i = 1; i < payloads.length; i++) {
      for (final entry in payloads[i].entries) {
        merged.putIfAbsent(entry.key, () => entry.value);
      }
    }

    return merged;
  }
}
