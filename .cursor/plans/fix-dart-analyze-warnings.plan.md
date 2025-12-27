# Fix Dart Analyze Warnings

## Overview

Fix all warnings from `dart analyze .` to ensure clean code before committing.

## Issues Summary

- **Warnings**: ~80 warnings (unused imports, unused variables, null-aware operators, etc.)
- **Info**: ~414 info messages (mostly type annotations and const constructors)

## Priority: Fix Warnings First

### Phase 1: Unused Imports (High Priority)

Files with unused imports:

- `lib/data/repositories/*.dart` - Remove unused `app_database.dart` imports
- `lib/pages/accounts.dart` - Remove unused `chopper.dart` and `auth.dart`
- `lib/pages/bills.dart` - Remove unused `chopper.dart` and `intl.dart`
- `lib/pages/home/*.dart` - Remove unused imports
- `lib/pages/transaction/*.dart` - Remove unused imports
- `lib/services/sync/*.dart` - Remove unused `app_database.dart` imports
- `lib/widgets/fabs.dart` - Remove unused imports
- `test/*.dart` - Remove unused imports

### Phase 2: Unused Variables and Fields

- `lib/data/local/database/app_database.dart:30` - Remove unused `dbPath`
- `lib/data/repositories/*.dart` - Remove unused `updatedAt` variables in update methods
- `lib/pages/home/main.dart:162` - Remove unused `api` variable
- `lib/pages/home/transactions.dart:764` - Remove unused `api` variable
- `lib/pages/transaction.dart:2476` - Remove unused `api` variable
- `lib/services/sync/sync_service.dart:280,732` - Remove unused variables
- `lib/pages/categories.dart:37` - Remove unused `_categoryRepo` field

### Phase 3: Null-Aware Operators and Null Checks

- `lib/data/repositories/account_repository.dart:232` - Fix unnecessary null-aware operator
- `lib/data/repositories/budget_repository.dart:59` - Fix unnecessary null-aware operator
- `lib/data/repositories/currency_repository.dart:52,55` - Fix unnecessary null-aware operators
- `lib/data/repositories/piggy_bank_repository.dart:52` - Fix unnecessary null-aware operator
- `lib/data/repositories/tag_repository.dart:52` - Fix unnecessary null-aware operator
- `lib/data/repositories/transaction_repository.dart:53` - Fix unnecessary null-aware operator
- `lib/pages/transaction.dart:1142,1456,1574,1878,1964` - Fix unnecessary null checks/operators
- `lib/pages/transaction/piggy.dart:103` - Fix dead null-aware expression
- `lib/pages/transaction/tags.dart:176` - Fix dead null-aware expression
- `lib/services/sync/upload_service.dart` - Fix unnecessary null checks and operators
- `lib/pages/settings/sync.dart:216` - Remove unnecessary non-null assertion

### Phase 4: Unused Shown Names

- `lib/data/repositories/account_repository.dart:12` - Remove unused `AccountProperties`
- `lib/data/repositories/budget_repository.dart:11,14` - Remove unused shown names

### Phase 5: Type Pattern Issues

- `lib/pages/transaction.dart` - Fix `AccountTypeFilter` vs `AccountTypeProperty` pattern matching issues (lines 1458, 1460, 1462, 1464, 1465, 1466, 1576, 1578, 1580, 1582, 1583, 1584, 1880, 1882, 1884, 1886, 1887, 1888, 1966, 1968, 1970, 1972, 1973, 1974)

### Phase 6: Unnecessary Casts

- `lib/services/sync/upload_service.dart:221,322` - Remove unnecessary casts
- `test/helpers/mock_isar.dart:104,113` - Remove unnecessary casts

### Phase 7: Override Annotations

- `test/helpers/mock_isar.dart` - Remove `@override` annotations from non-overriding methods (lines 101, 110, 163, 178, 196, 212, 232, 827)

## Execution Steps

1. Fix unused imports across all files
2. Remove unused variables and fields
3. Fix null-aware operators and null checks