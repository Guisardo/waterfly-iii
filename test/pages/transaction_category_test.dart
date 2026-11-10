import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/pages/transaction.dart';

void main() {
  group('transaction category editor', () {
    test('missing category stays empty', () {
      expect(transactionCategoryForDialog(null, 'Market'), '');
      expect(transactionCategoryForDialog('', 'Market'), '');
    });
    test('matching category is hidden', () {
      expect(transactionCategoryForDialog('Market', 'Market'), '');
    });
    test('different category remains visible with exact matching', () {
      expect(transactionCategoryForDialog('Food', 'Market'), 'Food');
      expect(transactionCategoryForDialog('market', 'Market'), 'market');
      expect(transactionCategoryForDialog('Market ', 'Market'), 'Market ');
    });
    test('missing destination preserves explicit category', () {
      expect(transactionCategoryForDialog('Food', null), 'Food');
      expect(transactionCategoryForDialog(null, null), '');
    });
    test('blank category falls back to destination', () {
      expect(transactionCategoryForSave('', 'Market'), 'Market');
      expect(transactionCategoryForSave('  ', 'Market'), 'Market');
      expect(transactionCategoryForSave('', ''), '');
    });
    test('explicit category is preserved', () {
      expect(transactionCategoryForSave('Food', 'Market'), 'Food');
    });
    test('hidden category follows changed destination', () {
      final String displayed = transactionCategoryForDialog('Market', 'Market');
      expect(transactionCategoryForSave(displayed, 'Cafe'), 'Cafe');
    });
    test('splits resolve independently', () {
      expect(transactionCategoryForSave('', 'Market'), 'Market');
      expect(transactionCategoryForSave('', 'Cafe'), 'Cafe');
      expect(transactionCategoryForSave('Food', 'Cafe'), 'Food');
    });
  });
}
