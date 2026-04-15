# CLAUDE.md

Flutter Android app for Firefly III. Material 3, minimal deps, offline-capable, 24-language i18n.

## Commands
```bash
dart run build_runner build --delete-conflicting-outputs  # codegen
flutter test                                              # tests
dart analyze .                                            # lint
flutter build apk --debug / --release
flutter build appbundle --release
flutter run [--debug|--profile]
```

## Architecture

**State:** Provider — `FireflyService` (lib/auth.dart), `SettingsProvider` (lib/settings.dart)

**API:** Chopper client generated from OpenAPI (lib/generated/swagger_fireflyiii_api/). CronetClient. Min API: 6.3.2. Bearer token in flutter_secure_storage.

**Cache:** Local-first. Isar NoSQL in lib/data/local/database/. Repos in lib/data/repositories/. Background sync. Invalidation on change. Schema via `@collection` annotations.

**Data flow:** AuthUser.create() → FireflyService.signIn() → API client → pages watch FireflyService → transactions through Stock cache → settings via SharedPreferencesAsync

**Pages (lib/pages/):**
- navigation.dart — bottom nav
- home/main.dart — dashboard
- transaction.dart — add/edit form (114KB, splits, attachments, multi-currency)
- login.dart, bills.dart, categories.dart, accounts.dart

**Services (lib/services/):**
- math_expression_evaluator.dart — eval math in amount fields
- notifications/ — banking app notification listener
- connectivity/ — offline detection
- sync/ — background sync

**Other:**
- lib/notificationlistener.dart — NL_APP_ prefix settings, NotificationTransaction → TransactionPage
- lib/timezonehandler.dart — server vs local time, SettingsProvider.useServerTime
- lib/widgets/ — input_number.dart, autocompletetext.dart, charts.dart, fabs.dart
- lib/generated/l10n/ — i18n files
- lib/generated/swagger_fireflyiii_api/ — generated API client

## Key Files
- lib/app.dart — init, lifecycle, auth flow, quick actions
- lib/auth.dart — auth, API client, version check, AuthError types
- lib/stock.dart — transaction/category cache
- lib/settings.dart — bitmask flags, SharedPreferences
- lib/extensions.dart — framework extension methods
- lib/pages/transaction.dart — most complex page
- pubspec.yaml — deps, versions

## Code Rules

**Lint (analysis_options.yaml):**
- always_use_package_imports, always_declare_return_types, always_specify_types
- prefer_const_constructors, prefer_final_locals, use_build_context_synchronously

**Patterns:**
- context.watch<T>() reactive, context.read<T>() one-time, context.select<T,R>() granular
- check context.mounted after every await
- apiThrowErrorIfEmpty() on all API responses
- clear TransStock cache on transaction modify (.clear())
- package imports only: package:waterflyiii/...

**i18n — CRITICAL:**
- ALL user-facing text via S.of(context).keyName — no hardcoded strings
- Add to lib/l10n/app_en.arb, then ALL 24 ARB files:
  en, de, fr, es, it, nl, pt, pt-BR, ru, zh, zh-TW, pl, ca, cs, da, hu, ro, sl, sv, tr, uk, fa, id, ko
- Placeholders: ARB placeholder syntax with types
- Background services: see lib/services/sync/sync_notifications.dart for locale without BuildContext

**Error handling:** raise with detail, log with Logger, never swallow. See AuthError hierarchy.

**API:** validate with apiThrowErrorIfEmpty(), check apiVersion ≥ minApiVersion, cache via Stock pattern.

## Pitfalls
- context.mounted after await
- watch() reactive / read() callbacks
- clear TransStock on transaction change
- min API 6.3.2 compat
- all text localized in all 24 langs
- explicit types everywhere
- const constructors always
- package imports never relative

## Commit Workflow
1. dart analyze . — fix all
2. flutter test — fix all
3. commit+push / generate plan if issues

## Debugging
Use print() with NDJSON. Wrap in `// #region agent log` / `// #endregion`. No file I/O.

```dart
print(jsonEncode({
  "sessionId": "s", "runId": "r", "hypothesisId": "A",
  "location": "file.dart:123", "message": "...",
  "data": {}, "timestamp": DateTime.now().millisecondsSinceEpoch
}));
```

Collect: `flutter run 2>&1 | tee .cursor/debug.log` or `adb logcat | grep '{' | jq -c '.'`
