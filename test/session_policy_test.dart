/// Staying signed in.
///
/// The app signed people out far sooner than anyone meant it to. Not because
/// a token expired — those last 30 days — but because startup fetched the
/// profile and read *any* failure as "not signed in". A timeout on a train,
/// a server blip, a moment of no signal, and you were back at the login
/// screen with a perfectly good token in storage.
///
/// These tests hold the line that matters: only two things end a session —
/// a week without opening the app, or a server that rejects the token twice.
/// A network error is neither.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:fitapp/core/auth/session_policy.dart';

/// A JWT-shaped token whose `exp` claim is [expiry]. Only the payload is
/// real; nothing here verifies signatures.
String tokenExpiring(DateTime? expiry) {
  String segment(Map<String, dynamic> claims) =>
      base64Url.encode(utf8.encode(jsonEncode(claims))).replaceAll('=', '');
  final claims = <String, dynamic>{'userId': 'u1'};
  if (expiry != null) {
    claims['exp'] = expiry.millisecondsSinceEpoch ~/ 1000;
  }
  return '${segment({'alg': 'HS256'})}.${segment(claims)}.signature';
}

void main() {
  final now = DateTime.utc(2026, 3, 1, 12);
  const policy = SessionPolicy();

  group('expiryOf', () {
    test('reads the exp claim', () {
      final expiry = DateTime.utc(2026, 4, 1);
      final parsed = SessionPolicy.expiryOf(tokenExpiring(expiry));
      // Second precision: exp is a whole number of seconds.
      expect(parsed!.difference(expiry).inSeconds, 0);
    });

    test('returns null for a token with no exp', () {
      expect(SessionPolicy.expiryOf(tokenExpiring(null)), isNull);
    });

    test('returns null rather than throwing on a token it cannot read', () {
      // An unreadable token is not evidence of anything; the server decides.
      for (final junk in ['', 'not-a-jwt', 'a.b', 'a.!!!.c', 'a.b.c.d']) {
        expect(SessionPolicy.expiryOf(junk), isNull, reason: 'for "$junk"');
      }
    });
  });

  group('verdict', () {
    test('no token means signed out', () {
      expect(
        policy.verdict(token: null, lastActiveAt: now, now: now),
        SessionVerdict.signedOut,
      );
      expect(
        policy.verdict(token: '', lastActiveAt: now, now: now),
        SessionVerdict.signedOut,
      );
    });

    test('a token used today is active', () {
      expect(
        policy.verdict(
          token: tokenExpiring(now.add(const Duration(days: 30))),
          lastActiveAt: now.subtract(const Duration(hours: 3)),
          now: now,
        ),
        SessionVerdict.active,
      );
    });

    test('six days idle is still active, eight days is signed out', () {
      SessionVerdict after(Duration idle) => policy.verdict(
            token: tokenExpiring(now.add(const Duration(days: 30))),
            lastActiveAt: now.subtract(idle),
            now: now,
          );

      expect(after(const Duration(days: 6)), SessionVerdict.active);
      expect(after(const Duration(days: 8)), SessionVerdict.signedOut);
    });

    test('exactly one week idle is still active', () {
      // The window is "after a week", not "at a week" — a boundary worth
      // being deliberate about, since it decides a sign-out.
      expect(
        policy.verdict(
          token: tokenExpiring(now.add(const Duration(days: 30))),
          lastActiveAt: now.subtract(kInactivitySignOutAfter),
          now: now,
        ),
        SessionVerdict.active,
      );
    });

    test('an expired token inside the window asks for a refresh', () {
      expect(
        policy.verdict(
          token: tokenExpiring(now.subtract(const Duration(hours: 1))),
          lastActiveAt: now.subtract(const Duration(days: 2)),
          now: now,
        ),
        SessionVerdict.needsRefresh,
      );
    });

    test('an expired token outside the window is signed out, not refreshed',
        () {
      // Idle time wins: there is no point refreshing a session the policy
      // has already ended.
      expect(
        policy.verdict(
          token: tokenExpiring(now.subtract(const Duration(hours: 1))),
          lastActiveAt: now.subtract(const Duration(days: 30)),
          now: now,
        ),
        SessionVerdict.signedOut,
      );
    });

    test('a session stored before timestamps existed is not signed out', () {
      // Upgrading the app must not log everybody out.
      expect(
        policy.verdict(
          token: tokenExpiring(now.add(const Duration(days: 30))),
          lastActiveAt: null,
          now: now,
        ),
        SessionVerdict.active,
      );
    });

    test('a token with no exp is left to the server', () {
      expect(
        policy.verdict(
          token: tokenExpiring(null),
          lastActiveAt: now.subtract(const Duration(days: 1)),
          now: now,
        ),
        SessionVerdict.active,
      );
    });

    test('the window is configurable', () {
      const short = SessionPolicy(inactivityWindow: Duration(minutes: 30));
      expect(
        short.verdict(
          token: tokenExpiring(now.add(const Duration(days: 30))),
          lastActiveAt: now.subtract(const Duration(hours: 2)),
          now: now,
        ),
        SessionVerdict.signedOut,
      );
    });
  });

  test('the shipped window is one week', () {
    expect(kInactivitySignOutAfter, const Duration(days: 7));
  });
}
