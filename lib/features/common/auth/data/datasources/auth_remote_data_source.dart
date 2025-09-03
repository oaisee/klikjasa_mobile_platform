import 'package:supabase_flutter/supabase_flutter.dart';

// Abstraksi untuk sumber data autentikasi jarak jauh (Supabase Auth).
// Mendefinisikan kontrak untuk operasi yang berinteraksi langsung dengan layanan Supabase Auth.

abstract class AuthRemoteDataSource {
  // Mengembalikan stream perubahan status autentikasi dari Supabase.
  Stream<AuthState> get authStateChanges;

  // Mendapatkan pengguna Supabase yang saat ini terautentikasi.
  User? getCurrentUser();

  // Melakukan sign-in dengan email dan password ke Supabase.
  // Melempar AuthException jika terjadi kesalahan.
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  });

  // Melakukan sign-up (pendaftaran) dengan email dan password ke Supabase.
  // Melempar AuthException jika terjadi kesalahan.
  // `data` bisa digunakan untuk menyimpan metadata pengguna tambahan saat pendaftaran.
  Future<User?> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data, // Untuk data tambahan seperti nama, dll.
  });

  // Melakukan sign-out dari Supabase.
  // Melempar AuthException jika terjadi kesalahan.
  Future<void> signOut();

  // TODO: Tambahkan metode untuk provider OAuth (Google, Apple) jika diperlukan
  // Future<bool> signInWithGoogle();
  // Future<bool> signInWithApple();

  // Metode untuk mengirim email reset password
  Future<void> resetPassword(String email);
  
  // Metode untuk mengirim ulang email konfirmasi
  Future<void> resendEmailConfirmation(String email);
}
