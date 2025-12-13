# Phase 2: Core Offline Functionality (Week 3-4)

## Overview
Implement core offline functionality including local CRUD operations, sync queue system, operation tracking, and UUID generation for offline-created entities.

## Goals
- Enable full CRUD operations in offline mode
- Implement sync queue for tracking pending operations
- Add operation metadata and tracking
- Generate conflict-free UUIDs for offline entities
- Ensure data integrity during offline operations

---

## Checklist

### 1. Local CRUD Operations

#### 1.1 Transaction Operations
- [ ] Implement `createTransactionOffline(Transaction)` in repository
  - [ ] Generate UUID for new transaction
  - [ ] Set `is_synced = false`
  - [ ] Set `sync_status = 'pending'`
  - [ ] Set timestamps (created_at, updated_at)
  - [ ] Validate all required fields
  - [ ] Insert into local database
  - [ ] Add to sync queue
  - [ ] Return created transaction with local ID
  - [ ] Add comprehensive logging
  - [ ] Handle validation errors with specific exceptions

- [ ] Implement `updateTransactionOffline(String id, Transaction)` in repository
  - [ ] Verify transaction exists locally
  - [ ] Update `updated_at` timestamp
  - [ ] Set `is_synced = false` if was previously synced
  - [ ] Update `sync_status = 'pending'`
  - [ ] Update in local database
  - [ ] Add update operation to sync queue
  - [ ] Return updated transaction
  - [ ] Handle not found errors
  - [ ] Add logging

- [ ] Implement `deleteTransactionOffline(String id)` in repository
  - [ ] Verify transaction exists
  - [ ] Check if transaction was synced (has server_id)
  - [ ] If synced: mark as deleted, add to sync queue
  - [ ] If not synced: remove from database and sync queue
  - [ ] Handle cascade deletes if needed
  - [ ] Add logging
  - [ ] Return success status

- [ ] Implement `getTransactionsOffline(filters)` in repository
  - [ ] Query local database with filters
  - [ ] Support date range filtering
  - [ ] Support account filtering
  - [ ] Support category filtering
  - [ ] Support search by description
  - [ ] Return sorted results (newest first)
  - [ ] Add pagination support
  - [ ] Cache query results
  - [ ] Add logging

- [ ] Implement `getTransactionByIdOffline(String id)` in repository
  - [ ] Query local database by ID
  - [ ] Include related entities (accounts, categories)
  - [ ] Handle not found case
  - [ ] Add logging

#### 1.2 Account Operations
- [ ] Implement `createAccountOffline(Account)` in repository
  - [ ] Generate UUID
  - [ ] Validate account data
  - [ ] Set sync flags
  - [ ] Insert into database
  - [ ] Add to sync queue
  - [ ] Update account balance cache
  - [ ] Add logging

- [ ] Implement `updateAccountOffline(String id, Account)` in repository
  - [ ] Verify account exists
  - [ ] Update timestamps and sync flags
  - [ ] Update in database
  - [ ] Add to sync queue
  - [ ] Recalculate balance if needed
  - [ ] Add logging

- [ ] Implement `deleteAccountOffline(String id)` in repository
  - [ ] Check for dependent transactions
  - [ ] Prevent deletion if transactions exist (or cascade)
  - [ ] Mark as deleted or remove
  - [ ] Add to sync queue
  - [ ] Add logging

- [ ] Implement `getAccountsOffline(filters)` in repository
  - [ ] Query with type filtering
  - [ ] Include balance calculations
  - [ ] Support search
  - [ ] Add logging

#### 1.3 Category Operations
- [ ] Implement `createCategoryOffline(Category)` in repository
- [ ] Implement `updateCategoryOffline(String id, Category)` in repository
- [ ] Implement `deleteCategoryOffline(String id)` in repository
- [ ] Implement `getCategoriesOffline()` in repository
- [ ] Add validation for duplicate category names
- [ ] Add logging for all operations

#### 1.4 Budget Operations
- [ ] Implement `createBudgetOffline(Budget)` in repository
- [ ] Implement `updateBudgetOffline(String id, Budget)` in repository
- [ ] Implement `deleteBudgetOffline(String id)` in repository
- [ ] Implement `getBudgetsOffline()` in repository
- [ ] Add budget period calculations
- [ ] Add logging

#### 1.5 Bill Operations
- [ ] Implement `createBillOffline(Bill)` in repository
- [ ] Implement `updateBillOffline(String id, Bill)` in repository
- [ ] Implement `deleteBillOffline(String id)` in repository
- [ ] Implement `getBillsOffline()` in repository
- [ ] Add recurrence calculations
- [ ] Add logging

