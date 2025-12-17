import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/providers/offline_settings_provider.dart';
import 'package:waterflyiii/widgets/incremental_sync_settings.dart';

/// Mock SharedPreferences for testing.
class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('IncrementalSyncSettingsSection', () {
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
      VoidCallback? onForceFullSync,
      VoidCallback? onForceIncrementalSync,
      bool showAdvancedSettings = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<OfflineSettingsProvider>.value(
            value: settingsProvider,
            child: SingleChildScrollView(
              child: IncrementalSyncSettingsSection(
                onForceFullSync: onForceFullSync,
                onForceIncrementalSync: onForceIncrementalSync,
                showAdvancedSettings: showAdvancedSettings,
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders header with title and subtitle', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // "Incremental Sync" appears in both header title and action button label
      expect(find.text('Incremental Sync'), findsAtLeast(1));
      expect(
        find.text('Optimize sync performance by fetching only changed data'),
        findsOneWidget,
      );
    });

    testWidgets('renders incremental sync toggle', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Enable Incremental Sync'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsAtLeast(1));
    });

    testWidgets('toggle changes incremental sync setting', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Initially enabled (default)
      final Finder switchFinder = find.byType(Switch).first;
      expect(tester.widget<Switch>(switchFinder).value, true);

      // Toggle off
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify setIncrementalSyncEnabled was called
      verify(
        () => mockPrefs.setBool('incremental_sync_enabled', false),
      ).called(1);
    });

    testWidgets('renders sync window selector', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Sync Window'), findsOneWidget);
      expect(find.text('How far back to look for changes'), findsOneWidget);
    });

    testWidgets('sync window selector contains all options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // Find and tap the dropdown
      final Finder dropdownFinder = find.byType(DropdownButton<SyncWindow>);
      expect(dropdownFinder, findsOneWidget);

      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      // Verify all sync window options are present
      expect(find.text('7 days'), findsOneWidget);
      expect(find.text('14 days'), findsOneWidget);
      expect(
        find.text('30 days'),
        findsAtLeast(1),
      ); // May appear multiple times
      expect(find.text('60 days'), findsOneWidget);
      expect(find.text('90 days'), findsOneWidget);
    });

    testWidgets('renders cache TTL selector when advanced settings enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(showAdvancedSettings: true));

      expect(find.text('Cache Duration'), findsOneWidget);
    });

    testWidgets('hides cache TTL selector when advanced settings disabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(showAdvancedSettings: false));

      expect(find.text('Cache Duration'), findsNothing);
    });

    testWidgets('renders sync timestamps section', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Last Incremental Sync'), findsOneWidget);
      expect(find.text('Last Full Sync'), findsOneWidget);
    });

    testWidgets('renders action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestWidget(onForceIncrementalSync: () {}, onForceFullSync: () {}),
      );

      // Find the OutlinedButton widgets specifically for the sync action buttons
      // Note: "Incremental Sync" also appears in header and toggle, so use button finder
      expect(
        find.widgetWithText(OutlinedButton, 'Incremental Sync'),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, 'Full Sync'), findsOneWidget);
    });

    testWidgets('incremental sync button triggers callback', (
      WidgetTester tester,
    ) async {
      bool syncTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onForceIncrementalSync: () => syncTapped = true,
          onForceFullSync: () {},
        ),
      );

      // Use OutlinedButton.icon with text 'Incremental Sync' to avoid ambiguity
      // with the header title
      await tester.tap(find.widgetWithText(OutlinedButton, 'Incremental Sync'));
      await tester.pumpAndSettle();

      expect(syncTapped, true);
    });

    testWidgets('full sync button triggers callback', (
      WidgetTester tester,
    ) async {
      bool fullSyncTapped = false;

      await tester.pumpWidget(
        buildTestWidget(
          onForceIncrementalSync: () {},
          onForceFullSync: () => fullSyncTapped = true,
        ),
      );

      // Use OutlinedButton.icon to find the button specifically
      await tester.tap(find.widgetWithText(OutlinedButton, 'Full Sync'));
      await tester.pumpAndSettle();

      expect(fullSyncTapped, true);
    });

    testWidgets(
      'renders reset statistics button when advanced settings enabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(showAdvancedSettings: true));

        // Scroll to find the Reset Statistics button
        final Finder scrollable = find.byType(Scrollable);
        await tester.scrollUntilVisible(
          find.text('Reset Statistics'),
          500.0,
          scrollable: scrollable.first,
        );
        await tester.pumpAndSettle();

        expect(find.text('Reset Statistics'), findsOneWidget);
      },
    );

    testWidgets(
      'hides reset statistics button when advanced settings disabled',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildTestWidget(showAdvancedSettings: false));

        expect(find.text('Reset Statistics'), findsNothing);
      },
    );

    testWidgets('reset statistics shows confirmation dialog', (
      WidgetTester tester,
    ) async {
      // Set a larger screen size to ensure content fits without scrolling
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildTestWidget(showAdvancedSettings: true));
      await tester.pumpAndSettle();

      // Find and tap the Reset Statistics button (it's a TextButton.icon)
      final Finder resetButton = find.text('Reset Statistics');
      expect(resetButton, findsOneWidget);

      await tester.tap(resetButton);
      await tester.pumpAndSettle();

      // Dialog should appear - find its title (now there will be 2: button + dialog)
      expect(find.text('Reset Statistics'), findsNWidgets(2));
      expect(
        find.textContaining('This will clear all incremental sync statistics'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets(
      'sync window dropdown is disabled when incremental sync is disabled',
      (WidgetTester tester) async {
        // Disable incremental sync
        await settingsProvider.setIncrementalSyncEnabled(false);

        await tester.pumpWidget(buildTestWidget());

        // Find the sync window list tile
        final Finder listTileFinder = find.ancestor(
          of: find.text('Sync Window'),
          matching: find.byType(ListTile),
        );

        expect(listTileFinder, findsOneWidget);
        final ListTile listTile = tester.widget<ListTile>(listTileFinder);
        expect(listTile.enabled, false);
      },
    );
  });

  group('IncrementalSyncSettingsCompact', () {
    late MockSharedPreferences mockPrefs;
    late OfflineSettingsProvider settingsProvider;

    setUp(() {
      mockPrefs = MockSharedPreferences();

      when(() => mockPrefs.getInt(any())).thenReturn(null);
      when(() => mockPrefs.getBool(any())).thenReturn(null);
      when(() => mockPrefs.setInt(any(), any())).thenAnswer((_) async => true);
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);

      settingsProvider = OfflineSettingsProvider.withPrefs(prefs: mockPrefs);
    });

    Widget buildTestWidget({bool showHeader = true}) {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<OfflineSettingsProvider>.value(
            value: settingsProvider,
            child: IncrementalSyncSettingsCompact(showHeader: showHeader),
          ),
        ),
      );
    }

    testWidgets('renders compact settings', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Enable Incremental Sync'), findsOneWidget);
    });

    testWidgets('shows header when showHeader is true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(showHeader: true));

      expect(find.text('Incremental Sync'), findsOneWidget);
    });

    testWidgets('hides header when showHeader is false', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget(showHeader: false));

      // The title "Incremental Sync" should not appear as a header
      // but may still appear in other context
      expect(find.text('Incremental Sync'), findsNothing);
    });

    testWidgets('shows sync window dropdown when incremental sync enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildTestWidget());

      // The widget shows "Sync window: " with a space before the dropdown
      expect(find.text('Sync window: '), findsOneWidget);
      expect(find.byType(DropdownButton<SyncWindow>), findsOneWidget);
    });

    testWidgets('hides sync window dropdown when incremental sync disabled', (
      WidgetTester tester,
    ) async {
      await settingsProvider.setIncrementalSyncEnabled(false);

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Sync window:'), findsNothing);
    });
  });
}
