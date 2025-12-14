# Phase 3 Services - Quick Reference Guide

This guide provides quick examples and usage patterns for all Phase 3 synchronization services.

---

## 🔄 Sync Manager

**Main orchestrator for synchronization operations**

```dart
// Initialize
final syncManager = SyncManager(
  progressTracker: SyncProgressTracker(),
  conflictDetector: ConflictDetector(),
  conflictResolver: ConflictResolver(),
  retryStrategy: RetryStrategy(),
  circuitBreaker: CircuitBreaker(),
);

// Perform sync
final result = await syncManager.synchronize();
print('Synced ${result.completedOperations} operations');

// Watch progress
syncManager.watchProgress().listen((progress) {
  print('Progress: ${progress.percentage}%');
  print('ETA: ${progress.estimatedTimeRemaining}');
});

// Full sync
await syncManager.performFullSync();

// Incremental sync
await syncManager.performIncrementalSync();
```

---

## 📊 Sync Progress Tracker

**Real-time progress monitoring with streams**

```dart
final tracker = SyncProgressTracker();

// Start tracking
tracker.start(totalOperations: 100);

// Update progress
tracker.incrementCompleted();
tracker.incrementFailed(error: 'Network error');
tracker.incrementSkipped();
tracker.incrementConflicts(conflictId: 'conflict_1');

// Update phase
tracker.updatePhase(SyncPhase.syncing);

// Watch progress
tracker.watchProgress().listen((progress) {
  print('${progress.completedOperations}/${progress.totalOperations}');
  print('Throughput: ${progress.throughput} ops/sec');
});

// Watch events
tracker.watchEvents().listen((event) {
  if (event is SyncCompletedEvent) {
    print('Sync completed!');
  }
});

// Complete
final result = tracker.complete(success: true);
print('Success rate: ${result.successRate}');
```

---

## 🔍 Conflict Detector

**Intelligent conflict detection with deep comparison**

```dart
final detector = ConflictDetector();

// Detect conflict for single operation
final conflict = await detector.detectConflict(
  operation,
  remoteData,
);

if (conflict != null) {
  print('Conflict detected: ${conflict.conflictType}');
  print('Severity: ${conflict.severity}');
  print('Conflicting fields: ${conflict.conflictingFields}');
}

// Batch detection
final conflicts = await detector.detectConflictsBatch(operations);
print('Found ${conflicts.length} conflicts');

// Get conflicting fields
final fields = detector.getConflictingFields(localData, remoteData);
print('Conflicting: $fields');
```

---

## 🔧 Conflict Resolver

**5 resolution strategies with automatic and manual resolution**

```dart
final resolver = ConflictResolver(
  autoResolveEnabled: true,
  autoResolveTimeWindow: Duration(hours: 24),
);

// Resolve with strategy
final resolution = await resolver.resolveConflict(
  conflict,
  ResolutionStrategy.lastWriteWins,
);

if (resolution.success) {
  print('Resolved with: ${resolution.resolvedData}');
}

// Auto-resolve conflicts
final resolutions = await resolver.autoResolveConflicts(conflicts);
print('Auto-resolved ${resolutions.length} conflicts');

// Manual resolution
await resolver.resolveManually(
  conflictId,
  ResolutionStrategy.localWins,
);

// Custom data resolution
await resolver.resolveWithCustomData(
  conflictId,
  mergedData,
);

// Get statistics
final stats = await resolver.getStatistics();
print('Total conflicts: ${stats.totalConflicts}');
print('Unresolved: ${stats.unresolvedConflicts}');
```

---

## 🔁 Retry Strategy

**Exponential backoff with jitter**

```dart
final strategy = RetryStrategy(
  maxAttempts: 5,
  initialDelay: Duration(seconds: 1),
  maxDelay: Duration(seconds: 60),
  exponentialFactor: 2.0,
  jitter: 0.2,
);

// Retry operation
final result = await strategy.retryOperation(
  () => apiClient.createTransaction(data),
  operationName: 'create_transaction',
  onRetry: (error, attempt) {
    print('Retry attempt $attempt: $error');
  },
);

// Batch retry
final batchResult = await strategy.retryBatch(
  {
    'op1': () => operation1(),
    'op2': () => operation2(),
    'op3': () => operation3(),
  },
  onProgress: (id, completed, total) {
    print('Progress: $completed/$total');
  },
);

print('Succeeded: ${batchResult.successCount}');
print('Failed: ${batchResult.failureCount}');
print('Success rate: ${batchResult.successRate}');

// Check if retryable
if (strategy.isRetryable(error)) {
  print('Error is retryable');
}

// Get retry delay
final delay = strategy.getRetryDelay(attemptNumber);
print('Wait ${delay.inSeconds}s before retry');

// Custom policies
final aggressive = RetryStrategy.createAggressivePolicy();
final conservative = RetryStrategy.createConservativePolicy();
```

