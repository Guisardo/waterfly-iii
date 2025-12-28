import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/widgets/input_number.dart';

/// Comprehensive test suite for NumberInput widget with math evaluation.
///
/// Tests cover:
/// - Basic number input
/// - Math expression input and evaluation
/// - Chained calculations (evaluates when second operator is pressed)
/// - Enter key evaluation
/// - Focus loss evaluation
/// - Input validation and formatting
void main() {
  group('NumberInput Widget', () {
    testWidgets('displays number input field', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(controller: controller, decimals: 2),
          ),
        ),
      );

      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('allows basic number input', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(controller: controller, decimals: 2),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '123.45');
      await tester.pump();

      expect(controller.text, '123.45');
    });

    testWidgets('replaces comma with dot for decimals', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(controller: controller, decimals: 2),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '123,45');
      await tester.pump();

      expect(controller.text, '123.45');
    });

    testWidgets('allows math operators when math evaluation enabled', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '10+5');
      await tester.pump();

      expect(controller.text, '10+5');
    });

    testWidgets('prevents consecutive operators', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      controller.text = '10+';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.tap(textField);
      await tester.pump();

      // Try to add another operator - should be prevented
      await tester.enterText(textField, '10++');
      await tester.pump();

      // Should not have consecutive operators
      expect(controller.text, isNot(contains('++')));
    });

    testWidgets('evaluates expression on Enter key', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '10+5');
      await tester.pump();

      // Simulate Enter key press
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Expression should be evaluated
      expect(controller.text, '15.00');
    });

    testWidgets('evaluates expression on focus loss', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                NumberInput(
                  controller: controller,
                  focusNode: focusNode,
                  decimals: 2,
                  enableMathEvaluation: true,
                ),
                // Another widget to focus on
                const TextField(key: Key('other_field')),
              ],
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField).first;
      await tester.enterText(textField, '10+5');
      await tester.pump();

      // Focus on another field
      final Finder otherField = find.byKey(const Key('other_field'));
      await tester.tap(otherField);
      await tester.pump();

      // Expression should be evaluated
      expect(controller.text, '15.00');
    });

    testWidgets('handles chained calculations', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);

      // Type "10+5" - should not evaluate yet
      await tester.enterText(textField, '10+5');
      await tester.pump();
      expect(controller.text, '10+5');

      // Add "*" - should evaluate "10+5" to 15, then add "*"
      await tester.enterText(textField, '10+5*');
      await tester.pump();

      // Should have evaluated and added the operator
      expect(controller.text, startsWith('15'));
      expect(controller.text, endsWith('*'));
    });

    testWidgets('formats result with correct decimal places', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '10/3');
      await tester.pump();

      // Simulate Enter key
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      // Should format with 2 decimal places
      expect(controller.text, '3.33');
    });

    testWidgets('handles fixed decimal places', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(controller: controller, decimals: 2),
          ),
        ),
      );
      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '10.005');
      await tester.pump();
      expect(controller.text, '10.01');

      await tester.enterText(textField, '10.502');
      await tester.pump();
      expect(controller.text, '10.5');

      await tester.enterText(textField, '10.5.5');
      await tester.pump();
      expect(controller.text, '10.5');

      await tester.enterText(textField, '10..');
      await tester.pump();
      expect(controller.text, '10');
    });

    testWidgets('handles invalid expressions gracefully', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      controller.text = '10+5';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);

      // Try to enter invalid expression
      await tester.enterText(textField, '10++5');
      await tester.pump();

      // Should not have consecutive operators
      expect(controller.text, isNot(contains('++')));
    });

    testWidgets('disables math evaluation when flag is false', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              enableMathEvaluation: false,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);

      // Try to enter operator - should be rejected
      await tester.enterText(textField, '10+5');
      await tester.pump();

      // Should not contain operators
      expect(controller.text, isNot(contains('+')));
    });

    testWidgets('calls onChanged callback', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      String? lastChangedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              onChanged: (String value) {
                lastChangedValue = value;
              },
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      await tester.enterText(textField, '123');
      await tester.pump();

      expect(lastChangedValue, '123');
    });

    // Regression test for Guisardo/waterfly-iii#3:
    // When the save button is pressed while the amount field still has focus and
    // contains a math expression, the TransactionPage calls
    // FocusScope.of(context).unfocus() to force evaluation before reading
    // _localAmounts. This test verifies the mechanism: programmatic unfocus must
    // trigger onChanged with the evaluated value, not the raw expression string.
    testWidgets(
      'evaluates math expression and fires onChanged when FocusScope.unfocus() is called',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController();
        final FocusNode focusNode = FocusNode();
        final List<String> changedValues = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  NumberInput(
                    controller: controller,
                    focusNode: focusNode,
                    decimals: 2,
                    enableMathEvaluation: true,
                    onChanged: (String value) {
                      changedValues.add(value);
                    },
                  ),
                  // Dummy widget that gives focus a place to go when unfocused
                  const TextField(key: Key('other_field')),
                ],
              ),
            ),
          ),
        );

        // Type a math expression while the field is focused — simulates the user
        // editing the amount field with an expression and not yet tapping away.
        final Finder textField = find.byType(TextFormField).first;
        await tester.tap(textField);
        await tester.pump();
        await tester.enterText(textField, '100+50');
        await tester.pump();

        // Precondition: raw expression is in the controller and onChanged received it.
        expect(controller.text, '100+50');

        // Simulate what TransactionPage does just before setState(_savingInProgress=true):
        // FocusScope.of(context).unfocus() — this fires NumberInput._onFocusChange
        // synchronously, which calls _evaluateExpression and then onChanged with the
        // evaluated result.
        final BuildContext ctx = tester.element(find.byType(Scaffold).first);
        FocusScope.of(ctx).unfocus();
        await tester.pump();

        // The controller must now contain the evaluated result, not the raw expression.
        expect(controller.text, '150.00');

        // onChanged must have been called with the evaluated value.
        expect(changedValues.last, '150.00');
      },
    );

    testWidgets('respects disabled state', (WidgetTester tester) async {
      final TextEditingController controller = TextEditingController();
      controller.text = '123';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NumberInput(
              controller: controller,
              decimals: 2,
              disabled: true,
            ),
          ),
        ),
      );

      final Finder textField = find.byType(TextFormField);
      final TextFormField field = tester.widget<TextFormField>(textField);

      // Check that the field is disabled (readOnly is not directly accessible)
      expect(field.enabled, false);
    });

    testWidgets(
      'does not evaluate or call onChanged when expression is invalid on focus loss',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController();
        final FocusNode focusNode = FocusNode();
        final List<String> changedValues = <String>[];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: <Widget>[
                  NumberInput(
                    controller: controller,
                    focusNode: focusNode,
                    decimals: 2,
                    onChanged: (String value) => changedValues.add(value),
                  ),
                  const TextField(key: Key('other')),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.byType(TextFormField).first);
        await tester.pump();
        await tester.enterText(find.byType(TextFormField).first, '10+');
        await tester.pump();

        // Lose focus — "10+" is an incomplete/invalid expression
        await tester.tap(find.byKey(const Key('other')));
        await tester.pump();

        // Controller text must remain unchanged (not evaluated)
        expect(controller.text, '10+');
        // onChanged must NOT have been called with an evaluated numeric result
        expect(changedValues.where((String v) => v == '10.00').isEmpty, isTrue);
      },
    );

    testWidgets(
      'formats integer result without decimal places when decimals is 0',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NumberInput(controller: controller, decimals: 0),
            ),
          ),
        );

        await tester.enterText(find.byType(TextFormField), '10+5');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Must be "15" not "15.0"
        expect(controller.text, '15');
      },
    );

    testWidgets(
      'still evaluates on focus loss after widget rebuilds with a new focusNode',
      (WidgetTester tester) async {
        final TextEditingController controller = TextEditingController();
        final FocusNode firstNode = FocusNode();
        final FocusNode secondNode = FocusNode();
        FocusNode activeNode = firstNode;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: <Widget>[
                      NumberInput(
                        controller: controller,
                        focusNode: activeNode,
                        decimals: 2,
                      ),
                      ElevatedButton(
                        key: const Key('swap'),
                        onPressed: () =>
                            setState(() => activeNode = secondNode),
                        child: const Text('Swap'),
                      ),
                      const TextField(key: Key('other')),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Rebuild with secondNode — triggers didUpdateWidget
        await tester.tap(find.byKey(const Key('swap')));
        await tester.pump();

        // Type expression with second node active
        await tester.tap(find.byType(TextFormField).first);
        await tester.pump();
        await tester.enterText(find.byType(TextFormField).first, '8+2');
        await tester.pump();

        // Lose focus — evaluation should work via second node's listener
        await tester.tap(find.byKey(const Key('other')));
        await tester.pump();

        expect(controller.text, '10.00');

        firstNode.dispose();
        secondNode.dispose();
      },
    );
  });
}