#### 1.6 Piggy Bank Operations
- [ ] Implement `createPiggyBankOffline(PiggyBank)` in repository
- [ ] Implement `updatePiggyBankOffline(String id, PiggyBank)` in repository
- [ ] Implement `deletePiggyBankOffline(String id)` in repository
- [ ] Implement `getPiggyBanksOffline()` in repository
- [ ] Implement `addMoneyToPiggyBank(String id, double amount)` in repository
- [ ] Implement `removeMoneyFromPiggyBank(String id, double amount)` in repository
- [ ] Add balance validation
- [ ] Add logging

### 2. Sync Queue System

#### 2.1 Create Sync Queue Manager
- [ ] Create `lib/services/sync/sync_queue_manager.dart`
- [ ] Implement singleton pattern
- [ ] Add method: `Future<void> enqueue(SyncOperation)` 
  - [ ] Generate operation ID
  - [ ] Set priority based on operation type
  - [ ] Insert into sync_queue table
  - [ ] Emit queue updated event
  - [ ] Add logging

- [ ] Add method: `Future<List<SyncOperation>> getPendingOperations()`
  - [ ] Query operations with status 'pending'
  - [ ] Order by priority (high to low), then created_at (old to new)
  - [ ] Return list of operations
  - [ ] Add logging

- [ ] Add method: `Future<void> markAsProcessing(String operationId)`
  - [ ] Update status to 'processing'
  - [ ] Set last_attempt_at timestamp
  - [ ] Increment attempts counter
  - [ ] Add logging

- [ ] Add method: `Future<void> markAsCompleted(String operationId)`
  - [ ] Update status to 'completed'
  - [ ] Add completion timestamp
  - [ ] Emit queue updated event
  - [ ] Add logging

- [ ] Add method: `Future<void> markAsFailed(String operationId, String error)`
  - [ ] Update status to 'failed'
  - [ ] Store error message
  - [ ] Check if max attempts reached
  - [ ] Schedule retry if attempts < max
  - [ ] Emit queue updated event
  - [ ] Add logging

- [ ] Add method: `Future<int> getQueueCount()`
  - [ ] Count pending and processing operations
  - [ ] Return count
  - [ ] Cache result for performance

- [ ] Add method: `Future<void> clearCompleted()`
  - [ ] Delete operations with status 'completed'
  - [ ] Keep operations from last 7 days for audit
  - [ ] Add logging

- [ ] Add method: `Future<void> retryFailed()`
  - [ ] Reset failed operations to pending
  - [ ] Reset attempts counter
  - [ ] Clear error message
  - [ ] Add logging

- [ ] Add method: `Stream<int> watchQueueCount()`
  - [ ] Return reactive stream of queue count
  - [ ] Update on any queue changes

#### 2.2 Define Sync Operation Model
- [ ] Create `lib/models/sync_operation.dart`
- [ ] Add fields: id, entityType, entityId, operation, payload, createdAt, attempts, status, errorMessage, priority
- [ ] Add `fromJson` and `toJson` methods
- [ ] Add validation methods
- [ ] Add `copyWith` method
- [ ] Add equality and hashCode overrides

#### 2.3 Implement Operation Priority System
- [ ] Define priority levels: HIGH (0), NORMAL (5), LOW (10)
- [ ] Assign priorities:
  - [ ] DELETE operations: HIGH priority
  - [ ] CREATE operations: NORMAL priority
  - [ ] UPDATE operations: NORMAL priority
- [ ] Add method to calculate priority based on operation age
- [ ] Implement priority-based queue ordering

#### 2.4 Add Queue Persistence
- [ ] Ensure queue survives app restarts
- [ ] Implement queue recovery on app startup
- [ ] Validate queue integrity on startup
- [ ] Remove corrupted queue entries
- [ ] Add logging for recovery process

### 3. Operation Tracking & Metadata

#### 3.1 Create Operation Tracker
- [ ] Create `lib/services/sync/operation_tracker.dart`
- [ ] Track operation lifecycle: created → queued → processing → completed/failed
- [ ] Add method: `trackOperation(String operationId, String status)`
- [ ] Store operation history in metadata table
- [ ] Add method: `getOperationHistory(String operationId)`
- [ ] Add method: `getOperationStatistics()` (success rate, avg time, etc.)
- [ ] Add logging for all tracking events

#### 3.2 Add Operation Metadata
- [ ] Store operation creation timestamp
- [ ] Store operation completion timestamp
- [ ] Calculate operation duration
- [ ] Store retry count
- [ ] Store error details for failed operations
- [ ] Add user context (which user initiated operation)
- [ ] Add device context (device ID, app version)

