import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Represents a data conflict detected during synchronization.
///
/// Conflicts occur when both local and remote versions of an entity have been
/// modified since the last sync. This model captures all information needed
/// to resolve the conflict.
///
/// Example:
/// ```dart
/// final conflict = Conflict(
///   id: 'conflict_123',
///   operationId: 'op_456',
///   entityType: 'transaction',
///   entityId: 'txn_789',
///   conflictType: ConflictType.updateUpdate,
///   localData: {'amount': 100.0, 'updated_at': '2024-01-01T10:00:00Z'},
///   remoteData: {'amount': 150.0, 'updated_at': '2024-01-01T11:00:00Z'},
///   conflictingFields: ['amount'],
///   severity: ConflictSeverity.high,
/// );
/// ```
class Conflict extends Equatable {
  /// Unique identifier for this conflict
  final String id;

  /// ID of the sync operation that detected this conflict
  final String operationId;

  /// Type of entity in conflict (transaction, account, etc.)
  final String entityType;

  /// ID of the entity in conflict
  final String entityId;

  /// Type of conflict
  final ConflictType conflictType;

  /// Local version of the entity data
  final Map<String, dynamic> localData;

  /// Remote version of the entity data
  final Map<String, dynamic> remoteData;

  /// List of fields that have conflicting values
  final List<String> conflictingFields;

  /// Severity level of the conflict
  final ConflictSeverity severity;

  /// Timestamp when the conflict was detected
  final DateTime detectedAt;

  /// Timestamp when the conflict was resolved (null if unresolved)
  final DateTime? resolvedAt;

  /// Strategy used to resolve the conflict (null if unresolved)
  final ResolutionStrategy? resolutionStrategy;

  /// Who resolved the conflict (user or auto)
  final String? resolvedBy;

  /// Additional notes about the conflict or resolution
  final String? notes;

  const Conflict({
    required this.id,
    required this.operationId,
    required this.entityType,
    required this.entityId,
    required this.conflictType,
    required this.localData,
    required this.remoteData,
    required this.conflictingFields,
    required this.severity,
    required this.detectedAt,
    this.resolvedAt,
    this.resolutionStrategy,
    this.resolvedBy,
    this.notes,
  });

  /// Whether this conflict has been resolved
  bool get isResolved => resolvedAt != null;

  /// Whether this conflict was resolved automatically
  bool get wasAutoResolved => resolvedBy == 'auto';

  /// Whether this conflict was resolved manually by user
  bool get wasManuallyResolved => resolvedBy == 'user';

  /// Create a copy with updated fields
  Conflict copyWith({
    String? id,
    String? operationId,
    String? entityType,
    String? entityId,
    ConflictType? conflictType,
    Map<String, dynamic>? localData,
    Map<String, dynamic>? remoteData,
    List<String>? conflictingFields,
    ConflictSeverity? severity,
    DateTime? detectedAt,
    DateTime? resolvedAt,
    ResolutionStrategy? resolutionStrategy,
    String? resolvedBy,
    String? notes,
  }) {
    return Conflict(
      id: id ?? this.id,
      operationId: operationId ?? this.operationId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      conflictType: conflictType ?? this.conflictType,
      localData: localData ?? this.localData,
      remoteData: remoteData ?? this.remoteData,
      conflictingFields: conflictingFields ?? this.conflictingFields,
      severity: severity ?? this.severity,
      detectedAt: detectedAt ?? this.detectedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionStrategy: resolutionStrategy ?? this.resolutionStrategy,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      notes: notes ?? this.notes,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'operation_id': operationId,
      'entity_type': entityType,
      'entity_id': entityId,
      'conflict_type': conflictType.name,
      'local_data': jsonEncode(localData),
      'remote_data': jsonEncode(remoteData),
      'conflicting_fields': jsonEncode(conflictingFields),
      'severity': severity.name,
      'detected_at': detectedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_strategy': resolutionStrategy?.name,
      'resolved_by': resolvedBy,
      'notes': notes,
    };
  }

