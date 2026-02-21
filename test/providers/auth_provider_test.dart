import 'package:flutter_test/flutter_test.dart';
import '../../lib/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/core/config/demo_config.dart';

// Add a mock implementation for the required dependency
class MockAuthRepository implements AuthRepositoryBase {
  @override
  Future<void> requestOTP(String phoneNumber) async {
    if (!phoneNumber.startsWith('+9665') || phoneNumber.length != 13) {
      throw Exception('Invalid phone number');
    }
  }

  @override
  Future<AuthResponse> verifyOTP(String phoneNumber, String otp) async {
    if (otp == '1234') {
      return AuthResponse(
        token: 'mock_token',
        user: UserProfile(
          id: 'mock_id',
          phoneNumber: '+966501234567',
          name: 'Test User',
          age: 30,
        ),
        isNewUser: false,
      );
    }
    throw Exception('Invalid OTP');
  }

  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<UserProfile?> getUserProfile() async {
    return UserProfile(
      id: 'mock_id',
      phoneNumber: '+966501234567',
      name: 'Test User',
      age: 30,
    );
  }

  @override
  Future<AuthResponse> loginWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  }) async {
    if (emailOrPhone == 'test@example.com' && password == 'password') {
      return AuthResponse(
        token: 'mock_token',
        user: UserProfile(
          id: 'mock_id',
          phoneNumber: '+966501234567',
          name: 'Test User',
          age: 30,
        ),
        isNewUser: false,
      );
    }
    throw Exception('Invalid OTP');
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
      user: UserProfile(
        id: 'mock_id',
        phoneNumber: phone,
        name: name,
        age: 30,
      ),
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
        age: 30,
      ),
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

  group('AuthProvider Tests', () {
    late AuthProvider authProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authProvider = AuthProvider(MockAuthRepository());
    });

    test('initial state should be unauthenticated', () {
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, null);
      expect(authProvider.token, null);
    });

    test('requestOTP should validate phone number', () async {
      if (DemoConfig.isDemo) {
        expect(await authProvider.requestOTP('+966501234567'), true);
        expect(await authProvider.requestOTP('invalid'), true);
        return;
      }
      // Valid Saudi phone numbers
      expect(await authProvider.requestOTP('+966501234567'), true);
      expect(await authProvider.requestOTP('+966551234567'), true);

      // Invalid phone numbers
      expect(await authProvider.requestOTP('+966401234567'), false);
      expect(await authProvider.requestOTP('501234567'), false);
      expect(await authProvider.requestOTP('+966'), false);
    });

    test('verifyOTP should authenticate user with correct OTP', () async {
      // Request OTP first
      await authProvider.requestOTP('+966501234567');

      // Verify with correct OTP (simulated)
      final result = await authProvider.verifyOTP('+966501234567', '1234');
      expect(result, true);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
      expect(authProvider.token, isNotNull);
    });

    test('verifyOTP should fail with incorrect OTP', () async {
      if (DemoConfig.isDemo) {
        return;
      }
      await authProvider.requestOTP('+966501234567');

      final result = await authProvider.verifyOTP('+966501234567', '0000');
      expect(result, false);
      expect(authProvider.isAuthenticated, false);
    });

    test('logout should clear authentication state', () async {
      // Authenticate first
      await authProvider.requestOTP('+966501234567');
      await authProvider.verifyOTP('+966501234567', '1234');
      expect(authProvider.isAuthenticated, true);

      // Logout
      await authProvider.logout();
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, null);
      expect(authProvider.token, null);
    });

    // test('updateProfile should update user data', () async {
    //   // Authenticate first
    //   await authProvider.requestOTP('+966501234567');
    //   await authProvider.verifyOTP('+966501234567', '1234');
    //
    //   // Update profile
    //   await authProvider.updateProfile({
    //     'name': 'Ahmed Ali',
    //     'age': 25,
    //   });
    //
    //   expect(authProvider.user?.name, 'Ahmed Ali');
    //   expect(authProvider.user?.age, 25);
    // });

    // test('completeFirstIntake should save intake data', () async {
    //   await authProvider.requestOTP('+966501234567');
    //   await authProvider.verifyOTP('+966501234567', '1234');
    //
    //   final intakeData = {
    //     'goal': 'fat_loss',
    //     'experience': 'beginner',
    //     'height': 175,
    //     'weight': 80,
    //     'injuries': [],
    //   };
    //
    //   await authProvider.completeFirstIntake(intakeData);
    //   expect(authProvider.user?.firstIntakeCompleted, true);
    // });

    // test('completeSecondIntake should save detailed intake data', () async {
    //   await authProvider.requestOTP('+966501234567');
    //   await authProvider.verifyOTP('+966501234567', '1234');
    //   await authProvider.completeFirstIntake({'goal': 'fat_loss'});
    //
    //   final intakeData = {
    //     'workoutPreference': 'gym',
    //     'dietRestrictions': ['none'],
    //     'sleepHours': 7,
    //     'stressLevel': 'medium',
    //     'medications': [],
    //     'previousInjuries': [],
    //   };
    //
    //   await authProvider.completeSecondIntake(intakeData);
    //   expect(authProvider.user?.secondIntakeCompleted, true);
    // });

    test('isLoading should be true during async operations', () async {
      if (DemoConfig.isDemo) {
        return;
      }
      expect(authProvider.isLoading, false);

      final future = authProvider.requestOTP('+966501234567');
      expect(authProvider.isLoading, true);

      await future;
      expect(authProvider.isLoading, false);
    });

    test('error should be set on authentication failure', () async {
      if (DemoConfig.isDemo) {
        return;
      }
      await authProvider.requestOTP('+966501234567');
      await authProvider.verifyOTP('+966501234567', 'wrong');

      expect(authProvider.error, isNotNull);
    });

    test('clearError should reset error state', () async {
      if (DemoConfig.isDemo) {
        return;
      }
      await authProvider.requestOTP('+966501234567');
      await authProvider.verifyOTP('+966501234567', 'wrong');
      expect(authProvider.error, isNotNull);

      authProvider.clearError();
      expect(authProvider.error, null);
    });
  });
}
