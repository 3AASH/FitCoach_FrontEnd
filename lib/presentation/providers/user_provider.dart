import 'package:flutter/material.dart';
import '../../core/config/demo_config.dart';
import '../../data/demo/demo_data.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/models/user_profile.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;
  
  UserProfile? _profile;
  bool _isLoading = false;
  String? _error;
  
  UserProvider(this._repository);
  
  // Getters
  UserProfile? get profile => _profile;
  UserProfile? get user => _profile;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load user profile
  Future<void> loadProfile() async {
    if (DemoConfig.isDemo) {
      _profile = DemoData.userProfile(role: 'user');
      _error = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final profile = await _repository.getUserProfile();
      _profile = profile;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update profile
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    if (DemoConfig.isDemo) {
      if (_profile != null) {
        _profile = _profile!.copyWith(
          name: updates['name'] as String?,
          email: updates['email'] as String?,
          age: updates['age'] as int?,
          weight: updates['weight'] as double?,
          height: updates['height'] as int?,
          gender: updates['gender'] as String?,
          workoutFrequency: updates['workoutFrequency'] as int?,
          workoutLocation: updates['workoutLocation'] as String?,
          experienceLevel: updates['experienceLevel'] as String?,
          mainGoal: updates['mainGoal'] as String?,
          injuries: updates['injuries'] as List<String>?,
          subscriptionTier: updates['subscriptionTier'] as String?,
          coachId: updates['coachId'] as String?,
          hasCompletedFirstIntake: updates['hasCompletedFirstIntake'] as bool?,
          hasCompletedSecondIntake: updates['hasCompletedSecondIntake'] as bool?,
          fitnessScore: updates['fitnessScore'] as int?,
        );
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Replace 'userId' with the actual user ID or required argument
      final updatedProfileMap = await _repository.updateProfile(_profile?.id ?? '', updates);
      _profile = UserProfile.fromJson(updatedProfileMap);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Submit first intake
  Future<bool> submitFirstIntake(Map<String, dynamic> data) async {
    if (DemoConfig.isDemo) {
      if (_profile != null) {
        _profile = _profile!.copyWith(
          hasCompletedFirstIntake: true,
          gender: data['gender'] as String?,
          mainGoal: data['mainGoal'] as String?,
          workoutLocation: data['workoutLocation'] as String?,
        );
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedProfile = await _repository.submitFirstIntake(data);
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Submit second intake
  Future<bool> submitSecondIntake(Map<String, dynamic> data) async {
    if (DemoConfig.isDemo) {
      if (_profile != null) {
        _profile = _profile!.copyWith(
          hasCompletedSecondIntake: true,
          age: data['age'] as int?,
          weight: data['weight'] as double?,
          height: data['height'] as int?,
          experienceLevel: data['experienceLevel'] as String?,
          workoutFrequency: data['workoutFrequency'] as int?,
          injuries: data['injuries'] as List<String>?,
        );
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedProfile = await _repository.submitSecondIntake(data);
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Update subscription tier
  Future<bool> updateSubscription(String tier) async {
    if (DemoConfig.isDemo) {
      if (_profile != null) {
        _profile = _profile!.copyWith(subscriptionTier: tier);
        notifyListeners();
      }
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final updatedProfile = await _repository.updateSubscription(tier);
      _profile = updatedProfile;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
  
  // Set profile (for initial load)
  void setProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }
}
