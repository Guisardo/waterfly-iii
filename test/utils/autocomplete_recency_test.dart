import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';
import 'package:waterflyiii/utils/autocomplete_recency.dart';

Transactions history(
  String id,
  String label,
  String created, {
  bool deleted = false,
}) => Transactions()
  ..transactionId = id
  ..localUpdatedAt = DateTime(2099)
  ..deletedAt = deleted ? DateTime(2026) : null
  ..data = jsonEncode(<String, dynamic>{
    'attributes': <String, dynamic>{
      'created_at': created,
      'transactions': <dynamic>[
        <String, dynamic>{
          'description': label,
          'source_name': label,
          'destination_name': label,
          'category_name': label,
          'budget_name': label,
          'bill_id': label,
          'currency_id': label,
          'foreign_currency_id': label,
          'piggy_bank_id': label,
          'tags': <String>[label],
        },
      ],
    },
  });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  test(
    'recent first, stable ties and unknowns, unchanged input and duplicates',
    () {
      final AutocompleteRecency r = AutocompleteRecency()
        ..remember('description', 'Zoo', 20)
        ..remember('description', 'Apple', 10)
        ..remember('description', 'banana', 10);
      final List<String> input = <String>[
        'unknown',
        'banana',
        'Apple',
        'Zoo',
        'Zoo',
      ];
      expect(r.sorted<String>('description', input, (String s) => s), <String>[
        'Zoo',
        'Zoo',
        'banana',
        'Apple',
        'unknown',
      ]);
      expect(input.first, 'unknown');
      expect(r.sorted<String>('unused', input, (String s) => s), input);
    },
  );
  test('exact text identities, not accent or case folding', () {
    final AutocompleteRecency r = AutocompleteRecency()
      ..remember('tag', 'Cafe', 1);
    expect(
      r.sorted<String>('tag', <String>[
        'cafe',
        'Caf\u00e9',
        'Cafe',
      ], (String s) => s),
      <String>['Cafe', 'cafe', 'Caf\u00e9'],
    );
  });
  test('history seeds all fields by creation, not sync receipt', () {
    final AutocompleteRecency r = AutocompleteRecency()
      ..seed(<Transactions>[
        history('1', 'old', '2025-01-01T00:00:00Z'),
        history('2', 'recent', '2026-01-01T00:00:00Z'),
        history('3', 'deleted', '2027-01-01T00:00:00Z', deleted: true),
        Transactions()
          ..transactionId = 'bad'
          ..data = 'invalid',
      ]);
    for (final String field in <String>[
      'description',
      'account',
      'category',
      'budget',
      'tag',
      'bill',
      'currency',
      'piggy',
    ]) {
      expect(
        r.sorted<String>(field, <String>[
          'old',
          'deleted',
          'recent',
        ], (String s) => s),
        <String>['recent', 'old', 'deleted'],
      );
    }
  });
  test('pending offline history uses local save timestamp', () {
    final Transactions row = Transactions()
      ..transactionId = 'pending-1'
      ..localUpdatedAt = DateTime(2026)
      ..data = jsonEncode(<String, dynamic>{
        'transactions': <dynamic>[
          <String, dynamic>{'description': 'offline'},
        ],
      });
    final AutocompleteRecency r = AutocompleteRecency()
      ..seed(<Transactions>[row]);
    expect(
      r.sorted<String>('description', <String>[
        'other',
        'offline',
      ], (String s) => s),
      <String>['offline', 'other'],
    );
  });
  test(
    'successful-save recency persists across new instances and fields stay separate',
    () async {
      await AutocompleteRecency.record(<String, List<String>>{
        'description': <String>['Zoo'],
      });
      await AutocompleteRecency.record(<String, List<String>>{
        'description': <String>['Apple'],
      });
      final AutocompleteRecency r = await AutocompleteRecency.load(
        history: <Transactions>[],
      );
      expect(
        r.sorted<String>('description', <String>[
          'Zoo',
          'Apple',
        ], (String s) => s),
        <String>['Apple', 'Zoo'],
      );
      expect(
        r.sorted<String>('tag', <String>['Zoo', 'Apple'], (String s) => s),
        <String>['Zoo', 'Apple'],
      );
    },
  );
  test(
    'empty values and sentinel IDs are not ranked; empty options supported',
    () {
      final AutocompleteRecency r = AutocompleteRecency()
        ..remember('bill', '0', 99)
        ..remember('bill', '', 99);
      expect(
        r.sorted<String>('bill', <String>['x', '0'], (String s) => s),
        <String>['x', '0'],
      );
      expect(r.sorted<String>('bill', <String>[], (String s) => s), isEmpty);
    },
  );
  test('corrupt preferences recover and can be recorded again', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      AutocompleteRecency.preferenceKey: 'bad json',
    });
    await AutocompleteRecency.record(<String, List<String>>{
      'tag': <String>['saved'],
    });
    final AutocompleteRecency r = await AutocompleteRecency.load(
      history: <Transactions>[],
    );
    expect(
      r.sorted<String>('tag', <String>['other', 'saved'], (String s) => s),
      <String>['saved', 'other'],
    );
  });
}
