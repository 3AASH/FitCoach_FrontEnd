import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/workout_plan.dart';
import '../models/workout_calendar.dart';
import '../models/inbody_model.dart';
import '../../core/config/api_config.dart';

class WorkoutRepository {
  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fitcoach_auth_token';
  static const List<String> _activePlanEndpoints = [
    '/workouts/plan',
    '/workouts/active-plan',
    '/workouts/current',
    '/users/workout-plan',
  ];

  WorkoutRepository()
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

  // Get active workout plan
  Future<WorkoutPlan?> getActivePlan() async {
    final options = await _getAuthOptions();

    for (var i = 0; i < _activePlanEndpoints.length; i++) {
      final endpoint = _activePlanEndpoints[i];
      final requestUrl = '${_dio.options.baseUrl}$endpoint';
      _debugLog('[WorkoutRepository] GET $requestUrl');

      try {
        final response = await _dio.get(
          endpoint,
          options: options,
        );
        _debugLog(
          '[WorkoutRepository] status=${response.statusCode ?? 'unknown'} body=${_toRawBody(response.data)}',
        );

        final parsedPlan = _parseActivePlanResponse(response.data);
        _debugLog(
          '[WorkoutRepository] parseResult=${parsedPlan == null ? 'null' : 'id=${parsedPlan.id}, days=${parsedPlan.days?.length ?? 0}'}',
        );
        return parsedPlan;
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        _debugLog(
          '[WorkoutRepository] status=${statusCode ?? 'unknown'} body=${_toRawBody(e.response?.data)}',
        );
        if (statusCode == 404 && i < _activePlanEndpoints.length - 1) {
          _debugLog('[WorkoutRepository] fallback to next endpoint');
          continue;
        }
        if (statusCode == 404) {
          return null;
        }
        throw Exception(
            _readableError(e, fallback: 'Failed to load workout plan'));
      }
    }
    return null;
  }

  Future<WorkoutCalendarResponse> getWorkoutCalendar() async {
    const endpoint = '/workouts/calendar';
    final requestUrl = '${_dio.options.baseUrl}$endpoint';
    _debugLog('[WorkoutRepository] GET $requestUrl');
    try {
      final response = await _dio.get(
        endpoint,
        options: await _getAuthOptions(),
      );
      _debugLog(
        '[WorkoutRepository] status=${response.statusCode ?? 'unknown'} body=${_toRawBody(response.data)}',
      );
      final dataMap = _asMap(response.data) ?? const <String, dynamic>{};
      final payloadMap = _asMap(dataMap['data']) ?? dataMap;
      final parsed = WorkoutCalendarResponse.fromJson(payloadMap);
      _debugLog(
        '[WorkoutRepository] calendar parseResult previous=${parsed.previous.length} today=${parsed.today != null} upcoming=${parsed.upcoming.length} allDays=${parsed.allDays.length}',
      );
      return parsed;
    } on DioException catch (e) {
      _debugLog(
        '[WorkoutRepository] status=${e.response?.statusCode ?? 'unknown'} body=${_toRawBody(e.response?.data)}',
      );
      throw Exception(
        _readableError(e, fallback: 'Failed to load workout calendar'),
      );
    }
  }

  WorkoutPlan? _parseActivePlanResponse(dynamic data) {
    if (data == null) {
      return null;
    }

    Map<String, dynamic>? payloadMap = _asMap(data);
    if (payloadMap == null) {
      return null;
    }
    _debugLog(
        '[WorkoutRepository] response top-level keys=${payloadMap.keys.toList()}');

    if (payloadMap['data'] is Map) {
      payloadMap = _asMap(payloadMap['data']);
    }
    if (payloadMap == null) {
      return null;
    }

    if (payloadMap['plan'] is Map) {
      payloadMap = _asMap(payloadMap['plan']);
    } else if (payloadMap['workoutPlan'] is Map) {
      payloadMap = _asMap(payloadMap['workoutPlan']);
    } else if (payloadMap['workout_plan'] is Map) {
      payloadMap = _asMap(payloadMap['workout_plan']);
    }

    if (payloadMap == null) {
      return null;
    }

    final looksLikePlan = payloadMap.containsKey('id') ||
        payloadMap.containsKey('_id') ||
        payloadMap.containsKey('days') ||
        payloadMap.containsKey('workoutDays') ||
        payloadMap.containsKey('plan_data') ||
        payloadMap.containsKey('planData');
    if (!looksLikePlan) {
      return null;
    }

    final firstRawExercise = _findFirstRawWorkoutExercise(payloadMap);
    if (firstRawExercise != null) {
      _debugLog(
        '[WorkoutRepository] first exercise raw keys=${firstRawExercise.keys.toList()} resolvedName=${resolveExerciseName(firstRawExercise)}',
      );
    }

    final normalized = _normalizeWorkoutPlan(payloadMap);
    return WorkoutPlan.fromJson(normalized);
  }

