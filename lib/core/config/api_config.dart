// API configuration.
// Centralized API endpoint configuration for different environments.

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Environment flag
  // Default points at the Hostinger PRODUCTION backend so release/TestFlight
  // builds (incl. the xcodebuild pipeline, which can't thread dart-defines)
  // hit prod out of the box. Override with `--dart-define=ENV=staging` for
  // staging or `--dart-define=ENV=development` for localhost:3000.
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _overrideSocketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: '',
  );

  // Base URLs for different environments
  static const Map<String, String> _baseUrls = {
    'development': 'http://localhost:3000/v2',
    'staging': 'https://stagingfitcoach.livingitenglish.com/v2',
    'production': 'https://fitcoach.livingitenglish.com/v2',
  };

  // Socket URLs for different environments
  static const Map<String, String> _socketUrls = {
    'development': 'http://localhost:3000',
    'staging': 'https://stagingfitcoach.livingitenglish.com',
    'production': 'https://fitcoach.livingitenglish.com',
  };

  /// Get current API base URL
  static String get baseUrl {
    if (_overrideBaseUrl.isNotEmpty) {
      return _overrideBaseUrl;
    }
    if (environment == 'development') {
      return _developmentApiBaseUrl;
    }
    return _baseUrls[environment] ?? _developmentApiBaseUrl;
  }

  /// Get current Socket URL
  static String get socketUrl {
    if (_overrideSocketUrl.isNotEmpty) {
      return _overrideSocketUrl;
    }
    if (environment == 'development') {
      return _developmentSocketUrl;
    }
    return _socketUrls[environment] ?? _developmentSocketUrl;
  }

  static String get _developmentApiBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/v2';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000/v2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:3000/v2';
    }
  }

  static String get _developmentSocketUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return 'http://localhost:3000';
    }
  }

  /// API Version
  static const String apiVersion = 'v2';

  /// Request timeout durations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Headers
  static const String contentType = 'application/json';

  /// API Endpoints
  static const String authEndpoint = '/auth';
  static const String usersEndpoint = '/users';
  static const String workoutsEndpoint = '/workouts';
  static const String nutritionEndpoint = '/nutrition';
  static const String messagesEndpoint = '/messages';
  static const String bookingsEndpoint = '/bookings';
  static const String ratingsEndpoint = '/ratings';
  static const String progressEndpoint = '/progress';
  static const String coachesEndpoint = '/coaches';
  static const String adminEndpoint = '/admin';
  static const String intakeEndpoint = '/intake';
  static const String uploadsEndpoint = '/uploads';

  /// Get full endpoint URL
  static String getEndpoint(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Check if in development mode
  static bool get isDevelopment => environment == 'development';

  /// Check if in production mode
  static bool get isProduction => environment == 'production';

  /// Check if in staging mode
  static bool get isStaging => environment == 'staging';

  /// Print current configuration (for debugging)
  static void printConfig() {
    if (!kDebugMode) {
      return;
    }
    debugPrint('=== API Configuration ===');
    debugPrint('Environment: $environment');
    debugPrint('Base URL: $baseUrl');
    debugPrint('Socket URL: $socketUrl');
    if (_overrideBaseUrl.isNotEmpty) {
      debugPrint('API override enabled');
    }
    if (_overrideSocketUrl.isNotEmpty) {
      debugPrint('Socket override enabled');
    }
    debugPrint('========================');
  }
}
