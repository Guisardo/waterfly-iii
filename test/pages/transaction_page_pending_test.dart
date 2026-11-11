import 'dart:convert';
import 'package:waterflyiii/utils/autocomplete_recency.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:waterflyiii/auth.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/data/local/database/tables/pending_changes.dart';
import 'package:waterflyiii/data/repositories/transaction_repository.dart';
import 'package:waterflyiii/generated/l10n/app_localizations.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.enums.swagger.dart';
import 'package:waterflyiii/generated/swagger_fireflyiii_api/firefly_iii.models.swagger.dart';
import 'package:waterflyiii/pages/transaction.dart';
import 'package:waterflyiii/settings.dart';
import 'package:waterflyiii/timezonehandler.dart';
import 'package:waterflyiii/widgets/number_keyboard.dart';

import '../helpers/test_database.dart';

Future<PendingChanges?> _pendingCreateFor(Isar isar, String pendingId) async {
  final List<PendingChanges> changes = await isar.pendingChanges
      .where()
      .findAll();
  for (final PendingChanges change in changes) {
    if (change.entityType == 'transactions' &&
        change.operation == PendingChangeOperation.create.name &&
        !change.synced &&
        change.localPendingId == pendingId) {
      return change;
    }
  }
  return null;
}

void main() {
  late Isar isar;
  late TransactionRepository repository;
  late FireflyService fireflyService;
  const MethodChannel timezoneChannel = MethodChannel('flutter_timezone');

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, (MethodCall call) async {
          if (call.method == 'getLocalTimezone') {
            return 'UTC';
          }
          return <String>[];
        });
    tzdata.initializeTimeZones();
    isar = await TestDatabase.instance;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'recency_test_sentinel': 'keep',
    });
    await TestDatabase.clear();
    AppDatabase.setTestInstance(isar);
    repository = TransactionRepository(isar);
    fireflyService = FireflyService()
      ..defaultCurrency = const CurrencyRead(
        type: 'currencies',
        id: '1',
        attributes: CurrencyProperties(
          code: 'USD',
          name: 'US Dollar',
          symbol: r'$',
          decimalPlaces: 2,
        ),
      )
      ..tzHandler = TimeZoneHandler('UTC');
  });

  tearDown(() {
    AppDatabase.resetForTesting();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(timezoneChannel, null);
    await TestDatabase.close();
  });

  testWidgets(
    'new transaction initially focuses amount and opens math keyboard',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: <SingleChildWidget>[
            ChangeNotifierProvider<FireflyService>.value(value: fireflyService),
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            home: TransactionPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final EditableText amount = tester.widget<EditableText>(
        find.byType(EditableText).first,
      );
      expect(amount.focusNode.hasFocus, isTrue);
      expect(find.byType(NumberKeyboard), findsOneWidget);
      final Finder title = find.descendant(
        of: find.byType(TransactionTitle).first,
        matching: find.byType(EditableText),
      );
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(title).focusNode.hasFocus, isTrue);
      expect(find.byType(NumberKeyboard), findsNothing);
      await tester.runAsync(() async {
        await AutocompleteRecency.load();
      });
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pending transaction opens and saves through edit page', (
    WidgetTester tester,
  ) async {
    final String pendingId = await repository.createNew(
      TransactionStore(
        transactions: <TransactionSplitStore>[
          TransactionSplitStore(
            type: TransactionTypeProperty.withdrawal,
            date: DateTime(2026, 5, 1, 12, 30),
            amount: '12.34',
            description: 'Pending widget original',
            currencyId: '1',
            currencyCode: 'USD',
            sourceId: 'asset-1',
            sourceName: 'Checking',
            destinationName: 'Market',
            categoryName: 'Groceries',
            notes: 'widget note',
            tags: <String>['widget'],
          ),
        ],
        applyRules: true,
        fireWebhooks: true,
        errorIfDuplicateHash: true,
      ),
    );
    final TransactionRead? pendingTransaction = await repository.getById(
      pendingId,
    );
    expect(pendingTransaction, isNotNull);

    await tester.pumpWidget(
      MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<FireflyService>.value(value: fireflyService),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: S.localizationsDelegates,
          supportedLocales: S.supportedLocales,
          home: Builder(
            builder: (BuildContext context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              TransactionPage(transaction: pendingTransaction),
                        ),
                      );
                    },
                    child: const Text('open pending'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('open pending'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Edit Transaction'), findsOneWidget);
    expect(find.text('Pending widget original'), findsWidgets);
    final Finder amountField = find.byType(EditableText).first;
    final Finder titleField = find.descendant(
      of: find.byType(TransactionTitle).first,
      matching: find.byType(EditableText),
    );
    expect(tester.widget<EditableText>(amountField).controller.text, '12.34');
    expect(tester.widget<EditableText>(amountField).focusNode.hasFocus, isTrue);
    expect(tester.widget<EditableText>(titleField).focusNode.hasFocus, isFalse);
    expect(find.byType(NumberKeyboard), findsOneWidget);
    expect(
      tester.getTopLeft(amountField).dy,
      lessThan(tester.getTopLeft(titleField).dy),
    );

    await tester.runAsync(() async {
      await AutocompleteRecency.load();
    });
    await tester.enterText(
      find.descendant(
        of: find.byType(TransactionTitle).first,
        matching: find.byType(EditableText),
      ),
      'Pending widget edited',
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      final Stopwatch deadline = Stopwatch()..start();
      while (true) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        if (prefs
                .getString(AutocompleteRecency.preferenceKey)
                ?.contains('Pending widget edited') ??
            false) {
          break;
        }
        if (deadline.elapsed > const Duration(seconds: 5)) {
          throw StateError(
            'Saved recency did not complete within five seconds',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final PendingChanges? pendingCreate = await _pendingCreateFor(
      isar,
      pendingId,
    );
    expect(pendingCreate, isNotNull);
    final TransactionStore queuedStore = TransactionStore.fromJson(
      jsonDecode(pendingCreate!.data!) as Map<String, dynamic>,
    );
    expect(queuedStore.transactions.first.description, 'Pending widget edited');
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('recency_test_sentinel'), 'keep');
    expect(fireflyService.hasApi, isFalse);
    final AutocompleteRecency recent = await AutocompleteRecency.load(
      history: const <Transactions>[],
    );
    expect(
      recent.sorted<String>('description', <String>[
        'unused',
        'Pending widget edited',
      ], (String s) => s).first,
      'Pending widget edited',
    );
  });
}
