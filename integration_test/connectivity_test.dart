import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waterflyiii/main.dart' as app;

/// Test connectivity changes (online/offline) in Android emulator
/// 
/// To toggle connectivity during test:
/// - Online to Offline: adb shell svc wifi disable && adb shell svc data disable
/// - Offline to Online: adb shell svc wifi enable && adb shell svc data enable
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Connectivity Detection Tests', () {
    testWidgets('Detect offline state when connectivity is disabled', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for app to initialize
      await tester.pump(const Duration(seconds: 2));

      // Look for offline indicator
      final Finder offlineIndicator = find.byKey(const Key('offlineIndicator'));
      final Finder connectivityBar = find.byKey(const Key('connectivityStatusBar'));
      
      // Check if offline mode is detected
      expect(
        offlineIndicator.evaluate().isNotEmpty || connectivityBar.evaluate().isNotEmpty,
        isTrue,
        reason: 'App should show offline indicator when connectivity is disabled',
      );
    });

    testWidgets('Detect online state when connectivity is enabled', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Wait for connectivity check
      await tester.pump(const Duration(seconds: 3));

      // Verify online state (no offline indicator or shows online)
      final Finder offlineIndicator = find.byKey(const Key('offlineIndicator'));
      final Finder onlineIndicator = find.text('Online');
      
      expect(
        offlineIndicator.evaluate().isEmpty || onlineIndicator.evaluate().isNotEmpty,
        isTrue,
        reason: 'App should not show offline indicator when online',
      );
    });

    testWidgets('React to connectivity changes during runtime', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Initial state - should be online
      await tester.pump(const Duration(seconds: 2));
      
      // Manually trigger connectivity change by toggling airplane mode
      // Note: This requires the test to pause and manually toggle connectivity
      
      print('=== TEST INSTRUCTION ===');
      print('Run this command to disable connectivity:');
      print('adb shell svc wifi disable && adb shell svc data disable');
      print('========================');
      
      // Wait for connectivity change to be detected
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Check for offline indicator
      final Finder offlineIndicator = find.byKey(const Key('offlineIndicator'));
      expect(offlineIndicator.evaluate().isNotEmpty, isTrue);

      print('=== TEST INSTRUCTION ===');
      print('Run this command to enable connectivity:');
      print('adb shell svc wifi enable && adb shell svc data enable');
      print('========================');

      // Wait for connectivity to restore
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      // Verify online state restored
      expect(offlineIndicator.evaluate().isEmpty, isTrue);
    });
  });
}
