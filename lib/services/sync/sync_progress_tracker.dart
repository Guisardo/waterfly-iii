import 'dart:async';
import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

import '../../models/sync_progress.dart';

/// Service for tracking and reporting synchronization progress.
///
/// Provides real-time progress updates through streams and calculates
/// statistics like completion percentage, throughput, and ETA.
///
/// Example:
/// ```dart
/// final tracker = SyncProgressTracker();
///
/// // Listen to progress updates
/// tracker.watchProgress().listen((progress) {
///   print('Progress: ${progress.percentage}%');
///   print('ETA: ${progress.estimatedTimeRemaining}');
/// });
///
/// // Start tracking
/// tracker.start(totalOperations: 100);
///
/// // Update progress
/// tracker.incrementCompleted();
/// tracker.incrementFailed();
///
/// // Complete tracking
/// final result = tracker.complete();
/// ```
class SyncProgressTracker {
  final Logger _logger = Logger('SyncProgressTracker');

  /// Progress stream controller
  final _progressController = BehaviorSubject<SyncProgress>();

  /// Event stream controller
  final _eventController = BehaviorSubject<SyncEvent>();

  /// Current progress state
  SyncProgress? _currentProgress;

  /// Start time of current sync
  DateTime? _startTime;

  /// Completed operation timestamps for throughput calculation
  final List<DateTime> _completionTimestamps = [];

  /// Maximum timestamps to keep for throughput calculation
  static const int _maxTimestamps = 100;

  /// Watch progress updates.
  ///
  /// Returns:
  ///   Stream of SyncProgress updates
  Stream<SyncProgress> watchProgress() => _progressController.stream;

  /// Watch sync events.
  ///
  /// Returns:
  ///   Stream of SyncEvent updates
  Stream<SyncEvent> watchEvents() => _eventController.stream;

  /// Get current progress.
  SyncProgress? get currentProgress => _currentProgress;

  /// Check if sync is in progress.
  bool get isInProgress => _currentProgress != null;

  /// Start tracking a new sync operation.
  ///
  /// Args:
  ///   totalOperations: Total number of operations to sync
  ///   phase: Initial sync phase
  void start({
    required int totalOperations,
    SyncPhase phase = SyncPhase.preparing,
  }) {
    _logger.info('Starting sync progress tracking: $totalOperations operations');

    _startTime = DateTime.now();
    _completionTimestamps.clear();

    _currentProgress = SyncProgress(
      totalOperations: totalOperations,
      completedOperations: 0,
      failedOperations: 0,
      skippedOperations: 0,
      currentOperation: null,
      percentage: 0.0,
      estimatedTimeRemaining: null,
      startTime: _startTime!,
      phase: phase,
      errors: const [],
      conflictsDetected: 0,
      throughput: 0.0,
    );

    _emitProgress();
    _emitEvent(SyncStartedEvent(
      timestamp: DateTime.now(),
      totalOperations: totalOperations,
    ));
  }

  /// Update current phase.
  void updatePhase(SyncPhase phase) {
    if (_currentProgress == null) return;

    _logger.fine('Sync phase changed to $phase');

    _currentProgress = _currentProgress!.copyWith(phase: phase);
    _emitProgress();
  }

  /// Update current operation being processed.
  void updateCurrentOperation(String? operation) {
    if (_currentProgress == null) return;

    _currentProgress = _currentProgress!.copyWith(currentOperation: operation);
    _emitProgress();
  }

  /// Increment completed operations count.
  void incrementCompleted({String? operationId}) {
    if (_currentProgress == null) return;

    _completionTimestamps.add(DateTime.now());
    if (_completionTimestamps.length > _maxTimestamps) {
      _completionTimestamps.removeAt(0);
    }

    _currentProgress = _currentProgress!.copyWith(
      completedOperations: _currentProgress!.completedOperations + 1,
    );

    _updateCalculatedFields();
    _emitProgress();
  }

  /// Increment failed operations count.
  void incrementFailed({String? operationId, String? error}) {
    if (_currentProgress == null) return;

    final errors = List<String>.from(_currentProgress!.errors);
    if (error != null) {
      errors.add(error);
    }

    _currentProgress = _currentProgress!.copyWith(
      failedOperations: _currentProgress!.failedOperations + 1,
      errors: errors,
    );

    _updateCalculatedFields();
    _emitProgress();
  }

  /// Increment skipped operations count.
  void incrementSkipped({String? operationId}) {
    if (_currentProgress == null) return;

    _currentProgress = _currentProgress!.copyWith(
      skippedOperations: _currentProgress!.skippedOperations + 1,
    );

    _updateCalculatedFields();
    _emitProgress();
  }

  /// Increment conflicts detected count.
  void incrementConflicts({String? conflictId}) {
    if (_currentProgress == null) return;

    _currentProgress = _currentProgress!.copyWith(
      conflictsDetected: _currentProgress!.conflictsDetected + 1,
    );

    _emitProgress();

    if (conflictId != null) {
      _emitEvent(ConflictDetectedEvent(
        timestamp: DateTime.now(),
        conflict: conflictId,
      ));
    }
  }

