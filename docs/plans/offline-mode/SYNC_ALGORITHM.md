# Synchronization Algorithm Documentation

**Version**: 1.0  
**Last Updated**: 2024-12-13  
**Status**: Complete

---

## Overview

The Waterfly III synchronization engine implements a robust, conflict-aware bidirectional sync algorithm that ensures data consistency between local offline storage and the Firefly III server.

---

## Core Algorithm

### 1. Sync Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                     SYNC WORKFLOW                            │
└─────────────────────────────────────────────────────────────┘

1. PREPARE
   ├─ Acquire sync lock (prevent concurrent syncs)
   ├─ Check connectivity
   ├─ Get pending operations from queue
   └─ Group operations by entity type

2. SYNC (Push Local Changes)
   ├─ Process operations in batches (20 ops/batch)
   ├─ Execute with retry strategy (max 5 attempts)
   ├─ Protect with circuit breaker
   ├─ Track progress in real-time
   └─ Handle errors gracefully

3. DETECT CONFLICTS
   ├─ Compare local vs remote versions
   ├─ Identify conflicting fields
   ├─ Calculate conflict severity
   └─ Store conflicts in database

4. RESOLVE CONFLICTS
   ├─ Auto-resolve low/medium severity
   ├─ Apply resolution strategy
   ├─ Update local and/or remote
   └─ Mark conflicts as resolved

5. PULL (Fetch Remote Changes)
   ├─ Get last sync timestamp
   ├─ Fetch changes since last sync
   ├─ Merge with local data
   └─ Don't overwrite pending changes

6. FINALIZE
   ├─ Validate data consistency
   ├─ Update sync statistics
   ├─ Set last sync timestamp
   └─ Release sync lock

7. COMPLETE
   ├─ Emit completion event
   ├─ Return sync result
   └─ Schedule next sync
```

---

## 2. Conflict Detection Algorithm

### Detection Process

```dart
Future<Conflict?> detectConflict(
  SyncOperation operation,
  Map<String, dynamic>? remoteData,
) async {
  // 1. Determine conflict type
  if (operation.operation == DELETE && remoteData != null) {
    return ConflictType.deleteUpdate;
  }
  if (operation.operation == UPDATE && remoteData == null) {
    return ConflictType.updateDelete;
  }
  if (operation.operation == CREATE && remoteData != null) {
    return ConflictType.createExists;
  }
  
  // 2. Compare timestamps
  final localUpdated = operation.payload['updated_at'];
  final remoteUpdated = remoteData['updated_at'];
  
  if (localUpdated <= remoteUpdated) {
    return null; // No conflict, remote is newer
  }
  
  // 3. Deep field comparison
  final conflictingFields = getConflictingFields(
    operation.payload,
    remoteData,
  );
  
  if (conflictingFields.isEmpty) {
    return null; // No actual conflicts
  }
  
  // 4. Calculate severity
  final severity = calculateSeverity(
    conflictingFields,
    operation.entityType,
  );
  
  // 5. Create conflict object
  return Conflict(
    operationId: operation.id,
    entityType: operation.entityType,
    entityId: operation.entityId,
    conflictType: ConflictType.updateUpdate,
    localData: operation.payload,
    remoteData: remoteData,
    conflictingFields: conflictingFields,
    severity: severity,
    detectedAt: DateTime.now(),
  );
}
```

### Severity Calculation

```
CRITICAL FIELDS (HIGH severity):
- amount (transactions)
- date (transactions)
- account_id (transactions)
- current_balance (accounts)

IMPORTANT FIELDS (MEDIUM severity):
- description
- category_id
- budget_id
- notes

