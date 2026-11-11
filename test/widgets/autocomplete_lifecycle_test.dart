import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waterflyiii/widgets/autocompletetext.dart';

void main() {
  for (final bool ranked in <bool>[false, true]) {
    testWidgets('late options after disposal, ranked=$ranked', (
      WidgetTester tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      final FocusNode focus = FocusNode();
      final Completer<Iterable<String>> response =
          Completer<Iterable<String>>();
      int requests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AutoCompleteText<String>(
              textController: controller,
              focusNode: focus,
              labelText: 'Test',
              recencyField: ranked ? 'description' : null,
              optionsBuilder: (TextEditingValue value) {
                requests++;
                return response.future;
              },
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'query');
      await tester.pump();
      expect(requests, greaterThan(0));
      await tester.pumpWidget(const SizedBox.shrink());
      response.complete(<String>['late']);
      await tester.pump();
      await tester.pump();
      // Controller remains caller-owned; no disposed-state listener may remain.
      controller.text = 'after disposal';
      await tester.pump();
      expect(tester.takeException(), isNull);
      controller.dispose();
      focus.dispose();
    });
  }
}
