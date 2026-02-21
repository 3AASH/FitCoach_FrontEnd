import 'package:fitapp/core/config/demo_config.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/repositories/rating_repository.dart';
import 'package:fitapp/data/repositories/user_repository.dart';
import 'package:fitapp/presentation/providers/auth_provider.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';
import 'package:fitapp/presentation/screens/profile/profile_edit_screen.dart';
import 'package:fitapp/presentation/screens/settings/notification_settings_screen.dart';
import 'package:fitapp/presentation/screens/video_call/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository implements AuthRepositoryBase {
  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<UserProfile?> getUserProfile() async => UserProfile(
        id: 'user-1',
        phoneNumber: '+966500000001',
        name: 'Test User',
        role: 'user',
        age: 30,
      );

  @override
  Future<void> requestOTP(String phoneNumber) async {}

  @override
  Future<AuthResponse> verifyOTP(String phoneNumber, String otp) async => AuthResponse(
        token: 'token',
        user: UserProfile(
          id: 'user-1',
          phoneNumber: '+966500000001',
          name: 'Test User',
          role: 'user',
          age: 30,
        ),
        isNewUser: false,
      );

  @override
  Future<AuthResponse> loginWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async =>
      throw UnimplementedError();

  @override
  Future<AuthResponse> socialLogin(String provider) async => throw UnimplementedError();

  @override
  Future<void> storeToken(String token) async {}

  @override
  Future<void> removeToken() async {}

  @override
  Future<String?> refreshToken() async => null;

  @override
  Future<void> logout() async {}
}

class _FakeUserRepository extends UserRepository {
  _FakeUserRepository()
      : super(
          tokenReader: () async => 'test-token',
        );

  bool removePhotoCalled = false;
  Map<String, dynamic>? updatedNotificationSettings;

  @override
  Future<void> removeProfilePhoto() async {
    removePhotoCalled = true;
  }

  @override
  Future<Map<String, dynamic>> getNotificationSettings() async {
    return {
      'push_enabled': true,
      'email_enabled': true,
      'sms_enabled': false,
      'workout_reminders': true,
      'coach_messages_notifications': true,
      'nutrition_tracking_notifications': false,
      'promotions_notifications': true,
    };
  }

  @override
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    updatedNotificationSettings = settings;
  }
}

class _FakeRatingRepository extends RatingRepository {
  String? coachId;
  String? appointmentId;
  int? rating;
  String? feedback;

  @override
  Future<void> submitVideoCallRating({
    required String coachId,
    required String appointmentId,
    required int rating,
    String? feedback,
  }) async {
    this.coachId = coachId;
    this.appointmentId = appointmentId;
    this.rating = rating;
    this.feedback = feedback;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<LanguageProvider> _languageProvider() async {
    final provider = LanguageProvider();
    await provider.setLanguage('en');
    return provider;
  }

  Widget _wrap({
    required Widget child,
    required LanguageProvider languageProvider,
    required AuthProvider authProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LanguageProvider>.value(value: languageProvider),
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('profile photo remove flow triggers repository remove', (tester) async {
    final languageProvider = await _languageProvider();
    final authProvider = AuthProvider(_MockAuthRepository());
    final repository = _FakeUserRepository();

    await tester.pumpWidget(
      _wrap(
        child: ProfileEditScreen(
          userRepository: repository,
          imagePicker: ImagePicker(),
        ),
        languageProvider: languageProvider,
        authProvider: authProvider,
      ),
    );
    await tester.pump();

    final dynamic state = tester.state(find.byType(ProfileEditScreen));
    await state.removePhotoForTest();
    await tester.pump(const Duration(milliseconds: 200));

    expect(repository.removePhotoCalled, isTrue);
  });

  testWidgets('account settings save flow updates notification settings', (tester) async {
    final languageProvider = await _languageProvider();
    final authProvider = AuthProvider(_MockAuthRepository());
    final repository = _FakeUserRepository();

    await tester.pumpWidget(
      _wrap(
        child: NotificationSettingsScreen(userRepository: repository),
        languageProvider: languageProvider,
        authProvider: authProvider,
      ),
    );
    await tester.pump();

    final pushToggle = find.byType(SwitchListTile).first;
    await tester.tap(pushToggle);
    await tester.pump();

    expect(repository.updatedNotificationSettings, isNotNull);
    expect(repository.updatedNotificationSettings!['pushEnabled'], isFalse);
  });

  testWidgets('rating submit flow sends rating to repository', (tester) async {
    final repository = _FakeRatingRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VideoCallScreen(
            appointmentId: 'appt-1',
            coachId: 'coach-1',
            coachName: 'Coach',
            autoInitialize: false,
            ratingRepository: repository,
          ),
        ),
      ),
    );
    await tester.pump();

    final dynamic state = tester.state(find.byType(VideoCallScreen));
    await state.submitRatingForTest(5, 'Great session');
    await tester.pump(const Duration(milliseconds: 200));

    if (DemoConfig.isDemo) {
      expect(repository.rating, isNull);
    } else {
      expect(repository.coachId, 'coach-1');
      expect(repository.appointmentId, 'appt-1');
      expect(repository.rating, 5);
      expect(repository.feedback, 'Great session');
    }
  });
}
