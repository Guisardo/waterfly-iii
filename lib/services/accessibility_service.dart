import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:logging/logging.dart';

/// Comprehensive accessibility service for offline mode features.
///
/// This service provides:
/// - Screen reader announcements for connectivity and sync changes
/// - Semantic labels for all offline mode UI elements
/// - Keyboard navigation support
/// - Focus management
/// - Accessibility event tracking and logging
///
/// Example:
/// ```dart
/// final accessibilityService = AccessibilityService();
/// await accessibilityService.initialize();
/// accessibilityService.announceConnectivityChange(isOnline: false);
/// ```
class AccessibilityService {
  static final Logger _logger = Logger('AccessibilityService');
  
  /// Singleton instance
  static final AccessibilityService _instance = AccessibilityService._internal();
  
  /// Factory constructor returns singleton
  factory AccessibilityService() => _instance;
  
  AccessibilityService._internal();
  
  /// Whether the service has been initialized
  bool _isInitialized = false;
  
  /// Stream controller for accessibility events
  final StreamController<AccessibilityEvent> _eventController = 
      StreamController<AccessibilityEvent>.broadcast();
  
  /// Stream of accessibility events
  Stream<AccessibilityEvent> get events => _eventController.stream;
  
  /// Current accessibility settings
  AccessibilitySettings _settings = AccessibilitySettings();
  
  /// Get current accessibility settings
  AccessibilitySettings get settings => _settings;
  
  /// Initialize the accessibility service
  ///
  /// This should be called during app initialization.
  ///
  /// Throws [StateError] if already initialized.
  Future<void> initialize() async {
    if (_isInitialized) {
      final error = StateError('AccessibilityService already initialized');
      _logger.severe(
        'Attempted to initialize already initialized service',
        error,
        StackTrace.current,
      );
      throw error;
    }
    
    try {
      _logger.info('Initializing AccessibilityService');
      
      // Load saved settings
      await _loadSettings();
      
      // Set up accessibility features
      await _setupAccessibilityFeatures();
      
      _isInitialized = true;
      
      _logger.info('AccessibilityService initialized successfully');
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.serviceInitialized,
        timestamp: DateTime.now(),
        message: 'Accessibility service initialized',
      ));
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to initialize AccessibilityService',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
  
  /// Dispose of the service and clean up resources
  Future<void> dispose() async {
    _logger.info('Disposing AccessibilityService');
    
    try {
      await _eventController.close();
      _isInitialized = false;
      
      _logger.info('AccessibilityService disposed successfully');
    } catch (e, stackTrace) {
      _logger.severe(
        'Error disposing AccessibilityService',
        e,
        stackTrace,
      );
    }
  }
  
