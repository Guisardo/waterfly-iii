# Phase 3: Synchronization Engine (Week 5-6)

## Overview
Build the synchronization engine to sync offline changes with the Firefly III server, including conflict detection, resolution strategies, and retry logic with exponential backoff.

## Goals
- Implement automatic synchronization when connectivity is restored
- Detect and resolve data conflicts
- Handle sync failures with retry logic
- Ensure data consistency between local and remote
- Provide sync progress feedback to users

---

## Checklist

### 1. Sync Manager Core

#### 1.1 Create Sync Manager Service
- [ ] Create `lib/services/sync/sync_manager.dart`
- [ ] Implement singleton pattern
- [ ] Add dependency injection for repositories and queue manager
- [ ] Add `retry` package for exponential backoff
- [ ] Add `synchronized` package for mutex locks
- [ ] Initialize with configuration (max retries, timeout, batch size)

#### 1.2 Implement Main Sync Method
- [ ] Add method: `Future<SyncResult> synchronize()`
  - [ ] Acquire sync lock to prevent concurrent syncs
  - [ ] Check connectivity status
  - [ ] Get pending operations from queue
  - [ ] Group operations by entity type
  - [ ] Process operations in batches
  - [ ] Track sync progress
  - [ ] Handle errors and rollback if needed
  - [ ] Release sync lock
  - [ ] Return sync result with statistics
  - [ ] Add comprehensive logging with exc_info=True

- [ ] Add method: `Future<void> syncEntity(SyncOperation operation)`
  - [ ] Determine operation type (create/update/delete)
  - [ ] Call appropriate sync method
  - [ ] Handle API errors
  - [ ] Update local database on success
  - [ ] Map local ID to server ID
  - [ ] Mark operation as completed
  - [ ] Add logging

- [ ] Add method: `Future<void> syncTransaction(SyncOperation operation)`
  - [ ] Parse operation payload
  - [ ] Resolve ID references (accounts, categories)
  - [ ] Call Firefly III API
  - [ ] Handle response
  - [ ] Update local transaction with server data
  - [ ] Map IDs
  - [ ] Add logging

- [ ] Add method: `Future<void> syncAccount(SyncOperation operation)`
- [ ] Add method: `Future<void> syncCategory(SyncOperation operation)`
- [ ] Add method: `Future<void> syncBudget(SyncOperation operation)`
- [ ] Add method: `Future<void> syncBill(SyncOperation operation)`
- [ ] Add method: `Future<void> syncPiggyBank(SyncOperation operation)`

#### 1.3 Implement Batch Processing
- [ ] Add method: `Future<void> processBatch(List<SyncOperation> operations)`
  - [ ] Process operations in parallel (max 5 concurrent)
  - [ ] Track batch progress
  - [ ] Handle partial failures
  - [ ] Continue on individual failures
  - [ ] Collect batch results
  - [ ] Add logging

- [ ] Configure batch size (default: 20 operations)
- [ ] Add batch timeout (default: 60 seconds)
- [ ] Implement batch retry logic
- [ ] Add batch progress events

#### 1.4 Add Sync Scheduling
- [ ] Add method: `Future<void> scheduleSync()`
  - [ ] Check if sync is needed (queue not empty)
  - [ ] Check connectivity
  - [ ] Check if already syncing
  - [ ] Start sync in background
  - [ ] Add logging

- [ ] Add method: `Future<void> schedulePeriodic(Duration interval)`
  - [ ] Use `workmanager` for background scheduling
  - [ ] Configure constraints (network required)
  - [ ] Set interval (default: 15 minutes)
  - [ ] Add logging

- [ ] Add method: `void cancelScheduledSync()`
  - [ ] Cancel workmanager tasks
  - [ ] Clear pending schedules
  - [ ] Add logging

### 2. Conflict Detection

#### 2.1 Create Conflict Detector
- [ ] Create `lib/services/sync/conflict_detector.dart`
- [ ] Add method: `Future<Conflict?> detectConflict(SyncOperation operation)`
  - [ ] Fetch current server version of entity
  - [ ] Compare with local version
  - [ ] Check timestamps (updated_at)
  - [ ] Compare field values
  - [ ] Identify conflicting fields
  - [ ] Return Conflict object if found
  - [ ] Add logging

