import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/exceptions/offline_exceptions.dart';

/// Types of consistency issues that can be detected.
enum InconsistencyType {
  /// Entity marked as synced but has no server ID
  missingSyncedServerId,

  /// Operation in queue for deleted entity
  orphanedOperation,

  /// Duplicate operations for same entity
  duplicateOperation,

  /// Entity references non-existent related entity
  brokenReference,

  /// Balance calculation mismatch
  balanceMismatch,

  /// Timestamp inconsistency
  timestampInconsistency,
}

/// Severity of consistency issues.
enum InconsistencySeverity {
  /// Low severity, can be auto-fixed
  low,

  /// Medium severity, should be reviewed
  medium,

  /// High severity, requires immediate attention
  high,

  /// Critical severity, data corruption risk
  critical,
}

/// Represents a detected consistency issue.
class InconsistencyIssue {
  /// Type of inconsistency
  final InconsistencyType type;

  /// Entity type affected
  final String entityType;

  /// Entity ID affected
  final String? entityId;

  /// Operation ID if applicable
  final String? operationId;

  /// Description of the issue
  final String description;

  /// Suggested fix
  final String suggestedFix;

  /// Severity level
  final InconsistencySeverity severity;

  /// Additional context data
  final Map<String, dynamic> context;

  const InconsistencyIssue({
    required this.type,
    required this.entityType,
    this.entityId,
    this.operationId,
    required this.description,
    required this.suggestedFix,
    required this.severity,
    this.context = const <String, dynamic>{},
  });

  @override
  String toString() {
    return 'InconsistencyIssue('
        'type: $type, '
        'entity: $entityType${entityId != null ? '/$entityId' : ''}, '
        'severity: $severity, '
        'description: $description'
        ')';
  }
}

/// Result of a repair operation.
class RepairResult {
  /// Number of issues repaired
  final int repaired;

  /// Number of issues that couldn't be repaired
  final int failed;

  /// List of errors encountered
  final List<String> errors;

  /// Detailed results by issue type
  final Map<InconsistencyType, int> byType;

  const RepairResult({
    required this.repaired,
    required this.failed,
    required this.errors,
    required this.byType,
  });

  /// Total issues processed
  int get total => repaired + failed;

  /// Success rate
  double get successRate => total == 0 ? 1.0 : repaired / total;

