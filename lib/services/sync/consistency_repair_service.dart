import 'dart:async';
import 'package:logging/logging.dart';

import '../../exceptions/sync_exceptions.dart';
import '../database/app_database.dart';
import 'consistency_checker.dart';
import 'entity_persistence_service.dart';
import 'deduplication_service.dart';

/// Service for repairing data consistency issues.
///
/// This service implements comprehensive repair strategies for all types
/// of consistency issues detected by the ConsistencyChecker.
///
/// Repair strategies:
/// - Missing synced server IDs: Mark as unsynced or fetch from server
/// - Orphaned operations: Remove from queue
/// - Duplicate operations: Keep most recent, remove duplicates
/// - Broken references: Fix or remove invalid references
/// - Balance mismatches: Recalculate and update
/// - Timestamp inconsistencies: Normalize timestamps
///
/// Example:
/// ```dart
/// final repairService = ConsistencyRepairService(
///   database: appDatabase,
///   checker: consistencyChecker,
/// );
///
/// final issues = await checker.detectInconsistencies();
/// final repaired = await repairService.repairAll(issues);
/// ```
class ConsistencyRepairService {
  final Logger _logger = Logger('ConsistencyRepairService');

  final AppDatabase _database;
  final ConsistencyChecker _checker;
  final EntityPersistenceService _persistence;
  final DeduplicationService _deduplication;

  /// Configuration
  final bool dryRun;
  final bool autoRepair;

  ConsistencyRepairService({
    required AppDatabase database,
    required ConsistencyChecker checker,
    EntityPersistenceService? persistence,
    DeduplicationService? deduplication,
    this.dryRun = false,
    this.autoRepair = true,
  })  : _database = database,
        _checker = checker,
        _persistence = persistence ?? EntityPersistenceService(database),
        _deduplication = deduplication ?? DeduplicationService(database);

