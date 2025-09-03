part of 'auth_bloc.dart';

// Kelas dasar abstrak untuk semua state autentikasi.
// Menggunakan Equatable untuk mempermudah perbandingan antar instance state.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// State baru untuk menandakan registrasi berhasil, mungkin memerlukan tindakan lebih lanjut (misal, konfirmasi email).
class AuthRegistrationSuccess extends AuthState {
  final String message;

  const AuthRegistrationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

// State awal, sebelum ada tindakan autentikasi yang dilakukan.
class AuthInitial extends AuthState {
  const AuthInitial();
}

// State yang menandakan bahwa proses autentikasi sedang berlangsung (misalnya, saat login atau registrasi).
class AuthLoading extends AuthState {
  const AuthLoading();
}

// State yang menandakan bahwa pengguna berhasil diautentikasi.
// Menyimpan informasi pengguna yang terautentikasi.
class AuthAuthenticated extends AuthState {
  final UserEntity user; // Menggunakan UserEntity dan non-nullable
  final String? role; 

  const AuthAuthenticated({required this.user, this.role});

  @override
  List<Object?> get props => [user, role];
}

// State yang menandakan bahwa tidak ada pengguna yang terautentikasi, atau pengguna telah logout.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

// State yang menandakan bahwa terjadi kegagalan selama proses autentikasi.
// Menyimpan pesan error untuk ditampilkan kepada pengguna atau untuk logging.
class AuthFailure extends AuthState {
  final String message;

  const AuthFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// State untuk implementasi kedua - digunakan sebagai alias untuk kompatibilitas
class Authenticated extends AuthState {
  final UserEntity user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// State untuk menandakan proses reset password sedang berlangsung
class AuthPasswordResetLoading extends AuthState {
  const AuthPasswordResetLoading();
}

// State untuk menandakan reset password berhasil
class AuthPasswordResetSuccess extends AuthState {
  final String message;

  const AuthPasswordResetSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

// State untuk menandakan reset password gagal
class AuthPasswordResetFailure extends AuthState {
  final String message;

  const AuthPasswordResetFailure({required this.message});

  @override
  List<Object?> get props => [message];
}

// State untuk menandakan proses resend email confirmation sedang berlangsung
class AuthEmailConfirmationResendLoading extends AuthState {
  const AuthEmailConfirmationResendLoading();
}

// State untuk menandakan resend email confirmation berhasil
class AuthEmailConfirmationResendSuccess extends AuthState {
  final String message;

  const AuthEmailConfirmationResendSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

// State untuk menandakan resend email confirmation gagal
class AuthEmailConfirmationResendFailure extends AuthState {
  final String message;

  const AuthEmailConfirmationResendFailure({required this.message});

  @override
  List<Object?> get props => [message];
}
