import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Service untuk menangani autentikasi pengguna
class AuthService {
  final _supabase = Supabase.instance.client;
  final _logger = Logger();
  
  /// Mendapatkan user yang sedang login
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Memeriksa apakah user sedang login
  bool get isAuthenticated => currentUser != null;
  
  /// Melakukan login dengan email dan password
  Future<AuthResponse> signInWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      _logger.e('Error signing in: $e');
      rethrow;
    }
  }
  
  /// Melakukan registrasi dengan email dan password
  Future<AuthResponse> signUpWithEmailPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      _logger.e('Error signing up: $e');
      rethrow;
    }
  }
  
  /// Melakukan logout
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      _logger.e('Error signing out: $e');
      rethrow;
    }
  }
  
  /// Mengirim link reset password
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      _logger.e('Error sending password reset email: $e');
      rethrow;
    }
  }
  
  /// Mengubah password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(
          password: newPassword,
        ),
      );
    } catch (e) {
      _logger.e('Error updating password: $e');
      rethrow;
    }
  }
  
  /// Menghapus akun pengguna
  Future<void> deleteAccount() async {
    try {
      // Catatan: Supabase tidak memiliki API langsung untuk menghapus akun
      // Biasanya ini memerlukan fungsi RPC khusus di backend
      // Contoh implementasi sederhana:
      await _supabase.functions.invoke('delete-account');
    } catch (e) {
      _logger.e('Error deleting account: $e');
      rethrow;
    }
  }
}
