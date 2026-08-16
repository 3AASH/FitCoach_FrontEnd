import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/repositories/user_repository.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/settings/change_mobile_screen.dart';
import 'package:fitapp/presentation/screens/settings/change_password_screen.dart';
import 'package:fitapp/presentation/screens/settings/delete_account_screen.dart';

/// Records what the screens ask the backend to do, so a test can assert the
/// call rather than the pixels.
class _FakeUserRepository extends UserRepository {
  bool deleteOtpRequested = false;
  bool mobileOtpRequested = false;
  String? mobileOtpNumber;
  String? deletedWithPassword;
  String? deletedWithOtp;
  String? changedNumber;
  String? changedOtp;
  String? changedPasswordFrom;
  Object? failWith;

  @override
  Future<void> requestDeleteAccountOtp() async {
    if (failWith != null) throw failWith!;
    deleteOtpRequested = true;
  }

  @override
  Future<void> deleteAccount({String? password, String? otpCode}) async {
    if (failWith != null) throw failWith!;
    deletedWithPassword = password;
    deletedWithOtp = otpCode;
  }

  @override
  Future<void> requestMobileChangeOtp(String newPhoneNumber) async {
    if (failWith != null) throw failWith!;
    mobileOtpRequested = true;
    mobileOtpNumber = newPhoneNumber;
  }

  @override
  Future<void> confirmMobileChange({
    required String newPhoneNumber,
    required String otpCode,
  }) async {
    if (failWith != null) throw failWith!;
    changedNumber = newPhoneNumber;
    changedOtp = otpCode;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (failWith != null) throw failWith!;
    changedPasswordFrom = currentPassword;
  }
}

class _StubAuthRepository implements AuthRepositoryBase {
  @override
  dynamic noSuchMethod(Invocation invocation) async => null;
}

UserProfile _profile({required bool hasPassword}) => UserProfile(
      id: 'user-1',
      name: 'Test User',
      phoneNumber: '+966500001001',
      hasPassword: hasPassword,
    );

Future<AuthProvider> _authProvider({required bool hasPassword}) async {
  final provider = AuthProvider(_StubAuthRepository());
  provider.updateUser(_profile(hasPassword: hasPassword));
  return provider;
}

Future<Widget> _wrap(
  Widget screen, {
  required bool hasPassword,
  String language = 'en',
}) async {
  SharedPreferences.setMockInitialValues({'language': language});
  final languageProvider = LanguageProvider();
  await languageProvider.setLanguage(language);
  final authProvider = await _authProvider(hasPassword: hasPassword);

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(home: screen),
  );
}

