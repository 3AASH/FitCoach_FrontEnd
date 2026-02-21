import '../models/quota_status.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../../core/config/api_config.dart';

class UserRepository {
    // Get user quota status
    Future<QuotaStatus> getUserQuota(String userId) async {
      try {
        final response = await _dio.get(
          '/users/$userId/quota',
          options: await _getAuthOptions(),
        );
        if (response.data['quota'] != null) {
          return QuotaStatus.fromJson(response.data['quota'] as Map<String, dynamic>);
        } else {
          throw Exception('No quota data');
        }
      } on DioException catch (e) {
        throw Exception(e.response?.data['message'] ?? 'Failed to get quota');
      }
    }
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _tokenReader;
  
  static const String _tokenKey = 'fitcoach_auth_token';
  
  UserRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function()? tokenReader,
  })
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenReader = tokenReader;
  
  Future<String?> _getToken() async {
    if (_tokenReader != null) {
      return _tokenReader();
    }
    return await _secureStorage.read(key: _tokenKey);
  }
  
  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }
  
  // Get user profile
  Future<UserProfile> getUserProfile() async {
    try {
      final response = await _dio.get(
        '/users/me',
        options: await _getAuthOptions(),
      );
      
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load profile');
    }
  }
  
  // Update user profile
  Future<Map<String, dynamic>> updateProfile(
    String userId,
    Map<String, dynamic> profileData,
  ) async {
    try {
      final response = await _dio.put(
        '/users/$userId',
        data: profileData,
        options: await _getAuthOptions(),
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update profile');
    }
  }
  
  // Submit first intake
  Future<UserProfile> submitFirstIntake(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/users/intake/first',
        data: data,
        options: await _getAuthOptions(),
      );
      
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit intake');
    }
  }
  
  // Submit second intake
  Future<UserProfile> submitSecondIntake(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        '/users/intake/second',
        data: data,
        options: await _getAuthOptions(),
      );
      
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to submit intake');
    }
  }
  
  // Update subscription
  Future<UserProfile> updateSubscription(String tier) async {
    try {
      final response = await _dio.patch(
        '/users/subscription',
        data: {'tier': tier},
        options: await _getAuthOptions(),
      );
      
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update subscription');
    }
  }
  
  // Get quota usage
  Future<Map<String, dynamic>> getQuotaUsage() async {
    try {
      final response = await _dio.get(
        '/users/quota',
        options: await _getAuthOptions(),
      );
      
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get quota');
    }
  }
  
  // Get notification settings
  Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final response = await _dio.get(
        '/settings/notifications',
        options: await _getAuthOptions(),
      );
      
      return response.data['settings'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get settings');
    }
  }
  
  // Update notification settings
  Future<void> updateNotificationSettings(Map<String, dynamic> settings) async {
    try {
      await _dio.put(
        '/settings/notifications',
        data: settings,
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update settings');
    }
  }
  
  // Change password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        '/settings/change-password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to change password');
    }
  }
  
  // Delete account
  Future<void> deleteAccount(String password) async {
    try {
      await _dio.delete(
        '/settings/delete-account',
        data: {'password': password},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete account');
    }
  }
  
  // Upload profile photo
  Future<String> uploadProfilePhoto(String imagePath) async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Unable to resolve user profile');
      }

      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(imagePath),
      });
      
      final response = await _dio.post(
        '/users/$userId/upload-photo',
        data: formData,
        options: await _getAuthOptions(),
      );
      
      return response.data['photoUrl'] as String;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to upload photo');
    }
  }

  // Remove profile photo
  Future<void> removeProfilePhoto() async {
    try {
      final userId = await _getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Unable to resolve user profile');
      }

      await _dio.post(
        '/users/$userId/upload-photo',
        data: {'remove': true},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to remove photo');
    }
  }

  Future<Map<String, dynamic>> getCoachProfileSettings() async {
    try {
      final response = await _dio.get(
        '/settings/coach-profile',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return (data['coach'] as Map?)?.cast<String, dynamic>() ?? data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load coach profile');
    }
  }

  Future<Map<String, dynamic>> getAdminProfileSettings() async {
    try {
      final response = await _dio.get(
        '/settings/admin-profile',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return (data['admin'] as Map?)?.cast<String, dynamic>() ?? data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load admin profile');
    }
  }
  
  Future<String?> _getUserId() async {
    try {
      final response = await _dio.get(
        '/users/me',
        options: await _getAuthOptions(),
      );

      final data = response.data;
      if (data is Map<String, dynamic>) {
        final directId = data['id'];
        if (directId is String && directId.isNotEmpty) {
          return directId;
        }

        final nestedUser = data['user'];
        if (nestedUser is Map<String, dynamic>) {
          final nestedId = nestedUser['id'];
          if (nestedId is String && nestedId.isNotEmpty) {
            return nestedId;
          }
        }
      }
    } catch (_) {
      // Keep null fallback so caller can surface a consistent error message.
    }
    return null;
  }
}
