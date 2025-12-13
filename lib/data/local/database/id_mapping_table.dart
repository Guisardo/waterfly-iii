import 'package:drift/drift.dart';

/// ID mapping table for tracking local-to-server ID mappings.
///
/// When entities are created offline, they get local UUIDs. After syncing,
/// this table maps the local ID to the server-assigned ID.
@DataClassName('IdMappingEntity')
class IdMapping extends Table {
  /// Local ID (UUID generated offline).
  TextColumn get localId => text()();

  /// Server ID (ID assigned by Firefly III API after sync).
  TextColumn get serverId => text()();

  /// Entity type: 'transaction', 'account', 'category', etc.
  TextColumn get entityType => text()();

  /// Timestamp when the mapping was created (when entity was synced).
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the entity was successfully synced.
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {localId};

  @override
  List<Set<Column>> get uniqueKeys => [
        {serverId, entityType}
      ];
}
