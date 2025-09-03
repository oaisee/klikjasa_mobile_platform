part of 'user_view_bloc.dart';

class UserViewState extends Equatable {
  /// Mode tampilan saat ini (pengguna atau penyedia).
  final UserViewMode currentViewMode;

  /// Status verifikasi penyedia jasa pengguna (misalnya, 'verified', 'pending', 'none').
  final String? providerStatus;

  /// Peran umum pengguna (misalnya, 'admin', 'user'), jika ada.
  final String? userRole;

  /// Menunjukkan apakah pengguna adalah penyedia jasa yang terverifikasi.
  final bool isVerifiedProvider;

  /// Menunjukkan apakah data sedang dimuat (misalnya, saat mengambil providerStatus).
  final bool isLoading;

  /// Menunjukkan apakah status verifikasi penyedia adalah 'pending'.
  final bool isPendingVerification;

  /// Nama lengkap pengguna.
  final String? fullName;

  /// URL avatar pengguna.
  final String? avatarUrl;

  /// Saldo pengguna.
  final double saldo;

  const UserViewState({
    this.currentViewMode = UserViewMode.pengguna, // Default ke pengguna
    this.providerStatus,
    this.userRole,
    this.isVerifiedProvider = false,
    this.isLoading = false,
    this.isPendingVerification = false,
    this.fullName,
    this.avatarUrl,
    this.saldo = 0.0,
  });

  UserViewState copyWith({
    UserViewMode? currentViewMode,
    String? providerStatus,
    String? userRole,
    bool? isVerifiedProvider,
    bool? isLoading,
    bool? isPendingVerification,
    String? fullName,
    String? avatarUrl,
    double? saldo, // Tambahan parameter saldo
    bool clearProviderStatus = false, // Flag untuk menghapus providerStatus
    bool clearUserRole = false, // Flag untuk menghapus userRole
    bool clearFullName = false, // Flag untuk menghapus fullName
    bool clearAvatarUrl = false, // Flag untuk menghapus avatarUrl
    bool clearSaldo = false, // Flag untuk menghapus saldo
  }) {
    return UserViewState(
      currentViewMode: currentViewMode ?? this.currentViewMode,
      providerStatus: clearProviderStatus ? null : providerStatus ?? this.providerStatus,
      userRole: clearUserRole ? null : userRole ?? this.userRole,
      isVerifiedProvider: isVerifiedProvider ?? this.isVerifiedProvider,
      isLoading: isLoading ?? this.isLoading,
      isPendingVerification: isPendingVerification ?? this.isPendingVerification,
      fullName: clearFullName ? null : fullName ?? this.fullName,
      avatarUrl: clearAvatarUrl ? null : avatarUrl ?? this.avatarUrl,
      saldo: clearSaldo ? 0.0 : saldo ?? this.saldo,
    );
  }

  @override
  List<Object?> get props => [
        currentViewMode,
        providerStatus,
        userRole,
        isVerifiedProvider,
        isLoading,
        isPendingVerification,
        fullName,
        avatarUrl,
        saldo,
      ];
}