  /// Add multiple completed operations at once.
  void addCompleted(int count) {
    if (_currentProgress == null || count <= 0) return;

    final now = DateTime.now();
    for (int i = 0; i < count; i++) {
      _completionTimestamps.add(now);
    }

    while (_completionTimestamps.length > _maxTimestamps) {
      _completionTimestamps.removeAt(0);
    }

    _currentProgress = _currentProgress!.copyWith(
      completedOperations: _currentProgress!.completedOperations + count,
    );

    _updateCalculatedFields();
    _emitProgress();
  }

  /// Update calculated fields (percentage, ETA, throughput).
  void _updateCalculatedFields() {
    if (_currentProgress == null || _startTime == null) return;

    final total = _currentProgress!.totalOperations;
    final completed = _currentProgress!.completedOperations;
    final failed = _currentProgress!.failedOperations;
    final skipped = _currentProgress!.skippedOperations;
    final processed = completed + failed + skipped;

    // Calculate percentage
    final percentage = total > 0 ? (processed / total) * 100 : 0.0;

    // Calculate throughput (operations per second)
    final throughput = _calculateThroughput();

    // Calculate ETA
    final eta = _calculateETA(total, processed, throughput);

    _currentProgress = _currentProgress!.copyWith(
      percentage: percentage,
      throughput: throughput,
      estimatedTimeRemaining: eta,
    );
  }

  /// Calculate current throughput (operations per second).
  double _calculateThroughput() {
    if (_completionTimestamps.isEmpty) return 0.0;

    // Use recent timestamps for more accurate throughput
    final recentCount = _completionTimestamps.length;
    if (recentCount < 2) return 0.0;

    final firstTimestamp = _completionTimestamps.first;
    final lastTimestamp = _completionTimestamps.last;
    final duration = lastTimestamp.difference(firstTimestamp);

    if (duration.inMilliseconds == 0) return 0.0;

    return recentCount / (duration.inMilliseconds / 1000.0);
  }

  /// Calculate estimated time remaining.
  Duration? _calculateETA(int total, int processed, double throughput) {
    if (throughput <= 0 || processed >= total) return null;

    final remaining = total - processed;
    final secondsRemaining = remaining / throughput;

    return Duration(seconds: secondsRemaining.round());
  }

  /// Complete the sync operation.
  ///
  /// Args:
  ///   success: Whether sync completed successfully
  ///   entityStats: Per-entity statistics
  ///
  /// Returns:
  ///   Final SyncResult
  SyncResult complete({
    bool success = true,
    Map<String, EntitySyncStats>? entityStats,
  }) {
    if (_currentProgress == null || _startTime == null) {
      throw StateError('No sync in progress');
    }

    _logger.info('Completing sync progress tracking');

    final endTime = DateTime.now();
    // ignore: unused_local_variable
    final duration = endTime.difference(_startTime!);

    final result = SyncResult(
      success: success,
      totalOperations: _currentProgress!.totalOperations,
      successfulOperations: _currentProgress!.completedOperations,
      failedOperations: _currentProgress!.failedOperations,
      skippedOperations: _currentProgress!.skippedOperations,
      conflictsDetected: _currentProgress!.conflictsDetected,
      conflictsResolved: 0,
      startTime: _startTime!,
      endTime: endTime,
      errors: _currentProgress!.errors,
      statsByEntity: entityStats ?? {},
    );

    // Update phase
    _currentProgress = _currentProgress!.copyWith(
      phase: success ? SyncPhase.completed : SyncPhase.failed,
    );
    _emitProgress();

    // Emit completion event
    if (success) {
      _emitEvent(SyncCompletedEvent(
        timestamp: DateTime.now(),
        result: result,
      ));
    } else {
      _emitEvent(SyncFailedEvent(
        timestamp: DateTime.now(),
        error: 'Sync failed',
      ));
    }

    // Clear current progress
    _currentProgress = null;
    _startTime = null;
    _completionTimestamps.clear();

    return result;
  }

  /// Calculate success rate.
  // ignore: unused_element
  double _calculateSuccessRate() {
    if (_currentProgress == null) return 0.0;

    final completed = _currentProgress!.completedOperations;
    final failed = _currentProgress!.failedOperations;
    final total = completed + failed;

    return total > 0 ? completed / total : 0.0;
  }

  /// Emit progress update.
  void _emitProgress() {
    if (_currentProgress != null) {
      _progressController.add(_currentProgress!);
    }
  }

  /// Emit sync event.
  void _emitEvent(SyncEvent event) {
    _eventController.add(event);

    // Also emit as progress event if applicable
    if (event is SyncProgressEvent) {
      // Already handled by _emitProgress
    }
  }

  /// Cancel current sync.
  void cancel() {
    if (_currentProgress == null) return;

    _logger.warning('Sync progress tracking cancelled');

    _currentProgress = _currentProgress!.copyWith(
      phase: SyncPhase.failed,
    );
    _emitProgress();

    _emitEvent(SyncFailedEvent(
      timestamp: DateTime.now(),
      error: 'Sync cancelled by user',
    ));

    _currentProgress = null;
    _startTime = null;
    _completionTimestamps.clear();
  }

  /// Dispose resources.
  void dispose() {
    _logger.fine('Disposing sync progress tracker');
    _progressController.close();
    _eventController.close();
  }
}
