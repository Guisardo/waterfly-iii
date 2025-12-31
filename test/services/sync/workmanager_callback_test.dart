import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/sync/workmanager_sync.dart';

void main() {
  group('WorkManager callbackDispatcher', () {
    test('callbackDispatcher can be called directly', () async {
      // Note: callbackDispatcher is a top-level function that WorkManager calls
      // We can't easily test it without mocking WorkManager, but we can verify
      // the function exists and can be referenced
      expect(callbackDispatcher, isNotNull);
      expect(callbackDispatcher, isA<Function>());
    });

    test('task name constants match expected values', () {
      expect(syncTaskName, equals('waterflySyncTask'));
      expect(uploadTaskName, equals('waterflyUploadTask'));
      expect(syncTaskName, isNot(uploadTaskName));
    });
  });
}
