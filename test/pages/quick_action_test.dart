import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/app.dart';

void main() {
  group('isAddTransactionQuickAction', () {
    test('add transaction shortcut', () {
      expect(isAddTransactionQuickAction('action_transaction_add'), isTrue);
    });
    test('no or other shortcut', () {
      expect(isAddTransactionQuickAction(null), isFalse);
      expect(isAddTransactionQuickAction('other'), isFalse);
    });
  });
}
