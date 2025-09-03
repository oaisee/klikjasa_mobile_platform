import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart';
import 'package:klik_jasa/features/admin_mode/domain/repositories/user_profile_repository.dart';

part 'user_management_event.dart';
part 'user_management_state.dart';

class UserManagementBloc extends Bloc<UserManagementEvent, UserManagementState> {
  final UserProfileRepository _userProfileRepository;

  UserManagementBloc({required UserProfileRepository userProfileRepository})
      : _userProfileRepository = userProfileRepository,
        super(UserManagementInitial()) {
    on<FetchUserProfiles>(_onFetchUserProfiles);
    on<FetchUserProfilesByType>(_onFetchUserProfilesByType);
    on<ResetUserPassword>(_onResetUserPassword);
  }

  Future<void> _onFetchUserProfiles(
    FetchUserProfiles event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await _userProfileRepository.getUserProfiles();
    result.fold(
      (failure) => emit(UserManagementError(message: failure.message)),
      (userProfiles) => emit(UserManagementLoaded(userProfiles: userProfiles)),
    );
  }
  
  Future<void> _onFetchUserProfilesByType(
    FetchUserProfilesByType event,
    Emitter<UserManagementState> emit,
  ) async {
    emit(UserManagementLoading());
    final result = await _userProfileRepository.getUserProfilesByType(event.isProvider);
    result.fold(
      (failure) => emit(UserManagementError(message: failure.message)),
      (userProfiles) => emit(UserManagementLoaded(userProfiles: userProfiles)),
    );
  }
  
  Future<void> _onResetUserPassword(
    ResetUserPassword event,
    Emitter<UserManagementState> emit,
  ) async {
    // Emit state loading untuk reset password
    emit(ResetPasswordInProgress());
    
    // Panggil repository untuk reset password
    final result = await _userProfileRepository.resetUserPassword(event.userId);
    
    // Handle hasil
    result.fold(
      (failure) => emit(ResetPasswordFailure(message: failure.message)),
      (success) => emit(ResetPasswordSuccess(userId: event.userId)),
    );
  }
}
