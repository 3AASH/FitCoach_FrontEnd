import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fitapp/presentation/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider Tests', () {
    late ThemeProvider themeProvider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      themeProvider = ThemeProvider();
    });

    test('initial theme should be light', () {
      expect(themeProvider.isDarkMode, false);
      expect(themeProvider.currentTheme, ThemeMode.light);
    });

    test('toggleTheme should switch between light and dark', () async {
      // Initial state
      expect(themeProvider.isDarkMode, false);

      // Toggle to dark
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, true);
      expect(themeProvider.currentTheme, ThemeMode.dark);

      // Toggle back to light
      await themeProvider.toggleTheme();
      expect(themeProvider.isDarkMode, false);
      expect(themeProvider.currentTheme, ThemeMode.light);
    });

    test('setTheme should update theme correctly', () async {
      // Set to dark
      await themeProvider.setTheme(ThemeMode.dark);
      expect(themeProvider.isDarkMode, true);
      expect(themeProvider.currentTheme, ThemeMode.dark);

      // Set to light
      await themeProvider.setTheme(ThemeMode.light);
      expect(themeProvider.isDarkMode, false);
      expect(themeProvider.currentTheme, ThemeMode.light);
    });

    test('setTheme with system should use system theme', () async {
      await themeProvider.setTheme(ThemeMode.system);
      expect(themeProvider.currentTheme, ThemeMode.system);
    });

    test('getLightTheme should return ThemeData', () {
      final lightTheme = themeProvider.getLightTheme();
      expect(lightTheme, isA<ThemeData>());
      expect(lightTheme.brightness, Brightness.light);
    });

    test('getDarkTheme should return ThemeData', () {
      final darkTheme = themeProvider.getDarkTheme();
      expect(darkTheme, isA<ThemeData>());
      expect(darkTheme.brightness, Brightness.dark);
    });

    test('getPrimaryColor should return correct color', () {
      final primaryColor = themeProvider.getPrimaryColor();
      expect(primaryColor, isA<Color>());
    });

    test('getSecondaryColor should return correct color', () {
      final secondaryColor = themeProvider.getSecondaryColor();
      expect(secondaryColor, isA<Color>());
    });

    test('getBackgroundColor should change based on theme', () async {
      // Light mode
      final lightBg = themeProvider.getBackgroundColor();
      
      // Switch to dark
      await themeProvider.toggleTheme();
      final darkBg = themeProvider.getBackgroundColor();

      expect(lightBg, isNot(equals(darkBg)));
    });

    test('getTextColor should change based on theme', () async {
      // Light mode
      final lightText = themeProvider.getTextColor();
      
      // Switch to dark
      await themeProvider.toggleTheme();
      final darkText = themeProvider.getTextColor();

      expect(lightText, isNot(equals(darkText)));
    });

    test('getCardColor should change based on theme', () async {
      // Light mode
      final lightCard = themeProvider.getCardColor();
      
      // Switch to dark
      await themeProvider.toggleTheme();
      final darkCard = themeProvider.getCardColor();

      expect(lightCard, isNot(equals(darkCard)));
    });

    test('theme persistence should work', () async {
      // Set to dark
      await themeProvider.setTheme(ThemeMode.dark);

      // Create new provider instance
      final newProvider = ThemeProvider();
      
      // Should load saved theme
      expect(newProvider.isDarkMode, true);
    });

    test('notifyListeners should be called on theme change', () async {
      var notified = false;
      themeProvider.addListener(() {
        notified = true;
      });

      await themeProvider.toggleTheme();
      expect(notified, true);
    });

    test('getThemeData should return correct theme', () {
      final lightThemeData = themeProvider.getThemeData();
      expect(lightThemeData.brightness, Brightness.light);

      themeProvider.toggleTheme();
      final darkThemeData = themeProvider.getThemeData();
      expect(darkThemeData.brightness, Brightness.dark);
    });

    test('isSystemTheme should detect system mode', () async {
      await themeProvider.setTheme(ThemeMode.system);
      expect(themeProvider.isSystemTheme, true);

      await themeProvider.setTheme(ThemeMode.light);
      expect(themeProvider.isSystemTheme, false);
    });
  });
}