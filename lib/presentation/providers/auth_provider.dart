import 'package:flutter/material.dart';
import 'package:fitapp/core/auth/session_policy.dart';
import 'package:fitapp/core/config/demo_config.dart';
import 'package:fitapp/data/demo/demo_data.dart';
import 'package:fitapp/data/repositories/auth_repository.dart';
import 'package:fitapp/data/models/user_profile.dart';
import 'package:fitapp/data/services/push_notification_registration_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepositoryBase _repository;
  final PushNotificationRegistrationService? _pushNotifications;
  final SessionPolicy _sessionPolicy;

  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserProfile? _user;
  String? _token;
  String? _error;
  String? _phoneFieldError;
  String? _lastPhoneNumber;

  /// False after an OTP sign-up until the remaining questions are answered.
  bool _registrationComplete = true;
  bool get registrationComplete => _registrationComplete;

  AuthProvider(
    this._repository, {
    PushNotificationRegistrationService? pushNotifications,
    SessionPolicy sessionPolicy = const SessionPolicy(),
  })  : _pushNotifications = pushNotifications,
        _sessionPolicy = sessionPolicy {
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
  String? get phoneFieldError => _phoneFieldError;
  String? get lastPhoneNumber => _lastPhoneNumber;

  void clearErrors() {
    if (_error == null && _phoneFieldError == null) {
      return;
    }
    _error = null;
    _phoneFieldError = null;
    notifyListeners();
  }

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
      final verdict = _sessionPolicy.verdict(
        token: storedToken,
        lastActiveAt: await _repository.getLastActiveAt(),
        now: DateTime.now().toUtc(),
      );

      if (verdict == SessionVerdict.signedOut) {
        // Either nothing is stored, or the app has gone unopened for longer
        // than the inactivity window.
        if (storedToken != null) await _repository.removeToken();
        return;
      }

      _isLoading = true;
      notifyListeners();
      _token = storedToken;

      if (verdict == SessionVerdict.needsRefresh) {
        final refreshed = await _repository.refreshToken();
        if (refreshed == null) {
          await _repository.removeToken();
          _token = null;
          return;
        }
        _token = refreshed;
      }

      await _loadProfileForRestoredSession();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Fetches the profile for a session restored from storage.
  ///
  /// The three outcomes are deliberately different, because collapsing them
  /// is what used to sign people out for no reason:
  ///
  ///  * profile loaded — signed in;
  ///  * the server rejected the token — try one refresh, then sign out;
  ///  * anything else (timeout, no network, server down) — stay signed in on
  ///    the stored token and let the next request try again.
  Future<void> _loadProfileForRestoredSession() async {
    try {
      final userProfile = await _repository.getUserProfile();
      if (userProfile != null) {
        _user = userProfile;
        _isAuthenticated = true;
        _registerPushNotifications();
      }
    } on SessionExpiredException {
      final userProfile = await _recoverExpiredSession();
      if (userProfile != null) {
        _user = userProfile;
        _isAuthenticated = true;
        _registerPushNotifications();
      }
    } catch (_) {
      // Offline or the server is unreachable. The token is still within its
      // window, so keep the person signed in; screens that need data will
      // surface their own errors.
      _isAuthenticated = true;
    }
  }

  /// One attempt to trade a rejected token for a fresh one.
  ///
  /// Returns the profile when the session was recovered. Returns null when it
  /// is really over, having signed the person out locally first.
  Future<UserProfile?> _recoverExpiredSession() async {
    final refreshed = await _repository.refreshToken();
    if (refreshed == null) {
      await _forgetSession();
      return null;
    }
    _token = refreshed;
    try {
      return await _repository.getUserProfile();
    } on SessionExpiredException {
      await _forgetSession();
      return null;
    } catch (_) {
      // The refresh worked; the follow-up call did not reach the server.
      // Keep the new token and try again next time.
      return null;
    }
  }

  /// Clears the stored session without calling the server.
  Future<void> _forgetSession() async {
    try {
      await _repository.removeToken();
    } catch (_) {
      // Nothing useful to do if the keystore refuses; the in-memory state
      // below still puts the person back at the login screen.
    }
    _token = null;
    _user = null;
    _isAuthenticated = false;
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
    } on SessionExpiredException {
      final userProfile = await _recoverExpiredSession();
      if (userProfile != null) {
        _user = userProfile;
        _isAuthenticated = true;
        _error = null;
      }
      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      if (notify) {
        notifyListeners();
      }
    }
  }

  // Request OTP
  /// Whether the number already has an account, so the screen shows a password
  /// prompt instead of sending a sign-up code. Null when the check failed.
  Future<PhoneStatus?> checkPhone(String phoneNumber) async {
    if (DemoConfig.isDemo) {
      return const PhoneStatus(
        registered: false,
        hasPassword: false,
        nextStep: 'send_otp',
      );
    }
    _isLoading = true;
    _error = null;
    _phoneFieldError = null;
    _lastPhoneNumber = phoneNumber;
    notifyListeners();

    try {
      final status = await _repository.checkPhone(phoneNumber);
      _isLoading = false;
      notifyListeners();
      return status;
    } catch (e) {
      _setAuthError(e);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  /// Record the rest of the sign-up answers for an account created by OTP.
  Future<bool> completeRegistration({
    required String fullName,
    required String password,
    String? email,
  }) async {
    if (DemoConfig.isDemo) return true;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _repository.completeRegistration(
        fullName: fullName,
        password: password,
        email: email,
      );
      // The token from OTP verification is still the live one.
      _user = response.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestOTP(String phoneNumber, {String? purpose}) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: 'user');
      return true;
    }
    _isLoading = true;
    _error = null;
    _phoneFieldError = null;
    _lastPhoneNumber = phoneNumber;
    notifyListeners();

    try {
      await _repository.requestOTP(phoneNumber, purpose: purpose);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setAuthError(e);
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
    _phoneFieldError = null;
    notifyListeners();

    try {
      final authResponse = await _repository.verifyOTP(phoneNumber, otp);

      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;

      // Store token
      await _repository.storeToken(authResponse.token);
      _registerPushNotifications();

      _registrationComplete = authResponse.registrationComplete;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setAuthError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset password via phone OTP, then log the user in
  Future<bool> resetPassword({
    required String phoneNumber,
    required String otpCode,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    _phoneFieldError = null;
    notifyListeners();

    try {
      final authResponse = await _repository.resetPassword(
        phoneNumber: phoneNumber,
        otpCode: otpCode,
        newPassword: newPassword,
      );

      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;

      await _repository.storeToken(authResponse.token);
      _registerPushNotifications();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setAuthError(e);
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
    _phoneFieldError = null;
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
      _registerPushNotifications();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setAuthError(e);
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
    String? otpCode,
  }) async {
    if (DemoConfig.isDemo) {
      _enableDemoUser(role: _demoRoleForCredential(email));
      return true;
    }
    _isLoading = true;
    _error = null;
    _phoneFieldError = null;
    notifyListeners();

    try {
      final authResponse = await _repository.signup(
        name: name,
        email: email,
        phone: phone,
        password: password,
        otpCode: otpCode,
      );

      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;

      // Store token
      await _repository.storeToken(authResponse.token);
      _registerPushNotifications();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _setAuthError(e);
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
    _phoneFieldError = null;
    notifyListeners();

    try {
      final authResponse = await _repository.socialLogin(provider);

      _token = authResponse.token;
      _user = authResponse.user;
      _isAuthenticated = true;

      // Store token
      await _repository.storeToken(authResponse.token);
      _registerPushNotifications();

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

  void _setAuthError(Object error) {
    if (error is AuthRepositoryException) {
      _error = error.message;
      _phoneFieldError = error.isPhoneFieldError ? error.message : null;
      return;
    }
    _error = error.toString();
    _phoneFieldError = _error!.toLowerCase().contains('phone') ? _error : null;
  }

  void _registerPushNotifications() {
    _pushNotifications?.registerCurrentDevice().catchError((_) {});
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
    } on SessionExpiredException {
      final userProfile = await _recoverExpiredSession();
      if (userProfile != null) _user = userProfile;
      notifyListeners();
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
    } catch (e) {
      _error = e.toString();
    } finally {
      _isAuthenticated = false;
      _user = null;
      _token = null;
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
    _phoneFieldError = null;
    notifyListeners();
  }

  void _enableDemoUser({required String role}) {
    _isLoading = false;
    _error = null;
    _phoneFieldError = null;
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
