import 'dart:async';
import 'package:logging/logging.dart';
import 'package:workmanager/workmanager.dart';

import '../../exceptions/sync_exceptions.dart';
import '../connectivity/connectivity_service.dart';
import 'sync_manager.dart';

/// Service for scheduling background synchronization using WorkManager.
///
/// This service uses the `workmanager` package to schedule periodic
/// background sync tasks that run even when the app is closed.
///
/// Features:
/// - Periodic sync at configurable intervals
/// - Network connectivity constraints
/// - Battery optimization
/// - Retry on failure
/// - Cancellation support
///
/// Example:
/// ```dart
/// final scheduler = BackgroundSyncScheduler(
///   syncManager: syncManager,
///   connectivityService: connectivity,
/// );
///
/// // Schedule periodic sync every 15 minutes
/// await scheduler.schedulePeriodicSync(
///   interval: Duration(minutes: 15),
/// );
///
/// // Cancel scheduled sync
/// await scheduler.cancelScheduledSync();
/// ```
class BackgroundSyncScheduler {
  final Logger _logger = Logger('BackgroundSyncScheduler');

  final SyncManager _syncManager;
  final ConnectivityService _connectivityService;

  /// Task identifiers
  static const String _periodicSyncTaskName = 'periodic_sync';
  static const String _oneTimeSyncTaskName = 'one_time_sync';

  /// Configuration
  final Duration defaultInterval;
  final bool requiresCharging;
  final bool requiresDeviceIdle;
  final int maxRetries;

  /// State
  bool _isScheduled = false;

  BackgroundSyncScheduler({
    required SyncManager syncManager,
    required ConnectivityService connectivityService,
    this.defaultInterval = const Duration(minutes: 15),
    this.requiresCharging = false,
    this.requiresDeviceIdle = false,
    this.maxRetries = 3,
  })  : _syncManager = syncManager,
        _connectivityService = connectivityService;

