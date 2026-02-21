import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/presentation/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LanguageProvider Tests', () {
    late LanguageProvider languageProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      languageProvider = LanguageProvider();
    });

    test('initial language should be Arabic', () {
      expect(languageProvider.isArabic, true);
      expect(languageProvider.currentLanguage, 'ar');
    });

     test('toggle language should switch between Arabic and English', () async {
       // Initial state
       expect(languageProvider.isArabic, true);
    
       // Toggle to English
       await languageProvider.toggleLanguage();
       expect(languageProvider.isArabic, false);
       expect(languageProvider.currentLanguage, 'en');
    
       // Toggle back to Arabic
       await languageProvider.toggleLanguage();
       expect(languageProvider.isArabic, true);
       expect(languageProvider.currentLanguage, 'ar');
     });

    test('setLanguage should update language correctly', () async {
      // Set to English
      await languageProvider.setLanguage('en');
      expect(languageProvider.isArabic, false);
      expect(languageProvider.currentLanguage, 'en');

      // Set to Arabic
      await languageProvider.setLanguage('ar');
      expect(languageProvider.isArabic, true);
      expect(languageProvider.currentLanguage, 'ar');
    });


    test('t should return correct translation', () async {
      // Test Arabic translations
      expect(languageProvider.t('welcome'), 'مرحباً بك في عاش');
      expect(languageProvider.t('login'), 'login'); // Not in translations, should return key

      // Switch to English and test
      await languageProvider.setLanguage('en');
      expect(languageProvider.t('welcome'), 'Welcome to FitCoach+');
      expect(languageProvider.t('login'), 'login'); // Not in translations, should return key
    });

    test('t should return key if translation not found', () {
      expect(languageProvider.t('nonexistent_key'), 'nonexistent_key');
    });

    test('notifyListeners should be called on language change', () async {
      var notified = false;
      languageProvider.addListener(() {
        notified = true;
      });

      await languageProvider.toggleLanguage();
      expect(notified, true);
    });
  });
}