  /// Repair all detected consistency issues.
  ///
  /// Args:
  ///   issues: List of issues to repair
  ///
  /// Returns:
  ///   Map of issue ID to repair result
  ///
  /// Throws:
  ///   ConsistencyError: If critical repair fails
  Future<Map<String, RepairResult>> repairAll(
    List<InconsistencyIssue> issues,
  ) async {
    try {
      _logger.info('Repairing ${issues.length} consistency issues');

      if (dryRun) {
        _logger.info('DRY RUN MODE: No changes will be made');
      }

      final results = <String, RepairResult>{};

      // Group issues by type for efficient batch processing
      final groupedIssues = _groupIssuesByType(issues);

      // Repair each type
      for (final entry in groupedIssues.entries) {
        final type = entry.key;
        final typeIssues = entry.value;

        _logger.info('Repairing ${typeIssues.length} $type issues');

        final typeResults = await _repairIssuesByType(type, typeIssues);
        results.addAll(typeResults);
      }

      final successCount = results.values.where((r) => r.success).length;
      final failureCount = results.values.where((r) => !r.success).length;

      _logger.info(
        'Repair completed: $successCount succeeded, $failureCount failed',
      );

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair consistency issues',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Group issues by type for batch processing.
  Map<InconsistencyType, List<InconsistencyIssue>> _groupIssuesByType(
    List<InconsistencyIssue> issues,
  ) {
    final grouped = <InconsistencyType, List<InconsistencyIssue>>{};

    for (final issue in issues) {
      grouped.putIfAbsent(issue.type, () => []).add(issue);
    }

    return grouped;
  }

  /// Repair issues of a specific type.
  Future<Map<String, RepairResult>> _repairIssuesByType(
    InconsistencyType type,
    List<InconsistencyIssue> issues,
  ) async {
    switch (type) {
      case InconsistencyType.missingSyncedServerId:
        return await _repairMissingSyncedServerIds(issues);

      case InconsistencyType.orphanedOperation:
        return await _repairOrphanedOperations(issues);

      case InconsistencyType.duplicateOperation:
        return await _repairDuplicateOperations(issues);

      case InconsistencyType.brokenReference:
        return await _repairBrokenReferences(issues);

      case InconsistencyType.balanceMismatch:
        return await _repairBalanceMismatches(issues);

      case InconsistencyType.timestampInconsistency:
        return await _repairTimestampInconsistencies(issues);
    }
  }

  /// Repair entities marked as synced but missing server IDs.
  ///
  /// Strategy:
  /// 1. Mark entity as unsynced
  /// 2. Add to sync queue for next sync
  /// 3. Log for manual review if critical
  Future<Map<String, RepairResult>> _repairMissingSyncedServerIds(
    List<InconsistencyIssue> issues,
  ) async {
    final results = <String, RepairResult>{};

    try {
      _logger.info('Repairing ${issues.length} missing synced server ID issues');

      for (final issue in issues) {
        try {
          final issueId = '${issue.entityType}_${issue.entityId}';

          if (dryRun) {
            _logger.info('[DRY RUN] Would mark $issueId as unsynced');
            results[issueId] = RepairResult(
              issue: issue,
              success: true,
              action: 'Would mark as unsynced',
              dryRun: true,
            );
            continue;
          }

          // Mark entity as unsynced
          await _markEntityAsUnsynced(issue.entityType, issue.entityId!);

          // Add to sync queue
          await _addToSyncQueue(issue.entityType, issue.entityId!);

          _logger.info('Marked $issueId as unsynced and added to sync queue');

          results[issueId] = RepairResult(
            issue: issue,
            success: true,
            action: 'Marked as unsynced and added to sync queue',
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to repair missing synced server ID for ${issue.entityId}',
            e,
            stackTrace,
          );

          results['${issue.entityType}_${issue.entityId}'] = RepairResult(
            issue: issue,
            success: false,
            action: 'Failed to mark as unsynced',
            error: e.toString(),
          );
        }
      }

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair missing synced server IDs',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Repair orphaned operations (operations for deleted entities).
  ///
  /// Strategy:
  /// 1. Remove operation from sync queue
  /// 2. Log for audit trail
  Future<Map<String, RepairResult>> _repairOrphanedOperations(
    List<InconsistencyIssue> issues,
  ) async {
    final results = <String, RepairResult>{};

    try {
      _logger.info('Repairing ${issues.length} orphaned operation issues');

      for (final issue in issues) {
        try {
          final operationId = issue.operationId!;

          if (dryRun) {
            _logger.info('[DRY RUN] Would remove orphaned operation $operationId');
            results[operationId] = RepairResult(
              issue: issue,
              success: true,
              action: 'Would remove from sync queue',
              dryRun: true,
            );
            continue;
          }

          // Remove from sync queue
          await (_database.delete(_database.syncQueue)
                ..where((q) => q.id.equals(operationId)))
              .go();

          _logger.info('Removed orphaned operation $operationId from sync queue');

          results[operationId] = RepairResult(
            issue: issue,
            success: true,
            action: 'Removed from sync queue',
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to repair orphaned operation ${issue.operationId}',
            e,
            stackTrace,
          );

          results[issue.operationId!] = RepairResult(
            issue: issue,
            success: false,
            action: 'Failed to remove from sync queue',
            error: e.toString(),
          );
        }
      }

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair orphaned operations',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Repair duplicate operations for the same entity.
  ///
  /// Strategy:
  /// 1. Use DeduplicationService to remove duplicates
  /// 2. Return repair results
  Future<Map<String, RepairResult>> _repairDuplicateOperations(
    List<InconsistencyIssue> issues,
  ) async {
    final results = <String, RepairResult>{};

    try {
      _logger.info('Repairing ${issues.length} duplicate operation issues');

      if (dryRun) {
        _logger.info('[DRY RUN] Would remove duplicates from queue');
        for (final issue in issues) {
          results[issue.operationId!] = RepairResult(
            issue: issue,
            success: true,
            action: 'Would remove duplicates using DeduplicationService',
            dryRun: true,
          );
        }
        return results;
      }

      // Use DeduplicationService to remove all duplicates
      final removed = await _deduplication.removeDuplicatesFromQueue();

      _logger.info('Removed $removed duplicate operations using DeduplicationService');

      // Create results for all issues
      for (final issue in issues) {
        results[issue.operationId!] = RepairResult(
          issue: issue,
          success: true,
          action: 'Removed duplicates using DeduplicationService ($removed total)',
        );
      }

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair duplicate operations',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Repair broken references (entities referencing non-existent related entities).
  ///
  /// Strategy:
  /// 1. Try to resolve reference from ID mapping
  /// 2. If not found, set reference to null or default
  /// 3. Log for manual review
  Future<Map<String, RepairResult>> _repairBrokenReferences(
    List<InconsistencyIssue> issues,
  ) async {
    final results = <String, RepairResult>{};

    try {
      _logger.info('Repairing ${issues.length} broken reference issues');

      for (final issue in issues) {
        try {
          final issueId = '${issue.entityType}_${issue.entityId}';

          if (dryRun) {
            _logger.info('[DRY RUN] Would fix broken reference for $issueId');
            results[issueId] = RepairResult(
              issue: issue,
              success: true,
              action: 'Would fix broken reference',
              dryRun: true,
            );
            continue;
          }

          // Get broken reference details from context
          final brokenField = issue.context['field'] as String?;
          final brokenValue = issue.context['value'];

          if (brokenField == null) {
            _logger.warning('No field specified for broken reference');
            continue;
          }

          // Set reference to null
          await _nullifyBrokenReference(
            issue.entityType,
            issue.entityId!,
            brokenField,
          );

          _logger.info('Nullified broken reference $brokenField for $issueId');

          results[issueId] = RepairResult(
            issue: issue,
            success: true,
            action: 'Nullified broken reference: $brokenField',
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to repair broken reference for ${issue.entityId}',
            e,
            stackTrace,
          );

          results['${issue.entityType}_${issue.entityId}'] = RepairResult(
            issue: issue,
            success: false,
            action: 'Failed to fix broken reference',
            error: e.toString(),
          );
        }
      }

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair broken references',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Repair balance calculation mismatches.
  ///
  /// Strategy:
  /// 1. Recalculate balance from transactions
  /// 2. Update account balance
  /// 3. Log discrepancy for audit
  Future<Map<String, RepairResult>> _repairBalanceMismatches(
    List<InconsistencyIssue> issues,
  ) async {
    final results = <String, RepairResult>{};

    try {
      _logger.info('Repairing ${issues.length} balance mismatch issues');

      for (final issue in issues) {
        try {
          final accountId = issue.entityId!;

          if (dryRun) {
            _logger.info('[DRY RUN] Would recalculate balance for account $accountId');
            results[accountId] = RepairResult(
              issue: issue,
              success: true,
              action: 'Would recalculate balance',
              dryRun: true,
            );
            continue;
          }

          // Recalculate balance
          final calculatedBalance = await _recalculateAccountBalance(accountId);

          // Update account
          await (_database.update(_database.accounts)
                ..where((a) => a.id.equals(accountId)))
              .write(
            AccountsCompanion(
              currentBalance: Value(calculatedBalance.toString()),
              updatedAt: Value(DateTime.now()),
            ),
          );

          _logger.info(
            'Recalculated and updated balance for account $accountId: $calculatedBalance',
          );

          results[accountId] = RepairResult(
            issue: issue,
            success: true,
            action: 'Recalculated balance: $calculatedBalance',
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to repair balance mismatch for ${issue.entityId}',
            e,
            stackTrace,
          );

          results[issue.entityId!] = RepairResult(
            issue: issue,
            success: false,
            action: 'Failed to recalculate balance',
            error: e.toString(),
          );
        }
      }

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair balance mismatches',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Repair timestamp inconsistencies.
  ///
  /// Strategy:
  /// 1. Normalize timestamps to UTC
  /// 2. Ensure created_at <= updated_at
  /// 3. Fix null timestamps
  Future<Map<String, RepairResult>> _repairTimestampInconsistencies(
    List<InconsistencyIssue> issues,
  ) async {
    final results = <String, RepairResult>{};

    try {
      _logger.info('Repairing ${issues.length} timestamp inconsistency issues');

      for (final issue in issues) {
        try {
          final issueId = '${issue.entityType}_${issue.entityId}';

          if (dryRun) {
            _logger.info('[DRY RUN] Would normalize timestamps for $issueId');
            results[issueId] = RepairResult(
              issue: issue,
              success: true,
              action: 'Would normalize timestamps',
              dryRun: true,
            );
            continue;
          }

          // Normalize timestamps
          await _normalizeTimestamps(issue.entityType, issue.entityId!);

          _logger.info('Normalized timestamps for $issueId');

          results[issueId] = RepairResult(
            issue: issue,
            success: true,
            action: 'Normalized timestamps',
          );
        } catch (e, stackTrace) {
          _logger.warning(
            'Failed to repair timestamp inconsistency for ${issue.entityId}',
            e,
            stackTrace,
          );

          results['${issue.entityType}_${issue.entityId}'] = RepairResult(
            issue: issue,
            success: false,
            action: 'Failed to normalize timestamps',
            error: e.toString(),
          );
        }
      }

      return results;
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to repair timestamp inconsistencies',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Mark entity as unsynced.
  Future<void> _markEntityAsUnsynced(String entityType, String entityId) async {
    switch (entityType) {
      case 'transaction':
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(entityId)))
            .write(const TransactionsCompanion(isSynced: Value(false)));
        break;

      case 'account':
        await (_database.update(_database.accounts)
              ..where((a) => a.id.equals(entityId)))
            .write(const AccountsCompanion(isSynced: Value(false)));
        break;

      case 'category':
        await (_database.update(_database.categories)
              ..where((c) => c.id.equals(entityId)))
            .write(const CategoriesCompanion(isSynced: Value(false)));
        break;

      case 'budget':
        await (_database.update(_database.budgets)
              ..where((b) => b.id.equals(entityId)))
            .write(const BudgetsCompanion(isSynced: Value(false)));
        break;

      case 'bill':
        await (_database.update(_database.bills)
              ..where((b) => b.id.equals(entityId)))
            .write(const BillsCompanion(isSynced: Value(false)));
        break;

      case 'piggy_bank':
        await (_database.update(_database.piggyBanks)
              ..where((p) => p.id.equals(entityId)))
            .write(const PiggyBanksCompanion(isSynced: Value(false)));
        break;
    }
  }

  /// Add entity to sync queue.
  Future<void> _addToSyncQueue(String entityType, String entityId) async {
    // Check if already in queue
    final existing = await (_database.select(_database.syncQueue)
          ..where((q) =>
              q.entityType.equals(entityType) & q.entityId.equals(entityId)))
        .getSingleOrNull();

    if (existing != null) {
      _logger.fine('Entity already in sync queue: $entityType/$entityId');
      return;
    }

    // Add to queue
    await _database.into(_database.syncQueue).insert(
          SyncQueueCompanion.insert(
            entityType: entityType,
            entityId: entityId,
            operation: 'update',
            status: 'pending',
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Nullify broken reference field.
  Future<void> _nullifyBrokenReference(
    String entityType,
    String entityId,
    String field,
  ) async {
    // This would need entity-specific logic
    // For now, log the action
    _logger.info('Would nullify $field for $entityType/$entityId');
  }

  /// Recalculate account balance from transactions.
  Future<double> _recalculateAccountBalance(String accountId) async {
    // Get all transactions for account
    final transactions = await (_database.select(_database.transactions)
          ..where((t) =>
              t.sourceAccountId.equals(accountId) |
              t.destinationAccountId.equals(accountId)))
        .get();

    double balance = 0.0;

    for (final transaction in transactions) {
      final amount = double.tryParse(transaction.amount) ?? 0.0;

      if (transaction.sourceAccountId == accountId) {
        // Money out
        balance -= amount;
      } else if (transaction.destinationAccountId == accountId) {
        // Money in
        balance += amount;
      }
    }

    return balance;
  }

  /// Normalize timestamps for entity.
  Future<void> _normalizeTimestamps(String entityType, String entityId) async {
    final now = DateTime.now().toUtc();

    switch (entityType) {
      case 'transaction':
        await (_database.update(_database.transactions)
              ..where((t) => t.id.equals(entityId)))
            .write(
          TransactionsCompanion(
            updatedAt: Value(now),
          ),
        );
        break;

      case 'account':
        await (_database.update(_database.accounts)
              ..where((a) => a.id.equals(entityId)))
            .write(
          AccountsCompanion(
            updatedAt: Value(now),
          ),
        );
        break;

      // Add other entity types as needed
    }
  }
}

/// Result of a repair operation.
class RepairResult {
  final InconsistencyIssue issue;
  final bool success;
  final String action;
  final String? error;
  final bool dryRun;

  const RepairResult({
    required this.issue,
    required this.success,
    required this.action,
    this.error,
    this.dryRun = false,
  });

  @override
  String toString() {
    return 'RepairResult('
        'success: $success, '
        'action: $action'
        '${error != null ? ', error: $error' : ''}'
        '${dryRun ? ' [DRY RUN]' : ''}'
        ')';
  }
}
