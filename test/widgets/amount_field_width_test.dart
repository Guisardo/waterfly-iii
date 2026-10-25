import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/widgets/input_number.dart';

void main() {
  group('amountFieldWidth', () {
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      testWidgets('NumberInput shows 999999.99 at text scale $scale', (
        WidgetTester tester,
      ) async {
        final TextEditingController controller = TextEditingController(
          text: '999999.99',
        );
        double expected = 0;
        await tester.pumpWidget(
          MaterialApp(
            builder: (BuildContext ctx, Widget? child) => MediaQuery(
              data: MediaQuery.of(
                ctx,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext ctx) {
                  final TextPainter p = TextPainter(
                    text: TextSpan(
                      text: '999999.99',
                      style: Theme.of(ctx).textTheme.bodyLarge,
                    ),
                    textDirection: TextDirection.ltr,
                    textScaler: MediaQuery.textScalerOf(ctx),
                  )..layout();
                  expected = p.width;
                  p.dispose();
                  return Row(
                    children: <Widget>[
                      SizedBox(
                        width: amountFieldWidth(ctx),
                        child: NumberInput(
                          icon: const SizedBox(
                            width: 24,
                            height: 32,
                            child: Icon(Icons.attach_money),
                          ),
                          controller: controller,
                          decimals: 2,
                          showMathKeyboard: false,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pump();
        final double actual = tester.getSize(find.byType(EditableText)).width;
        expect(actual, greaterThanOrEqualTo(expected));
      });
    }
  });
}
