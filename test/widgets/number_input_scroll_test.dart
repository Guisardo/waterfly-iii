import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/widgets/input_number.dart';
import 'package:waterflyiii/widgets/number_keyboard.dart';

void main() {
  testWidgets('field scrolls to the end while typing with the math keyboard', (
    WidgetTester tester,
  ) async {
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

    for (final String key in '123456789.12'.split('')) {
      await tester.tap(
        find.descendant(
          of: find.byType(NumberKeyboard),
          matching: find.text(key),
        ),
      );
      await tester.pumpAndSettle();
    }
    expect(controller.text, '123456789.12');

    final ScrollableState scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(NumberInput),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollable.position.maxScrollExtent, greaterThan(0));
    expect(scrollable.position.pixels, scrollable.position.maxScrollExtent);
  });
}
