import 'package:logging/logging.dart';

class AccessibilityService {
  final Logger _logger = Logger('AccessibilityService');

  void announceMessage(String message) {
    _logger.fine('Accessibility announcement: $message');
  }

  void setFocusOrder(List<String> order) {
    _logger.fine('Setting focus order: ${order.length} elements');
  }

  String getSyncStatusLabel({
    required bool isSynced,
    required bool isPending,
    required bool isSyncing,
    required bool hasFailed,
  }) {
    if (hasFailed) return 'Sync failed';
    if (isSyncing) return 'Syncing';
    if (isPending) return 'Sync pending';
    if (isSynced) return 'Synced';
    return 'Unknown sync status';
  }

  bool get isScreenReaderEnabled => false;
}
