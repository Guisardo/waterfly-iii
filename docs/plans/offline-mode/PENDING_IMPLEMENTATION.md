# Pending Implementation Checklist

**Created**: 2024-12-14  
**Status**: Active Development

This document tracks all TODO items that need implementation to complete the offline mode functionality.

---

## 🔴 Critical - Sync Manager Core

### SyncManager (`lib/services/sync/sync_manager.dart`)

#### Queue Operations
- [ ] **Line 210**: Implement `_getPendingOperations()`
  - Get operations from SyncQueueManager
  - Filter by status and priority
  - Return sorted list

#### Entity Sync Methods
- [ ] **Line 339**: Implement `_syncTransaction()`
  - Resolve ID references (accounts, categories)
  - Call API based on operation type (CREATE/UPDATE/DELETE)
  - Handle splits and attachments
  - Update ID mapping on success

- [ ] **Line 353**: Implement `_syncAccount()`
  - Sync account data to server
  - Handle balance updates
  - Map local ID to server ID

- [ ] **Line 360**: Implement `_syncCategory()`
  - Sync category data to server
  - Handle parent category references
  - Map local ID to server ID

- [ ] **Line 367**: Implement `_syncBudget()`
  - Sync budget data to server
  - Handle period calculations
  - Map local ID to server ID

- [ ] **Line 374**: Implement `_syncBill()`
  - Sync bill data to server
  - Handle recurrence rules
  - Map local ID to server ID

- [ ] **Line 381**: Implement `_syncPiggyBank()`
  - Sync piggy bank data to server
  - Handle target amounts and events
  - Map local ID to server ID

#### Server Pull
- [ ] **Line 423**: Implement `_pullFromServer()`
  - Get last sync timestamp from metadata
  - Fetch changes since last sync (incremental)
  - Update local database
  - Handle pagination
  - Update sync timestamp

#### Finalization
- [ ] **Line 433**: Implement `_finalize()`
  - Validate data consistency
  - Clean up completed operations from queue
  - Update sync metadata
  - Verify referential integrity

---

## 🟡 Important - Error Handling

### Conflict Handling
- [ ] **Line 461**: Store conflict in database
  - Save conflict details to conflicts table
  - Include local and server versions
  - Set conflict status

- [ ] **Line 462**: Remove from sync queue
  - Mark operation as conflicted
  - Remove from active queue

- [ ] **Line 463**: Notify user
  - Show notification about conflict
  - Provide link to conflict resolution screen

### Validation Errors
- [ ] **Line 472**: Mark operation as failed
  - Update operation status in queue
  - Set retry count

- [ ] **Line 473**: Store error details
  - Save validation error message
  - Include field-level errors

- [ ] **Line 474**: Notify user with fix suggestions
  - Show actionable error message
  - Provide guidance on how to fix

### Network Errors
- [ ] **Line 483**: Keep operation in queue
  - Don't remove failed operation
  - Increment retry count

- [ ] **Line 484**: Schedule retry when connectivity restored
  - Listen to connectivity changes
  - Trigger sync when online

---

## 🟢 Enhancement - Full & Incremental Sync

### Full Sync
- [ ] **Line 519**: Implement full sync
  - Fetch all data from server with pagination
  - Clear local database (except pending operations)
  - Insert all server data
  - Update sync metadata
  - Handle large datasets efficiently

### Incremental Sync
- [ ] **Line 559**: Implement incremental sync
  - Get last sync timestamp
  - Fetch changes since last sync
  - Merge changes into local database
  - Detect and handle conflicts
  - Update sync timestamp

---

## 🔵 Optional - Background Sync

### Periodic Sync Scheduling
- [ ] **Line 582**: Implement `schedulePeriodicSync()`
  - Add workmanager dependency
  - Register periodic task
  - Configure interval and constraints
  - Handle background execution

### Cancel Scheduled Sync
- [ ] **Line 596**: Implement `cancelScheduledSync()`
  - Cancel workmanager task by unique name
  - Clean up any pending callbacks

---

## 📋 Implementation Priority

### Phase 1: Core Sync (Week 1-2)
1. ✅ Queue operations (`_getPendingOperations`)
2. ✅ Transaction sync (`_syncTransaction`)
3. ✅ Account sync (`_syncAccount`)
4. ✅ Pull from server (`_pullFromServer`)
5. ✅ Finalization (`_finalize`)

### Phase 2: Error Handling (Week 3)
6. ⏳ Conflict handling (store, remove, notify)
7. ⏳ Validation error handling
8. ⏳ Network error handling with retry

### Phase 3: Advanced Sync (Week 4)
9. ⏳ Full sync implementation
10. ⏳ Incremental sync implementation
11. ⏳ Category/Budget/Bill/PiggyBank sync

### Phase 4: Background Sync (Week 5)
12. ⏳ Workmanager integration
13. ⏳ Periodic sync scheduling
14. ⏳ Background task management

---

## 🎯 Success Criteria

### Core Functionality
- [ ] All entity types can sync to server
- [ ] Pending operations are processed in order
- [ ] ID mapping works correctly
- [ ] Sync completes without errors

### Error Handling
- [ ] Conflicts are detected and stored
- [ ] Validation errors are reported clearly
- [ ] Network errors trigger retry
- [ ] User is notified of issues

### Performance
- [ ] Sync completes in reasonable time (<30s for 100 operations)
- [ ] Large datasets handled with pagination
- [ ] Background sync doesn't drain battery
- [ ] UI remains responsive during sync

### Reliability
- [ ] No data loss during sync
- [ ] Referential integrity maintained
- [ ] Sync can recover from interruption
- [ ] Duplicate operations are prevented

---

## 📝 Notes

### Dependencies Required
- `workmanager: ^0.5.2` - For background sync scheduling
- Already have: `synchronized`, `logging`, connectivity packages

### Testing Strategy
1. Unit tests for each sync method
2. Integration tests for full sync flow
3. Conflict resolution scenarios
4. Network failure scenarios
5. Large dataset performance tests

### Related Files
- `lib/services/sync/sync_queue_manager.dart` - Queue management
- `lib/services/sync/conflict_detector.dart` - Conflict detection
- `lib/services/sync/conflict_resolver.dart` - Conflict resolution
- `lib/data/repositories/*_repository.dart` - Data access layer
- `lib/services/id_mapping_service.dart` - ID translation

---

## 🔄 Progress Tracking

**Last Updated**: 2024-12-14  
**Overall Progress**: 20% (Core structure in place, implementations pending)

| Category | Items | Completed | Progress |
|----------|-------|-----------|----------|
| Queue Operations | 1 | 0 | 0% |
| Entity Sync | 6 | 0 | 0% |
| Server Pull | 1 | 0 | 0% |
| Finalization | 1 | 0 | 0% |
| Conflict Handling | 3 | 0 | 0% |
| Validation Errors | 3 | 0 | 0% |
| Network Errors | 2 | 0 | 0% |
| Full Sync | 1 | 0 | 0% |
| Incremental Sync | 1 | 0 | 0% |
| Background Sync | 2 | 0 | 0% |
| **TOTAL** | **21** | **0** | **0%** |

---

## 🚀 Next Steps

1. Start with `_getPendingOperations()` - foundation for all sync
2. Implement `_syncTransaction()` - most complex entity
3. Add error handling for conflicts and validation
4. Implement pull from server for incremental sync
5. Add finalization and cleanup logic
6. Test end-to-end sync flow
7. Add remaining entity sync methods
8. Implement background sync scheduling
