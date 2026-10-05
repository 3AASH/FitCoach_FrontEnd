import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Whether the app can currently reach the backend.
///
/// The app had no connectivity awareness at all, so "offline" and "no data"
/// looked identical: a spinner resolving into an empty state with no
/// explanation and usually no retry.
///
/// This reports *reachability* rather than interface state, which is what
/// actually matters -- a device can hold a full-strength Wi-Fi association to
/// a captive portal or a dead router and still reach nothing. It is driven by
/// real request outcomes via [NetworkStatusInterceptor], which also means no
/// new dependency and no background polling.
class NetworkStatus extends ChangeNotifier {
  static final NetworkStatus instance = NetworkStatus._();

  NetworkStatus._();

  bool _isOnline = true;

  /// Optimistic until a request actually fails: showing an offline banner on
  /// cold start, before anything has been attempted, would be a false alarm.
  bool get isOnline => _isOnline;

  void reportSuccess() {
    if (_isOnline) return;
    _isOnline = true;
    notifyListeners();
  }

  void reportConnectionFailure() {
    if (!_isOnline) return;
    _isOnline = false;
    notifyListeners();
  }
}

/// Feeds [NetworkStatus] from Dio request outcomes.
///
/// Only transport-level failures count. An HTTP error response (401, 500) is
/// proof the server was reached, so it must not be read as being offline.
class NetworkStatusInterceptor extends Interceptor {
  const NetworkStatusInterceptor();

  static const _offlineTypes = {
    DioExceptionType.connectionError,
    DioExceptionType.connectionTimeout,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
  };

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    NetworkStatus.instance.reportSuccess();
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (_offlineTypes.contains(err.type)) {
      NetworkStatus.instance.reportConnectionFailure();
    } else if (err.response != null) {
      // A response of any status means the server answered.
      NetworkStatus.instance.reportSuccess();
    }
    handler.next(err);
  }
}
