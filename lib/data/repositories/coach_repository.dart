import '../models/coach_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/coach_client.dart';
import '../models/appointment.dart';
import '../models/coach_analytics.dart';
import '../models/coach_earnings.dart';
import '../models/workout_plan.dart';
import '../models/nutrition_plan.dart';
import '../../core/config/api_config.dart';

class CoachRepository {

  /// Get comprehensive coach profile
  Future<CoachProfile> getCoachProfile({required String coachId}) async {
    try {
      final response = await _dio.get(
        '/coaches/$coachId/profile',
        options: await _getAuthOptions(),
      );
      return CoachProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get coach profile');
    }
  }
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  CoachRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )),
        _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'fitcoach_auth_token';

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  /// Get coach's clients
  Future<List<CoachClient>> getClients({
    required String coachId,
    String? status,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        if (status != null) 'status': status,
        if (search != null) 'search': search,
      };

      final response = await _dio.get(
        '/coaches/$coachId/clients',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final clientsList = data['clients'] as List;
      
      return clientsList
          .map((json) => CoachClient.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get clients');
    }
  }

  /// Get specific client details
  Future<CoachClient> getClientById({
    required String coachId,
    required String clientId,
  }) async {
    try {
      final clients = await getClients(coachId: coachId);
      return clients.firstWhere((c) => c.id == clientId);
    } catch (e) {
      throw Exception('Failed to get client details');
    }
  }

  /// Get coach's appointments
  Future<List<Appointment>> getAppointments({
    required String coachId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final queryParams = {
        'limit': limit,
        'offset': offset,
        if (status != null) 'status': status,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await _dio.get(
        '/coaches/$coachId/appointments',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      final appointmentsList = data['appointments'] as List;
      
      return appointmentsList
          .map((json) => Appointment.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get appointments');
    }
  }

  /// Create new appointment
  Future<Appointment> createAppointment({
    required String coachId,
    required String userId,
    required DateTime scheduledAt,
    required int duration,
    required String type,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/coaches/$coachId/appointments',
        data: {
          'userId': userId,
          'scheduledAt': scheduledAt.toIso8601String(),
          'duration': duration,
          'type': type,
          if (notes != null) 'notes': notes,
        },
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return Appointment.fromJson(data['appointment'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to create appointment');
    }
  }

  /// Update appointment
  Future<Appointment> updateAppointment({
    required String coachId,
    required String appointmentId,
    DateTime? scheduledAt,
    int? duration,
    String? type,
    String? notes,
    String? status,
  }) async {
    try {
      final response = await _dio.put(
        '/coaches/$coachId/appointments/$appointmentId',
        data: {
          if (scheduledAt != null) 'scheduledAt': scheduledAt.toIso8601String(),
          if (duration != null) 'duration': duration,
          if (type != null) 'type': type,
          if (notes != null) 'notes': notes,
          if (status != null) 'status': status,
        },
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return Appointment.fromJson(data['appointment'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update appointment');
    }
  }

  /// Get coach earnings
  Future<CoachEarnings> getEarnings({
    required String coachId,
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
        '/coaches/$coachId/earnings',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return CoachEarnings.fromJson(data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get earnings');
    }
  }

  /// Assign fitness score to client
  Future<void> assignFitnessScore({
    required String coachId,
    required String clientId,
    required int fitnessScore,
    String? notes,
  }) async {
    try {
      await _dio.put(
        '/coaches/$coachId/clients/$clientId/fitness-score',
        data: {
          'fitnessScore': fitnessScore,
          if (notes != null) 'notes': notes,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to assign fitness score');
    }
  }

  /// Get coach analytics/dashboard stats
  Future<CoachAnalytics> getAnalytics({
    required String coachId,
  }) async {
    try {
      final response = await _dio.get(
        '/coaches/$coachId/analytics',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      return CoachAnalytics.fromJson(data['analytics'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get analytics');
    }
  }

  /// Get client's workout plan
  Future<WorkoutPlan?> getClientWorkoutPlan({
    required String coachId,
    required String clientId,
  }) async {
    try {
      final response = await _dio.get(
        '/coaches/$coachId/clients/$clientId/workout-plan',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['workoutPlan'] == null) {
        return null;
      }
      return WorkoutPlan.fromJson(data['workoutPlan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get workout plan');
    }
  }

  /// Update client's workout plan
  Future<void> updateClientWorkoutPlan({
    required String coachId,
    required String clientId,
    required Map<String, dynamic> planData,
    required String notes,
  }) async {
    try {
      await _dio.put(
        '/coaches/$coachId/clients/$clientId/workout-plan',
        data: {
          'planData': planData,
          'notes': notes,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update workout plan');
    }
  }

  /// Get client's nutrition plan
  Future<NutritionPlan?> getClientNutritionPlan({
    required String coachId,
    required String clientId,
  }) async {
    try {
      final response = await _dio.get(
        '/coaches/$coachId/clients/$clientId/nutrition-plan',
        options: await _getAuthOptions(),
      );

      final data = response.data as Map<String, dynamic>;
      if (data['nutritionPlan'] == null) {
        return null;
      }
      return NutritionPlan.fromJson(data['nutritionPlan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to get nutrition plan');
    }
  }

  /// Update client's nutrition plan
  Future<void> updateClientNutritionPlan({
    required String coachId,
    required String clientId,
    required int dailyCalories,
    required Map<String, dynamic> macros,
    required Map<String, dynamic> mealPlan,
    required String notes,
  }) async {
    try {
      await _dio.put(
        '/coaches/$coachId/clients/$clientId/nutrition-plan',
        data: {
          'dailyCalories': dailyCalories,
          'macros': macros,
          'mealPlan': mealPlan,
          'notes': notes,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update nutrition plan');
    }
  }
}