import 'dart:convert';

import 'package:equatable/equatable.dart';

/// Represents a synchronization operation to be performed with the server.
///
/// This model tracks all pending operations that need to be synchronized
/// when connectivity is restored. Each operation contains the entity type,
/// operation type (CREATE/UPDATE/DELETE), and the complete payload.
///
/// Example:
/// ```dart
/// final operation = SyncOperation(
///   id: 'op_123',
///   entityType: 'transaction',
///   entityId: 'offline_txn_abc',
///   operation: SyncOperationType.create,
///   payload: {'amount': 100.0, 'description': 'Groceries'},
///   priority: SyncPriority.normal,
/// );
/// ```
class SyncOperation extends Equatable {
  /// Unique identifier for this operation
  final String id;

  /// Type of entity being synchronized (transaction, account, category, etc.)
  final String entityType;

  /// ID of the entity being synchronized (local ID for offline entities)
  final String entityId;

  /// Type of operation (CREATE, UPDATE, DELETE)
  final SyncOperationType operation;

  /// Complete payload data for the operation (JSON-serializable)
  final Map<String, dynamic> payload;

  /// Current status of the operation
  final SyncOperationStatus status;

  /// Number of sync attempts made
  final int attempts;

  /// Error message if operation failed
  final String? errorMessage;

  /// Priority level for queue ordering
  final SyncPriority priority;

  /// Timestamp when operation was created
  final DateTime createdAt;

  /// Timestamp of last sync attempt
  final DateTime? lastAttemptAt;

  /// Timestamp when operation completed successfully
  final DateTime? completedAt;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.operation,
    required this.payload,
    this.status = SyncOperationStatus.pending,
    this.attempts = 0,
    this.errorMessage,
    this.priority = SyncPriority.normal,
    required this.createdAt,
    this.lastAttemptAt,
    this.completedAt,
  });

  /// Creates a SyncOperation from JSON data
  factory SyncOperation.fromJson(Map<String, dynamic> json) {
    return SyncOperation(
      id: json['id'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String,
      operation: SyncOperationType.values.firstWhere(
        (SyncOperationType e) => e.name == json['operation'],
        orElse: () => SyncOperationType.create,
      ),
      payload: json['payload'] is String
          ? jsonDecode(json['payload'] as String) as Map<String, dynamic>
          : json['payload'] as Map<String, dynamic>,
      status: SyncOperationStatus.values.firstWhere(
        (SyncOperationStatus e) => e.name == json['status'],
        orElse: () => SyncOperationStatus.pending,
      ),
      attempts: json['attempts'] as int? ?? 0,
      errorMessage: json['error_message'] as String?,
      priority: SyncPriority.values.firstWhere(
        (SyncPriority e) => e.value == json['priority'],
        orElse: () => SyncPriority.normal,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastAttemptAt: json['last_attempt_at'] != null
          ? DateTime.parse(json['last_attempt_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
    );
  }

  /// Converts this SyncOperation to JSON
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'operation': operation.name,
      'payload': jsonEncode(payload),
      'status': status.name,
      'attempts': attempts,
      'error_message': errorMessage,
      'priority': priority.value,
      'created_at': createdAt.toIso8601String(),
      'last_attempt_at': lastAttemptAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this operation with updated fields
  SyncOperation copyWith({
    String? id,
    String? entityType,
    String? entityId,
    SyncOperationType? operation,
    Map<String, dynamic>? payload,
    SyncOperationStatus? status,
    int? attempts,
    String? errorMessage,
    SyncPriority? priority,
    DateTime? createdAt,
    DateTime? lastAttemptAt,
    DateTime? completedAt,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      operation: operation ?? this.operation,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      attempts: attempts ?? this.attempts,
      errorMessage: errorMessage ?? this.errorMessage,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Validates that this operation has all required fields
  bool validate() {
    if (id.isEmpty) return false;
    if (entityType.isEmpty) return false;
    if (entityId.isEmpty) return false;
    if (payload.isEmpty && operation != SyncOperationType.delete) return false;
    return true;
  }

  /// Checks if this operation can be retried
  bool canRetry({int maxAttempts = 5}) {
    return attempts < maxAttempts && status == SyncOperationStatus.failed;
  }

  /// Calculates the age of this operation in minutes
  int getAgeInMinutes() {
    return DateTime.now().difference(createdAt).inMinutes;
  }

  /// Gets the effective priority considering operation age
  /// Older operations get higher priority
  int getEffectivePriority() {
    final int ageBonus = (getAgeInMinutes() / 60).floor(); // +1 priority per hour
    return (priority.value - ageBonus).clamp(0, 10);
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        entityType,
        entityId,
        operation,
        payload,
        status,
        attempts,
        errorMessage,
        priority,
        createdAt,
        lastAttemptAt,
        completedAt,
      ];

  @override
  String toString() {
    return 'SyncOperation(id: $id, entityType: $entityType, '
        'operation: ${operation.name}, status: ${status.name}, '
        'attempts: $attempts, priority: ${priority.value})';
  }
}

/// Types of synchronization operations
enum SyncOperationType {
  /// Create a new entity on the server
  create,

  /// Update an existing entity on the server
  update,

  /// Delete an entity from the server
  delete,
}

/// Status of a synchronization operation
enum SyncOperationStatus {
  /// Operation is waiting to be processed
  pending,

  /// Operation is currently being processed
  processing,

  /// Operation completed successfully
  completed,

  /// Operation failed and needs retry
  failed,

  /// Operation was skipped (duplicate or invalid)
  skipped,
}

/// Priority levels for sync operations
enum SyncPriority {
  /// High priority (0) - DELETE operations, critical updates
  high(0),

  /// Normal priority (5) - CREATE and UPDATE operations
  normal(5),

  /// Low priority (10) - Non-critical operations
  low(10);

  const SyncPriority(this.value);

  /// Numeric value for priority ordering (lower = higher priority)
  final int value;
}
