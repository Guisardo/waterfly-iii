import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/utils/autocomplete_sort.dart';

void main() {
  test('case and composed/decomposed accents compare equally', () {
    expect(compareAutocompleteLabels('\u00c1RBOL', 'arbol'), 0);
    expect(compareAutocompleteLabels('Cafe\u0301', 'CAF\u00c9'), 0);
    expect(compareAutocompleteLabels('NI\u00d1O', 'nino'), 0);
    expect(compareAutocompleteLabels('\u00dcber', 'uber'), 0);
  });
  test('alphabetical order, stable ties and unchanged input', () {
    final List<String> input = <String>[
      'Zoo',
      '\u00e9clair',
      'Apple',
      '\u00c9clair',
      'apple',
      'banana',
    ];
    final List<String> before = List<String>.of(input);
    expect(sortedAutocompleteOptions(input, (String s) => s), <String>[
      'Apple',
      'apple',
      'banana',
      '\u00e9clair',
      '\u00c9clair',
      'Zoo',
    ]);
    expect(input, before);
  });
  test('preserves object identity and duplicates', () {
    final Object a = Object();
    final Object b = Object();
    final Map<Object, String> labels = <Object, String>{a: '\u00e1', b: 'A'};
    final List<Object> result = sortedAutocompleteOptions(<Object>[
      a,
      b,
      a,
    ], (Object o) => labels[o]!);
    expect(result, <Object>[a, b, a]);
    expect(identical(result.first, a), isTrue);
  });
  test('empty and single options', () {
    expect(sortedAutocompleteOptions(<String>[], (String s) => s), isEmpty);
    expect(
      sortedAutocompleteOptions(<String>['Only'], (String s) => s),
      <String>['Only'],
    );
  });
  test('preserves emoji variation selectors and non-Latin text', () {
    expect(autocompleteSortKey('\u2764\ufe0f'), '\u2764\ufe0f');
    expect(autocompleteSortKey('\u4e2d\u6587'), '\u4e2d\u6587');
  });
}