  Map<String, dynamic>? _findFirstRawWorkoutExercise(
      Map<String, dynamic> plan) {
    final days =
        _asList(plan['days'] ?? plan['workoutDays'] ?? plan['plan_days']);
    if (days == null || days.isEmpty) return null;
    final firstDay = _asMap(days.first);
    if (firstDay == null) return null;
    final exercises = _asList(
      firstDay['exercises'] ?? firstDay['workouts'] ?? firstDay['activities'],
    );
    if (exercises == null || exercises.isEmpty) return null;
    return _asMap(exercises.first);
  }

  Map<String, dynamic> _normalizeWorkoutPlan(Map<String, dynamic> source) {
    final id = _asString(
      source['id'] ?? source['_id'] ?? source['planId'] ?? source['plan_id'],
      fallback: 'plan-unknown',
    );
    final userId = _asString(
      source['user_id'] ??
          source['userId'] ??
          (source['user'] is Map ? (source['user'] as Map)['id'] : null),
    );
    final coachId = _nullableString(
      source['coach_id'] ??
          source['coachId'] ??
          (source['coach'] is Map ? (source['coach'] as Map)['id'] : null),
    );
    final daysSource =
        source['days'] ?? source['workoutDays'] ?? source['plan_days'];
    final normalizedDays = _normalizeWorkoutDays(daysSource);
    final isActive =
        _asBool(source['is_active'] ?? source['isActive'], fallback: true);
    final customizedByCoach = _asBool(
      source['customized_by_coach'] ?? source['customizedByCoach'],
      fallback: false,
    );
    final totalDays = _asInt(
      source['totalDays'] ??
          source['total_days'] ??
          (normalizedDays.isNotEmpty ? normalizedDays.length : 0),
      fallback: normalizedDays.length,
    );

    return {
      ...source,
      'id': id,
      'user_id': userId,
      'coach_id': coachId,
      'days': normalizedDays,
      'is_active': isActive,
      'customized_by_coach': customizedByCoach,
      'currentDayNumber': _asInt(
          source['currentDayNumber'] ?? source['current_day_number'],
          fallback: 0),
      'currentDayId': source['currentDayId'] ?? source['current_day_id'],
      'completedDays': _asInt(
          source['completedDays'] ?? source['completed_days'],
          fallback: 0),
      'totalDays': totalDays,
      'dayProgressPercent':
          source['dayProgressPercent'] ?? source['day_progress_percent'],
      if (source['name'] == null && source['title'] != null)
        'name': source['title'],
      if (source['description'] == null && source['goal'] != null)
        'description': source['goal'],
    };
  }

  List<Map<String, dynamic>> _normalizeWorkoutDays(dynamic daysSource) {
    if (daysSource is! List) {
      return <Map<String, dynamic>>[];
    }

    final days = <Map<String, dynamic>>[];
    for (var dayIndex = 0; dayIndex < daysSource.length; dayIndex++) {
      final day = _asMap(daysSource[dayIndex]);
      if (day == null) {
        continue;
      }
      final exercisesSource =
          day['exercises'] ?? day['workouts'] ?? day['activities'];
      final exercises = _normalizeExercises(exercisesSource, dayIndex + 1);
      final totalExercises = _asInt(
        day['totalExercises'] ?? day['total_exercises'],
        fallback: exercises.length,
      );
      days.add({
        ...day,
        'id':
            _asString(day['id'] ?? day['_id'], fallback: 'day-${dayIndex + 1}'),
        'dayName': _asString(
          day['dayName'] ?? day['day_name'] ?? day['name'],
          fallback: 'Day ${dayIndex + 1}',
        ),
        'dayNameAr': _nullableString(
            day['dayNameAr'] ?? day['day_name_ar'] ?? day['nameAr']),
        'dayNumber': _asInt(day['dayNumber'] ?? day['day_number'],
            fallback: dayIndex + 1),
        'exercises': exercises,
        'notes': _nullableString(day['notes']),
        'isCompleted':
            _asBool(day['isCompleted'] ?? day['is_completed'], fallback: false),
        'completedExercises': _asInt(
            day['completedExercises'] ?? day['completed_exercises'],
            fallback: 0),
        'totalExercises': totalExercises,
      });
    }
    return days;
  }

