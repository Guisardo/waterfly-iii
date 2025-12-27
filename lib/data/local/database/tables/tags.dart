import 'package:isar_community/isar.dart';

part 'tags.g.dart';

@collection
class Tags {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String tagId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