OTHER FIELDS (LOW severity):
- tags
- metadata
- custom fields
```

---

## 3. Conflict Resolution Strategies

### Strategy Selection Matrix

| Severity | Age | Auto-Resolve | Strategy |
|----------|-----|--------------|----------|
| LOW | Any | Yes | lastWriteWins |
| MEDIUM | < 24h | Yes | lastWriteWins |
| MEDIUM | > 24h | No | Manual |
| HIGH | Any | No | Manual |

### Resolution Algorithms

#### 3.1 Local Wins
```dart
Future<Map<String, dynamic>> resolveLocalWins(Conflict conflict) async {
  // 1. Take local data
  final resolvedData = conflict.localData;
  
  // 2. Push to server
  await apiClient.update(
    conflict.entityType,
    conflict.entityId,
    resolvedData,
  );
  
  // 3. Update local with server response
  await database.update(
    conflict.entityType,
    conflict.entityId,
    serverResponse,
  );
  
  return resolvedData;
}
```

#### 3.2 Remote Wins
```dart
Future<Map<String, dynamic>> resolveRemoteWins(Conflict conflict) async {
  // 1. Take remote data
  final resolvedData = conflict.remoteData;
  
  // 2. Update local database
  await database.update(
    conflict.entityType,
    conflict.entityId,
    resolvedData,
  );
  
  // 3. Remove from sync queue
  await queueManager.removeOperation(conflict.operationId);
  
  return resolvedData;
}
```

#### 3.3 Last Write Wins
```dart
Future<Map<String, dynamic>> resolveLastWriteWins(Conflict conflict) async {
  // 1. Parse timestamps
  final localTime = parseDateTime(conflict.localData['updated_at']);
  final remoteTime = parseDateTime(conflict.remoteData['updated_at']);
  
  // 2. Compare and choose winner
  if (localTime.isAfter(remoteTime)) {
    return await resolveLocalWins(conflict);
  } else {
    return await resolveRemoteWins(conflict);
  }
}
```

#### 3.4 Merge
```dart
Future<Map<String, dynamic>> resolveMerge(Conflict conflict) async {
  final merged = <String, dynamic>{};
  final conflictingFields = conflict.conflictingFields.toSet();
  
  // 1. Get all unique keys
  final allKeys = {
    ...conflict.localData.keys,
    ...conflict.remoteData.keys,
  };
  
  // 2. Merge fields
  for (final key in allKeys) {
    if (conflictingFields.contains(key)) {
      // Use lastWriteWins for conflicting fields
      final localTime = parseDateTime(conflict.localData['updated_at']);
      final remoteTime = parseDateTime(conflict.remoteData['updated_at']);
      
      merged[key] = localTime.isAfter(remoteTime)
          ? conflict.localData[key]
          : conflict.remoteData[key];
    } else {
      // Use remote for non-conflicting fields
      merged[key] = conflict.remoteData.containsKey(key)
          ? conflict.remoteData[key]
          : conflict.localData[key];
    }
  }
  
  // 3. Push merged version to server
  await apiClient.update(
    conflict.entityType,
    conflict.entityId,
    merged,
  );
  
  return merged;
}
```

---

## 4. Retry Strategy

### Exponential Backoff Algorithm

```
Delay = min(
  initialDelay * (exponentialFactor ^ (attempt - 1)) * (1 + jitter),
  maxDelay
)

Where:
- initialDelay = 1 second
- exponentialFactor = 2.0
- jitter = random(-0.2, +0.2)
- maxDelay = 60 seconds

Example delays:
- Attempt 1: 1s ± 20% = 0.8-1.2s
- Attempt 2: 2s ± 20% = 1.6-2.4s
- Attempt 3: 4s ± 20% = 3.2-4.8s
- Attempt 4: 8s ± 20% = 6.4-9.6s
- Attempt 5: 16s ± 20% = 12.8-19.2s
```

### Retry Decision Tree

```
┌─────────────────┐
│  Error Occurs   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ Is Retryable?   │
└────┬───────┬────┘
     │       │
    Yes     No
     │       │
     ▼       ▼
┌─────────┐ ┌──────────┐
│ Retry   │ │ Fail     │
│ with    │ │ Immediately│
│ Backoff │ └──────────┘
└────┬────┘
     │
     ▼
┌─────────────────┐
│ Max Attempts?   │
└────┬───────┬────┘
     │       │
    No      Yes
     │       │
     ▼       ▼
┌─────────┐ ┌──────────┐
│ Wait &  │ │ Fail     │
│ Retry   │ │ Permanently│
└─────────┘ └──────────┘
```

---

## 5. Circuit Breaker Pattern

### State Machine

```
┌──────────┐
│  CLOSED  │ ◄─────────────────┐
└────┬─────┘                   │
     │                         │
     │ Failure Threshold       │ Success Threshold
     │ Reached (5 failures)    │ Reached (2 successes)
     │                         │
     ▼                         │
┌──────────┐                   │
│   OPEN   │                   │
└────┬─────┘                   │
     │                         │
     │ Reset Timeout           │
     │ Elapsed (60s)           │
     │                         │
     ▼                         │
┌──────────┐                   │
│ HALF_OPEN│ ──────────────────┘
└──────────┘
```

### State Behaviors

**CLOSED**:
- All requests pass through
- Failures increment counter
- Successes reset counter

**OPEN**:
- All requests rejected immediately
- Throws CircuitBreakerOpenError
- Waits for reset timeout

**HALF_OPEN**:
- Limited requests allowed
- Testing if service recovered
- Success → CLOSED
- Failure → OPEN

---

## 6. Batch Processing

### Batch Algorithm

```dart
Future<void> processBatch(List<SyncOperation> operations) async {
  final futures = <Future>[];
  
  for (final operation in operations) {
    // Limit concurrent operations
    if (futures.length >= maxConcurrentOperations) {
      await Future.any(futures);
      futures.removeWhere((f) => f.hashCode == f.hashCode);
    }
    
    // Process operation
    futures.add(
      circuitBreaker.execute(
        () => retryStrategy.retryOperation(
          () => syncEntity(operation),
        ),
      ),
    );
  }
  
  // Wait for remaining
  await Future.wait(futures, eagerError: false);
}
```

### Batch Configuration

- **Batch Size**: 20 operations
- **Max Concurrent**: 5 operations
- **Batch Timeout**: 60 seconds
- **Continue on Failure**: Yes

---

## 7. Progress Tracking

### Progress Calculation

```dart
// Percentage
percentage = (completed + failed + skipped) / total * 100

