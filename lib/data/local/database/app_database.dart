import 'dart:io';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/local/database/tables/accounts.dart';
import 'package:waterflyiii/data/local/database/tables/categories.dart';
import 'package:waterflyiii/data/local/database/tables/tags.dart';
import 'package:waterflyiii/data/local/database/tables/bills.dart';
import 'package:waterflyiii/data/local/database/tables/budget_limits.dart';
import 'package:waterflyiii/data/local/database/tables/budgets.dart';
import 'package:waterflyiii/data/local/database/tables/currencies.dart';
import 'package:waterflyiii/data/local/database/tables/piggy_banks.dart';
import 'package:waterflyiii/data/local/database/tables/attachments.dart';
import 'package:waterflyiii/data/local/database/tables/insights.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/local/database/tables/sync_conflicts.dart';

class AppDatabase {
  static Isar? _isar;

  static Future<Isar> get instance async {
    if (_isar != null) {
      return _isar!;
    }

    final Directory dbFolder = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      [
        TransactionsSchema,
        AccountsSchema,
        CategoriesSchema,
        TagsSchema,
        BillsSchema,
        BudgetsSchema,
        BudgetLimitsSchema,
        CurrenciesSchema,
        PiggyBanksSchema,
        AttachmentsSchema,
        InsightsSchema,
        SyncMetadataSchema,
        PendingChangesSchema,
        SyncConflictsSchema,
      ],
      directory: dbFolder.path,
      name: 'waterflyiii',
    );

    return _isar!;
  }

  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}
