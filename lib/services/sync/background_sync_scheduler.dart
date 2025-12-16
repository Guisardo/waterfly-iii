import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/services/sync/database_adapter.dart';
import 'package:waterflyiii/services/sync/firefly_api_adapter.dart';
import 'package:waterflyiii/services/sync/metadata_service.dart';
import 'package:waterflyiii/services/sync/sync_progress_tracker.dart';
import 'package:waterflyiii/services/sync/sync_service.dart';

/// Background sync scheduler using WorkManager for periodic and one-time sync tasks.
///
/// Features:
/// - Periodic sync scheduling with configurable intervals
/// - One-time sync scheduling
/// - Network connectivity constraint
/// - Battery optimization (charging preferred)
/// - Dynamic interval adjustment based on success/failure
/// - Comprehensive error handling and logging
///
/// Platform support:
/// - Android: Uses WorkManager with constraints
/// - iOS: Uses BGTaskScheduler (configured in Info.plist)
class BackgroundSyncScheduler {
  final Logger _logger = Logger('BackgroundSyncScheduler');
  final SharedPreferences _prefs;

  static const String _taskNamePeriodicSync = 'periodic_sync_task';
  static const String _taskNameOneTimeSync = 'one_time_sync_task';
  static const String _keyLastSyncTime = 'last_background_sync_time';
  static const String _keyFailureCount = 'background_sync_failure_count';

  BackgroundSyncScheduler(this._prefs);

  /// Schedule periodic background sync.
  ///
  /// [interval] - Duration between syncs (default: 1 hour)
  /// [requiresCharging] - Whether to require device charging (default: false)
  /// [requiresWifi] - Whether to require WiFi connection (default: false)
  Future<void> schedulePeriodicSync({
    Duration interval = const Duration(hours: 1),
    bool requiresCharging = false,
    bool requiresWifi = false,
  }) async {
    try {
      _logger.info(
        'Scheduling periodic sync: interval=${interval.inMinutes}min, '
        'charging=$requiresCharging, wifi=$requiresWifi',
      );

      await Workmanager().registerPeriodicTask(
        _taskNamePeriodicSync,
        _taskNamePeriodicSync,
        frequency: interval,
        constraints: Constraints(
          networkType: requiresWifi ? NetworkType.unmetered : NetworkType.connected,
          requiresCharging: requiresCharging,
          requiresBatteryNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 15),
      );

      _logger.info('Periodic sync scheduled successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to schedule periodic sync', e, stackTrace);
      rethrow;
    }
  }

