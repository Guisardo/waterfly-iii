import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../data/local/database/app_database.dart';

/// Centralized service for metadata management.
///
/// Provides consistent access to the sync_metadata table with:
/// - Type-safe key definitions
/// - Automatic timestamp management
/// - Batch operations
/// - Query helpers
/// - Validation
///
/// Eliminates duplication across:
/// - operation_tracker.dart
/// - sync_statistics.dart
/// - full_sync_service.dart
/// - incremental_sync_service.dart
class MetadataService {
  final Logger _logger = Logger('MetadataService');
  final AppDatabase _database;

  MetadataService(this._database);

  /// Get metadata value by key.
  ///
  /// Returns null if key doesn't exist.
  Future<String?> get(String key) async {
    try {
      final result = await (_database.select(_database.syncMetadata)
            ..where((t) => t.key.equals(key))
            ..limit(1))
          .getSingleOrNull();

      _logger.fine('Retrieved metadata: $key = ${result?.value}');
      return result?.value;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get metadata: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Set metadata value for key.
  ///
  /// Creates new entry or updates existing one.
  /// Automatically sets updatedAt timestamp.
  Future<void> set(String key, String value) async {
    try {
      await _database
          .into(_database.syncMetadata)
          .insertOnConflictUpdate(
            SyncMetadataEntityCompanion.insert(
              key: key,
              value: value,
              updatedAt: DateTime.now(),
            ),
          );

      _logger.fine('Set metadata: $key = $value');
    } catch (e, stackTrace) {
      _logger.severe('Failed to set metadata: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Delete metadata entry by key.
  ///
  /// No-op if key doesn't exist.
  Future<void> delete(String key) async {
    try {
      final deleted = await (_database.delete(_database.syncMetadata)
            ..where((t) => t.key.equals(key)))
          .go();

      _logger.fine('Deleted metadata: $key (rows: $deleted)');
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete metadata: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Get all metadata entries with optional prefix filter.
  ///
  /// Example:
  /// ```dart
  /// // Get all operation history entries
  /// final history = await metadata.getAll(prefix: 'operation_history_');
  /// ```
  Future<Map<String, String>> getAll({String? prefix}) async {
    try {
      final query = _database.select(_database.syncMetadata);

      if (prefix != null) {
        query.where((t) => t.key.like('$prefix%'));
      }

      final results = await query.get();
      final map = Map.fromEntries(
        results.map((row) => MapEntry(row.key, row.value)),
      );

      _logger.fine(
        'Retrieved ${map.length} metadata entries'
        '${prefix != null ? ' with prefix: $prefix' : ''}',
      );

      return map;
    } catch (e, stackTrace) {
      _logger.severe('Failed to get all metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Delete all metadata entries with prefix.
  ///
  /// Useful for clearing operation history or statistics.
  Future<int> deleteAll({String? prefix}) async {
    try {
      final delete = _database.delete(_database.syncMetadata);

      if (prefix != null) {
        delete.where((t) => t.key.like('$prefix%'));
      }

      final deleted = await delete.go();
      _logger.info(
        'Deleted $deleted metadata entries'
        '${prefix != null ? ' with prefix: $prefix' : ''}',
      );

      return deleted;
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete all metadata', e, stackTrace);
      rethrow;
    }
  }

  /// Set multiple metadata entries in a batch.
  ///
  /// More efficient than multiple individual set() calls.
  Future<void> setMany(Map<String, String> entries) async {
    if (entries.isEmpty) return;

    try {
      await _database.batch((batch) {
        for (final entry in entries.entries) {
          batch.insert(
            _database.syncMetadata,
            SyncMetadataEntityCompanion.insert(
              key: entry.key,
              value: entry.value,
              updatedAt: DateTime.now(),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });

      _logger.fine('Set ${entries.length} metadata entries in batch');
    } catch (e, stackTrace) {
      _logger.severe('Failed to set many metadata entries', e, stackTrace);
      rethrow;
    }
  }

  /// Check if metadata key exists.
  Future<bool> exists(String key) async {
    try {
      final result = await (_database.select(_database.syncMetadata)
            ..where((t) => t.key.equals(key))
            ..limit(1))
          .getSingleOrNull();

      return result != null;
    } catch (e, stackTrace) {
      _logger.severe('Failed to check metadata existence: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Get metadata entry with timestamp information.
  Future<MetadataEntry?> getEntry(String key) async {
    try {
      final result = await (_database.select(_database.syncMetadata)
            ..where((t) => t.key.equals(key))
            ..limit(1))
          .getSingleOrNull();

      if (result == null) return null;

      return MetadataEntry(
        key: result.key,
        value: result.value,
        updatedAt: result.updatedAt,
      );
    } catch (e, stackTrace) {
      _logger.severe('Failed to get metadata entry: $key', e, stackTrace);
      rethrow;
    }
  }

  /// Get all metadata entries with timestamp information.
  Future<List<MetadataEntry>> getAllEntries({String? prefix}) async {
    try {
      final query = _database.select(_database.syncMetadata);

      if (prefix != null) {
        query.where((t) => t.key.like('$prefix%'));
      }

      final results = await query.get();
      return results
          .map((row) => MetadataEntry(
                key: row.key,
                value: row.value,
                updatedAt: row.updatedAt,
              ))
          .toList();
    } catch (e, stackTrace) {
      _logger.severe('Failed to get all metadata entries', e, stackTrace);
      rethrow;
    }
  }

  /// Count metadata entries with optional prefix filter.
  Future<int> count({String? prefix}) async {
    try {
      final query = _database.select(_database.syncMetadata);

      if (prefix != null) {
        query.where((t) => t.key.like('$prefix%'));
      }

      final results = await query.get();
      return results.length;
    } catch (e, stackTrace) {
      _logger.severe('Failed to count metadata entries', e, stackTrace);
      rethrow;
    }
  }
}

/// Metadata entry with timestamp information.
class MetadataEntry {
  final String key;
  final String value;
  final DateTime updatedAt;

  MetadataEntry({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  @override
  String toString() => 'MetadataEntry($key: $value, updated: $updatedAt)';
}

/// Standard metadata keys used across sync services.
///
/// Centralizes key definitions to prevent typos and inconsistencies.
class MetadataKeys {
  MetadataKeys._();

  // Sync timestamps
  static const String lastFullSync = 'last_full_sync';
  static const String lastIncrementalSync = 'last_incremental_sync';
  static const String lastSuccessfulSync = 'last_successful_sync';

  // Sync statistics
  static const String totalSyncs = 'total_syncs';
  static const String successfulSyncs = 'successful_syncs';
  static const String failedSyncs = 'failed_syncs';

  // Operation tracking (prefix)
  static const String operationHistoryPrefix = 'operation_history_';

  // Sync state
  static const String syncInProgress = 'sync_in_progress';
  static const String currentSyncId = 'current_sync_id';

  /// Generate operation history key for specific operation.
  static String operationHistory(String operationId) =>
      '$operationHistoryPrefix$operationId';
}
