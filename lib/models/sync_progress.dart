import 'package:equatable/equatable.dart';

/// Represents the current progress of a synchronization operation.
///
/// This model provides real-time updates about sync progress, including
/// operation counts, current operation details, and time estimates.
///
/// Example:
/// ```dart
/// syncManager.watchProgress().listen((progress) {
///   print('Sync progress: ${progress.percentage}%');
///   print('Current: ${progress.currentOperation}');
///   print('ETA: ${progress.estimatedTimeRemaining?.inSeconds}s');
/// });
/// ```
class SyncProgress extends Equatable {
  /// Total number of operations to sync
  final int totalOperations;

  /// Number of operations completed successfully
  final int completedOperations;

  /// Number of operations that failed
  final int failedOperations;

  /// Number of operations skipped (e.g., due to conflicts)
  final int skippedOperations;

  /// Current operation being processed (null if none)
  final String? currentOperation;

  /// Current operation entity type
  final String? currentEntityType;

  /// Current operation type (CREATE, UPDATE, DELETE)
  final String? currentOperationType;

  /// Percentage complete (0-100)
  final double percentage;

  /// Estimated time remaining
  final Duration? estimatedTimeRemaining;

  /// Time when sync started
  final DateTime startTime;

  /// Current sync phase
  final SyncPhase phase;

  /// List of errors encountered
  final List<String> errors;

  /// Number of conflicts detected
  final int conflictsDetected;

  /// Current throughput (operations per second)
  final double throughput;

  const SyncProgress({
    required this.totalOperations,
    required this.completedOperations,
    required this.failedOperations,
    required this.skippedOperations,
    this.currentOperation,
    this.currentEntityType,
    this.currentOperationType,
    required this.percentage,
    this.estimatedTimeRemaining,
    required this.startTime,
    required this.phase,
    required this.errors,
    required this.conflictsDetected,
    required this.throughput,
  });

  /// Number of operations remaining
  int get remainingOperations =>
      totalOperations - completedOperations - failedOperations - skippedOperations;

  /// Whether sync is complete
  bool get isComplete => remainingOperations == 0;

  /// Whether sync has errors
  bool get hasErrors => errors.isNotEmpty || failedOperations > 0;

  /// Whether sync has conflicts
  bool get hasConflicts => conflictsDetected > 0;

  /// Elapsed time since sync started
  Duration get elapsedTime => DateTime.now().difference(startTime);

  /// Create initial progress
  factory SyncProgress.initial({
    required int totalOperations,
    required DateTime startTime,
  }) {
    return SyncProgress(
      totalOperations: totalOperations,
      completedOperations: 0,
      failedOperations: 0,
      skippedOperations: 0,
      percentage: 0.0,
      startTime: startTime,
      phase: SyncPhase.preparing,
      errors: const [],
      conflictsDetected: 0,
      throughput: 0.0,
    );
  }

  /// Create a copy with updated fields
  SyncProgress copyWith({
    int? totalOperations,
    int? completedOperations,
    int? failedOperations,
    int? skippedOperations,
    String? currentOperation,
    String? currentEntityType,
    String? currentOperationType,
    double? percentage,
    Duration? estimatedTimeRemaining,
    DateTime? startTime,
    SyncPhase? phase,
    List<String>? errors,
    int? conflictsDetected,
    double? throughput,
  }) {
    return SyncProgress(
      totalOperations: totalOperations ?? this.totalOperations,
      completedOperations: completedOperations ?? this.completedOperations,
      failedOperations: failedOperations ?? this.failedOperations,
      skippedOperations: skippedOperations ?? this.skippedOperations,
      currentOperation: currentOperation ?? this.currentOperation,
      currentEntityType: currentEntityType ?? this.currentEntityType,
      currentOperationType: currentOperationType ?? this.currentOperationType,
      percentage: percentage ?? this.percentage,
      estimatedTimeRemaining: estimatedTimeRemaining ?? this.estimatedTimeRemaining,
      startTime: startTime ?? this.startTime,
      phase: phase ?? this.phase,
      errors: errors ?? this.errors,
      conflictsDetected: conflictsDetected ?? this.conflictsDetected,
      throughput: throughput ?? this.throughput,
    );
  }

