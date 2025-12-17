import 'package:drift/drift.dart';

/// Conflicts table for storing sync conflicts that require user resolution.
@DataClassName('ConflictEntity')
class Conflicts extends Table {
  /// Unique identifier for the conflict.
  TextColumn get id => text()();

  /// Entity type: 'transaction', 'account', 'category', 'budget', 'bill', 'piggy_bank'.
  TextColumn get entityType => text()();

  /// Entity ID (local or server ID).
  TextColumn get entityId => text()();

  /// Conflict type: 'update_conflict', 'delete_conflict', 'create_conflict'.
  TextColumn get conflictType => text()();

  /// Local version of the entity as JSON.
  TextColumn get localData => text()();

  /// Server version of the entity as JSON.
  TextColumn get serverData => text()();

  /// Conflicting fields as JSON array.
  TextColumn get conflictingFields => text()();

  /// Resolution status: 'pending', 'resolved', 'ignored'.
  TextColumn get status => text().withDefault(const Constant('pending'))();

  /// Resolution strategy: 'use_local', 'use_server', 'merge', 'manual'.
  TextColumn get resolutionStrategy => text().nullable()();

  /// Resolved data as JSON (after user resolution).
  TextColumn get resolvedData => text().nullable()();

  /// Timestamp when the conflict was detected.
  DateTimeColumn get detectedAt => dateTime()();

  /// Timestamp when the conflict was resolved.
  DateTimeColumn get resolvedAt => dateTime().nullable()();

  /// User who resolved the conflict.
  TextColumn get resolvedBy => text().nullable()();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<String> get customConstraints => <String>[
    'CHECK (entity_type IN (\'transaction\', \'account\', \'category\', \'budget\', \'bill\', \'piggy_bank\'))',
    'CHECK (conflict_type IN (\'update_conflict\', \'delete_conflict\', \'create_conflict\'))',
    'CHECK (status IN (\'pending\', \'resolved\', \'ignored\'))',
  ];
}
