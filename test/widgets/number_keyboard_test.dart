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

    testWidgets('- layout puts backspace above equals and C % × ÷ on top', (
      WidgetTester tester,
    ) async {
      await pumpKeyboard(tester);

      Rect rectOfText(String label) =>
          tester.getRect(find.widgetWithText(FilledButton, label));

      final Rect backspace = tester.getRect(
        find.widgetWithIcon(FilledButton, Icons.backspace_outlined),
      );
      final Rect confirm = rectOfText('=');
      final Rect plus = rectOfText('+');
      final Rect three = rectOfText('3');

      // Top row, left to right: C % × ÷
      final List<Rect> top = <String>[
        'C',
        '%',
        '×',
        '÷',
      ].map(rectOfText).toList();
      for (int i = 1; i < top.length; i++) {
        expect(top[i].left, greaterThan(top[i - 1].left));
        expect(top[i].center.dy, closeTo(top[0].center.dy, 0.5));
      }

      // Backspace: right of 3, directly above the right half of =.
      expect(backspace.center.dy, closeTo(three.center.dy, 0.5));
      expect(backspace.left, greaterThan(three.right));
      expect(backspace.right, closeTo(confirm.right, 0.5));
      expect(backspace.bottom, lessThan(confirm.top));
      expect(plus.center.dx, closeTo(backspace.center.dx, 0.5));
      expect(plus.bottom, lessThan(backspace.top));
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
