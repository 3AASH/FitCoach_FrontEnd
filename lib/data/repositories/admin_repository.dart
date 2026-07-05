import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/admin_analytics.dart';
import '../models/admin_user.dart';
import '../models/admin_coach.dart';
import '../models/admin_exercise.dart';
import '../models/admin_workout_template.dart';
import '../models/revenue_analytics.dart';
import '../models/audit_log.dart';
import '../../core/config/api_config.dart';

class CoachCredentials {
  final String email;
  final String defaultPassword;

  const CoachCredentials({
    required this.email,
    required this.defaultPassword,
  });
}

class AdminCoachUpdatePayload {
  final String fullName;
  final String? fullNameAr;
  final String email;
  final String? phoneNumber;
  final String? profilePhotoUrl;
  final String? bio;
  final int? yearsOfExperience;
  final List<String> specializations;
  final bool isApproved;
  final bool isActive;

  const AdminCoachUpdatePayload({
    required this.fullName,
    this.fullNameAr,
    required this.email,
    this.phoneNumber,
    this.profilePhotoUrl,
    this.bio,
    this.yearsOfExperience,
    required this.specializations,
    required this.isApproved,
    required this.isActive,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      if (fullNameAr != null) 'fullNameAr': fullNameAr,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (profilePhotoUrl != null) 'profilePhotoUrl': profilePhotoUrl,
      if (bio != null) 'bio': bio,
      if (yearsOfExperience != null) 'yearsOfExperience': yearsOfExperience,
      'specializations': specializations,
      'isApproved': isApproved,
      'isActive': isActive,
    };
  }
}

class CoachCreationResult {
  final AdminCoach coach;
  final CoachCredentials? credentials;

  const CoachCreationResult({
    required this.coach,
    this.credentials,
  });
}

class AdminRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  final Future<String?> Function()? _tokenReader;
  static const String _tokenKey = 'fitcoach_auth_token';
  static const bool _enableDebugLogs = true;

  AdminRepository({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
    Future<String?> Function()? tokenReader,
  })  : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _tokenReader = tokenReader;

  Future<Options> _getAuthOptions() async {
    final token = _tokenReader != null
        ? await _tokenReader()
        : await _secureStorage.read(key: _tokenKey);
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': ApiConfig.contentType,
      },
      contentType: ApiConfig.contentType,
    );
  }

  Future<Options> _getUploadAuthOptions() async {
    final token = _tokenReader != null
        ? await _tokenReader()
        : await _secureStorage.read(key: _tokenKey);
    return Options(
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Get dashboard analytics
  Future<AdminAnalytics> getDashboardAnalytics() async {
    const endpoint = '/admin/analytics';
    _debugLog('[AdminRepository] GET ${_dio.options.baseUrl}$endpoint');
    try {
      final response = await _dio.get(
        endpoint,
        options: await _getAuthOptions(),
      );
      _debugLog(
          '[AdminRepository] $endpoint status=${response.statusCode ?? 'unknown'} body=${_toRawBody(response.data)}');
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final analyticsMap =
          _asMap(data['analytics']) ?? _asMap(data['data']) ?? data;
      return AdminAnalytics.fromJson(analyticsMap);
    } on DioException catch (e) {
      _debugLog(
          '[AdminRepository] $endpoint status=${e.response?.statusCode ?? 'unknown'} body=${_toRawBody(e.response?.data)}');
      throw Exception(_readableError(e, fallback: 'Failed to get analytics'));
    }
  }

  /// Get all users with filters
  Future<List<AdminUser>> getUsers({
    String? search,
    String? subscriptionTier,
    String? status,
    String? coachId,
    int limit = 50,
    int offset = 0,
  }) async {
    const endpoint = '/admin/users';
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        if (search != null) 'search': search,
        if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
        if (status != null) 'status': status,
        if (coachId != null) 'coachId': coachId,
      };

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );
      _debugLog(
          '[AdminRepository] GET ${_dio.options.baseUrl}$endpoint status=${response.statusCode ?? 'unknown'} body=${_toRawBody(response.data)}');

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final usersList = _asList(
        data['users'] ??
            (_asMap(data['data'])?['users']) ??
            data['data'] ??
            data['results'],
      );

      return usersList
          .map((json) =>
              AdminUser.fromJson(_asMap(json) ?? const <String, dynamic>{}))
          .toList();
    } on DioException catch (e) {
      _debugLog(
          '[AdminRepository] $endpoint status=${e.response?.statusCode ?? 'unknown'} body=${_toRawBody(e.response?.data)}');
      throw Exception(_readableError(e, fallback: 'Failed to get users'));
    }
  }

  /// Get user by ID
  Future<AdminUser> getUserById(String id) async {
    try {
      final response = await _dio.get(
        '/admin/users/$id',
        options: await _getAuthOptions(),
      );
      final data = response.data as Map<String, dynamic>;
      final user = _asMap(data['user']) ?? _asMap(data['data']) ?? data;
      return AdminUser.fromJson(user);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to get user'));
    }
  }

  /// Update user
  Future<AdminUser> updateUser(
    String id, {
    String? fullName,
    String? email,
    String? subscriptionTier,
    bool? isActive,
    String? coachId,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/users/$id',
        data: {
          if (fullName != null) 'fullName': fullName,
          if (email != null) 'email': email,
          if (subscriptionTier != null) 'subscriptionTier': subscriptionTier,
          if (isActive != null) 'isActive': isActive,
          if (coachId != null) 'coachId': coachId,
        },
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final user = _asMap(data['user']) ?? _asMap(data['data']) ?? data;
      return AdminUser.fromJson(user);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to update user'));
    }
  }

  /// Suspend user
  Future<void> suspendUser(String id, String reason) async {
    try {
      await _dio.post(
        '/admin/users/$id/suspend',
        data: {'reason': reason},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to suspend user'));
    }
  }

  /// Delete user
  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete(
        '/admin/users/$id',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to delete user'));
    }
  }

  /// Get all coaches
  Future<List<AdminCoach>> getCoaches({
    String? search,
    String? status,
    String? approved,
    int limit = 50,
    int offset = 0,
  }) async {
    const endpoint = '/admin/coaches';
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        if (search != null) 'search': search,
        if (status != null) 'status': status,
        if (approved != null) 'approved': approved,
      };

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final coachesList = _asList(
        data['coaches'] ??
            (_asMap(data['data'])?['coaches']) ??
            data['data'] ??
            data['results'],
      );

      return coachesList
          .map((json) =>
              AdminCoach.fromJson(_asMap(json) ?? const <String, dynamic>{}))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to get coaches'));
    }
  }

  /// Create a new coach account directly (auto approved/active by backend)
  Future<CoachCreationResult> createCoach({
    required String fullName,
    required String email,
    required String phoneNumber,
    List<String>? specializations,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/coaches',
        data: {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber,
          if (specializations != null && specializations.isNotEmpty)
            'specializations': specializations,
        },
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final coach = _asMap(data['coach']) ?? _asMap(data['data']) ?? data;
      final credentialsMap = _asMap(data['credentials']);

      CoachCredentials? credentials;
      if (credentialsMap != null) {
        credentials = CoachCredentials(
          email: (credentialsMap['email'] ?? email).toString(),
          defaultPassword:
              (credentialsMap['defaultPassword'] ?? '123456').toString(),
        );
      }

      return CoachCreationResult(
        coach: AdminCoach.fromJson(coach),
        credentials: credentials,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception('email already exists');
      }
      throw Exception(_readableError(e, fallback: 'Failed to create coach'));
    }
  }

  /// Approve coach
  Future<void> approveCoach(String id) async {
    try {
      await _dio.post(
        '/admin/coaches/$id/approve',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to approve coach'));
    }
  }

  /// Suspend coach
  Future<AdminCoach?> suspendCoach(String id, String reason) async {
    try {
      final response = await _dio.post(
        '/admin/coaches/$id/suspend',
        data: {'reason': reason},
        options: await _getAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final coach = _asMap(data['coach']) ?? _asMap(data['data']);
      return coach == null ? null : AdminCoach.fromJson(coach);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to suspend coach'));
    }
  }

  Future<AdminCoach> updateCoach(
      String id, AdminCoachUpdatePayload payload) async {
    try {
      final response = await _dio.put(
        '/admin/coaches/$id',
        data: payload.toJson(),
        options: await _getAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final coach = _asMap(data['coach']) ?? _asMap(data['data']) ?? data;
      return AdminCoach.fromJson(coach);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to update coach'));
    }
  }

  Future<void> deleteCoach(String id) async {
    try {
      await _dio.delete(
        '/admin/coaches/$id',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to delete coach'));
    }
  }

  Future<List<AdminExercise>> getExercises({
    String? search,
    String? category,
    String? difficulty,
    int limit = 100,
    int offset = 0,
  }) async {
    const endpoint = '/admin/exercises';
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (search != null && search.trim().isNotEmpty) 'search': search,
          if (category != null && category.trim().isNotEmpty)
            'category': category,
          if (difficulty != null && difficulty.trim().isNotEmpty)
            'difficulty': difficulty,
        },
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final list = _asList(
        data['exercises'] ??
            (_asMap(data['data'])?['exercises']) ??
            data['data'],
      );

      return list
          .map((json) =>
              AdminExercise.fromJson(_asMap(json) ?? const <String, dynamic>{}))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to get exercises'));
    }
  }

  Future<AdminExercise> createExercise(AdminExercise exercise) async {
    try {
      final response = await _dio.post(
        '/admin/exercises',
        data: exercise.toAdminPayload(),
        options: await _getAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final payload = _asMap(data['exercise']) ?? _asMap(data['data']) ?? data;
      return AdminExercise.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to create exercise'));
    }
  }

  Future<AdminExercise> updateExercise(AdminExercise exercise) async {
    try {
      final response = await _dio.put(
        '/admin/exercises/${exercise.id}',
        data: exercise.toAdminPayload(),
        options: await _getAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final payload = _asMap(data['exercise']) ?? _asMap(data['data']) ?? data;
      return AdminExercise.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to update exercise'));
    }
  }

  Future<void> deleteExercise(String id) async {
    try {
      await _dio.delete(
        '/admin/exercises/$id',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to delete exercise'));
    }
  }

  Future<AdminExercise> uploadExerciseVideo(String id, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'video': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '/admin/exercises/$id/video',
        data: formData,
        options: await _getUploadAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final payload = _asMap(data['exercise']) ?? data;
      return AdminExercise.fromJson(payload);
    } on DioException catch (e) {
      throw Exception(
          _readableError(e, fallback: 'Failed to upload exercise video'));
    }
  }

  Future<List<AdminWorkoutTemplate>> getWorkoutTemplates({
    String? type,
    String? goal,
    String? location,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/workout-templates',
        queryParameters: {
          if (type != null && type.trim().isNotEmpty) 'type': type,
          if (goal != null && goal.trim().isNotEmpty) 'goal': goal,
          if (location != null && location.trim().isNotEmpty)
            'location': location,
        },
        options: await _getAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final list = _asList(data['templates'] ?? data['data']);
      return list
          .map((json) => AdminWorkoutTemplate.fromJson(
              _asMap(json) ?? const <String, dynamic>{}))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          _readableError(e, fallback: 'Failed to get workout templates'));
    }
  }

  Future<Map<String, dynamic>> getWorkoutTemplate(String planId) async {
    try {
      final response = await _dio.get(
        '/admin/workout-templates/$planId',
        options: await _getAuthOptions(),
      );
      final data = _asMap(response.data) ?? const <String, dynamic>{};
      return _asMap(data['template']) ?? const <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(
          _readableError(e, fallback: 'Failed to get workout template'));
    }
  }

  Future<Map<String, dynamic>> saveWorkoutTemplate(
      Map<String, dynamic> template) async {
    final planId = template['plan_id']?.toString();
    if (planId == null || planId.trim().isEmpty) {
      throw Exception('Workout template plan_id is required');
    }
    try {
      final response = await _dio.put(
        '/admin/workout-templates/$planId',
        data: template,
        options: await _getAuthOptions(),
      );
      return _asMap(response.data) ?? const <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(
          _readableError(e, fallback: 'Failed to save workout template'));
    }
  }

  Future<Map<String, dynamic>> importWorkoutTemplatesFromFile(
      String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _dio.post(
        '/admin/workout-templates/import',
        data: formData,
        options: await _getUploadAuthOptions(),
      );
      return _asMap(response.data) ?? const <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(
          _readableError(e, fallback: 'Failed to import workout templates'));
    }
  }

  Future<Map<String, dynamic>> refreshWorkoutTemplateUsers(
      String planId) async {
    try {
      final response = await _dio.post(
        '/admin/workout-templates/$planId/refresh-users',
        options: await _getAuthOptions(),
      );
      return _asMap(response.data) ?? const <String, dynamic>{};
    } on DioException catch (e) {
      throw Exception(_readableError(e,
          fallback: 'Failed to refresh users for workout template'));
    }
  }

  /// Get revenue analytics
  Future<RevenueAnalytics> getRevenueAnalytics({
    String period = 'month',
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        'period': period,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '/admin/revenue',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final revenue = _asMap(data['revenue']) ?? _asMap(data['data']) ?? data;
      return RevenueAnalytics.fromJson(revenue);
    } on DioException catch (e) {
      throw Exception(
          _readableError(e, fallback: 'Failed to get revenue analytics'));
    }
  }

  /// Get audit logs
  Future<List<AuditLog>> getAuditLogs({
    String? userId,
    String? action,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        if (userId != null) 'userId': userId,
        if (action != null) 'action': action,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '/admin/audit-logs',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      final data = _asMap(response.data) ?? const <String, dynamic>{};
      final logsList = _asList(
        data['logs'] ?? (_asMap(data['data'])?['logs']) ?? data['data'],
      );

      return logsList
          .map((json) =>
              AuditLog.fromJson(_asMap(json) ?? const <String, dynamic>{}))
          .toList();
    } on DioException catch (e) {
      throw Exception(_readableError(e, fallback: 'Failed to get audit logs'));
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic> _asList(dynamic value) {
    if (value is List) return value;
    return const [];
  }

  String _toRawBody(dynamic body) {
    if (body == null) return 'null';
    if (body is String) return body;
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  void _debugLog(String message) {
    if (_enableDebugLogs && kDebugMode) {
      debugPrint(message);
    }
  }

  String _readableError(DioException error, {required String fallback}) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      final map = _asMap(data);
      if (map != null) {
        final message = map['message'] ?? map['error'] ?? map['details'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
        }
      }
      if (data is String && data.trim().isNotEmpty) {
        return data;
      }
      return '$fallback (${response.statusCode ?? 'unknown status'})';
    }
    return fallback;
  }
}
