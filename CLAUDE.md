# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Waterfly III is an unofficial Flutter-based Android app for Firefly III, a free and open source personal finance manager. The app is designed as a companion to the web interface for on-the-go access to the most common functions, with a design heavily influenced by Bluecoins.

**Key Characteristics:**
- Built with Flutter and Material 3 design guidelines
- Minimal dependency philosophy - avoids external packages when possible, no trackers
- Multi-language support via Crowdin
- Offline-capable architecture with local caching

## Development Commands

### Code Generation
```bash
# Generate API clients and serialization code from OpenAPI specs
dart run build_runner build

# Watch mode for continuous generation during development
dart run build_runner watch
```

### Testing
```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/services/math_expression_evaluator_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Run static analysis
dart analyze .

# Check for specific lint issues
flutter analyze
```

### Building
```bash
# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release
```

### Running
```bash
# Run on connected device
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run in profile mode (for performance testing)
flutter run --profile
```

## Architecture

### State Management
The app uses **Provider** for state management with two primary providers:
- `FireflyService` (lib/auth.dart): Manages authentication, API client lifecycle, and API versioning
- `SettingsProvider` (lib/settings.dart): Handles all app settings using SharedPreferences and bitmasks for boolean flags

### API Communication
- **Chopper-based API client**: Generated from OpenAPI specs in `lib/generated/swagger_fireflyiii_api/`
- **CronetClient**: Uses Cronet HTTP client for better performance on Android
- **Minimum API version**: 6.3.2 (enforced at login in lib/auth.dart:27)
- **Authentication**: Bearer token authentication stored in flutter_secure_storage

### Caching Strategy (lib/stock.dart)
The app uses a **Stock-based caching layer** for transactions and categories:
- `TransStock`: Caches transactions with separate stocks for get/getAccount/getSearch operations
- `CatStock`: Caches category data by month
- `CachedSourceOfTruth`: Local cache that serves data while fetching fresh data from API
- Cache invalidation happens automatically when data changes (e.g., transaction dates change)

### Data Flow
1. User authenticates → `AuthUser.create()` validates host/API key → stores credentials
2. `FireflyService.signIn()` creates API client, fetches default currency and timezone
3. Pages use `context.watch<FireflyService>()` to react to auth state changes
4. Transaction data flows through Stock cache layer before reaching UI
5. Settings persist via SharedPreferencesAsync with immediate UI updates via notifyListeners()

### Page Structure (lib/pages/)
- **navigation.dart**: Main bottom navigation container (Dashboard/Transactions/Balance/Settings)
- **home/main.dart**: Dashboard with customizable cards (charts, budgets, bills)
- **transaction.dart**: Complex transaction add/edit form (114KB file with attachments, split transactions, multi-currency)
- **login.dart**: Authentication flow with host URL and API key validation
- **bills.dart**: Bills overview with grouping and sorting
- **categories.dart**: Monthly category spending/earning breakdown
- **accounts.dart**: Asset/expense/revenue/liability account listings

