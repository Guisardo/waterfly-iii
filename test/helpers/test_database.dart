import 'package:isar_community/isar.dart';
import 'mock_isar.dart' show MockIsar;

/// Helper class for setting up test Isar database instances
/// Uses MockIsar to avoid requiring native libraries
class TestDatabase {
  static Isar? _isar;

  /// Get or create a test Isar instance (uses MockIsar)
  static Future<Isar> get instance async {
    if (_isar != null) {
      return _isar!;
    }

    _isar = MockIsar();
    return _isar!;
  }

  /// Close and clean up the test database
  static Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }

  /// Clear all data from the test database
  static Future<void> clear() async {
    if (_isar == null) {
      return;
    }

    final MockIsar mockIsar = _isar! as MockIsar;
    await mockIsar.writeTxn(() async {
      await mockIsar.transactions.clear();
      await mockIsar.accounts.clear();
      await mockIsar.categories.clear();
      await mockIsar.tags.clear();
      await mockIsar.bills.clear();
      await mockIsar.budgets.clear();
      await mockIsar.budgetLimits.clear();
      await mockIsar.currencies.clear();
      await mockIsar.piggyBanks.clear();
      await mockIsar.attachments.clear();
      await mockIsar.insights.clear();
      await mockIsar.syncMetadatas.clear();
      await mockIsar.pendingChanges.clear();
      await mockIsar.syncConflicts.clear();
    });
  }
}

