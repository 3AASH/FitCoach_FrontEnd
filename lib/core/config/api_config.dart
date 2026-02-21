/// API Configuration
/// Centralized API endpoint configuration for different environments

import 'package:flutter/foundation.dart';

class ApiConfig {
  // Environment flag
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  // Base URLs for different environments
  static const Map<String, String> _baseUrls = {
    'development': 'http://localhost:3000/v2',
    'staging': 'https://staging-api.fitcoach.sa/v2',
    'production': 'https://api.fitcoach.sa/v2',
  };

  // Socket URLs for different environments
  static const Map<String, String> _socketUrls = {
    'development': 'http://localhost:3000',
    'staging': 'https://staging-api.fitcoach.sa',
    'production': 'https://api.fitcoach.sa',
  };

  /// Get current API base URL
  static String get baseUrl => _baseUrls[environment] ?? _baseUrls['development']!;

  /// Get current Socket URL
  static String get socketUrl => _socketUrls[environment] ?? _socketUrls['development']!;

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
    debugPrint('========================');
  }
}
