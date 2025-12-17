import 'dart:convert';
import 'package:sqflite/sqflite.dart';

import 'package:waterflyiii/models/conflict.dart';

/// Database table for storing sync conflicts.
///
/// This table tracks all conflicts detected during synchronization,
/// including their resolution status and strategy used.
class ConflictsTable {
  static const String tableName = 'conflicts';

  /// Create the conflicts table.
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        operation_id TEXT NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id TEXT NOT NULL,
        conflict_type TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        conflicting_fields TEXT NOT NULL,
        severity TEXT NOT NULL,
        detected_at INTEGER NOT NULL,
        resolved_at INTEGER,
        resolution_strategy TEXT,
        resolved_by TEXT,
        resolved_data TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (operation_id) REFERENCES sync_queue(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for efficient queries
    await db.execute('''
      CREATE INDEX idx_conflicts_operation_id ON $tableName(operation_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_conflicts_entity ON $tableName(entity_type, entity_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_conflicts_resolved ON $tableName(resolved_at)
    ''');

    await db.execute('''
      CREATE INDEX idx_conflicts_severity ON $tableName(severity)
    ''');
  }

  /// Insert a conflict into the database.
  static Future<void> insert(Database db, Conflict conflict) async {
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.insert(tableName, <String, Object?>{
      'id': conflict.id,
      'operation_id': conflict.operationId,
      'entity_type': conflict.entityType,
      'entity_id': conflict.entityId,
      'conflict_type': conflict.conflictType.name,
      'local_data': jsonEncode(conflict.localData),
      'remote_data': jsonEncode(conflict.remoteData),
      'conflicting_fields': jsonEncode(conflict.conflictingFields),
      'severity': conflict.severity.name,
      'detected_at': conflict.detectedAt.millisecondsSinceEpoch,
      'resolved_at': conflict.resolvedAt?.millisecondsSinceEpoch,
      'resolution_strategy': null,
      'resolved_by': null,
      'resolved_data': null,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Update a conflict's resolution.
  static Future<void> updateResolution(
    Database db,
    String conflictId, {
    required ResolutionStrategy strategy,
    required String resolvedBy,
    required Map<String, dynamic> resolvedData,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      tableName,
      <String, Object?>{
        'resolved_at': now,
        'resolution_strategy': strategy.name,
        'resolved_by': resolvedBy,
        'resolved_data': jsonEncode(resolvedData),
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: <Object?>[conflictId],
    );
  }

  /// Get a conflict by ID.
  static Future<Conflict?> getById(Database db, String id) async {
    final List<Map<String, Object?>> results = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: <Object?>[id],
    );

    if (results.isEmpty) return null;

    return _fromMap(results.first);
  }

  /// Get a conflict by operation ID.
  static Future<Conflict?> getByOperationId(
    Database db,
    String operationId,
  ) async {
    final List<Map<String, Object?>> results = await db.query(
      tableName,
      where: 'operation_id = ?',
      whereArgs: <Object?>[operationId],
    );

    if (results.isEmpty) return null;

    return _fromMap(results.first);
  }

  /// Get all unresolved conflicts.
  static Future<List<Conflict>> getUnresolved(Database db) async {
    final List<Map<String, Object?>> results = await db.query(
      tableName,
      where: 'resolved_at IS NULL',
      orderBy: 'detected_at DESC',
    );

    return results.map(_fromMap).toList();
  }

  /// Get unresolved conflicts by severity.
  static Future<List<Conflict>> getUnresolvedBySeverity(
    Database db,
    ConflictSeverity severity,
  ) async {
    final List<Map<String, Object?>> results = await db.query(
      tableName,
      where: 'resolved_at IS NULL AND severity = ?',
      whereArgs: <Object?>[severity.name],
      orderBy: 'detected_at DESC',
    );

    return results.map(_fromMap).toList();
  }

  /// Get conflicts by entity.
  static Future<List<Conflict>> getByEntity(
    Database db,
    String entityType,
    String entityId,
  ) async {
    final List<Map<String, Object?>> results = await db.query(
      tableName,
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: <Object?>[entityType, entityId],
      orderBy: 'detected_at DESC',
    );

    return results.map(_fromMap).toList();
  }

  /// Get conflict statistics.
  static Future<ConflictStatistics> getStatistics(Database db) async {
    // Total conflicts
    final List<Map<String, Object?>> totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName',
    );
    final int totalConflicts = totalResult.first['count'] as int;

    // Unresolved conflicts
    final List<Map<String, Object?>> unresolvedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE resolved_at IS NULL',
    );
    final int unresolvedConflicts = unresolvedResult.first['count'] as int;

    // Auto-resolved conflicts
    final List<Map<String, Object?>> autoResolvedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE resolved_by = ?',
      <Object?>['auto'],
    );
    final int autoResolvedConflicts = autoResolvedResult.first['count'] as int;

    // Manually resolved conflicts
    final List<Map<String, Object?>> manuallyResolvedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE resolved_by = ?',
      <Object?>['user'],
    );
    final int manuallyResolvedConflicts =
        manuallyResolvedResult.first['count'] as int;

