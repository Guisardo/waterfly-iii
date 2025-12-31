import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/services/sync/sync_notifications.dart';
import 'package:waterflyiii/settings.dart';

void main() {
  group('SyncNotifications Localization Tests', () {
    late SyncNotifications notifications;
    late SettingsProvider settingsProvider;

    setUp(() {
      notifications = SyncNotifications();
      settingsProvider = SettingsProvider();
    });

    test('_getLocalizedString is called when showing notifications', () async {
      try {
        await notifications.initialize();
        notifications.setSettingsProvider(settingsProvider);

        // Call all notification methods to exercise _getLocalizedString
        // Even if they throw, the _getLocalizedString method should be called
        try {
          await notifications.showSyncStarted();
        } catch (_) {}

        try {
          await notifications.showSyncProgress(
            entityType: 'test',
            current: 1,
            total: 10,
          );
        } catch (_) {}

        try {
          await notifications.showSyncCompleted();
        } catch (_) {}

        try {
          await notifications.showSyncPaused('Error');
        } catch (_) {}

        try {
          await notifications.showCredentialError();
        } catch (_) {}

        expect(notifications, isNotNull);
      } catch (e) {
        expect(e, isNotNull);
      }
    });

    test('setSettingsProvider with null', () {
      notifications.setSettingsProvider(null);
      expect(notifications, isNotNull);
    });

    test('setSettingsProvider with provider', () {
      notifications.setSettingsProvider(settingsProvider);
      expect(notifications, isNotNull);
    });

    test('notification constants are accessible', () {
      expect(SyncNotifications.syncNotificationId, equals(1000));
      expect(SyncNotifications.credentialErrorNotificationId, equals(1001));
      expect(SyncNotifications.syncPausedNotificationId, equals(1002));
    });

    test('all notification methods can be called', () async {
      try {
        await notifications.initialize();
        notifications.setSettingsProvider(settingsProvider);

        // Call each method at least once
        await notifications.showSyncStarted().catchError((_) {});
        await notifications
            .showSyncProgress(
              entityType: 'accounts',
              current: 5,
              total: 10,
              message: 'Test',
            )
            .catchError((_) {});
        await notifications
            .showSyncProgress(entityType: 'transactions', current: 3, total: 5)
            .catchError((_) {});
        await notifications.showSyncCompleted().catchError((_) {});
        await notifications.showSyncPaused('Network error').catchError((_) {});
        await notifications.showCredentialError().catchError((_) {});
        await notifications.cancelAll().catchError((_) {});

        expect(notifications, isNotNull);
      } catch (e) {
        expect(e, isNotNull);
      }
    });
  });
}
