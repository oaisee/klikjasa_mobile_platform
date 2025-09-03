part of 'user_management_bloc.dart';

abstract class UserManagementState extends Equatable {
  const UserManagementState();

  @override
  List<Object> get props => [];
}

class UserManagementInitial extends UserManagementState {}

class UserManagementLoading extends UserManagementState {}

class UserManagementLoaded extends UserManagementState {
  final List<UserProfile> userProfiles;

  const UserManagementLoaded({required this.userProfiles});

  @override
  List<Object> get props => [userProfiles];
}

class UserManagementError extends UserManagementState {
  final String message;

  const UserManagementError({required this.message});

  @override
  List<Object> get props => [message];
}

// States untuk reset password
class ResetPasswordInProgress extends UserManagementState {}

class ResetPasswordSuccess extends UserManagementState {
  final String userId;
  
  const ResetPasswordSuccess({required this.userId});
  
  @override
  List<Object> get props => [userId];
}

class ResetPasswordFailure extends UserManagementState {
  final String message;
  
  const ResetPasswordFailure({required this.message});
  
  @override
  List<Object> get props => [message];
}