  List<Map<String, dynamic>> _normalizeExercises(
      dynamic exercisesSource, int dayNumber) {
    if (exercisesSource is! List) {
      return <Map<String, dynamic>>[];
    }

    final exercises = <Map<String, dynamic>>[];
    for (var exIndex = 0; exIndex < exercisesSource.length; exIndex++) {
      final exercise = _asMap(exercisesSource[exIndex]);
      if (exercise == null) {
        continue;
      }

      final nameEn = _asString(
        exercise['nameEn'] ??
            exercise['name_en'] ??
            exercise['englishName'] ??
            exercise['name'],
        fallback: 'Exercise ${exIndex + 1}',
      );
      final nameAr = _asString(
        exercise['nameAr'] ??
            exercise['name_ar'] ??
            exercise['arabicName'] ??
            exercise['name'],
        fallback: nameEn,
      );

      exercises.add({
        ...exercise,
        'id': _asString(
          exercise['id'] ??
              exercise['_id'] ??
              exercise['exerciseId'] ??
              exercise['exercise_id'],
          fallback: 'day-$dayNumber-exercise-${exIndex + 1}',
        ),
        'name': _asString(exercise['name'], fallback: nameEn),
        'nameAr': nameAr,
        'nameEn': nameEn,
        'sets': _asInt(exercise['sets'], fallback: 3),
        'reps': _asString(exercise['reps'] ?? exercise['repetitions'],
            fallback: '10'),
        'restTime':
            _nullableString(exercise['restTime'] ?? exercise['rest_time']),
        'tempo': _nullableString(exercise['tempo']),
        'notes': _nullableString(exercise['notes']),
        'category': _nullableString(exercise['category']),
        'muscleGroup': _nullableString(
            exercise['muscleGroup'] ?? exercise['muscle_group']),
        'equipment': _nullableString(exercise['equipment']),
        'difficulty': _nullableString(exercise['difficulty']),
        'videoUrl':
            _nullableString(exercise['videoUrl'] ?? exercise['video_url']),
        'thumbnailUrl': _nullableString(
            exercise['thumbnailUrl'] ?? exercise['thumbnail_url']),
        'instructions': _nullableString(exercise['instructions']),
        'instructionsAr': _nullableString(
            exercise['instructionsAr'] ?? exercise['instructions_ar']),
        'instructionsEn': _nullableString(
            exercise['instructionsEn'] ?? exercise['instructions_en']),
        'contraindications': _asStringList(exercise['contraindications']),
        'alternatives': _asStringList(exercise['alternatives']),
        'isCompleted': exercise['isCompleted'] == true,
        'order': _asInt(exercise['order'], fallback: exIndex),
      });
    }

    return exercises;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return const <String>[];
  }

