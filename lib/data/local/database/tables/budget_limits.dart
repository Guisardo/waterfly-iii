import 'package:isar_community/isar.dart';

part 'budget_limits.g.dart';

@collection
class BudgetLimits {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String budgetLimitId;

  late String data; // JSON-encoded BudgetLimitRead

  DateTime? updatedAt;

  late DateTime localUpdatedAt;

  @Index()
  bool synced = false;
}
