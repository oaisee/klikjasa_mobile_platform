import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:klik_jasa/features/common/auth/domain/entities/auth_state_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';



part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final Logger _logger = Logger();
  final AuthRepository _authRepository;

  StreamSubscription<AuthStateEntity>? _authStateSubscription;

  AuthBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const AuthInitial()) {
    _logger.i('AuthBloc INITIALIZED');

    // Handler untuk event perubahan status autentikasi dari repository
    on<AuthStatusChanged>(_onAuthStatusChanged);
    // Handler untuk event permintaan login
    on<AuthLoginRequested>(_onLoginRequested);
    // Handler untuk event permintaan registrasi
    on<AuthRegisterRequested>(_onRegisterRequested);
    // Handler untuk event permintaan logout
    on<AuthLogoutRequested>(_onLogoutRequested);
    // Handler untuk event pengecekan status auth awal
    on<AuthCheckRequested>(_onAuthCheckRequested);
    // Handler untuk event login dengan Google
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    // Handler untuk event login dengan Apple
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    // Handler untuk event login dengan biometrik
    on<AuthBiometricLoginRequested>(_onBiometricLoginRequested);
    // Handler untuk event reset password
    on<AuthPasswordResetRequested>(_onPasswordResetRequested);
    // Handler untuk event resend email confirmation
    on<AuthEmailConfirmationResendRequested>(_onEmailConfirmationResendRequested);



    // Hanya satu subscription ke authStateChanges
    _authStateSubscription =
        _authRepository.authStateChanges.listen((authStateEntity) {
      _logger.d(
          'AuthBloc: Received authStateEntity from authStateChanges: ${authStateEntity.runtimeType}');
      add(AuthStatusChanged(authStateEntity));
    }, onError: (error) {
      _logger.e('AuthBloc: Error on authStateChanges stream',
          error: error, stackTrace: StackTrace.current);
    }, onDone: () {
      _logger.d('AuthBloc: authStateChanges stream done.');
    });


  }

  // Fungsi helper untuk menerjemahkan pesan error dari AuthException
  String _translateAuthExceptionMessage(String? englishMessage) {
    if (englishMessage == null) {
      return 'Terjadi kesalahan yang tidak diketahui.';
    }

    _logger.d('AuthBloc: Menerjemahkan pesan: "$englishMessage"');
    if (englishMessage.contains('Invalid login credentials')) {
      return 'Kredensial masuk tidak valid. Periksa kembali email dan kata sandi Anda.';
    } else if (englishMessage.contains('User already registered') ||
        englishMessage.contains('User already exists')) {
      return 'Pengguna dengan email ini sudah terdaftar.';
    } else if (englishMessage
        .contains('Unable to validate email address: invalid format')) {
      return 'Format email tidak valid.';
    } else if (englishMessage
        .contains('Password should be at least 6 characters')) {
      return 'Kata sandi minimal harus 6 karakter.';
    } else if (englishMessage.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Silakan periksa email Anda untuk link konfirmasi.';
    } else if (englishMessage.contains('User not found')) {
      return 'Pengguna tidak ditemukan.';
    } else if (englishMessage.contains('Network request failed')) {
      return 'Gagal terhubung ke server. Periksa koneksi internet Anda.';
    } else if (englishMessage.contains('Login dibatalkan oleh pengguna')) {
      return 'Login Google dibatalkan.';
    }
    // Fallback jika tidak ada terjemahan spesifik
    _logger.d(
        'AuthBloc: Tidak ada terjemahan spesifik untuk "$englishMessage", mengembalikan pesan asli.');
    return englishMessage; // Kembalikan pesan asli jika tidak ada padanan
  }

  Future<void> _onAuthStatusChanged(
      AuthStatusChanged event, Emitter<AuthState> emit) async {
    final authStateEntity = event.authState;
    _logger.d(
        'AuthBloc: _onAuthStatusChanged - AuthStateEntity: ${authStateEntity.runtimeType}');
    if (authStateEntity is AuthStateAuthenticated) {
      // Gunakan nilai role langsung dari database yang sudah diambil oleh repository
      // Role ini sudah diatur oleh trigger database ensure_provider_consistency
      final role = authStateEntity.user.role;
      emit(AuthAuthenticated(user: authStateEntity.user, role: role));
      _logger.i(
          'AuthBloc: Emitting AuthAuthenticated for ${authStateEntity.user.email} with role: $role (from status change)');
    } else if (authStateEntity is AuthStateLoading) {
      // Tambahkan ini jika ada AuthStateLoading dari repository
      emit(const AuthLoading());
      _logger.d('AuthBloc: Emitting AuthLoading (Status Changed)');
    } else if (authStateEntity is AuthStateInitial) {
      emit(const AuthInitial()); // Pertahankan state AuthInitial
      _logger.d('AuthBloc: Emitting AuthInitial (Status Changed)');
    } else if (authStateEntity is AuthStateUnauthenticated) {
      emit(const AuthUnauthenticated());
      _logger.i('AuthBloc: Emitting AuthUnauthenticated');
    } else if (authStateEntity is AuthStateError) {
      emit(AuthFailure(message: authStateEntity.message));
      _logger.w(
          'AuthBloc: Emitting AuthFailure from AuthStateError: ${authStateEntity.message}');
    } else {
      // Fallback jika tipe AuthStateEntity tidak dikenali
      // Ini bisa terjadi jika ada tipe state baru dari repository yang belum ditangani di sini
      _logger.w(
          'AuthBloc: Emitting AuthUnauthenticated (Fallback from unknown AuthStateEntity: ${authStateEntity.runtimeType})');
      emit(const AuthUnauthenticated());
    }
  }



  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('AuthBloc: AuthLoginRequested - Email: ${event.email}');
    emit(const AuthLoading());
    _logger.d('AuthBloc: Emitting AuthLoading (Login)');
    try {
      final eitherResult = await _authRepository.signInWithEmailPassword(
        email: event.email,
        password: event.password,
      );
      eitherResult.fold(
        (failure) {
          final translatedMessage =
              _translateAuthExceptionMessage(failure.message);
          emit(AuthFailure(message: translatedMessage));
          _logger.w(
              'AuthBloc: Emitting AuthFailure (Login) - Original: ${failure.message}, Translated: $translatedMessage');
        },
        (userEntity) {
          // Role sudah diambil dari database oleh repository
          emit(AuthAuthenticated(user: userEntity, role: userEntity.role));
          _logger.i(
              'AuthBloc: Emitting AuthAuthenticated (Login) for ${userEntity.email} with role: ${userEntity.role}');
        },
      );
    } on supabase.AuthException catch (e) {
      // Ini seharusnya ditangani oleh Either di repository
      _logger.e('AuthBloc: AuthLoginRequested - AuthException',
          error: e, stackTrace: StackTrace.current);
      final translatedMessage = _translateAuthExceptionMessage(e.message);
      emit(AuthFailure(message: translatedMessage));

    } catch (e) {
      emit(AuthFailure(
          message: 'Terjadi kesalahan tidak diketahui: ${e.toString()}'));
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final eitherResult = await _authRepository.signUpWithEmailPassword(
        email: event.email,
        password: event.password,
        data: {'full_name': event.fullName},
      );
      eitherResult.fold(
        (failure) {
          final translatedMessage =
              _translateAuthExceptionMessage(failure.message);
          emit(AuthFailure(message: translatedMessage));

        },
        (userEntity) {
          emit(const AuthRegistrationSuccess(
              message:
                  'Registrasi berhasil! Silakan cek email Anda untuk verifikasi.'));

        },
      );
    } on supabase.AuthException catch (e) {
      // Ini seharusnya ditangani oleh Either di repository
      final translatedMessage = _translateAuthExceptionMessage(e.message);
      emit(AuthFailure(message: translatedMessage));
    } catch (e) {
      emit(AuthFailure(
          message: 'Terjadi kesalahan tidak diketahui: ${e.toString()}'));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {

    try {
      await _authRepository.signOut();

    } on supabase.AuthException catch (e) {
      emit(AuthFailure(message: e.message)); // Jarang terjadi error saat logout
    } catch (e) {
      emit(AuthFailure(
          message: 'Terjadi kesalahan saat logout: ${e.toString()}'));
    }
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {

    try {
      final userEntity = await _authRepository.getCurrentUser();
      if (userEntity == null) {
        emit(const AuthUnauthenticated());
      }

    } catch (e) {

      emit(AuthFailure(
          message: 'Gagal memeriksa status autentikasi: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription?.cancel();
    return super.close();
  }





  // Handler untuk login dengan Google
  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('AuthBloc: AuthGoogleSignInRequested');
    emit(const AuthLoading());
    _logger.d('AuthBloc: Emitting AuthLoading (Google Login)');

    try {
      final eitherResult = await _authRepository.signInWithGoogle();

      eitherResult.fold(
        (failure) {
          final translatedMessage =
              _translateAuthExceptionMessage(failure.message);
          emit(AuthFailure(message: translatedMessage));
          _logger.w(
              'AuthBloc: Emitting AuthFailure (Google Login) - Original: ${failure.message}, Translated: $translatedMessage');
        },
        (userEntity) {
          // Role sudah termasuk dalam UserEntity jika berhasil diambil oleh repository
          final role =
              (userEntity.isProvider && userEntity.providerStatus == 'verified')
                  ? 'provider'
                  : 'user';
          emit(AuthAuthenticated(user: userEntity, role: role));
          _logger.i(
              'AuthBloc: Emitting AuthAuthenticated (Google Login) for ${userEntity.email} with role: $role');
        },
      );
    } catch (e) {
      _logger.e('AuthBloc: AuthGoogleSignInRequested - Generic Exception',
          error: e, stackTrace: StackTrace.current);
      emit(AuthFailure(
          message: 'Terjadi kesalahan tidak diketahui: ${e.toString()}'));
      _logger.w('AuthBloc: Emitting AuthFailure (Google Login) - Generic Error',
          error: e);
    }
  }

  // Handler untuk login dengan Apple
  Future<void> _onAppleSignInRequested(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i('AuthBloc: AuthAppleSignInRequested');
    emit(const AuthLoading());
    _logger.d('AuthBloc: Emitting AuthLoading (Apple Login)');

    try {
      final eitherResult = await _authRepository.signInWithApple();

      eitherResult.fold(
        (failure) {
          final translatedMessage =
              _translateAuthExceptionMessage(failure.message);
          emit(AuthFailure(message: translatedMessage));
          _logger.w(
              'AuthBloc: Emitting AuthFailure (Apple Login) - Original: ${failure.message}, Translated: $translatedMessage');
        },
        (userEntity) {
          // Role sudah termasuk dalam UserEntity jika berhasil diambil oleh repository
          final role =
              (userEntity.isProvider && userEntity.providerStatus == 'verified')
                  ? 'provider'
                  : 'user';
          emit(AuthAuthenticated(user: userEntity, role: role));
          _logger.i(
              'AuthBloc: Emitting AuthAuthenticated (Apple Login) for ${userEntity.email} with role: $role');
        },
      );
    } catch (e) {
      _logger.e('AuthBloc: AuthAppleSignInRequested - Generic Exception',
          error: e, stackTrace: StackTrace.current);
      emit(AuthFailure(
          message: 'Terjadi kesalahan tidak diketahui: ${e.toString()}'));
      _logger.w('AuthBloc: Emitting AuthFailure (Apple Login) - Generic Error',
          error: e);
    }
  }

  // Handler untuk login dengan biometrik
  Future<void> _onBiometricLoginRequested(
    AuthBiometricLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger.i(
        'AuthBloc: AuthBiometricLoginRequested untuk userId: ${event.userId}');
    emit(const AuthLoading());
    _logger.d('AuthBloc: Emitting AuthLoading (Biometric Login)');

    try {
      // Cek user saat ini dari repository
      final currentUser = await _authRepository.getCurrentUser();

      if (currentUser != null && currentUser.id == event.userId) {
        // User sudah terautentikasi dan ID cocok dengan yang tersimpan
        final role =
            (currentUser.isProvider && currentUser.providerStatus == 'verified')
                ? 'provider'
                : 'user';
        emit(AuthAuthenticated(user: currentUser, role: role));
        _logger.i(
            'AuthBloc: Emitting AuthAuthenticated (Biometric Login) for ${currentUser.email} with role: $role');
      } else {
        // User tidak terautentikasi atau ID tidak cocok
        emit(const AuthFailure(
            message:
                'Login biometrik gagal. Silakan login dengan email dan password.'));
        _logger.w(
            'AuthBloc: Emitting AuthFailure (Biometric Login) - User tidak ditemukan atau ID tidak cocok');
      }
    } catch (e) {
      _logger.e('AuthBloc: AuthBiometricLoginRequested - Generic Exception',
          error: e, stackTrace: StackTrace.current);
      emit(AuthFailure(
          message:
              'Terjadi kesalahan saat login dengan biometrik: ${e.toString()}'));
      _logger.w(
          'AuthBloc: Emitting AuthFailure (Biometric Login) - Generic Error',
          error: e);
    }
  }

  // Handler untuk reset password
  Future<void> _onPasswordResetRequested(
    AuthPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger
        .i('AuthBloc: AuthPasswordResetRequested untuk email: ${event.email}');
    emit(const AuthPasswordResetLoading());
    _logger.d('AuthBloc: Emitting AuthPasswordResetLoading');

    try {
      final eitherResult = await _authRepository.resetPassword(event.email);

      eitherResult.fold(
        (failure) {
          final translatedMessage =
              _translateAuthExceptionMessage(failure.message);
          emit(AuthPasswordResetFailure(message: translatedMessage));
          _logger.w(
              'AuthBloc: Emitting AuthPasswordResetFailure - Original: ${failure.message}, Translated: $translatedMessage');
        },
        (_) {
          emit(const AuthPasswordResetSuccess(
            message:
                'Email reset password telah dikirim. Silakan periksa kotak masuk email Anda.',
          ));
          _logger.i(
              'AuthBloc: Emitting AuthPasswordResetSuccess untuk email: ${event.email}');
        },
      );
    } catch (e) {
      _logger.e('AuthBloc: AuthPasswordResetRequested - Generic Exception',
          error: e, stackTrace: StackTrace.current);
      emit(AuthPasswordResetFailure(
          message: 'Terjadi kesalahan tidak diketahui: ${e.toString()}'));
      _logger.w('AuthBloc: Emitting AuthPasswordResetFailure - Generic Error',
          error: e);
    }
  }

  Future<void> _onEmailConfirmationResendRequested(
    AuthEmailConfirmationResendRequested event,
    Emitter<AuthState> emit,
  ) async {
    _logger
        .i('AuthBloc: AuthEmailConfirmationResendRequested untuk email: ${event.email}');
    emit(const AuthEmailConfirmationResendLoading());
    _logger.d('AuthBloc: Emitting AuthEmailConfirmationResendLoading');

    try {
      final eitherResult = await _authRepository.resendEmailConfirmation(event.email);

      eitherResult.fold(
        (failure) {
          final translatedMessage =
              _translateAuthExceptionMessage(failure.message);
          emit(AuthEmailConfirmationResendFailure(message: translatedMessage));
          _logger.w(
              'AuthBloc: Emitting AuthEmailConfirmationResendFailure - Original: ${failure.message}, Translated: $translatedMessage');
        },
        (_) {
          emit(const AuthEmailConfirmationResendSuccess(
            message:
                'Email konfirmasi telah dikirim ulang. Silakan periksa kotak masuk email Anda.',
          ));
          _logger.i(
              'AuthBloc: Emitting AuthEmailConfirmationResendSuccess untuk email: ${event.email}');
        },
      );
    } catch (e) {
      _logger.e('AuthBloc: AuthEmailConfirmationResendRequested - Generic Exception',
          error: e, stackTrace: StackTrace.current);
      emit(AuthEmailConfirmationResendFailure(
          message: 'Terjadi kesalahan tidak diketahui: ${e.toString()}'));
      _logger.w('AuthBloc: Emitting AuthEmailConfirmationResendFailure - Generic Error',
          error: e);
    }
  }
}
