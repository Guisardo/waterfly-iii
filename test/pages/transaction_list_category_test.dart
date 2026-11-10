import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/pages/home/transactions.dart';

void main() {
  group('transaction list category visibility', () {
    test('exact destination match is omitted', () {
      expect(transactionListShowsCategory('Market', 'Market'), isFalse);
    });
    test('different category remains visible', () {
      expect(transactionListShowsCategory('Food', 'Market'), isTrue);
    });
    test('missing and empty categories are omitted', () {
      expect(transactionListShowsCategory(null, 'Market'), isFalse);
      expect(transactionListShowsCategory('', 'Market'), isFalse);
      expect(transactionListShowsCategory(null, null), isFalse);
    });
    test('comparison is exact, not case or whitespace normalized', () {
      expect(transactionListShowsCategory('market', 'Market'), isTrue);
      expect(transactionListShowsCategory('Market ', 'Market'), isTrue);
    });
    test('missing destination preserves nonempty category', () {
      expect(transactionListShowsCategory('Food', null), isTrue);
      expect(transactionListShowsCategory('Food', ''), isTrue);
    });
    test('split categories are filtered before counting', () {
      final List<(String?, String?)> splits = <(String?, String?)>[
        ('Market', 'Market'),
        ('Food', 'Cafe'),
        ('Cafe', 'Cafe'),
      ];
      final List<String?> visible = splits
          .where(
            ((String?, String?) split) =>
                transactionListShowsCategory(split.$1, split.$2),
          )
          .map(((String?, String?) split) => split.$1)
          .toList();
      expect(visible, <String>['Food']);
    });
    test('all redundant split categories disappear', () {
      expect(
        <(String, String)>[('Market', 'Market'), ('Cafe', 'Cafe')].any(
          ((String, String) split) =>
              transactionListShowsCategory(split.$1, split.$2),
        ),
        isFalse,
      );
    });
  });
}