  List<dynamic>? _asList(dynamic value) {
    if (value is List) {
      return value;
    }
    return null;
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? fallback;
    }
    return fallback;
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) {
      return fallback;
    }
    final result = value.toString().trim();
    return result.isEmpty ? fallback : result;
  }

  String? _nullableString(dynamic value) {
    final text = _asString(value);
    return text.isEmpty ? null : text;
  }

  String _toRawBody(dynamic body) {
    if (body == null) {
      return 'null';
    }
    if (body is String) {
      return body;
    }
    try {
      return jsonEncode(body);
    } catch (_) {
      return body.toString();
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint(message);
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

  // Get exercise library
  Future<List<Map<String, dynamic>>> getExerciseLibrary({
    String? muscleGroup,
    String? equipment,
    String? difficulty,
    String? search,
    String? location,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (muscleGroup != null) queryParams['muscle_group'] = muscleGroup;
      if (equipment != null) queryParams['equipment'] = equipment;
      if (difficulty != null) queryParams['difficulty'] = difficulty;
      if (search != null) queryParams['search'] = search;
      if (location != null) queryParams['location'] = location;

      final response = await _dio.get(
        '/exercises',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      return List<Map<String, dynamic>>.from(response.data['exercises'] ?? []);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load exercises');
    }
  }

  // Get exercise by ID
  Future<Map<String, dynamic>> getExerciseById(String exerciseId) async {
    try {
      final response = await _dio.get(
        '/exercises/$exerciseId',
        options: await _getAuthOptions(),
      );

      return response.data['exercise'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load exercise');
    }
  }

  // Get exercises by muscle group
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(
      String muscleGroup) async {
    try {
      final response = await _dio.get(
        '/exercises/muscle-group/$muscleGroup',
        options: await _getAuthOptions(),
      );

      return List<Map<String, dynamic>>.from(response.data['exercises'] ?? []);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load exercises');
    }
  }

  // Get user's favorite exercises
  Future<List<Map<String, dynamic>>> getFavoriteExercises() async {
    try {
      final response = await _dio.get(
        '/exercises/favorites/list',
        options: await _getAuthOptions(),
      );

      return List<Map<String, dynamic>>.from(response.data['favorites'] ?? []);
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load favorites');
    }
  }

  // Add exercise to favorites
  Future<void> addToFavorites(String exerciseId) async {
    try {
      await _dio.post(
        '/exercises/favorites',
        data: {'exerciseId': exerciseId},
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to add to favorites');
    }
  }

  // Remove exercise from favorites
  Future<void> removeFromFavorites(String exerciseId) async {
    try {
      await _dio.delete(
        '/exercises/favorites/$exerciseId',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to remove from favorites');
    }
  }

  // Mark exercise as completed
  Future<WorkoutExerciseCompletionResult> markExerciseComplete(
      String exerciseId) async {
    try {
      final response = await _dio.post(
        '/workouts/exercises/$exerciseId/complete',
        options: await _getAuthOptions(),
      );
      final map = _asMap(response.data) ?? const <String, dynamic>{};
      final dayProgress = _asMap(map['dayProgress'] ?? map['day_progress']) ??
          const <String, dynamic>{};
      final nextDay = _asMap(map['nextDay'] ?? map['next_day']) ??
          const <String, dynamic>{};
      final planProgress =
          _asMap(map['planProgress'] ?? map['plan_progress']) ??
              const <String, dynamic>{};

      return WorkoutExerciseCompletionResult(
        dayCompleted: _asBool(
            dayProgress['dayCompleted'] ?? dayProgress['day_completed'],
            fallback: false),
        nextDayNumber: _asNullableInt(
          map['nextDayNumber'] ??
              map['next_day_number'] ??
              nextDay['dayNumber'] ??
              nextDay['day_number'],
        ),
        planProgressPercent: _asNullableDouble(
          planProgress['progressPercent'] ?? planProgress['progress_percent'],
        ),
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to mark exercise complete');
    }
  }

  int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Get exercise alternatives (injury-safe substitutions)
  Future<List<Exercise>> getExerciseAlternatives(
    String exerciseId,
    List<String> userInjuries,
  ) async {
    try {
      final response = await _dio.get(
        '/exercises/alternatives/$exerciseId',
        queryParameters: {'injuries': userInjuries.join(',')},
        options: await _getAuthOptions(),
      );

      return (response.data as List)
          .map((ex) => Exercise.fromJson(ex as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load alternatives');
    }
  }

  // Substitute exercise
  Future<void> substituteExercise(
    String originalExerciseId,
    String newExerciseId,
  ) async {
    try {
      await _dio.post(
        '/workouts/exercises/substitute',
        data: {
          'originalExerciseId': originalExerciseId,
          'newExerciseId': newExerciseId,
        },
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to substitute exercise');
    }
  }

  // Log workout session
  Future<void> logWorkout(Map<String, dynamic> workoutData) async {
    try {
      await _dio.post(
        '/workouts/log',
        data: workoutData,
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to log workout');
    }
  }

  // Get workout history
  Future<List<Map<String, dynamic>>> getWorkoutHistory() async {
    try {
      final response = await _dio.get(
        '/workouts/history',
        options: await _getAuthOptions(),
      );

      return List<Map<String, dynamic>>.from(response.data as List);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load history');
    }
  }

  // ============================================
  // INBODY API METHODS
  // ============================================

  /// Save new InBody scan
  Future<InBodyScan> saveInBodyScan(InBodyScan scan) async {
    try {
      final response = await _dio.post(
        '/inbody',
        data: scan.toJson(),
        options: await _getAuthOptions(),
      );

      final payload = _asMap(response.data);
      final savedScan = _asMap(payload?['scan']);
      if (savedScan != null) {
        return InBodyScan.fromJson(savedScan);
      }

      final latestScan = await getLatestInBodyScan();
      if (latestScan != null) {
        return latestScan;
      }

      throw Exception('InBody scan saved but latest scan could not be loaded');
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? 'Failed to save InBody scan',
      );
    }
  }

  /// Get all InBody scans for user
  Future<List<InBodyScan>> getAllInBodyScans(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _dio.get(
        '/inbody',
        queryParameters: {'limit': limit, 'offset': offset},
        options: await _getAuthOptions(),
      );

      return (response.data['scans'] as List)
          .map((scan) => InBodyScan.fromJson(scan as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load InBody scans');
    }
  }

  /// Get latest InBody scan
  Future<InBodyScan?> getLatestInBodyScan() async {
    try {
      final response = await _dio.get(
        '/inbody/latest',
        options: await _getAuthOptions(),
      );

      final payload = _asMap(response.data);
      final latestScan = _asMap(payload?['scan']);
      if (latestScan == null) return null;

      return InBodyScan.fromJson(latestScan);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No scans yet
      }
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load latest scan');
    }
  }

  /// Get InBody scan by ID
  Future<InBodyScan> getInBodyScanById(String scanId) async {
    try {
      final response = await _dio.get(
        '/inbody/$scanId',
        options: await _getAuthOptions(),
      );

      return InBodyScan.fromJson(response.data['scan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load scan');
    }
  }

  /// Update InBody scan
  Future<InBodyScan> updateInBodyScan(String scanId,
      {String? notes, String? scanLocation}) async {
    try {
      final response = await _dio.put(
        '/inbody/$scanId',
        data: {
          if (notes != null) 'notes': notes,
          if (scanLocation != null) 'scanLocation': scanLocation,
        },
        options: await _getAuthOptions(),
      );

      return InBodyScan.fromJson(response.data['scan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to update scan');
    }
  }

  /// Delete InBody scan
  Future<void> deleteInBodyScan(String scanId) async {
    try {
      await _dio.delete(
        '/inbody/$scanId',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to delete scan');
    }
  }

  /// Get body composition trends
  Future<List<Map<String, dynamic>>> getInBodyTrends({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }

      final response = await _dio.get(
        '/inbody/trends',
        queryParameters: queryParams,
        options: await _getAuthOptions(),
      );

      return List<Map<String, dynamic>>.from(response.data['trends'] ?? []);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load trends');
    }
  }

  /// Get body composition progress
  Future<InBodyProgress?> getInBodyProgress() async {
    try {
      final response = await _dio.get(
        '/inbody/progress',
        options: await _getAuthOptions(),
      );

      if (response.data['progress'] == null) return null;

      return InBodyProgress.fromJson(
          response.data['progress'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Not enough data yet
      }
      throw Exception(
          e.response?.data['message'] ?? 'Failed to calculate progress');
    }
  }

  /// Get InBody statistics
  Future<Map<String, dynamic>> getInBodyStatistics() async {
    try {
      final response = await _dio.get(
        '/inbody/statistics',
        options: await _getAuthOptions(),
      );

      return response.data['statistics'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(
          e.response?.data['message'] ?? 'Failed to load statistics');
    }
  }

  /// Set body composition goals
  Future<InBodyGoals> setInBodyGoals(InBodyGoals goals) async {
    try {
      final response = await _dio.post(
        '/inbody/goals',
        data: goals.toJson(),
        options: await _getAuthOptions(),
      );

      return InBodyGoals.fromJson(
          response.data['goals'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to set goals');
    }
  }

  /// Get current body composition goals
  Future<InBodyGoals?> getInBodyGoals() async {
    try {
      final response = await _dio.get(
        '/inbody/goals/current',
        options: await _getAuthOptions(),
      );

      if (response.data['goals'] == null) return null;

      return InBodyGoals.fromJson(
          response.data['goals'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load goals');
    }
  }

  /// Upload InBody scan image for AI extraction (Premium feature)
  Future<Map<String, dynamic>> uploadInBodyImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });

      final response = await _dio.post(
        '/inbody/upload-image',
        data: formData,
        options: await _getAuthOptions(),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final data = e.response?.data;
      final body =
          data is Map<String, dynamic> ? data : const <String, dynamic>{};
      throw InBodyUploadException(
        body['message']?.toString() ?? 'Failed to upload image',
        statusCode: e.response?.statusCode,
        code: body['code']?.toString(),
        retryable: body['retryable'] == true,
        upgradeRequired: body['upgradeRequired'] == true,
      );
    }
  }
}

/// Structured failure from the InBody AI extraction endpoint, so the UI can
/// distinguish "retake the photo" from "upgrade required" from hard errors.
class InBodyUploadException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;
  final bool retryable;
  final bool upgradeRequired;

  InBodyUploadException(
    this.message, {
    this.statusCode,
    this.code,
    this.retryable = false,
    this.upgradeRequired = false,
  });

  @override
  String toString() => message;
}

class WorkoutExerciseCompletionResult {
  final bool dayCompleted;
  final int? nextDayNumber;
  final double? planProgressPercent;

  WorkoutExerciseCompletionResult({
    required this.dayCompleted,
    required this.nextDayNumber,
    required this.planProgressPercent,
  });
}
