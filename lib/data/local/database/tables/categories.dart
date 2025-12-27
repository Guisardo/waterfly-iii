import 'package:isar_community/isar.dart';

part 'categories.g.dart';

@collection
class Categories {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String categoryId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