#### 3.3 Implement Operation Deduplication
- [ ] Create `lib/services/sync/deduplication_service.dart`
- [ ] Add method: `isDuplicate(SyncOperation)` 
  - [ ] Check for same entity + operation type
  - [ ] Check within time window (5 minutes)
  - [ ] Compare payload hash
  - [ ] Return true if duplicate found

- [ ] Add method: `mergeDuplicates(List<SyncOperation>)`
  - [ ] Find duplicate operations
  - [ ] Keep most recent operation
  - [ ] Merge payloads if needed
  - [ ] Remove older duplicates
  - [ ] Add logging

- [ ] Integrate deduplication into queue manager
  - [ ] Check for duplicates before enqueuing
  - [ ] Skip duplicate operations
  - [ ] Log skipped duplicates

### 4. UUID Generation for Offline Entities

#### 4.1 Create UUID Service
- [ ] Create `lib/services/uuid/uuid_service.dart`
- [ ] Implement singleton pattern
- [ ] Use `uuid` package for generation
- [ ] Add method: `String generateTransactionId()`
  - [ ] Generate UUID v4
  - [ ] Add prefix: 'offline_txn_'
  - [ ] Ensure uniqueness
  - [ ] Add logging

- [ ] Add method: `String generateAccountId()`
  - [ ] Generate UUID v4
  - [ ] Add prefix: 'offline_acc_'
  - [ ] Add logging

- [ ] Add method: `String generateCategoryId()`
- [ ] Add method: `String generateBudgetId()`
- [ ] Add method: `String generateBillId()`
- [ ] Add method: `String generatePiggyBankId()`
- [ ] Add method: `String generateOperationId()`

#### 4.2 Implement ID Mapping System
- [ ] Create `id_mapping_table.dart` in database
  - [ ] local_id (text, primary key)
  - [ ] server_id (text, unique)
  - [ ] entity_type (text)
  - [ ] created_at (datetime)
  - [ ] synced_at (datetime)

- [ ] Add method: `Future<void> mapIds(String localId, String serverId, String entityType)`
  - [ ] Insert mapping into table
  - [ ] Update entity's server_id field
  - [ ] Add logging

- [ ] Add method: `Future<String?> getServerId(String localId)`
  - [ ] Query mapping table
  - [ ] Return server ID or null
  - [ ] Cache results

- [ ] Add method: `Future<String?> getLocalId(String serverId)`
  - [ ] Query mapping table
  - [ ] Return local ID or null
  - [ ] Cache results

#### 4.3 Handle ID References
- [ ] Update transaction creation to use local IDs for references
- [ ] Update account references in transactions
- [ ] Update category references in transactions
- [ ] Update budget references in transactions
- [ ] Implement ID resolution during sync
- [ ] Add validation for ID references

### 5. Data Integrity & Validation

#### 5.1 Implement Data Validators
- [ ] Create `lib/validators/transaction_validator.dart`
  - [ ] Validate required fields
  - [ ] Validate amount > 0
  - [ ] Validate date not in future
  - [ ] Validate account references exist
  - [ ] Validate currency codes
  - [ ] Return detailed validation errors

- [ ] Create `lib/validators/account_validator.dart`
  - [ ] Validate account name not empty
  - [ ] Validate account type is valid
  - [ ] Validate currency code
  - [ ] Validate opening balance logic

- [ ] Create validators for other entities
- [ ] Add comprehensive error messages
- [ ] Add logging for validation failures

#### 5.2 Implement Referential Integrity
- [ ] Add foreign key constraints in database
- [ ] Implement cascade delete logic
- [ ] Prevent deletion of referenced entities
- [ ] Add integrity checks on startup
- [ ] Add method to repair integrity issues
- [ ] Add logging for integrity violations

#### 5.3 Add Transaction Support
- [ ] Wrap multi-step operations in database transactions
- [ ] Implement rollback on errors
- [ ] Add transaction logging
- [ ] Test transaction isolation
- [ ] Handle transaction deadlocks

### 6. Caching & Performance

#### 6.1 Implement Query Caching
- [ ] Create `lib/services/cache/query_cache.dart`
- [ ] Cache frequently accessed queries
- [ ] Implement LRU cache eviction
- [ ] Set cache size limit (50MB)
- [ ] Add cache invalidation on data changes
- [ ] Add cache hit/miss metrics
- [ ] Add logging

#### 6.2 Optimize Database Queries
- [ ] Add indexes on frequently queried columns
  - [ ] transactions: date, account_id, category_id, is_synced
  - [ ] accounts: type, active
  - [ ] sync_queue: status, priority, created_at
- [ ] Use prepared statements
- [ ] Batch insert operations
- [ ] Optimize JOIN queries
- [ ] Profile slow queries
- [ ] Add query performance logging