- [ ] Add method: `List<String> getConflictingFields(Entity local, Entity remote)`
  - [ ] Compare all fields
  - [ ] Identify differences
  - [ ] Return list of field names
  - [ ] Add logging

#### 2.2 Define Conflict Model
- [ ] Create `lib/models/conflict.dart`
- [ ] Add fields: operationId, entityType, entityId, localVersion, remoteVersion, conflictingFields, detectedAt
- [ ] Add method: `ConflictSeverity getSeverity()`
  - [ ] LOW: Only non-critical fields differ
  - [ ] MEDIUM: Important fields differ
  - [ ] HIGH: Critical fields differ (amount, date, etc.)
- [ ] Add `toJson` and `fromJson` methods
- [ ] Add equality and hashCode

#### 2.3 Implement Conflict Types
- [ ] Define `ConflictType` enum:
  - [ ] UPDATE_UPDATE: Both local and remote updated
  - [ ] UPDATE_DELETE: Local updated, remote deleted
  - [ ] DELETE_UPDATE: Local deleted, remote updated
  - [ ] CREATE_EXISTS: Local create, entity already exists on server

- [ ] Add method to determine conflict type
- [ ] Add conflict type to Conflict model
- [ ] Add logging for each conflict type

#### 2.4 Store Conflicts
- [ ] Create `conflicts_table.dart` in database
  - [ ] id (text, primary key)
  - [ ] operation_id (text)
  - [ ] entity_type (text)
  - [ ] entity_id (text)
  - [ ] conflict_type (text)
  - [ ] local_data (text, JSON)
  - [ ] remote_data (text, JSON)
  - [ ] conflicting_fields (text, JSON array)
  - [ ] severity (text)
  - [ ] detected_at (datetime)
  - [ ] resolved_at (datetime, nullable)
  - [ ] resolution_strategy (text, nullable)
  - [ ] resolved_by (text, nullable: user, auto)

- [ ] Add method: `Future<void> storeConflict(Conflict conflict)`
- [ ] Add method: `Future<List<Conflict>> getUnresolvedConflicts()`
- [ ] Add method: `Future<Conflict?> getConflictByOperationId(String id)`

### 3. Conflict Resolution

#### 3.1 Create Conflict Resolver
- [ ] Create `lib/services/sync/conflict_resolver.dart`
- [ ] Add method: `Future<Resolution> resolveConflict(Conflict conflict, ResolutionStrategy strategy)`
  - [ ] Apply resolution strategy
  - [ ] Merge data if needed
  - [ ] Update local or remote
  - [ ] Mark conflict as resolved
  - [ ] Update sync queue
  - [ ] Add logging

#### 3.2 Implement Resolution Strategies
- [ ] Define `ResolutionStrategy` enum:
  - [ ] LOCAL_WINS: Keep local changes, overwrite remote
  - [ ] REMOTE_WINS: Keep remote changes, overwrite local
  - [ ] LAST_WRITE_WINS: Use timestamp to determine winner
  - [ ] MANUAL: User must choose
  - [ ] MERGE: Attempt to merge both versions

- [ ] Implement `resolveLocalWins(Conflict conflict)`
  - [ ] Push local version to server
  - [ ] Update local with server response
  - [ ] Mark as resolved
  - [ ] Add logging

- [ ] Implement `resolveRemoteWins(Conflict conflict)`
  - [ ] Fetch remote version
  - [ ] Overwrite local version
  - [ ] Remove from sync queue
  - [ ] Mark as resolved
  - [ ] Add logging

- [ ] Implement `resolveLastWriteWins(Conflict conflict)`
  - [ ] Compare timestamps
  - [ ] Apply LOCAL_WINS or REMOTE_WINS
  - [ ] Add logging

- [ ] Implement `resolveMerge(Conflict conflict)`
  - [ ] Merge non-conflicting fields
  - [ ] For conflicting fields, use LAST_WRITE_WINS
  - [ ] Create merged entity
  - [ ] Push to server
  - [ ] Update local
  - [ ] Mark as resolved
  - [ ] Add logging

