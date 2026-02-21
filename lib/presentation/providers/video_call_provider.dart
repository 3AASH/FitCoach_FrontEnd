import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/config/api_config.dart';

/// Video Call Provider
/// Manages video call state and API calls
class VideoCallProvider with ChangeNotifier {
  String? _authToken;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_authToken != null && _authToken!.isNotEmpty)
        'Authorization': 'Bearer $_authToken',
    };
  }

  /// Start a video call for an appointment
  Future<Map<String, dynamic>?> startCall(String appointmentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/video-calls/$appointmentId/start'),
        headers: _buildHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return data['call'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to start call';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error starting call: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Get call token (join existing call)
  Future<Map<String, dynamic>?> getCallToken(String appointmentId) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/video-calls/$appointmentId/token'),
        headers: _buildHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _isLoading = false;
        notifyListeners();
        return data['call'];
      } else {
        _errorMessage = data['message'] ?? 'Failed to get call token';
        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _errorMessage = 'Error getting call token: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// End video call
  Future<bool> endCall(String appointmentId, int durationMinutes) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/video-calls/$appointmentId/end'),
        headers: _buildHeaders(),
        body: json.encode({
          'duration': durationMinutes,
        }),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return true;
      } else {
        _errorMessage = data['message'] ?? 'Failed to end call';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error ending call: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  /// Check if user can join call
  Future<Map<String, dynamic>?> canJoinCall(String appointmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/video-calls/$appointmentId/can-join'),
        headers: _buildHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error checking can join: $e');
      return null;
    }
  }

  /// Get call status
  Future<Map<String, dynamic>?> getCallStatus(String appointmentId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/video-calls/$appointmentId/status'),
        headers: _buildHeaders(),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return data['session'];
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error getting call status: $e');
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
