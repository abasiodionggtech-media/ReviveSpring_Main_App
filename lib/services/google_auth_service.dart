import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthConfigurationException implements Exception {
  const GoogleAuthConfigurationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GoogleAuthService {
  GoogleAuthService._();

  static final instance = GoogleAuthService._();

  bool _initialized = false;

  String get _serverClientId {
    const explicitServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (explicitServerClientId.isNotEmpty) return explicitServerClientId;
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    return webClientId;
  }

  String? get _clientId {
    const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (!kIsWeb && Platform.isAndroid) return null;
    return webClientId.isEmpty ? null : webClientId;
  }

  Future<void> _initialize() async {
    if (_initialized) return;

    final serverClientId = _serverClientId;
    if (!kIsWeb && Platform.isAndroid && serverClientId.isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Missing GOOGLE_SERVER_CLIENT_ID for Android. Provide it via --dart-define.',
      );
    }

    await GoogleSignIn.instance.initialize(
      clientId: _clientId,
      serverClientId: serverClientId.isEmpty ? null : serverClientId,
    );
    _initialized = true;
  }

  bool _isAndroidOAuthConfigError(GoogleSignInException error) {
    final details = '${error.code} ${error.description} ${error.details}'.toLowerCase();
    return details.contains('reauth') || details.contains('[16]') || details.contains('developer_error');
  }

  Future<GoogleSignInAccount> _authenticate() {
    return GoogleSignIn.instance.authenticate(scopeHint: const ['email', 'profile']);
  }

  Future<String> getIdToken() async {
    await _initialize();
    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError('Google Sign-In is not supported on this platform.');
    }

    GoogleSignInAccount account;
    try {
      await GoogleSignIn.instance.signOut();
      account = await _authenticate();
    } on GoogleSignInException catch (error) {
      if (_isAndroidOAuthConfigError(error)) {
        throw const GoogleAuthConfigurationException(
          'Google sign-in is not connected to this Android release yet. Add the app package and release SHA-1/SHA-256 to the same Firebase/Google project as your Web OAuth client, then download a fresh google-services.json.',
        );
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Google did not return an ID token. Check GOOGLE_SERVER_CLIENT_ID / GOOGLE_WEB_CLIENT_ID.',
      );
    }
    return idToken;
  }
}
