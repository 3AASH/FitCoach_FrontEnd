import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/nutrition_plan.dart';
import '../../core/config/api_config.dart';

class NutritionRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fitcoach_auth_token';

  NutritionRepository()
      : _dio = Dio(BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: ApiConfig.connectTimeout,
          receiveTimeout: ApiConfig.receiveTimeout,
        )),
        _secureStorage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<Options> _getAuthOptions() async {
    final token = await _getToken();
    return Options(
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  // Get active nutrition plan
  Future<NutritionPlan?> getActivePlan() async {
    try {
      final response = await _dio.get(
        '/nutrition/plan',
        options: await _getAuthOptions(),
      );

      final top = _asMap(response.data);
      if (kDebugMode && top != null) {
        debugPrint(
            '[NutritionRepository] response top-level keys=${top.keys.toList()}');
      }

      final payload = _extractNutritionPayload(response.data);
      if (payload == null) return null;
      final normalizedPayload = _mergeTopLevelProgress(
        payload: payload,
        topLevel: top,
      );
      if (kDebugMode) {
        final firstMeal = _findFirstRawMeal(normalizedPayload);
        if (firstMeal != null) {
          debugPrint(
            '[NutritionRepository] first meal raw keys=${firstMeal.keys.toList()} resolvedName=${resolveMealName(firstMeal)}',
          );
        }
      }
      return NutritionPlan.fromJson(normalizedPayload);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No active plan
      }
      final message = _readErrorMessage(e.response?.data);
      throw Exception(message ?? 'Failed to load nutrition plan');
    }
  }

  // Get trial status for Freemium users
  Future<Map<String, dynamic>> getTrialStatus() async {
    try {
      final response = await _dio.get(
        '/nutrition/trial-status',
        options: await _getAuthOptions(),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to get trial status');
    }
  }

  // Log meal consumption
  Future<Map<String, dynamic>> logMeal(
    String mealId,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _dio.post(
        '/nutrition/meals/$mealId/log',
        data: data,
        options: await _getAuthOptions(),
      );
      final map = _asMap(response.data) ?? const <String, dynamic>{};
      final today = _asMap(map['todayProgress'] ?? map['today_progress']) ??
          <String, dynamic>{
            'consumedCalories': map['consumedCalories'],
            'remainingCalories': map['remainingCalories'],
            'targetCalories': map['targetCalories'],
            'progressPercent': map['progressPercent'],
            'consumedProtein': map['consumedProtein'],
            'consumedCarbs': map['consumedCarbs'],
            'consumedFats': map['consumedFats'],
          };
      return {
        'todayProgress': today,
        'success': map['success'],
        'message': map['message'],
      };
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to log meal');
    }
  }

  // Get nutrition history
  Future<List<Map<String, dynamic>>> getNutritionHistory() async {
    try {
      final response = await _dio.get(
        '/nutrition/history',
        options: await _getAuthOptions(),
      );

      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load history');
    }
  }

  // Generate nutrition plan using preferences/intake
  Future<Map<String, dynamic>> generatePlan(
      Map<String, dynamic> preferences) async {
    try {
      final response = await _dio.post(
        '/nutrition/generate',
        data: preferences,
        options: await _getAuthOptions(),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to generate nutrition plan');
    }
  }

  Map<String, dynamic>? _extractNutritionPayload(dynamic data) {
    final map = _asMap(data);
    if (map == null) return null;

    if (map.containsKey('id') ||
        map.containsKey('days') ||
        map.containsKey('meals')) {
      return map;
    }

    for (final key in const [
      'nutritionPlan',
      'nutrition_plan',
      'plan',
      'data'
    ]) {
      final nested = _asMap(map[key]);
      if (nested != null) return nested;
    }

    if (map['success'] == true) {
      for (final value in map.values) {
        final nested = _asMap(value);
        if (nested != null) return nested;
      }
    }

    return null;
  }

  Map<String, dynamic> _mergeTopLevelProgress({
    required Map<String, dynamic> payload,
    required Map<String, dynamic>? topLevel,
  }) {
    if (topLevel == null) return payload;
    final merged = Map<String, dynamic>.from(payload);
    final today =
        _asMap(topLevel['todayProgress'] ?? topLevel['today_progress']);
    if (today != null) {
      merged['todayProgress'] = today;
    } else {
      merged['todayProgress'] = {
        'targetCalories': topLevel['targetCalories'],
        'consumedCalories': topLevel['consumedCalories'],
        'remainingCalories': topLevel['remainingCalories'],
        'progressPercent': topLevel['progressPercent'],
        'consumedProtein': topLevel['consumedProtein'],
        'consumedCarbs': topLevel['consumedCarbs'],
        'consumedFats': topLevel['consumedFats'],
      };
    }
    return merged;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List) return value;
    return null;
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

  String? _readErrorMessage(dynamic data) {
    final map = _asMap(data);
    if (map == null) return null;
    final value = map['message'] ?? map['error'] ?? map['details'];
    return value?.toString();
  }
}
