import 'package:logging/logging.dart';
import 'package:drift/drift.dart';
import '../../data/local/database/app_database.dart';

/// Adapter for AppDatabase to work with sync manager.
class DatabaseAdapter {
  final Logger _logger = Logger('DatabaseAdapter');
  final AppDatabase database;

  DatabaseAdapter(this.database);

  /// Insert or update a transaction
  Future<void> upsertTransaction(Map<String, dynamic> data) async {
    final id = data['id'] as String;
    
    final entity = TransactionsCompanion(
      id: Value(id),
      serverId: Value(data['server_id'] as String?),
      type: Value(data['type'] as String? ?? 'withdrawal'),
      date: Value(DateTime.parse(data['date'] as String? ?? DateTime.now().toIso8601String())),
      amount: Value((data['amount'] as num?)?.toDouble() ?? 0.0),
      description: Value(data['description'] as String? ?? ''),
      sourceAccountId: Value(data['source_account_id'] as String? ?? ''),
      destinationAccountId: Value(data['destination_account_id'] as String? ?? ''),
      categoryId: Value(data['category_id'] as String?),
      budgetId: Value(data['budget_id'] as String?),
      currencyCode: Value(data['currency_code'] as String? ?? 'USD'),
      foreignAmount: Value((data['foreign_amount'] as num?)?.toDouble()),
      foreignCurrencyCode: Value(data['foreign_currency_code'] as String?),
      notes: Value(data['notes'] as String?),
      tags: Value(data['tags'] as String? ?? '[]'),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
      isSynced: const Value(true),
      syncStatus: const Value('synced'),
    );

    await database.into(database.transactions).insertOnConflictUpdate(entity);
    _logger.fine('Upserted transaction: $id');
  }

  /// Get a transaction by ID
  Future<Map<String, dynamic>?> getTransaction(String id) async {
    final query = database.select(database.transactions)
      ..where((t) => t.id.equals(id));
    
    final result = await query.getSingleOrNull();
    if (result == null) return null;

    return {
      'id': result.id,
      'server_id': result.serverId,
      'type': result.type,
      'date': result.date.toIso8601String(),
      'amount': result.amount,
      'description': result.description,
      'source_account_id': result.sourceAccountId,
      'destination_account_id': result.destinationAccountId,
      'category_id': result.categoryId,
      'is_synced': result.isSynced,
    };
  }

  /// Delete a transaction
  Future<void> deleteTransaction(String id) async {
    await (database.delete(database.transactions)
      ..where((t) => t.id.equals(id))).go();
    _logger.fine('Deleted transaction: $id');
  }

  /// Get all transactions
  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final results = await database.select(database.transactions).get();
    
    return results.map((t) => {
      'id': t.id,
      'server_id': t.serverId,
      'amount': t.amount,
      'description': t.description,
    }).toList();
  }
}