  @override
  List<Object?> get props => [
        totalOperations,
        completedOperations,
        failedOperations,
        skippedOperations,
        currentOperation,
        currentEntityType,
        currentOperationType,
        percentage,
        estimatedTimeRemaining,
        startTime,
        phase,
        errors,
        conflictsDetected,
        throughput,
      ];

  @override
  String toString() {
    return 'SyncProgress(${percentage.toStringAsFixed(1)}%, '
        '$completedOperations/$totalOperations completed, '
        'phase: $phase, throughput: ${throughput.toStringAsFixed(2)} ops/s)';
  }
}

/// Phases of the synchronization process.
enum SyncPhase {
  /// Preparing for sync (checking connectivity, loading queue)
  preparing,

  /// Syncing operations to server
  syncing,

  /// Detecting conflicts
  detectingConflicts,

  /// Resolving conflicts
  resolvingConflicts,

  /// Pulling updates from server
  pulling,

  /// Finalizing sync (updating metadata, cleaning up)
  finalizing,

  /// Sync completed successfully
  completed,

  /// Sync failed
  failed,
}

/// Result of a synchronization operation.
class SyncResult extends Equatable {
  /// Whether sync completed successfully
  final bool success;

  /// Total number of operations processed
  final int totalOperations;

  /// Number of operations synced successfully
  final int successfulOperations;

  /// Number of operations that failed
  final int failedOperations;

  /// Number of operations skipped
  final int skippedOperations;

  /// Number of conflicts detected
  final int conflictsDetected;

  /// Number of conflicts resolved
  final int conflictsResolved;

  /// Time when sync started
  final DateTime startTime;

  /// Time when sync ended
  final DateTime endTime;

  /// List of errors encountered
  final List<String> errors;

  /// Statistics by entity type
  final Map<String, EntitySyncStats> statsByEntity;

  /// Error message if sync failed
  final String? errorMessage;

  const SyncResult({
    required this.success,
    required this.totalOperations,
    required this.successfulOperations,
    required this.failedOperations,
    required this.skippedOperations,
    required this.conflictsDetected,
    required this.conflictsResolved,
    required this.startTime,
    required this.endTime,
    required this.errors,
    required this.statsByEntity,
    this.errorMessage,
  });

  /// Duration of the sync operation
  Duration get duration => endTime.difference(startTime);

  /// Success rate (successful / total)
  double get successRate {
    if (totalOperations == 0) return 1.0;
    return successfulOperations / totalOperations;
  }

  /// Throughput (operations per second)
  double get throughput {
    final seconds = duration.inSeconds;
    if (seconds == 0) return 0.0;
    return totalOperations / seconds;
  }

  /// Whether there are unresolved conflicts
  bool get hasUnresolvedConflicts => conflictsDetected > conflictsResolved;

  /// Create a successful result
  factory SyncResult.success({
    required int totalOperations,
    required int successfulOperations,
    required int failedOperations,
    required int skippedOperations,
    required int conflictsDetected,
    required int conflictsResolved,
    required DateTime startTime,
    required DateTime endTime,
    required Map<String, EntitySyncStats> statsByEntity,
    List<String> errors = const [],
  }) {
    return SyncResult(
      success: true,
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      failedOperations: failedOperations,
      skippedOperations: skippedOperations,
      conflictsDetected: conflictsDetected,
      conflictsResolved: conflictsResolved,
      startTime: startTime,
      endTime: endTime,
      errors: errors,
      statsByEntity: statsByEntity,
    );
  }

  /// Create a failed result
  factory SyncResult.failure({
    required String errorMessage,
    required int totalOperations,
    required int successfulOperations,
    required int failedOperations,
    required DateTime startTime,
    required DateTime endTime,
    List<String> errors = const [],
  }) {
    return SyncResult(
      success: false,
      totalOperations: totalOperations,
      successfulOperations: successfulOperations,
      failedOperations: failedOperations,
      skippedOperations: 0,
      conflictsDetected: 0,
      conflictsResolved: 0,
      startTime: startTime,
      endTime: endTime,
      errors: errors,
      statsByEntity: const {},
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        success,
        totalOperations,
        successfulOperations,
        failedOperations,
        skippedOperations,
        conflictsDetected,
        conflictsResolved,
        startTime,
        endTime,
        errors,
        statsByEntity,
        errorMessage,
      ];

  @override
  String toString() {
    return 'SyncResult(success: $success, $successfulOperations/$totalOperations synced, '
        'duration: ${duration.inSeconds}s, throughput: ${throughput.toStringAsFixed(2)} ops/s)';
  }
}

/// Statistics for a specific entity type during sync.
class EntitySyncStats extends Equatable {
  /// Entity type
  final String entityType;

