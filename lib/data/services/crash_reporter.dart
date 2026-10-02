import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/config/api_config.dart';

/// Ships client-side failures to the backend so they appear in its logs.
///
/// Why this exists: a crash in the app left no server-side trace. A 403 the
/// app renders as "Exception: ..." and a type error while decoding a response
/// both look identical from the server — a successful request — so the only
/// evidence of a user-visible failure was a screenshot.
///
/// Every path here is best-effort. A reporter that throws, blocks startup, or
/// retries into a loop would be worse than no reporter at all.
class CrashReporter {
  CrashReporter._();

  static const String _tokenKey = 'fitcoach_auth_token';

  /// Repeated identical failures are collapsed. A widget that throws during
  /// build throws on every frame, which would otherwise emit a request per
  /// frame and bury everything else in the log.
  static const Duration _dedupeWindow = Duration(seconds: 30);
  static final Map<String, DateTime> _recent = {};

  static Dio? _dio;
  static FlutterSecureStorage _storage = const FlutterSecureStorage();
  static bool _installed = false;

  /// Test seam: lets a test supply a fake transport and storage.
  @visibleForTesting
  static void configureForTest({Dio? dio, FlutterSecureStorage? storage}) {
    _dio = dio;
    if (storage != null) _storage = storage;
    _recent.clear();
  }

  static Dio get _client =>
      _dio ??= Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

  /// Routes Flutter's own error channels here. Call once, before `runApp`.
  ///
  /// Errors inside a zone are not covered by these two hooks; wrap `runApp`
  /// in [guard] for that.
  static void install() {
    if (_installed) return;
    _installed = true;

    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      // Keep the console output: this augments local debugging, replacing it
      // would make the app harder to work on, not easier.
      previousOnError?.call(details);
      report(
        details.exception,
        stackTrace: details.stack,
        context: details.context?.toDescription(),
        fatal: false,
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      report(error, stackTrace: stack, fatal: true);
      return true;
    };
  }

  /// Runs [body] in a zone whose uncaught async errors are reported.
  static void guard(void Function() body) {
    runZonedGuarded(body, (error, stack) {
      report(error, stackTrace: stack, fatal: true);
    });
  }

  /// Reports a single failure. Safe to call from anywhere, including a
  /// `catch` block that is already handling the error for the user.
  static void report(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    String? screen,
    bool fatal = false,
  }) {
    // Deliberately not awaited: the caller is on a failure path and must not
    // wait on the network to finish handling it.
    unawaited(_send(
      error: error,
      stackTrace: stackTrace,
      context: context,
      screen: screen,
      fatal: fatal,
    ));
  }

  static Future<void> _send({
    required Object error,
    StackTrace? stackTrace,
    String? context,
    String? screen,
    required bool fatal,
  }) async {
    try {
      final message = error.toString();
      final key = '$message|$screen';
      final now = DateTime.now();
      final last = _recent[key];
      if (last != null && now.difference(last) < _dedupeWindow) return;
      _recent[key] = now;
      if (_recent.length > 50) {
        _recent.removeWhere((_, at) => now.difference(at) > _dedupeWindow);
      }

      String? token;
      try {
        token = await _storage.read(key: _tokenKey);
      } catch (_) {
        // Keychain unavailable; the report is still worth sending unattributed.
      }

      await _client.post(
        '/client-logs/errors',
        data: {
          'type': error.runtimeType.toString(),
          'message': message,
          'stack': stackTrace?.toString(),
          'context': context,
          'screen': screen,
          'fatal': fatal,
          'platform': defaultTargetPlatform.name,
        },
        options: Options(
          headers: token == null ? null : {'Authorization': 'Bearer $token'},
          // A failed report must not itself raise.
          validateStatus: (_) => true,
        ),
      );
    } catch (_) {
      // Swallowed on purpose. Reporting is diagnostics, never a second failure.
    }
  }
}
