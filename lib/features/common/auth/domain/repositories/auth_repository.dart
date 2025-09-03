import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/auth_state_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';

// Abstraksi untuk layanan autentikasi.
// Ini mendefinisikan kontrak yang harus dipenuhi oleh implementasi repository autentikasi.
// Memungkinkan penggantian implementasi backend auth jika diperlukan tanpa mengubah logika bisnis.

abstract class AuthRepository {
  // Mengembalikan stream perubahan status autentikasi pengguna.
  // Berguna untuk mendengarkan perubahan login/logout secara real-time.
  Stream<AuthStateEntity> get authStateChanges;

  // Mendapatkan pengguna yang saat ini terautentikasi.
  // Mengembalikan null jika tidak ada pengguna yang login.
  Future<UserEntity?> getCurrentUser();

  // Proses login menggunakan email dan kata sandi.
  // Mengembalikan User jika berhasil, atau melempar Exception jika gagal.
  Future<Either<Failure, UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  // Proses pendaftaran pengguna baru menggunakan email dan kata sandi.
  // Mengembalikan User jika berhasil, atau melempar Exception jika gagal.
  // Mungkin juga perlu menangani konfirmasi email tergantung konfigurasi Supabase.
  Future<Either<Failure, UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data, // Untuk nama, dll.
  });

  // Proses logout pengguna saat ini.
  // Melempar Exception jika gagal.
  Future<Either<Failure, void>> signOut();

  // Mengambil peran pengguna berdasarkan ID pengguna.
  // Future<String?> getUserRole(String userId); // Dikomentari untuk saat ini

  // Metode untuk login dengan Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();
  
  // Metode untuk login dengan Apple
  Future<Either<Failure, UserEntity>> signInWithApple();
  
  // Metode untuk mengirim email reset password
  Future<Either<Failure, void>> resetPassword(String email);
  
  // Metode untuk mengirim ulang email konfirmasi
  Future<Either<Failure, void>> resendEmailConfirmation(String email);
  
  // Metode untuk memeriksa status email confirmation
  Future<Either<Failure, bool>> isEmailConfirmed(String email);
}
