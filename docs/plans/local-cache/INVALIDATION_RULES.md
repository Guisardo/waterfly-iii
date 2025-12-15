# Cache Invalidation Rules

## Overview

This document defines comprehensive cache invalidation rules for Waterfly III's cache-first architecture. Proper cache invalidation is critical to prevent stale data from being displayed to users while maintaining the performance benefits of caching.

## Core Principles

1. **Conservative Invalidation**: When in doubt, invalidate. Better to miss cache than show wrong data.
2. **Cascade Invalidation**: Invalidate all related entities when one entity changes.
3. **Granular Control**: Invalidate specific entries when possible, avoid blanket invalidation.
4. **Async Invalidation**: Invalidation should be fast and non-blocking.
5. **Logged Invalidation**: All invalidations logged for debugging and metrics.

---

## Entity Dependency Graph

Understanding entity relationships is crucial for proper invalidation:

```
Transaction
├─> Source Account (affects balance)
├─> Destination Account (affects balance)
├─> Budget (affects spent amount)
├─> Category (affects category totals)
├─> Bill (affects bill payment status)
└─> Tags (affects tag totals)

Account
├─> Transactions (all transactions with this account)
├─> Budgets (budgets auto-calculating from account)
└─> Piggy Banks (linked to account)

Budget
├─> Transactions (all transactions with this budget)
└─> Accounts (accounts used in budget auto-limits)

Category
└─> Transactions (all transactions with this category)

Bill
└─> Transactions (transactions linked to bill)

Piggy Bank
└─> Account (linked account balance)

Currency
└─> All entities with amounts (transactions, accounts, budgets, etc.)

Tags
└─> Transactions (all transactions with this tag)
```

---

## Invalidation Rules by Entity Type

### 1. Transaction Invalidation

**On Transaction Create/Update/Delete**:

```dart
/// Invalidate caches after transaction mutation
///
/// This is the most complex invalidation due to transactions affecting many entities.
/// Comprehensive invalidation ensures all affected data is refreshed.
///
/// Affected caches:
/// - Transaction itself
/// - All transaction lists (paginated, filtered, etc.)
/// - Source account (balance, transaction list)
/// - Destination account (balance, transaction list)
/// - Budget (spent amount, remaining amount)
/// - Category (category totals, transaction list)
/// - Bill (if linked, payment status)
/// - Tags (if present, tag totals)
/// - Dashboard summary data
/// - All chart/graph data
static Future<void> onTransactionMutation(
  CacheService cache,
  Transaction transaction,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after transaction $mutationType: ${transaction.id}');

  // Always invalidate the transaction itself
  await cache.invalidate('transaction', transaction.id);

  // Invalidate ALL transaction lists
  // Reason: Transaction could appear in many filtered/paginated lists
  await cache.invalidateType('transaction_list');
  log.fine('Invalidated all transaction lists');

  // Invalidate source account
  if (transaction.sourceId != null && transaction.sourceId!.isNotEmpty) {
    await cache.invalidate('account', transaction.sourceId!);
    log.fine('Invalidated source account: ${transaction.sourceId}');

    // Invalidate account's transaction list
    await cache.invalidate('account_transactions', transaction.sourceId!);
  }

  // Invalidate destination account
  if (transaction.destinationId != null && transaction.destinationId!.isNotEmpty) {
    await cache.invalidate('account', transaction.destinationId!);
    log.fine('Invalidated destination account: ${transaction.destinationId}');

    // Invalidate account's transaction list
    await cache.invalidate('account_transactions', transaction.destinationId!);
  }

  // Invalidate ALL account lists (balances changed)
  await cache.invalidateType('account_list');
  log.fine('Invalidated all account lists');

  // Invalidate budget if present
  if (transaction.budgetId != null && transaction.budgetId!.isNotEmpty) {
    await cache.invalidate('budget', transaction.budgetId!);
    log.fine('Invalidated budget: ${transaction.budgetId}');

    // Invalidate budget's transaction list
    await cache.invalidate('budget_transactions', transaction.budgetId!);

    // Invalidate all budget lists (spent amounts changed)
    await cache.invalidateType('budget_list');
  }

  // Invalidate category if present
  if (transaction.categoryId != null && transaction.categoryId!.isNotEmpty) {
    await cache.invalidate('category', transaction.categoryId!);
    log.fine('Invalidated category: ${transaction.categoryId}');

    // Invalidate category's transaction list
    await cache.invalidate('category_transactions', transaction.categoryId!);
  }

  // Invalidate bill if present
  if (transaction.billId != null && transaction.billId!.isNotEmpty) {
    await cache.invalidate('bill', transaction.billId!);
    log.fine('Invalidated bill: ${transaction.billId}');

    // Invalidate bill's transaction list
    await cache.invalidate('bill_transactions', transaction.billId!);

    // Invalidate bill list (payment status changed)
    await cache.invalidateType('bill_list');
  }

  // Invalidate tags if present
  if (transaction.tags != null && transaction.tags!.isNotEmpty) {
    for (final tag in transaction.tags!) {
      await cache.invalidate('tag', tag);
      await cache.invalidate('tag_transactions', tag);
      log.fine('Invalidated tag: $tag');
    }
    await cache.invalidateType('tag_list');
  }

  // Invalidate dashboard (summary data affected)
  await cache.invalidateType('dashboard');
  await cache.invalidateType('dashboard_summary');
  log.fine('Invalidated dashboard caches');

  // Invalidate ALL charts/graphs (they aggregate transaction data)
  await cache.invalidateType('chart');
  await cache.invalidateType('chart_account');
  await cache.invalidateType('chart_budget');
  await cache.invalidateType('chart_category');
  log.fine('Invalidated all chart caches');

  log.info('Transaction cache invalidation complete');
}
```

