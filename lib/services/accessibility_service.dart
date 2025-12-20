import 'dart:async';
import 'dart:ui' show FlutterView;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:logging/logging.dart';

/// Comprehensive accessibility service for screen readers and assistive technologies.
///
/// Features:
/// - Message announcements for screen readers
/// - Focus order management
/// - Screen reader detection (TalkBack/VoiceOver)
/// - Semantic labels for sync states
/// - Keyboard navigation support
/// - High contrast mode detection
/// - Font scaling support
class AccessibilityService {
  final Logger _logger = Logger('AccessibilityService');

  final List<String> _announcementQueue = <String>[];
  Timer? _announcementTimer;
  bool _isAnnouncing = false;

  /// Announce a message to screen readers.
  ///
  /// Messages are queued to avoid overlapping announcements.
  void announceMessage(
    String message, {
    AnnouncementPriority priority = AnnouncementPriority.normal,
  }) {
    _logger.fine('Accessibility announcement: $message (priority: $priority)');

    if (priority == AnnouncementPriority.high) {
      // High priority announcements go to the front
      _announcementQueue.insert(0, message);
    } else {
      _announcementQueue.add(message);
    }

    _processAnnouncementQueue();
  }

  /// Set focus traversal order for a group of widgets.
  void setFocusOrder(List<FocusNode> nodes) {
    _logger.fine('Setting focus order: ${nodes.length} elements');

    for (int i = 0; i < nodes.length; i++) {
      if (i < nodes.length - 1) {
        nodes[i].nextFocus();
      }
    }
  }

  /// Get descriptive label for sync status.
  String getSyncStatusLabel({
    required bool isSynced,
    required bool isPending,
    required bool isSyncing,
    required bool hasFailed,
    int? pendingCount,
    double? progress,
  }) {
    if (hasFailed) {
      return 'Synchronization failed. Tap to view details and retry.';
    }

    if (isSyncing) {
      if (progress != null) {
        final int percentage = (progress * 100).toInt();
        return 'Synchronizing, $percentage percent complete';
      }
      return 'Synchronization in progress';
    }

    if (isPending) {
      if (pendingCount != null && pendingCount > 0) {
        return '$pendingCount ${pendingCount == 1 ? "item" : "items"} pending synchronization';
      }
      return 'Synchronization pending';
    }

    if (isSynced) {
      return 'All data synchronized';
    }

    return 'Synchronization status unknown';
  }

  /// Get label for sync progress.
  String getProgressLabel(int completed, int total) {
    return 'Synchronizing: $completed of $total items complete';
  }

  /// Get label for conflict count.
  String getConflictLabel(int count) {
    if (count == 0) return 'No conflicts';
    if (count == 1) return '1 conflict requires resolution';
    return '$count conflicts require resolution';
  }

  /// Get label for error count.
  String getErrorLabel(int count) {
    if (count == 0) return 'No errors';
    if (count == 1) return '1 error occurred';
    return '$count errors occurred';
  }

  /// Check if screen reader is enabled.
  ///
  /// Detects TalkBack (Android) and VoiceOver (iOS).
  bool get isScreenReaderEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.accessibleNavigation;
  }

  /// Check if high contrast mode is enabled.
  bool get isHighContrastEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.highContrast;
  }

  /// Check if bold text is enabled.
  bool get isBoldTextEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.boldText;
  }

  /// Get text scale factor for font scaling.
  double get textScaleFactor {
    return WidgetsBinding.instance.platformDispatcher.textScaleFactor;
  }

  /// Check if reduce motion is enabled.
  bool get isReduceMotionEnabled {
    return WidgetsBinding.instance.accessibilityFeatures.disableAnimations;
  }

  /// Create semantic label for button action.
  String getButtonLabel(String action, {String? context}) {
    if (context != null) {
      return '$action $context button';
    }
    return '$action button';
  }

  /// Create semantic hint for interactive element.
  String getHint(String action) {
    return 'Double tap to $action';
  }

  /// Announce sync started.
  void announceSyncStarted() {
    announceMessage(
      'Synchronization started',
      priority: AnnouncementPriority.normal,
    );
  }

  /// Announce sync completed.
  void announceSyncCompleted({required int itemCount}) {
    announceMessage(
      'Synchronization completed. $itemCount ${itemCount == 1 ? "item" : "items"} synchronized.',
      priority: AnnouncementPriority.high,
    );
  }

  /// Announce sync failed.
  void announceSyncFailed({required String reason}) {
    announceMessage(
      'Synchronization failed: $reason',
      priority: AnnouncementPriority.high,
    );
  }

  /// Announce conflict detected.
  void announceConflictDetected({required int count}) {
    announceMessage(
      '$count ${count == 1 ? "conflict" : "conflicts"} detected and require resolution',
      priority: AnnouncementPriority.high,
    );
  }

  /// Dispose resources.
  void dispose() {
    _announcementTimer?.cancel();
    _announcementQueue.clear();
  }

  // Private helper methods

  void _processAnnouncementQueue() {
    if (_isAnnouncing || _announcementQueue.isEmpty) return;

    _isAnnouncing = true;
    final String message = _announcementQueue.removeAt(0);

    // Use SemanticsService to announce
    final FlutterView view = WidgetsBinding.instance.platformDispatcher.views.first;
    SemanticsService.sendAnnouncement(view, message, TextDirection.ltr);

    // Wait before processing next announcement to avoid overlap
    _announcementTimer = Timer(const Duration(milliseconds: 1500), () {
      _isAnnouncing = false;
      _processAnnouncementQueue();
    });
  }
}

/// Priority level for accessibility announcements.
enum AnnouncementPriority {
  /// Normal priority - queued in order
  normal,

  /// High priority - announced immediately
  high,
}
