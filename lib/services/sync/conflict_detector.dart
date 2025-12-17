import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

import 'package:waterflyiii/models/conflict.dart';
import 'package:waterflyiii/models/sync_operation.dart';

/// Service for detecting conflicts during synchronization.
///
/// This service compares local and remote versions of entities to detect
/// conflicts, classify their type and severity, and prepare them for resolution.
///
/// Example:
/// ```dart
/// final detector = ConflictDetector();
/// final conflict = await detector.detectConflict(operation, remoteData);
/// if (conflict != null) {
///   print('Conflict detected: ${conflict.severity}');
///   print('Conflicting fields: ${conflict.conflictingFields}');
/// }
/// ```
class ConflictDetector {
  final Logger _logger = Logger('ConflictDetector');
  final Uuid _uuid = const Uuid();

  /// Critical fields that always result in HIGH severity conflicts
  static const Set<String> _criticalFields = <String>{
    'amount',
    'date',
    'type',
    'currency_code',
    'account_id',
    'destination_id',
    'source_id',
  };

  /// Important fields that result in MEDIUM severity conflicts
  static const Set<String> _importantFields = <String>{
    'description',
    'category_id',
    'budget_id',
    'bill_id',
    'notes',
    'tags',
  };

  /// Detect conflict between local operation and remote data.
  ///
  /// Compares the local version (from operation payload) with the remote
  /// version fetched from the server. Returns a Conflict object if differences
  /// are detected, null otherwise.
  ///
  /// Args:
  ///   operation: The sync operation containing local data
  ///   remoteData: The current server version of the entity
  ///
  /// Returns:
  ///   Conflict object if conflict detected, null otherwise
  ///
  /// Throws:
  ///   Exception: If comparison fails
  Future<Conflict?> detectConflict(
    SyncOperation operation,
    Map<String, dynamic>? remoteData,
  ) async {
    try {
      _logger.fine(
        'Detecting conflict for operation ${operation.id} '
        '(${operation.entityType}/${operation.entityId})',
      );

      // No remote data means entity doesn't exist on server
      if (remoteData == null) {
        return _handleMissingRemote(operation);
      }

      // Determine conflict type
      final ConflictType? conflictType = _determineConflictType(
        operation,
        remoteData,
      );

      // No conflict if types don't indicate one
      if (conflictType == null) {
        _logger.fine('No conflict detected for operation ${operation.id}');
        return null;
      }

      // Get conflicting fields
      final List<String> conflictingFields = getConflictingFields(
        operation.payload,
        remoteData,
      );

      // No conflict if no fields differ
      if (conflictingFields.isEmpty &&
          conflictType == ConflictType.updateUpdate) {
        _logger.fine('No field differences for operation ${operation.id}');
        return null;
      }

      // Calculate severity
      final ConflictSeverity severity = _calculateSeverity(
        conflictingFields,
        operation.entityType,
      );

      // Create conflict object
      final Conflict conflict = Conflict(
        id: _uuid.v4(),
        operationId: operation.id,
        entityType: operation.entityType,
        entityId: operation.entityId,
        conflictType: conflictType,
        localData: operation.payload,
        remoteData: remoteData,
        conflictingFields: conflictingFields,
        severity: severity,
        detectedAt: DateTime.now(),
      );

      _logger.warning(
        'Conflict detected: ${conflict.id} '
        '(type: $conflictType, severity: $severity, fields: $conflictingFields)',
      );

      return conflict;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to detect conflict for operation ${operation.id}',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Handle case where remote entity doesn't exist.
  Conflict? _handleMissingRemote(SyncOperation operation) {
    if (operation.operation == SyncOperationType.create) {
      // CREATE with no remote is normal
      return null;
    }

    if (operation.operation == SyncOperationType.delete) {
      // DELETE with no remote is already done
      return null;
    }

    // UPDATE with no remote means remote was deleted
    _logger.warning('Remote entity deleted for operation ${operation.id}');

    return Conflict(
      id: _uuid.v4(),
      operationId: operation.id,
      entityType: operation.entityType,
      entityId: operation.entityId,
      conflictType: ConflictType.updateDelete,
      localData: operation.payload,
      remoteData: const <String, dynamic>{},
      conflictingFields: const <String>['_deleted'],
      severity: ConflictSeverity.high,
      detectedAt: DateTime.now(),
    );
  }

  /// Determine the type of conflict.
  ConflictType? _determineConflictType(
    SyncOperation operation,
    Map<String, dynamic> remoteData,
  ) {
    final bool isRemoteDeleted =
        remoteData['deleted_at'] != null || remoteData['is_deleted'] == true;

    switch (operation.operation) {
      case SyncOperationType.create:
        // CREATE when entity exists on server
        return ConflictType.createExists;

      case SyncOperationType.update:
        if (isRemoteDeleted) {
          // UPDATE when remote was deleted
          return ConflictType.updateDelete;
        }
        // Check if remote was modified after local
        if (_wasRemoteModified(operation.payload, remoteData)) {
          return ConflictType.updateUpdate;
        }
        return null; // No conflict

      case SyncOperationType.delete:
        if (!isRemoteDeleted &&
            _wasRemoteModified(operation.payload, remoteData)) {
          // DELETE when remote was updated
          return ConflictType.deleteUpdate;
        }
        return null; // No conflict
    }
  }

  /// Check if remote was modified after local.
  bool _wasRemoteModified(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    try {
      final DateTime? localUpdated = _parseDateTime(localData['updated_at']);
      final DateTime? remoteUpdated = _parseDateTime(remoteData['updated_at']);

      if (localUpdated == null || remoteUpdated == null) {
        // Can't determine, assume modified
        return true;
      }

      return remoteUpdated.isAfter(localUpdated);
    } catch (e) {
      _logger.warning('Failed to compare timestamps: $e');
      return true; // Assume modified on error
    }
  }

  /// Parse datetime from various formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Get list of fields that have conflicting values.
  ///
  /// Compares all fields in local and remote data, identifying those
  /// with different values. Handles nested objects and arrays.
  ///
  /// Args:
  ///   localData: Local version of entity
  ///   remoteData: Remote version of entity
  ///
  /// Returns:
  ///   List of field names that differ
  List<String> getConflictingFields(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    final List<String> conflicting = <String>[];

    // Get all unique keys from both maps
    final Set<String> allKeys = <String>{...localData.keys, ...remoteData.keys};

    for (final String key in allKeys) {
      // Skip internal fields
      if (key.startsWith('_') || key == 'id' || key == 'created_at') {
        continue;
      }

      final localValue = localData[key];
      final remoteValue = remoteData[key];

      // Check if values differ
      if (!_valuesEqual(localValue, remoteValue)) {
        conflicting.add(key);
        _logger.fine(
          'Field "$key" differs: local=$localValue, remote=$remoteValue',
        );
      }
    }

    return conflicting;
  }

  /// Check if two values are equal, handling various types.
  bool _valuesEqual(dynamic a, dynamic b) {
    // Both null
    if (a == null && b == null) return true;

    // One null
    if (a == null || b == null) return false;

    // Same type comparison
    if (a.runtimeType == b.runtimeType) {
      if (a is List && b is List) {
        return _listsEqual(a, b);
      }
      if (a is Map && b is Map) {
        return _mapsEqual(a, b);
      }
      return a == b;
    }

    // Number comparison (int vs double)
    if (a is num && b is num) {
      return a.toDouble() == b.toDouble();
    }

    // String comparison (case-insensitive for some fields)
    if (a is String && b is String) {
      return a.trim() == b.trim();
    }

    return false;
  }

  /// Check if two lists are equal.
  bool _listsEqual(List a, List b) {
    if (a.length != b.length) return false;

    for (int i = 0; i < a.length; i++) {
      if (!_valuesEqual(a[i], b[i])) return false;
    }

    return true;
  }

  /// Check if two maps are equal.
  bool _mapsEqual(Map a, Map b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_valuesEqual(a[key], b[key])) return false;
    }

    return true;
  }

