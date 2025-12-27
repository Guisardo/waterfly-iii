import 'package:isar_community/isar.dart';

part 'sync_conflicts.g.dart';

@collection
class SyncConflicts {
  Id id = Isar.autoIncrement;

  @Index()
  late String entityType;

  @Index()
  late String entityId;

  @Index()
  late String conflictType; // download, upload, concurrent

  DateTime? localUpdatedAt;

  DateTime? serverUpdatedAt;

  late String resolution; // server_wins, local_cancelled

  @Index()
  late DateTime timestamp;
}
