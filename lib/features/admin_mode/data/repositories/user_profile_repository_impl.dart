import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';
import 'package:klik_jasa/features/admin_mode/domain/repositories/user_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final SupabaseClient supabase;

  UserProfileRepositoryImpl({required this.supabase});

  @override
  Future<Either<Failure, List<UserProfile>>> getUserProfilesByType(
    bool isProvider,
  ) async {
    try {
      // Panggil Edge Function 'get-all-users' dengan parameter is_provider
      final url = 'get-all-users?is_provider=${isProvider.toString()}';
      final response = await supabase.functions.invoke(url);

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] as String? ?? 'Gagal memuat pengguna.';
        // Periksa pesan error spesifik dari fungsi
        if (errorMessage.contains('Forbidden')) {
          return Left(
            ServerFailure(
              message: 'Akses ditolak: Anda harus menjadi admin untuk melihat halaman ini.',
            ),
          );
        }
        return Left(ServerFailure(message: errorMessage));
      }

      final List<dynamic> data = response.data as List<dynamic>;

      final userProfiles = data.map((userData) {
        final map = userData as Map<String, dynamic>;

        // Konversi nilai saldo dengan aman
        final balanceNum = map['balance'] as num?;
        final balance = balanceNum?.toDouble() ?? 0.0;

        return UserProfile(
          id: map['id'] as String,
          email: map['email'] as String?,
          fullName: map['full_name'] as String?,
          role: map['role'] as String?,
          isProvider: map['is_provider'] as bool? ?? false,
          providerVerificationStatus:
              map['provider_verification_status'] as String?,
          createdAt: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'] as String)
              : null,
          updatedAt: map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'] as String)
              : null,
          avatarUrl: map['avatar_url'] as String?,
          phoneNumber: map['phone_number'] as String?,
          provinsi: map['provinsi'] as String?,
          kabupatenKota: map['kabupaten_kota'] as String?,
          kecamatan: map['kecamatan'] as String?,
          desaKelurahan: map['desa_kelurahan'] as String?,
          addressDetail: map['address_detail'] as String?,
          postalCode: map['postal_code'] as String?,
          ktpUrl: map['ktp_url'] as String?,
          latitude: (map['latitude'] as num?)?.toDouble(),
          longitude: (map['longitude'] as num?)?.toDouble(),
          saldo: balance,
        );
      }).toList();

      return Right(userProfiles);
    } on FunctionException catch (e) {
      final details = e.details as Map<String, dynamic>?;
      final errorMessage = details?['error'] as String? ?? e.toString();
      return Left(ServerFailure(message: 'Gagal memanggil fungsi: $errorMessage'));
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Terjadi kesalahan yang tidak diketahui: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, List<UserProfile>>> getUserProfiles() async {
    try {
      // Panggil Edge Function 'get-all-users'
      final response = await supabase.functions.invoke('get-all-users');

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] as String? ?? 'Gagal memuat pengguna.';
        // Periksa pesan error spesifik dari fungsi
        if (errorMessage.contains('Forbidden')) {
          return Left(
            ServerFailure(
              message: 'Akses ditolak: Anda harus menjadi admin untuk melihat halaman ini.',
            ),
          );
        }
        return Left(ServerFailure(message: errorMessage));
      }

      final List<dynamic> data = response.data as List<dynamic>;

      final userProfiles = data.map((userData) {
        final map = userData as Map<String, dynamic>;

        // Konversi nilai saldo dengan aman
        final balanceNum = map['balance'] as num?;
        final balance = balanceNum?.toDouble() ?? 0.0;

        return UserProfile(
          id: map['id'] as String,
          email: map['email'] as String?,
          fullName: map['full_name'] as String?,
          role: map['role'] as String?,
          isProvider: map['is_provider'] as bool? ?? false,
          providerVerificationStatus:
              map['provider_verification_status'] as String?,
          createdAt: map['created_at'] != null
              ? DateTime.tryParse(map['created_at'] as String)
              : null,
          updatedAt: map['updated_at'] != null
              ? DateTime.tryParse(map['updated_at'] as String)
              : null,
          avatarUrl: map['avatar_url'] as String?,
          phoneNumber: map['phone_number'] as String?,
          provinsi: map['provinsi'] as String?,
          kabupatenKota: map['kabupaten_kota'] as String?,
          kecamatan: map['kecamatan'] as String?,
          desaKelurahan: map['desa_kelurahan'] as String?,
          addressDetail: map['address_detail'] as String?,
          postalCode: map['postal_code'] as String?,
          ktpUrl: map['ktp_url'] as String?,
          latitude: (map['latitude'] as num?)?.toDouble(),
          longitude: (map['longitude'] as num?)?.toDouble(),
          saldo: balance,
        );
      }).toList();

      return Right(userProfiles);
    } on FunctionException catch (e) {
      final details = e.details as Map<String, dynamic>?;
      final errorMessage = details?['error'] as String? ?? e.toString();
      return Left(ServerFailure(message: 'Gagal memanggil fungsi: $errorMessage'));
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Terjadi kesalahan yang tidak diketahui: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> resetUserPassword(String userId) async {
    try {
      // Panggil Edge Function 'admin-reset-user-password' dengan parameter user_id
      final response = await supabase.functions.invoke(
        'admin-reset-user-password',
        body: {'user_id': userId},
      );

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] as String? ??
            'Gagal mereset password pengguna.';

        // Periksa pesan error spesifik dari fungsi
        if (errorMessage.contains('Forbidden')) {
          return Left(
            ServerFailure(
              message: 'Akses ditolak: Anda harus menjadi admin untuk melakukan operasi ini.',
            ),
          );
        }
        return Left(ServerFailure(message: errorMessage));
      }

      // Jika berhasil, response.data akan berisi {"success": true}
      final data = response.data as Map<String, dynamic>;
      final success = data['success'] as bool? ?? false;

      if (success) {
        return const Right(true);
      } else {
        return Left(ServerFailure(message: 'Gagal mereset password pengguna.'));
      }
    } on FunctionException catch (e) {
      final details = e.details as Map<String, dynamic>?;
      final errorMessage = details?['error'] as String? ?? e.toString();
      return Left(ServerFailure(message: 'Gagal memanggil fungsi: $errorMessage'));
    } catch (e) {
      return Left(
        ServerFailure(
          message: 'Terjadi kesalahan yang tidak diketahui: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .single();

      return response;
    } catch (e) {
      // Return null jika user tidak ditemukan atau terjadi error
      return null;
    }
  }
}
