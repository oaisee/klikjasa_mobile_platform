part of 'provider_verification_bloc.dart';

@immutable
abstract class ProviderVerificationState extends Equatable {
  const ProviderVerificationState();

  @override
  List<Object> get props => [];
}

class ProviderVerificationInitial extends ProviderVerificationState {}

class ProviderVerificationLoading extends ProviderVerificationState {}

class ProviderVerificationLoaded extends ProviderVerificationState {
  // Kita asumsikan akan menggunakan model UserProfile yang sudah ada
  // atau model spesifik seperti ProviderProfile jika dibuat.
  // Untuk saat ini, kita gunakan UserProfile dari auth/domain/entities
  // Path UserProfile telah dikonfirmasi ke features/admin_mode/domain/entities/user_profile.dart
  final List<UserProfile> pendingProviders;

  const ProviderVerificationLoaded(this.pendingProviders);

  @override
  List<Object> get props => [pendingProviders];
}

class ProviderVerificationError extends ProviderVerificationState {
  final String message;

  const ProviderVerificationError(this.message);

  @override
  List<Object> get props => [message];
}

// State untuk proses update (approve/reject)
class ProviderVerificationUpdateInProgress extends ProviderVerificationState {}

class ProviderVerificationUpdateSuccess extends ProviderVerificationState {
  final String message;
  const ProviderVerificationUpdateSuccess(this.message);

  @override
  List<Object> get props => [message];
}

class ProviderVerificationUpdateFailure extends ProviderVerificationState {
  final String message;
  const ProviderVerificationUpdateFailure(this.message);

  @override
  List<Object> get props => [message];
}
