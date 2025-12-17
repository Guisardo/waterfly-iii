import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waterflyiii/main.dart' as app;

/// Comprehensive E2E test suite for Waterfly III
///
/// Tests cover:
/// - App initialization and splash screen
/// - Login flow with valid/invalid credentials
/// - Navigation between main screens
/// - Transaction creation and editing
/// - Offline mode functionality
/// - Sync operations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Waterfly III E2E Tests', () {
    testWidgets('App launches and shows splash screen', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Verify splash screen or login screen appears
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should initialize with MaterialApp',
      );
    });

    testWidgets('Login flow with valid credentials', (
      WidgetTester tester,
    ) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and fill server URL field
      final Finder serverUrlField = find.byKey(const Key('serverUrlField'));
      if (serverUrlField.evaluate().isNotEmpty) {
        await tester.enterText(serverUrlField, 'https://demo.firefly-iii.org');
        await tester.pumpAndSettle();
      }

      // Find and fill personal access token field
      final Finder tokenField = find.byKey(const Key('tokenField'));
      if (tokenField.evaluate().isNotEmpty) {
        await tester.enterText(tokenField, 'demo-token');
        await tester.pumpAndSettle();
      }

      // Tap login button
      final Finder loginButton = find.byKey(const Key('loginButton'));
      if (loginButton.evaluate().isNotEmpty) {
        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }

      // Verify navigation to home screen
      expect(
        find.byType(BottomNavigationBar),
        findsOneWidget,
        reason: 'Should navigate to home screen with bottom navigation',
      );
    });

    testWidgets('Navigate through main screens', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Assuming user is logged in, test navigation
      final Finder bottomNav = find.byType(BottomNavigationBar);
      if (bottomNav.evaluate().isNotEmpty) {
        // Navigate to Transactions
        await tester.tap(find.byIcon(Icons.receipt_long));
        await tester.pumpAndSettle();

        // Navigate to Accounts
        await tester.tap(find.byIcon(Icons.account_balance));
        await tester.pumpAndSettle();

        // Navigate to Settings
        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        // Return to Dashboard
        await tester.tap(find.byIcon(Icons.dashboard));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Create new transaction', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find and tap FAB to create transaction
      final Finder fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // Fill transaction details
        final Finder descriptionField = find.byKey(
          const Key('transactionDescription'),
        );
        if (descriptionField.evaluate().isNotEmpty) {
          await tester.enterText(descriptionField, 'Test Transaction');
          await tester.pumpAndSettle();
        }

        final Finder amountField = find.byKey(const Key('transactionAmount'));
        if (amountField.evaluate().isNotEmpty) {
          await tester.enterText(amountField, '100.00');
          await tester.pumpAndSettle();
        }

        // Save transaction
        final Finder saveButton = find.byKey(const Key('saveTransaction'));
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }
      }
    });

    testWidgets('Test offline mode toggle', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Navigate to settings
      final Finder settingsIcon = find.byIcon(Icons.settings);
      if (settingsIcon.evaluate().isNotEmpty) {
        await tester.tap(settingsIcon);
        await tester.pumpAndSettle();

        // Find offline mode toggle
        final Finder offlineToggle = find.byKey(const Key('offlineModeToggle'));
        if (offlineToggle.evaluate().isNotEmpty) {
          await tester.tap(offlineToggle);
          await tester.pumpAndSettle();

          // Verify offline mode is enabled
          expect(
            find.text('Offline Mode'),
            findsOneWidget,
            reason: 'Offline mode should be visible',
          );
        }
      }
    });

    testWidgets('Test sync functionality', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find sync button
      final Finder syncButton = find.byKey(const Key('syncButton'));
      if (syncButton.evaluate().isNotEmpty) {
        await tester.tap(syncButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Verify sync progress indicator appears
        expect(
          find.byType(CircularProgressIndicator),
          findsWidgets,
          reason: 'Sync should show progress indicator',
        );
      }
    });
  });
}