---

## ⚡ Circuit Breaker

**API protection with automatic state management**

```dart
final breaker = CircuitBreaker(
  failureThreshold: 5,
  successThreshold: 2,
  resetTimeout: Duration(seconds: 60),
  operationTimeout: Duration(seconds: 30),
);

// Execute operation
try {
  final result = await breaker.execute(
    () => apiClient.getData(),
    operationName: 'get_data',
  );
  print('Success: $result');
} on CircuitBreakerOpenError {
  print('Circuit is open, try again later');
}

// Check state
if (breaker.isOpen) {
  print('Circuit is open');
} else if (breaker.isHalfOpen) {
  print('Circuit is half-open, testing recovery');
} else {
  print('Circuit is closed, operating normally');
}

// Get statistics
final stats = breaker.getStatistics();
print('State: ${stats.state}');
print('Successes: ${stats.totalSuccesses}');
print('Failures: ${stats.totalFailures}');
print('Rejected: ${stats.totalRejected}');
print('Success rate: ${(stats.successRate * 100).toStringAsFixed(1)}%');

// Manual control
await breaker.reset(); // Force close
await breaker.open(); // Force open
await breaker.resetStatistics();
```

---

## ✅ Consistency Checker

**Data integrity validation with auto-repair**

```dart
final checker = ConsistencyChecker();

// Validate consistency
final isConsistent = await checker.validateConsistency();
if (!isConsistent) {
  print('Consistency issues detected');
}

// Detect issues
final issues = await checker.detectInconsistencies();
for (final issue in issues) {
  print('${issue.type}: ${issue.description}');
  print('Severity: ${issue.severity}');
  print('Suggested fix: ${issue.suggestedFix}');
}

// Repair issues
final repaired = await checker.repairInconsistencies(issues);
print('Repaired $repaired out of ${issues.length} issues');

// Get report
final report = await checker.getReport();
print('Total issues: ${report.totalIssues}');
print('Critical: ${report.bySeverity[InconsistencySeverity.critical] ?? 0}');
print('High: ${report.bySeverity[InconsistencySeverity.high] ?? 0}');
print('Has critical issues: ${report.hasCriticalIssues}');
```

---

## 🗄️ Conflicts Table

**Database operations for conflict storage**

```dart
// Insert conflict
await ConflictsTable.insert(db, conflict);

// Get by ID
final conflict = await ConflictsTable.getById(db, conflictId);

// Get unresolved
final unresolved = await ConflictsTable.getUnresolved(db);
print('${unresolved.length} unresolved conflicts');

// Get by severity
final highSeverity = await ConflictsTable.getUnresolvedBySeverity(
  db,
  ConflictSeverity.high,
);

// Update resolution
await ConflictsTable.updateResolution(
  db,
  conflictId,
  strategy: ResolutionStrategy.lastWriteWins,
  resolvedBy: 'auto',
  resolvedData: mergedData,
);

// Get statistics
final stats = await ConflictsTable.getStatistics(db);
print('Total: ${stats.totalConflicts}');
print('Unresolved: ${stats.unresolvedConflicts}');
print('Auto-resolved: ${stats.autoResolvedConflicts}');
print('Manual: ${stats.manuallyResolvedConflicts}');
print('Avg resolution time: ${stats.averageResolutionTime}s');

// Cleanup
await ConflictsTable.deleteOldResolved(db, Duration(days: 30));
```

---

## 🚨 Exception Handling

**11 exception types with retry logic**

```dart
try {
  await syncOperation();
} on NetworkError catch (e) {
  // Retryable: connectivity issues
  print('Network error: ${e.message}');
  if (e.isRetryable) {
    await Future.delayed(e.retryDelay ?? Duration(seconds: 10));
    // Retry
  }
} on ServerError catch (e) {
  // Retryable: 5xx responses
  print('Server error: ${e.statusCode} - ${e.message}');
} on ConflictError catch (e) {
  // Not retryable: requires resolution
  print('Conflict: ${e.conflict?.conflictType}');
  // Resolve conflict
} on ValidationError catch (e) {
  // Not retryable: invalid data
  print('Validation error in ${e.field}: ${e.message}');
  print('Rule: ${e.rule}');
  print('Suggested fix: ${e.suggestedFix}');
} on RateLimitError catch (e) {
  // Retryable: respect Retry-After
  print('Rate limited, retry after: ${e.retryAfter}');
  await Future.delayed(e.retryAfter ?? Duration(seconds: 60));
} on CircuitBreakerOpenError catch (e) {
  // Not retryable: circuit is open
  print('Circuit breaker open, failures: ${e.failureCount}');
  print('Opened at: ${e.openedAt}');
} on AuthenticationError catch (e) {
  // Not retryable: re-authenticate
  print('Authentication failed: ${e.message}');
  // Prompt for credentials
} on TimeoutError catch (e) {
  // Retryable: request timeout
  print('Timeout after ${e.timeout}');
}
```