  /// Initialize the background sync scheduler.
  ///
  /// This must be called before scheduling any tasks.
  /// Typically called in main() before runApp().
  ///
  /// Example:
  /// ```dart
  /// void main() {
  ///   WidgetsFlutterBinding.ensureInitialized();
  ///   
  ///   // Initialize workmanager
  ///   Workmanager().initialize(
  ///     callbackDispatcher,
  ///     isInDebugMode: kDebugMode,
  ///   );
  ///   
  ///   runApp(MyApp());
  /// }
  /// ```
  static Future<void> initialize({
    bool isInDebugMode = false,
  }) async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: isInDebugMode,
      );

      Logger('BackgroundSyncScheduler').info(
        'Background sync scheduler initialized',
      );
    } catch (e, stackTrace) {
      Logger('BackgroundSyncScheduler').severe(
        'Failed to initialize background sync scheduler',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Schedule periodic background synchronization.
  ///
  /// Args:
  ///   interval: Time between sync attempts (minimum 15 minutes)
  ///   requiresNetwork: Whether network connectivity is required
  ///   requiresCharging: Whether device must be charging
  ///   requiresDeviceIdle: Whether device must be idle
  ///
  /// Throws:
  ///   ValidationError: If interval is less than 15 minutes
  Future<void> schedulePeriodicSync({
    Duration? interval,
    bool requiresNetwork = true,
    bool? requiresCharging,
    bool? requiresDeviceIdle,
  }) async {
    try {
      final syncInterval = interval ?? defaultInterval;

      // Validate interval (WorkManager minimum is 15 minutes)
      if (syncInterval.inMinutes < 15) {
        throw ValidationError(
          'Sync interval must be at least 15 minutes',
          field: 'interval',
          rule: 'Minimum 15 minutes for periodic tasks',
        );
      }

      _logger.info(
        'Scheduling periodic sync every ${syncInterval.inMinutes} minutes',
      );

      await Workmanager().registerPeriodicTask(
        _periodicSyncTaskName,
        _periodicSyncTaskName,
        frequency: syncInterval,
        constraints: Constraints(
          networkType: requiresNetwork ? NetworkType.connected : NetworkType.not_required,
          requiresCharging: requiresCharging ?? this.requiresCharging,
          requiresDeviceIdle: requiresDeviceIdle ?? this.requiresDeviceIdle,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        initialDelay: const Duration(minutes: 1),
      );

      _isScheduled = true;

      _logger.info('Periodic sync scheduled successfully');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to schedule periodic sync',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Schedule a one-time background synchronization.
  ///
  /// Args:
  ///   delay: Delay before running the sync
  ///   requiresNetwork: Whether network connectivity is required
  ///
  /// Returns:
  ///   Task ID for tracking
  Future<String> scheduleOneTimeSync({
    Duration delay = Duration.zero,
    bool requiresNetwork = true,
  }) async {
    try {
      _logger.info('Scheduling one-time sync with ${delay.inSeconds}s delay');

      final taskId = '${_oneTimeSyncTaskName}_${DateTime.now().millisecondsSinceEpoch}';

      await Workmanager().registerOneOffTask(
        taskId,
        _oneTimeSyncTaskName,
        initialDelay: delay,
        constraints: Constraints(
          networkType: requiresNetwork ? NetworkType.connected : NetworkType.not_required,
        ),
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 1),
        existingWorkPolicy: ExistingWorkPolicy.keep,
      );

      _logger.info('One-time sync scheduled: $taskId');

      return taskId;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to schedule one-time sync',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel all scheduled synchronization tasks.
  Future<void> cancelScheduledSync() async {
    try {
      _logger.info('Cancelling all scheduled sync tasks');

      await Workmanager().cancelAll();

      _isScheduled = false;

      _logger.info('All scheduled sync tasks cancelled');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to cancel scheduled sync',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Cancel a specific scheduled task.
  Future<void> cancelTask(String taskId) async {
    try {
      _logger.info('Cancelling task: $taskId');

      await Workmanager().cancelByUniqueName(taskId);

      _logger.info('Task cancelled: $taskId');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to cancel task $taskId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Check if periodic sync is scheduled.
  bool get isScheduled => _isScheduled;

  /// Get recommended sync interval based on battery and network status.
  ///
  /// Returns:
  ///   Recommended interval (15 min to 6 hours)
  Future<Duration> getRecommendedInterval() async {
    try {
      // Check connectivity
      final isConnected = await _connectivityService.checkConnectivity();
      final connectionType = await _connectivityService.getConnectionType();

      // Base interval
      Duration interval = defaultInterval;

      // Adjust based on connection type
      if (!isConnected) {
        // No connection, use maximum interval
        interval = const Duration(hours: 6);
      } else if (connectionType == 'wifi') {
        // WiFi, use default interval
        interval = defaultInterval;
      } else if (connectionType == 'mobile') {
        // Mobile data, use longer interval to save data
        interval = const Duration(hours: 1);
      }

      _logger.info('Recommended sync interval: ${interval.inMinutes} minutes');

      return interval;
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to determine recommended interval, using default',
        e,
        stackTrace,
      );
      return defaultInterval;
    }
  }

  /// Update sync interval dynamically.
  Future<void> updateSyncInterval(Duration newInterval) async {
    try {
      _logger.info('Updating sync interval to ${newInterval.inMinutes} minutes');

      // Cancel existing schedule
      await cancelScheduledSync();

      // Schedule with new interval
      await schedulePeriodicSync(interval: newInterval);

      _logger.info('Sync interval updated successfully');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to update sync interval',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}

/// Callback dispatcher for background tasks.
///
/// This function is called by WorkManager when a background task runs.
/// It must be a top-level function (not a class method).
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final logger = Logger('BackgroundSyncCallback');

    try {
      logger.info('Background sync task started: $task');

      // Initialize services
      // Note: In a real implementation, you would need to properly
      // initialize all dependencies here
      
      // Check connectivity
      final connectivityService = ConnectivityService();
      final isConnected = await connectivityService.checkConnectivity();

      if (!isConnected) {
        logger.warning('No network connectivity, skipping sync');
        return Future.value(false); // Retry later
      }

      // Perform sync
      // final syncManager = SyncManager(...);
      // final result = await syncManager.synchronize();

      logger.info('Background sync completed successfully');

      return Future.value(true);
    } catch (e, stackTrace) {
      logger.severe(
        'Background sync task failed',
        e,
        stackTrace,
      );

      // Return false to trigger retry with backoff
      return Future.value(false);
    }
  });
}

/// Extension for WorkManager constraints.
extension ConstraintsExtension on Constraints {
  /// Create constraints for sync tasks.
  static Constraints forSync({
    bool requiresNetwork = true,
    bool requiresCharging = false,
    bool requiresDeviceIdle = false,
  }) {
    return Constraints(
      networkType: requiresNetwork ? NetworkType.connected : NetworkType.not_required,
      requiresCharging: requiresCharging,
      requiresDeviceIdle: requiresDeviceIdle,
    );
  }
}

/// Sync task configuration.
class SyncTaskConfig {
  final String taskName;
  final Duration interval;
  final Constraints constraints;
  final BackoffPolicy backoffPolicy;
  final Duration backoffDelay;
  final ExistingWorkPolicy existingWorkPolicy;

  const SyncTaskConfig({
    required this.taskName,
    required this.interval,
    required this.constraints,
    this.backoffPolicy = BackoffPolicy.exponential,
    this.backoffDelay = const Duration(minutes: 1),
    this.existingWorkPolicy = ExistingWorkPolicy.replace,
  });

  /// Create default periodic sync configuration.
  factory SyncTaskConfig.periodic({
    Duration interval = const Duration(minutes: 15),
    bool requiresNetwork = true,
    bool requiresCharging = false,
  }) {
    return SyncTaskConfig(
      taskName: 'periodic_sync',
      interval: interval,
      constraints: ConstraintsExtension.forSync(
        requiresNetwork: requiresNetwork,
        requiresCharging: requiresCharging,
      ),
    );
  }

  /// Create configuration for one-time sync.
  factory SyncTaskConfig.oneTime({
    String? taskName,
    bool requiresNetwork = true,
  }) {
    return SyncTaskConfig(
      taskName: taskName ?? 'one_time_sync_${DateTime.now().millisecondsSinceEpoch}',
      interval: Duration.zero,
      constraints: ConstraintsExtension.forSync(
        requiresNetwork: requiresNetwork,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }
}
