import '../../presentation/providers/language_provider.dart';

/// Turns a raw thrown error into something a user can read, in their language.
///
/// Providers across the app store `_error = e.toString()`, and screens render
/// that string directly. The result is users seeing
/// `SocketException: Failed host lookup: 'api.fitcoach...'` -- and seeing it in
/// English even when the rest of the app is Arabic.
///
/// Mapping here rather than in each provider keeps the fix to one place: the
/// providers go on carrying the raw string (it is still what we want in logs),
/// and only the display boundary translates. Call it wherever a provider error
/// reaches a `Text`.
///
/// A server-sent message is passed through as-is: those are already written for
/// users ("Card declined"), and replacing them with a generic string would lose
/// the only specific thing the user could act on. Only transport- and
/// framework-level noise is swapped for a translated equivalent.
String friendlyError(LanguageProvider lang, Object? rawError) {
  final raw = rawError?.toString().trim() ?? '';
  if (raw.isEmpty) return lang.t('error_generic');

  final lower = raw.toLowerCase();

  // Transport failures: the user is offline or the host is unreachable.
  if (lower.contains('socketexception') ||
      lower.contains('failed host lookup') ||
      lower.contains('network is unreachable') ||
      lower.contains('connection refused') ||
      lower.contains('connection error') ||
      lower.contains('connection closed')) {
    return lang.t('error_offline');
  }

  if (lower.contains('timeout') || lower.contains('timeoutexception')) {
    return lang.t('error_timeout');
  }

  // Auth: the token expired or was rejected.
  if (lower.contains('401') ||
      lower.contains('unauthorized') ||
      lower.contains('unauthenticated')) {
    return lang.t('error_session_expired');
  }

  if (lower.contains('403') || lower.contains('forbidden')) {
    return lang.t('error_forbidden');
  }

  if (lower.contains('404') || lower.contains('not found')) {
    return lang.t('error_not_found');
  }

  // 5xx and anything else the server failed on.
  if (lower.contains('500') ||
      lower.contains('502') ||
      lower.contains('503') ||
      lower.contains('504') ||
      lower.contains('internal server error')) {
    return lang.t('error_server');
  }

  // Framework noise that would mean nothing to a user.
  if (lower.startsWith('exception:') ||
      lower.startsWith('dioexception') ||
      lower.startsWith('dioerror') ||
      lower.contains('stack trace') ||
      lower.contains('type \'') ||
      lower.contains('null check operator')) {
    final stripped = _stripExceptionPrefix(raw);
    // `Exception: Card declined` is a real message wearing a prefix -- keep the
    // message. `Exception: DioError [...]` is not; fall back to generic.
    return _looksUserFacing(stripped) ? stripped : lang.t('error_generic');
  }

  return _looksUserFacing(raw) ? raw : lang.t('error_generic');
}

String _stripExceptionPrefix(String raw) {
  final idx = raw.indexOf(':');
  if (idx == -1 || idx + 1 >= raw.length) return raw;
  return raw.substring(idx + 1).trim();
}

/// A message is worth showing when it reads like a sentence rather than a
/// stack frame: no bracketed error codes, no file paths, and short enough to
/// fit in a snackbar.
bool _looksUserFacing(String message) {
  if (message.isEmpty || message.length > 160) return false;
  if (message.contains('[') || message.contains('#')) return false;
  if (message.contains('/') && message.contains('.dart')) return false;
  if (message.contains('<') && message.contains('>')) return false;
  return true;
}
