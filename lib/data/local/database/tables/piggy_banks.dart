import 'package:isar_community/isar.dart';

part 'piggy_banks.g.dart';

@collection
class PiggyBanks {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String piggyBankId;

  late String data;

  DateTime? updatedAt;

  DateTime? localUpdatedAt;

  @Index()
  bool synced = false;
}
