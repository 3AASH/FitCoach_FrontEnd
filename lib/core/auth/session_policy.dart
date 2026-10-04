/// How long a signed-in session survives without being used.
///
/// The app used to sign people out far sooner than anyone intended, and not
/// because a token had expired. At startup it fetched the profile and treated
/// *any* failure as "not signed in" — including a timeout or a moment with no
/// network. Open the app on a bad connection and you were back at the login
/// screen holding a token that was still good for weeks.
///
/// Two separate clocks decide whether a session is still alive, and they are
/// kept apart deliberately:
///
///  * the token's own `exp`, which the server issued and will enforce however
///    the client feels about it;
///  * how long it has been since the person last used the app, which is the
///    part product cares about and the part this file names.
///
/// A network error is not a clock. It means "ask again later", and
/// [SessionPolicy] never turns it into a sign-out.
library;

import 'dart:convert';

/// How long the app may go unopened before the session is dropped.
const Duration kInactivitySignOutAfter = Duration(days: 7);

/// What should happen to a stored session at startup.
enum SessionVerdict {
  /// Nothing stored, or the session is finished. Show the login screen.
  signedOut,

  /// Usable now. Validate in the background, but let the person in.
  active,

  /// Past its expiry but within the inactivity window: try to refresh it
  /// before giving up on the person.
  needsRefresh,
}

class SessionPolicy {
  /// How long a session may sit unused. Injectable so tests do not have to
  /// wait a week.
  final Duration inactivityWindow;

  const SessionPolicy({this.inactivityWindow = kInactivitySignOutAfter});

  /// What to do with [token], last used at [lastActiveAt], as of [now].
  ///
  /// [lastActiveAt] is null for a session stored before the app started
  /// recording it; that is treated as "just used" rather than as a sign-out,
  /// so an upgrade does not log everyone out.
  SessionVerdict verdict({
    required String? token,
    required DateTime? lastActiveAt,
    required DateTime now,
  }) {
    if (token == null || token.isEmpty) return SessionVerdict.signedOut;

    if (lastActiveAt != null &&
        now.difference(lastActiveAt) > inactivityWindow) {
      return SessionVerdict.signedOut;
    }

    final expiry = expiryOf(token);
    if (expiry != null && !expiry.isAfter(now)) {
      // The server will reject it, but the person is still within their
      // window, so this is a refresh, not a sign-out.
      return SessionVerdict.needsRefresh;
    }

    return SessionVerdict.active;
  }

  /// The `exp` claim of a JWT, or null when it has none or cannot be read.
  ///
  /// Reading the claim is a convenience, not a security check — the server
  /// verifies the signature. It only saves a round trip that is certain to
  /// come back 401.
  static DateTime? expiryOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = parts[1];
      // base64url without the padding the decoder insists on.
      final normalized = base64Url.normalize(payload);
      final claims =
          jsonDecode(utf8.decode(base64Url.decode(normalized))) as Map;
      final exp = claims['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000,
          isUtc: true);
    } catch (_) {
      // A token we cannot parse is not automatically a bad token; let the
      // server be the judge.
      return null;
    }
  }
}