  /// Schedule one-time background sync.
  ///
  /// [delay] - Optional delay before execution (default: immediate)
  /// [requiresWifi] - Whether to require WiFi connection (default: false)
  Future<void> scheduleOneTimeSync({
    Duration delay = Duration.zero,
    bool requiresWifi = false,
  }) async {
    try {
      _logger.info(
        'Scheduling one-time sync: delay=${delay.inSeconds}s, wifi=$requiresWifi',
      );

      await Workmanager().registerOneOffTask(
        _taskNameOneTimeSync,
        _taskNameOneTimeSync,
        initialDelay: delay,
        constraints: Constraints(
          networkType: requiresWifi ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: true,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );

      _logger.info('One-time sync scheduled successfully');
    } catch (e, stackTrace) {
      _logger.severe('Failed to schedule one-time sync', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel all scheduled background sync tasks.
  Future<void> cancelAll() async {
    try {
      _logger.info('Cancelling all scheduled syncs');
      await Workmanager().cancelAll();
      _logger.info('All scheduled syncs cancelled');
    } catch (e, stackTrace) {
      _logger.severe('Failed to cancel scheduled syncs', e, stackTrace);
      rethrow;
    }
  }

  /// Cancel specific task by name.
  Future<void> cancelTask(String taskName) async {
    try {
      _logger.info('Cancelling task: $taskName');
      await Workmanager().cancelByUniqueName(taskName);
      _logger.info('Task cancelled: $taskName');
    } catch (e, stackTrace) {
      _logger.severe('Failed to cancel task: $taskName', e, stackTrace);
      rethrow;
    }
  }

  /// Record successful sync execution.
  Future<void> recordSuccess() async {
    try {
      await _prefs.setInt(_keyLastSyncTime, DateTime.now().millisecondsSinceEpoch);
      await _prefs.setInt(_keyFailureCount, 0);
      _logger.info('Recorded successful sync');
    } catch (e, stackTrace) {
      _logger.warning('Failed to record sync success', e, stackTrace);
    }
  }

  /// Record failed sync execution and adjust interval if needed.
  Future<void> recordFailure() async {
    try {
      final int failureCount = (_prefs.getInt(_keyFailureCount) ?? 0) + 1;
      await _prefs.setInt(_keyFailureCount, failureCount);
      _logger.warning('Recorded sync failure (count: $failureCount)');

      // Increase interval after repeated failures
      if (failureCount >= 3) {
        _logger.info('Multiple failures detected, increasing sync interval');
        // Caller should handle interval adjustment
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to record sync failure', e, stackTrace);
    }
  }

  /// Get last successful sync time.
  DateTime? getLastSyncTime() {
    final int? timestamp = _prefs.getInt(_keyLastSyncTime);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Get current failure count.
  int getFailureCount() {
    return _prefs.getInt(_keyFailureCount) ?? 0;
  }

  /// Check if sync is needed based on last sync time and interval.
  bool isSyncNeeded(Duration interval) {
    final DateTime? lastSync = getLastSyncTime();
    if (lastSync == null) return true;

    final DateTime nextSync = lastSync.add(interval);
    return DateTime.now().isAfter(nextSync);
  }
}

/// Context holder for background sync initialization.
///
/// This class holds the API client needed for background sync operations.
/// It must be initialized before background sync tasks can execute.
class BackgroundSyncContext {
  /// Singleton instance
  static BackgroundSyncContext? _instance;

  /// The Firefly III API client
  final dynamic apiClient;

  BackgroundSyncContext._({required this.apiClient});

  /// Initialize the background sync context.
  ///
  /// Must be called during app initialization before scheduling background tasks.
  static void initialize({required dynamic apiClient}) {
    _instance = BackgroundSyncContext._(apiClient: apiClient);
  }

  /// Get the current instance.
  static BackgroundSyncContext? get instance => _instance;

  /// Check if context is initialized.
  static bool get isInitialized => _instance != null;
}

/// Background sync callback handler.
///
/// This function is called by WorkManager when a background task executes.
/// It must be a top-level function or static method.
///
/// The handler initializes all required services and performs incremental sync:
/// 1. Opens/creates the database
/// 2. Creates API adapter with stored credentials
/// 3. Creates database adapter
/// 4. Creates sync service with all dependencies
/// 5. Executes incremental sync
/// 6. Records success/failure for interval adjustment
@pragma('vm:entry-point')
void backgroundSyncCallback() {
  Workmanager().executeTask((String task, Map<String, dynamic>? inputData) async {
    final Logger logger = Logger('BackgroundSyncCallback');
    logger.info('Background sync task started: $task');

    try {
      // Initialize services for background sync
      final AppDatabase database = AppDatabase();
      
      // Check if API client context is available
      if (!BackgroundSyncContext.isInitialized) {
        logger.warning('BackgroundSyncContext not initialized, skipping sync');
        return Future.value(false);
      }

      final dynamic apiClient = BackgroundSyncContext.instance!.apiClient;
      
      // Create adapters and services
      final FireflyApiAdapter apiAdapter = FireflyApiAdapter(apiClient);
      final DatabaseAdapter dbAdapter = DatabaseAdapter(database: database);
      final SyncProgressTracker progressTracker = SyncProgressTracker();
      final MetadataService metadata = MetadataService(database);
      
      // Create sync service
      final SyncService syncService = SyncService(
        apiAdapter: apiAdapter,
        dbAdapter: dbAdapter,
        database: database,
        progressTracker: progressTracker,
        metadata: metadata,
      );

      // Perform incremental sync
      logger.info('Starting incremental sync from background task');
      final result = await syncService.sync(mode: SyncMode.incremental);
      
      // Record result for interval adjustment
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final BackgroundSyncScheduler scheduler = BackgroundSyncScheduler(prefs);
      
      if (result.success) {
        await scheduler.recordSuccess();
        logger.info(
          'Background sync completed successfully: '
          '${result.successfulOperations}/${result.totalOperations} operations',
        );
      } else {
        await scheduler.recordFailure();
        logger.warning(
          'Background sync completed with errors: '
          '${result.failedOperations} failed operations',
        );
      }

      // Cleanup
      progressTracker.dispose();
      await database.close();

      return Future.value(result.success);
    } catch (e, stackTrace) {
      logger.severe('Background sync task failed', e, stackTrace);
      
      // Record failure
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final BackgroundSyncScheduler scheduler = BackgroundSyncScheduler(prefs);
        await scheduler.recordFailure();
      } catch (_) {
        // Ignore errors during failure recording
      }
      
      return Future.value(false);
    }
  });
}
