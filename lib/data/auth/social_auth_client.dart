import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/config/demo_config.dart';

class SocialAuthResult {
  SocialAuthResult({
    required this.provider,
    required this.accessToken,
    required this.socialId,
    this.email,
    this.name,
    this.profilePhoto,
  });

  final String provider;
  final String accessToken;
  final String socialId;
  final String? email;
  final String? name;
  final String? profilePhoto;
}

abstract class SocialAuthClient {
  Future<SocialAuthResult> signIn(String provider);
}

class DefaultSocialAuthClient implements SocialAuthClient {
  DefaultSocialAuthClient({
    GoogleSignIn? googleSignIn,
    FacebookAuth? facebookAuth,
  })  : _googleSignIn = googleSignIn,
        _facebookAuth = facebookAuth ?? FacebookAuth.instance;

  GoogleSignIn? _googleSignIn;
  final FacebookAuth _facebookAuth;

  @override
  Future<SocialAuthResult> signIn(String provider) async {
    switch (provider) {
      case 'google':
        return _signInWithGoogle();
      case 'facebook':
        return _signInWithFacebook();
      case 'apple':
        return _signInWithApple();
      default:
        throw Exception('Unsupported provider: $provider');
    }
  }

  Future<SocialAuthResult> _signInWithGoogle() async {
    final account = await _getGoogleSignIn().signIn();
    if (account == null) {
      throw Exception('Google sign-in canceled');
    }
    final auth = await account.authentication;
    final accessToken = auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Google access token missing');
    }
    return SocialAuthResult(
      provider: 'google',
      accessToken: accessToken,
      socialId: account.id,
      email: account.email,
      name: account.displayName,
      profilePhoto: account.photoUrl,
    );
  }

  Future<SocialAuthResult> _signInWithFacebook() async {
    final result = await _facebookAuth.login(
      permissions: const ['email', 'public_profile'],
      loginBehavior: LoginBehavior.dialogOnly,
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      throw Exception('Facebook sign-in failed');
    }

    final userData = await _facebookAuth.getUserData();
    return SocialAuthResult(
      provider: 'facebook',
      accessToken: result.accessToken!.token,
      socialId: result.accessToken!.userId,
      email: userData['email'] as String?,
      name: userData['name'] as String?,
      profilePhoto: (userData['picture']?['data']?['url'] as String?),
    );
  }

  Future<SocialAuthResult> _signInWithApple() async {
    if (kIsWeb) {
      throw Exception('Apple sign-in on web requires Services ID configuration.');
    }

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw Exception('Apple identity token missing');
    }

    final fullName = [
      credential.givenName,
      credential.familyName,
    ].where((part) => part?.isNotEmpty ?? false).join(' ');

    return SocialAuthResult(
      provider: 'apple',
      accessToken: identityToken,
      socialId: credential.userIdentifier ?? identityToken,
      email: credential.email,
      name: fullName.isEmpty ? null : fullName,
    );
  }

  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn != null) {
      return _googleSignIn!;
    }
    if (kIsWeb) {
      const clientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');
      if (clientId.isEmpty) {
        throw Exception(
          DemoConfig.isDemo
              ? 'Google sign-in is not configured for demo mode on web.'
              : 'Google sign-in client ID missing for web.',
        );
      }
      _googleSignIn = GoogleSignIn(
        clientId: clientId,
        scopes: const ['email', 'profile'],
      );
      return _googleSignIn!;
    }
    _googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);
    return _googleSignIn!;
  }
}