  /// Number of CREATE operations
  final int creates;

  /// Number of UPDATE operations
  final int updates;

  /// Number of DELETE operations
  final int deletes;

  /// Number of successful operations
  final int successful;

  /// Number of failed operations
  final int failed;

  /// Number of conflicts
  final int conflicts;

  const EntitySyncStats({
    required this.entityType,
    required this.creates,
    required this.updates,
    required this.deletes,
    required this.successful,
    required this.failed,
    required this.conflicts,
  });

  /// Total operations for this entity type
  int get total => creates + updates + deletes;

  /// Success rate for this entity type
  double get successRate {
    if (total == 0) return 1.0;
    return successful / total;
  }

  @override
  List<Object?> get props => [
        entityType,
        creates,
        updates,
        deletes,
        successful,
        failed,
        conflicts,
      ];

  @override
  String toString() {
    return 'EntitySyncStats($entityType: $successful/$total successful, '
        'C:$creates U:$updates D:$deletes, conflicts:$conflicts)';
  }
}

/// Events emitted during synchronization.
abstract class SyncEvent extends Equatable {
  /// Timestamp when event occurred
  final DateTime timestamp;

  const SyncEvent({required this.timestamp});

  @override
  List<Object?> get props => [timestamp];
}

/// Sync started event
class SyncStartedEvent extends SyncEvent {
  /// Number of operations to sync
  final int totalOperations;

  const SyncStartedEvent({
    required this.totalOperations,
    required super.timestamp,
  });

  @override
  List<Object?> get props => [...super.props, totalOperations];

  @override
  String toString() => 'SyncStartedEvent($totalOperations operations)';
}

/// Sync progress event
class SyncProgressEvent extends SyncEvent {
  /// Current progress
  final SyncProgress progress;

  const SyncProgressEvent({
    required this.progress,
    required super.timestamp,
  });

  @override
  List<Object?> get props => [...super.props, progress];

  @override
  String toString() => 'SyncProgressEvent(${progress.percentage}%)';
}

/// Sync completed event
class SyncCompletedEvent extends SyncEvent {
  /// Sync result
  final SyncResult result;

  const SyncCompletedEvent({
    required this.result,
    required super.timestamp,
  });

  @override
  List<Object?> get props => [...super.props, result];

  @override
  String toString() => 'SyncCompletedEvent(success: ${result.success})';
}

/// Sync failed event
class SyncFailedEvent extends SyncEvent {
  /// Error message
  final String error;

  /// Exception that caused the failure
  final Exception? exception;

  const SyncFailedEvent({
    required this.error,
    this.exception,
    required super.timestamp,
  });

  @override
  List<Object?> get props => [...super.props, error, exception];

  @override
  String toString() => 'SyncFailedEvent($error)';
}

/// Conflict detected event
class ConflictDetectedEvent extends SyncEvent {
  /// The conflict that was detected
  final dynamic conflict;

  const ConflictDetectedEvent({
    required this.conflict,
    required super.timestamp,
  });

  @override
  List<Object?> get props => [...super.props, conflict];

  @override
  String toString() => 'ConflictDetectedEvent($conflict)';
}

/// Conflict resolved event
class ConflictResolvedEvent extends SyncEvent {
  /// ID of the conflict that was resolved
  final String conflictId;

  /// Strategy used for resolution
  final String strategy;

  const ConflictResolvedEvent({
    required this.conflictId,
    required this.strategy,
    required super.timestamp,
  });

  @override
  List<Object?> get props => [...super.props, conflictId, strategy];

  @override
  String toString() => 'ConflictResolvedEvent($conflictId, strategy: $strategy)';
}
