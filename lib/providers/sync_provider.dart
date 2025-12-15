import 'package:flutter/foundation.dart';

/// Global instance for sync state (accessible without context)
SyncProvider? _globalSyncProvider;

/// Provider for tracking sync state across the app.
class SyncProvider extends ChangeNotifier {
  SyncProvider() {
    _globalSyncProvider = this;
  }
  
  bool _isSyncing = false;
  
  bool get isSyncing => _isSyncing;
  
  void startSync() {
    if (!_isSyncing) {
      _isSyncing = true;
      notifyListeners();
    }
  }
  
  void stopSync() {
    if (_isSyncing) {
      _isSyncing = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    if (_globalSyncProvider == this) {
      _globalSyncProvider = null;
    }
    super.dispose();
  }
}

/// Global function to notify sync state without context
void notifyGlobalSyncState(bool isSyncing) {
  if (_globalSyncProvider != null) {
    if (isSyncing) {
      _globalSyncProvider!.startSync();
    } else {
      _globalSyncProvider!.stopSync();
    }
  }
}