#### 3.3 Implement Automatic Resolution
- [ ] Add method: `Future<void> autoResolveConflicts()`
  - [ ] Get all unresolved conflicts
  - [ ] Apply default strategy (LAST_WRITE_WINS)
  - [ ] Resolve low severity conflicts automatically
  - [ ] Keep medium/high severity for manual resolution
  - [ ] Add logging

- [ ] Configure auto-resolution rules:
  - [ ] LOW severity: Always auto-resolve
  - [ ] MEDIUM severity: Auto-resolve if < 24 hours old
  - [ ] HIGH severity: Always require manual resolution

- [ ] Add setting to enable/disable auto-resolution

#### 3.4 Implement Manual Resolution UI Support
- [ ] Add method: `Future<void> resolveManually(String conflictId, ResolutionStrategy strategy)`
  - [ ] Validate conflict exists
  - [ ] Apply user-selected strategy
  - [ ] Mark as resolved by user
  - [ ] Add logging

- [ ] Add method: `Future<void> resolveWithCustomData(String conflictId, Entity customData)`
  - [ ] Allow user to edit merged version
  - [ ] Validate custom data
  - [ ] Push to server
  - [ ] Update local
  - [ ] Mark as resolved
  - [ ] Add logging

### 4. Retry Logic & Error Handling

#### 4.1 Implement Retry Strategy
- [ ] Use `retry` package for exponential backoff
- [ ] Configure retry parameters:
  - [ ] Max attempts: 5
  - [ ] Initial delay: 1 second
  - [ ] Max delay: 60 seconds
  - [ ] Exponential factor: 2
  - [ ] Jitter: ±20%

- [ ] Add method: `Future<T> retryOperation<T>(Future<T> Function() operation)`
  - [ ] Wrap operation in retry logic
  - [ ] Log each attempt
  - [ ] Increase delay exponentially
  - [ ] Add jitter to prevent thundering herd
  - [ ] Throw after max attempts
  - [ ] Add comprehensive logging with exc_info=True

#### 4.2 Implement Error Classification
- [ ] Create `lib/exceptions/sync_errors.dart`
- [ ] Define error types:
  - [ ] `NetworkError`: No connectivity, timeout
  - [ ] `ServerError`: 5xx responses
  - [ ] `ClientError`: 4xx responses
  - [ ] `ConflictError`: 409 conflict
  - [ ] `AuthenticationError`: 401 unauthorized
  - [ ] `ValidationError`: Invalid data
  - [ ] `RateLimitError`: 429 too many requests

- [ ] Add method: `bool isRetryable(Exception error)`
  - [ ] NetworkError: Retryable
  - [ ] ServerError: Retryable
  - [ ] ClientError: Not retryable (except 429)
  - [ ] ConflictError: Not retryable (needs resolution)
  - [ ] AuthenticationError: Not retryable
  - [ ] ValidationError: Not retryable

- [ ] Add method: `Duration getRetryDelay(Exception error, int attempt)`
  - [ ] Calculate delay based on error type
  - [ ] Use exponential backoff
  - [ ] Respect Retry-After header for 429
  - [ ] Add jitter

#### 4.3 Implement Error Recovery
- [ ] Add method: `Future<void> handleSyncError(SyncOperation operation, Exception error)`
  - [ ] Classify error
  - [ ] Determine if retryable
  - [ ] Update operation status
  - [ ] Increment retry count
  - [ ] Store error message
  - [ ] Schedule retry if applicable
  - [ ] Notify user if not retryable
  - [ ] Add comprehensive logging with exc_info=True

- [ ] Add method: `Future<void> handleNetworkError(SyncOperation operation)`
  - [ ] Mark operation as pending
  - [ ] Wait for connectivity
  - [ ] Retry when online
  - [ ] Add logging

- [ ] Add method: `Future<void> handleConflictError(SyncOperation operation)`
  - [ ] Detect conflict
  - [ ] Store conflict
  - [ ] Remove from sync queue
  - [ ] Notify user
  - [ ] Add logging

- [ ] Add method: `Future<void> handleValidationError(SyncOperation operation, ValidationError error)`
  - [ ] Mark operation as failed
  - [ ] Store detailed error
  - [ ] Notify user
  - [ ] Provide fix suggestions
  - [ ] Add logging

