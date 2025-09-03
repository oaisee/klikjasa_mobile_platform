import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

class SocialAuthService {
  final Logger _logger = Logger();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final SupabaseClient _supabaseClient = Supabase.instance.client;
  GoogleSignInAccount? _currentUser;
  bool _isInitialized = false;

  // Getter untuk mendapatkan current user
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _googleSignIn.initialize(
        serverClientId:
            '918293903493-5aok2u3s57dk8dns8g3v4j5l65sjsk03.apps.googleusercontent.com',
      );
      _isInitialized = true;
    }
  }

  // Metode untuk login dengan Google
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      _logger.i('Memulai proses login dengan Google');

      // Ensure GoogleSignIn is initialized
      await _ensureInitialized();

      // Coba lightweight authentication terlebih dahulu
      GoogleSignInAccount? account =
          await _googleSignIn.attemptLightweightAuthentication();

      // Jika lightweight auth gagal, lakukan full authentication
      if (account == null) {
        _logger.i('Lightweight auth gagal, mencoba full authentication');
        await _googleSignIn.signOut(); // Clear any cached state
        account = await _googleSignIn.authenticate();
      }

      _currentUser = account;
      _logger.i('User signed in: ${account.email}');

      // Dapatkan authentication details
      final GoogleSignInAuthentication googleAuth = account.authentication;

      if (googleAuth.idToken == null) {
        _logger.e('Gagal mendapatkan ID token dari Google');
        return null;
      }

      _logger.i('Login dengan Google berhasil, user: ${account.email}');

      // Integrate with Supabase Auth menggunakan ID token
      return await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );
    } catch (e) {
      // Handle specific Google Sign-In exceptions
      if (e.toString().contains('GoogleSignInExceptionCode.canceled') ||
          e.toString().contains('activity is cancelled by the user')) {
        _logger.i('Pengguna membatalkan login Google');
        throw Exception('Login dibatalkan oleh pengguna');
      }

      _logger.e('Error saat login dengan Google', error: e);
      rethrow;
    }
  }

  // Metode untuk login dengan Apple
  Future<AuthResponse?> signInWithApple() async {
    try {
      _logger.i('Memulai proses login dengan Apple');

      // Generate secure nonce
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // Request credential untuk Apple Sign In
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Jika tidak ada id token, login dibatalkan
      if (credential.identityToken == null) {
        _logger.w('Login dengan Apple dibatalkan: tidak ada identity token');
        return null;
      }

      // Login ke Supabase dengan credential Apple
      final response = await _supabaseClient.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );

      _logger.i('Login dengan Apple berhasil');
      return response;
    } catch (e) {
      _logger.e('Error saat login dengan Apple', error: e);
      rethrow;
    }
  }

  // Helper untuk generate nonce acak untuk Apple Sign In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  // Helper untuk generate SHA256 hash dari string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