**Special Cases**:

- **Bulk Transaction Import**: Batch invalidate after all imports complete
- **Transaction Split**: Invalidate all splits together
- **Recurring Transaction**: Invalidate recurrence rule cache

---

### 2. Account Invalidation

**On Account Create/Update/Delete**:

```dart
/// Invalidate caches after account mutation
static Future<void> onAccountMutation(
  CacheService cache,
  Account account,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after account $mutationType: ${account.id}');

  // Invalidate the account itself
  await cache.invalidate('account', account.id);

  // Invalidate all account lists
  await cache.invalidateType('account_list');

  // Invalidate account's transaction list
  await cache.invalidate('account_transactions', account.id);

  // If account deleted, invalidate ALL transactions
  // Reason: Transactions with this account need to reflect deleted state
  if (mutationType == MutationType.delete) {
    log.warning('Account deleted, invalidating all transactions');
    await cache.invalidateType('transaction');
    await cache.invalidateType('transaction_list');
  }

  // Invalidate piggy banks linked to this account
  await cache.invalidateType('piggy_bank_list');

  // Invalidate budgets (auto-budget calculations may use account)
  await cache.invalidateType('budget_list');

  // Invalidate dashboard
  await cache.invalidateType('dashboard');
  await cache.invalidateType('dashboard_summary');

  // Invalidate account-specific charts
  await cache.invalidate('chart_account', account.id);
  await cache.invalidateType('chart');

  log.info('Account cache invalidation complete');
}
```

---

### 3. Budget Invalidation

**On Budget Create/Update/Delete**:

```dart
/// Invalidate caches after budget mutation
static Future<void> onBudgetMutation(
  CacheService cache,
  Budget budget,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after budget $mutationType: ${budget.id}');

  // Invalidate the budget itself
  await cache.invalidate('budget', budget.id);

  // Invalidate all budget lists
  await cache.invalidateType('budget_list');

  // Invalidate budget's transaction list
  await cache.invalidate('budget_transactions', budget.id);

  // If budget deleted, invalidate transactions with this budget
  if (mutationType == MutationType.delete) {
    log.warning('Budget deleted, invalidating related transactions');
    // Don't invalidate all transactions - they're still valid, just without budget
    // But invalidate lists that filter by budget
    await cache.invalidateType('transaction_list');
  }

  // Invalidate dashboard (budget summary affected)
  await cache.invalidateType('dashboard');
  await cache.invalidateType('dashboard_summary');

  // Invalidate budget-specific charts
  await cache.invalidate('chart_budget', budget.id);
  await cache.invalidateType('chart');

  log.info('Budget cache invalidation complete');
}
```

---

### 4. Category Invalidation

**On Category Create/Update/Delete**:

```dart
/// Invalidate caches after category mutation
static Future<void> onCategoryMutation(
  CacheService cache,
  Category category,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after category $mutationType: ${category.id}');

  // Invalidate the category itself
  await cache.invalidate('category', category.id);

  // Invalidate all category lists
  await cache.invalidateType('category_list');

  // Invalidate category's transaction list
  await cache.invalidate('category_transactions', category.id);

  // Category changes affect transaction display (name, color, etc.)
  // Invalidate transaction lists (they show category info)
  await cache.invalidateType('transaction_list');

  // If category deleted, invalidate transactions with this category
  if (mutationType == MutationType.delete) {
    log.warning('Category deleted, invalidating related transactions');
    // Transactions still exist, but category reference is now invalid
    await cache.invalidateType('transaction');
  }

  // Invalidate category-specific charts
  await cache.invalidate('chart_category', category.id);
  await cache.invalidateType('chart');

  log.info('Category cache invalidation complete');
}
```

---

### 5. Bill Invalidation

**On Bill Create/Update/Delete**:

```dart
/// Invalidate caches after bill mutation
static Future<void> onBillMutation(
  CacheService cache,
  Bill bill,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after bill $mutationType: ${bill.id}');

  // Invalidate the bill itself
  await cache.invalidate('bill', bill.id);

  // Invalidate all bill lists
  await cache.invalidateType('bill_list');

  // Invalidate bill's transaction list
  await cache.invalidate('bill_transactions', bill.id);

  // Bill changes might affect transaction display
  await cache.invalidateType('transaction_list');

  // Invalidate dashboard (upcoming bills widget)
  await cache.invalidateType('dashboard');

  log.info('Bill cache invalidation complete');
}
```

---

### 6. Piggy Bank Invalidation

**On Piggy Bank Create/Update/Delete**:

```dart
/// Invalidate caches after piggy bank mutation
static Future<void> onPiggyBankMutation(
  CacheService cache,
  PiggyBank piggyBank,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after piggy bank $mutationType: ${piggyBank.id}');

  // Invalidate the piggy bank itself
  await cache.invalidate('piggy_bank', piggyBank.id);

  // Invalidate all piggy bank lists
  await cache.invalidateType('piggy_bank_list');

  // Invalidate linked account (piggy bank affects account display)
  if (piggyBank.accountId != null && piggyBank.accountId!.isNotEmpty) {
    await cache.invalidate('account', piggyBank.accountId!);
    log.fine('Invalidated linked account: ${piggyBank.accountId}');
  }

  // Invalidate dashboard (piggy banks widget)
  await cache.invalidateType('dashboard');

  log.info('Piggy bank cache invalidation complete');
}
```

---

### 7. Currency Invalidation

**On Currency Update** (rare):