  /// Announce connectivity status change to screen readers
  ///
  /// [isOnline] - Whether the device is now online
  /// [queueCount] - Number of pending sync operations (optional)
  void announceConnectivityChange({
    required bool isOnline,
    int? queueCount,
  }) {
    _ensureInitialized();
    
    try {
      final String message = isOnline
          ? queueCount != null && queueCount > 0
              ? 'Back online. $queueCount ${queueCount == 1 ? 'item' : 'items'} pending sync.'
              : 'Back online. All data synced.'
          : 'You are now offline. Changes will sync when back online.';
      
      _logger.info('Announcing connectivity change: $message');
      
      SemanticsService.announce(
        message,
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      );
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.connectivityAnnounced,
        timestamp: DateTime.now(),
        message: message,
        data: {'isOnline': isOnline, 'queueCount': queueCount},
      ));
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to announce connectivity change',
        e,
        stackTrace,
      );
    }
  }
  
  /// Announce sync progress to screen readers
  ///
  /// [completed] - Number of completed operations
  /// [total] - Total number of operations
  /// [currentOperation] - Description of current operation (optional)
  void announceSyncProgress({
    required int completed,
    required int total,
    String? currentOperation,
  }) {
    _ensureInitialized();
    
    try {
      final percentage = ((completed / total) * 100).round();
      final String message = currentOperation != null
          ? 'Syncing: $percentage percent complete. $currentOperation'
          : 'Syncing: $percentage percent complete. $completed of $total items synced.';
      
      _logger.debug('Announcing sync progress: $message');
      
      // Use polite assertiveness for progress updates to avoid interrupting
      SemanticsService.announce(
        message,
        TextDirection.ltr,
        assertiveness: Assertiveness.polite,
      );
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.syncProgressAnnounced,
        timestamp: DateTime.now(),
        message: message,
        data: {
          'completed': completed,
          'total': total,
          'percentage': percentage,
          'currentOperation': currentOperation,
        },
      ));
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to announce sync progress',
        e,
        stackTrace,
      );
    }
  }
  
  /// Announce sync completion to screen readers
  ///
  /// [successCount] - Number of successfully synced items
  /// [failureCount] - Number of failed items
  void announceSyncCompletion({
    required int successCount,
    required int failureCount,
  }) {
    _ensureInitialized();
    
    try {
      final String message = failureCount > 0
          ? 'Sync complete. $successCount ${successCount == 1 ? 'item' : 'items'} synced successfully. $failureCount ${failureCount == 1 ? 'item' : 'items'} failed.'
          : 'Sync complete. All $successCount ${successCount == 1 ? 'item' : 'items'} synced successfully.';
      
      _logger.info('Announcing sync completion: $message');
      
      SemanticsService.announce(
        message,
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      );
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.syncCompletionAnnounced,
        timestamp: DateTime.now(),
        message: message,
        data: {
          'successCount': successCount,
          'failureCount': failureCount,
        },
      ));
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to announce sync completion',
        e,
        stackTrace,
      );
    }
  }
  
  /// Announce conflict detection to screen readers
  ///
  /// [conflictCount] - Number of conflicts detected
  /// [entityType] - Type of entity with conflicts (optional)
  void announceConflicts({
    required int conflictCount,
    String? entityType,
  }) {
    _ensureInitialized();
    
    try {
      final String message = entityType != null
          ? '$conflictCount ${conflictCount == 1 ? 'conflict' : 'conflicts'} detected in $entityType. Review required.'
          : '$conflictCount ${conflictCount == 1 ? 'conflict' : 'conflicts'} detected. Review required.';
      
      _logger.warning('Announcing conflicts: $message');
      
      SemanticsService.announce(
        message,
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      );
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.conflictsAnnounced,
        timestamp: DateTime.now(),
        message: message,
        data: {
          'conflictCount': conflictCount,
          'entityType': entityType,
        },
      ));
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to announce conflicts',
        e,
        stackTrace,
      );
    }
  }
  
  /// Announce error to screen readers
  ///
  /// [errorMessage] - User-friendly error message
  /// [errorType] - Type of error (optional)
  void announceError({
    required String errorMessage,
    String? errorType,
  }) {
    _ensureInitialized();
    
    try {
      final String message = errorType != null
          ? '$errorType error: $errorMessage'
          : 'Error: $errorMessage';
      
      _logger.warning('Announcing error: $message');
      
      SemanticsService.announce(
        message,
        TextDirection.ltr,
        assertiveness: Assertiveness.assertive,
      );
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.errorAnnounced,
        timestamp: DateTime.now(),
        message: message,
        data: {
          'errorMessage': errorMessage,
          'errorType': errorType,
        },
      ));
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to announce error',
        e,
        stackTrace,
      );
    }
  }
  
  /// Get semantic label for sync status
  ///
  /// [isSynced] - Whether the item is synced
  /// [isPending] - Whether sync is pending
  /// [isSyncing] - Whether currently syncing
  /// [hasFailed] - Whether sync failed
  ///
  /// Returns a descriptive label for screen readers.
  String getSyncStatusLabel({
    required bool isSynced,
    required bool isPending,
    required bool isSyncing,
    required bool hasFailed,
  }) {
    if (hasFailed) {
      return 'Sync failed. Tap to retry.';
    } else if (isSyncing) {
      return 'Syncing in progress.';
    } else if (isPending) {
      return 'Pending sync. Will sync when online.';
    } else if (isSynced) {
      return 'Synced successfully.';
    } else {
      return 'Sync status unknown.';
    }
  }
  
  /// Get semantic label for connectivity status
  ///
  /// [isOnline] - Whether device is online
  /// [queueCount] - Number of pending operations
  ///
  /// Returns a descriptive label for screen readers.
  String getConnectivityLabel({
    required bool isOnline,
    required int queueCount,
  }) {
    if (isOnline) {
      if (queueCount > 0) {
        return 'Online. $queueCount ${queueCount == 1 ? 'item' : 'items'} pending sync. Tap for details.';
      } else {
        return 'Online. All data synced. Tap for details.';
      }
    } else {
      if (queueCount > 0) {
        return 'Offline. $queueCount ${queueCount == 1 ? 'item' : 'items'} will sync when online. Tap for details.';
      } else {
        return 'Offline. Changes will sync when online. Tap for details.';
      }
    }
  }
  
  /// Get semantic hint for action button
  ///
  /// [action] - The action the button performs
  ///
  /// Returns a hint for screen readers.
  String getActionHint(String action) {
    return 'Double tap to $action';
  }
  
  /// Update accessibility settings
  ///
  /// [settings] - New accessibility settings
  Future<void> updateSettings(AccessibilitySettings settings) async {
    _ensureInitialized();
    
    try {
      _logger.info('Updating accessibility settings');
      
      _settings = settings;
      await _saveSettings();
      
      _eventController.add(AccessibilityEvent(
        type: AccessibilityEventType.settingsUpdated,
        timestamp: DateTime.now(),
        message: 'Accessibility settings updated',
        data: settings.toJson(),
      ));
      
      _logger.info('Accessibility settings updated successfully');
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to update accessibility settings',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
  
  /// Load accessibility settings from storage
  Future<void> _loadSettings() async {
    try {
      _logger.debug('Loading accessibility settings');
      
      // TODO: Load from shared preferences or secure storage
      // For now, use defaults
      _settings = AccessibilitySettings();
      
      _logger.debug('Accessibility settings loaded');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to load accessibility settings, using defaults',
        e,
        stackTrace,
      );
      _settings = AccessibilitySettings();
    }
  }
  
  /// Save accessibility settings to storage
  Future<void> _saveSettings() async {
    try {
      _logger.debug('Saving accessibility settings');
      
      // TODO: Save to shared preferences or secure storage
      
      _logger.debug('Accessibility settings saved');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to save accessibility settings',
        e,
        stackTrace,
      );
    }
  }
  
  /// Set up accessibility features
  Future<void> _setupAccessibilityFeatures() async {
    try {
      _logger.debug('Setting up accessibility features');
      
      // Enable semantic debugging in debug mode
      if (_settings.enableSemanticDebugging) {
        WidgetsBinding.instance.ensureSemantics();
      }
      
      _logger.debug('Accessibility features set up');
    } catch (e, stackTrace) {
      _logger.warning(
        'Failed to set up accessibility features',
        e,
        stackTrace,
      );
    }
  }
  
  /// Ensure service is initialized
  void _ensureInitialized() {
    if (!_isInitialized) {
      final error = StateError('AccessibilityService not initialized. Call initialize() first.');
      _logger.severe(
        'Attempted to use uninitialized service',
        error,
        StackTrace.current,
      );
      throw error;
    }
  }
}

