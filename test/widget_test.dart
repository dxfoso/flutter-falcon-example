// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:red_rect_app/main.dart';

void main() {
  testWidgets('Red rectangle renders in the center', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const RedRectApp());

    expect(
      find.byWidgetPredicate((widget) {
        return widget is ColoredBox && widget.color == Colors.red;
      }),
      findsOneWidget,
    );
  });
}
