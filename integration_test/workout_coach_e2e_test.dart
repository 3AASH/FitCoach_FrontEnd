import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitapp/main.dart' as app;

const String kE2EEmail = String.fromEnvironment('E2E_EMAIL');
const String kE2EPassword = String.fromEnvironment('E2E_PASSWORD');

bool get _hasCredentials => kE2EEmail.isNotEmpty && kE2EPassword.isNotEmpty;

Future<void> _launchApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
}

Future<void> _selectEnglishIfNeeded(WidgetTester tester) async {
  if (tester.any(find.text('اختر اللغة'))) {
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
  }
}

Future<void> _completeOnboardingIfNeeded(WidgetTester tester) async {
  if (tester.any(find.text('Welcome to FitCoach+'))) {
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();
  }

  if (tester.any(find.text('Get Started'))) {
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
  }
}

Future<void> _loginWithEmailIfNeeded(WidgetTester tester) async {
  if (!_hasCredentials) {
    return;
  }

  if (tester.any(find.text('Continue with Email'))) {
    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();
  }

  if (tester.any(find.text('Sign In'))) {
    final fields = find.byType(TextField);
    if (tester.any(fields)) {
      await tester.enterText(fields.at(0), kE2EEmail);
      await tester.enterText(fields.at(1), kE2EPassword);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }
}

Future<void> _dismissSecondIntakePromptIfNeeded(WidgetTester tester) async {
  if (tester.any(find.text('Complete your workout intake'))) {
    await tester.tap(find.text('Later'));
    await tester.pumpAndSettle();
  }
}

Future<void> _dismissWorkoutIntroIfNeeded(WidgetTester tester) async {
  if (tester.any(find.text('Workout Center'))) {
    if (tester.any(find.text('Get Started'))) {
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
    }
  }
}

Future<void> _openWorkoutTab(WidgetTester tester) async {
  await tester.tap(find.text('Workout'));
  await tester.pumpAndSettle();
}

Future<void> _openMessagesTab(WidgetTester tester) async {
  await tester.tap(find.text('Messages'));
  await tester.pumpAndSettle();
}

Future<void> _tapFirstConversationIfNeeded(WidgetTester tester) async {
  if (!tester.any(find.byIcon(Icons.send)) && tester.any(find.byType(ListTile))) {
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();
  }
}

void registerWorkoutCoachE2ETests() {
  group('Workout + Coach E2E (Frontend -> Backend)', () {
    testWidgets('workout plan load, injury substitution, and logging flow', (WidgetTester tester) async {
      await _launchApp(tester);
      await _selectEnglishIfNeeded(tester);
      await _completeOnboardingIfNeeded(tester);
      await _loginWithEmailIfNeeded(tester);

      if (!_hasCredentials) {
        return;
      }

      await _openWorkoutTab(tester);
      await _dismissWorkoutIntroIfNeeded(tester);
      await _dismissSecondIntakePromptIfNeeded(tester);

      expect(find.text('Workout'), findsOneWidget);

      if (tester.any(find.text('Start Workout'))) {
        await tester.tap(find.text('Start Workout').first);
        await tester.pumpAndSettle();
      }

      if (tester.any(find.text('Report injury'))) {
        await tester.tap(find.text('Report injury'));
        await tester.pumpAndSettle();

        if (tester.any(find.text('Substitute Exercise'))) {
          if (tester.any(find.text('No alternatives available'))) {
            if (tester.any(find.text('Cancel'))) {
              await tester.tap(find.text('Cancel'));
              await tester.pumpAndSettle();
            }
          } else if (tester.any(find.byType(ListTile))) {
            await tester.tap(find.byType(ListTile).first);
            await tester.pumpAndSettle();
          }
        }
      }

      final numberFields = find.byType(TextField);
      if (tester.any(numberFields)) {
        await tester.enterText(numberFields.at(0), '10');
        await tester.enterText(numberFields.at(1), '20');
        await tester.pumpAndSettle();
      }

      if (tester.any(find.text('Log set'))) {
        await tester.tap(find.text('Log set'));
        await tester.pumpAndSettle();
      }

      if (tester.any(find.text('Next exercise'))) {
        await tester.tap(find.text('Next exercise'));
        await tester.pumpAndSettle();
      } else if (tester.any(find.text('Finish workout'))) {
        await tester.tap(find.text('Finish workout'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('coach messaging send flow', (WidgetTester tester) async {
      await _launchApp(tester);
      await _selectEnglishIfNeeded(tester);
      await _completeOnboardingIfNeeded(tester);
      await _loginWithEmailIfNeeded(tester);

      if (!_hasCredentials) {
        return;
      }

      await _openMessagesTab(tester);
      await _tapFirstConversationIfNeeded(tester);

      final messageField = find.widgetWithText(TextField, 'Type a message...');
      if (tester.any(messageField)) {
        await tester.enterText(messageField, 'E2E: workout check-in from test');
        await tester.pumpAndSettle();
      } else if (tester.any(find.byType(TextField))) {
        await tester.enterText(find.byType(TextField).last, 'E2E: workout check-in from test');
        await tester.pumpAndSettle();
      }

      if (tester.any(find.byIcon(Icons.send))) {
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();
      }

      expect(find.text('E2E: workout check-in from test'), findsOneWidget);
    });
  });
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  registerWorkoutCoachE2ETests();
}
