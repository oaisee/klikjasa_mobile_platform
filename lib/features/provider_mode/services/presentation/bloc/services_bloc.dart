import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/add_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/delete_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_layanan_detail_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/get_provider_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/update_layanan_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/toggle_service_promotion_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/usecases/toggle_service_active_usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_event.dart';
import 'package:klik_jasa/features/provider_mode/services/presentation/bloc/services_state.dart';

/// BLoC untuk mengelola state layanan provider.
class ServicesBloc extends Bloc<ServicesEvent, ServicesState> {
  final GetProviderLayananUseCase getProviderLayananUseCase;
  final AddLayananUseCase addLayananUseCase;
  final UpdateLayananUseCase updateLayananUseCase;
  final DeleteLayananUseCase deleteLayananUseCase;
  final GetLayananDetailUseCase getLayananDetailUseCase;
  final ToggleServicePromotionUsecase toggleServicePromotionUsecase;
  final ToggleServiceActiveUseCase toggleServiceActiveUseCase;

  ServicesBloc({
    required this.getProviderLayananUseCase,
    required this.addLayananUseCase,
    required this.updateLayananUseCase,
    required this.deleteLayananUseCase,
    required this.getLayananDetailUseCase,
    required this.toggleServicePromotionUsecase,
    required this.toggleServiceActiveUseCase,
  }) : super(ServicesInitial()) {
    on<LoadProviderLayanan>(_onLoadProviderLayanan);
    on<AddLayanan>(_onAddLayanan);
    on<UpdateLayanan>(_onUpdateLayanan);
    on<DeleteLayanan>(_onDeleteLayanan);
    on<LoadLayananDetail>(_onLoadLayananDetail);
    on<SetLayananActive>(_onSetLayananActive);
    on<ToggleLayananPromosi>(_onToggleLayananPromosi);
  }

  /// Handler untuk event [LoadProviderLayanan].
  Future<void> _onLoadProviderLayanan(
    LoadProviderLayanan event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    final result = await getProviderLayananUseCase(
      GetProviderLayananParams(
        providerId: event.providerId,
        isActive: event.isActive,
      ),
    );
    
    result.fold(
      (failure) => emit(ServicesError(message: failure.message)),
      (layanan) => emit(ServicesLoaded(layanan: layanan)),
    );
  }

  /// Handler untuk event [AddLayanan].
  Future<void> _onAddLayanan(
    AddLayanan event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    final result = await addLayananUseCase(
      AddLayananParams(service: event.layanan),
    );
    
    result.fold(
      (failure) => emit(ServicesError(message: failure.message)),
      (_) => emit(LayananAdded(layanan: event.layanan)),
    );
  }

  /// Handler untuk event [UpdateLayanan].
  Future<void> _onUpdateLayanan(
    UpdateLayanan event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    final result = await updateLayananUseCase(
      UpdateLayananParams(service: event.layanan),
    );
    
    result.fold(
      (failure) => emit(ServicesError(message: failure.message)),
      (_) => emit(LayananUpdated(layanan: event.layanan)),
    );
  }

  /// Handler untuk event [DeleteLayanan].
  Future<void> _onDeleteLayanan(
    DeleteLayanan event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    final result = await deleteLayananUseCase(
      DeleteLayananParams(layananId: event.layananId),
    );
    
    result.fold(
      (failure) => emit(ServicesError(message: failure.message)),
      (_) => emit(LayananDeleted(layananId: event.layananId)),
    );
  }

  /// Handler untuk event [LoadLayananDetail].
  Future<void> _onLoadLayananDetail(
    LoadLayananDetail event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    final result = await getLayananDetailUseCase(
      GetLayananDetailParams(layananId: event.layananId),
    );
    
    result.fold(
      (failure) => emit(ServicesError(message: failure.message)),
      (layanan) => emit(LayananDetailLoaded(layanan: layanan)),
    );
  }

  /// Handler untuk event [SetLayananActive].
  Future<void> _onSetLayananActive(
    SetLayananActive event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    // Pertama, dapatkan detail layanan yang akan diubah status aktifnya
    final detailResult = await getLayananDetailUseCase(
      GetLayananDetailParams(layananId: event.layananId),
    );

    await detailResult.fold(
      (failure) async {
        emit(ServicesError(message: failure.message));
        return Left<Failure, void>(failure);
      },
      (layanan) async {
        // Perbarui status aktif layanan
        final updatedLayanan = layanan.copyWith(isActive: event.isActive);
        
        final updateResult = await updateLayananUseCase(
          UpdateLayananParams(service: updatedLayanan),
        );
        
        return updateResult.fold(
          (failure) {
            emit(ServicesError(message: failure.message));
            return Left<Failure, void>(failure);
          },
          (_) {
            emit(LayananUpdated(layanan: updatedLayanan));
            return const Right<Failure, void>(null);
          },
        );
      },
    );
    
    // Tidak perlu melakukan apa-apa lagi di sini karena emit sudah dilakukan di dalam fold
  }

  /// Handler untuk event [ToggleLayananPromosi].
  Future<void> _onToggleLayananPromosi(
    ToggleLayananPromosi event,
    Emitter<ServicesState> emit,
  ) async {
    emit(ServicesLoading());

    // Menggunakan ToggleServicePromotionUsecase untuk mengaktifkan/menonaktifkan promosi
    final toggleResult = await toggleServicePromotionUsecase(
      serviceId: event.layananId,
      providerId: event.providerId,
      isPromoted: event.isPromoted,
      serviceTitle: event.serviceTitle,
    );
    
    toggleResult.fold(
      (failure) {
        emit(ServicesError(message: failure.message));
      },
      (updatedService) {
        emit(LayananUpdated(layanan: updatedService));
      },
    );
  }
}