    // By severity
    final List<Map<String, Object?>> severityResult = await db.rawQuery(
      'SELECT severity, COUNT(*) as count FROM $tableName GROUP BY severity',
    );
    final Map<ConflictSeverity, int> bySeverity = <ConflictSeverity, int>{};
    for (final Map<String, Object?> row in severityResult) {
      final ConflictSeverity severity = ConflictSeverity.values.firstWhere(
        (ConflictSeverity s) => s.name == row['severity'],
      );
      bySeverity[severity] = row['count'] as int;
    }

    // By type
    final List<Map<String, Object?>> typeResult = await db.rawQuery(
      'SELECT conflict_type, COUNT(*) as count FROM $tableName GROUP BY conflict_type',
    );
    final Map<ConflictType, int> byType = <ConflictType, int>{};
    for (final Map<String, Object?> row in typeResult) {
      final ConflictType type = ConflictType.values.firstWhere(
        (ConflictType t) => t.name == row['conflict_type'],
      );
      byType[type] = row['count'] as int;
    }

    // By entity type
    final List<Map<String, Object?>> entityTypeResult = await db.rawQuery(
      'SELECT entity_type, COUNT(*) as count FROM $tableName GROUP BY entity_type',
    );
    final Map<String, int> byEntityType = <String, int>{};
    for (final Map<String, Object?> row in entityTypeResult) {
      byEntityType[row['entity_type'] as String] = row['count'] as int;
    }

    // Average resolution time
    final List<Map<String, Object?>> resolutionTimeResult = await db.rawQuery(
      'SELECT AVG(resolved_at - detected_at) as avg_time FROM $tableName WHERE resolved_at IS NOT NULL',
    );
    final double avgResolutionTime =
        (resolutionTimeResult.first['avg_time'] as num?)?.toDouble() ?? 0.0;

    return ConflictStatistics(
      totalConflicts: totalConflicts,
      unresolvedConflicts: unresolvedConflicts,
      autoResolvedConflicts: autoResolvedConflicts,
      manuallyResolvedConflicts: manuallyResolvedConflicts,
      bySeverity: bySeverity,
      byType: byType,
      byEntityType: byEntityType,
      averageResolutionTime: avgResolutionTime / 1000.0, // Convert to seconds
    );
  }

  /// Delete a conflict.
  static Future<void> delete(Database db, String id) async {
    await db.delete(tableName, where: 'id = ?', whereArgs: <Object?>[id]);
  }

  /// Delete all resolved conflicts older than the specified duration.
  static Future<int> deleteOldResolved(Database db, Duration age) async {
    final int cutoffTime = DateTime.now().subtract(age).millisecondsSinceEpoch;

    return db.delete(
      tableName,
      where: 'resolved_at IS NOT NULL AND resolved_at < ?',
      whereArgs: <Object?>[cutoffTime],
    );
  }

  /// Delete all conflicts.
  static Future<void> deleteAll(Database db) async {
    await db.delete(tableName);
  }

  /// Convert database map to Conflict model.
  static Conflict _fromMap(Map<String, dynamic> map) {
    return Conflict(
      id: map['id'] as String,
      operationId: map['operation_id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      conflictType: ConflictType.values.firstWhere(
        (ConflictType t) => t.name == map['conflict_type'],
      ),
      localData:
          jsonDecode(map['local_data'] as String) as Map<String, dynamic>,
      remoteData:
          jsonDecode(map['remote_data'] as String) as Map<String, dynamic>,
      conflictingFields: List<String>.from(
        jsonDecode(map['conflicting_fields'] as String) as List,
      ),
      severity: ConflictSeverity.values.firstWhere(
        (ConflictSeverity s) => s.name == map['severity'],
      ),
      detectedAt: DateTime.fromMillisecondsSinceEpoch(
        map['detected_at'] as int,
      ),
      resolvedAt:
          map['resolved_at'] != null
              ? DateTime.fromMillisecondsSinceEpoch(map['resolved_at'] as int)
              : null,
    );
  }
}