  /// Calculate conflict severity based on conflicting fields.
  ///
  /// Severity is determined by which fields are in conflict:
  /// - HIGH: Critical fields (amount, date, account_id, etc.)
  /// - MEDIUM: Important fields (description, category, etc.)
  /// - LOW: Non-critical fields (notes, tags, etc.)
  ///
  /// Args:
  ///   conflictingFields: List of fields that differ
  ///   entityType: Type of entity (for entity-specific rules)
  ///
  /// Returns:
  ///   ConflictSeverity level
  ConflictSeverity _calculateSeverity(
    List<String> conflictingFields,
    String entityType,
  ) {
    if (conflictingFields.isEmpty) {
      return ConflictSeverity.low;
    }

    // Check for critical fields
    for (final String field in conflictingFields) {
      if (_criticalFields.contains(field)) {
        _logger.fine('Critical field "$field" in conflict - HIGH severity');
        return ConflictSeverity.high;
      }
    }

    // Check for important fields
    for (final String field in conflictingFields) {
      if (_importantFields.contains(field)) {
        _logger.fine('Important field "$field" in conflict - MEDIUM severity');
        return ConflictSeverity.medium;
      }
    }

    // Entity-specific severity rules
    if (entityType == 'account') {
      if (conflictingFields.any(
        (String f) => f.contains('balance') || f == 'iban',
      )) {
        return ConflictSeverity.high;
      }
    }

    if (entityType == 'budget') {
      if (conflictingFields.any(
        (String f) => f.contains('amount') || f == 'period',
      )) {
        return ConflictSeverity.high;
      }
    }

    // Default to low severity
    _logger.fine('Non-critical fields in conflict - LOW severity');
    return ConflictSeverity.low;
  }

