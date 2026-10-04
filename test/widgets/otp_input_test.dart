/// Autofilling the SMS code.
///
/// The verification step used to be six one-character `TextField`s. Both iOS
/// and Android deliver an autofilled code as a single string to a single
/// field, so that layout could never receive one: at best the first box got
/// the whole code and the other five stayed empty. Everybody typed it out.
///
/// [OtpInput] keeps the six-box look but is one field underneath. These tests
/// pin the two things that make autofill work — the hint is declared, and the
/// field takes the whole code at once — plus the ordinary typing path.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/presentation/widgets/otp_input.dart';

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode();
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<int> pumpOtp(WidgetTester tester, {VoidCallback? onCompleted}) async {
    var completions = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtpInput(
          controller: controller,
          focusNode: focusNode,
          onCompleted: () async {
            completions++;
            onCompleted?.call();
          },
        ),
      ),
    ));
    return completions;
  }

  testWidgets('declares the one-time-code hint on a single field',
      (tester) async {
    await pumpOtp(tester);

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.length, 1,
        reason: 'autofill delivers the code to one field; six fields cannot '
            'receive it');
    expect(fields.single.autofillHints, contains(AutofillHints.oneTimeCode));
    // The hint only reaches the platform from inside an AutofillGroup.
    expect(find.byType(AutofillGroup), findsOneWidget);
  });

  testWidgets('accepts a whole code arriving at once, as autofill sends it',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtpInput(
          controller: controller,
          focusNode: focusNode,
          onCompleted: () async => completed++,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();

    expect(controller.text, '123456');
    expect(completed, 1, reason: 'a filled code should submit on its own');
    for (final digit in ['1', '2', '3', '4', '5', '6']) {
      expect(find.text(digit), findsOneWidget,
          reason: 'each digit should appear in its own box');
    }
  });

  testWidgets('submits once, not once per rebuild', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtpInput(
          controller: controller,
          focusNode: focusNode,
          onCompleted: () async => completed++,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    await tester.pump();
    expect(completed, 1);
  });

  testWidgets('re-arms after the code is cleared and retyped', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtpInput(
          controller: controller,
          focusNode: focusNode,
          onCompleted: () async => completed++,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    // A wrong code is cleared and the person tries again; that second attempt
    // has to submit too.
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.enterText(find.byType(TextField), '654321');
    await tester.pump();

    expect(completed, 2);
  });

  testWidgets('does not submit a partial code', (tester) async {
    var completed = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: OtpInput(
          controller: controller,
          focusNode: focusNode,
          onCompleted: () async => completed++,
        ),
      ),
    ));

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();

    expect(completed, 0);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('5'), findsNothing);
  });

  testWidgets('keeps digits only and stops at six', (tester) async {
    await pumpOtp(tester);

    await tester.enterText(find.byType(TextField), '12a34b5678');
    await tester.pump();

    expect(controller.text, '123456');
  });

  testWidgets('shows six boxes before anything is entered', (tester) async {
    await pumpOtp(tester);
    expect(find.byType(Container), findsNWidgets(6));
  });
}
