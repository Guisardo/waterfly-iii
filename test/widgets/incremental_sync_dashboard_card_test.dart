import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/services/sync/incremental_sync_service.dart';
import 'package:waterflyiii/widgets/incremental_sync_dashboard_card.dart';

/// Mock SharedPreferences for testing.
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('IncrementalSyncDashboardCard', () {
    late MockSharedPreferences mockPrefs;
    late OfflineSettingsProvider settingsProvider;

    setUp(() {
      mockPrefs = MockSharedPreferences();

      // Set up default mock returns
      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.remove(any())).thenAnswer((_) async => true);

      settingsProvider = OfflineSettingsProvider.withPrefs(prefs: mockPrefs);
    });

    Widget buildTestWidget({
      IncrementalSyncDashboardCardMode mode =
          IncrementalSyncDashboardCardMode.standard,
      VoidCallback? onSyncTap,
      VoidCallback? onSettingsTap,
      bool isSyncing = false,
      SyncProgressEvent? currentProgress,
      Stream<SyncProgressEvent>? progressStream,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<OfflineSettingsProvider>.value(
            value: settingsProvider,
            child: SingleChildScrollView(
              child: IncrementalSyncDashboardCard(
                mode: mode,
                onSyncTap: onSyncTap,
                onSettingsTap: onSettingsTap,
                isSyncing: isSyncing,
                currentProgress: currentProgress,
                progressStream: progressStream,
              ),
            ),
          ),
        ),
      );
    }

    group('Standard Mode', () {
      testWidgets('renders header with title', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );

        expect(find.text('Incremental Sync'), findsOneWidget);
      });

      testWidgets('renders settings button when callback provided', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            onSettingsTap: () {},
          ),
        );

        expect(find.byIcon(Icons.settings), findsOneWidget);
      });

      testWidgets('settings button triggers callback', (
        WidgetTester tester,
      ) async {
        bool settingsTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            onSettingsTap: () => settingsTapped = true,
          ),
        );

        await tester.tap(find.byIcon(Icons.settings));
        await tester.pumpAndSettle();

        expect(settingsTapped, true);
      });

      testWidgets('renders sync button', (WidgetTester tester) async {
        // Mark full sync as done so needsFullSync = false
        await settingsProvider.recordFullSyncCompleted();

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            onSyncTap: () {},
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sync Now'), findsOneWidget);
      });

      testWidgets('sync button triggers callback', (WidgetTester tester) async {
        // Mark full sync as done so needsFullSync = false
        // Otherwise button shows "Full Sync" instead of "Sync Now"
        await settingsProvider.recordFullSyncCompleted();

        bool syncTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            onSyncTap: () => syncTapped = true,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Sync Now'));
        await tester.pumpAndSettle();

        expect(syncTapped, true);
      });

      testWidgets('shows disabled message when incremental sync disabled', (
        WidgetTester tester,
      ) async {
        await settingsProvider.setIncrementalSyncEnabled(false);

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(
            'Incremental sync is disabled. Enable it in settings for faster syncs.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows first sync message when no syncs yet', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );

        expect(
          find.text(
            'Run your first incremental sync to see efficiency metrics!',
          ),
          findsOneWidget,
        );
      });

      testWidgets('shows stats after syncs', (WidgetTester tester) async {
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 100,
          itemsUpdated: 20,
          itemsSkipped: 80,
          bandwidthSaved: 163840,
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );
        await tester.pumpAndSettle();

        expect(find.text('Efficiency'), findsOneWidget);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Syncs'), findsOneWidget);
      });

      testWidgets('shows full sync warning when needed', (
        WidgetTester tester,
      ) async {
        // Simulate no full sync timestamp (needsFullSync = true)
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );

        expect(find.text('Full sync recommended (>7 days)'), findsOneWidget);
      });

      testWidgets('shows Full Sync button when full sync needed', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            onSyncTap: () {},
          ),
        );

        // Since needsFullSync is true by default (no lastFullSyncTime)
        expect(find.text('Full Sync'), findsOneWidget);
      });
    });

    group('Compact Mode', () {
      testWidgets('renders compact layout', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.compact),
        );

        expect(find.text('Sync'), findsOneWidget);
      });

      testWidgets('shows status badge', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.compact),
        );

        // Should show OUTDATED badge since no full sync
        expect(find.text('OUTDATED'), findsOneWidget);
      });

      testWidgets('shows OK badge when sync is up to date', (
        WidgetTester tester,
      ) async {
        // Set full sync timestamp to make needsFullSync = false
        await settingsProvider.recordFullSyncCompleted();

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.compact),
        );
        await tester.pumpAndSettle();

        expect(find.text('OK'), findsOneWidget);
      });

      testWidgets('shows DISABLED badge when disabled', (
        WidgetTester tester,
      ) async {
        // First record full sync to clear needsFullSync state
        // (otherwise OUTDATED takes precedence over DISABLED)
        await settingsProvider.recordFullSyncCompleted();
        await settingsProvider.setIncrementalSyncEnabled(false);

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.compact),
        );
        await tester.pumpAndSettle();

        expect(find.text('DISABLED'), findsOneWidget);
      });

      testWidgets('sync icon button triggers callback', (
        WidgetTester tester,
      ) async {
        bool syncTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.compact,
            onSyncTap: () => syncTapped = true,
          ),
        );

        await tester.tap(find.byIcon(Icons.sync).last);
        await tester.pumpAndSettle();

        expect(syncTapped, true);
      });
    });

    group('Mini Mode', () {
      testWidgets('renders mini icon', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.mini),
        );

        expect(find.byIcon(Icons.sync_problem), findsOneWidget);
      });

      testWidgets('tap triggers sync callback', (WidgetTester tester) async {
        bool syncTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.mini,
            onSyncTap: () => syncTapped = true,
          ),
        );

        await tester.tap(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(syncTapped, true);
      });
    });

    group('Syncing State', () {
      testWidgets('shows syncing indicator when isSyncing is true', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            isSyncing: true,
          ),
        );

        // Should show syncing status text
        expect(find.text('Syncing in progress...'), findsOneWidget);
      });

      testWidgets('shows SYNCING badge in compact mode', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.compact,
            isSyncing: true,
          ),
        );

        expect(find.text('SYNCING'), findsOneWidget);
      });

      testWidgets('shows progress with current progress event', (
        WidgetTester tester,
      ) async {
        final SyncProgressEvent progressEvent = SyncProgressEvent.progress(
          'transaction',
          50,
          10,
          40,
          total: 100,
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            isSyncing: true,
            currentProgress: progressEvent,
          ),
        );

        // Should show progress indicator and stats
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(find.text('Fetched'), findsOneWidget);
        expect(find.text('Updated'), findsOneWidget);
        expect(find.text('Skipped'), findsOneWidget);
      });

      testWidgets('updates with progress stream', (WidgetTester tester) async {
        final StreamController<SyncProgressEvent> streamController =
            StreamController<SyncProgressEvent>.broadcast();

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            isSyncing: true,
            progressStream: streamController.stream,
          ),
        );

        // Emit progress event
        streamController.add(
          SyncProgressEvent.progress('transaction', 25, 5, 20, total: 100),
        );
        await tester.pump();

        // Should update display
        expect(find.text('Transactions'), findsOneWidget);

        await streamController.close();
      });

      testWidgets('disables sync button when syncing', (
        WidgetTester tester,
      ) async {
        bool syncTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.compact,
            isSyncing: true,
            onSyncTap: () => syncTapped = true,
          ),
        );

        // Use pump() instead of pumpAndSettle() because of animation
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Sync button should be hidden or disabled when syncing
        // In compact mode, the sync button is replaced with progress
        // Try to find sync icon - it may not be tappable
        final Finder syncFinder = find.byIcon(Icons.sync);
        if (syncFinder.evaluate().isNotEmpty) {
          await tester.tap(syncFinder.last, warnIfMissed: false);
          await tester.pump();
        }

        // Should not have triggered since syncing
        expect(syncTapped, false);
      });
    });

    group('Status Messages', () {
      testWidgets('shows "Ready to sync" when enabled and no last sync', (
        WidgetTester tester,
      ) async {
        await settingsProvider.recordFullSyncCompleted();

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ready to sync'), findsOneWidget);
      });

      testWidgets('shows relative time since last sync', (
        WidgetTester tester,
      ) async {
        await settingsProvider.recordFullSyncCompleted();
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 10,
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );
        await tester.pumpAndSettle();

        // Should show "Last sync: Just now" or similar
        expect(find.textContaining('Last sync:'), findsOneWidget);
      });

      testWidgets('shows "Incremental sync disabled" when disabled', (
        WidgetTester tester,
      ) async {
        await settingsProvider.setIncrementalSyncEnabled(false);

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );
        await tester.pumpAndSettle();

        expect(find.text('Incremental sync disabled'), findsOneWidget);
      });

      testWidgets('shows "Full sync recommended" when needed', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncDashboardCardMode.standard),
        );

        expect(find.text('Full sync recommended'), findsOneWidget);
      });
    });

    group('Entity Type Formatting', () {
      testWidgets('formats transaction correctly', (WidgetTester tester) async {
        final SyncProgressEvent progressEvent = SyncProgressEvent.entityStarted(
          'transaction',
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            isSyncing: true,
            currentProgress: progressEvent,
          ),
        );

        expect(find.text('Syncing Transactions...'), findsOneWidget);
      });

      testWidgets('formats piggy_bank correctly', (WidgetTester tester) async {
        final SyncProgressEvent progressEvent = SyncProgressEvent.entityStarted(
          'piggy_bank',
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.standard,
            isSyncing: true,
            currentProgress: progressEvent,
          ),
        );

        expect(find.text('Syncing Piggy Banks...'), findsOneWidget);
      });
    });

    group('Long Press Actions', () {
      testWidgets('long press triggers settings callback in compact mode', (
        WidgetTester tester,
      ) async {
        bool settingsTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.compact,
            onSettingsTap: () => settingsTapped = true,
          ),
        );

        await tester.longPress(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(settingsTapped, true);
      });

      testWidgets('long press triggers settings callback in mini mode', (
        WidgetTester tester,
      ) async {
        bool settingsTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncDashboardCardMode.mini,
            onSettingsTap: () => settingsTapped = true,
          ),
        );

        await tester.longPress(find.byType(InkWell).first);
        await tester.pumpAndSettle();

        expect(settingsTapped, true);
      });
    });
  });
}
