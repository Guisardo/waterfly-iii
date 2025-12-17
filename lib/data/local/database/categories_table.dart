import 'package:drift/drift.dart';

/// Categories table for storing Firefly III categories locally.
@DataClassName('CategoryEntity')
class Categories extends Table {
  /// Unique identifier (UUID) for the category.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created categories.
  TextColumn get serverId => text().nullable()();

  /// Category name.
  TextColumn get name => text()();

  /// Additional notes for the category, nullable.
  TextColumn get notes => text().nullable()();

  /// Timestamp when the category was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the category was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Server's last updated timestamp for incremental sync change detection.
  ///
  /// This field stores the `updated_at` timestamp from the Firefly III API
  /// response. It is used during incremental sync to determine if the local
  /// entity needs to be updated by comparing with the server's timestamp.
  ///
  /// If server timestamp is newer, the entity is updated. If equal or older,
  /// the entity is skipped (no database write), improving sync performance.
  ///
  /// Nullable for:
  /// - Offline-created categories that haven't been synced yet
  /// - Legacy categories created before incremental sync was implemented
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the category has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{serverId},
  ];
}
