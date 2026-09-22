import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/core/config/demo_config.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/auth/auth_screen.dart';

class MockAuthRepository implements AuthRepositoryBase {
  /// What `checkPhone` should report, so a test can drive either branch of the
  /// phone step: a registered number asks for a password, a new one gets a code.
  PhoneStatus phoneStatus = const PhoneStatus(
    registered: false,
    hasPassword: false,
    nextStep: 'send_otp',
  );

  String? lastOtpPurpose;

  @override
  Future<PhoneStatus> checkPhone(String phoneNumber) async => phoneStatus;

  @override
  Future<void> requestOTP(String phoneNumber, {String? purpose}) async {
    lastOtpPurpose = purpose;
  }

  @override
  Future<AuthResponse> completeRegistration({
    required String fullName,
    required String password,
    String? email,
  }) async {
    return AuthResponse(
      token: '',
      user: UserProfile(
          id: 'mock_id', phoneNumber: '+201027856024', name: fullName, age: 30),
      isNewUser: true,
      registrationComplete: true,
    );
  }

  @override
  Future<AuthResponse> verifyOTP(String phoneNumber, String otp) async {
    return AuthResponse(
      token: 'mock_token',
      user: UserProfile(
          id: 'mock_id', phoneNumber: phoneNumber, name: 'Test User', age: 30),
      isNewUser: false,
    );
  }

  @override
  Future<AuthResponse> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    return AuthResponse(
      token: 'mock_token',
      user: UserProfile(
        id: 'mock_id',
        phoneNumber: phoneNumber,
        name: 'Test User',
        age: 30,
      ),
      isNewUser: false,
    );
  }

  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<UserProfile?> getUserProfile() async => null;

  @override
  Future<AuthResponse> loginWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  }) async {
    return AuthResponse(
      token: 'mock_token',
      user: UserProfile(
          id: 'mock_id',
          phoneNumber: '+966501234567',
          name: 'Test User',
          age: 30),
      isNewUser: false,
    );
  }

  @override
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? otpCode,
  }) async {
    return AuthResponse(
      token: 'mock_token',
      user: UserProfile(id: 'mock_id', phoneNumber: phone, name: name, age: 30),
      isNewUser: true,
    );
  }

  @override
  Future<AuthResponse> socialLogin(String provider) async {
    return AuthResponse(
      token: 'mock_token',
      user: UserProfile(
          id: 'mock_id',
          phoneNumber: '+966501234567',
          name: 'Test User',
          age: 30),
      isNewUser: false,
    );
  }

  @override
  Future<void> storeToken(String token) async {}

  @override
  Future<void> removeToken() async {}

  @override
  Future<void> logout() async {}

  @override
  Future<String?> refreshToken() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<Widget> buildTestWidget({
    required VoidCallback onAuthenticated,
    MockAuthRepository? repository,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final languageProvider = LanguageProvider();
    await languageProvider.setLanguage('en');
    final repo = repository ?? MockAuthRepository();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(repo),
        ),
      ],
      child: MaterialApp(
        home: AuthScreen(onAuthenticated: onAuthenticated),
      ),
    );
  }

  testWidgets('auth screen shows choose options', (tester) async {
    var authenticated = false;
    await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {
      authenticated = true;
    }));

    expect(find.text('Continue with Email'), findsOneWidget);
    expect(find.text('Continue with Phone'), findsOneWidget);
    expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    expect(find.byIcon(Icons.facebook), findsOneWidget);
    expect(find.byIcon(Icons.apple), findsOneWidget);
    expect(authenticated, isFalse);
  });

  testWidgets('email sign in shows forgot password dialog', (tester) async {
    await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {}));

    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsWidgets);
    expect(find.text('Forgot Password?'), findsOneWidget);

    await tester.ensureVisible(find.text('Forgot Password?'));
    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
  });

  testWidgets('sign up shows phone field and allows switch back',
      (tester) async {
    await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {}));

    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Don't have an account? Sign Up"));
    await tester.tap(find.text("Don't have an account? Sign Up"));
    await tester.pumpAndSettle();

    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);

    await tester.ensureVisible(find.text('Already have an account? Sign In'));
    await tester.tap(find.text('Already have an account? Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsWidgets);
  });

  testWidgets('phone sign in shows phone input', (tester) async {
    await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {}));

    await tester.tap(find.text('Continue with Phone'));
    await tester.pumpAndSettle();

    expect(find.text('Phone Number'), findsOneWidget);
  });

  testWidgets('a registered phone number is asked for its password',
      (tester) async {
    if (DemoConfig.isDemo) return;
    // A registered number must not be sent an OTP, or knowing the number would
    // be enough to sign in without the password.
    final repo = MockAuthRepository()
      ..phoneStatus = const PhoneStatus(
        registered: true,
        hasPassword: true,
        nextStep: 'password',
      );

    await tester.pumpWidget(
      await buildTestWidget(onAuthenticated: () {}, repository: repo),
    );

    await tester.tap(find.text('Continue with Phone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '1027856024');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Password'), findsWidgets);
    expect(repo.lastOtpPurpose, isNull);
  }, skip: DemoConfig.isDemo);

  // Asserted through the provider rather than the screen: a new number lands on
  // the OTP step, whose 60-second resend countdown a widget test cannot settle.
  test('a sign-up code is requested with the signup purpose', () async {
    if (DemoConfig.isDemo) return;
    final repo = MockAuthRepository();
    final authProvider = AuthProvider(repo);

    final sent = await authProvider.requestOTP('+201027856024', purpose: 'signup');

    expect(sent, isTrue);
    // The purpose is what lets the backend refuse a code for a number that
    // already has a password.
    expect(repo.lastOtpPurpose, 'signup');
  }, skip: DemoConfig.isDemo);

  test('checkPhone reports a registered number so the UI can ask for a password',
      () async {
    if (DemoConfig.isDemo) return;
    final repo = MockAuthRepository()
      ..phoneStatus = const PhoneStatus(
        registered: true,
        hasPassword: true,
        nextStep: 'password',
      );
    final authProvider = AuthProvider(repo);

    final status = await authProvider.checkPhone('+201027856024');

    expect(status?.registered, isTrue);
    expect(status?.nextStep, 'password');
    // No code is requested for a registered number.
    expect(repo.lastOtpPurpose, isNull);
  }, skip: DemoConfig.isDemo);

  testWidgets(
    'demo mode bypass authenticates when enabled',
    (tester) async {
      if (!DemoConfig.isDemo) {
        return;
      }
      var authenticated = false;
      await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {
        authenticated = true;
      }));

      await tester.tap(find.text('Try Demo'));
      await tester.pumpAndSettle();

      expect(authenticated, isTrue);
    },
    skip: !DemoConfig.isDemo,
  );
}
