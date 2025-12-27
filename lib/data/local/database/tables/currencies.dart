import 'package:isar_community/isar.dart';

part 'currencies.g.dart';

@collection
class Currencies {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String currencyId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
