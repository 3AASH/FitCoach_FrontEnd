import 'dart:convert';

import '../models/coach_profile.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get coach profile');
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
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get appointments');
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
      throw Exception(
          e.response?.data['message'] ?? 'Failed to create appointment');
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
      throw Exception(
          e.response?.data['message'] ?? 'Failed to update appointment');
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
      throw Exception(
          e.response?.data['message'] ?? 'Failed to assign fitness score');
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

      final data = _asMap(response.data);
      if (data == null) {
        return null;
      }
      if (kDebugMode) {
        debugPrint(
          '[CoachRepository] workout-plan response top-level keys: ${data.keys.toList()}',
        );
      }

      final planJson = _extractPlanPayload(
        data: data,
        preferredKeys: const ['workoutPlan', 'workout_plan', 'plan', 'data'],
      );
      if (planJson == null) {
        return null;
      }

      if (kDebugMode) {
        debugPrint(
          '[CoachRepository] workout-plan payload keys: ${planJson.keys.toList()}',
        );
        final firstExercise = _findFirstRawWorkoutExercise(planJson);
        if (firstExercise != null) {
          debugPrint(
            '[CoachRepository] first exercise raw keys=${firstExercise.keys.toList()} resolvedName=${resolveExerciseName(firstExercise)}',
          );
        }
      }
      final parsed = WorkoutPlan.fromJson(planJson);
      if (kDebugMode) {
        final dayCount = parsed.days?.length ?? 0;
        final exerciseCount = parsed.days
                ?.fold<int>(0, (sum, day) => sum + day.exercises.length) ??
            0;
        debugPrint(
          '[CoachRepository] workout-plan parsed dayCount=$dayCount exerciseCount=$exerciseCount',
        );
      }
      return parsed;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get workout plan');
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
      final body = {
        'planData': planData,
        'notes': notes,
      };
      if (kDebugMode) {
        debugPrint(
          '[CoachRepository] PUT /coaches/$coachId/clients/$clientId/workout-plan body=${jsonEncode(body)}',
        );
      }

      final response = await _dio.put(
        '/coaches/$coachId/clients/$clientId/workout-plan',
        data: body,
        options: await _getAuthOptions(),
      );
      if (kDebugMode) {
        final keys = _asMap(response.data)?.keys.toList() ?? const [];
        debugPrint(
          '[CoachRepository] workout-plan PUT status=${response.statusCode} keys=$keys',
        );
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to update workout plan');
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

      final data = _asMap(response.data);
      if (data == null) {
        return null;
      }
      if (kDebugMode) {
        debugPrint(
          '[CoachRepository] nutrition-plan response top-level keys: ${data.keys.toList()}',
        );
      }

      final planJson = _extractPlanPayload(
        data: data,
        preferredKeys: const [
          'nutritionPlan',
          'nutrition_plan',
          'plan',
          'data',
        ],
      );
      if (planJson == null) {
        return null;
      }

      if (kDebugMode) {
        debugPrint(
          '[CoachRepository] nutrition-plan payload keys: ${planJson.keys.toList()}',
        );
        final firstMeal = _findFirstRawMeal(planJson);
        if (firstMeal != null) {
          debugPrint(
            '[CoachRepository] first meal raw keys=${firstMeal.keys.toList()} resolvedName=${resolveMealName(firstMeal)}',
          );
        }
      }
      final parsed = NutritionPlan.fromJson(planJson);
      if (kDebugMode) {
        final dayCount = parsed.days?.length ?? 0;
        final mealCount =
            parsed.days?.fold<int>(0, (sum, day) => sum + day.meals.length) ??
                0;
        debugPrint(
          '[CoachRepository] nutrition-plan parsed dayCount=$dayCount mealCount=$mealCount',
        );
      }
      return parsed;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get nutrition plan');
    }
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return null;
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return null;
  }

  Map<String, dynamic>? _findFirstRawWorkoutExercise(
      Map<String, dynamic> plan) {
    final days =
        _asList(plan['days'] ?? plan['workoutDays'] ?? plan['workout_days']);
    if (days == null || days.isEmpty) return null;
    final firstDay = _asMap(days.first);
    if (firstDay == null) return null;
    final exercises = _asList(firstDay['exercises'] ?? firstDay['workouts']);
    if (exercises == null || exercises.isEmpty) return null;
    return _asMap(exercises.first);
  }

  Map<String, dynamic>? _findFirstRawMeal(Map<String, dynamic> plan) {
    final mealPlan = _asMap(plan['mealPlan'] ?? plan['meal_plan']);
    final days = _asList(plan['days']) ??
        _asList(mealPlan?['days']) ??
        _asList(mealPlan?['mealPlanDays']);
    if (days != null && days.isNotEmpty) {
      final firstDay = _asMap(days.first);
      final dayMeals = _asList(firstDay?['meals']) ??
          _asList(_asMap(firstDay?['mealPlan'])?['meals']);
      if (dayMeals != null && dayMeals.isNotEmpty) {
        return _asMap(dayMeals.first);
      }
    }
    final flatMeals = _asList(mealPlan?['meals']) ?? _asList(plan['meals']);
    if (flatMeals != null && flatMeals.isNotEmpty) {
      return _asMap(flatMeals.first);
    }
    return null;
  }

  Map<String, dynamic>? _extractPlanPayload({
    required Map<String, dynamic> data,
    required List<String> preferredKeys,
  }) {
    for (final key in preferredKeys) {
      final nested = _asMap(data[key]);
      if (nested != null) {
        return nested;
      }
    }
    if (data['success'] == true) {
      for (final value in data.values) {
        final nested = _asMap(value);
        if (nested != null) {
          return nested;
        }
      }
    }
    if (data.containsKey('id') || data.containsKey('days')) {
      return data;
    }
    return null;
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
      final body = {
        'dailyCalories': dailyCalories,
        'macros': macros,
        'mealPlan': mealPlan,
        'notes': notes,
      };
      if (kDebugMode) {
        debugPrint(
          '[CoachRepository] PUT /coaches/$coachId/clients/$clientId/nutrition-plan body=${jsonEncode(body)}',
        );
      }

      final response = await _dio.put(
        '/coaches/$coachId/clients/$clientId/nutrition-plan',
        data: body,
        options: await _getAuthOptions(),
      );
      if (kDebugMode) {
        final keys = _asMap(response.data)?.keys.toList() ?? const [];
        debugPrint(
          '[CoachRepository] nutrition-plan PUT status=${response.statusCode} keys=$keys',
        );
      }
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to update nutrition plan');
    }
  }
}
