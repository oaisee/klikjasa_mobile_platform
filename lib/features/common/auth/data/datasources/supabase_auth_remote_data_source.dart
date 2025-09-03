import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';
import 'auth_remote_data_source.dart';

// Implementasi AuthRemoteDataSource menggunakan Supabase Client.
// Kelas ini bertanggung jawab untuk semua interaksi langsung dengan Supabase Authentication.

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  final Logger _logger = Logger();
  final GoTrueClient _supabaseAuth;

  // Konstruktor, bisa juga di-inject menggunakan dependency injection.
  SupabaseAuthRemoteDataSource({GoTrueClient? supabaseAuth}) 
      : _supabaseAuth = supabaseAuth ?? Supabase.instance.client.auth;

  @override
  Stream<AuthState> get authStateChanges => _supabaseAuth.onAuthStateChange;

  @override
  User? getCurrentUser() {
    return _supabaseAuth.currentUser;
  }

  @override
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final AuthResponse response = await _supabaseAuth.signInWithPassword(
        email: email,
        password: password,
      );
      return response.user;
    } on AuthException catch (e) {
      // Tangani atau lempar ulang error spesifik Supabase
      // Misalnya, log error atau konversi ke error domain kustom
      _logger.e('SupabaseAuthRemoteDataSource - signIn Error', error: e, stackTrace: StackTrace.current);
      rethrow; // Lempar ulang agar bisa ditangani di lapisan atas
    }
  }

  @override
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final AuthResponse response = await _supabaseAuth.signUp(
        email: email,
        password: password,
        data: data, // Untuk menyimpan metadata pengguna tambahan
      );
      // Periksa apakah sesi dan pengguna ada. 
      // Untuk signUp, Supabase mungkin tidak langsung mengembalikan sesi aktif jika konfirmasi email diperlukan.
      // response.user akan ada jika pendaftaran berhasil, meskipun sesi mungkin null.
      return response.user;
    } on AuthException catch (e) {
      _logger.e('SupabaseAuthRemoteDataSource - signUp Error', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _supabaseAuth.signOut();
    } on AuthException catch (e) {
      _logger.e('SupabaseAuthRemoteDataSource - signOut Error', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _supabaseAuth.resetPasswordForEmail(email);
      _logger.i('SupabaseAuthRemoteDataSource - resetPassword: Email reset password berhasil dikirim ke $email');
    } on AuthException catch (e) {
      _logger.e('SupabaseAuthRemoteDataSource - resetPassword Error', error: e, stackTrace: StackTrace.current);
      rethrow;
    } catch (e) {
      _logger.e('SupabaseAuthRemoteDataSource - resetPassword Error tidak diketahui', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }

  @override
  Future<void> resendEmailConfirmation(String email) async {
    try {
      await _supabaseAuth.resend(
        type: OtpType.signup,
        email: email,
      );
      _logger.i('SupabaseAuthRemoteDataSource - resendEmailConfirmation: Email konfirmasi berhasil dikirim ulang ke $email');
    } on AuthException catch (e) {
      _logger.e('SupabaseAuthRemoteDataSource - resendEmailConfirmation Error', error: e, stackTrace: StackTrace.current);
      rethrow;
    } catch (e) {
      _logger.e('SupabaseAuthRemoteDataSource - resendEmailConfirmation Error tidak diketahui', error: e, stackTrace: StackTrace.current);
      rethrow;
    }
  }
}
