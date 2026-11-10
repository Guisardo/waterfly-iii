/// The sync settings must show the state of the insights refresh like they
/// show it for the entities, since it runs separately from the download.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:waterflyiii/data/local/database/tables/sync_metadata.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/pages/settings/sync.dart';
import 'package:waterflyiii/services/sync/sync_status_provider.dart';
import 'package:waterflyiii/settings.dart';

class _FakeSyncStatusProvider extends SyncStatusProvider {
  _FakeSyncStatusProvider({
    this.refreshing = false,
    this.current = 0,
    this.total = 0,
    this.stale = 0,
    Map<String, SyncMetadata>? metadata,
  }) : _metadata = metadata ?? <String, SyncMetadata>{};

  final bool refreshing;
  final int current;
  final int total;
  final int stale;
  final Map<String, SyncMetadata> _metadata;

  @override
  bool get isRefreshingInsights => refreshing;

  @override
  int get insightsRefreshCurrent => current;

  @override
  int get insightsRefreshTotal => total;

  @override
  int get staleInsightsCount => stale;

  @override
  Map<String, SyncMetadata> get entityMetadata => _metadata;

  @override
  Future<void> refreshMetadata() async {}
}

Future<void> _pumpPage(
  WidgetTester tester,
  SyncStatusProvider syncStatus,
) async {
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<SettingsProvider>.value(
          value: SettingsProvider(),
        ),
        ChangeNotifierProvider<SyncStatusProvider>.value(value: syncStatus),
      ],
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: SyncSettingsPage(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('lists insights with a localized name', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakeSyncStatusProvider());

    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('insights'), findsNothing);
  });

  testWidgets('shows the progress while insights are refreshing', (
    WidgetTester tester,
  ) async {
    await _pumpPage(
      tester,
      _FakeSyncStatusProvider(refreshing: true, current: 3, total: 50),
    );

    expect(find.text('3 of 50'), findsOneWidget);
  });

  testWidgets('shows how many insights are waiting to refresh', (
    WidgetTester tester,
  ) async {
    await _pumpPage(tester, _FakeSyncStatusProvider(stale: 6743));

    expect(find.text('6743 waiting to refresh'), findsOneWidget);
  });

  testWidgets('shows the last refresh and the error of the insights', (
    WidgetTester tester,
  ) async {
    final SyncMetadata insights = SyncMetadata()
      ..entityType = 'insights'
      ..lastDownloadSync = DateTime.utc(2026, 11, 10, 19, 24)
      ..lastError = '2 of 50 insights failed to refresh';
    await _pumpPage(
      tester,
      _FakeSyncStatusProvider(
        metadata: <String, SyncMetadata>{'insights': insights},
      ),
    );

    expect(
      find.textContaining('2 of 50 insights failed to refresh'),
      findsOneWidget,
    );
    expect(find.textContaining('Last sync'), findsWidgets);
  });
}
