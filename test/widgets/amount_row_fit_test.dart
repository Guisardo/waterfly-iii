import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:waterflyiii/pages/transaction.dart';
import 'package:waterflyiii/widgets/input_number.dart';

void main() {
  const double pagePadding = 24;

  for (final double width in <double>[360, 411]) {
    for (final double scale in <double>[1.0, 1.3, 2.0]) {
      testWidgets('amount, date and time fit ${width}dp at text scale $scale', (
        WidgetTester tester,
      ) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = Size(width, 800);
        addTearDown(tester.view.reset);

        final TextEditingController controller = TextEditingController(
          text: '999999.99',
        );
        addTearDown(controller.dispose);

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
                builder: (BuildContext ctx) => ListView(
                  padding: const EdgeInsets.symmetric(horizontal: pagePadding),
                  children: <Widget>[
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: <Widget>[
                          SizedBox(
                            width: amountFieldWidth(ctx),
                            child: Center(
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
                          ),
                          const SizedBox(width: 16),
                          DateTimePicker(
                            initialDateTime: tz.TZDateTime(
                              tz.UTC,
                              2026,
                              9,
                              28,
                              22,
                              43,
                            ),
                            onDateTimeChanged: (tz.TZDateTime _) {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        final Finder fields = find.byType(TextField);
        expect(fields, findsAtLeastNWidgets(3));
        final double limit = width - pagePadding + 0.5;
        for (int i = 0; i < fields.evaluate().length; i++) {
          expect(
            tester.getTopRight(fields.at(i)).dx,
            lessThanOrEqualTo(limit),
            reason: 'field #$i right edge past viewport at ${width}dp x$scale',
          );
        }
      });
    }
  }
}
