import 'package:drift/drift.dart';

/// Attachments table for storing Firefly III attachments locally.
///
/// Stores metadata for attachments associated with transactions.
/// Actual attachment files are stored separately (file system or server).
///
/// Attachment metadata changes infrequently after creation,
/// using long TTL (2 hours as per CacheTtlConfig).
///
/// Primary use cases:
/// - Attachment listing in transaction details
/// - Attachment upload/download tracking
/// - Offline attachment metadata access
/// - Sync queue for pending attachment operations
@DataClassName('AttachmentEntity')
class Attachments extends Table {
  /// Unique identifier (UUID) for the attachment.
  TextColumn get id => text()();

  /// Server-side ID from Firefly III API, nullable for offline-created attachments.
  TextColumn get serverId => text().nullable()();

  /// The type of entity this attachment belongs to (e.g., 'TransactionJournal').
  TextColumn get attachableType => text()();

  /// The ID of the entity this attachment belongs to.
  TextColumn get attachableId => text()();

  /// Original filename of the attachment.
  TextColumn get filename => text()();

  /// Optional title/description for the attachment.
  TextColumn get title => text().nullable()();

  /// MIME type of the attachment (e.g., 'image/jpeg', 'application/pdf').
  TextColumn get mimeType => text().nullable()();

  /// File size in bytes.
  IntColumn get size => integer().nullable()();

  /// MD5 hash of the file content for integrity verification.
  TextColumn get md5 => text().nullable()();

  /// Download URL for the attachment (from Firefly III API).
  TextColumn get downloadUrl => text().nullable()();

  /// Upload URL for posting new attachment content.
  TextColumn get uploadUrl => text().nullable()();

  /// Local file path if attachment is cached locally.
  TextColumn get localPath => text().nullable()();

  /// Whether the attachment content has been downloaded locally.
  BoolColumn get isDownloaded => boolean().withDefault(const Constant(false))();

  /// Whether the attachment content is pending upload.
  BoolColumn get isPendingUpload =>
      boolean().withDefault(const Constant(false))();

  /// Optional notes about the attachment.
  TextColumn get notes => text().nullable()();

  /// Timestamp when the attachment was created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Timestamp when the attachment was last updated locally.
  DateTimeColumn get updatedAt => dateTime()();

  /// Server's last updated timestamp for incremental sync change detection.
  ///
  /// Used during incremental sync to determine if the local entity
  /// needs to be updated by comparing with the server's timestamp.
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();

  /// Whether the attachment has been synced with the server.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  /// Sync status: 'pending', 'syncing', 'synced', 'error', 'pending_upload', 'pending_delete'.
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => <Column<Object>>{id};

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column<Object>>>[
    <Column<Object>>{serverId},
  ];
}
