# Offline Mode Architecture

**Document Version**: 1.0  
**Last Updated**: 2024-12-12  
**Status**: Phase 1 Complete

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture Principles](#architecture-principles)
3. [System Architecture](#system-architecture)
4. [Data Flow](#data-flow)
5. [Component Details](#component-details)
6. [Database Schema](#database-schema)
7. [State Management](#state-management)
8. [Synchronization Strategy](#synchronization-strategy)
9. [Error Handling](#error-handling)
10. [Security Considerations](#security-considerations)

---

## Overview

The Waterfly III offline mode architecture enables the app to function without an active internet connection by maintaining a local database that mirrors the Firefly III server data. The architecture follows clean architecture principles with clear separation of concerns and dependency inversion.

### Key Features

- **Offline-First Design**: All operations work offline by default
- **Automatic Synchronization**: Changes sync automatically when online
- **Conflict Resolution**: Intelligent handling of data conflicts
- **Real-time Updates**: Reactive UI updates via streams
- **Type Safety**: Full Dart null safety and type checking

---

## Architecture Principles

### 1. Clean Architecture

The implementation follows Uncle Bob's Clean Architecture with distinct layers:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (Widgets, Providers, UI State)         │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Application Layer               │
│  (Use Cases, Business Logic)            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Domain Layer                    │
│  (Entities, Repository Interfaces)      │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         Data Layer                      │
│  (Repositories, Data Sources, DB)       │
└─────────────────────────────────────────┘
```

### 2. Repository Pattern

All data access goes through repository interfaces, allowing:
- Abstraction of data sources (local vs remote)
- Easy testing with mocks
- Consistent API across entities
- Automatic routing based on connectivity

### 3. Reactive Programming

Uses RxDart streams for:
- Real-time UI updates
- Connectivity monitoring
- App mode changes
- Data synchronization events

### 4. Dependency Injection

Services and repositories are injected, enabling:
- Loose coupling
- Easy testing
- Flexible configuration
- Runtime behavior changes

---

## System Architecture

### High-Level Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter UI                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Widgets    │  │   Providers  │  │  Controllers │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────┐
│                     Service Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Connectivity │  │  App Mode    │  │     UUID     │     │
│  │   Service    │  │   Manager    │  │   Service    │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────┐
│                   Repository Layer                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Transaction  │  │   Account    │  │   Category   │     │
│  │  Repository  │  │  Repository  │  │  Repository  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
└─────────┼──────────────────┼──────────────────┼─────────────┘
          │                  │                  │
┌─────────▼──────────────────▼──────────────────▼─────────────┐
│                      Data Sources                            │
│  ┌──────────────┐                    ┌──────────────┐       │
│  │    Drift     │                    │  Firefly III │       │
│  │   Database   │                    │   API Client │       │
│  │   (SQLite)   │                    │    (HTTP)    │       │
│  └──────────────┘                    └──────────────┘       │
└─────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### Read Operations (Online Mode)

```
User Request
    │
    ▼
Widget/Controller
    │
    ▼
Repository
    ├─► Check Local Cache
    │   └─► Return if fresh
    │
    ├─► Fetch from API
    │   └─► Update Local Cache
    │
    └─► Return Data
        │
        ▼
    Update UI
```

### Read Operations (Offline Mode)

```
User Request
    │
    ▼
Widget/Controller
    │
    ▼
Repository
    │
    ├─► Read from Local DB
    │
    └─► Return Data
        │
        ▼
    Update UI
```

### Write Operations (Online Mode)

```
User Action
    │
    ▼
Widget/Controller
    │
    ▼
Repository
    ├─► Validate Data
    │
    ├─► Save to API
    │   └─► Get Server ID
    │
    ├─► Update Local DB
    │   └─► Mark as Synced
    │
    └─► Return Result
        │
        ▼
    Update UI
```

### Write Operations (Offline Mode)

```
User Action
    │
    ▼
Widget/Controller
    │
    ▼
Repository
    ├─► Validate Data
    │
    ├─► Generate Local UUID
    │
    ├─► Save to Local DB
    │   └─► Mark as Unsynced
    │
    ├─► Add to Sync Queue
    │
    └─► Return Result
        │
        ▼
    Update UI
```

---

## Component Details

### 1. Connectivity Service

**Purpose**: Monitor network connectivity and server reachability

**Responsibilities**:
- Detect network state changes (WiFi, mobile, none)
- Verify actual internet connectivity
- Check Firefly III server reachability
- Debounce rapid connectivity changes
- Emit connectivity status stream

**Key Methods**:
```dart
Stream<ConnectivityStatus> get statusStream
Future<bool> checkServerReachability()
Future<ConnectivityStatus> getCurrentStatus()
```

**Dependencies**:
- `connectivity_plus`: Network state monitoring
- `internet_connection_checker_plus`: Internet verification
- `rxdart`: Stream management

### 2. App Mode Manager

**Purpose**: Manage application operating mode (online/offline/syncing)

**Responsibilities**:
- Track current app mode
- Switch modes based on connectivity
- Allow manual mode override
- Persist mode across app restarts
- Emit mode change events

**Key Methods**:
```dart
Stream<AppMode> get modeStream
AppMode get currentMode
Future<void> setMode(AppMode mode)
Future<void> setManualOverride(bool enabled, AppMode? mode)
```

**State Machine**:
```
     ┌─────────┐
     │ Online  │◄──────┐
     └────┬────┘       │
          │            │
  Offline │            │ Connected
          │            │
     ┌────▼────┐       │
     │ Offline │───────┘
     └────┬────┘
          │
   Sync   │
  Trigger │
          │
     ┌────▼────┐
     │ Syncing │
     └────┬────┘
          │
   Done   │
          │
     ┌────▼────┐
     │ Online  │
     └─────────┘
```

### 3. UUID Service

**Purpose**: Generate collision-free UUIDs for offline entities

**Responsibilities**:
- Generate entity-specific UUIDs with prefixes
- Validate UUID format
- Extract entity type from UUID
- Ensure uniqueness

**UUID Format**:
```
offline_<type>_<uuid-v4>

Examples:
- offline_txn_550e8400-e29b-41d4-a716-446655440000
- offline_acc_6ba7b810-9dad-11d1-80b4-00c04fd430c8
- offline_cat_6ba7b811-9dad-11d1-80b4-00c04fd430c8
```

**Key Methods**:
```dart
String generateTransactionId()
String generateAccountId()
String generateCategoryId()
bool isOfflineId(String id)
String? extractEntityType(String id)
```

### 4. Offline Configuration

**Purpose**: Manage offline mode settings and preferences

**Responsibilities**:
- Store user preferences
- Provide default values
- Validate settings
- Persist configuration
- Emit configuration changes

**Settings**:
- `offlineModeEnabled`: Enable/disable offline mode
- `autoSyncEnabled`: Auto-sync when online
- `syncFrequency`: Sync interval (minutes)
- `maxRetryAttempts`: Max sync retry attempts
- `dataRetentionDays`: Days to keep offline data
- `maxCacheSize`: Maximum cache size (MB)
- `backgroundSyncEnabled`: Enable background sync
- `conflictResolution`: Default conflict strategy
- `debugLoggingEnabled`: Enable debug logs

### 5. Repository Layer

**Purpose**: Abstract data access and provide consistent API

**Base Repository Interface**:
```dart
abstract class BaseRepository<T, ID> {
  Future<List<T>> getAll();
  Stream<List<T>> watchAll();
  Future<T?> getById(ID id);
  Stream<T?> watchById(ID id);
  Future<T> create(T entity);
  Future<T> update(ID id, T entity);
  Future<void> delete(ID id);
  Future<List<T>> getUnsynced();
  Future<void> markAsSynced(ID localId, String serverId);
  Future<String> getSyncStatus(ID id);
  Future<void> clearCache();
  Future<int> count();
}
```

**Implemented Repositories**:
- `TransactionRepository`: Transaction CRUD and queries
- Additional repositories planned for Phase 2

---

## Database Schema

### Entity Relationship Diagram

```
┌──────────────┐         ┌──────────────┐
│ Transactions │────────►│   Accounts   │
│              │         │              │
│ - id         │         │ - id         │
│ - type       │         │ - name       │
│ - amount     │         │ - type       │
│ - date       │         │ - balance    │
│ - source_id  │         │ - currency   │
│ - dest_id    │         └──────────────┘
│ - category_id│
│ - budget_id  │         ┌──────────────┐
│ - is_synced  │────────►│  Categories  │
│ - sync_status│         │              │
└──────────────┘         │ - id         │
                         │ - name       │
       │                 └──────────────┘
       │
       │                 ┌──────────────┐
       └────────────────►│   Budgets    │
                         │              │
                         │ - id         │
                         │ - name       │
                         │ - amount     │
                         └──────────────┘

┌──────────────┐         ┌──────────────┐
│    Bills     │         │ Piggy Banks  │
│              │         │              │
│ - id         │         │ - id         │
│ - name       │         │ - name       │
│ - amount_min │         │ - account_id │
│ - amount_max │         │ - target     │
│ - date       │         │ - current    │
│ - repeat_freq│         └──────────────┘
└──────────────┘

┌──────────────┐         ┌──────────────┐
│  Sync Queue  │         │ Sync Metadata│
│              │         │              │
│ - id         │         │ - key        │
│ - entity_type│         │ - value      │
│ - entity_id  │         │ - updated_at │
│ - operation  │         └──────────────┘
│ - payload    │
│ - status     │         ┌──────────────┐
│ - attempts   │         │  ID Mapping  │
└──────────────┘         │              │
                         │ - local_id   │
                         │ - server_id  │
                         │ - entity_type│
                         └──────────────┘
```

### Sync Tracking Fields

All entity tables include:
- `is_synced` (boolean): Whether synced with server
- `sync_status` (text): Current sync status
  - `pending`: Waiting to sync
  - `syncing`: Currently syncing
  - `synced`: Successfully synced
  - `error`: Sync failed
- `created_at` (datetime): Creation timestamp
- `updated_at` (datetime): Last update timestamp
- `server_id` (text, nullable): Server-assigned ID

---

## State Management

### Provider Architecture

```
┌─────────────────────────────────────────┐
│          Flutter Widget Tree            │
└──────────────┬──────────────────────────┘
               │
┌──────────────▼──────────────────────────┐
│         ChangeNotifier Providers        │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Connectivity │  │   App Mode   │   │
│  │   Provider   │  │   Provider   │   │
│  └──────┬───────┘  └──────┬───────┘   │
└─────────┼──────────────────┼───────────┘
          │                  │
┌─────────▼──────────────────▼───────────┐
│            Service Layer                │
│                                         │
│  ┌──────────────┐  ┌──────────────┐   │
│  │ Connectivity │  │   App Mode   │   │
│  │   Service    │  │   Manager    │   │
│  └──────────────┘  └──────────────┘   │
└─────────────────────────────────────────┘
```

### State Flow

1. **Service Layer** emits state changes via RxDart streams
2. **Providers** listen to streams and call `notifyListeners()`
3. **Widgets** rebuild automatically via `Consumer` or `Provider.of`

---

## Synchronization Strategy

### Sync Queue Processing

```
┌─────────────────────────────────────────┐
│         Sync Queue Manager              │
└──────────────┬──────────────────────────┘
               │
               ▼
    ┌──────────────────┐
    │  Get Pending     │
    │  Operations      │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  Sort by         │
    │  Priority        │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  Process Batch   │
    │  (10 at a time)  │
    └────────┬─────────┘
             │
             ▼
    ┌──────────────────┐
    │  Send to Server  │
    └────────┬─────────┘
             │
        ┌────┴────┐
        │         │
    Success   Failure
        │         │
        ▼         ▼
    ┌────┐    ┌────────┐
    │Mark│    │ Retry  │
    │Done│    │ Later  │
    └────┘    └────────┘
```

### Conflict Resolution

**Strategies**:
1. **Server Wins**: Server data overwrites local
2. **Client Wins**: Local data overwrites server
3. **Manual**: User chooses which to keep
4. **Merge**: Combine both (field-level)

**Detection**:
- Compare `updated_at` timestamps
- Check for concurrent modifications
- Validate data integrity

---

## Error Handling

### Exception Hierarchy

```
OfflineException (base)
    │
    ├─► DatabaseException
    │   ├─► queryFailed
    │   ├─► connectionFailed
    │   └─► transactionFailed
    │
    ├─► SyncException
    │   ├─► operationFailed
    │   ├─► serverError
    │   └─► conflictDetected
    │
    ├─► ConnectivityException
    │   ├─► noConnection
    │   └─► serverUnreachable
    │
    ├─► ValidationException
    │   └─► invalidData
    │
    ├─► ConflictException
    │   └─► dataConflict
    │
    ├─► ConfigurationException
    │   └─► invalidConfig
    │
    └─► StorageException
        └─► storageFull
```

### Error Recovery

1. **Automatic Retry**: Exponential backoff for transient errors
2. **User Notification**: Show error messages for user action
3. **Logging**: Comprehensive error logging for debugging
4. **Fallback**: Graceful degradation when possible

---

## Security Considerations

### Data Protection

1. **Encryption at Rest**: SQLite database encryption (planned)
2. **Secure Storage**: Use platform secure storage for credentials
3. **No Credentials in Logs**: Sanitize all log output
4. **API Token Security**: Store tokens securely, never in code

### Sync Security

1. **HTTPS Only**: All API communication over HTTPS
2. **Token Validation**: Validate API tokens before sync
3. **Data Validation**: Validate all data before storage
4. **Rate Limiting**: Respect API rate limits

### Privacy

1. **Local Data**: All offline data stays on device
2. **No Analytics**: No tracking or analytics in offline mode
3. **User Control**: User can clear all local data
4. **Transparent**: Clear indication of sync status

---

## Performance Considerations

### Database Optimization

- **WAL Mode**: Write-Ahead Logging for better concurrency
- **Indexes**: Proper indexing on frequently queried fields
- **Batch Operations**: Batch inserts/updates for efficiency
- **Connection Pooling**: Reuse database connections

### Memory Management

- **Stream Disposal**: Proper cleanup of streams
- **Pagination**: Load data in pages, not all at once
- **Cache Limits**: Configurable cache size limits
- **Resource Cleanup**: Dispose of resources properly

### Network Optimization

- **Batch Sync**: Sync multiple operations together
- **Compression**: Compress sync payloads
- **Delta Sync**: Only sync changes, not full data
- **Background Sync**: Sync during idle time

---

## Future Enhancements

### Phase 2-6 Additions

1. **Complete Repository Layer**: All entity repositories
2. **Advanced Sync**: Conflict resolution UI
3. **Background Sync**: WorkManager integration
4. **Offline Search**: Full-text search in local DB
5. **Data Export**: Export offline data
6. **Sync Analytics**: Track sync performance
7. **Smart Caching**: Predictive data caching
8. **Offline Reports**: Generate reports offline

---

## References

### External Documentation

- [Drift Documentation](https://drift.simonbinder.eu/)
- [Flutter State Management](https://flutter.dev/docs/development/data-and-backend/state-mgmt)
- [Clean Architecture](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Repository Pattern](https://martinfowler.com/eaaCatalog/repository.html)

### Internal Documentation

- [Phase 1 Foundation](./PHASE_1_FOUNDATION.md)
- [Phase 2 Core Offline](./PHASE_2_CORE_OFFLINE.md)
- [Phase 3 Synchronization](./PHASE_3_SYNCHRONIZATION.md)
- [Implementation Report](./IMPLEMENTATION_REPORT.md)

---

**Document Status**: Complete  
**Review Date**: 2024-12-12  
**Next Review**: Start of Phase 2