---

## 📦 Models

### Conflict
```dart
final conflict = Conflict(
  id: 'conflict_1',
  operationId: 'op_123',
  entityType: 'transaction',
  entityId: 'txn_456',
  conflictType: ConflictType.updateUpdate,
  localData: {'amount': 100.0},
  remoteData: {'amount': 150.0},
  conflictingFields: ['amount'],
  severity: ConflictSeverity.high,
  detectedAt: DateTime.now(),
);

print('Type: ${conflict.conflictType}');
print('Severity: ${conflict.severity}');
print('Is resolved: ${conflict.isResolved}');
```

### SyncProgress
```dart
final progress = SyncProgress(
  totalOperations: 100,
  completedOperations: 50,
  failedOperations: 5,
  skippedOperations: 2,
  currentOperation: 'Syncing transaction',
  percentage: 57.0,
  estimatedTimeRemaining: Duration(minutes: 2),
  startTime: DateTime.now(),
  phase: SyncPhase.syncing,
  errors: ['Error 1', 'Error 2'],
  conflictsDetected: 3,
  throughput: 10.5,
);

print('Progress: ${progress.percentage}%');
print('ETA: ${progress.estimatedTimeRemaining}');
print('Throughput: ${progress.throughput} ops/sec');
```

### SyncResult
```dart
final result = SyncResult(
  success: true,
  totalOperations: 100,
  completedOperations: 95,
  failedOperations: 5,
  skippedOperations: 0,
  conflictsDetected: 3,
  conflictsResolved: 3,
  duration: Duration(minutes: 5),
  startTime: startTime,
  endTime: endTime,
  errors: ['Error 1'],
  successRate: 0.95,
  throughput: 0.33,
  entityStats: {
    'transaction': EntitySyncStats(
      entityType: 'transaction',
      created: 10,
      updated: 80,
      deleted: 5,
    ),
  },
);

print('Success: ${result.success}');
print('Success rate: ${(result.successRate * 100).toStringAsFixed(1)}%');
print('Duration: ${result.duration.inMinutes} minutes');
```

---

## 🎯 Common Patterns

### Full Sync Flow
```dart
final syncManager = SyncManager();

// Watch progress
syncManager.watchProgress().listen((progress) {
  updateUI(progress);
});

// Watch events
syncManager.watchEvents().listen((event) {
  if (event is ConflictDetectedEvent) {
    showConflictNotification(event.conflictId);
  }
});

// Perform sync
try {
  final result = await syncManager.synchronize();
  if (result.success) {
    showSuccess('Synced ${result.completedOperations} operations');
  } else {
    showError('Sync failed: ${result.errors}');
  }
} catch (e) {
  showError('Sync error: $e');
}
```

### Conflict Resolution Flow
```dart
// Detect conflicts
final conflicts = await conflictDetector.detectConflictsBatch(operations);

// Auto-resolve low/medium severity
final autoResolved = await conflictResolver.autoResolveConflicts(conflicts);

// Get remaining high severity conflicts
final remaining = conflicts.where((c) => !c.isResolved).toList();

// Show to user for manual resolution
for (final conflict in remaining) {
  final strategy = await showConflictDialog(conflict);
  await conflictResolver.resolveManually(conflict.id, strategy);
}
```

### Retry with Circuit Breaker
```dart
final breaker = CircuitBreaker();
final retry = RetryStrategy();

try {
  await breaker.execute(
    () => retry.retryOperation(
      () => apiClient.syncData(data),
      operationName: 'sync_data',
    ),
  );
} on CircuitBreakerOpenError {
  print('Service unavailable, try again later');
} catch (e) {
  print('Sync failed: $e');
}
```

---

## 📚 Additional Resources

- **Phase 3 Plan**: `docs/plans/offline-mode/PHASE_3_SYNCHRONIZATION.md`
- **Progress Tracking**: `docs/plans/offline-mode/PHASE_3_PROGRESS.md`
- **Implementation Summary**: `PHASE_3_IMPLEMENTATION_COMPLETE.md`
- **Session Summary**: `PHASE_3_SESSION_SUMMARY_2024-12-13.md`

---

**Last Updated**: 2024-12-13  
**Version**: 1.0  
**Status**: Active