// Throughput (ops/sec)
throughput = recentCompletions / timeWindow

// ETA
remaining = total - (completed + failed + skipped)
eta = remaining / throughput

// Success Rate
successRate = completed / (completed + failed)
```

### Progress Phases

1. **PREPARING** - Initializing sync
2. **SYNCING** - Pushing local changes
3. **DETECTING_CONFLICTS** - Comparing versions
4. **RESOLVING_CONFLICTS** - Applying strategies
5. **PULLING** - Fetching remote changes
6. **FINALIZING** - Validating consistency
7. **COMPLETED** - Sync successful
8. **FAILED** - Sync failed

---

## 8. Data Consistency

### Consistency Checks

1. **Missing Synced Server IDs**
   - Find: `is_synced = true AND server_id IS NULL`
   - Fix: Set `is_synced = false`

2. **Orphaned Operations**
   - Find: Operations referencing deleted entities
   - Fix: Remove from queue

3. **Duplicate Operations**
   - Find: Multiple operations for same entity
   - Fix: Keep latest, remove others

4. **Broken References**
   - Find: Foreign key violations
   - Fix: Depends on reference type

5. **Balance Mismatches**
   - Find: Calculated balance ≠ stored balance
   - Fix: Recalculate from transactions

6. **Timestamp Inconsistencies**
   - Find: `updated_at < created_at`
   - Fix: Set `updated_at = created_at`

---

## 9. Performance Characteristics

### Time Complexity

| Operation | Complexity | Notes |
|-----------|------------|-------|
| Conflict Detection | O(n*m) | n=operations, m=fields |
| Batch Processing | O(n/b) | b=batch size |
| Progress Tracking | O(1) | Constant time updates |
| Retry Strategy | O(k) | k=max attempts |
| Circuit Breaker | O(1) | Constant time checks |

### Space Complexity

| Component | Complexity | Notes |
|-----------|------------|-------|
| Progress Tracker | O(1) | Bounded buffer (100 samples) |
| Conflict Storage | O(c) | c=number of conflicts |
| Retry Strategy | O(1) | Stateless |
| Circuit Breaker | O(1) | Fixed state size |

### Performance Targets

- **Throughput**: >10 operations/second
- **Latency**: <100ms per operation
- **Memory**: <50MB for 1000 operations
- **Battery**: <5% per 100 operations

---

## 10. Error Handling

### Error Classification

```
Retryable Errors:
├─ NetworkError (connectivity issues)
├─ ServerError (5xx responses)
├─ TimeoutError (request timeouts)
└─ RateLimitError (429 responses)

Non-Retryable Errors:
├─ ClientError (4xx responses)
├─ ConflictError (requires resolution)
├─ AuthenticationError (401)
├─ ValidationError (invalid data)
└─ CircuitBreakerOpenError (circuit open)
```

### Error Recovery

1. **Transient Errors** → Retry with backoff
2. **Conflicts** → Detect and resolve
3. **Validation Errors** → Notify user
4. **Auth Errors** → Re-authenticate
5. **Circuit Open** → Wait for reset

---

## 11. Sequence Diagrams

### Full Sync Sequence

```
User          SyncManager    Queue    API    Database
 │                │            │       │        │
 │─sync()────────>│            │       │        │
 │                │─lock()─────┤       │        │
 │                │            │       │        │
 │                │─getOps()──>│       │        │
 │                │<───────────┤       │        │
 │                │            │       │        │
 │                │─batch()────┤       │        │
 │                │            │       │        │
 │                │─sync()─────┼──────>│        │
 │                │<───────────┼───────┤        │
 │                │            │       │        │
 │                │─update()───┼───────┼───────>│
 │                │<───────────┼───────┼────────┤
 │                │            │       │        │
 │                │─unlock()───┤       │        │
 │<───result──────│            │       │        │
```

---

## References

- [Firefly III API Documentation](https://docs.firefly-iii.org/api/)
- [Conflict-Free Replicated Data Types](https://en.wikipedia.org/wiki/Conflict-free_replicated_data_type)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff)

---

**Document Version**: 1.0  
**Author**: Implementation Team  
**Date**: 2024-12-13
