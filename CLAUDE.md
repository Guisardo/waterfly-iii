# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Waterfly III is an unofficial Flutter mobile app for [Firefly III](https://github.com/firefly-iii/firefly-iii), a self-hosted personal finance manager. The app provides a companion mobile interface for tracking expenses, managing accounts, viewing budgets, and handling transactions on-the-go. It follows Material 3 design guidelines and supports both light and dark modes with dynamic colors.

Key philosophy: The app is a **companion** to Firefly III's web interface, not a complete replacement. It focuses on the most-used mobile functions rather than replicating every web feature.

## Development Commands

### Building and Running

```bash
# Get dependencies
flutter pub get

# Generate code (Drift database, Chopper API client, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Run the app
flutter run

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release
```

### Testing

```bash
# Run all tests
flutter test

# Run specific test categories
flutter test test/widgets/          # Widget tests only
flutter test test/services/         # Service tests only
flutter test integration_test/      # Integration tests

# Run single test file
flutter test test/services/accessibility_service_test.dart

# Run with coverage
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Update golden files
flutter test --update-goldens
```

### Code Quality

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

## Core Development Philosophy

### NO MINIMAL CODE PRINCIPLE
- **NEVER USE MINIMAL CODE**: Always write comprehensive, complete implementations
- **NO SHORTCUTS**: Avoid abbreviated or simplified solutions
- **FULL IMPLEMENTATIONS**: Provide complete, production-ready code with all features
- **NO THROWAWAY CODE**: Never write temporary or example code for debugging
- **COMPREHENSIVE SOLUTIONS**: Include all necessary error handling, validation, and edge cases
- **PREFER EXISTING PACKAGES**: Always use prebuilt packages and existing code over custom implementations

### Library-First Development
- **Use Existing Packages**: Before writing custom code, search pub.dev for existing solutions
- **Leverage Flutter Ecosystem**: Prefer well-maintained packages with good community support
- **Check pubspec.yaml**: Review existing dependencies - the solution might already be integrated
- **Evaluate Package Quality**: Check package popularity, maintenance status, and documentation
- **Examples of preferred packages**:
  - Networking: `chopper`, `dio`, `http`
  - State management: `provider`, `riverpod`
  - Database: `drift`, `hive`
  - Utilities: `rxdart`, `synchronized`, `retry`
  - Background work: `workmanager`

### Debugging Standards
- **Logging for Debugging**: Use proper `Logger` statements, not `print()` or temporary code
- **Tests for Testing**: Write actual tests for validation, not throwaway scripts
- **No Debug Code**: Never include temporary debugging code in solutions
- **Production Ready**: All code should be production-ready, not experimental
- **Prefer Libraries**: Use existing packages over custom implementations

### Error Handling Philosophy
```dart
// REQUIRED: Detailed exception raising with comprehensive logging
Future<ProcessedData> processData(Map<String, dynamic> data) async {
  final log = Logger('DataProcessor');

  // Log input data for debugging
  log.fine('Processing data: $data');

  if (data is! Map) {
    final errorMsg = 'Expected Map, got ${data.runtimeType}: $data';
    log.severe(errorMsg);
    throw TypeError(errorMsg);
  }

  if (!data.containsKey('required_field')) {
    final errorMsg =
        'Missing required "required_field" field in data. '
        'Available fields: ${data.keys.toList()}';
    log.severe(errorMsg, data);
    throw ValidationException(errorMsg);
  }

  // Continue with detailed validation...
}
```

### Code Style Requirements
- **Comprehensive Implementations**: Always write thorough, complete solutions
- **Verbose and Documented**: Every function, class, and module must have detailed documentation
- **No Fallbacks**: Throw exceptions with detailed error messages instead of fallback behavior
- **Full Feature Implementation**: Include all necessary features, not just basic functionality
- **Package-First Approach**: Search for and use existing packages before writing custom code

## Architecture

### High-Level Structure

