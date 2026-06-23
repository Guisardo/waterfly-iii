import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/sync/sync_log_sanitizer.dart';

void main() {
  group('sanitizeSyncLogText', () {
    test('redacts auth headers, URLs, and financial fields', () {
      final String sanitized = sanitizeSyncLogText(
        'Bearer secret-token https://firefly.example/api/v1/transactions?query=coffee '
        'description=Morning coffee amount=12.34 external_id=abc123 token=xyz '
        'name=Checking iban=NL00TEST group_title=Trip tags=travel foreign_amount=9.99',
      );

      expect(sanitized, isNot(contains('secret-token')));
      expect(sanitized, isNot(contains('firefly.example')));
      expect(sanitized, isNot(contains('Morning coffee')));
      expect(sanitized, isNot(contains('12.34')));
      expect(sanitized, isNot(contains('abc123')));
      expect(sanitized, isNot(contains('Checking')));
      expect(sanitized, isNot(contains('NL00TEST')));
      expect(sanitized, isNot(contains('Trip')));
      expect(sanitized, isNot(contains('travel')));
      expect(sanitized, isNot(contains('9.99')));
      expect(sanitized, contains('Bearer <redacted>'));
      expect(sanitized, contains('<redacted-url>'));
      expect(sanitized, contains('<redacted>'));
    });

    test('truncates long messages', () {
      final String sanitized = sanitizeSyncLogText(
        List<String>.filled(700, 'x').join(),
        maxLength: 32,
      );

      expect(sanitized.length, lessThan(60));
      expect(sanitized, endsWith('...<truncated>'));
    });
  });
}
