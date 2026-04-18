import 'package:isar_community/isar.dart';

part 'sync_metadata.g.dart';

@collection
class SyncMetadata {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String entityType;

  DateTime? lastDownloadSync;

  DateTime? lastUploadSync;

  DateTime? lastFullSync;

  @Index()
  bool syncPaused = false;

  int retryCount = 0;

  DateTime? nextRetryAt;

  String? lastError;

  bool credentialsValidated = false;

  bool credentialsInvalid = false;
}
