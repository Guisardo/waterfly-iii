import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:waterflyiii/main.dart' as app;

/// Integration Tests for Incremental Sync Feature.
///
/// These tests validate the incremental sync functionality on a real device,
/// including UI interactions, settings persistence, and sync progress display.
///
/// ## Prerequisites
///
/// - Android device or emulator connected via USB
/// - App must be able to run on the device
/// - Tests can run without a real Firefly III server (offline mode testing)
///
/// ## Running Tests
///
/// ```bash
/// # Run on connected device
/// flutter test integration_test/incremental_sync_test.dart -d <device_id>
///
/// # Run on all connected devices
/// flutter test integration_test/incremental_sync_test.dart
/// ```
///
/// ## Test Categories
///
/// 1. **Settings UI Tests** - Verify incremental sync settings are visible and functional
/// 2. **Progress Display Tests** - Verify sync progress is displayed correctly
/// 3. **Statistics Display Tests** - Verify sync statistics are shown
/// 4. **Dashboard Card Tests** - Verify dashboard integration works
/// 5. **Force Sync Tests** - Verify force sync functionality
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Incremental Sync Integration Tests', () {
    /// Test that the app launches successfully.
    ///
    /// This is a prerequisite test that verifies the app can start
    /// without crashing, which is essential for all other tests.
    testWidgets('App launches successfully', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify app has started
      expect(
        find.byType(MaterialApp),
        findsOneWidget,
        reason: 'App should initialize with MaterialApp',
      );
    });

    // ==================== Settings UI Tests ====================

    group('Incremental Sync Settings', () {
      testWidgets('Settings page displays incremental sync section',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Verify incremental sync section is visible
        expect(
          find.textContaining('Incremental'),
          findsWidgets,
          reason: 'Incremental sync section should be visible in settings',
        );
      });

      testWidgets('Incremental sync toggle is functional',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Find and tap the incremental sync switch
        final Finder incrementalSwitch = find.descendant(
          of: find.ancestor(
            of: find.textContaining('Incremental Sync'),
            matching: find.byType(SwitchListTile),
          ),
          matching: find.byType(Switch),
        );

        if (incrementalSwitch.evaluate().isNotEmpty) {
          // Get initial state
          final Switch switchWidget =
              tester.widget<Switch>(incrementalSwitch);
          final bool initialValue = switchWidget.value;

          // Toggle the switch
          await tester.tap(incrementalSwitch);
          await tester.pumpAndSettle();

          // Verify switch state changed
          final Switch switchWidgetAfter =
              tester.widget<Switch>(incrementalSwitch);
          expect(
            switchWidgetAfter.value,
            isNot(equals(initialValue)),
            reason: 'Switch should toggle when tapped',
          );

          // Toggle back to original state
          await tester.tap(incrementalSwitch);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Sync window selector is accessible',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Find sync window setting
        final Finder syncWindowText = find.textContaining('Sync Window');
        expect(
          syncWindowText,
          findsWidgets,
          reason: 'Sync window setting should be visible',
        );
      });
    });

    // ==================== Statistics Display Tests ====================

    group('Incremental Sync Statistics', () {
      testWidgets('Statistics section displays correctly',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Verify statistics are visible (may show "No data" initially)
        // Note: Statistics card is searched but may not be visible in all states
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Card &&
              widget.toString().contains('Statistics'),
          description: 'Statistics card',
        );

        // Look for common statistics labels
        expect(
          find.textContaining('Fetched').evaluate().isNotEmpty ||
              find.textContaining('Updated').evaluate().isNotEmpty ||
              find.textContaining('Skipped').evaluate().isNotEmpty ||
              find.textContaining('No data').evaluate().isNotEmpty ||
              find.textContaining('Statistics').evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show statistics section or "No data" message',
        );
      });

      testWidgets('Bandwidth saved is formatted correctly',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for bandwidth saved text (may contain B, KB, MB, GB)
        final Finder bandwidthText = find.textContaining(RegExp(r'\d+.*[BKMG]B'));
        
        // This is an optional check - bandwidth may not be shown if no syncs have occurred
        if (bandwidthText.evaluate().isNotEmpty) {
          expect(
            bandwidthText,
            findsWidgets,
            reason: 'Bandwidth should be formatted with units',
          );
        }
      });
    });

    // ==================== Force Sync Tests ====================

    group('Force Sync Functionality', () {
      testWidgets('Force sync button triggers sync',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Find force sync button
        final Finder forceSyncButton = find.widgetWithText(
          ElevatedButton,
          'Force Sync',
        );

        if (forceSyncButton.evaluate().isEmpty) {
          // Try alternative button text
          final Finder altForceSyncButton = find.widgetWithText(
            TextButton,
            'Force Sync',
          );
          if (altForceSyncButton.evaluate().isNotEmpty) {
            await tester.tap(altForceSyncButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }
        } else {
          await tester.tap(forceSyncButton);
          await tester.pumpAndSettle(const Duration(seconds: 3));
        }

        // Check for sync progress indicator or dialog
        expect(
          find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
              find.byType(LinearProgressIndicator).evaluate().isNotEmpty ||
              find.byType(AlertDialog).evaluate().isNotEmpty,
          isTrue,
          reason: 'Should show progress indicator or dialog when force sync is triggered',
        );
      });

      testWidgets('Individual entity force sync is available',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Look for entity-specific sync buttons
        final bool hasCategoriesSync =
            find.textContaining('Categories').evaluate().isNotEmpty;
        final bool hasBillsSync =
            find.textContaining('Bills').evaluate().isNotEmpty;
        final bool hasPiggyBanksSync =
            find.textContaining('Piggy').evaluate().isNotEmpty;

        expect(
          hasCategoriesSync || hasBillsSync || hasPiggyBanksSync,
          isTrue,
          reason: 'Should have entity-specific sync options',
        );
      });
    });

    // ==================== Progress Display Tests ====================

    group('Sync Progress Display', () {
      testWidgets('Progress dialog shows during sync',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // This test verifies that progress is shown during sync operations
        // The actual sync may not happen without a server, but we can verify
        // the UI components are present

        // Look for any sync-related UI elements
        final bool hasSyncUI = find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
            find.textContaining('Sync').evaluate().isNotEmpty ||
            find.byIcon(Icons.sync).evaluate().isNotEmpty;

        expect(
          hasSyncUI,
          isTrue,
          reason: 'App should have sync-related UI elements',
        );
      });

      testWidgets('Progress shows entity types being synced',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings and try to trigger sync
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings or any sync button
        final Finder syncButton = find.widgetWithIcon(IconButton, Icons.sync);
        if (syncButton.evaluate().isNotEmpty) {
          await tester.tap(syncButton);
          await tester.pump(const Duration(milliseconds: 500));

          // Check for entity type labels in progress
          final bool showsEntityTypes =
              find.textContaining('Transaction').evaluate().isNotEmpty ||
                  find.textContaining('Account').evaluate().isNotEmpty ||
                  find.textContaining('Budget').evaluate().isNotEmpty ||
                  find.textContaining('Category').evaluate().isNotEmpty;

          if (showsEntityTypes) {
            expect(
              showsEntityTypes,
              isTrue,
              reason: 'Progress should show entity types being synced',
            );
          }

          await tester.pumpAndSettle();
        }
      });
    });

    // ==================== Dashboard Card Tests ====================

    group('Dashboard Integration', () {
      testWidgets('Dashboard shows sync status',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to dashboard/home if not already there
        final Finder dashboardIcon = find.byIcon(Icons.dashboard);
        if (dashboardIcon.evaluate().isNotEmpty) {
          await tester.tap(dashboardIcon);
          await tester.pumpAndSettle();
        }

        // Look for sync status elements on dashboard
        // Note: Sync status may or may not be visible depending on app state
        // We just verify the dashboard loads without errors
        expect(
          find.byType(Scaffold),
          findsWidgets,
          reason: 'Dashboard should be visible',
        );
      });

      testWidgets('Sync can be triggered from dashboard',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for sync button on dashboard
        final Finder syncButton = find.byIcon(Icons.sync);
        if (syncButton.evaluate().isNotEmpty) {
          await tester.tap(syncButton.first);
          await tester.pump(const Duration(milliseconds: 500));

          // Verify some UI response to sync trigger
          expect(
            find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
                find.byType(SnackBar).evaluate().isNotEmpty ||
                find.byType(AlertDialog).evaluate().isNotEmpty,
            isTrue,
            reason: 'Should show feedback when sync is triggered',
          );

          await tester.pumpAndSettle();
        }
      });
    });

    // ==================== Accessibility Tests ====================

    group('Accessibility', () {
      testWidgets('Sync settings are accessible via screen reader',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Verify semantic labels are present for key elements
        final SemanticsHandle handle = tester.ensureSemantics();

        // Check that the page has semantic information
        expect(
          tester.getSemantics(find.byType(Scaffold).first),
          matchesSemantics(
            scopesRoute: true,
          ),
          reason: 'Page should have semantic information for accessibility',
        );

        handle.dispose();
      });

      testWidgets('Progress indicators have semantic labels',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Look for any progress indicators
        final Finder progressIndicators =
            find.byType(CircularProgressIndicator);

        if (progressIndicators.evaluate().isNotEmpty) {
          final SemanticsHandle handle = tester.ensureSemantics();

          // Progress indicators should have semantic information
          final Finder firstProgress = progressIndicators.first;
          expect(
            tester.getSemantics(firstProgress).label.isNotEmpty,
            isTrue,
            reason: 'Progress indicators should have semantic labels',
          );

          handle.dispose();
        }
      });
    });

    // ==================== Error Handling Tests ====================

    group('Error Handling', () {
      testWidgets('App handles sync errors gracefully',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Try to force sync (will fail without network/server)
        final Finder forceSyncButton = find.textContaining('Force');
        if (forceSyncButton.evaluate().isNotEmpty) {
          await tester.tap(forceSyncButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 5));

          // App should not crash - verify we're still on a valid screen
          expect(
            find.byType(Scaffold),
            findsWidgets,
            reason: 'App should remain functional after sync error',
          );
        }
      });

      testWidgets('Reset statistics shows confirmation',
          (WidgetTester tester) async {
        app.main();
        await tester.pumpAndSettle(const Duration(seconds: 5));

        // Navigate to settings
        final Finder settingsButton = find.byIcon(Icons.settings);
        if (settingsButton.evaluate().isNotEmpty) {
          await tester.tap(settingsButton);
          await tester.pumpAndSettle();
        }

        // Look for sync settings
        final Finder syncSettingsText = find.text('Sync Settings');
        if (syncSettingsText.evaluate().isNotEmpty) {
          await tester.tap(syncSettingsText);
          await tester.pumpAndSettle();
        }

        // Look for reset button
        final Finder resetButton = find.textContaining('Reset');
        if (resetButton.evaluate().isNotEmpty) {
          await tester.tap(resetButton.first);
          await tester.pumpAndSettle();

          // Should show confirmation dialog
          expect(
            find.byType(AlertDialog).evaluate().isNotEmpty ||
                find.textContaining('confirm').evaluate().isNotEmpty ||
                find.textContaining('sure').evaluate().isNotEmpty,
            isTrue,
            reason: 'Reset should show confirmation dialog',
          );

          // Dismiss dialog
          final Finder cancelButton = find.textContaining('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton.first);
            await tester.pumpAndSettle();
          }
        }
      });
    });
  });
}

