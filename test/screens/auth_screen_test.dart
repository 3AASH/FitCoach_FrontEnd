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
  @override
  Future<void> requestOTP(String phoneNumber) async {}

  @override
  Future<AuthResponse> verifyOTP(String phoneNumber, String otp) async {
    return AuthResponse(
      token: 'mock_token',
      user: UserProfile(id: 'mock_id', phoneNumber: phoneNumber, name: 'Test User', age: 30),
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
      user: UserProfile(id: 'mock_id', phoneNumber: '+966501234567', name: 'Test User', age: 30),
      isNewUser: false,
    );
  }

  @override
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
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
      user: UserProfile(id: 'mock_id', phoneNumber: '+966501234567', name: 'Test User', age: 30),
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

  Future<Widget> buildTestWidget({required VoidCallback onAuthenticated}) async {
    SharedPreferences.setMockInitialValues({});
    final languageProvider = LanguageProvider();
    await languageProvider.setLanguage('en');

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(MockAuthRepository()),
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
    expect(find.text('Try Demo'), findsOneWidget);
    expect(authenticated, isFalse);
  });

  testWidgets('email sign in shows forgot password dialog', (tester) async {
    await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {}));

    await tester.tap(find.text('Continue with Email'));
    await tester.pumpAndSettle();

    expect(find.text('Email or Phone'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsOneWidget);

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot Password'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
  });

  testWidgets('sign up shows phone field and allows switch back', (tester) async {
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

    expect(find.text('Email or Phone'), findsOneWidget);
  });

  testWidgets('phone sign in shows phone input', (tester) async {
    await tester.pumpWidget(await buildTestWidget(onAuthenticated: () {}));

    await tester.tap(find.text('Continue with Phone'));
    await tester.pumpAndSettle();

    expect(find.text('Phone Number'), findsOneWidget);
  });

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
