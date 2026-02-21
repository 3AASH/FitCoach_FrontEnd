import 'package:flutter/material.dart';
import 'package:fitapp/core/config/demo_config.dart';
import 'package:fitapp/data/demo/demo_data.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryBase _repository;
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserProfile? _user;
  String? _token;
  String? _error;
  String? _lastPhoneNumber;
  
  AuthProvider(this._repository) {
    if (!DemoConfig.isDemo) {
      _checkAuthStatus();
    }
  }
  
  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserProfile? get user => _user;
  String? get token => _token;
  String? get error => _error;
  String? get lastPhoneNumber => _lastPhoneNumber;
  
  // Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    if (DemoConfig.isDemo) {
      _isAuthenticated = false;
      _user = null;
      _token = null;
      return;
    }
    try {
      final storedToken = await _repository.getStoredToken();
      
      if (storedToken != null) {
        _isLoading = true;
        notifyListeners();
        _token = storedToken;
        final userProfile = await _repository.getUserProfile();
        
        if (userProfile != null) {
          _user = userProfile;
          _isAuthenticated = true;
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Refresh user profile
  Future<void> refreshUserProfile({bool notify = true}) async {
    if (DemoConfig.isDemo) {
      return;
    }

    try {
      final userProfile = await _repository.getUserProfile();
      if (userProfile != null) {
        _user = userProfile;
        _isAuthenticated = true;
        _error = null;
        if (notify) {
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      if (notify) {
        notifyListeners();
      }
    }
  }
  
  // Request OTP
  Future<bool> requestOTP(String phoneNumber) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: 'user');
      return true;
    }
    _isLoading = true;
    _error = null;
    _lastPhoneNumber = phoneNumber;
    notifyListeners();
    
    try {
      await _repository.requestOTP(phoneNumber);
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
  
  // Verify OTP and login
  Future<bool> verifyOTP(String phoneNumber, String otp) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: 'user');
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final authResponse = await _repository.verifyOTP(phoneNumber, otp);
      
      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;
      
      // Store token
      await _repository.storeToken(authResponse.token);
      
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
  
  // Login with email or phone
  Future<bool> loginWithEmailOrPhone({
    required String emailOrPhone,
    required String password,
  }) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: _demoRoleForCredential(emailOrPhone));
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final authResponse = await _repository.loginWithEmailOrPhone(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      
      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;
      
      // Store token
      await _repository.storeToken(authResponse.token);
      
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
  
  // Signup with email
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: _demoRoleForCredential(email));
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final authResponse = await _repository.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      
      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;
      
      // Store token
      await _repository.storeToken(authResponse.token);
      
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
  
  // Social login (Google, Facebook, Apple)
  Future<bool> socialLogin(String provider) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: 'user');
      return true;
    }
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final authResponse = await _repository.socialLogin(provider);
      
      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;
      
      // Store token
      await _repository.storeToken(authResponse.token);
      
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
  
  // Refresh user data
  Future<void> refreshUser() async {
    if (DemoConfig.isDemo) {
      _user = DemoData.userProfile(role: _user?.role ?? 'user');
      notifyListeners();
      return;
    }
    try {
      final userProfile = await _repository.getUserProfile();
      if (userProfile != null) {
        _user = userProfile;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Logout
  Future<void> logout() async {
    if (DemoConfig.isDemo) {
      _isAuthenticated = false;
      _user = null;
      _token = null;
      _error = null;
      notifyListeners();
      return;
    }
    _isLoading = true;
    notifyListeners();
    
    try {
      await _repository.logout();
      
      _isAuthenticated = false;
      _user = null;
      _token = null;
      _error = null;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Update user profile
  void updateUser(UserProfile updatedUser) {
    _user = updatedUser;
    notifyListeners();
  }

  void setDemoRole(String role) {
    if (!DemoConfig.isDemo) return;
    _enableDemoUser(role: role);
  }
  
  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _enableDemoUser({required String role}) {
    _isLoading = false;
    _error = null;
    _token = 'demo-token';
    _user = DemoData.userProfile(role: role);
    _isAuthenticated = true;
    notifyListeners();
  }

  String _demoRoleForCredential(String credential) {
    final normalized = credential.trim().toLowerCase();
    if (normalized == 'coach@fitcoach.com') return 'coach';
    if (normalized == 'admin@fitcoach.com') return 'admin';
    return 'user';
  }
}
