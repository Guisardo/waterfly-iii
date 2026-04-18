---
name: verify
description: Run full lint + test suite for waterfly-iii. Use before marking work done or before creating a PR.
---

Run the full verification pipeline:

1. Lint:
```bash
dart analyze .
```

2. Format check (CI enforces this):
```bash
dart format --set-exit-if-changed .
```

3. Tests:
```bash
flutter test
```

Report: lint issues (count + severity), format violations (list of files), test results (pass/fail counts). If any step fails, report the exact errors — do not suppress or skip.

If tests fail due to missing generated files, run `/codegen` first.
