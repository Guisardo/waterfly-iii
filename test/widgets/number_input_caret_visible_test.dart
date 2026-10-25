import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/widgets/input_number.dart';
import 'package:waterflyiii/widgets/number_keyboard.dart';

void main() {
  testWidgets(
    'caret stays visible when typing in the middle of a long number',
    (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 100,
                child: NumberInput(controller: controller, decimals: 2),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextFormField));
      await tester.pumpAndSettle();
      expect(find.byType(NumberKeyboard), findsOneWidget);

      Future<void> type(String keys) async {
        for (final String key in keys.split('')) {
          await tester.tap(
            find.descendant(
              of: find.byType(NumberKeyboard),
              matching: find.text(key),
            ),
          );
          await tester.pumpAndSettle();
        }
      }

      await type('123456789.12');
      expect(controller.text, '123456789.12');

      // Caret right after the 9, as when the user taps there.
      controller.selection = const TextSelection.collapsed(offset: 9);
      await tester.pumpAndSettle();

      await type('12345678');
      expect(controller.text, '12345678912345678.12');
      expect(controller.selection.baseOffset, 17);

      final EditableTextState editable = tester.state<EditableTextState>(
        find.descendant(
          of: find.byType(NumberInput),
          matching: find.byType(EditableText),
        ),
      );
      final Rect caret = editable.renderEditable.getLocalRectForCaret(
        const TextPosition(offset: 17),
      );
      final double viewport = editable.renderEditable.size.width;
      expect(
        caret.left,
        greaterThanOrEqualTo(-0.5),
        reason: 'caret left of view',
      );
      expect(
        caret.right,
        lessThanOrEqualTo(viewport + 0.5),
        reason: 'caret right of view (viewport $viewport, caret $caret)',
      );
    },
  );

  testWidgets('caret stays visible when deleting in the middle', (
    WidgetTester tester,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: '12345678912345678.12',
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 100,
              child: NumberInput(controller: controller, decimals: 2),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();

    controller.selection = const TextSelection.collapsed(offset: 17);
    await tester.pumpAndSettle();
    for (int i = 0; i < 6; i++) {
      await tester.tap(
        find.descendant(
          of: find.byType(NumberKeyboard),
          matching: find.byType(Icon),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(controller.selection.baseOffset, 11);

    final EditableTextState editable = tester.state<EditableTextState>(
      find.descendant(
        of: find.byType(NumberInput),
        matching: find.byType(EditableText),
      ),
    );
    final Rect caret = editable.renderEditable.getLocalRectForCaret(
      const TextPosition(offset: 11),
    );
    final double viewport = editable.renderEditable.size.width;
    expect(
      caret.left,
      greaterThanOrEqualTo(-0.5),
      reason: 'caret left of view',
    );
    expect(
      caret.right,
      lessThanOrEqualTo(viewport + 0.5),
      reason: 'caret right of view',
    );
  });
}
