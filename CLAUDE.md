# CLAUDE.md

Flutter/Dart Android app. Firefly III API client. Dart >=3.10.0, Flutter 3.41.6.

## Commands

```bash
dart analyze .
dart format .
dart format <file>
flutter test
flutter test test/path/to_test.dart
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## After `flutter pub get`

```bash
bash patch_isar_generator.sh
dart run build_runner build --delete-conflicting-outputs
bash fix_generated_files.sh
```

Patch: `~/.pub-cache/.../isar_community_generator-3.3.0/lib/src/helper.dart` + `isar_type.dart`. See BUILD_RUNNER_WORKAROUND.md.

## Codegen triggers

- `lib/data/local/database/tables/` — Isar `@collection`
- Swagger input specs — Chopper API clients
- `@JsonSerializable` classes

Never edit: `lib/generated/`, `lib/data/local/database/tables/*.g.dart`

## Architecture

- State: Provider — `FireflyService`, `SettingsProvider`, `ConnectivityService`, `SyncStatusProvider`
- Local DB: Isar 3.3.0
- API: Chopper + `lib/generated/swagger_fireflyiii_api/`
- Sync: WorkManager, `lib/services/sync/`
- Auth: `local_auth` + `flutter_secure_storage`
- Data: `lib/data/repositories/`

## Lint (strict, CI-enforced)

`always_use_package_imports`, `avoid_types_as_parameter_names`, `always_declare_return_types`, `always_specify_types`, `prefer_null_aware_method_calls`, `unnecessary_null_aware_operator_on_extension_on_nullable`, `unnecessary_null_checks`, `use_if_null_to_convert_nulls_to_bools`, `prefer_const_constructors`, `prefer_final_locals`, `avoid_void_async`, `unawaited_futures`, `unnecessary_async`, `unnecessary_await_in_return`, `use_build_context_synchronously`

Excludes: `lib/generated/**`, `lib/data/local/database/tables/*.g.dart`

## GitHub

Use GitHub API directly. Get credentials via `/github-guisardo`.

## Branching

`feature/*`, `fix/*`, `chore/*` → `master`

## CI

`.github/workflows/commit.yml`: patch isar → codegen → format check → analyze → test. `.github/workflows/release.yml` build job skips on `[skip build]`.

## Custom forks

`notifications_listener_service`, `appcheck` — non-standard APIs, limited maintenance.

## Device testing

Always build+install release. `debugPrint` suppressed in release — use `print` or logcat tag filtering.
```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Never use `flutter install` — it runs `adb uninstall` first, wiping all app data.

## Entry points

`lib/main.dart`, `lib/app.dart`, `lib/data/repositories/`, `lib/services/sync/`