```dart
/// Invalidate caches after currency mutation
///
/// Currency changes are rare but affect EVERYTHING with amounts.
static Future<void> onCurrencyMutation(
  CacheService cache,
  Currency currency,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.warning('Invalidating caches after currency $mutationType: ${currency.code}');

  // Currency changes affect all monetary displays
  // Nuclear option: invalidate everything

  await cache.invalidate('currency', currency.code);
  await cache.invalidateType('currency_list');

  // Invalidate all entities with amounts
  await cache.invalidateType('transaction');
  await cache.invalidateType('transaction_list');
  await cache.invalidateType('account');
  await cache.invalidateType('account_list');
  await cache.invalidateType('budget');
  await cache.invalidateType('budget_list');
  await cache.invalidateType('bill');
  await cache.invalidateType('bill_list');
  await cache.invalidateType('piggy_bank');
  await cache.invalidateType('piggy_bank_list');

  // Invalidate dashboard and charts
  await cache.invalidateType('dashboard');
  await cache.invalidateType('chart');

  log.warning('Currency cache invalidation complete - full cache cleared');
}
```

---

### 8. Tag Invalidation

**On Tag Create/Update/Delete**:

```dart
/// Invalidate caches after tag mutation
static Future<void> onTagMutation(
  CacheService cache,
  String tagName,
  MutationType mutationType,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after tag $mutationType: $tagName');

  // Invalidate the tag itself
  await cache.invalidate('tag', tagName);

  // Invalidate all tag lists
  await cache.invalidateType('tag_list');

  // Invalidate tag's transaction list
  await cache.invalidate('tag_transactions', tagName);

  // Tag changes affect transaction display
  await cache.invalidateType('transaction_list');

  log.info('Tag cache invalidation complete');
}
```

---

## Sync-Triggered Invalidation

**On Background Sync Completion**:

When background sync completes, invalidate affected caches:

```dart
/// Invalidate caches after sync operations complete
///
/// Sync operations modify data on the server, so caches must be invalidated
/// to reflect server state.
static Future<void> onSyncComplete(
  CacheService cache,
  List<SyncOperation> operations,
) async {
  final log = Logger('CacheInvalidationRules');
  log.info('Invalidating caches after sync: ${operations.length} operations');

  // Group operations by entity type
  final byType = <String, Set<String>>{};
  for (final op in operations) {
    byType.putIfAbsent(op.entityType, () => <String>{}).add(op.entityId);
  }

  // Invalidate per entity type
  for (final entry in byType.entries) {
    final entityType = entry.key;
    final entityIds = entry.value;

    log.fine('Invalidating $entityType: ${entityIds.length} entities');

    // Invalidate individual entities
    for (final id in entityIds) {
      await cache.invalidate(entityType, id);
    }

    // Invalidate collections
    await cache.invalidateType('${entityType}_list');

    // Cascade invalidation based on entity type
    switch (entityType) {
      case 'transaction':
        // Transactions affect accounts, budgets, categories
        await cache.invalidateType('account');
        await cache.invalidateType('account_list');
        await cache.invalidateType('budget_list');
        await cache.invalidateType('category_list');
        await cache.invalidateType('dashboard');
        await cache.invalidateType('chart');
        break;

      case 'account':
        // Accounts affect dashboard and charts
        await cache.invalidateType('dashboard');
        await cache.invalidateType('chart');
        break;

      case 'budget':
        // Budgets affect dashboard
        await cache.invalidateType('dashboard');
        await cache.invalidateType('chart');
        break;

      // Add more cases as needed
    }
  }

  log.info('Sync cache invalidation complete');
}
```

---

## Manual Invalidation Triggers

**User-Triggered Invalidation**:

1. **Pull-to-Refresh**: Force refresh all visible data
   ```dart
   await cacheService.invalidateType('transaction_list');
   await cacheService.invalidateType('account_list');
   // Then trigger re-fetch with forceRefresh: true
   ```

2. **Settings > Clear Cache**: Nuclear option
   ```dart
   await cacheService.clearAll();
   ```

3. **Account Switch**: Clear user-specific cache
   ```dart
   await cacheService.clearAll();
   ```

4. **Logout**: Clear all cached data
   ```dart
   await cacheService.clearAll();
   ```

---

## Invalidation Performance

