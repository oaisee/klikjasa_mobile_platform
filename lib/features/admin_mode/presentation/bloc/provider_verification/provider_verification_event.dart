part of 'provider_verification_bloc.dart';

@immutable
abstract class ProviderVerificationEvent extends Equatable {
  const ProviderVerificationEvent();

  @override
  List<Object> get props => [];
}

class LoadPendingVerifications extends ProviderVerificationEvent {}

class ApproveProviderVerification extends ProviderVerificationEvent {
  final String userId;

  const ApproveProviderVerification(this.userId);

  @override
  List<Object> get props => [userId];
}

class RejectProviderVerification extends ProviderVerificationEvent {
  final String userId;
  // Pertimbangkan untuk menambahkan alasan penolakan jika diperlukan
  // final String reason;

  const RejectProviderVerification(this.userId);

  @override
  List<Object> get props => [userId];
}
