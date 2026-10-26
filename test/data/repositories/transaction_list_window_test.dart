import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';

void main() {
  group('TransactionRepository.listQueryEnd', () {
    // Server day starts at 00:00Z. On a UTC-3 device a pending row dated today
    // is stored at device midnight, 03:00Z. Synced rows keep their time of day.
    final DateTime serverDayStart = DateTime.utc(2026, 10, 25);
    final DateTime pendingToday = DateTime.utc(2026, 10, 25, 3);
    final DateTime syncedToday = DateTime.utc(2026, 10, 25, 20, 23);
    final DateTime tomorrowNoon = DateTime.utc(2026, 10, 26, 12);

    test('start of day alone would hide rows dated today', () {
      expect(pendingToday.isAfter(serverDayStart), isTrue);
      expect(syncedToday.isAfter(serverDayStart), isTrue);
    });

    test('keeps every row dated today inside the window', () {
      final DateTime end = TransactionRepository.listQueryEnd(
        serverDayStart,
        serverDayStart,
      );
      expect(pendingToday.isAfter(end), isFalse);
      expect(syncedToday.isAfter(end), isFalse);
    });

    test('still excludes rows dated after today', () {
      final DateTime end = TransactionRepository.listQueryEnd(
        serverDayStart,
        serverDayStart,
      );
      expect(tomorrowNoon.isAfter(end), isTrue);
    });

    test('without an end date the window reaches a year ahead', () {
      expect(
        TransactionRepository.listQueryEnd(null, serverDayStart),
        serverDayStart.add(const Duration(days: 365)),
      );
    });
  });
}
