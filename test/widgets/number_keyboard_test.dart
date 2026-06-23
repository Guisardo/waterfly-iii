import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/widgets/number_keyboard.dart';

void main() {
  group('NumberKeyboard widget', () {
    /// Pumps a [NumberKeyboard] with stub callbacks and returns the captured
    /// values for verification.
    Future<_Captures> pumpKeyboard(
      WidgetTester tester, {
      bool hasDecimal = true,
    }) async {
      final _Captures captures = _Captures();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberKeyboard(
              hasDecimal: hasDecimal,
              onKey: (String value) => captures.keys.add(value),
              onBackspace: () => captures.backspaceTaps++,
              onClear: () => captures.clearTaps++,
              onEquals: () => captures.equalsTaps++,
              onPercent: () => captures.percentTaps++,
            ),
          ),
        ),
      );
      return captures;
    }

    testWidgets('- renders digit keys 0–9', (WidgetTester tester) async {
      await pumpKeyboard(tester);
      for (final String digit in <String>[
        '0',
        '1',
        '2',
        '3',
        '4',
        '5',
        '6',
        '7',
        '8',
        '9',
      ]) {
        expect(
          find.widgetWithText(FilledButton, digit),
          findsWidgets,
          reason: 'Digit key "$digit" should be present',
        );
      }
    });

    testWidgets('- digit key fires onKey with correct value', (
      WidgetTester tester,
    ) async {
      final _Captures captures = await pumpKeyboard(tester);

      await tester.tap(find.widgetWithText(FilledButton, '7').first);
      await tester.pump();
      expect(captures.keys, <String>['7']);

      await tester.tap(find.widgetWithText(FilledButton, '0').first);
      await tester.pump();
      expect(captures.keys, <String>['7', '0']);
    });

    testWidgets('- operator keys fire onKey with ASCII operators', (
      WidgetTester tester,
    ) async {
      final _Captures captures = await pumpKeyboard(tester);

      // The keyboard shows display labels but passes ASCII values to onKey.
      // ÷ → '/', × → '*', − → '-', + → '+'
      await tester.tap(find.widgetWithText(FilledButton, '÷').first);
      await tester.pump();
      expect(captures.keys.last, '/');

      await tester.tap(find.widgetWithText(FilledButton, '×').first);
      await tester.pump();
      expect(captures.keys.last, '*');

      await tester.tap(find.widgetWithText(FilledButton, '−').first);
      await tester.pump();
      expect(captures.keys.last, '-');

      await tester.tap(find.widgetWithText(FilledButton, '+').first);
      await tester.pump();
      expect(captures.keys.last, '+');
    });

    testWidgets('- backspace key fires onBackspace', (
      WidgetTester tester,
    ) async {
      final _Captures captures = await pumpKeyboard(tester);
      expect(captures.backspaceTaps, 0);

      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();
      expect(captures.backspaceTaps, 1);
    });

    testWidgets('- C key fires onClear', (WidgetTester tester) async {
      final _Captures captures = await pumpKeyboard(tester);
      expect(captures.clearTaps, 0);

      await tester.tap(find.widgetWithText(FilledButton, 'C').first);
      await tester.pump();
      expect(captures.clearTaps, 1);
    });

    testWidgets('- = key fires onEquals', (WidgetTester tester) async {
      final _Captures captures = await pumpKeyboard(tester);
      expect(captures.equalsTaps, 0);

      await tester.tap(find.widgetWithText(FilledButton, '=').first);
      await tester.pump();
      expect(captures.equalsTaps, 1);
    });

    testWidgets('- % key fires onPercent', (WidgetTester tester) async {
      final _Captures captures = await pumpKeyboard(tester);
      expect(captures.percentTaps, 0);

      await tester.tap(find.widgetWithText(FilledButton, '%').first);
      await tester.pump();
      expect(captures.percentTaps, 1);
    });

    testWidgets('- shows decimal key when hasDecimal is true', (
      WidgetTester tester,
    ) async {
      await pumpKeyboard(tester, hasDecimal: true);
      expect(find.widgetWithText(FilledButton, '.'), findsOneWidget);
    });

    testWidgets('- hides decimal key when hasDecimal is false', (
      WidgetTester tester,
    ) async {
      await pumpKeyboard(tester, hasDecimal: false);
      expect(find.widgetWithText(FilledButton, '.'), findsNothing);
    });

    testWidgets('- decimal key fires onKey with "."', (
      WidgetTester tester,
    ) async {
      final _Captures captures = await pumpKeyboard(tester, hasDecimal: true);

      await tester.tap(find.widgetWithText(FilledButton, '.').first);
      await tester.pump();
      expect(captures.keys, <String>['.']);
    });
  });
}

/// Collects callback invocations during a test.
class _Captures {
  final List<String> keys = <String>[];
  int backspaceTaps = 0;
  int clearTaps = 0;
  int equalsTaps = 0;
  int percentTaps = 0;
}