### Key Services (lib/services/)
- **math_expression_evaluator.dart**: Evaluates math expressions in amount fields (e.g., "12.5+3.2")
- **notifications/**: Handles notification listener service for auto-filling transactions from banking apps
- **connectivity/**: Monitors network status for offline mode
- **sync/**: Handles offline data synchronization

### Notification Listener System (lib/notificationlistener.dart)
The app can listen to notifications from banking apps and pre-fill transaction data:
- Settings stored per-app in SharedPreferences with prefix "NL_APP_"
- `NotificationAppSettings` configures default account, title inclusion, auto-add behavior
- Parsed data flows to TransactionPage via NotificationTransaction payload

### Timezone Handling (lib/timezonehandler.dart)
- `TimeZoneHandler` manages server vs. local time based on user preference
- Fetches server timezone from Firefly API configuration endpoint
- Setting controlled via `SettingsProvider.useServerTime`

### Custom Widgets (lib/widgets/)
- **input_number.dart**: Number input with math expression support
- **autocompletetext.dart**: Autocomplete text fields for accounts, categories, tags
- **charts.dart**: Reusable chart components for dashboard
- **fabs.dart**: Floating action buttons with Material animations

### Generated Code
- **lib/generated/l10n/**: Localization files (20+ languages via Crowdin)
- **lib/generated/swagger_fireflyiii_api/**: API client generated via swagger_dart_code_generator

## Development Guidelines

### Code Style (analysis_options.yaml)
Strict linting is enabled with flutter_lints package:
- `always_use_package_imports: true` - No relative imports
- `always_declare_return_types: true` - Explicit return types required
- `always_specify_types: true` - Type annotations required everywhere
- `prefer_const_constructors: true` - Use const where possible
- `prefer_final_locals: true` - Prefer final for local variables
- `use_build_context_synchronously: true` - Prevent context usage across async gaps

### Error Handling Philosophy
- Raise exceptions with detailed error messages (see AuthError hierarchy in lib/auth.dart)
- Use logging extensively for debugging (Logger instances throughout)
- Never hide failures - make errors visible to users with localized messages

### State Management Patterns
- Use Provider's `context.watch<T>()` for reactive UI updates
- Use Provider's `context.read<T>()` for one-time reads without rebuilding
- Use Provider's `context.select<T, R>()` for granular widget rebuilds
- Always check `context.mounted` before using BuildContext after async operations

### API Integration
- All API responses should be validated with `apiThrowErrorIfEmpty()` helper
- Use generated Firefly III client types from lib/generated/swagger_fireflyiii_api/
- Handle API version compatibility (check apiVersion against minApiVersion)
- Consider offline mode - cache data appropriately using Stock pattern

### Testing Practices
- Tests located in test/ directory mirroring lib/ structure
- Use flutter_test for widget tests
- Use test package for unit tests
- Math evaluation has comprehensive test coverage (test/services/math_expression_evaluator_test.dart)

### Commit Workflow (.cursor/commands/commit-dart.md)
1. Run `dart analyze .` and fix all errors/warnings
2. Run all tests and fix any failures
3. If no pending issues, commit and push
4. If pending issues exist, generate an execution plan to resolve them

## User Preferences and Development Rules

### Core Development Philosophy
- **NO MINIMAL CODE**: Always write comprehensive, complete implementations
- **Use Existing Code/Packages**: Prefer prebuilt packages or existing code over creating new implementations
- **Comprehensive Solutions**: Include all necessary error handling, validation, and edge cases
- **Production Ready**: All code should be production-ready with proper logging for debugging

### Flutter-Specific Practices
- Follow Material 3 design guidelines strictly
- Support both light and dark themes (with dynamic colors when available)
- Ensure proper localization for all user-facing strings
- Test on real Android devices when possible
- Keep dependencies minimal - evaluate necessity before adding packages
- Prefer flutter_secure_storage for sensitive data (API keys, tokens)
- Use SharedPreferences (async API) for user settings and preferences

## Common Pitfalls

1. **BuildContext across async**: Always check `context.mounted` after await calls before using context
2. **Provider misuse**: Use `.watch()` for reactive updates, `.read()` for callbacks/one-time reads
3. **Cache invalidation**: When modifying transactions, clear TransStock cache via `.clear()`
4. **API compatibility**: New features must work with minimum API version (6.3.2)
5. **Localization**: Use `S.of(context).keyName` for all user-facing text, never hardcode strings
6. **Type annotations**: Dart analyzer is strict - all types must be explicitly declared
7. **Const constructors**: Use const wherever possible to improve performance
8. **Relative imports**: Always use package imports (`package:waterflyiii/...`), never relative paths

## Key Files to Understand

- **lib/app.dart**: App initialization, lifecycle management, authentication flow, quick actions
- **lib/auth.dart**: Authentication system, API client creation, version checking, error types
- **lib/stock.dart**: Caching layer implementation for transactions and categories
- **lib/settings.dart**: Settings provider with bitmask for boolean flags, SharedPreferences management
- **lib/extensions.dart**: Extension methods on framework types (27KB of utilities)
- **lib/pages/transaction.dart**: Largest and most complex page - transaction form with all features
- **pubspec.yaml**: Dependencies, version, Flutter SDK constraints

## Feature Development Notes

- The app intentionally does NOT replicate all web interface features
- Focus is on companion functionality for on-the-go usage
- Complex operations (rules, reports) should remain web-only
- New features should respect the "lean" philosophy - avoid unnecessary dependencies
- Consider offline functionality for all new features
- Notification listener integration for auto-filling transactions is a key differentiator
