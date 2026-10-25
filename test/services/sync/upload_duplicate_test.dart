import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/sync/upload_service.dart';

void main() {
  group('duplicateTransactionIdFromError', () {
    test('extracts the id from the firefly duplicate response', () {
      const String body =
          '{"message":"Duplicate of transaction #29127.","errors":'
          '{"transactions.0.description":["Duplicate of transaction #29127."]}}';
      expect(duplicateTransactionIdFromError(body), 29127);
    });

    test('works on the wrapped exception text', () {
      final Exception error = Exception(
        'Failed to create transactions: '
        '{"message":"Duplicate of transaction #29113."}',
      );
      expect(duplicateTransactionIdFromError(error), 29113);
    });

    test('returns null for other errors', () {
      expect(
        duplicateTransactionIdFromError(
          '{"message":"The given data was invalid."}',
        ),
        isNull,
      );
      expect(duplicateTransactionIdFromError(null), isNull);
    });
  });
}
