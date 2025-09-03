part of 'user_view_bloc.dart';

abstract class UserViewEvent extends Equatable {
  const UserViewEvent();

  @override
  List<Object?> get props => [];
}

/// Event untuk menginisialisasi UserViewBloc, biasanya setelah login.
/// Membawa userId untuk mengambil status penyedia.
class UserViewInitialize extends UserViewEvent {
  final String userId;
  final String? userRole; // Role umum dari AuthBloc

  const UserViewInitialize({required this.userId, this.userRole});

  @override
  List<Object?> get props => [userId, userRole];
}

/// Event yang dipicu ketika status penyedia jasa pengguna telah diambil.
class _UserProviderStatusUpdated extends UserViewEvent {
  final String? providerStatus;
  final String? fullName;
  final String? avatarUrl;
  final double saldo; // Tambahan field saldo (non-nullable)

  const _UserProviderStatusUpdated({this.providerStatus, this.fullName, this.avatarUrl, this.saldo = 0.0});

  @override
  List<Object?> get props => [providerStatus, fullName, avatarUrl, saldo];
}

/// Event untuk meminta pergantian mode tampilan.
class UserViewSwitchModeRequested extends UserViewEvent {
  final UserViewMode requestedMode;

  const UserViewSwitchModeRequested({required this.requestedMode});

  @override
  List<Object?> get props => [requestedMode];
}

/// Event untuk mereset state UserViewBloc, biasanya saat logout.
class UserViewReset extends UserViewEvent {}

/// Event untuk memperbarui saldo pengguna setelah transaksi.
class UserViewUpdateBalance extends UserViewEvent {
  final String userId;

  const UserViewUpdateBalance({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Event untuk memperbarui saldo pengguna secara real-time dari subscription.
class UserViewUpdateBalanceRealtime extends UserViewEvent {
  final double newBalance;

  const UserViewUpdateBalanceRealtime(this.newBalance);

  @override
  List<Object?> get props => [newBalance];
}
