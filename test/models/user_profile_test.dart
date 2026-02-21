import 'package:flutter_test/flutter_test.dart';
// Ensure that user_profile.dart exports the UserProfile class.
import 'package:fitapp/data/models/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('should create UserProfile instance', () {
      final user = UserProfile(
        id: 'user123',
        name: 'Ahmed Ali',
        phoneNumber: '+966501234567',
        email: 'ahmed@example.com',
        role: 'client',
        subscriptionTier: 'premium',
        injuries: [],
        hasCompletedFirstIntake: true,
        hasCompletedSecondIntake: true,
      );

      expect(user.id, 'user123');
      expect(user.name, 'Ahmed Ali');
      expect(user.phoneNumber, '+966501234567');
      expect(user.role, 'client');
      expect(user.subscriptionTier, 'premium');
    });

    test('should handle null values', () {
      final user = UserProfile(
        id: 'user123',
        name: 'Ahmed',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'freemium',
        injuries: [],
        hasCompletedFirstIntake: false,
        hasCompletedSecondIntake: false,
      );

      expect(user.email, isNull);
      expect(user.age, isNull);
      expect(user.weight, isNull);
    });

    test('should create from JSON', () {
      final json = {
        'id': 'user123',
        'name': 'Ahmed Ali',
        'phoneNumber': '+966501234567',
        'email': 'ahmed@example.com',
        'role': 'client',
        'subscriptionTier': 'premium',
        'injuries': [],
        'hasCompletedFirstIntake': true,
        'hasCompletedSecondIntake': true,
      };

      final user = UserProfile.fromJson(json);

      expect(user.id, 'user123');
      expect(user.name, 'Ahmed Ali');
      expect(user.subscriptionTier, 'premium');
    });

    test('should convert to JSON', () {
      final user = UserProfile(
        id: 'user123',
        name: 'Ahmed',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'freemium',
        injuries: [],
        hasCompletedFirstIntake: false,
        hasCompletedSecondIntake: false,
      );

      final json = user.toJson();

      expect(json['id'], 'user123');
      expect(json['name'], 'Ahmed');
      expect(json['subscriptionTier'], 'freemium');
    });

    test('should check subscription tiers', () {
      final freemiumUser = UserProfile(
        id: '1',
        name: 'User',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'freemium',
        injuries: [],
        hasCompletedFirstIntake: false,
        hasCompletedSecondIntake: false,
      );

      expect(freemiumUser.subscriptionTier, 'freemium');

      final premiumUser = UserProfile(
        id: '2',
        name: 'User',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'premium',
        injuries: [],
        hasCompletedFirstIntake: true,
        hasCompletedSecondIntake: true,
      );

      expect(premiumUser.subscriptionTier, 'premium');
    });

    test('should handle injuries list', () {
      final user = UserProfile(
        id: '1',
        name: 'User',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'premium',
        injuries: ['shoulder', 'knee'],
        hasCompletedFirstIntake: true,
        hasCompletedSecondIntake: true,
      );

      expect(user.injuries.length, 2);
      expect(user.injuries.contains('shoulder'), true);
    });

    test('should track intake completion', () {
      final userComplete = UserProfile(
        id: '1',
        name: 'User',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'premium',
        injuries: [],
        hasCompletedFirstIntake: true,
        hasCompletedSecondIntake: true,
      );

      expect(userComplete.hasCompletedFirstIntake, true);
      expect(userComplete.hasCompletedSecondIntake, true);

      final userIncomplete = UserProfile(
        id: '2',
        name: 'User',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'freemium',
        injuries: [],
        hasCompletedFirstIntake: true,
        hasCompletedSecondIntake: false,
      );

      expect(userIncomplete.hasCompletedFirstIntake, true);
      expect(userIncomplete.hasCompletedSecondIntake, false);
    });

    test('should handle fitness score', () {
      final user = UserProfile(
        id: '1',
        name: 'User',
        phoneNumber: '+966501234567',
        role: 'client',
        subscriptionTier: 'premium',
        injuries: [],
        hasCompletedFirstIntake: true,
        hasCompletedSecondIntake: true,
        fitnessScore: 85,
        fitnessScoreUpdatedBy: 'coach123',
      );

      expect(user.fitnessScore, 85);
      expect(user.fitnessScoreUpdatedBy, 'coach123');
    });
  });
}