#### 6.3 Implement Lazy Loading
- [ ] Load transaction details on demand
- [ ] Load related entities only when needed
- [ ] Implement pagination for large lists
- [ ] Add loading indicators in UI
- [ ] Cache loaded data

### 7. Error Handling & Recovery

#### 7.1 Implement Error Recovery
- [ ] Create `lib/services/recovery/error_recovery_service.dart`
- [ ] Add method: `recoverFromDatabaseError()`
  - [ ] Attempt to repair database
  - [ ] Restore from backup if available
  - [ ] Clear corrupted data
  - [ ] Reinitialize database
  - [ ] Add logging

- [ ] Add method: `recoverFromSyncError()`
  - [ ] Identify problematic operations
  - [ ] Skip or retry operations
  - [ ] Notify user of issues
  - [ ] Add logging

#### 7.2 Add Data Backup
- [ ] Implement automatic database backup
- [ ] Backup before major operations
- [ ] Keep last 3 backups
- [ ] Add method to restore from backup
- [ ] Add backup to cloud storage (optional)
- [ ] Add logging

#### 7.3 Implement Graceful Degradation
- [ ] Handle database full errors
- [ ] Handle out of memory errors
- [ ] Disable features if needed
- [ ] Show user-friendly error messages
- [ ] Add recovery suggestions
- [ ] Add logging

### 8. Testing

#### 8.1 Unit Tests
- [ ] Test all CRUD operations for each entity
- [ ] Test sync queue manager methods
- [ ] Test UUID generation and uniqueness
- [ ] Test operation tracking
- [ ] Test deduplication logic
- [ ] Test validators
- [ ] Test error recovery
- [ ] Achieve >85% code coverage

#### 8.2 Integration Tests
- [ ] Test offline transaction creation flow
- [ ] Test offline account management
- [ ] Test queue persistence across restarts
- [ ] Test ID mapping system
- [ ] Test referential integrity
- [ ] Test transaction rollback

#### 8.3 Performance Tests
- [ ] Test with 1000+ transactions
- [ ] Test with 100+ queued operations
- [ ] Measure query performance
- [ ] Measure cache effectiveness
- [ ] Test memory usage
- [ ] Test battery impact

#### 8.4 Manual Testing
- [ ] Create transaction offline
- [ ] Edit transaction offline
- [ ] Delete transaction offline
- [ ] Create multiple entities offline
- [ ] Verify queue updates
- [ ] Test app restart with pending queue
- [ ] Test with low storage
- [ ] Test with low memory

### 9. Documentation

#### 9.1 API Documentation
- [ ] Document all repository methods
- [ ] Document sync queue API
- [ ] Document UUID service
- [ ] Add usage examples
- [ ] Document error codes

#### 9.2 Architecture Documentation
- [ ] Update architecture diagrams
- [ ] Document data flow for offline operations
- [ ] Document queue processing logic
- [ ] Document ID mapping strategy

#### 9.3 User Documentation
- [ ] Document offline mode capabilities
- [ ] Document limitations
- [ ] Add troubleshooting guide

### 10. Code Review & Cleanup

#### 10.1 Code Quality
- [ ] Format all code
- [ ] Fix linter warnings
- [ ] Remove debug code
- [ ] Remove unused code
- [ ] Add TODO comments for Phase 3

#### 10.2 Security Review
- [ ] Verify data encryption
- [ ] Check for SQL injection vulnerabilities
- [ ] Verify input sanitization
- [ ] Review error messages for sensitive data

#### 10.3 Performance Review
- [ ] Profile critical paths
- [ ] Optimize slow operations
- [ ] Reduce memory allocations
- [ ] Minimize database writes

---

## Deliverables

- [ ] Full offline CRUD for all entities
- [ ] Working sync queue system
- [ ] UUID generation and ID mapping
- [ ] Operation tracking and deduplication
- [ ] Data validation and integrity checks
- [ ] Comprehensive test suite (>85% coverage)
- [ ] Updated documentation

## Success Criteria

- [ ] Users can create/edit/delete all entities offline
- [ ] All operations are queued for sync
- [ ] No duplicate operations in queue
- [ ] UUIDs are unique and conflict-free
- [ ] Data integrity maintained
- [ ] All tests pass
- [ ] Performance meets requirements (<100ms for operations)
- [ ] Code review approved

## Dependencies for Next Phase

- Working offline CRUD operations
- Functional sync queue
- UUID generation system
- Operation tracking

---

**Phase Status**: Not Started  
**Estimated Effort**: 80 hours (2 weeks)  
**Priority**: High  
**Blocking**: Phase 1 completion
