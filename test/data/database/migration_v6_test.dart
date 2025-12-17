import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';

void main() {
  group('Database Migration v5 to v6', () {
    late AppDatabase database;

    setUp(() async {
      // Create in-memory database for testing
      // This will run all migrations up to v6
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    group('Table Creation', () {
      test('should create sync_statistics table with correct schema', () async {
        // Verify table exists
        final List<SyncStatisticsEntity> stats =
            await database.select(database.syncStatistics).get();
        expect(stats, isNotEmpty);
        expect(stats.length, equals(6)); // 6 entity types
      });

      test('should have correct columns in sync_statistics table', () async {
        // Query table info
        final List<QueryRow> columns =
            await database
                .customSelect("PRAGMA table_info(sync_statistics)")
                .get();

        final List<String> columnNames =
            columns.map((QueryRow col) => col.read<String>('name')).toList();

        expect(columnNames, contains('entity_type'));
        expect(columnNames, contains('last_incremental_sync'));
        expect(columnNames, contains('last_full_sync'));
        expect(columnNames, contains('items_fetched_total'));
        expect(columnNames, contains('items_updated_total'));
        expect(columnNames, contains('items_skipped_total'));
        expect(columnNames, contains('bandwidth_saved_bytes'));
        expect(columnNames, contains('api_calls_saved_count'));
        expect(columnNames, contains('sync_window_start'));
        expect(columnNames, contains('sync_window_end'));
        expect(columnNames, contains('sync_window_days'));
      });
    });

    group('Column Additions', () {
      test('should add server_updated_at column to transactions', () async {
        final DateTime now = DateTime.now();

        // First create accounts (required by FK constraint)
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'src-acc-1',
                name: 'Source Account',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'dst-acc-1',
                name: 'Destination Account',
                type: 'expense',
                currencyCode: 'USD',
                currentBalance: 0.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Insert transaction with serverUpdatedAt
        await database
            .into(database.transactions)
            .insert(
              TransactionEntityCompanion.insert(
                id: 'test-tx-123',
                serverId: const Value<String?>('server-123'),
                description: 'Test Transaction',
                amount: 100.0,
                date: now,
                type: 'withdrawal',
                currencyCode: 'USD',
                sourceAccountId: 'src-acc-1',
                destinationAccountId: 'dst-acc-1',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Verify serverUpdatedAt column exists (should be null initially)
        final TransactionEntity transaction =
            await (database.select(database.transactions)..where(
              ($TransactionsTable t) => t.id.equals('test-tx-123'),
            )).getSingle();

        expect(transaction.serverUpdatedAt, isNull); // Nullable column
      });

      test('should add server_updated_at column to accounts', () async {
        final DateTime now = DateTime.now();

        // Insert account
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'test-acc-123',
                serverId: const Value<String?>('server-acc-123'),
                name: 'Test Account',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Verify serverUpdatedAt column exists
        final AccountEntity account =
            await (database.select(database.accounts)..where(
              ($AccountsTable a) => a.id.equals('test-acc-123'),
            )).getSingle();

        expect(account.serverUpdatedAt, isNull);
      });

      test('should add server_updated_at column to budgets', () async {
        final DateTime now = DateTime.now();

        await database
            .into(database.budgets)
            .insert(
              BudgetEntityCompanion.insert(
                id: 'test-bgt-123',
                serverId: const Value<String?>('server-bgt-123'),
                name: 'Test Budget',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final BudgetEntity budget =
            await (database.select(database.budgets)..where(
              ($BudgetsTable b) => b.id.equals('test-bgt-123'),
            )).getSingle();

        expect(budget.serverUpdatedAt, isNull);
      });

      test('should add server_updated_at column to categories', () async {
        final DateTime now = DateTime.now();

        await database
            .into(database.categories)
            .insert(
              CategoryEntityCompanion.insert(
                id: 'test-cat-123',
                serverId: const Value<String?>('server-cat-123'),
                name: 'Test Category',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final CategoryEntity category =
            await (database.select(database.categories)..where(
              ($CategoriesTable c) => c.id.equals('test-cat-123'),
            )).getSingle();

        expect(category.serverUpdatedAt, isNull);
      });

      test('should add server_updated_at column to bills', () async {
        final DateTime now = DateTime.now();

        await database
            .into(database.bills)
            .insert(
              BillEntityCompanion.insert(
                id: 'test-bill-123',
                serverId: const Value<String?>('server-bill-123'),
                name: 'Test Bill',
                minAmount: 50.0,
                maxAmount: 100.0,
                date: now,
                repeatFreq: 'monthly',
                currencyCode: 'USD',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final BillEntity bill =
            await (database.select(database.bills)..where(
              ($BillsTable b) => b.id.equals('test-bill-123'),
            )).getSingle();

        expect(bill.serverUpdatedAt, isNull);
      });

      test('should add server_updated_at column to piggy_banks', () async {
        final DateTime now = DateTime.now();

        // First create an account for the piggy bank
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'piggy-acc-123',
                serverId: const Value<String?>('server-piggy-acc-123'),
                name: 'Piggy Bank Account',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 5000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.piggyBanks)
            .insert(
              PiggyBankEntityCompanion.insert(
                id: 'test-piggy-123',
                serverId: const Value<String?>('server-piggy-123'),
                name: 'Test Piggy Bank',
                accountId: 'piggy-acc-123',
                targetAmount: const Value<double?>(1000.0),
                currentAmount: const Value<double>(0.0),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final PiggyBankEntity piggyBank =
            await (database.select(database.piggyBanks)..where(
              ($PiggyBanksTable p) => p.id.equals('test-piggy-123'),
            )).getSingle();

        expect(piggyBank.serverUpdatedAt, isNull);
      });

      test('should verify all entity tables have server_updated_at', () async {
        final List<String> tables = <String>[
          'transactions',
          'accounts',
          'budgets',
          'categories',
          'bills',
          'piggy_banks',
        ];

        for (final String table in tables) {
          final List<QueryRow> columns =
              await database.customSelect("PRAGMA table_info($table)").get();

          final bool hasServerUpdatedAt = columns.any(
            (QueryRow col) => col.read<String>('name') == 'server_updated_at',
          );

          expect(
            hasServerUpdatedAt,
            isTrue,
            reason: 'Table $table should have server_updated_at column',
          );
        }
      });
    });

    group('Index Creation', () {
      test('should create indexes on server_updated_at columns', () async {
        // Query sqlite_master for indexes
        final List<QueryRow> indexes =
            await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='index' "
                  "AND name LIKE 'idx_%_server_updated_at'",
                )
                .get();

        expect(indexes.length, greaterThanOrEqualTo(6));

        final List<String> indexNames =
            indexes.map((QueryRow i) => i.read<String>('name')).toList();

        expect(indexNames, contains('idx_transactions_server_updated_at'));
        expect(indexNames, contains('idx_accounts_server_updated_at'));
        expect(indexNames, contains('idx_budgets_server_updated_at'));
        expect(indexNames, contains('idx_categories_server_updated_at'));
        expect(indexNames, contains('idx_bills_server_updated_at'));
        expect(indexNames, contains('idx_piggy_banks_server_updated_at'));
      });
    });

    group('Backfill Logic', () {
      test('should backfill server_updated_at from updated_at', () async {
        // This tests the manual backfill behavior
        final DateTime now = DateTime.now();

        // First create accounts (required by FK constraint)
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'src-acc-backfill',
                name: 'Source Account Backfill',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'dst-acc-backfill',
                name: 'Dest Account Backfill',
                type: 'expense',
                currencyCode: 'USD',
                currentBalance: 0.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Insert transaction with updated_at but no server_updated_at
        await database
            .into(database.transactions)
            .insert(
              TransactionEntityCompanion.insert(
                id: 'backfill-tx-123',
                serverId: const Value<String?>('backfill-server-123'),
                description: 'Test',
                amount: 100.0,
                date: now,
                type: 'withdrawal',
                currencyCode: 'USD',
                sourceAccountId: 'src-acc-backfill',
                destinationAccountId: 'dst-acc-backfill',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Manually trigger backfill (would happen during migration)
        await database.customStatement(
          "UPDATE transactions SET server_updated_at = updated_at "
          "WHERE id = 'backfill-tx-123' AND server_updated_at IS NULL",
        );

        // Verify backfilled
        final TransactionEntity transaction =
            await (database.select(database.transactions)..where(
              ($TransactionsTable t) => t.id.equals('backfill-tx-123'),
            )).getSingle();

        expect(transaction.serverUpdatedAt, isNotNull);
        // Note: Due to DateTime precision, we check they're close
        expect(
          transaction.serverUpdatedAt!.difference(now).inSeconds.abs(),
          lessThan(2),
        );
      });

      test('should not overwrite existing server_updated_at', () async {
        final DateTime now = DateTime.now();
        final DateTime earlier = now.subtract(const Duration(hours: 1));

        // First create accounts (required by FK constraint)
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'src-acc-nooverwrite',
                name: 'Source Account NoOverwrite',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'dst-acc-nooverwrite',
                name: 'Dest Account NoOverwrite',
                type: 'expense',
                currencyCode: 'USD',
                currentBalance: 0.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Insert transaction with both updated_at and server_updated_at
        await database
            .into(database.transactions)
            .insert(
              TransactionEntityCompanion.insert(
                id: 'nooverwrite-tx-456',
                serverId: const Value<String?>('nooverwrite-server-456'),
                description: 'Test Existing',
                amount: 200.0,
                date: now,
                type: 'withdrawal',
                currencyCode: 'USD',
                sourceAccountId: 'src-acc-nooverwrite',
                destinationAccountId: 'dst-acc-nooverwrite',
                createdAt: now,
                updatedAt: now,
                serverUpdatedAt: Value<DateTime?>(earlier),
              ),
            );

        // Backfill should not affect this row
        await database.customStatement(
          'UPDATE transactions SET server_updated_at = updated_at '
          'WHERE server_updated_at IS NULL AND updated_at IS NOT NULL',
        );

        // Verify server_updated_at was NOT overwritten
        final TransactionEntity transaction =
            await (database.select(database.transactions)..where(
              ($TransactionsTable t) => t.id.equals('nooverwrite-tx-456'),
            )).getSingle();

        expect(
          transaction.serverUpdatedAt!.difference(earlier).inSeconds.abs(),
          lessThan(2),
        );
      });
    });

    group('Statistics Initialization', () {
      test('should initialize sync statistics for all entity types', () async {
        final List<SyncStatisticsEntity> stats =
            await database.select(database.syncStatistics).get();

        final Set<String> entityTypes =
            stats.map((SyncStatisticsEntity s) => s.entityType).toSet();

        expect(
          entityTypes,
          containsAll(<String>[
            'transaction',
            'account',
            'budget',
            'category',
            'bill',
            'piggy_bank',
          ]),
        );
      });

      test('should have default values for statistics', () async {
        final SyncStatisticsEntity? transactionStats =
            await (database.select(database.syncStatistics)..where(
              ($SyncStatisticsTable s) => s.entityType.equals('transaction'),
            )).getSingleOrNull();

        expect(transactionStats, isNotNull);
        expect(transactionStats!.itemsFetchedTotal, equals(0));
        expect(transactionStats.itemsUpdatedTotal, equals(0));
        expect(transactionStats.itemsSkippedTotal, equals(0));
        expect(transactionStats.bandwidthSavedBytes, equals(0));
        expect(transactionStats.apiCallsSavedCount, equals(0));
        expect(transactionStats.syncWindowDays, equals(30));
      });

      test('should have lastIncrementalSync set', () async {
        final List<SyncStatisticsEntity> stats =
            await database.select(database.syncStatistics).get();

        for (final SyncStatisticsEntity stat in stats) {
          expect(stat.lastIncrementalSync, isNotNull);
          expect(stat.lastFullSync, isNotNull);
        }
      });
    });

    group('Database Operations', () {
      test('should update sync statistics', () async {
        // Update statistics for transactions
        await (database.update(database.syncStatistics)..where(
          ($SyncStatisticsTable s) => s.entityType.equals('transaction'),
        )).write(
          const SyncStatisticsEntityCompanion(
            itemsFetchedTotal: Value<int>(100),
            itemsUpdatedTotal: Value<int>(25),
            itemsSkippedTotal: Value<int>(75),
          ),
        );

        // Verify update
        final SyncStatisticsEntity? stats =
            await (database.select(database.syncStatistics)..where(
              ($SyncStatisticsTable s) => s.entityType.equals('transaction'),
            )).getSingleOrNull();

        expect(stats!.itemsFetchedTotal, equals(100));
        expect(stats.itemsUpdatedTotal, equals(25));
        expect(stats.itemsSkippedTotal, equals(75));
      });

      test('should query entities by server_updated_at', () async {
        final DateTime now = DateTime.now();
        final DateTime earlier = now.subtract(const Duration(days: 7));

        // First create accounts (required by FK constraint)
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'src-acc-old',
                name: 'Source Account Old',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: earlier,
                updatedAt: earlier,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'dst-acc-old',
                name: 'Dest Account Old',
                type: 'expense',
                currencyCode: 'USD',
                currentBalance: 0.0,
                createdAt: earlier,
                updatedAt: earlier,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'src-acc-new',
                name: 'Source Account New',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'dst-acc-new',
                name: 'Dest Account New',
                type: 'expense',
                currencyCode: 'USD',
                currentBalance: 0.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Insert multiple transactions with different server_updated_at
        await database
            .into(database.transactions)
            .insert(
              TransactionEntityCompanion.insert(
                id: 'old-tx-1',
                serverId: const Value<String?>('old-server-1'),
                description: 'Old Transaction',
                amount: 100.0,
                date: earlier,
                type: 'withdrawal',
                currencyCode: 'USD',
                sourceAccountId: 'src-acc-old',
                destinationAccountId: 'dst-acc-old',
                createdAt: earlier,
                updatedAt: earlier,
                serverUpdatedAt: Value<DateTime?>(earlier),
              ),
            );

        await database
            .into(database.transactions)
            .insert(
              TransactionEntityCompanion.insert(
                id: 'new-tx-1',
                serverId: const Value<String?>('new-server-1'),
                description: 'New Transaction',
                amount: 200.0,
                date: now,
                type: 'withdrawal',
                currencyCode: 'USD',
                sourceAccountId: 'src-acc-new',
                destinationAccountId: 'dst-acc-new',
                createdAt: now,
                updatedAt: now,
                serverUpdatedAt: Value<DateTime?>(now),
              ),
            );

        // Query transactions updated since a specific time
        final DateTime cutoff = now.subtract(const Duration(days: 3));
        final List<TransactionEntity> recentTransactions =
            await (database.select(database.transactions)..where(
              ($TransactionsTable t) =>
                  t.serverUpdatedAt.isBiggerThanValue(cutoff),
            )).get();

        expect(recentTransactions.length, equals(1));
        expect(recentTransactions.first.serverId, equals('new-server-1'));
      });

      test('should handle null server_updated_at in queries', () async {
        final DateTime now = DateTime.now();

        // First create accounts (required by FK constraint)
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'src-acc-null',
                name: 'Source Account Null',
                type: 'asset',
                currencyCode: 'USD',
                currentBalance: 1000.0,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.accounts)
            .insert(
              AccountEntityCompanion.insert(
                id: 'dst-acc-null',
                name: 'Dest Account Null',
                type: 'expense',
                currencyCode: 'USD',
                currentBalance: 0.0,
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Insert transaction without server_updated_at
        await database
            .into(database.transactions)
            .insert(
              TransactionEntityCompanion.insert(
                id: 'null-tx-1',
                serverId: const Value<String?>('null-server-1'),
                description: 'No Server Timestamp',
                amount: 300.0,
                date: now,
                type: 'withdrawal',
                currencyCode: 'USD',
                sourceAccountId: 'src-acc-null',
                destinationAccountId: 'dst-acc-null',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // Query transactions with null server_updated_at using Drift's isNull()
        final List<TransactionEntity> nullTimestampTransactions =
            await (database.select(database.transactions)..where(
              ($TransactionsTable t) => t.serverUpdatedAt.isNull(),
            )).get();

        expect(
          nullTimestampTransactions.any(
            (TransactionEntity t) => t.serverId == 'null-server-1',
          ),
          isTrue,
        );
      });
    });

    group('Migration Validation', () {
      test('should pass validation with correct schema', () async {
        // The database is already created with the correct schema
        // This just verifies the validation logic doesn't throw

        // Check sync_statistics table exists
        final QueryRow? tableExists =
            await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_statistics'",
                )
                .getSingleOrNull();

        expect(tableExists, isNotNull);

        // Check all entity types have stats
        final List<SyncStatisticsEntity> stats =
            await database.select(database.syncStatistics).get();
        expect(stats.length, greaterThanOrEqualTo(6));

        // Check indexes exist
        final List<QueryRow> indexes =
            await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type='index' "
                  "AND name LIKE 'idx_%_server_updated_at'",
                )
                .get();

        expect(indexes.length, greaterThanOrEqualTo(6));
      });
    });
  });

  group('Database Schema Version', () {
    test('should report schema version 8', () async {
      final AppDatabase database = AppDatabase.forTesting(
        NativeDatabase.memory(),
      );

      expect(database.schemaVersion, equals(8));

      await database.close();
    });
  });

  group('MigrationException', () {
    test('should format message correctly', () {
      final MigrationException exception = MigrationException(
        'Test error message',
      );

      expect(
        exception.toString(),
        equals('MigrationException: Test error message'),
      );
      expect(exception.message, equals('Test error message'));
    });
  });
}
