import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/api_config.dart';

class PushNotificationRegistrationService {
  PushNotificationRegistrationService({
    Dio? dio,
    FirebaseMessaging? messaging,
    FlutterSecureStorage? secureStorage,
  }) : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: ApiConfig.baseUrl,
                connectTimeout: ApiConfig.connectTimeout,
                receiveTimeout: ApiConfig.receiveTimeout,
                sendTimeout: ApiConfig.sendTimeout,
                contentType: ApiConfig.contentType,
              ),
            ),
        _secureStorage = secureStorage ?? const FlutterSecureStorage() {
    if (messaging != null) {
      _messaging = messaging;
    } else {
      _messaging = _resolveMessaging();
    }
  }

  static FirebaseMessaging? _resolveMessaging() {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }

  final Dio _dio;
  late final FirebaseMessaging? _messaging;
  final FlutterSecureStorage _secureStorage;
  bool _tokenRefreshListenerRegistered = false;

  static const String _tokenKey = 'fitcoach_auth_token';

  Future<void> registerCurrentDevice() async {
    if (kIsWeb) return;

    final messaging = _messaging;
    if (messaging == null) return;

    final authToken = await _secureStorage.read(key: _tokenKey);
    if (authToken == null || authToken.isEmpty) return;

    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return;
    }

    final deviceToken = await messaging.getToken();
    if (deviceToken == null || deviceToken.isEmpty) return;

    try {
      await _registerToken(authToken, deviceToken);
    } catch (_) {
      return;
    }

    if (_tokenRefreshListenerRegistered) return;
    _tokenRefreshListenerRegistered = true;
    messaging.onTokenRefresh.listen((refreshedToken) {
      if (refreshedToken.isEmpty) return;
      _registerToken(authToken, refreshedToken).catchError((_) {});
    });
  }

  Future<void> _registerToken(String authToken, String deviceToken) async {
    await _dio.post(
      '/notifications/register-device',
      data: {
        'deviceToken': deviceToken,
        'deviceType': Platform.isIOS ? 'ios' : 'android',
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'environment': ApiConfig.environment,
        },
      },
      options: Options(headers: {'Authorization': 'Bearer $authToken'}),
    );
  }
}
