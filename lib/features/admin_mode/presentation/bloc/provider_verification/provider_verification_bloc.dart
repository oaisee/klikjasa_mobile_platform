import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:klik_jasa/features/admin_mode/domain/entities/user_profile.dart'; // Path UserProfile yang benar
import 'package:klik_jasa/features/admin_mode/domain/repositories/provider_verification_repository.dart';

part 'provider_verification_event.dart';
part 'provider_verification_state.dart';

class ProviderVerificationBloc extends Bloc<ProviderVerificationEvent, ProviderVerificationState> {
  final ProviderVerificationRepository _repository;

  ProviderVerificationBloc({required ProviderVerificationRepository repository}) : _repository = repository, super(ProviderVerificationInitial()) {
    on<LoadPendingVerifications>(_onLoadPendingVerifications);
    on<ApproveProviderVerification>(_onApproveProviderVerification);
    on<RejectProviderVerification>(_onRejectProviderVerification);
  }

  Future<void> _onLoadPendingVerifications(
    LoadPendingVerifications event,
    Emitter<ProviderVerificationState> emit,
  ) async {
    emit(ProviderVerificationLoading());
    try {
      final providers = await _repository.getPendingProviderVerifications();
      emit(ProviderVerificationLoaded(providers));
    } catch (e) {
      emit(ProviderVerificationError(e.toString()));
    }
  }

  Future<void> _onApproveProviderVerification(
    ApproveProviderVerification event,
    Emitter<ProviderVerificationState> emit,
  ) async {
    emit(ProviderVerificationUpdateInProgress());
    try {
      await _repository.updateProviderVerificationStatus(event.userId, 'verified');
      emit(const ProviderVerificationUpdateSuccess('Verifikasi penyedia berhasil disetujui.'));
      // Muat ulang daftar setelah update
      add(LoadPendingVerifications()); 
    } catch (e) {
      emit(ProviderVerificationUpdateFailure('Gagal menyetujui verifikasi: ${e.toString()}'));
    }
  }

  Future<void> _onRejectProviderVerification(
    RejectProviderVerification event,
    Emitter<ProviderVerificationState> emit,
  ) async {
    emit(ProviderVerificationUpdateInProgress());
    try {
      await _repository.updateProviderVerificationStatus(event.userId, 'rejected');
      emit(const ProviderVerificationUpdateSuccess('Verifikasi penyedia berhasil ditolak.'));
      // Muat ulang daftar setelah update
      add(LoadPendingVerifications());
    } catch (e) {
      emit(ProviderVerificationUpdateFailure('Gagal menolak verifikasi: ${e.toString()}'));
    }
  }
}
