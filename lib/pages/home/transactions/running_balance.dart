import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';

/// Change that [item] applies to the balance of [accountId].
double transactionBalanceEffect(TransactionRead item, String accountId) {
  double effect = 0;
  for (final TransactionSplit tx in item.attributes.transactions) {
    final double amount = double.tryParse(tx.amount) ?? 0.0;
    if (amount == 0.0) {
      continue;
    }
    if (tx.type == TransactionTypeProperty.withdrawal) {
      effect -= amount;
    } else if (tx.type == TransactionTypeProperty.transfer) {
      effect += tx.destinationId == accountId ? amount : -amount;
    } else {
      effect += amount;
    }
  }
  return effect;
}

/// Balance after the newest row when the balance is zero before the oldest.
double windowBalanceTotal(Iterable<TransactionRead> items, String accountId) =>
    items.fold(
      0.0,
      (double sum, TransactionRead item) =>
          sum + transactionBalanceEffect(item, accountId),
    );
