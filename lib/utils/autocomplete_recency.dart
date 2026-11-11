import 'dart:convert';

import 'package:isar_community/isar.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waterflyiii/data/local/database/app_database.dart';
import 'package:waterflyiii/data/local/database/tables/transactions.dart';

/// Local successful-save recency, with historical creation times as a seed.
/// Exact text keys deliberately do not merge distinct case/accent variants.
class AutocompleteRecency {
  AutocompleteRecency();

  static const String preferenceKey = 'transaction_autocomplete_recency_v1';
  static final Logger _log = Logger('Autocomplete.Recency');
  final Map<String, Map<String, int>> _used = <String, Map<String, int>>{};

  void remember(String field, String? value, int stamp) {
    if (value == null ||
        value.trim().isEmpty ||
        (value == '0' &&
            <String>['bill', 'piggy', 'currency'].contains(field))) {
      return;
    }
    final Map<String, int> values = _used.putIfAbsent(
      field,
      () => <String, int>{},
    );
    if (stamp > (values[value] ?? -1)) values[value] = stamp;
  }

  List<T> sorted<T>(String field, Iterable<T> options, String Function(T) key) {
    final List<T> input = options.toList();
    final List<int> indices = List<int>.generate(input.length, (int i) => i);
    indices.sort((int a, int b) {
      final int comparison = (_used[field]?[key(input[b])] ?? -1).compareTo(
        _used[field]?[key(input[a])] ?? -1,
      );
      return comparison != 0 ? comparison : a.compareTo(b);
    });
    return indices.map((int i) => input[i]).toList();
  }

  /// Sync receipt times and updated_at are not evidence of item use.
  void seed(Iterable<Transactions> rows) {
    for (final Transactions row in rows) {
      if (row.deletedAt != null) continue;
      try {
        final Map<String, dynamic> data =
            jsonDecode(row.data) as Map<String, dynamic>;
        final bool pending = row.transactionId.startsWith('pending-');
        final Map<String, dynamic> attributes = pending
            ? data
            : data['attributes'] as Map<String, dynamic>;
        final DateTime? time = pending
            ? row.localUpdatedAt
            : DateTime.tryParse(attributes['created_at']?.toString() ?? '');
        if (time == null) continue;
        final int stamp = time.microsecondsSinceEpoch;
        remember('description', attributes['group_title'] as String?, stamp);
        for (final dynamic item
            in attributes['transactions'] as List<dynamic>) {
          final Map<String, dynamic> split = item as Map<String, dynamic>;
          for (final String name in <String>[
            'description',
            'category',
            'budget',
          ]) {
            remember(
              name,
              split[name == 'description' ? name : '${name}_name'] as String?,
              stamp,
            );
          }
          remember('account', split['source_name'] as String?, stamp);
          remember('account', split['destination_name'] as String?, stamp);
          for (final String name in <String>[
            'bill',
            'currency',
            'foreign_currency',
            'piggy_bank',
          ]) {
            final String field = name == 'foreign_currency'
                ? 'currency'
                : name == 'piggy_bank'
                ? 'piggy'
                : name;
            remember(field, split['${name}_id']?.toString(), stamp);
          }
          for (final dynamic tag
              in (split['tags'] as List<dynamic>?) ?? <dynamic>[]) {
            if (tag is String) remember('tag', tag, stamp);
          }
        }
      } catch (_) {
        // One malformed historical row must not hide otherwise valid options.
        continue;
      }
    }
  }

  void _restore(String? raw) {
    if (raw == null) return;
    try {
      final Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      for (final MapEntry<String, dynamic> field in data.entries) {
        if (field.value is! Map<String, dynamic>) continue;
        final Map<String, dynamic> values = field.value as Map<String, dynamic>;
        for (final MapEntry<String, dynamic> entry in values.entries) {
          if (entry.value is int) {
            remember(field.key, entry.key, entry.value as int);
          }
        }
      }
    } catch (_) {
      // Corrupt optional preferences do not prevent autocomplete or saving.
    }
  }

  static Future<AutocompleteRecency> load({
    Iterable<Transactions>? history,
  }) async {
    final AutocompleteRecency result = AutocompleteRecency();
    try {
      final Iterable<Transactions> rows;
      if (history != null) {
        rows = history;
      } else {
        final Isar isar = await AppDatabase.instance;
        rows = await isar.transactions.where().findAll();
      }
      result.seed(rows);
    } catch (error, stack) {
      _log.warning('Could not seed suggestion history', error, stack);
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      result._restore(prefs.getString(preferenceKey));
    } catch (error, stack) {
      _log.warning('Could not read suggestion recency', error, stack);
    }
    return result;
  }

  /// Called only after the transaction's local persistence succeeded.
  /// No transaction/schema/sync data is modified here.
  static Future<void> record(Map<String, List<String>> fields) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final AutocompleteRecency result = AutocompleteRecency()
      .._restore(prefs.getString(preferenceKey));
    int stamp = DateTime.now().microsecondsSinceEpoch;
    for (final Map<String, int> values in result._used.values) {
      for (final int previous in values.values) {
        if (previous >= stamp) stamp = previous + 1;
      }
    }
    for (final MapEntry<String, List<String>> field in fields.entries) {
      for (final String value in field.value) {
        result.remember(field.key, value, stamp);
      }
    }
    if (!await prefs.setString(preferenceKey, jsonEncode(result._used))) {
      throw StateError('Could not persist suggestion recency');
    }
  }
}
