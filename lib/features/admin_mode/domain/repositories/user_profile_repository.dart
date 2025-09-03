import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  /// Mengambil semua profil pengguna tanpa filter
  Future<Either<Failure, List<UserProfile>>> getUserProfiles();
  
  /// Mengambil profil pengguna berdasarkan filter is_provider
  /// [isProvider] true untuk penyedia jasa, false untuk pengguna biasa
  Future<Either<Failure, List<UserProfile>>> getUserProfilesByType(bool isProvider);
  
  /// Reset password pengguna oleh admin
  /// [userId] ID pengguna yang akan direset passwordnya
  /// Mengembalikan true jika berhasil, failure jika gagal
  Future<Either<Failure, bool>> resetUserPassword(String userId);
  
  /// Mengambil profil pengguna berdasarkan userId
  /// [userId] ID pengguna yang akan diambil profilnya
  /// Mengembalikan Map\<String, dynamic\> yang berisi data profil pengguna
  Future<Map<String, dynamic>?> getUserProfile(String userId);
}
