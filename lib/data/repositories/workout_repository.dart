import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/workout_plan.dart';
import '../models/inbody_model.dart';
import '../../core/config/api_config.dart';

class WorkoutRepository {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  static const String _tokenKey = 'fitcoach_auth_token';
  
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
    try {
      final response = await _dio.get(
        '/workouts/plan',
        options: await _getAuthOptions(),
      );
      
      if (response.data == null) return null;
      
      return WorkoutPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No active plan
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to load workout plan');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to load exercises');
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
  Future<List<Map<String, dynamic>>> getExercisesByMuscleGroup(String muscleGroup) async {
    try {
      final response = await _dio.get(
        '/exercises/muscle-group/$muscleGroup',
        options: await _getAuthOptions(),
      );
      
      return List<Map<String, dynamic>>.from(response.data['exercises'] ?? []);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load exercises');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to load favorites');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to add to favorites');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to remove from favorites');
    }
  }
  
  // Mark exercise as completed
  Future<void> markExerciseComplete(String exerciseId) async {
    try {
      await _dio.post(
        '/workouts/exercises/$exerciseId/complete',
        options: await _getAuthOptions(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to mark exercise complete');
    }
  }
  
  // Get exercise alternatives (injury-safe substitutions)
  Future<List<Exercise>> getExerciseAlternatives(
    String exerciseId,
    List<String> userInjuries,
  ) async {
    try {
      final response = await _dio.post(
        '/exercises/$exerciseId/alternatives',
        data: {'injuries': userInjuries},
        options: await _getAuthOptions(),
      );
      
      return (response.data as List)
          .map((ex) => Exercise.fromJson(ex as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to load alternatives');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to substitute exercise');
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
      
      return InBodyScan.fromJson(response.data['scan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to save InBody scan');
    }
  }
  
  /// Get all InBody scans for user
  Future<List<InBodyScan>> getAllInBodyScans({int limit = 50, int offset = 0}) async {
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
      throw Exception(e.response?.data['message'] ?? 'Failed to load InBody scans');
    }
  }
  
  /// Get latest InBody scan
  Future<InBodyScan?> getLatestInBodyScan() async {
    try {
      final response = await _dio.get(
        '/inbody/latest',
        options: await _getAuthOptions(),
      );
      
      if (response.data['scan'] == null) return null;
      
      return InBodyScan.fromJson(response.data['scan'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No scans yet
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to load latest scan');
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
  Future<InBodyScan> updateInBodyScan(String scanId, {String? notes, String? scanLocation}) async {
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
      if (startDate != null) queryParams['startDate'] = startDate.toIso8601String();
      if (endDate != null) queryParams['endDate'] = endDate.toIso8601String();
      
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
      
      return InBodyProgress.fromJson(response.data['progress'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // Not enough data yet
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to calculate progress');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to load statistics');
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
      
      return InBodyGoals.fromJson(response.data['goals'] as Map<String, dynamic>);
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
      
      return InBodyGoals.fromJson(response.data['goals'] as Map<String, dynamic>);
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
      throw Exception(e.response?.data['message'] ?? 'Failed to upload image');
    }
  }
}