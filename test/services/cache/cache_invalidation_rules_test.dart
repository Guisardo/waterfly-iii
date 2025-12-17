import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/cache/cache_service.dart';
import 'package:waterflyiii/services/cache/cache_invalidation_rules.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:drift/native.dart';

/// Mock Transaction for testing
class MockTransaction {
  final String id;
  final String?
  sourceAccountId; // CORRECTED: Match CacheInvalidationRules expectation
  final String?
  destinationAccountId; // CORRECTED: Match CacheInvalidationRules expectation
  final String? budgetId;
  final String? categoryId;
  final String? billId;
  final List<String>? tags;

  MockTransaction({
    required this.id,
    this.sourceAccountId, // CORRECTED
    this.destinationAccountId, // CORRECTED
    this.budgetId,
    this.categoryId,
    this.billId,
    this.tags,
  });
}

/// Mock Account for testing
class MockAccount {
  final String id;
  final String name;

  MockAccount({required this.id, required this.name});
}

/// Mock Budget for testing
class MockBudget {
  final String id;
  final String name;

  MockBudget({required this.id, required this.name});
}

/// Mock Category for testing
class MockCategory {
  final String id;
  final String name;

  MockCategory({required this.id, required this.name});
}

/// Mock Bill for testing
class MockBill {
  final String id;
  final String name;

  MockBill({required this.id, required this.name});
}

/// Mock PiggyBank for testing
class MockPiggyBank {
  final String id;
  final String name;
  final String? accountId;

  MockPiggyBank({required this.id, required this.name, this.accountId});
}

/// Mock Currency for testing
class MockCurrency {
  final String code;
  final String name;

  MockCurrency({required this.code, required this.name});
}

/// Spy CacheService for tracking invalidation calls
class SpyCacheService extends CacheService {
  final List<InvalidationCall> invalidationCalls = <InvalidationCall>[];

  SpyCacheService(AppDatabase database) : super(database: database);

  @override
  Future<void> invalidate(String entityType, String entityId) async {
    invalidationCalls.add(
      InvalidationCall(
        type: InvalidationType.single,
        entityType: entityType,
        entityId: entityId,
      ),
    );
    await super.invalidate(entityType, entityId);
  }

  @override
  Future<void> invalidateType(String entityType) async {
    invalidationCalls.add(
      InvalidationCall(
        type: InvalidationType.typeLevel,
        entityType: entityType,
        entityId: '*',
      ),
    );
    await super.invalidateType(entityType);
  }

  void clearInvalidationCalls() {
    invalidationCalls.clear();
  }
}

/// Represents an invalidation call for testing
class InvalidationCall {
  final InvalidationType type;
  final String entityType;
  final String entityId;

  InvalidationCall({
    required this.type,
    required this.entityType,
    required this.entityId,
  });

  @override
  String toString() =>
      'InvalidationCall(type: $type, entityType: $entityType, entityId: $entityId)';
}

enum InvalidationType { single, typeLevel }

