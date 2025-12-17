import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/models/sync_progress.dart';
import 'package:waterflyiii/services/sync/sync_manager.dart';
import 'package:waterflyiii/services/sync/sync_statistics.dart';
import 'package:waterflyiii/services/app_mode/app_mode_manager.dart';

final Logger _log = Logger('SyncStatusProvider');

/// Provider for managing sync status and history.
///
/// Handles:
/// - Real-time sync status updates
/// - Sync history tracking
/// - Entity-specific statistics
/// - Conflict tracking
/// - Error tracking
///
/// Listens to sync events and updates UI automatically.
class SyncStatusProvider extends ChangeNotifier {
  SyncStatusProvider({
    required SyncManager syncManager,
    required SyncStatisticsService statisticsService,
    required AppDatabase database,
  }) : _syncManager = syncManager,
       _statisticsService = statisticsService,
       _database = database {
    _initialize();
  }

  final SyncManager _syncManager;
  final SyncStatisticsService _statisticsService;
  final AppDatabase _database;
  StreamSubscription<SyncEvent>? _syncEventSubscription;

  // Current sync state
  SyncProgress? _currentProgress;
  bool _isSyncing = false;
  String? _currentError;

  // Sync history (last 20 syncs)
  final List<SyncResult> _syncHistory = <SyncResult>[];
  static const int _maxHistorySize = 20;

  // Statistics
  SyncStatistics? _statistics;

  // Entity-specific stats
  final Map<String, EntitySyncStats> _entityStats = <String, EntitySyncStats>{};

  // Conflicts
  final List<dynamic> _unresolvedConflicts = <dynamic>[];

  // Errors
  final List<SyncError> _recentErrors = <SyncError>[];
  static const int _maxErrorsSize = 50;

  // Loading state
  bool _isLoading = false;

  // Getters
  SyncManager get syncManager => _syncManager;
  SyncProgress? get currentProgress => _currentProgress;
  bool get isSyncing => _isSyncing;
  String? get currentError => _currentError;
  List<SyncResult> get syncHistory => List.unmodifiable(_syncHistory);
  SyncStatistics? get statistics => _statistics;
  Map<String, EntitySyncStats> get entityStats =>
      Map.unmodifiable(_entityStats);
  List<dynamic> get unresolvedConflicts =>
      List.unmodifiable(_unresolvedConflicts);
  List<SyncError> get recentErrors => List.unmodifiable(_recentErrors);
  bool get isLoading => _isLoading;

  /// Initialize provider and start listening to sync events.
  void _initialize() {
    _log.info('Initializing SyncStatusProvider');

    // Set SyncManager in AppModeManager for auto-sync on reconnect
    AppModeManager().setSyncManager(_syncManager);
    _log.fine('Set SyncManager in AppModeManager for auto-sync on reconnect');

    // Load initial statistics
    _loadStatistics();

    // Listen to sync events
    _syncEventSubscription = _syncManager.watchEvents().listen(
      _handleSyncEvent,
      onError: (error, stackTrace) {
        _log.severe('Error in sync event stream', error, stackTrace);
        _currentError = error.toString();
        notifyListeners();
      },
    );
  }

