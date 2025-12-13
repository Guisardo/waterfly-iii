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

  /// Whether the category has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {serverId}
      ];
}