  /// Create from JSON
  factory Conflict.fromJson(Map<String, dynamic> json) {
    return Conflict(
      id: json['id'] as String,
      operationId: json['operation_id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      conflictType: ConflictType.values.firstWhere(
        (e) => e.name == json['conflict_type'],
      ),
      localData: jsonDecode(json['local_data'] as String) as Map<String, dynamic>,
      remoteData: jsonDecode(json['remote_data'] as String) as Map<String, dynamic>,
      conflictingFields: (jsonDecode(json['conflicting_fields'] as String) as List)
          .cast<String>(),
      severity: ConflictSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
      ),
      detectedAt: DateTime.parse(json['detected_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionStrategy: json['resolution_strategy'] != null
          ? ResolutionStrategy.values.firstWhere(
              (e) => e.name == json['resolution_strategy'],
            )
          : null,
      resolvedBy: json['resolved_by'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        operationId,
        entityType,
        entityId,
        conflictType,
        localData,
        remoteData,
        conflictingFields,
        severity,
        detectedAt,
        resolvedAt,
        resolutionStrategy,
        resolvedBy,
        notes,
      ];

  @override
  String toString() {
    return 'Conflict(id: $id, type: $conflictType, entity: $entityType/$entityId, '
        'severity: $severity, fields: $conflictingFields, resolved: $isResolved)';
  }
}

/// Types of conflicts that can occur during synchronization.
enum ConflictType {
  /// Both local and remote versions were updated
  updateUpdate,

  /// Local version was updated, remote version was deleted
  updateDelete,

  /// Local version was deleted, remote version was updated
  deleteUpdate,

  /// Attempted to create entity that already exists on server
  createExists,
}

/// Severity levels for conflicts.
///
/// Severity determines whether a conflict can be auto-resolved and
/// how urgently it needs user attention.
enum ConflictSeverity {
  /// Low severity - only non-critical fields differ
  /// Can be auto-resolved safely
  low,

  /// Medium severity - important fields differ
  /// May be auto-resolved with caution
  medium,

  /// High severity - critical fields differ (amount, date, etc.)
  /// Requires manual resolution
  high,
}

/// Strategies for resolving conflicts.
enum ResolutionStrategy {
  /// Keep local changes, overwrite remote
  localWins,

  /// Keep remote changes, overwrite local
  remoteWins,

  /// Use timestamp to determine winner
  lastWriteWins,

  /// Attempt to merge both versions
  merge,

  /// User must manually choose
  manual,
}

/// Result of a conflict resolution operation.
class Resolution extends Equatable {
  /// The conflict that was resolved
  final Conflict conflict;

  /// Strategy used for resolution
  final ResolutionStrategy strategy;

  /// Merged/resolved data
  final Map<String, dynamic> resolvedData;

  /// Whether resolution was successful
  final bool success;

  /// Error message if resolution failed
  final String? errorMessage;

  /// Timestamp when resolution was performed
  final DateTime resolvedAt;

  const Resolution({
    required this.conflict,
    required this.strategy,
    required this.resolvedData,
    required this.success,
    this.errorMessage,
    required this.resolvedAt,
  });

  @override
  List<Object?> get props => [
        conflict,
        strategy,
        resolvedData,
        success,
        errorMessage,
        resolvedAt,
      ];

  @override
  String toString() {
    return 'Resolution(conflict: ${conflict.id}, strategy: $strategy, '
        'success: $success${errorMessage != null ? ", error: $errorMessage" : ""})';
  }
}

/// Statistics about conflicts.
class ConflictStatistics extends Equatable {
  /// Total number of conflicts detected
  final int totalConflicts;

  /// Number of unresolved conflicts
  final int unresolvedConflicts;

  /// Number of auto-resolved conflicts
  final int autoResolvedConflicts;

  /// Number of manually resolved conflicts
  final int manuallyResolvedConflicts;

  /// Conflicts by severity
  final Map<ConflictSeverity, int> bySeverity;

  /// Conflicts by type
  final Map<ConflictType, int> byType;

  /// Conflicts by entity type
  final Map<String, int> byEntityType;

  /// Average resolution time in seconds
  final double averageResolutionTime;

  const ConflictStatistics({
    required this.totalConflicts,
    required this.unresolvedConflicts,
    required this.autoResolvedConflicts,
    required this.manuallyResolvedConflicts,
    required this.bySeverity,
    required this.byType,
    required this.byEntityType,
    required this.averageResolutionTime,
  });

  /// Success rate (resolved / total)
  double get resolutionRate {
    if (totalConflicts == 0) return 1.0;
    return (autoResolvedConflicts + manuallyResolvedConflicts) / totalConflicts;
  }

  /// Auto-resolution rate (auto / resolved)
  double get autoResolutionRate {
    final resolved = autoResolvedConflicts + manuallyResolvedConflicts;
    if (resolved == 0) return 0.0;
    return autoResolvedConflicts / resolved;
  }

  @override
  List<Object?> get props => [
        totalConflicts,
        unresolvedConflicts,
        autoResolvedConflicts,
        manuallyResolvedConflicts,
        bySeverity,
        byType,
        byEntityType,
        averageResolutionTime,
      ];

  @override
  String toString() {
    return 'ConflictStatistics(total: $totalConflicts, unresolved: $unresolvedConflicts, '
        'auto: $autoResolvedConflicts, manual: $manuallyResolvedConflicts, '
        'rate: ${(resolutionRate * 100).toStringAsFixed(1)}%)';
  }
}
