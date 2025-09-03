import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/features/common/auth/data/datasources/auth_remote_data_source.dart';
import 'package:klik_jasa/features/common/auth/data/services/social_auth_service.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/auth_state_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart' as domain_user;
import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _authRemoteDataSource;
  final SocialAuthService _socialAuthService;
  final supabase.SupabaseClient _supabaseClient;
  final Logger _logger;

  AuthRepositoryImpl({
    required AuthRemoteDataSource authRemoteDataSource,
    required SocialAuthService socialAuthService,
    required supabase.SupabaseClient supabaseClient,
    required Logger logger,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _socialAuthService = socialAuthService,
        _supabaseClient = supabaseClient,
        _logger = logger;

  Future<domain_user.UserEntity> _mapSupabaseUserToDomainUserEntity(
    supabase.User supabaseUser, {
    Map<String, dynamic>? profileDataParam,
  }) async {
    try {
      // Ambil data profil dari database jika tidak disediakan sebagai parameter
      Map<String, dynamic>? profileData = profileDataParam;
      
      if (profileData == null) {
        try {
          final response = await _supabaseClient
              .from('profiles')
              .select('*')
              .eq('id', supabaseUser.id)
              .single();
          profileData = response;
        } catch (e) {
          _logger.w('Gagal mengambil data profil untuk user ${supabaseUser.id}: $e');
          profileData = null;
        }
      }

      // Tentukan role pengguna berdasarkan kolom 'role' di database
      String role = 'pengguna_jasa'; // Default role untuk pengguna jasa
      if (profileData != null && profileData.containsKey('role')) {
        final dbRole = profileData['role'] as String?;
        if (dbRole != null && dbRole.isNotEmpty) {
          role = dbRole;
        }
      }

      // Buat entity pengguna domain
      return domain_user.UserEntity(
        id: supabaseUser.id,
        email: supabaseUser.email,
        fullName: profileData?['full_name'] as String?,
        avatarUrl: profileData?['avatar_url'] as String?,
        phoneNumber: profileData?['phone_number'] as String?,
        address: profileData?['address'] as String?,
        isProvider: profileData?['is_provider'] as bool? ?? false,
        providerStatus: profileData?['provider_verification_status'] as String?,
        role: role,
        saldo: profileData?['saldo'] != null ? (profileData!['saldo'] as num).toDouble() : null,
      );
    } catch (e) {
      _logger.e('Error saat memetakan pengguna: $e');
      // Jika terjadi error, kembalikan entity pengguna minimal
      return domain_user.UserEntity(
        id: supabaseUser.id,
        email: supabaseUser.email,
        role: 'pengguna_jasa', // Default ke pengguna jasa
      );
    }
  }

  @override
  Stream<AuthStateEntity> get authStateChanges {
    return _authRemoteDataSource.authStateChanges.asyncMap((supabaseAuthState) async {
      // Jika tidak ada state autentikasi atau session, kembalikan status tidak terautentikasi
      if (supabaseAuthState.session == null) {
        return AuthStateUnauthenticated();
      }

      try {
        final supabaseUser = supabaseAuthState.session?.user;
        if (supabaseUser == null) {
          return AuthStateUnauthenticated();
        }

        final domainUserEntity = await _mapSupabaseUserToDomainUserEntity(supabaseUser);
        return AuthStateAuthenticated(user: domainUserEntity);
      } catch (e) {
        _logger.e('Error saat memetakan status auth: $e');
        return AuthStateUnauthenticated();
      }
    });
  }

  @override
  Future<Either<Failure, domain_user.UserEntity>> signInWithGoogle() async {
    try {
      debugPrint('AuthRepositoryImpl: Memulai proses login dengan Google');
      final authResponse = await _socialAuthService.signInWithGoogle();
      
      if (authResponse == null) {
        return Left(AuthenticationFailure(
          message: 'Login dengan Google dibatalkan oleh pengguna',
        ));
      }
      
      final supabaseUser = authResponse.session?.user;
      
      if (supabaseUser == null) {
        return Left(AuthenticationFailure(
          message: 'Tidak dapat mendapatkan data pengguna dari Google',
        ));
      }
      
      final domainUserEntity = await _mapSupabaseUserToDomainUserEntity(supabaseUser);
      
      return Right(domainUserEntity);
    } on supabase.AuthException catch (e) {
      debugPrint('AuthRepositoryImpl: Error login Google (AuthException): ${e.message}');
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      debugPrint('AuthRepositoryImpl: Error login Google (ServerException): ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      debugPrint('AuthRepositoryImpl: Error login Google (Generic): ${e.toString()}');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat login dengan Google: ${e.toString()}',
      ));
    }
  }
  
  @override
  Future<Either<Failure, domain_user.UserEntity>> signInWithApple() async {
    try {
      debugPrint('AuthRepositoryImpl: Memulai proses login dengan Apple');
      final authResponse = await _socialAuthService.signInWithApple();
      
      if (authResponse == null) {
        return Left(AuthenticationFailure(
          message: 'Login dengan Apple dibatalkan oleh pengguna',
        ));
      }
      
      final supabaseUser = authResponse.session?.user;
      
      if (supabaseUser == null) {
        return Left(AuthenticationFailure(
          message: 'Tidak dapat mendapatkan data pengguna dari Apple',
        ));
      }
      
      final domainUserEntity = await _mapSupabaseUserToDomainUserEntity(supabaseUser);
      
      return Right(domainUserEntity);
    } on supabase.AuthException catch (e) {
      debugPrint('AuthRepositoryImpl: Error login Apple (AuthException): ${e.message}');
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      debugPrint('AuthRepositoryImpl: Error login Apple (ServerException): ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      debugPrint('AuthRepositoryImpl: Error login Apple (Generic): ${e.toString()}');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat login dengan Apple: ${e.toString()}',
      ));
    }
  }

  @override
  Future<domain_user.UserEntity?> getCurrentUser() async {
    try {
      final supabaseUser = _authRemoteDataSource.getCurrentUser();
      if (supabaseUser == null) {
        return null;
      }
      return _mapSupabaseUserToDomainUserEntity(supabaseUser);
    } catch (e) {
      _logger.e('Error saat mendapatkan pengguna saat ini: $e');
      return null;
    }
  }

  @override
  Future<Either<Failure, domain_user.UserEntity>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final supabaseUser = await _authRemoteDataSource.signInWithEmailPassword(
        email: email,
        password: password,
      );
      if (supabaseUser == null) {
        return Left(AuthenticationFailure(
          message: 'Tidak dapat mendapatkan data pengguna',
        ));
      }

      final domainUserEntity = await _mapSupabaseUserToDomainUserEntity(supabaseUser);
      return Right(domainUserEntity);
    } on supabase.AuthException catch (e) {
      _logger.e('AuthException: ${e.message}');
      
      // Handle specific email confirmation error
      if (e.message.toLowerCase().contains('email not confirmed') ||
          e.message.toLowerCase().contains('email belum dikonfirmasi')) {
        return Left(AuthenticationFailure(
          message: 'Email Anda belum dikonfirmasi. Silakan cek email dan klik link konfirmasi, atau kirim ulang email konfirmasi.',
        ));
      }
      
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      _logger.e('Error umum: $e');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat login: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, domain_user.UserEntity>> signUpWithEmailPassword({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final supabaseUser = await _authRemoteDataSource.signUpWithEmailPassword(
        email: email,
        password: password,
        data: data,
      );
      if (supabaseUser == null) {
        return Left(AuthenticationFailure(
          message: 'Tidak dapat mendapatkan data pengguna',
        ));
      }

      final domainUserEntity = await _mapSupabaseUserToDomainUserEntity(
        supabaseUser,
        profileDataParam: data,
      );
      
      // Log info about email confirmation requirement
      if (supabaseUser.emailConfirmedAt == null) {
        _logger.i('User registered successfully but email confirmation required for: $email');
      }
      
      return Right(domainUserEntity);
    } on supabase.AuthException catch (e) {
      _logger.e('AuthException: ${e.message}');
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      _logger.e('Error umum: $e');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat mendaftar: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _authRemoteDataSource.signOut();
      return const Right(null);
    } catch (e) {
      _logger.e('Error saat logout: $e');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat logout: ${e.toString()}',
      ));
    }
  }
  
  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await _authRemoteDataSource.resetPassword(email);
      return const Right(null);
    } on supabase.AuthException catch (e) {
      _logger.e('AuthException saat reset password: ${e.message}');
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      _logger.e('Error umum saat reset password: $e');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat mengirim email reset password: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> resendEmailConfirmation(String email) async {
    try {
      await _authRemoteDataSource.resendEmailConfirmation(email);
      return const Right(null);
    } on supabase.AuthException catch (e) {
      _logger.e('AuthException saat resend email confirmation: ${e.message}');
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      _logger.e('Error umum saat resend email confirmation: $e');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat mengirim ulang email konfirmasi: ${e.toString()}',
      ));
    }
  }

  @override
  Future<Either<Failure, bool>> isEmailConfirmed(String email) async {
    try {
      final currentUser = _supabaseClient.auth.currentUser;
      if (currentUser == null || currentUser.email != email) {
        return const Left(AuthenticationFailure(
          message: 'Pengguna tidak ditemukan atau email tidak cocok',
        ));
      }
      
      final isConfirmed = currentUser.emailConfirmedAt != null;
      return Right(isConfirmed);
    } catch (e) {
      _logger.e('Error saat memeriksa status email confirmation: $e');
      return Left(ServerFailure(
        message: 'Terjadi kesalahan saat memeriksa status email: ${e.toString()}',
      ));
    }
  }
}
