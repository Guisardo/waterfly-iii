# CLAUDE.md

Flutter/Dart Android app. Firefly III API client. Dart >=3.7.0, Flutter 3.41.6.

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
.dart_tool/patch_isar_generator.sh
dart run build_runner build --delete-conflicting-outputs
bash fix_generated_files.sh
```

Patch: `~/.pub-cache/.../isar_community_generator-3.3.0/lib/src/helper.dart` + `isar_type.dart`. See BUILD_RUNNER_WORKAROUND.md.

## Codegen triggers

- `lib/data/local/database/tables/` — Isar `@Collection`
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

`always_use_package_imports`, `always_specify_types`, `prefer_final_locals`, `prefer_const_constructors`, `unawaited_futures`, `use_build_context_synchronously`

Excludes: `lib/generated/**`, `lib/data/local/database/tables/*.g.dart`

## GitHub

Use GitHub API directly. Get credentials via `/guisardo-github`.

## Branching

`feature/*`, `fix/*`, `chore/*` → `master`

## CI

`.github/workflows/commit.yml`: patch isar → codegen → format check → analyze → test. Skip: `[skip build]` in commit message.

## Custom forks

`notification_listener_service`, `appcheck` — non-standard APIs, limited maintenance.

## Device testing

Always install with `adb install -r` to preserve user data (credentials, local DB):
```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```
Never use `flutter install` — it runs `adb uninstall` first, wiping all app data.

## Entry points

`lib/main.dart`, `lib/app.dart`, `lib/data/repositories/`, `lib/services/sync/`
