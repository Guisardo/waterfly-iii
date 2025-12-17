import 'package:drift/drift.dart';

/// Tags table for storing Firefly III tags locally.
///
/// Stores all tags that can be associated with transactions.
/// Tags provide flexible categorization beyond the primary category system.
///
/// Tag data changes moderately often as users create new tags,
/// using medium TTL (1 hour as per CacheTtlConfig).
///
/// Primary use cases:
/// - Tag selection in transaction forms (autocomplete)
/// - Tag filtering in transaction lists
/// - Tag management and editing
/// - Offline tag lookups
@DataClassName('TagEntity')
class Tags extends Table {
  /// Unique identifier (UUID) for the tag.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created tags.
  TextColumn get serverId => text().nullable()();

  /// Tag name/label (e.g., 'vacation', 'groceries', 'work-expense').
  ///
  /// Tag names are case-sensitive and must be unique within the instance.
  TextColumn get tag => text()();

  /// Optional description or notes for the tag.
  TextColumn get description => text().nullable()();

  /// Optional date when this tag was first used or created.
  DateTimeColumn get date => dateTime().nullable()();

  /// Latitude for location-based tags, nullable.
  RealColumn get latitude => real().nullable()();

  /// Longitude for location-based tags, nullable.
  RealColumn get longitude => real().nullable()();

  /// Zoom level for map display of location tags, nullable.
  IntColumn get zoomLevel => integer().nullable()();

  /// Timestamp when the tag was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the tag was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Server's last updated timestamp for incremental sync change detection.
  ///
  /// Used during incremental sync to determine if the local entity
  /// needs to be updated by comparing with the server's timestamp.
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the tag has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error'.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{tag}, // Tag names must be unique
    <Column<Object>>{serverId},
  ];
}
