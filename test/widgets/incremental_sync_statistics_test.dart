import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/models/incremental_sync_stats.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/widgets/incremental_sync_statistics.dart';

/// Mock SharedPreferences for testing.
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('IncrementalSyncStatisticsWidget', () {
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
      IncrementalSyncStatisticsMode mode = IncrementalSyncStatisticsMode.card,
      IncrementalSyncResult? liveResult,
      bool showHeader = true,
      VoidCallback? onRefresh,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<OfflineSettingsProvider>.value(
            value: settingsProvider,
            child: SingleChildScrollView(
              child: IncrementalSyncStatisticsWidget(
                mode: mode,
                liveResult: liveResult,
                showHeader: showHeader,
                onRefresh: onRefresh,
              ),
            ),
          ),
        ),
      );
    }

    group('Card Mode', () {
      testWidgets('renders empty state when no data', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.card),
        );

        expect(find.text('No Sync Statistics Yet'), findsOneWidget);
        expect(
          find.text(
            'Statistics will appear here after your first incremental sync.',
          ),
          findsOneWidget,
        );
      });

      testWidgets('renders header with title', (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            showHeader: true,
          ),
        );

        expect(find.text('Sync Statistics'), findsOneWidget);
      });

      testWidgets('hides header when showHeader is false', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            showHeader: false,
          ),
        );

        expect(find.text('Sync Statistics'), findsNothing);
      });

      testWidgets('renders refresh button when onRefresh provided', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            showHeader: true,
            onRefresh: () {},
          ),
        );

        expect(find.byIcon(Icons.refresh), findsOneWidget);
      });

      testWidgets('refresh button triggers callback', (
        WidgetTester tester,
      ) async {
        bool refreshTapped = false;

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            showHeader: true,
            onRefresh: () => refreshTapped = true,
          ),
        );

        await tester.tap(find.byIcon(Icons.refresh));
        await tester.pumpAndSettle();

        expect(refreshTapped, true);
      });

      testWidgets('renders statistics with live result', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 30),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 20,
              itemsSkipped: 80,
            ),
            'account': IncrementalSyncStats(
              entityType: 'account',
              itemsFetched: 10,
              itemsUpdated: 2,
              itemsSkipped: 8,
            ),
          },
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        // Should show main stats
        expect(find.text('Fetched'), findsOneWidget);
        expect(find.text('Updated'), findsOneWidget);
        expect(find.text('Skipped'), findsOneWidget);

        // Should show efficiency indicator
        expect(find.text('Excellent Efficiency'), findsOneWidget);

        // Should show live result details section
        expect(find.text('Current Sync'), findsOneWidget);
        expect(find.text('Duration: 30s'), findsOneWidget);
        expect(find.text('Status: Success'), findsOneWidget);
      });

      testWidgets('displays error when live result has error', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = const IncrementalSyncResult(
          isIncremental: true,
          success: false,
          duration: Duration(seconds: 5),
          statsByEntity: <String, IncrementalSyncStats>{},
          error: 'Network error occurred',
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        expect(find.text('Status: Failed'), findsOneWidget);
        expect(find.text('Error: Network error occurred'), findsOneWidget);
      });
    });

    group('Compact Mode', () {
      testWidgets('renders empty state when no data', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.compact),
        );

        expect(find.text('No incremental sync data yet'), findsOneWidget);
      });

      testWidgets('renders compact stats with data', (
        WidgetTester tester,
      ) async {
        // Set up some statistics
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 100,
          itemsUpdated: 20,
          itemsSkipped: 80,
          bandwidthSaved: 163840, // 160 KB
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.compact),
        );
        await tester.pumpAndSettle();

        // Should show compact stat items
        expect(find.text('Skipped'), findsOneWidget);
        expect(find.text('Saved'), findsOneWidget);
        expect(find.text('Syncs'), findsOneWidget);
      });
    });

    group('Summary Mode', () {
      testWidgets('renders no data message when empty', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.summary),
        );

        expect(find.text('No sync data available'), findsOneWidget);
      });

      testWidgets('renders summary with data', (WidgetTester tester) async {
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 100,
          itemsUpdated: 20,
          itemsSkipped: 80,
          bandwidthSaved: 163840,
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.summary),
        );
        await tester.pumpAndSettle();

        // Should show efficiency percentage and bandwidth saved
        expect(find.textContaining('efficient'), findsOneWidget);
        expect(find.byIcon(Icons.speed), findsOneWidget);
        expect(find.byIcon(Icons.data_saver_on), findsOneWidget);
      });
    });

    group('Efficiency Indicators', () {
      testWidgets('shows excellent efficiency for 80%+ skip rate', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 30),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 15,
              itemsSkipped: 85,
            ),
          },
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        expect(find.text('Excellent Efficiency'), findsOneWidget);
      });

      testWidgets('shows good efficiency for 60-79% skip rate', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 30),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 30,
              itemsSkipped: 70,
            ),
          },
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        expect(find.text('Good Efficiency'), findsOneWidget);
      });

      testWidgets('shows moderate efficiency for 40-59% skip rate', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 30),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 50,
              itemsSkipped: 50,
            ),
          },
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        expect(find.text('Moderate Efficiency'), findsOneWidget);
      });

      testWidgets('shows low efficiency for 20-39% skip rate', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 30),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 70,
              itemsSkipped: 30,
            ),
          },
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        expect(find.text('Low Efficiency'), findsOneWidget);
      });

      testWidgets('shows very low efficiency for <20% skip rate', (
        WidgetTester tester,
      ) async {
        final IncrementalSyncResult liveResult = IncrementalSyncResult(
          isIncremental: true,
          success: true,
          duration: const Duration(seconds: 30),
          statsByEntity: <String, IncrementalSyncStats>{
            'transaction': IncrementalSyncStats(
              entityType: 'transaction',
              itemsFetched: 100,
              itemsUpdated: 90,
              itemsSkipped: 10,
            ),
          },
        );

        await tester.pumpWidget(
          buildTestWidget(
            mode: IncrementalSyncStatisticsMode.card,
            liveResult: liveResult,
          ),
        );

        expect(find.text('Very Low Efficiency'), findsOneWidget);
      });
    });

    group('Bandwidth Formatting', () {
      testWidgets('formats bytes correctly', (WidgetTester tester) async {
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 1,
          bandwidthSaved: 512,
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.compact),
        );
        await tester.pumpAndSettle();

        expect(find.text('512 B'), findsOneWidget);
      });

      testWidgets('formats kilobytes correctly', (WidgetTester tester) async {
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 10,
          bandwidthSaved: 51200, // 50 KB
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.compact),
        );
        await tester.pumpAndSettle();

        expect(find.text('50.0 KB'), findsOneWidget);
      });

      testWidgets('formats megabytes correctly', (WidgetTester tester) async {
        await settingsProvider.updateIncrementalSyncStatistics(
          isIncremental: true,
          itemsFetched: 100,
          bandwidthSaved: 5242880, // 5 MB
        );

        await tester.pumpWidget(
          buildTestWidget(mode: IncrementalSyncStatisticsMode.compact),
        );
        await tester.pumpAndSettle();

        expect(find.text('5.0 MB'), findsOneWidget);
      });
    });
  });
}
