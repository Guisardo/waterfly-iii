import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/pages/transaction.dart';

void main() {
  group('shouldOpenTransactionsAfterSave', () {
    test('new transaction opens the Transactions tab', () {
      expect(
        shouldOpenTransactionsAfterSave(
          isNewTransaction: true,
          fromNotification: false,
          fromSharedFiles: false,
        ),
        isTrue,
      );
    });

    test('edit or clone keeps previous behavior', () {
      expect(
        shouldOpenTransactionsAfterSave(
          isNewTransaction: false,
          fromNotification: false,
          fromSharedFiles: false,
        ),
        isFalse,
      );
    });

    test('notification launch keeps previous behavior', () {
      expect(
        shouldOpenTransactionsAfterSave(
          isNewTransaction: true,
          fromNotification: true,
          fromSharedFiles: false,
        ),
        isFalse,
      );
    });

    test('shared files launch keeps previous behavior', () {
      expect(
        shouldOpenTransactionsAfterSave(
          isNewTransaction: true,
          fromNotification: false,
          fromSharedFiles: true,
        ),
        isFalse,
      );
    });
  });
}
