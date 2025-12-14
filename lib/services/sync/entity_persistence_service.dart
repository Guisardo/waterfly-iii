import 'package:drift/drift.dart';
import 'package:logging/logging.dart';

import '../../database/app_database.dart';
import '../../exceptions/sync_exceptions.dart';

/// Centralized service for entity persistence operations.
///
/// Eliminates duplication between FullSyncService and IncrementalSyncService
/// by providing a single source of truth for entity CRUD operations.
///
/// Supports all entity types:
/// - Transactions
/// - Accounts
/// - Categories
/// - Budgets
/// - Bills
/// - Piggy Banks
class EntityPersistenceService {
  final Logger _logger = Logger('EntityPersistenceService');
  final AppDatabase _database;

  EntityPersistenceService(this._database);

  /// Insert entity into database.
  Future<void> insertEntity(
    String entityType,
    Map<String, dynamic> entity,
  ) async {
    final serverId = entity['id']?.toString();
    final attributes = entity['attributes'] as Map<String, dynamic>?;
    final createdAt = _parseDateTime(entity['created_at']);
    final updatedAt = _parseDateTime(entity['updated_at']);

    if (serverId == null) {
      _logger.warning('Entity missing server ID, skipping: $entity');
      return;
    }

    try {
      switch (entityType) {
        case 'transactions':
          await _database.into(_database.transactions).insert(
                TransactionsCompanion.insert(
                  id: serverId,
                  serverId: Value(serverId),
                  type: attributes?['type'] ?? '',
                  description: attributes?['description'] ?? '',
                  amount: attributes?['amount']?.toString() ?? '0',
                  date: _parseDateTime(attributes?['date']) ?? DateTime.now(),
                  sourceAccountId: Value(attributes?['source_id']?.toString()),
                  destinationAccountId: Value(attributes?['destination_id']?.toString()),
                  categoryId: Value(attributes?['category_id']?.toString()),
                  isSynced: const Value(true),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                ),
              );
          break;

        case 'accounts':
          await _database.into(_database.accounts).insert(
                AccountsCompanion.insert(
                  id: serverId,
                  serverId: Value(serverId),
                  name: attributes?['name'] ?? '',
                  type: attributes?['type'] ?? '',
                  currentBalance: Value(attributes?['current_balance']?.toString()),
                  isSynced: const Value(true),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                ),
              );
          break;

        case 'categories':
          await _database.into(_database.categories).insert(
                CategoriesCompanion.insert(
                  id: serverId,
                  serverId: Value(serverId),
                  name: attributes?['name'] ?? '',
                  isSynced: const Value(true),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                ),
              );
          break;

        case 'budgets':
          await _database.into(_database.budgets).insert(
                BudgetsCompanion.insert(
                  id: serverId,
                  serverId: Value(serverId),
                  name: attributes?['name'] ?? '',
                  isSynced: const Value(true),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                ),
              );
          break;

        case 'bills':
          await _database.into(_database.bills).insert(
                BillsCompanion.insert(
                  id: serverId,
                  serverId: Value(serverId),
                  name: attributes?['name'] ?? '',
                  isSynced: const Value(true),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                ),
              );
          break;

        case 'piggy_banks':
          await _database.into(_database.piggyBanks).insert(
                PiggyBanksCompanion.insert(
                  id: serverId,
                  serverId: Value(serverId),
                  name: attributes?['name'] ?? '',
                  isSynced: const Value(true),
                  createdAt: Value(createdAt),
                  updatedAt: Value(updatedAt),
                ),
              );
          break;

        default:
          throw ValidationError(
            'Unknown entity type: $entityType',
            field: 'entityType',
            rule: 'Must be valid entity type',
          );
      }

      _logger.fine('Inserted $entityType: $serverId');
    } catch (e, stackTrace) {
      _logger.severe('Failed to insert $entityType: $serverId', e, stackTrace);
      rethrow;
    }
  }