  /// Load statistics from service.
  Future<void> _loadStatistics() async {
    try {
      _isLoading = true;
      notifyListeners();

      _statistics = await _statisticsService.getStatistics();
      _log.fine('Loaded statistics: $_statistics');
    } catch (e, stackTrace) {
      _log.severe('Failed to load statistics', e, stackTrace);
      _currentError = 'Failed to load statistics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handle sync events from SyncManager.
  void _handleSyncEvent(SyncEvent event) {
    _log.fine('Received sync event: $event');

    if (event is SyncStartedEvent) {
      _handleSyncStarted(event);
    } else if (event is SyncProgressEvent) {
      _handleSyncProgress(event);
    } else if (event is SyncCompletedEvent) {
      _handleSyncCompleted(event);
    } else if (event is SyncFailedEvent) {
      _handleSyncFailed(event);
    } else if (event is ConflictDetectedEvent) {
      _handleConflictDetected(event);
    } else if (event is ConflictResolvedEvent) {
      _handleConflictResolved(event);
    }
  }

  /// Handle sync started event.
  void _handleSyncStarted(SyncStartedEvent event) {
    _log.info('Sync started: ${event.totalOperations} operations');

    _isSyncing = true;
    _currentError = null;
    _currentProgress = SyncProgress.initial(
      totalOperations: event.totalOperations,
      startTime: event.timestamp,
    );

    notifyListeners();
  }

  /// Handle sync progress event.
  void _handleSyncProgress(SyncProgressEvent event) {
    _currentProgress = event.progress;
    notifyListeners();
  }

  /// Handle sync completed event.
  void _handleSyncCompleted(SyncCompletedEvent event) {
    _log.info('Sync completed: ${event.result}');

    _isSyncing = false;
    _currentProgress = null;

    // Add to history
    _syncHistory.insert(0, event.result);
    if (_syncHistory.length > _maxHistorySize) {
      _syncHistory.removeLast();
    }

    // Update entity stats
    _entityStats.clear();
    _entityStats.addAll(event.result.statsByEntity);

    // Reload statistics
    _loadStatistics();

    notifyListeners();
  }

  /// Handle sync failed event.
  void _handleSyncFailed(SyncFailedEvent event) {
    _log.warning('Sync failed: ${event.error}');

    _isSyncing = false;
    _currentError = event.error;
    _currentProgress = null;

    // Add to error list
    _recentErrors.insert(
      0,
      SyncError(
        message: event.error,
        timestamp: event.timestamp,
        exception: event.exception,
      ),
    );
    if (_recentErrors.length > _maxErrorsSize) {
      _recentErrors.removeLast();
    }

    notifyListeners();
  }

  /// Handle conflict detected event.
  void _handleConflictDetected(ConflictDetectedEvent event) {
    _log.info('Conflict detected: ${event.conflict}');

    _unresolvedConflicts.add(event.conflict);
    notifyListeners();
  }

  /// Handle conflict resolved event.
  void _handleConflictResolved(ConflictResolvedEvent event) {
    _log.info('Conflict resolved: ${event.conflictId}');

    // Remove from unresolved list
    _unresolvedConflicts.removeWhere(
      (conflict) => conflict.id == event.conflictId,
    );

    notifyListeners();
  }

  /// Refresh all data.
  Future<void> refresh() async {
    _log.info('Refreshing sync status');

    try {
      _isLoading = true;
      notifyListeners();

      await _loadStatistics();
      await _loadConflicts();
      await _loadRecentErrors();
    } catch (e, stackTrace) {
      _log.severe('Failed to refresh sync status', e, stackTrace);
      _currentError = 'Failed to refresh: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear sync history.
  void clearHistory() {
    _log.info('Clearing sync history');
    _syncHistory.clear();
    notifyListeners();
  }

  /// Clear error list.
  void clearErrors() {
    _log.info('Clearing error list');
    _recentErrors.clear();
    _currentError = null;
    notifyListeners();
  }

  /// Get sync history for a specific date range.
  List<SyncResult> getHistoryForDateRange(DateTime start, DateTime end) {
    return _syncHistory.where((SyncResult result) {
      return result.startTime.isAfter(start) && result.startTime.isBefore(end);
    }).toList();
  }

  /// Get entity stats for a specific entity type.
  EntitySyncStats? getEntityStats(String entityType) {
    return _entityStats[entityType];
  }

  /// Get total operations for all entity types.
  int get totalOperations {
    return _entityStats.values.fold(
      0,
      (int sum, EntitySyncStats stats) => sum + stats.total,
    );
  }

  /// Get total successful operations for all entity types.
  int get totalSuccessful {
    return _entityStats.values.fold(
      0,
      (int sum, EntitySyncStats stats) => sum + stats.successful,
    );
  }

  /// Get total failed operations for all entity types.
  int get totalFailed {
    return _entityStats.values.fold(
      0,
      (int sum, EntitySyncStats stats) => sum + stats.failed,
    );
  }

  /// Get total conflicts for all entity types.
  int get totalConflicts {
    return _entityStats.values.fold(
      0,
      (int sum, EntitySyncStats stats) => sum + stats.conflicts,
    );
  }

  /// Get overall success rate.
  double get overallSuccessRate {
    if (totalOperations == 0) return 100.0;
    return (totalSuccessful / totalOperations) * 100;
  }

  /// Load conflicts from database.
  Future<void> _loadConflicts() async {
    try {
      final List<ConflictEntity> conflicts =
          await (_database.select(_database.conflicts)
                ..where(($ConflictsTable tbl) => tbl.status.equals('pending'))
                ..orderBy(<OrderClauseGenerator<$ConflictsTable>>[
                  ($ConflictsTable tbl) => OrderingTerm.desc(tbl.detectedAt),
                ]))
              .get();

      _unresolvedConflicts.clear();
      _unresolvedConflicts.addAll(conflicts);

      _log.fine('Loaded ${conflicts.length} unresolved conflicts');
    } catch (e, stackTrace) {
      _log.warning('Failed to load conflicts', e, stackTrace);
    }
  }

  /// Load recent errors from database.
  Future<void> _loadRecentErrors() async {
    try {
      final List<ErrorLogEntity> errors =
          await (_database.select(_database.errorLog)
                ..where(($ErrorLogTable tbl) => tbl.resolved.equals(false))
                ..orderBy(<OrderClauseGenerator<$ErrorLogTable>>[
                  ($ErrorLogTable tbl) => OrderingTerm.desc(tbl.occurredAt),
                ])
                ..limit(_maxErrorsSize))
              .get();

      _recentErrors.clear();
      _recentErrors.addAll(
        errors.map(
          (ErrorLogEntity e) =>
              SyncError(message: e.errorMessage, timestamp: e.occurredAt),
        ),
      );

      _log.fine('Loaded ${errors.length} recent errors');
    } catch (e, stackTrace) {
      _log.warning('Failed to load errors', e, stackTrace);
    }
  }

  @override
  void dispose() {
    _log.info('Disposing SyncStatusProvider');
    _syncEventSubscription?.cancel();
    super.dispose();
  }
}

/// Represents a sync error.
class SyncError {
  final String message;
  final DateTime timestamp;
  final Exception? exception;

  const SyncError({
    required this.message,
    required this.timestamp,
    this.exception,
  });

  @override
  String toString() => 'SyncError($message at $timestamp)';
}
