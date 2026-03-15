import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_profile.dart';
import '../../core/config/api_config.dart';
import '../auth/social_auth_client.dart';

abstract class AuthRepositoryBase {
  Future<void> requestOTP(String phoneNumber);
  Future<AuthResponse> verifyOTP(String phoneNumber, String otpCode);
  Future<AuthResponse> loginWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  });
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  });
  Future<AuthResponse> socialLogin(String provider);
  Future<String?> getStoredToken();
  Future<void> storeToken(String token);
  Future<void> removeToken();
  Future<UserProfile?> getUserProfile();
  Future<void> logout();
  Future<String?> refreshToken();
}

class AuthResponse {
  final String token;
  final UserProfile user;
  final bool isNewUser;

  AuthResponse(
      {required this.token, required this.user, required this.isNewUser});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String,
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      isNewUser: json['isNewUser'] ?? false,
    );
  }
}

class AuthRepository implements AuthRepositoryBase {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final SocialAuthClient _socialAuthClient;

  static const String _tokenKey = 'fitcoach_auth_token';

  AuthRepository({SocialAuthClient? socialAuthClient})
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
          contentType: ApiConfig.contentType,
        )),
        _secureStorage = const FlutterSecureStorage(),
        _socialAuthClient = socialAuthClient ?? DefaultSocialAuthClient() {
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );
  }

  // Request OTP
  @override
  Future<void> requestOTP(String phoneNumber) async {
    try {
      await _dio.post('/auth/send-otp', data: {
        'phoneNumber': phoneNumber,
      });
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to send OTP'));
    }
  }

  // Verify OTP
  @override
  Future<AuthResponse> verifyOTP(String phoneNumber, String otpCode) async {
    try {
      final response = await _dio.post(
        '/auth/verify-otp',
        data: {
          'phoneNumber': phoneNumber,
          'otpCode': otpCode,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      return AuthResponse(
          user: user, token: token, isNewUser: data['isNewUser'] ?? false);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to verify OTP'));
    }
  }

  // Login with email or phone + password
  @override
  Future<AuthResponse> loginWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'emailOrPhone': emailOrPhone,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      return AuthResponse(user: user, token: token, isNewUser: false);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Login failed'));
    }
  }

  // Signup with email
  @override
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      return AuthResponse(user: user, token: token, isNewUser: true);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Signup failed'));
    }
  }

  // Social login (Google, Facebook, Apple)
  @override
  Future<AuthResponse> socialLogin(String provider) async {
    try {
      final socialAuth = await _socialAuthClient.signIn(provider);
      final response = await _dio.post(
        '/auth/social-login',
        data: {
          'provider': socialAuth.provider,
          'accessToken': socialAuth.accessToken,
          'socialId': socialAuth.socialId,
          'email': socialAuth.email,
          'name': socialAuth.name,
          'profilePhoto': socialAuth.profilePhoto,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final user = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
      final token = data['token'] as String;

      return AuthResponse(
          user: user, token: token, isNewUser: data['isNewUser'] ?? false);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Social login failed'));
    }
  }

  String _readableError(DioException error, {required String fallback}) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'] ?? data['details'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      return '$fallback (${response.statusCode ?? 'unknown status'})';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Check the API server and URL.';
      case DioExceptionType.connectionError:
        return 'Cannot reach ${ApiConfig.baseUrl}. Check that the backend is running and reachable from this device.';
      case DioExceptionType.badCertificate:
        return 'TLS certificate error while contacting the API.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
      case DioExceptionType.badResponse:
        return fallback;
    }
  }

  // Get stored token
  @override
  Future<String?> getStoredToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      return null;
    }
  }

  // Store token
  @override
  Future<void> storeToken(String token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
    } catch (e) {
      throw Exception('Failed to store authentication token');
    }
  }

  // Get user profile
  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final token = await getStoredToken();

      if (token == null) {
        return null;
      }

      final response = await _dio.get(
        '/users/me',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token expired, clear it
        await logout();
        return null;
      }
      return null;
    }
  }

  // Remove token
  @override
  Future<void> removeToken() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      throw Exception('Failed to remove authentication token');
    }
  }

  // Logout
  @override
  Future<void> logout() async {
    try {
      final token = await getStoredToken();
      if (token != null) {
        await _dio.post(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $token'}),
        );
      }
      await _secureStorage.delete(key: _tokenKey);
    } catch (e) {
      throw Exception('Failed to logout');
    }
  }

  // Refresh token
  @override
  Future<String?> refreshToken() async {
    try {
      final currentToken = await getStoredToken();

      if (currentToken == null) {
        return null;
      }

      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': currentToken},
        options: Options(
          headers: {'Authorization': 'Bearer $currentToken'},
        ),
      );

      final data = response.data as Map<String, dynamic>;
      final newToken = (data['token'] ?? data['accessToken']) as String?;
      if (newToken == null) {
        return null;
      }
      await storeToken(newToken);

      return newToken;
    } catch (e) {
      return null;
    }
  }
}