/// Comprehensive Unit Tests for CacheInvalidationRules
///
/// Tests cover:
/// - Transaction mutation invalidation (comprehensive cascade)
/// - Account mutation invalidation
/// - Budget mutation invalidation
/// - Category mutation invalidation
/// - Bill mutation invalidation
/// - Piggy bank mutation invalidation
/// - Currency mutation invalidation (nuclear option)
/// - Tag mutation invalidation
/// - Sync-triggered invalidation with batching
/// - Cascade behavior for related entities
/// - MutationType variations (create, update, delete)
///
/// Target: >85% code coverage
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CacheInvalidationRules', () {
    late AppDatabase database;
    late SpyCacheService cacheService;

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
      cacheService = SpyCacheService(database);
    });

    tearDown(() async {
      cacheService.dispose();
      await database.close();
    });

    group('onTransactionMutation() - Transaction invalidation', () {
      test(
        'should invalidate all related caches on transaction create',
        () async {
          // Arrange: Transaction affecting multiple entities
          final MockTransaction transaction = MockTransaction(
            id: 'txn_123',
            sourceAccountId: 'acc_src',
            destinationAccountId: 'acc_dest',
            budgetId: 'budget_1',
            categoryId: 'cat_1',
            billId: 'bill_1',
            tags: <String>['tag1', 'tag2'],
          );

          cacheService.clearInvalidationCalls();

          // Act: Trigger transaction mutation
          await CacheInvalidationRules.onTransactionMutation(
            cacheService,
            transaction,
            MutationType.create,
          );

          // Wait for async invalidations
          await Future.delayed(const Duration(milliseconds: 50));

          // Assert: All affected caches invalidated
          final List<InvalidationCall> calls = cacheService.invalidationCalls;

          // Transaction itself
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'transaction' &&
                  c.entityId == 'txn_123' &&
                  c.type == InvalidationType.single,
            ),
            hasLength(1),
          );

          // All transaction lists
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'transaction_list' &&
                  c.type == InvalidationType.typeLevel,
            ),
            hasLength(1),
          );

          // Source account
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'account' &&
                  c.entityId == 'acc_src' &&
                  c.type == InvalidationType.single,
            ),
            hasLength(1),
          );

          // Destination account
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'account' &&
                  c.entityId == 'acc_dest' &&
                  c.type == InvalidationType.single,
            ),
            hasLength(1),
          );

          // All account lists
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'account_list' &&
                  c.type == InvalidationType.typeLevel,
            ),
            hasLength(1),
          );

          // Budget
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'budget' &&
                  c.entityId == 'budget_1' &&
                  c.type == InvalidationType.single,
            ),
            hasLength(1),
          );

          // Category
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'category' &&
                  c.entityId == 'cat_1' &&
                  c.type == InvalidationType.single,
            ),
            hasLength(1),
          );

          // Bill
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'bill' &&
                  c.entityId == 'bill_1' &&
                  c.type == InvalidationType.single,
            ),
            hasLength(1),
          );

          // Dashboard
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'dashboard' &&
                  c.type == InvalidationType.typeLevel,
            ),
            hasLength(greaterThanOrEqualTo(1)),
          );

          // Charts
          expect(
            calls.where(
              (InvalidationCall c) =>
                  c.entityType == 'chart' &&
                  c.type == InvalidationType.typeLevel,
            ),
            hasLength(greaterThanOrEqualTo(1)),
          );
        },
      );

      test('should handle transaction with minimal fields', () async {
        // Arrange: Transaction with only required fields
        final MockTransaction transaction = MockTransaction(id: 'txn_min');

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Basic invalidations still occur
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'transaction' && c.entityId == 'txn_min',
          ),
          hasLength(1),
        );

        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'transaction_list',
          ),
          hasLength(1),
        );

        // No account/budget/category invalidations (fields null)
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'account' && c.type == InvalidationType.single,
          ),
          isEmpty,
        );
      });

      test('should invalidate for transaction update', () async {
        // Arrange
        final MockTransaction transaction = MockTransaction(
          id: 'txn_update',
          sourceAccountId: 'acc_1',
          budgetId: 'budget_1',
        );

        cacheService.clearInvalidationCalls();

        // Act: Update mutation
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.update,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Same invalidation as create
        final List<InvalidationCall> calls = cacheService.invalidationCalls;
        expect(calls, isNotEmpty);
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'transaction' && c.entityId == 'txn_update',
          ),
          hasLength(1),
        );
      });

      test('should invalidate for transaction delete', () async {
        // Arrange
        final MockTransaction transaction = MockTransaction(
          id: 'txn_delete',
          sourceAccountId: 'acc_1',
          categoryId: 'cat_1',
        );

        cacheService.clearInvalidationCalls();

        // Act: Delete mutation
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.delete,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Same cascade as create/update
        final List<InvalidationCall> calls = cacheService.invalidationCalls;
        expect(calls, isNotEmpty);
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'transaction' && c.entityId == 'txn_delete',
          ),
          hasLength(1),
        );
      });

      test('should invalidate tags when present', () async {
        // Arrange: Transaction with tags
        final MockTransaction transaction = MockTransaction(
          id: 'txn_tags',
          tags: <String>['groceries', 'food', 'walmart'],
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Tag-related invalidations
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'tag' && c.entityId == 'groceries',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'tag_list'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });
    });

    group('onAccountMutation() - Account invalidation', () {
      test('should invalidate account and related caches', () async {
        // Arrange
        final MockAccount account = MockAccount(
          id: 'acc_123',
          name: 'Checking',
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onAccountMutation(
          cacheService,
          account,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Account itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'account' && c.entityId == 'acc_123',
          ),
          hasLength(1),
        );

        // Account lists
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'account_list'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Dashboard
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'dashboard'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });

      test('should invalidate all transactions on account delete', () async {
        // Arrange
        final MockAccount account = MockAccount(
          id: 'acc_del',
          name: 'Old Account',
        );

        cacheService.clearInvalidationCalls();

        // Act: Delete mutation
        await CacheInvalidationRules.onAccountMutation(
          cacheService,
          account,
          MutationType.delete,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: All transactions invalidated
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'transaction'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'transaction_list',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });

      test(
        'should not invalidate transactions on account create/update',
        () async {
          // Arrange
          final MockAccount account = MockAccount(
            id: 'acc_new',
            name: 'New Account',
          );

          cacheService.clearInvalidationCalls();

          // Act: Create mutation
          await CacheInvalidationRules.onAccountMutation(
            cacheService,
            account,
            MutationType.create,
          );

          await Future.delayed(const Duration(milliseconds: 50));

          // Assert: Transactions NOT invalidated (only on delete)
          final List<InvalidationCall> calls = cacheService.invalidationCalls;

          expect(
            calls
                .where(
                  (InvalidationCall c) =>
                      c.entityType == 'transaction' &&
                      c.type == InvalidationType.typeLevel,
                )
                .length,
            equals(0),
          );
        },
      );
    });

    group('onBudgetMutation() - Budget invalidation', () {
      test('should invalidate budget and related caches', () async {
        // Arrange
        final MockBudget budget = MockBudget(
          id: 'budget_123',
          name: 'Monthly Budget',
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onBudgetMutation(
          cacheService,
          budget,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Budget itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'budget' && c.entityId == 'budget_123',
          ),
          hasLength(1),
        );

        // Budget lists
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'budget_list'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Dashboard
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'dashboard'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });

      test('should invalidate transaction lists on budget delete', () async {
        // Arrange
        final MockBudget budget = MockBudget(
          id: 'budget_del',
          name: 'Old Budget',
        );

        cacheService.clearInvalidationCalls();

        // Act: Delete mutation
        await CacheInvalidationRules.onBudgetMutation(
          cacheService,
          budget,
          MutationType.delete,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Transaction lists invalidated
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'transaction_list',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });
    });

    group('onCategoryMutation() - Category invalidation', () {
      test('should invalidate category and related caches', () async {
        // Arrange
        final MockCategory category = MockCategory(
          id: 'cat_123',
          name: 'Groceries',
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onCategoryMutation(
          cacheService,
          category,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Category itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'category' && c.entityId == 'cat_123',
          ),
          hasLength(1),
        );

        // Category lists
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'category_list'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Transaction lists (category display in transactions)
        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'transaction_list',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });

      test('should invalidate transactions on category delete', () async {
        // Arrange
        final MockCategory category = MockCategory(
          id: 'cat_del',
          name: 'Old Category',
        );

        cacheService.clearInvalidationCalls();

        // Act: Delete mutation
        await CacheInvalidationRules.onCategoryMutation(
          cacheService,
          category,
          MutationType.delete,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: All transactions invalidated
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'transaction'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });
    });

    group('onBillMutation() - Bill invalidation', () {
      test('should invalidate bill and related caches', () async {
        // Arrange
        final MockBill bill = MockBill(id: 'bill_123', name: 'Electric Bill');

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onBillMutation(
          cacheService,
          bill,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Bill itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'bill' && c.entityId == 'bill_123',
          ),
          hasLength(1),
        );

        // Bill lists
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'bill_list'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Dashboard (upcoming bills widget)
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'dashboard'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });

      test('should invalidate transaction lists on bill mutation', () async {
        // Arrange
        final MockBill bill = MockBill(id: 'bill_456', name: 'Internet Bill');

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onBillMutation(
          cacheService,
          bill,
          MutationType.update,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Transaction lists invalidated
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'transaction_list',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });
    });

    group('onPiggyBankMutation() - Piggy bank invalidation', () {
      test('should invalidate piggy bank and related caches', () async {
        // Arrange
        final MockPiggyBank piggyBank = MockPiggyBank(
          id: 'piggy_123',
          name: 'Vacation Fund',
          accountId: 'acc_1',
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onPiggyBankMutation(
          cacheService,
          piggyBank,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Piggy bank itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'piggy_bank' && c.entityId == 'piggy_123',
          ),
          hasLength(1),
        );

        // Piggy bank lists
        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'piggy_bank_list',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Linked account
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'account' && c.entityId == 'acc_1',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Dashboard
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'dashboard'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });

      test('should handle piggy bank without linked account', () async {
        // Arrange: Piggy bank with no account
        final MockPiggyBank piggyBank = MockPiggyBank(
          id: 'piggy_noacc',
          name: 'Vacation Fund',
          accountId: null,
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onPiggyBankMutation(
          cacheService,
          piggyBank,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: No account invalidation
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        expect(
          calls
              .where(
                (InvalidationCall c) =>
                    c.entityType == 'account' &&
                    c.type == InvalidationType.single,
              )
              .length,
          equals(0),
        );
      });
    });

    group('onCurrencyMutation() - Currency invalidation (nuclear)', () {
      test('should invalidate EVERYTHING on currency mutation', () async {
        // Arrange
        final MockCurrency currency = MockCurrency(
          code: 'USD',
          name: 'US Dollar',
        );

        cacheService.clearInvalidationCalls();

        // Act: Currency mutation (rare but affects everything)
        await CacheInvalidationRules.onCurrencyMutation(
          cacheService,
          currency,
          MutationType.update,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Nuclear invalidation
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Currency itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'currency' && c.entityId == 'USD',
          ),
          hasLength(1),
        );

        // All entity types with amounts invalidated
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'transaction'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'account'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'budget'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'dashboard'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        expect(
          calls.where((InvalidationCall c) => c.entityType == 'chart'),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });
    });

    group('onTagMutation() - Tag invalidation', () {
      test('should invalidate tag and related caches', () async {
        // Arrange
        const String tagName = 'groceries';

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onTagMutation(
          cacheService,
          tagName,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Tag itself
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'tag' && c.entityId == tagName,
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Tag lists
        expect(
          calls.where((InvalidationCall c) => c.entityType == 'tag_list'),
          hasLength(greaterThanOrEqualTo(1)),
        );

        // Transaction lists (tags affect transaction display)
        expect(
          calls.where(
            (InvalidationCall c) => c.entityType == 'transaction_list',
          ),
          hasLength(greaterThanOrEqualTo(1)),
        );
      });
    });

    group('Cascade Behavior', () {
      test('should cascade invalidations for complex transaction', () async {
        // Arrange: Complex transaction touching many entities
        final MockTransaction transaction = MockTransaction(
          id: 'txn_complex',
          sourceAccountId: 'acc_src',
          destinationAccountId: 'acc_dest',
          budgetId: 'budget_1',
          categoryId: 'cat_1',
          billId: 'bill_1',
          tags: <String>['tag1', 'tag2', 'tag3'],
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: Comprehensive cascade
        final List<InvalidationCall> calls = cacheService.invalidationCalls;

        // Count unique entity types affected
        final Set<String> affectedEntityTypes =
            calls.map((InvalidationCall c) => c.entityType).toSet();

        // Should affect at least: transaction, account, budget, category, bill, tag, dashboard, chart
        expect(affectedEntityTypes.length, greaterThanOrEqualTo(8));
      });
    });

    group('Edge Cases', () {
      test('should handle null entity fields gracefully', () async {
        // Arrange: Transaction with all optional fields null
        final MockTransaction transaction = MockTransaction(
          id: 'txn_null',
          sourceAccountId: null,
          destinationAccountId: null,
          budgetId: null,
          categoryId: null,
          billId: null,
          tags: null,
        );

        cacheService.clearInvalidationCalls();

        // Act & Assert: Should not throw
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Minimal invalidations still occur
        final List<InvalidationCall> calls = cacheService.invalidationCalls;
        expect(calls, isNotEmpty);
      });

      test('should handle empty string entity IDs', () async {
        // Arrange: Transaction with empty string IDs
        final MockTransaction transaction = MockTransaction(
          id: 'txn_empty',
          sourceAccountId: '',
          destinationAccountId: '',
        );

        cacheService.clearInvalidationCalls();

        // Act & Assert: Should handle gracefully
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Should not invalidate accounts with empty IDs
        final List<InvalidationCall> calls = cacheService.invalidationCalls;
        expect(
          calls.where(
            (InvalidationCall c) =>
                c.entityType == 'account' && c.entityId == '',
          ),
          isEmpty,
        );
      });

      test('should handle empty tags list', () async {
        // Arrange: Transaction with empty tags list
        final MockTransaction transaction = MockTransaction(
          id: 'txn_notags',
          tags: <String>[],
        );

        cacheService.clearInvalidationCalls();

        // Act
        await CacheInvalidationRules.onTransactionMutation(
          cacheService,
          transaction,
          MutationType.create,
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Assert: No tag invalidations
        final List<InvalidationCall> calls = cacheService.invalidationCalls;
        expect(
          calls
              .where(
                (InvalidationCall c) =>
                    c.entityType == 'tag' && c.type == InvalidationType.single,
              )
              .length,
          equals(0),
        );
      });
    });
  });
}
