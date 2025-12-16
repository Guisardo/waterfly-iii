import 'package:flutter/foundation.dart';

/// Global instance for sync state (accessible without context)
SyncProvider? _globalSyncProvider;

/// Provider for tracking sync state across the app.
class SyncProvider extends ChangeNotifier {
  SyncProvider() {
    _globalSyncProvider = this;
  }
  
  bool _isSyncing = false;
  double _progress = 0.0;
  String? _currentOperation;
  int _completedOperations = 0;
  int _totalOperations = 0;
  
  bool get isSyncing => _isSyncing;
  
  /// Progress percentage (0.0 to 1.0)
  double get progress => _progress;
  
  /// Current operation description (e.g., "Fetching accounts...")
  String? get currentOperation => _currentOperation;
  
  /// Number of completed operations
  int get completedOperations => _completedOperations;
  
  /// Total number of operations
  int get totalOperations => _totalOperations;
  
  /// Progress percentage as integer (0-100)
  int get progressPercent => (_progress * 100).round();
  
  void startSync({int totalOperations = 0}) {
    _isSyncing = true;
    _progress = 0.0;
    _currentOperation = null;
    _completedOperations = 0;
    _totalOperations = totalOperations;
    notifyListeners();
  }
  
  void stopSync() {
    _isSyncing = false;
    _progress = 0.0;
    _currentOperation = null;
    _completedOperations = 0;
    _totalOperations = 0;
    notifyListeners();
  }
  
  /// Update sync progress
  void updateProgress({
    double? progress,
    String? currentOperation,
    int? completedOperations,
    int? totalOperations,
  }) {
    bool changed = false;
    
    if (progress != null && progress != _progress) {
      _progress = progress.clamp(0.0, 1.0);
      changed = true;
    }
    
    if (currentOperation != null && currentOperation != _currentOperation) {
      _currentOperation = currentOperation;
      changed = true;
    }
    
    if (completedOperations != null && completedOperations != _completedOperations) {
      _completedOperations = completedOperations;
      changed = true;
    }
    
    if (totalOperations != null && totalOperations != _totalOperations) {
      _totalOperations = totalOperations;
      changed = true;
    }
    
    // Auto-calculate progress if we have operation counts
    if (_totalOperations > 0) {
      final calculatedProgress = _completedOperations / _totalOperations;
      if ((calculatedProgress - _progress).abs() > 0.001) {
        _progress = calculatedProgress.clamp(0.0, 1.0);
        changed = true;
      }
    }
    
    if (changed) {
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
void notifyGlobalSyncState(bool isSyncing, {int totalOperations = 0}) {
  if (_globalSyncProvider != null) {
    if (isSyncing) {
      _globalSyncProvider!.startSync(totalOperations: totalOperations);
    } else {
      _globalSyncProvider!.stopSync();
    }
  }
}

/// Global function to update sync progress without context
void updateGlobalSyncProgress({
  double? progress,
  String? currentOperation,
  int? completedOperations,
  int? totalOperations,
}) {
  _globalSyncProvider?.updateProgress(
    progress: progress,
    currentOperation: currentOperation,
    completedOperations: completedOperations,
    totalOperations: totalOperations,
  );
}