/// The submit button carries the same label as the app bar title and sits below
/// the fold, so target the button itself and bring it into view first.
Future<void> submitChangePassword(WidgetTester tester) async {
  final button = find.widgetWithText(ElevatedButton, 'Change password');
  await tester.scrollUntilVisible(button, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

void main() {
  group('ChangePasswordScreen', () {
    testWidgets('shows the form for an account that has a password',
        (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        ChangePasswordScreen(userRepository: repo),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Current password'), findsOneWidget);
      expect(find.text('New password'), findsOneWidget);
      expect(find.text('Confirm new password'), findsOneWidget);
    });

    testWidgets('offers the OTP route instead when there is no password',
        (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        ChangePasswordScreen(userRepository: repo),
        hasPassword: false,
      ));
      await tester.pumpAndSettle();

      expect(find.text('This account has no password'), findsOneWidget);
      expect(find.text('Set a password with a code'), findsOneWidget);
      // No dead form for an account that cannot use it.
      expect(find.text('Current password'), findsNothing);
    });

    testWidgets('refuses two new passwords that do not match', (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        ChangePasswordScreen(userRepository: repo),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'old-password');
      await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
      await tester.enterText(find.byType(TextFormField).at(2), 'different');
      await submitChangePassword(tester);

      expect(find.text('The two passwords do not match'), findsOneWidget);
      expect(repo.changedPasswordFrom, isNull);
    });

    testWidgets('sends the change when the form is valid', (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        ChangePasswordScreen(userRepository: repo),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'old-password');
      await tester.enterText(find.byType(TextFormField).at(1), 'new-password');
      await tester.enterText(find.byType(TextFormField).at(2), 'new-password');
      await submitChangePassword(tester);

      expect(repo.changedPasswordFrom, 'old-password');
    });
  });

  group('ChangeMobileScreen', () {
    testWidgets('sends the code to the new number, then confirms',
        (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        ChangeMobileScreen(userRepository: repo),
        hasPassword: false,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '+966500002002');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(repo.mobileOtpNumber, '+966500002002');
      expect(find.text('Verification code'), findsOneWidget);

      await tester.enterText(find.byType(TextField).last, '123456');
      await tester.tap(find.text('Change number'));
      await tester.pumpAndSettle();

      expect(repo.changedNumber, '+966500002002');
      expect(repo.changedOtp, '123456');
    });

    testWidgets('refuses a number that is not in international format',
        (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        ChangeMobileScreen(userRepository: repo),
        hasPassword: false,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '0500002002');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(repo.mobileOtpRequested, isFalse);
      expect(
        find.text(
            'Enter the number in international format, for example +966500000000'),
        findsOneWidget,
      );
    });

    testWidgets('shows the backend message when the number is taken',
        (tester) async {
      final repo = _FakeUserRepository()
        ..failWith = Exception('This phone number is already in use');
      await tester.pumpWidget(await _wrap(
        ChangeMobileScreen(userRepository: repo),
        hasPassword: false,
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '+966500002002');
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(find.text('This phone number is already in use'), findsOneWidget);
    });
  });

  group('DeleteAccountScreen', () {
    Future<void> scrollTo(WidgetTester tester, Finder target) async {
      await tester.scrollUntilVisible(target, 200,
          scrollable: find.byType(Scrollable).first);
    }

    testWidgets('states what is erased and what is kept', (tester) async {
      await tester.pumpWidget(await _wrap(
        DeleteAccountScreen(userRepository: _FakeUserRepository()),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      expect(find.text('What is erased'), findsOneWidget);
      expect(find.text('What is kept'), findsOneWidget);
      expect(
        find.text(
            'Your InBody scans, the scan photos and your progress history'),
        findsOneWidget,
      );
    });

    testWidgets('asks a password account for the password', (tester) async {
      await tester.pumpWidget(await _wrap(
        DeleteAccountScreen(userRepository: _FakeUserRepository()),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Your password'));
      expect(find.text('Your password'), findsOneWidget);
      expect(find.text('Send code'), findsNothing);
    });

    testWidgets('asks an OTP account to request a code first', (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        DeleteAccountScreen(userRepository: repo),
        hasPassword: false,
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Send code'));
      await tester.tap(find.text('Send code'));
      await tester.pumpAndSettle();

      expect(repo.deleteOtpRequested, isTrue);
      expect(find.text('Verification code'), findsOneWidget);
    });

    testWidgets('will not delete until the confirmation word is typed',
        (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        DeleteAccountScreen(userRepository: repo),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Delete my account'));
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(repo.deletedWithPassword, isNull);
      expect(find.text('Type the confirmation word exactly'), findsOneWidget);
    });

    testWidgets('asks once more in a dialog, and a cancel deletes nothing',
        (tester) async {
      final repo = _FakeUserRepository();
      await tester.pumpWidget(await _wrap(
        DeleteAccountScreen(userRepository: repo),
        hasPassword: true,
      ));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('DELETE'));
      await tester.enterText(find.byType(TextField).last, 'DELETE');
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Delete my account'));
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(repo.deletedWithPassword, isNull);
    });
  });

  group('Arabic', () {
    testWidgets('delete screen renders right to left with Arabic text',
        (tester) async {
      await tester.pumpWidget(await _wrap(
        DeleteAccountScreen(userRepository: _FakeUserRepository()),
        hasPassword: true,
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      // Every string must come from the dictionary, so no English may leak.
      expect(find.text('حذف الحساب'), findsWidgets);
      expect(find.text('ما سيتم حذفه'), findsOneWidget);
      expect(find.text('ما سيتم الاحتفاظ به'), findsOneWidget);
      expect(find.text('What is erased'), findsNothing);
    });

    testWidgets('change password screen renders Arabic', (tester) async {
      await tester.pumpWidget(await _wrap(
        ChangePasswordScreen(userRepository: _FakeUserRepository()),
        hasPassword: true,
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      expect(find.text('كلمة المرور الحالية'), findsOneWidget);
      expect(find.text('Current password'), findsNothing);
    });

    testWidgets('change mobile screen renders Arabic', (tester) async {
      await tester.pumpWidget(await _wrap(
        ChangeMobileScreen(userRepository: _FakeUserRepository()),
        hasPassword: false,
        language: 'ar',
      ));
      await tester.pumpAndSettle();

      expect(find.text('الرقم الجديد'), findsOneWidget);
      expect(find.text('New number'), findsNothing);
    });
  });
}
