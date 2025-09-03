part of 'user_management_bloc.dart';

abstract class UserManagementEvent extends Equatable {
  const UserManagementEvent();

  @override
  List<Object> get props => [];
}

/// Event untuk mengambil semua profil pengguna tanpa filter
class FetchUserProfiles extends UserManagementEvent {}

/// Event untuk mengambil profil pengguna berdasarkan filter is_provider
class FetchUserProfilesByType extends UserManagementEvent {
  final bool isProvider;

  const FetchUserProfilesByType(this.isProvider);

  @override
  List<Object> get props => [isProvider];
}

/// Event untuk mereset password pengguna oleh admin
class ResetUserPassword extends UserManagementEvent {
  final String userId;

  const ResetUserPassword(this.userId);

  @override
  List<Object> get props => [userId];
}