#### 4.4 Implement Circuit Breaker
- [ ] Add circuit breaker pattern for API calls
- [ ] Configure thresholds:
  - [ ] Failure threshold: 5 consecutive failures
  - [ ] Timeout: 30 seconds
  - [ ] Reset timeout: 60 seconds

- [ ] Add method: `bool isCircuitOpen()`
  - [ ] Check failure count
  - [ ] Check last failure time
  - [ ] Return circuit state

- [ ] Add method: `void recordSuccess()`
  - [ ] Reset failure count
  - [ ] Close circuit

- [ ] Add method: `void recordFailure()`
  - [ ] Increment failure count
  - [ ] Open circuit if threshold reached
  - [ ] Add logging

### 5. Data Consistency

#### 5.1 Implement Consistency Checks
- [ ] Add method: `Future<void> validateConsistency()`
  - [ ] Check referential integrity
  - [ ] Verify all synced entities have server IDs
  - [ ] Check for orphaned records
  - [ ] Verify balance calculations
  - [ ] Add logging

- [ ] Add method: `Future<List<InconsistencyIssue>> detectInconsistencies()`
  - [ ] Find entities with is_synced=true but no server_id
  - [ ] Find operations in queue for deleted entities
  - [ ] Find duplicate operations
  - [ ] Return list of issues

- [ ] Add method: `Future<void> repairInconsistencies(List<InconsistencyIssue> issues)`
  - [ ] Fix each issue type
  - [ ] Remove invalid operations
  - [ ] Update entity states
  - [ ] Add logging

#### 5.2 Implement Transaction Integrity
- [ ] Wrap sync operations in database transactions
- [ ] Add method: `Future<void> syncWithTransaction(SyncOperation operation)`
  - [ ] Begin transaction
  - [ ] Execute sync
  - [ ] Update local database
  - [ ] Update sync queue
  - [ ] Commit transaction
  - [ ] Rollback on error
  - [ ] Add logging

- [ ] Ensure atomic updates (all or nothing)
- [ ] Handle transaction deadlocks
- [ ] Add transaction timeout

#### 5.3 Implement Idempotency
- [ ] Add idempotency keys to API requests
- [ ] Store idempotency keys in operations
- [ ] Reuse keys on retry
- [ ] Handle duplicate request responses
- [ ] Add logging

### 6. Sync Progress & Monitoring

#### 6.1 Create Sync Progress Tracker
- [ ] Create `lib/services/sync/sync_progress_tracker.dart`
- [ ] Add method: `Stream<SyncProgress> watchProgress()`
  - [ ] Emit progress updates
  - [ ] Include: total operations, completed, failed, current operation
  - [ ] Calculate percentage
  - [ ] Estimate time remaining

- [ ] Add method: `void updateProgress(SyncProgress progress)`
  - [ ] Update current state
  - [ ] Emit to stream
  - [ ] Add logging

- [ ] Define `SyncProgress` model:
  - [ ] totalOperations
  - [ ] completedOperations
  - [ ] failedOperations
  - [ ] currentOperation
  - [ ] percentage
  - [ ] estimatedTimeRemaining
  - [ ] startTime
  - [ ] errors

#### 6.2 Implement Sync Statistics
- [ ] Add method: `Future<SyncStatistics> getStatistics()`
  - [ ] Total syncs performed
  - [ ] Success rate
  - [ ] Average sync duration
  - [ ] Total operations synced
  - [ ] Conflicts detected
  - [ ] Conflicts resolved
  - [ ] Last sync time
  - [ ] Next scheduled sync

- [ ] Store statistics in metadata table
- [ ] Update statistics after each sync
- [ ] Add method to reset statistics

#### 6.3 Add Sync Events
- [ ] Define `SyncEvent` types:
  - [ ] SYNC_STARTED
  - [ ] SYNC_PROGRESS
  - [ ] SYNC_COMPLETED
  - [ ] SYNC_FAILED
  - [ ] CONFLICT_DETECTED
  - [ ] CONFLICT_RESOLVED

- [ ] Create event stream: `Stream<SyncEvent> watchEvents()`
- [ ] Emit events at appropriate times
- [ ] Add event logging

### 7. Full Sync Implementation

