import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/providers/nutrition_provider.dart';
import 'package:fitapp/presentation/screens/nutrition/nutrition_preferences_intake_screen.dart';
import 'package:fitapp/presentation/screens/nutrition/nutrition_screen.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/repositories/nutrition_repository.dart';
import 'package:fitapp/data/models/nutrition_plan.dart';

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

class MockNutritionRepository extends NutritionRepository {
  @override
  Future<NutritionPlan?> getActivePlan() async => null;

  @override
  Future<Map<String, dynamic>> getTrialStatus() async => {'startDate': null};

  @override
  Future<void> logMeal(String mealId, Map<String, dynamic> data) async {}

  @override
  Future<List<Map<String, dynamic>>> getNutritionHistory() async => [];
}

void main() {
  group('Nutrition Screens', () {
    testWidgets('NutritionPreferencesIntakeScreen renders correctly', (tester) async {
      SharedPreferences.setMockInitialValues({'fitcoach_language': 'en'});
      final languageProvider = LanguageProvider();
      await languageProvider.setLanguage('en');
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: languageProvider,
          child: MaterialApp(
            home: NutritionPreferencesIntakeScreen(
              onComplete: (_) {},
              onBack: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NutritionPreferencesIntakeScreen), findsOneWidget);
      expect(find.text(languageProvider.t('nutrition_intake_title')), findsOneWidget);
    });

    testWidgets('NutritionScreen shows locked view for freemium', (tester) async {
      SharedPreferences.setMockInitialValues({
        'fitcoach_language': 'en',
        'nutrition_intro_seen': true,
        'nutrition_preferences_completed_user-1': true,
        'pending_nutrition_intake_user-1': false,
      });

      final authProvider = AuthProvider(MockAuthRepository());
      authProvider.updateUser(
        UserProfile(
          id: 'user-1',
          name: 'Test User',
          phoneNumber: '+966501234567',
          subscriptionTier: 'Freemium',
        ),
      );
      final languageProvider = LanguageProvider();
      await languageProvider.setLanguage('en');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: languageProvider),
            ChangeNotifierProvider(create: (_) => authProvider),
            ChangeNotifierProvider(create: (_) => NutritionProvider(MockNutritionRepository())),
          ],
          child: const MaterialApp(
            home: NutritionScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text(languageProvider.t('nutrition_locked_title')), findsOneWidget);
    });
  });
}
