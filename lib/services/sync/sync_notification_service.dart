import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

import 'package:waterflyiii/models/sync_progress.dart';

/// Service for managing sync-related notifications.
///
/// Features:
/// - Show notification when sync starts
/// - Update notification with progress
/// - Show completion notification
/// - Show error notification if sync fails
/// - Tappable notifications to open sync status
/// - Configurable notification settings
class SyncNotificationService {
  static final Logger _logger = Logger('SyncNotificationService');
  static final SyncNotificationService _instance =
      SyncNotificationService._internal();

  factory SyncNotificationService() => _instance;

  SyncNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'sync_channel';
  static const String _channelName = 'Sync Notifications';
  static const String _channelDescription =
      'Notifications for data synchronization';
  static const int _syncNotificationId = 1000;

  bool _isInitialized = false;
  bool _notificationsEnabled = true;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    try {
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channel for Android
      const AndroidNotificationChannel androidChannel =
          AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.low,
            showBadge: false,
          );

      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      _isInitialized = true;
      _logger.info('Sync notification service initialized');
    } catch (e, stackTrace) {
      _logger.severe('Failed to initialize sync notifications', e, stackTrace);
    }
  }

  /// Enable or disable notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _logger.info('Sync notifications ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Show notification when sync starts
  Future<void> showSyncStarted({required int operationCount}) async {
    if (!_notificationsEnabled || !_isInitialized) {
      return;
    }

    try {
      await _notifications.show(
        _syncNotificationId,
        'Syncing data',
        'Syncing $operationCount operation${operationCount == 1 ? '' : 's'}...',
        _getNotificationDetails(showProgress: true, progress: 0),
      );

      _logger.fine('Showed sync started notification');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to show sync started notification',
        e,
        stackTrace,
      );
    }
  }

  /// Update notification with sync progress
  Future<void> updateSyncProgress(SyncProgress progress) async {
    if (!_notificationsEnabled || !_isInitialized) {
      return;
    }

    try {
      final int percentage = progress.percentage.toInt();

      await _notifications.show(
        _syncNotificationId,
        'Syncing data',
        '${progress.completedOperations} of ${progress.totalOperations} operations',
        _getNotificationDetails(
          showProgress: true,
          progress: percentage,
          maxProgress: 100,
        ),
      );

      _logger.fine('Updated sync progress notification: $percentage%');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to update sync progress notification',
        e,
        stackTrace,
      );
    }
  }

  /// Show notification when sync completes successfully
  Future<void> showSyncCompleted({
    required int completedCount,
    required int failedCount,
  }) async {
    if (!_notificationsEnabled || !_isInitialized) {
      return;
    }

    try {
      String message;
      if (failedCount > 0) {
        message = 'Synced $completedCount operations, $failedCount failed';
      } else {
        message =
            'Successfully synced $completedCount operation${completedCount == 1 ? '' : 's'}';
      }

      await _notifications.show(
        _syncNotificationId,
        'Sync complete',
        message,
        _getNotificationDetails(showProgress: false),
      );

      _logger.info('Showed sync completed notification');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to show sync completed notification',
        e,
        stackTrace,
      );
    }
  }

  /// Show notification when sync fails
  Future<void> showSyncFailed({
    required String errorMessage,
    required int failedCount,
  }) async {
    if (!_notificationsEnabled || !_isInitialized) {
      return;
    }

    try {
      await _notifications.show(
        _syncNotificationId,
        'Sync failed',
        '$failedCount operation${failedCount == 1 ? '' : 's'} failed: $errorMessage',
        _getNotificationDetails(showProgress: false, priority: Priority.high),
      );

      _logger.warning('Showed sync failed notification');
    } catch (e, stackTrace) {
      _logger.warning('Failed to show sync failed notification', e, stackTrace);
    }
  }

  /// Show notification for conflicts detected
  Future<void> showConflictsDetected({required int conflictCount}) async {
    if (!_notificationsEnabled || !_isInitialized) {
      return;
    }

    try {
      await _notifications.show(
        _syncNotificationId + 1,
        'Conflicts detected',
        '$conflictCount conflict${conflictCount == 1 ? '' : 's'} require${conflictCount == 1 ? 's' : ''} your attention',
        _getNotificationDetails(showProgress: false, priority: Priority.high),
      );

      _logger.info('Showed conflicts detected notification');
    } catch (e, stackTrace) {
      _logger.warning('Failed to show conflicts notification', e, stackTrace);
    }
  }

  /// Cancel sync notification
  Future<void> cancelSyncNotification() async {
    try {
      await _notifications.cancel(_syncNotificationId);
      _logger.fine('Cancelled sync notification');
    } catch (e, stackTrace) {
      _logger.warning('Failed to cancel sync notification', e, stackTrace);
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.info('Cancelled all sync notifications');
    } catch (e, stackTrace) {
      _logger.warning('Failed to cancel all notifications', e, stackTrace);
    }
  }

  /// Get notification details
  NotificationDetails _getNotificationDetails({
    required bool showProgress,
    int progress = 0,
    int maxProgress = 100,
    Priority priority = Priority.low,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.low,
        priority: priority,
        showProgress: showProgress,
        progress: progress,
        maxProgress: maxProgress,
        ongoing: showProgress,
        autoCancel: !showProgress,
        playSound: false,
        enableVibration: false,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      ),
    );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('Sync notification tapped: ${response.id}');
    // Navigation will be handled by the app when it receives this callback
  }
}