  /// Update entity in database.
  Future<void> updateEntity(
    String entityType,
    String serverId,
    Map<String, dynamic> entity,
  ) async {
    final attributes = entity['attributes'] as Map<String, dynamic>?;
    final updatedAt = _parseDateTime(entity['updated_at']) ?? DateTime.now();

    try {
      switch (entityType) {
        case 'transactions':
          await (_database.update(_database.transactions)
                ..where((t) => t.serverId.equals(serverId)))
              .write(
            TransactionsCompanion(
              type: Value(attributes?['type'] ?? ''),
              description: Value(attributes?['description'] ?? ''),
              amount: Value(attributes?['amount']?.toString() ?? '0'),
              date: Value(_parseDateTime(attributes?['date']) ?? DateTime.now()),
              sourceAccountId: Value(attributes?['source_id']?.toString()),
              destinationAccountId: Value(attributes?['destination_id']?.toString()),
              categoryId: Value(attributes?['category_id']?.toString()),
              isSynced: const Value(true),
              updatedAt: Value(updatedAt),
            ),
          );
          break;

        case 'accounts':
          await (_database.update(_database.accounts)
                ..where((a) => a.serverId.equals(serverId)))
              .write(
            AccountsCompanion(
              name: Value(attributes?['name'] ?? ''),
              type: Value(attributes?['type'] ?? ''),
              currentBalance: Value(attributes?['current_balance']?.toString()),
              isSynced: const Value(true),
              updatedAt: Value(updatedAt),
            ),
          );
          break;

        case 'categories':
          await (_database.update(_database.categories)
                ..where((c) => c.serverId.equals(serverId)))
              .write(
            CategoriesCompanion(
              name: Value(attributes?['name'] ?? ''),
              isSynced: const Value(true),
              updatedAt: Value(updatedAt),
            ),
          );
          break;

        case 'budgets':
          await (_database.update(_database.budgets)
                ..where((b) => b.serverId.equals(serverId)))
              .write(
            BudgetsCompanion(
              name: Value(attributes?['name'] ?? ''),
              isSynced: const Value(true),
              updatedAt: Value(updatedAt),
            ),
          );
          break;

        case 'bills':
          await (_database.update(_database.bills)
                ..where((b) => b.serverId.equals(serverId)))
              .write(
            BillsCompanion(
              name: Value(attributes?['name'] ?? ''),
              isSynced: const Value(true),
              updatedAt: Value(updatedAt),
            ),
          );
          break;

        case 'piggy_banks':
          await (_database.update(_database.piggyBanks)
                ..where((p) => p.serverId.equals(serverId)))
              .write(
            PiggyBanksCompanion(
              name: Value(attributes?['name'] ?? ''),
              isSynced: const Value(true),
              updatedAt: Value(updatedAt),
            ),
          );
          break;

        default:
          throw ValidationError(
            'Unknown entity type: $entityType',
            field: 'entityType',
            rule: 'Must be valid entity type',
          );
      }

      _logger.fine('Updated $entityType: $serverId');
    } catch (e, stackTrace) {
      _logger.severe('Failed to update $entityType: $serverId', e, stackTrace);
      rethrow;
    }
  }

  /// Delete entity from database.
  Future<void> deleteEntity(String entityType, String entityId) async {
    try {
      switch (entityType) {
        case 'transactions':
          await (_database.delete(_database.transactions)
                ..where((t) => t.id.equals(entityId)))
              .go();
          break;

        case 'accounts':
          await (_database.delete(_database.accounts)
                ..where((a) => a.id.equals(entityId)))
              .go();
          break;

        case 'categories':
          await (_database.delete(_database.categories)
                ..where((c) => c.id.equals(entityId)))
              .go();
          break;

        case 'budgets':
          await (_database.delete(_database.budgets)
                ..where((b) => b.id.equals(entityId)))
              .go();
          break;

        case 'bills':
          await (_database.delete(_database.bills)
                ..where((b) => b.id.equals(entityId)))
              .go();
          break;

        case 'piggy_banks':
          await (_database.delete(_database.piggyBanks)
                ..where((p) => p.id.equals(entityId)))
              .go();
          break;

        default:
          throw ValidationError(
            'Unknown entity type: $entityType',
            field: 'entityType',
            rule: 'Must be valid entity type',
          );
      }

      _logger.fine('Deleted $entityType: $entityId');
    } catch (e, stackTrace) {
      _logger.severe('Failed to delete $entityType: $entityId', e, stackTrace);
      rethrow;
    }
  }

  /// Get entity from database by server ID.
  Future<Map<String, dynamic>?> getEntityByServerId(
    String entityType,
    String serverId,
  ) async {
    try {
      switch (entityType) {
        case 'transactions':
          final result = await (_database.select(_database.transactions)
                ..where((t) => t.serverId.equals(serverId)))
              .getSingleOrNull();
          return result?.toJson();

        case 'accounts':
          final result = await (_database.select(_database.accounts)
                ..where((a) => a.serverId.equals(serverId)))
              .getSingleOrNull();
          return result?.toJson();

        case 'categories':
          final result = await (_database.select(_database.categories)
                ..where((c) => c.serverId.equals(serverId)))
              .getSingleOrNull();
          return result?.toJson();

        case 'budgets':
          final result = await (_database.select(_database.budgets)
                ..where((b) => b.serverId.equals(serverId)))
              .getSingleOrNull();
          return result?.toJson();

        case 'bills':
          final result = await (_database.select(_database.bills)
                ..where((b) => b.serverId.equals(serverId)))
              .getSingleOrNull();
          return result?.toJson();

        case 'piggy_banks':
          final result = await (_database.select(_database.piggyBanks)
                ..where((p) => p.serverId.equals(serverId)))
              .getSingleOrNull();
          return result?.toJson();

        default:
          return null;
      }
    } catch (e, stackTrace) {
      _logger.warning('Failed to get $entityType: $serverId', e, stackTrace);
      return null;
    }
  }

  /// Parse datetime from various formats.
  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        _logger.warning('Failed to parse datetime: $value');
        return null;
      }
    }
    return null;
  }
}
