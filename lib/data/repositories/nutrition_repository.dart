import 'package:dio/dio.dart';
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
      
      if (response.data == null) return null;
      
      return NutritionPlan.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null; // No active plan
      }
      throw Exception(e.response?.data['message'] ?? 'Failed to load nutrition plan');
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
      throw Exception(e.response?.data['message'] ?? 'Failed to get trial status');
    }
  }
  
  // Log meal consumption
  Future<void> logMeal(String mealId, Map<String, dynamic> data) async {
    try {
      await _dio.post(
        '/nutrition/meals/$mealId/log',
        data: data,
        options: await _getAuthOptions(),
      );
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
  Future<Map<String, dynamic>> generatePlan(Map<String, dynamic> preferences) async {
    try {
      final response = await _dio.post(
        '/nutrition/generate',
        data: preferences,
        options: await _getAuthOptions(),
      );

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Failed to generate nutrition plan');
    }
  }
}