### Batch Invalidation

For multiple invalidations, use Drift batch operations:

```dart
/// Batch invalidate multiple entities efficiently
Future<void> invalidateBatch(List<InvalidationRequest> requests) async {
  await _lock.synchronized(() async {
    await database.batch((batch) {
      for (final request in requests) {
        batch.update(
          database.cacheMetadataTable,
          CacheMetadataTableCompanion(
            isInvalidated: Value(true),
          ),
          where: (tbl) =>
              tbl.entityType.equals(request.entityType) &
              tbl.entityId.equals(request.entityId),
        );
      }
    });
  });

  _log.info('Batch invalidated ${requests.length} cache entries');

  // Emit invalidation events
  for (final request in requests) {
    _invalidationStream.add(CacheInvalidationEvent(
      entityType: request.entityType,
      entityId: request.entityId,
      eventType: CacheEventType.invalidated,
    ));
  }
}
```

### Async Invalidation

Invalidation should be fast and non-blocking:

```dart
// Don't await invalidation if not critical
unawaited(cacheService.invalidate('account', accountId));

// Or use fire-and-forget helper
void invalidateAsync(String entityType, String entityId) {
  Future(() => cacheService.invalidate(entityType, entityId)).catchError((e) {
    _log.warning('Async invalidation failed: $entityType:$entityId', e);
  });
}
```

---

## Invalidation Logging

All invalidations should be logged for debugging:

```dart
// In CacheService.invalidate()
Future<void> invalidate(String entityType, String entityId) async {
  _log.info('Invalidating cache: $entityType:$entityId');

  await _lock.synchronized(() async {
    final result = await (database.update(database.cacheMetadataTable)
          ..where((tbl) =>
              tbl.entityType.equals(entityType) &
              tbl.entityId.equals(entityId)))
        .write(CacheMetadataTableCompanion(
      isInvalidated: Value(true),
    ));

    if (result > 0) {
      _log.fine('Cache invalidated: $entityType:$entityId');
    } else {
      _log.fine('Cache entry not found (already cleared): $entityType:$entityId');
    }
  });

  // Emit invalidation event
  _invalidationStream.add(CacheInvalidationEvent(
    entityType: entityType,
    entityId: entityId,
    eventType: CacheEventType.invalidated,
  ));
}
```

---

## Testing Invalidation Rules

### Unit Tests

Test each invalidation rule comprehensively:

```dart
group('Transaction Invalidation Rules', () {
  test('should invalidate all related caches on transaction create', () async {
    // Arrange: cache account, budget, category
    await cacheService.set(entityType: 'account', entityId: '1', data: account1);
    await cacheService.set(entityType: 'budget', entityId: '2', data: budget2);
    await cacheService.set(entityType: 'category', entityId: '3', data: category3);

    // Act: create transaction that affects all three
    final transaction = Transaction(
      id: '100',
      sourceId: '1',
      budgetId: '2',
      categoryId: '3',
    );
    await CacheInvalidationRules.onTransactionMutation(
      cacheService,
      transaction,
      MutationType.create,
    );

    // Assert: all affected caches invalidated
    expect(await cacheService.isFresh('account', '1'), isFalse);
    expect(await cacheService.isFresh('budget', '2'), isFalse);
    expect(await cacheService.isFresh('category', '3'), isFalse);
    expect(await cacheService.isFresh('transaction', '100'), isFalse);
  });

  // ... more comprehensive tests
});
```

---

## Conclusion

Proper cache invalidation is critical for data consistency. These rules ensure that:

1. ✅ Users never see stale data that contradicts their actions
2. ✅ Related entities stay synchronized
3. ✅ Performance benefits of caching are maintained (granular invalidation)
4. ✅ Debugging is possible (comprehensive logging)
5. ✅ Testing validates correct behavior

**Key Principle**: When in doubt, invalidate. The cost of a cache miss is far less than showing incorrect data to users.