  @override
  String toString() {
    return 'RepairResult(repaired: $repaired, failed: $failed, total: $total, successRate: ${(successRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Comprehensive service for checking and repairing data consistency.
///
/// Consolidates consistency_checker.dart and consistency_repair_service.dart
/// to provide unified consistency management.
///
/// Features:
/// - Detects 6 types of consistency issues
/// - Repairs issues automatically or with dry-run mode
/// - Provides detailed statistics and reporting
/// - Transaction-based repairs for data integrity
/// - Comprehensive error handling and logging
///
/// Example:
/// ```dart
/// final service = ConsistencyService(database: database);
///
/// // Check for issues
/// final issues = await service.check();
/// print('Found ${issues.length} issues');
///
/// // Repair all issues
/// final result = await service.repairAll();
/// print('Repaired ${result.repaired} issues');
///
/// // Dry run to see what would be repaired
/// final dryRunResult = await service.repairAll(dryRun: true);
/// ```
class ConsistencyService {
  final Logger _logger = Logger('ConsistencyService');
  final AppDatabase _database;

  ConsistencyService({required AppDatabase database}) : _database = database;

  /// Check for all types of consistency issues.
  ///
  /// Returns list of detected issues. Does not modify data.
  Future<List<InconsistencyIssue>> check({
    List<InconsistencyType>? types,
  }) async {
    _logger.info('Checking consistency');
    
    final List<InconsistencyType> typesToCheck = types ?? InconsistencyType.values;
    final List<InconsistencyIssue> allIssues = <InconsistencyIssue>[];

    for (final InconsistencyType type in typesToCheck) {
      try {
        final List<InconsistencyIssue> issues = await _checkType(type);
        allIssues.addAll(issues);
        _logger.fine('Found ${issues.length} ${type.name} issues');
      } catch (e, stackTrace) {
        _logger.severe('Failed to check ${type.name}', e, stackTrace);
      }
    }

    _logger.info('Found ${allIssues.length} total consistency issues');
    return allIssues;
  }

  /// Repair all detected consistency issues.
  ///
  /// If [dryRun] is true, only reports what would be repaired without making changes.
  /// Returns [RepairResult] with statistics about the repair operation.
  Future<RepairResult> repairAll({
    bool dryRun = false,
    List<InconsistencyType>? types,
  }) async {
    _logger.info('Starting consistency repair${dryRun ? ' (dry run)' : ''}');
    
    final List<InconsistencyType> typesToRepair = types ?? InconsistencyType.values;
    int totalRepaired = 0;
    int totalFailed = 0;
    final List<String> errors = <String>[];
    final Map<InconsistencyType, int> byType = <InconsistencyType, int>{};

    for (final InconsistencyType type in typesToRepair) {
      try {
        final int repaired = await _repairType(type, dryRun: dryRun);
        totalRepaired += repaired;
        byType[type] = repaired;
        _logger.info('Repaired $repaired ${type.name} issues');
      } catch (e, stackTrace) {
        _logger.severe('Failed to repair ${type.name}', e, stackTrace);
        errors.add('${type.name}: ${e.toString()}');
        totalFailed++;
      }
    }

    final RepairResult result = RepairResult(
      repaired: totalRepaired,
      failed: totalFailed,
      errors: errors,
      byType: byType,
    );

    _logger.info('Repair complete: $result');
    return result;
  }

  /// Repair specific type of consistency issue.
  Future<int> repair(
    InconsistencyType type, {
    bool dryRun = false,
  }) async {
    _logger.info('Repairing ${type.name}${dryRun ? ' (dry run)' : ''}');
    return await _repairType(type, dryRun: dryRun);
  }

  /// Check for specific type of consistency issue.
  Future<List<InconsistencyIssue>> _checkType(InconsistencyType type) async {
    switch (type) {
      case InconsistencyType.missingSyncedServerId:
        return await _checkMissingSyncedServerIds();
      case InconsistencyType.orphanedOperation:
        return await _checkOrphanedOperations();
      case InconsistencyType.duplicateOperation:
        return await _checkDuplicateOperations();
      case InconsistencyType.brokenReference:
        return await _checkBrokenReferences();
      case InconsistencyType.balanceMismatch:
        return await _checkBalanceMismatches();
      case InconsistencyType.timestampInconsistency:
        return await _checkTimestampInconsistencies();
    }
  }

  /// Repair specific type of consistency issue.
  Future<int> _repairType(InconsistencyType type, {required bool dryRun}) async {
    switch (type) {
      case InconsistencyType.missingSyncedServerId:
        return await _repairMissingSyncedServerIds(dryRun: dryRun);
      case InconsistencyType.orphanedOperation:
        return await _repairOrphanedOperations(dryRun: dryRun);
      case InconsistencyType.duplicateOperation:
        return await _repairDuplicateOperations(dryRun: dryRun);
      case InconsistencyType.brokenReference:
        return await _repairBrokenReferences(dryRun: dryRun);
      case InconsistencyType.balanceMismatch:
        return await _repairBalanceMismatches(dryRun: dryRun);
      case InconsistencyType.timestampInconsistency:
        return await _repairTimestampInconsistencies(dryRun: dryRun);
    }
  }

  // ==================== CHECK METHODS ====================

  /// Check for entities marked as synced but missing server IDs.
  Future<List<InconsistencyIssue>> _checkMissingSyncedServerIds() async {
    final List<InconsistencyIssue> issues = <InconsistencyIssue>[];

    try {
      // Check transactions
      final List<TransactionEntity> transactions = await (_database.select(_database.transactions)
            ..where(($TransactionsTable t) => t.isSynced.equals(true) & t.serverId.isNull()))
          .get();

      for (final TransactionEntity t in transactions) {
        issues.add(InconsistencyIssue(
          type: InconsistencyType.missingSyncedServerId,
          entityType: 'transaction',
          entityId: t.id,
          description: 'Transaction marked as synced but has no server ID',
          suggestedFix: 'Mark as not synced or fetch server ID',
          severity: InconsistencySeverity.medium,
          context: {'local_id': t.id},
        ));
      }

      // Check accounts
      final List<AccountEntity> accounts = await (_database.select(_database.accounts)
            ..where(($AccountsTable a) => a.isSynced.equals(true) & a.serverId.isNull()))
          .get();

      for (final AccountEntity a in accounts) {
        issues.add(InconsistencyIssue(
          type: InconsistencyType.missingSyncedServerId,
          entityType: 'account',
          entityId: a.id,
          description: 'Account marked as synced but has no server ID',
          suggestedFix: 'Mark as not synced or fetch server ID',
          severity: InconsistencySeverity.medium,
          context: {'local_id': a.id},
        ));
      }

      // Check other entity types similarly
      // Categories, budgets, bills, piggy banks
    } catch (e, stackTrace) {
      _logger.severe('Failed to check missing synced server IDs', e, stackTrace);
    }

    return issues;
  }

  /// Check for orphaned operations (operations for deleted entities).
  Future<List<InconsistencyIssue>> _checkOrphanedOperations() async {
    final List<InconsistencyIssue> issues = <InconsistencyIssue>[];

    try {
      final List<SyncQueueEntity> operations = await _database.select(_database.syncQueue).get();

      for (final SyncQueueEntity op in operations) {
        bool entityExists = false;

        // Check if entity still exists based on entity type
        switch (op.entityType) {
          case 'transaction':
            final TransactionEntity? entity = await (_database.select(_database.transactions)
                  ..where(($TransactionsTable t) => t.id.equals(op.entityId)))
                .getSingleOrNull();
            entityExists = entity != null;
            break;
          case 'account':
            final AccountEntity? entity = await (_database.select(_database.accounts)
                  ..where(($AccountsTable a) => a.id.equals(op.entityId)))
                .getSingleOrNull();
            entityExists = entity != null;
            break;
          // Add other entity types
        }

        if (!entityExists) {
          issues.add(InconsistencyIssue(
            type: InconsistencyType.orphanedOperation,
            entityType: op.entityType,
            entityId: op.entityId,
            operationId: op.id,
            description: 'Operation exists for deleted ${op.entityType}',
            suggestedFix: 'Remove orphaned operation',
            severity: InconsistencySeverity.low,
            context: {'operation_id': op.id, 'operation': op.operation},
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to check orphaned operations', e, stackTrace);
    }

    return issues;
  }

  /// Check for duplicate operations in sync queue.
  Future<List<InconsistencyIssue>> _checkDuplicateOperations() async {
    final List<InconsistencyIssue> issues = <InconsistencyIssue>[];

    try {
      final List<SyncQueueEntity> operations = await _database.select(_database.syncQueue).get();
      final Map<String, List<SyncQueueEntity>> grouped = <String, List<SyncQueueEntity>>{};

      // Group by entity type + entity ID + operation
      for (final SyncQueueEntity op in operations) {
        final String key = '${op.entityType}:${op.entityId}:${op.operation}';
        grouped.putIfAbsent(key, () => <SyncQueueEntity>[]);
        grouped[key]!.add(op);
      }

      // Find duplicates
      for (final MapEntry<String, List<SyncQueueEntity>> entry in grouped.entries) {
        if (entry.value.length > 1) {
          final SyncQueueEntity first = entry.value.first;
          issues.add(InconsistencyIssue(
            type: InconsistencyType.duplicateOperation,
            entityType: first.entityType,
            entityId: first.entityId,
            description: '${entry.value.length} duplicate operations for same entity',
            suggestedFix: 'Keep most recent, remove others',
            severity: InconsistencySeverity.low,
            context: {
              'count': entry.value.length,
              'operation_ids': entry.value.map((SyncQueueEntity o) => o.id).toList(),
            },
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to check duplicate operations', e, stackTrace);
    }

    return issues;
  }

  /// Check for broken references between entities.
  Future<List<InconsistencyIssue>> _checkBrokenReferences() async {
    final List<InconsistencyIssue> issues = <InconsistencyIssue>[];

    try {
      // Check transactions with invalid account references
      final List<TransactionEntity> transactions = await _database.select(_database.transactions).get();

      for (final TransactionEntity t in transactions) {
        // Check source account
        if (t.sourceAccountId.isNotEmpty) {
          final AccountEntity? sourceAccount = await (_database.select(_database.accounts)
                ..where(($AccountsTable a) => a.id.equals(t.sourceAccountId)))
              .getSingleOrNull();

          if (sourceAccount == null) {
            issues.add(InconsistencyIssue(
              type: InconsistencyType.brokenReference,
              entityType: 'transaction',
              entityId: t.id,
              description: 'Transaction references non-existent source account',
              suggestedFix: 'Remove transaction or fix account reference',
              severity: InconsistencySeverity.high,
              context: {'source_account_id': t.sourceAccountId},
            ));
          }
        }

        // Check destination account
        if (t.destinationAccountId.isNotEmpty) {
          final AccountEntity? destAccount = await (_database.select(_database.accounts)
                ..where(($AccountsTable a) => a.id.equals(t.destinationAccountId)))
              .getSingleOrNull();

          if (destAccount == null) {
            issues.add(InconsistencyIssue(
              type: InconsistencyType.brokenReference,
              entityType: 'transaction',
              entityId: t.id,
              description: 'Transaction references non-existent destination account',
              suggestedFix: 'Remove transaction or fix account reference',
              severity: InconsistencySeverity.high,
              context: {'destination_account_id': t.destinationAccountId},
            ));
          }
        }
      }

      // Check piggy banks with invalid account references
      final List<PiggyBankEntity> piggyBanks = await _database.select(_database.piggyBanks).get();

      for (final PiggyBankEntity pb in piggyBanks) {
        final AccountEntity? account = await (_database.select(_database.accounts)
              ..where(($AccountsTable a) => a.id.equals(pb.accountId)))
            .getSingleOrNull();

        if (account == null) {
          issues.add(InconsistencyIssue(
            type: InconsistencyType.brokenReference,
            entityType: 'piggy_bank',
            entityId: pb.id,
            description: 'Piggy bank references non-existent account',
            suggestedFix: 'Remove piggy bank or fix account reference',
            severity: InconsistencySeverity.high,
            context: {'account_id': pb.accountId},
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to check broken references', e, stackTrace);
    }

    return issues;
  }

  /// Check for account balance mismatches.
  Future<List<InconsistencyIssue>> _checkBalanceMismatches() async {
    final List<InconsistencyIssue> issues = <InconsistencyIssue>[];

    try {
      final List<AccountEntity> accounts = await _database.select(_database.accounts).get();

      for (final AccountEntity account in accounts) {
        // Calculate balance from transactions
        final List<TransactionEntity> transactions = await (_database.select(_database.transactions)
              ..where(($TransactionsTable t) =>
                  t.sourceAccountId.equals(account.id) | t.destinationAccountId.equals(account.id)))
            .get();

        double calculatedBalance = 0.0;
        for (final TransactionEntity t in transactions) {
          if (t.sourceAccountId == account.id) {
            calculatedBalance -= t.amount;
          }
          if (t.destinationAccountId == account.id) {
            calculatedBalance += t.amount;
          }
        }

        // Compare with stored balance
        final double storedBalance = account.currentBalance ?? 0.0;
        final double difference = (calculatedBalance - storedBalance).abs();

        if (difference > 0.01) {
          // Allow 1 cent tolerance for rounding
          issues.add(InconsistencyIssue(
            type: InconsistencyType.balanceMismatch,
            entityType: 'account',
            entityId: account.id,
            description: 'Account balance mismatch: stored=$storedBalance, calculated=$calculatedBalance',
            suggestedFix: 'Recalculate balance from transactions',
            severity: InconsistencySeverity.medium,
            context: {
              'stored_balance': storedBalance,
              'calculated_balance': calculatedBalance,
              'difference': difference,
            },
          ));
        }
      }
    } catch (e, stackTrace) {
      _logger.severe('Failed to check balance mismatches', e, stackTrace);
    }

    return issues;
  }

  /// Check for timestamp inconsistencies.
  Future<List<InconsistencyIssue>> _checkTimestampInconsistencies() async {
    final List<InconsistencyIssue> issues = <InconsistencyIssue>[];

    try {
      // Check transactions with updatedAt < createdAt
      final List<TransactionEntity> transactions = await _database.select(_database.transactions).get();

      for (final TransactionEntity t in transactions) {
        if (t.updatedAt.isBefore(t.createdAt)) {
          issues.add(InconsistencyIssue(
            type: InconsistencyType.timestampInconsistency,
            entityType: 'transaction',
            entityId: t.id,
            description: 'Updated timestamp is before created timestamp',
            suggestedFix: 'Set updatedAt = createdAt',
            severity: InconsistencySeverity.low,
            context: {
              'created_at': t.createdAt.toIso8601String(),
              'updated_at': t.updatedAt.toIso8601String(),
            },
          ));
        }
      }

      // Check other entity types similarly
    } catch (e, stackTrace) {
      _logger.severe('Failed to check timestamp inconsistencies', e, stackTrace);
    }

    return issues;
  }

  // ==================== REPAIR METHODS ====================

  /// Repair entities marked as synced but missing server IDs.
  Future<int> _repairMissingSyncedServerIds({required bool dryRun}) async {
    int repaired = 0;

    try {
      if (dryRun) {
        final List<InconsistencyIssue> issues = await _checkMissingSyncedServerIds();
        return issues.length;
      }

      await _database.transaction(() async {
        // Mark transactions as not synced
        repaired += await (_database.update(_database.transactions)
              ..where(($TransactionsTable t) => t.isSynced.equals(true) & t.serverId.isNull()))
            .write(const TransactionEntityCompanion(isSynced: Value(false)));

        // Mark accounts as not synced
        repaired += await (_database.update(_database.accounts)
              ..where(($AccountsTable a) => a.isSynced.equals(true) & a.serverId.isNull()))
            .write(const AccountEntityCompanion(isSynced: Value(false)));

        // Mark other entity types similarly
      });

      _logger.info('Marked $repaired entities as not synced');
    } catch (e, stackTrace) {
      _logger.severe('Failed to repair missing synced server IDs', e, stackTrace);
      throw DatabaseException('Failed to repair missing synced server IDs: ${e.toString()}');
    }

    return repaired;
  }

  /// Repair orphaned operations.
  Future<int> _repairOrphanedOperations({required bool dryRun}) async {
    int repaired = 0;

    try {
      final List<InconsistencyIssue> issues = await _checkOrphanedOperations();

      if (dryRun) {
        return issues.length;
      }

      await _database.transaction(() async {
        for (final InconsistencyIssue issue in issues) {
          if (issue.operationId != null) {
            await (_database.delete(_database.syncQueue)
                  ..where(($SyncQueueTable sq) => sq.id.equals(issue.operationId!)))
                .go();
            repaired++;
          }
        }
      });

      _logger.info('Removed $repaired orphaned operations');
    } catch (e, stackTrace) {
      _logger.severe('Failed to repair orphaned operations', e, stackTrace);
      throw DatabaseException('Failed to repair orphaned operations: ${e.toString()}');
    }

    return repaired;
  }

  /// Repair duplicate operations.
  Future<int> _repairDuplicateOperations({required bool dryRun}) async {
    int repaired = 0;

    try {
      final List<InconsistencyIssue> issues = await _checkDuplicateOperations();

      if (dryRun) {
        return issues.length;
      }

      await _database.transaction(() async {
        for (final InconsistencyIssue issue in issues) {
          final List<String> operationIds = (issue.context['operation_ids'] as List<dynamic>).cast<String>();
          
          // Keep the most recent (last in list), remove others
          for (int i = 0; i < operationIds.length - 1; i++) {
            await (_database.delete(_database.syncQueue)
                  ..where(($SyncQueueTable sq) => sq.id.equals(operationIds[i])))
                .go();
            repaired++;
          }
        }
      });

      _logger.info('Removed $repaired duplicate operations');
    } catch (e, stackTrace) {
      _logger.severe('Failed to repair duplicate operations', e, stackTrace);
      throw DatabaseException('Failed to repair duplicate operations: ${e.toString()}');
    }

    return repaired;
  }

  /// Repair broken references.
  Future<int> _repairBrokenReferences({required bool dryRun}) async {
    int repaired = 0;

    try {
      final List<InconsistencyIssue> issues = await _checkBrokenReferences();

      if (dryRun) {
        return issues.length;
      }

      await _database.transaction(() async {
        for (final InconsistencyIssue issue in issues) {
          // For now, delete entities with broken references
          // In production, might want to prompt user or try to fix references
          if (issue.entityType == 'transaction' && issue.entityId != null) {
            await (_database.delete(_database.transactions)
                  ..where(($TransactionsTable t) => t.id.equals(issue.entityId!)))
                .go();
            repaired++;
          } else if (issue.entityType == 'piggy_bank' && issue.entityId != null) {
            await (_database.delete(_database.piggyBanks)
                  ..where(($PiggyBanksTable pb) => pb.id.equals(issue.entityId!)))
                .go();
            repaired++;
          }
        }
      });

      _logger.info('Removed $repaired entities with broken references');
    } catch (e, stackTrace) {
      _logger.severe('Failed to repair broken references', e, stackTrace);
      throw DatabaseException('Failed to repair broken references: ${e.toString()}');
    }

    return repaired;
  }

  /// Repair balance mismatches.
  Future<int> _repairBalanceMismatches({required bool dryRun}) async {
    int repaired = 0;

    try {
      final List<InconsistencyIssue> issues = await _checkBalanceMismatches();

      if (dryRun) {
        return issues.length;
      }

      await _database.transaction(() async {
        for (final InconsistencyIssue issue in issues) {
          if (issue.entityId != null) {
            final double calculatedBalance = issue.context['calculated_balance'] as double;
            
            await (_database.update(_database.accounts)
                  ..where(($AccountsTable a) => a.id.equals(issue.entityId!)))
                .write(AccountEntityCompanion(currentBalance: Value(calculatedBalance)));
            repaired++;
          }
        }
      });

      _logger.info('Recalculated $repaired account balances');
    } catch (e, stackTrace) {
      _logger.severe('Failed to repair balance mismatches', e, stackTrace);
      throw DatabaseException('Failed to repair balance mismatches: ${e.toString()}');
    }

    return repaired;
  }

  /// Repair timestamp inconsistencies.
  Future<int> _repairTimestampInconsistencies({required bool dryRun}) async {
    int repaired = 0;

    try {
      final List<InconsistencyIssue> issues = await _checkTimestampInconsistencies();

      if (dryRun) {
        return issues.length;
      }

      await _database.transaction(() async {
        for (final InconsistencyIssue issue in issues) {
          if (issue.entityId != null && issue.entityType == 'transaction') {
            // Get the entity to access createdAt
            final TransactionEntity? entity = await (_database.select(_database.transactions)
                  ..where(($TransactionsTable t) => t.id.equals(issue.entityId!)))
                .getSingleOrNull();

            if (entity != null) {
              await (_database.update(_database.transactions)
                    ..where(($TransactionsTable t) => t.id.equals(issue.entityId!)))
                  .write(TransactionEntityCompanion(updatedAt: Value(entity.createdAt)));
              repaired++;
            }
          }
        }
      });

      _logger.info('Fixed $repaired timestamp inconsistencies');
    } catch (e, stackTrace) {
      _logger.severe('Failed to repair timestamp inconsistencies', e, stackTrace);
      throw DatabaseException('Failed to repair timestamp inconsistencies: ${e.toString()}');
    }

    return repaired;
  }
}