/// Accessibility settings configuration
class AccessibilitySettings {
  /// Whether to enable verbose announcements
  final bool enableVerboseAnnouncements;
  
  /// Whether to announce sync progress updates
  final bool announceSyncProgress;
  
  /// Whether to announce connectivity changes
  final bool announceConnectivityChanges;
  
  /// Whether to announce conflicts
  final bool announceConflicts;
  
  /// Whether to enable semantic debugging
  final bool enableSemanticDebugging;
  
  /// Minimum time between progress announcements (milliseconds)
  final int progressAnnouncementInterval;
  
  const AccessibilitySettings({
    this.enableVerboseAnnouncements = true,
    this.announceSyncProgress = true,
    this.announceConnectivityChanges = true,
    this.announceConflicts = true,
    this.enableSemanticDebugging = false,
    this.progressAnnouncementInterval = 5000,
  });
  
  /// Create settings from JSON
  factory AccessibilitySettings.fromJson(Map<String, dynamic> json) {
    return AccessibilitySettings(
      enableVerboseAnnouncements: json['enableVerboseAnnouncements'] as bool? ?? true,
      announceSyncProgress: json['announceSyncProgress'] as bool? ?? true,
      announceConnectivityChanges: json['announceConnectivityChanges'] as bool? ?? true,
      announceConflicts: json['announceConflicts'] as bool? ?? true,
      enableSemanticDebugging: json['enableSemanticDebugging'] as bool? ?? false,
      progressAnnouncementInterval: json['progressAnnouncementInterval'] as int? ?? 5000,
    );
  }
  
  /// Convert settings to JSON
  Map<String, dynamic> toJson() {
    return {
      'enableVerboseAnnouncements': enableVerboseAnnouncements,
      'announceSyncProgress': announceSyncProgress,
      'announceConnectivityChanges': announceConnectivityChanges,
      'announceConflicts': announceConflicts,
      'enableSemanticDebugging': enableSemanticDebugging,
      'progressAnnouncementInterval': progressAnnouncementInterval,
    };
  }
  
  /// Create a copy with updated values
  AccessibilitySettings copyWith({
    bool? enableVerboseAnnouncements,
    bool? announceSyncProgress,
    bool? announceConnectivityChanges,
    bool? announceConflicts,
    bool? enableSemanticDebugging,
    int? progressAnnouncementInterval,
  }) {
    return AccessibilitySettings(
      enableVerboseAnnouncements: enableVerboseAnnouncements ?? this.enableVerboseAnnouncements,
      announceSyncProgress: announceSyncProgress ?? this.announceSyncProgress,
      announceConnectivityChanges: announceConnectivityChanges ?? this.announceConnectivityChanges,
      announceConflicts: announceConflicts ?? this.announceConflicts,
      enableSemanticDebugging: enableSemanticDebugging ?? this.enableSemanticDebugging,
      progressAnnouncementInterval: progressAnnouncementInterval ?? this.progressAnnouncementInterval,
    );
  }
}

/// Accessibility event types
enum AccessibilityEventType {
  serviceInitialized,
  settingsUpdated,
  connectivityAnnounced,
  syncProgressAnnounced,
  syncCompletionAnnounced,
  conflictsAnnounced,
  errorAnnounced,
}

/// Accessibility event
class AccessibilityEvent {
  /// Type of event
  final AccessibilityEventType type;
  
  /// When the event occurred
  final DateTime timestamp;
  
  /// Event message
  final String message;
  
  /// Additional event data
  final Map<String, dynamic>? data;
  
  const AccessibilityEvent({
    required this.type,
    required this.timestamp,
    required this.message,
    this.data,
  });
  
  @override
  String toString() {
    return 'AccessibilityEvent(type: $type, timestamp: $timestamp, message: $message, data: $data)';
  }
}