  /// Batch detect conflicts for multiple operations.
  ///
  /// Efficiently detects conflicts for a list of operations by batching
  /// remote data fetches.
  ///
  /// Args:
  ///   operations: List of sync operations
  ///   fetchRemoteData: Function to fetch remote data for entities
  ///
  /// Returns:
  ///   Map of operation ID to detected conflict (null if no conflict)
  Future<Map<String, Conflict?>> detectConflictsBatch(
    List<SyncOperation> operations,
    Future<Map<String, Map<String, dynamic>?>> Function(List<String> entityIds)
    fetchRemoteData,
  ) async {
    try {
      _logger.info('Detecting conflicts for ${operations.length} operations');

      // Group operations by entity type
      final Map<String, List<SyncOperation>> byType =
          <String, List<SyncOperation>>{};
      for (final SyncOperation op in operations) {
        byType.putIfAbsent(op.entityType, () => <SyncOperation>[]).add(op);
      }

      final Map<String, Conflict?> results = <String, Conflict?>{};

      // Process each entity type
      for (final MapEntry<String, List<SyncOperation>> entry
          in byType.entries) {
        final String entityType = entry.key;
        final List<SyncOperation> ops = entry.value;

        _logger.fine(
          'Fetching remote data for ${ops.length} $entityType entities',
        );

        // Fetch remote data for all entities of this type
        final List<String> entityIds =
            ops.map((SyncOperation op) => op.entityId).toList();
        final Map<String, Map<String, dynamic>?> remoteDataMap =
            await fetchRemoteData(entityIds);

        // Detect conflicts for each operation
        for (final SyncOperation op in ops) {
          final Map<String, dynamic>? remoteData = remoteDataMap[op.entityId];
          final Conflict? conflict = await detectConflict(op, remoteData);
          results[op.id] = conflict;
        }
      }

      final int conflictCount =
          results.values.where((Conflict? c) => c != null).length;
      _logger.info(
        'Detected $conflictCount conflicts out of ${operations.length} operations',
      );

      return results;
    } catch (e, stackTrace) {
      _logger.severe('Failed to detect conflicts in batch', e, stackTrace);
      rethrow;
    }
  }
}