Waterfly III follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  Pages (Screens) + Widgets (Reusable Components)        │
│  State managed by Provider                               │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Business Logic Layer                   │
│  Providers + Services + Validators                       │
│  (connectivity, sync, app mode, auth, notifications)     │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                      Data Layer                          │
│  Repositories + Local Database (Drift) + API Client      │
│  (offline-first with sync queue)                         │
└─────────────────────────────────────────────────────────┘
```

### Key Directories

- **`lib/pages/`** - UI screens organized by feature (home, transactions, settings, bills, categories, accounts)
- **`lib/widgets/`** - Reusable UI components (charts, inputs, dialogs, offline indicators)
- **`lib/services/`** - Business logic services (sync, connectivity, accessibility, app mode)
- **`lib/providers/`** - Provider state management (connectivity, sync, settings, app mode)
- **`lib/data/repositories/`** - Data access layer with offline-first pattern
- **`lib/data/local/database/`** - Drift database tables and schemas
- **`lib/models/`** - Data models (sync operations, conflicts, progress)
- **`lib/validators/`** - Business rule validation (transactions, accounts, budgets, etc.)
- **`lib/generated/`** - Auto-generated code (API clients, localizations, Drift database)
- **`lib/config/`** - App configuration (offline mode settings)
- **`lib/exceptions/`** - Custom exception hierarchy (offline, sync exceptions)

### State Management

Uses **Provider** pattern throughout:
- **Multiple providers** initialized in `lib/app.dart` via `MultiProvider`
- **Key providers:**
  - `FireflyService` - Authentication and API communication
  - `SettingsProvider` - User preferences
  - `ConnectivityProvider` - Network status monitoring (using `connectivity_plus` package)
  - `SyncProvider` - Offline sync status and progress
  - `AppModeProvider` - App mode state (online/offline/syncing)

### Offline Mode Architecture

**Critical feature**: Full offline-first support with background sync (95% complete as of Dec 2024).

**Key packages used:**
- **drift** (^2.14.0) - Local SQLite database with type-safety
- **connectivity_plus** (^7.0.0) - Network connectivity monitoring
- **internet_connection_checker_plus** (^2.9.1+1) - Internet connection verification
- **rxdart** (^0.28.0) - Reactive programming utilities
- **uuid** (^4.5.2) - UUID generation for offline entities
- **synchronized** (^3.4.0) - Mutex/locks for thread safety
- **retry** (^3.1.2) - Retry logic for failed operations
- **workmanager** (^0.9.0) - Background sync scheduling

**Key components:**
1. **Local Database (Drift)**: SQLite tables for all entities (transactions, accounts, budgets, bills, categories, piggy banks)
2. **Sync Queue System**: Tracks pending operations with priority, retry logic, and deduplication
3. **ID Mapping Service**: Translates between local temporary IDs and server IDs
4. **Conflict Detection & Resolution**: Handles data conflicts during sync (5 strategies: localWins, remoteWins, lastWriteWins, merge, manual)
5. **Circuit Breaker Pattern**: API protection with CLOSED/OPEN/HALF_OPEN states
6. **Background Sync**: WorkManager integration for periodic background synchronization
7. **Consistency Checker**: Validates referential integrity and auto-repairs orphaned records

**Sync flow:**
1. User creates/edits data while offline → saved to local Drift database
2. Operation queued in `sync_queue` table with temporary UUID (from `uuid` package)
3. When online, `SyncManager` processes queue in batches
4. Conflict detection compares local vs server state
5. Resolved data pushed to Firefly III API (with `retry` package for resilience)
6. ID mapping updates (temp ID → server ID)
7. Local database updated with server response

**Important files:**
- `lib/services/sync/sync_manager.dart` - Main sync orchestrator (80KB, complex)
- `lib/services/sync/conflict_resolver.dart` - Conflict resolution strategies (38KB)
- `lib/services/sync/background_sync_handler.dart` - WorkManager integration
- `lib/data/repositories/base_repository.dart` - Base class for all repositories

See `docs/plans/offline-mode/README.md` for comprehensive implementation documentation.

### Cache-First Architecture

**New feature**: Local database caching with metadata management for improved performance (Completed December 2024).

**Key insight**: CacheService manages METADATA (freshness, TTL, invalidation), NOT actual data. Entity data lives in repository Drift tables. Cache metadata controls WHEN to fetch from API, not WHERE data is stored.

**Key packages used:**
- **crypto** (^3.0.3) - SHA-256 hashing for query parameter normalization
- **rxdart** (^0.28.0) - Reactive streams for cache invalidation events
- **synchronized** (^3.4.0) - Thread-safe cache operations
- **retry** (^3.1.2) - Background refresh resilience

**Architecture:**
1. **CacheService (Metadata Manager)**:
   - Stores cache metadata in `cache_metadata` table (schema v5)
   - Tracks: cachedAt, lastAccessedAt, TTL, isInvalidated, ETag, queryHash
   - **NEVER stores actual entity data** - data lives in repository tables
   - Provides `get<T>()` method that ALWAYS calls the fetcher function
   - Cache freshness determines whether to trigger API refresh, not whether to fetch from DB

2. **Cache-First Flow**:
   ```
   Repository.getById(id) →
     CacheService.get(fetcher: () => _fetchFromDb(id)) →
       if (fresh metadata):
         data = await fetcher()  // Query repository DB
         return CacheResult(data, isFresh: true)
       else if (stale metadata):
         data = await fetcher()  // Query repository DB
         trigger background API refresh
         return CacheResult(data, isFresh: false)
       else (cache miss):
         data = await fetcher()  // Query repository DB
         create cache metadata
         return CacheResult(data, source: api)
   ```

3. **Stale-While-Revalidate**:
   - Fresh data returned immediately from repository DB
   - Stale data returned immediately, API refresh triggered in background
   - Background refresh updates repository DB + cache metadata
   - UI updates via RxDart invalidation streams (CacheStreamBuilder widget)

4. **Cache Invalidation Rules** (`lib/services/cache/cache_invalidation_rules.dart`):
   - Cascade invalidation on mutations (e.g., transaction create → invalidate accounts, budgets, categories)
   - 8 entity types with comprehensive invalidation logic
   - Nuclear invalidation for currency changes (affects everything)
   - Sync-triggered batch invalidation

5. **TTL Configuration** (`lib/config/cache_ttl_config.dart`):
   - Per-entity-type TTL (5min transactions, 1hr categories, 24hr currencies)
   - Configurable via static constants
   - Balance between freshness and performance

6. **Advanced Features**:
   - **ETag Support**: HTTP cache validation for bandwidth optimization (RFC 7232 compliant)
   - **Query Hashing**: SHA-256 deterministic hashing for collection cache keys
   - **LRU Eviction**: Automatic cleanup based on lastAccessedAt (configurable 100MB limit)
   - **Cache Debug UI**: Comprehensive debug page for statistics, entry inspection, manual management
   - **Cache Warming**: Pre-fetch frequently accessed data on app start

7. **Statistics Tracking**:
   - Hit rate, miss rate, stale served rate
   - ETag hit rate and bandwidth savings
   - Per-entity-type metrics
   - Average cache age, total entries, invalidated count

**Critical Files**:
- `lib/services/cache/cache_service.dart` - Core cache service (1,500+ lines, metadata-only)
- `lib/services/cache/cache_invalidation_rules.dart` - Cascade invalidation logic (750+ lines)
- `lib/config/cache_ttl_config.dart` - TTL configuration for all entity types
- `lib/models/cache/*.dart` - CacheResult, CacheStats, CacheInvalidationEvent models
- `lib/widgets/cache_stream_builder.dart` - Reactive UI widget for cache updates
- `lib/pages/settings/cache_debug.dart` - Debug UI for cache management

**Repository Integration**:
All repositories extend `BaseRepository<T, ID>` with built-in cache support:
```dart
class TransactionRepository extends BaseRepository<TransactionEntity, String> {
  @override
  String get entityType => 'transaction';

  @override
  Duration get cacheTtl => CacheTtlConfig.transactions;

  @override
  Future<TransactionEntity?> getById(String id) async {
    if (cacheService != null) {
      final result = await cacheService!.get<TransactionEntity?>(
        entityType: entityType,
        entityId: id,
        fetcher: () => _fetchTransactionFromDb(id),  // Query Drift DB
        ttl: cacheTtl,
      );
      return result.data;
    }
    return await _fetchTransactionFromDb(id);  // Fallback: direct DB query
  }
}
```

**Usage in UI**:
```dart
CacheStreamBuilder<TransactionEntity>(
  entityType: 'transaction',
  entityId: transactionId,
  fetcher: () => repository.getById(transactionId),
  builder: (context, data, isFresh) {
    if (data == null) return LoadingWidget();
    return TransactionCard(
      transaction: data,
      staleIndicator: !isFresh,  // Show refresh icon if stale
    );
  },
)
```

**Feature Flag**:
- `SettingsProvider.enableCaching` - Toggle cache on/off (default: true)
- UI in Debug Dialog with confirmation on disable
- Fallback to direct API calls when disabled

**Testing**:
- `test/services/cache/cache_service_test.dart` - 800+ lines unit tests
- `test/services/cache/cache_invalidation_rules_test.dart` - 750+ lines cascade tests
- `test/widgets/cache_stream_builder_test.dart` - 600+ lines widget tests
- `test/data/repositories/transaction_repository_cache_integration_test.dart` - Integration tests with real DB

**Performance Targets** (Achieved):
- 70-80% API call reduction
- 50-70% load time improvement
- >75% cache hit rate
- Thread-safe with synchronized locks

**Critical Bug Fixed** (December 15, 2024):
CacheService.get() was incorrectly calling `_getFromLocalDb()` (returns null) instead of the fetcher function. Fixed to ALWAYS call fetcher, as CacheService only manages metadata, not data.

See `docs/plans/local-cache/IMPLEMENTATION_CHECKLIST.md` for comprehensive implementation documentation.

### API Integration

- **Swagger/OpenAPI generated client** in `lib/generated/swagger_fireflyiii_api/` (using `swagger_dart_code_generator`)
- Uses **Chopper** (^8.4.0) HTTP client library for API requests
- **dio** (^5.4.0) also available for complex HTTP operations
- `FireflyService` wraps the API client and handles authentication
- All API models are JSON-serializable via `json_annotation` (^4.8.0)

### Database Layer (Drift)

- **Drift** (^2.14.0) (formerly Moor) - Type-safe SQL database for Flutter
- Table definitions in `lib/data/local/database/*_table.dart`
- **9 main tables**: transactions, accounts, budgets, categories, bills, piggy_banks, sync_queue, sync_metadata, id_mapping
- **Features:**
  - WAL mode for better concurrency
  - 24+ performance indexes
  - Foreign key constraints with cascade deletes
  - Schema versioning with migrations
- Code generation required: `dart run build_runner build --delete-conflicting-outputs`
- Generated files: `*.g.dart` (do not edit manually)

### Navigation

- **Global navigator key**: `navigatorKey` in `lib/app.dart`
- Routes managed dynamically based on auth state
- Supports:
  - Deep linking (sharing files to the app via `flutter_sharing_intent`)
  - Quick actions (shortcuts via `quick_actions`)
  - Notification taps (from notification listener)
  - App lifecycle state handling (biometric auth on resume using `local_auth`)

### Localization

- **flutter_localizations** with `flutter_gen` for type-safe translations
- **intl** (0.20.2) for date/time formatting and locale handling
- Localization files generated at build time
- Access via `S.of(context)` throughout the app
- Context-free localization for background services (using device locale)

## Important Implementation Patterns

### Repository Pattern

All data access goes through repositories (`lib/data/repositories/`):
```dart
// Example: AccountRepository
class AccountRepository extends BaseRepository<Account> {
  Future<Account?> getById(String id) async { ... }
  Future<List<Account>> getAll({bool includeDeleted = false}) async { ... }
  Future<Account> create(Account account) async { ... }
  Future<Account> update(Account account) async { ... }
  Future<void> delete(String id) async { ... }
}
```

**Key principle**: Repositories handle both online (API) and offline (local DB) operations transparently based on app mode. Always implement comprehensive error handling and logging in repositories.

### Validation Pattern

All entities have validators in `lib/validators/`:
```dart
// Example: TransactionValidator
class TransactionValidator {
  static Future<ValidationResult> validate(Transaction transaction) async {
    final log = Logger('TransactionValidator');
    log.fine('Validating transaction: ${transaction.id}');

    // Comprehensive business rules validation
    final errors = <String>[];
    final warnings = <String>[];

    // Validate all fields thoroughly
    if (transaction.amount == null || transaction.amount <= 0) {
      errors.add('Transaction amount must be positive');
    }

    // ... more validation

    log.info('Validation complete: ${errors.length} errors, ${warnings.length} warnings');
    return ValidationResult(errors: errors, warnings: warnings);
  }
}
```

Validators are called **before** saving to database or API. Always provide detailed error messages.

### Error Handling

Custom exception hierarchy in `lib/exceptions/`:
- `OfflineException` - Base for offline-related errors
- `SyncException` - Base for sync-related errors
- Specific types: `NetworkException`, `ConflictException`, `ValidationException`, etc.

All exceptions include:
- Descriptive messages
- Retry logic hints
- User-friendly display messages
- Full context for debugging

### Logging

Uses `logging` package (^1.1.1) throughout:
```dart
final Logger log = Logger('FeatureName');

// Standard logging levels
log.finest('Detailed debug information'); // Lazy evaluation recommended
log.fine('Debug information');
log.info('Informational message');
log.warning('Warning message');
log.severe('Error message', error, stackTrace); // Always include error details

// Lazy evaluation for expensive operations
log.finest(() => 'Expensive debug message: ${heavyComputation()}');
```

**Critical**:
- Always use lazy evaluation `() =>` for expensive log messages
- Include full error context with `log.severe(message, error, stackTrace)`
- Use appropriate log levels (DEBUG=finest, INFO=info, WARNING=warning, ERROR=severe)
- Log function entry/exit for complex operations
- Log all validation failures with context

### Background Work

- **workmanager** (^0.9.0) for background sync (Android)
- **flutter_local_notifications** (^19.4.0) for sync progress notifications
- Handler: `lib/services/sync/background_sync_handler.dart`
- Initialized in `lib/main.dart` at app startup

## Code Generation

The app relies heavily on code generation. After modifying:
- Drift tables (`*_table.dart`)
- API definitions (if regenerating from Swagger)
- JSON serializable models (`@JsonSerializable()`)
- Localization strings

Run:
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Key packages for code generation:**
- **build_runner** (^2.5.4) - Build system
- **drift_dev** (^2.14.0) - Drift code generation
- **chopper_generator** (^8.2.0) - Chopper API client generation
- **json_serializable** (^6.9.0) - JSON serialization generation
- **swagger_dart_code_generator** (^3.0.1) - OpenAPI client generation

**Common issues:**
- Missing imports in generated files → Check source file imports
- Build fails → Try `flutter clean && flutter pub get` first
- Conflicts → Use `--delete-conflicting-outputs` flag

### Auto-Generated Files (Do Not Edit Manually)

The following files are **auto-generated** and should **NOT** be manually edited. Code review findings in these files should be ignored:

**Flutter-Generated Files:**
- `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` - Generated by Flutter tool based on plugins in `pubspec.yaml`. Contains plugin registration code that is regenerated on each build.
- `ios/Flutter/ephemeral/flutter_lldb_helper.py` - Generated by Flutter for LLDB debugging support. Contains debug helper functions required by the LLDB debugger.

**Build Runner Generated Files:**
- `lib/**/*.g.dart` - Generated by build_runner (Drift database, JSON serialization, Chopper API clients)
- `lib/generated/swagger_fireflyiii_api/**` - Generated from Firefly III OpenAPI spec
- Files with `@JsonSerializable()` annotations generate `.g.dart` files
- Drift table files (`*_table.dart`) generate corresponding `.g.dart` files

**Identifying Generated Files:**
- Look for "Generated file. Do not edit." comments in file headers
- Files in `generated/` or `ephemeral/` directories
- Files with `.g.dart` extension (generated from source files)
- Files that are regenerated when running `dart run build_runner build`

**Code Review Process:**
- **Exclude auto-generated files from code review tools** - When running code review tools (e.g., MCP code reviewer, SonarQube, CodeClimate), configure them to exclude these files
- **Ignore all findings in generated files** - Code quality findings (complexity, length, testability, SOLID violations, DRY violations) in generated files should be ignored
- **Focus on manually-written code** - Code review should focus on manually-written source files only
- **No manual edits** - Generated files will be regenerated and any manual changes will be lost
- **Reference documentation** - See `docs/code-review-execution-plan.md` for detailed code review findings and execution plan

## Testing Guidelines

**Coverage targets:**
- Widget tests: >80%
- Service tests: >90%
- Integration tests: >70%

**Test structure:**
```
test/
├── widgets/         # Widget tests (UI components)
├── services/        # Service/unit tests (business logic)
└── integration/     # Integration tests (complete flows)
```

**Key testing packages:**
- **flutter_test** (SDK) - Widget and unit testing
- **test** (^1.16.0) - Dart testing framework
- **integration_test** (SDK) - Integration testing
- **patrol** (^3.13.0) - E2E testing framework
- **mocktail** (^1.0.0) - Mocking library

**Key testing practices:**
- Use `mocktail` for mocking (already set up)
- Widget tests should use `pumpWidget` with full `MaterialApp` wrapper
- Integration tests use `patrol` package for E2E testing
- Always test accessibility (semantic labels, announcements)
- Write comprehensive test documentation explaining what each test validates
- Cover all error scenarios and edge cases
- Use realistic test data that mirrors production

### Test Documentation Template
```dart
class TestTransactionRepository {
  /// Comprehensive test suite for TransactionRepository.
  ///
  /// Tests cover:
  /// - Normal operation scenarios
  /// - Edge cases and boundary conditions
  /// - Error conditions and exception handling
  /// - Offline mode behavior
  /// - Sync queue integration

  @test
  Future<void> testCreateTransactionSuccess() async {
    /// Test successful transaction creation with valid data.
    ///
    /// Validates:
    /// - Correct storage in local database
    /// - Queue operation creation
    /// - Proper ID generation
    /// - Validation execution
  }

  @test
  Future<void> testCreateTransactionInvalidData() async {
    /// Test transaction creation with invalid input data.
    ///
    /// Validates:
    /// - Proper exception raising for invalid data
    /// - Detailed error messages with context
    /// - No side effects from failed creation
    /// - Validation error details
  }
}
```

See `test/README.md` for detailed testing guide.

## Common Development Tasks

### Adding a New Feature

1. **Check if it fits the app philosophy** - Is it a mobile-first, on-the-go feature?
2. **Search for existing packages** - Check pub.dev for pre-built solutions before writing custom code
3. **Review pubspec.yaml** - Check if a suitable package is already integrated
4. **Plan offline support** - Will it work offline? Does it need sync?
5. **Create comprehensive implementation plan** - Document all components needed
6. **Create/modify database table** if storing data locally (Drift)
7. **Add repository with full CRUD operations** if new entity type
8. **Add validator with comprehensive business rules**
9. **Create UI in pages/** following Material 3 patterns
10. **Update providers** if state management needed
11. **Add comprehensive logging** throughout all components
12. **Run code generation** after Drift/JSON changes
13. **Add comprehensive tests** (widget, service, integration)
14. **Update localization** strings if needed

**Important**: Never write minimal implementations. Every feature should be production-ready with:
- Complete error handling for all scenarios
- Comprehensive logging for debugging
- Full validation with detailed error messages
- Thorough documentation
- Complete test coverage
- Use of existing packages where applicable

### Working with Offline Mode

**Before modifying offline/sync code:**
1. Read `docs/plans/offline-mode/README.md` - comprehensive implementation docs
2. Understand the sync flow (queue → process → resolve → push → update)
3. Review the packages used: `drift`, `connectivity_plus`, `rxdart`, `retry`, `workmanager`
4. Test both online and offline scenarios thoroughly
5. Consider conflict resolution (what happens if data changes on both sides?)
6. Add comprehensive logging for all sync operations
7. Handle all error scenarios with proper exceptions
8. Leverage `retry` package for resilient API calls

**Key services to understand:**
- `SyncManager` - Central orchestrator (complex, 80KB file)
- `ConflictResolver` - Handles data conflicts (38KB, 5 resolution strategies)
- `IdMappingService` - Local ID ↔ Server ID translation (uses `uuid` package)
- `SyncQueueManager` - Queue operations management
- `CircuitBreaker` - API protection with state management
- `ConsistencyService` - Data integrity validation and repair

### Debugging Sync Issues

```bash
# Enable verbose logging (set in lib/main.dart)
Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;

# Logs will show format: [LoggerName] LEVEL: message
```

Important debugging queries (via Drift):
- Check sync queue state: `sync_queue` table where `status = 'pending'`
- Check ID mappings: `id_mapping` table
- Check conflicts: `conflicts` table where `resolved = 0`

Always add comprehensive logging when debugging:
```dart
log.fine('Starting sync operation for ${operation.entityType}');
log.fine('Operation details: ${operation.toJson()}');
try {
  // sync logic with retry package
  await retry(
    () => syncOperation(),
    maxAttempts: 3,
    onRetry: (e) => log.warning('Retry attempt after error: $e'),
  );
  log.info('Sync completed successfully');
} catch (e, stackTrace) {
  log.severe('Sync failed for operation ${operation.id}', e, stackTrace);
  rethrow;
}
```

### Modifying API Integration

API client is auto-generated from Firefly III's OpenAPI spec using `swagger_dart_code_generator`:
1. Update Swagger spec in `docs/` (if available)
2. Regenerate with `dart run build_runner build --delete-conflicting-outputs`
3. Review changes in `lib/generated/swagger_fireflyiii_api/`
4. Update `FireflyService` wrapper if API contract changed
5. Update repositories that call the API
6. Add comprehensive error handling for all API calls
7. Add logging for all API requests/responses
8. Update validators if data models changed
9. Consider using `retry` package for transient failures

## Documentation Standards

### Code Documentation Requirements
- **File-level documentation**: Every file must have comprehensive header documentation
- **Class documentation**: Detailed description, attributes, usage examples
- **Method documentation**: Parameters, returns, exceptions, examples for all public methods
- **Inline comments**: Explain complex logic, business rules, and algorithms
- **Type annotations**: Complete type annotations for all functions and methods
- **Package usage**: Document which packages are used and why

### Dart Documentation Template
```dart
/// Data Processing Repository
///
/// This repository provides comprehensive data processing capabilities using:
/// - [drift] for local database operations
/// - [retry] for resilient API calls
/// - [uuid] for offline ID generation
///
/// Key Features:
/// - Full offline support with sync queue
/// - Comprehensive validation with detailed error messages
/// - Conflict resolution for sync operations
/// - Performance optimized with caching
///
/// Example:
/// ```dart
/// final processor = DataProcessor(config: config);
/// final result = await processor.process(inputData);
/// print('Processed ${result.itemCount} items');
/// ```
///
/// See also:
/// - [DataValidator] for validation rules
/// - [SyncManager] for sync operations
class DataProcessor {
  /// Creates a new data processor with the given configuration.
  ///
  /// Parameters:
  /// - [config]: Configuration settings for processing behavior
  /// - [validator]: Custom data validator (creates default if null)
  ///
  /// Throws:
  /// - [ConfigurationException] when config is invalid
  /// - [DependencyException] when dependencies cannot be initialized
  DataProcessor({
    required this.config,
    DataValidator? validator,
  }) : validator = validator ?? DataValidator() {
    _log.fine('Initializing DataProcessor with config: ${config.toJson()}');
    _validateConfiguration();
  }

  // ... implementation
}
```

## Known Constraints and Considerations

- **No web interface features** - The app doesn't replicate advanced features like rule creation/editing
- **Material 3 design** - Follow Material 3 guidelines for consistency
- **No trackers** - The app is explicitly tracker-free, avoid adding analytics libraries
- **Offline-first** - All new features should consider offline functionality
- **Minimal dependencies** - Keep the app "lean", evaluate necessity before adding packages
- **Prefer existing packages** - Use pub.dev packages over custom code when possible
- **Firefly III compatibility** - App must stay compatible with Firefly III API versions
- **Production-ready code** - All implementations must be comprehensive, not minimal

## Platform-Specific Notes

### Android
- Minimum SDK: Check `android/app/build.gradle`
- Notification listener service for banking app notifications (pre-fill transactions) using `notifications_listener_service`
- WorkManager background sync supported via `workmanager` package
- TalkBack accessibility testing required

### iOS
- Local auth (biometric) supported via `local_auth` package
- Background sync limited (iOS restrictions)
- VoiceOver accessibility testing required

## Release Process

See `docs/plans/offline-mode/PHASE_6_RELEASE.md` for release checklist (when implementing releases).

Releases go to:
1. Google Play Store (stable)
2. Google Play Beta Channel (pre-releases)
3. GitHub Releases (APK downloads)

No fixed release schedule - releases when ready.

## Key Packages Reference

### Core Packages
- **flutter** - Framework
- **provider** (^6.1.2) - State management
- **drift** (^2.14.0) - Local database
- **chopper** (^8.4.0) - HTTP client
- **dio** (^5.4.0) - Advanced HTTP operations

### Offline Mode Packages
- **connectivity_plus** (^7.0.0) - Network monitoring
- **internet_connection_checker_plus** (^2.9.1+1) - Internet verification
- **rxdart** (^0.28.0) - Reactive streams
- **uuid** (^4.5.2) - UUID generation
- **synchronized** (^3.4.0) - Thread synchronization
- **retry** (^3.1.2) - Retry logic
- **workmanager** (^0.9.0) - Background tasks

### UI/UX Packages
- **flutter_svg** (^2.2.0) - SVG rendering
- **dynamic_color** (^1.7.0) - Material You colors
- **animations** (^2.0.11) - Page transitions
- **community_charts_flutter** (^1.0.2) - Charts
- **syncfusion_flutter_charts** (^31.1.17) - Advanced charts

### Utilities
- **intl** (0.20.2) - Internationalization
- **logging** (^1.1.1) - Logging framework
- **path_provider** (^2.1.4) - File system paths
- **shared_preferences** (^2.3.4) - Key-value storage
- **package_info_plus** (^9.0.0) - App info
- **local_auth** (^3.0.0) - Biometric auth
- **quick_actions** (^1.0.7) - App shortcuts

Before writing custom code for common functionality, check if any of these packages or similar ones on pub.dev can solve the problem.

## Additional Resources

- **FAQ**: `FAQ.md` in project root
- **Offline mode docs**: `docs/plans/offline-mode/` directory (comprehensive implementation documentation)
- **Test guide**: `test/README.md`
- **Firefly III API**: https://api-docs.firefly-iii.org/
- **Flutter docs**: https://docs.flutter.dev/
- **Material 3**: https://m3.material.io/
- **Drift docs**: https://drift.simonbinder.eu/docs/
- **pub.dev**: https://pub.dev/ (search for packages before writing custom code)

## Architecture Decisions

### Why Provider over Riverpod/Bloc?
Provider is simpler and sufficient for the app's needs. The app prioritizes staying lean.

### Why Drift over other ORMs?
Drift is type-safe, compile-time checked, and has excellent Flutter integration. It's specifically designed for Flutter/Dart.

### Why Chopper for API?
Generated from OpenAPI spec, type-safe, and integrates well with JSON serialization.

### Why offline-first architecture?
Mobile apps frequently lose connectivity. Offline-first ensures the app remains functional and provides a better UX.

## File Naming Conventions

- **Pages**: `lib/pages/feature_name.dart` (lowercase with underscores)
- **Widgets**: `lib/widgets/widget_name.dart`
- **Services**: `lib/services/category/service_name.dart`
- **Models**: `lib/models/model_name.dart`
- **Tables**: `lib/data/local/database/entity_table.dart` (plural)
- **Repositories**: `lib/data/repositories/entity_repository.dart` (singular)
- **Tests**: Mirror source structure (`test/services/service_name_test.dart`)

## Important Global Variables

- `navigatorKey` - Global navigator key in `lib/app.dart`
- `log` - Logger instances (created per-file with `Logger('ClassName')`)
- Database instance - Managed by Drift, accessed through repositories

## Context-Free Services

Some services operate without `BuildContext` (e.g., background sync via `workmanager`):
- Use `Intl.defaultLocale` for localization
- Access device locale directly via `flutter_timezone`
- Store necessary context in service state

This is critical for **background sync** and **WorkManager** tasks that run outside the Flutter UI tree.

## Key Development Principles Summary

1. **PREFER EXISTING PACKAGES**: Always search pub.dev and use prebuilt packages before writing custom code
2. **NO MINIMAL CODE**: Never write minimal implementations - always provide comprehensive, production-ready solutions
3. **Thoroughness Over Speed**: Always provide complete, robust implementations with full error handling
4. **Documentation First**: Document comprehensively - explain why, not just what, including package usage
5. **Error Transparency**: Raise detailed exceptions with full context, never hide failures
6. **Test Everything**: Comprehensive test coverage with realistic scenarios covering all edge cases
7. **Type Safety**: Complete type annotations for all code
8. **Logging for Debugging**: Use proper `Logger` with appropriate levels, never temporary debug code
9. **Offline-First**: Always consider offline functionality for new features
10. **Material 3 Compliance**: Follow Material 3 design guidelines consistently

---

**Remember**: This codebase prioritizes code quality, maintainability, and comprehensive functionality. Every implementation should be production-ready with full error handling, comprehensive logging, thorough testing, and detailed documentation. **Always search for and use existing packages from pub.dev before writing custom implementations.** The offline-first architecture is critical - always consider sync implications for data operations.
