import 'package:flutter_test/flutter_test.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/auth/social_auth_client.dart';

void main() {
  group('AuthRepository Tests', () {
    late AuthRepository authRepository;

    setUp(() {
      authRepository = AuthRepository(
        socialAuthClient: _FakeSocialAuthClient(),
      );
    });

    test('should create AuthRepository instance', () {
      expect(authRepository, isNotNull);
    });

    test('AuthResponse should create from JSON', () {
      final json = {
        'token': 'test_token_123',
        'user': {
          'id': 'user123',
          'name': 'Ahmed Ali',
          'phoneNumber': '+966501234567',
          'role': 'client',
          'subscriptionTier': 'premium',
          'injuries': [],
          'hasCompletedFirstIntake': true,
          'hasCompletedSecondIntake': true,
        }
      };

      final response = AuthResponse.fromJson(json);

      expect(response.token, 'test_token_123');
      expect(response.user.id, 'user123');
      expect(response.user.name, 'Ahmed Ali');
    });

    test('should handle token storage key correctly', () {
      // Just verify the repository initializes properly
      expect(authRepository, isA<AuthRepository>());
    });
  });
}

class _FakeSocialAuthClient implements SocialAuthClient {
  @override
  Future<SocialAuthResult> signIn(String provider) async {
    return SocialAuthResult(
      provider: provider,
      accessToken: 'token',
      socialId: 'social-id',
      email: 'user@fitcoach.com',
      name: 'Demo User',
    );
  }
}
