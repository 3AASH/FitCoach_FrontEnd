// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/main.dart';

void main() {
  testWidgets('FitCoach app builds', (WidgetTester tester) async {
    await tester.pumpWidget(const FitCoachApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(FitCoachApp), findsOneWidget);
  });
}
