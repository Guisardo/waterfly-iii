import 'dart:async';
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
  static Completer<Isar>? _completer;

  static Future<Isar> get instance async {
    if (_completer != null) {
      return _completer!.future;
    }
    _completer = Completer<Isar>();
    try {
      final Directory dbFolder = await getApplicationDocumentsDirectory();
      final Isar isar = await Isar.open(
        <CollectionSchema<dynamic>>[
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
      _completer!.complete(isar);
    } catch (e) {
      _completer = null;
      rethrow;
    }
    return _completer!.future;
  }

  static Future<void> close() async {
    if (_completer == null) {
      return;
    }
    final Isar isar = await _completer!.future;
    await isar.close();
    _completer = null;
  }
}
