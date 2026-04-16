---
name: codegen
description: Run the full code generation pipeline for waterfly-iii. Use after modifying Isar table schemas, Swagger API specs, or @JsonSerializable models.
---

Run the full codegen pipeline in this order:

1. Verify the Isar generator patch is applied (check if patch script exists and run it):
```bash
.dart_tool/patch_isar_generator.sh
```

2. Run build_runner:
```bash
dart run build_runner build --delete-conflicting-outputs
```

3. Fix null-aware syntax for Dart 3.7 compatibility:
```bash
bash fix_generated_files.sh
```

4. Regenerate localization if any `.arb` files changed:
```bash
flutter gen-l10n
```

5. Run analyze to confirm no errors from generated code:
```bash
dart analyze .
```

Report: how many `.g.dart` files changed, whether analyze passed, any warnings.

If build_runner fails with TypeChecker errors, the Isar patch was not applied or was reset by a `flutter pub get`. Reapply the patch (step 1) and retry. See BUILD_RUNNER_WORKAROUND.md for details.