#### 7.1 Implement Initial Sync
- [ ] Add method: `Future<void> performInitialSync()`
  - [ ] Fetch all data from server
  - [ ] Clear local database
  - [ ] Insert server data
  - [ ] Mark all as synced
  - [ ] Set last_full_sync timestamp
  - [ ] Add logging

- [ ] Add progress tracking for initial sync
- [ ] Handle large datasets (pagination)
- [ ] Add cancellation support

#### 7.2 Implement Incremental Sync
- [ ] Add method: `Future<void> performIncrementalSync()`
  - [ ] Get last sync timestamp
  - [ ] Fetch changes since last sync
  - [ ] Merge with local data
  - [ ] Resolve conflicts
  - [ ] Update last_partial_sync timestamp
  - [ ] Add logging

- [ ] Optimize for minimal data transfer
- [ ] Use ETags for caching
- [ ] Handle pagination

#### 7.3 Implement Pull Sync
- [ ] Add method: `Future<void> pullFromServer()`
  - [ ] Fetch latest data from server
  - [ ] Update local database
  - [ ] Don't overwrite pending local changes
  - [ ] Add logging

- [ ] Schedule periodic pull (every hour)
- [ ] Add manual pull trigger

### 8. Testing

#### 8.1 Unit Tests
- [ ] Test sync manager methods
- [ ] Test conflict detection
- [ ] Test conflict resolution strategies
- [ ] Test retry logic
- [ ] Test error handling
- [ ] Test consistency checks
- [ ] Test progress tracking
- [ ] Achieve >85% code coverage

#### 8.2 Integration Tests
- [ ] Test full sync flow
- [ ] Test incremental sync
- [ ] Test conflict resolution flow
- [ ] Test retry with exponential backoff
- [ ] Test circuit breaker
- [ ] Test transaction integrity

#### 8.3 Scenario Tests
- [ ] Test sync with 100+ operations
- [ ] Test sync with conflicts
- [ ] Test sync with network interruption
- [ ] Test sync with server errors
- [ ] Test concurrent modifications
- [ ] Test sync after long offline period

#### 8.4 Performance Tests
- [ ] Measure sync throughput (operations/second)
- [ ] Test with large datasets (1000+ transactions)
- [ ] Measure memory usage during sync
- [ ] Test battery impact
- [ ] Profile slow operations

### 9. Documentation

#### 9.1 Technical Documentation
- [ ] Document sync algorithm
- [ ] Document conflict resolution strategies
- [ ] Document retry logic
- [ ] Document error handling
- [ ] Add sequence diagrams

#### 9.2 API Documentation
- [ ] Document sync manager API
- [ ] Document conflict resolver API
- [ ] Add usage examples
- [ ] Document configuration options

#### 9.3 Troubleshooting Guide
- [ ] Common sync issues
- [ ] Error messages and solutions
- [ ] How to resolve conflicts manually
- [ ] How to force full sync

### 10. Code Review & Cleanup

#### 10.1 Code Quality
- [ ] Format all code
- [ ] Fix linter warnings
- [ ] Remove debug code
- [ ] Add comprehensive logging with exc_info=True
- [ ] Add TODO comments for Phase 4

#### 10.2 Security Review
- [ ] Verify API authentication
- [ ] Check for data leaks in logs
- [ ] Verify conflict data security
- [ ] Review error messages

#### 10.3 Performance Optimization
- [ ] Optimize batch processing
- [ ] Reduce API calls
- [ ] Minimize database writes
- [ ] Profile and optimize hot paths

---

## Deliverables

- [ ] Working sync engine
- [ ] Conflict detection and resolution
- [ ] Retry logic with exponential backoff
- [ ] Progress tracking
- [ ] Full and incremental sync
- [ ] Comprehensive test suite (>85% coverage)
- [ ] Documentation

## Success Criteria

- [ ] Sync completes successfully for 100+ operations
- [ ] Conflicts detected and resolved correctly
- [ ] Retry logic handles transient failures
- [ ] Sync throughput >10 operations/second
- [ ] No data loss during sync
- [ ] All tests pass
- [ ] Code review approved

## Dependencies for Next Phase

- Working sync engine
- Conflict resolution system
- Progress tracking

---

**Phase Status**: Not Started  
**Estimated Effort**: 80 hours (2 weeks)  
**Priority**: High  
**Blocking**: Phase 2 completion
