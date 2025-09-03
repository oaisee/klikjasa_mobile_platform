import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/repositories/store_settings_repository.dart';

class UpdateStoreStatusUseCase implements UseCase<bool, UpdateStoreStatusParams> {
  final StoreSettingsRepository repository;

  UpdateStoreStatusUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateStoreStatusParams params) {
    return repository.updateStoreStatus(params.providerId, params.isActive);
  }
}

class UpdateStoreStatusParams extends Equatable {
  final String providerId;
  final bool isActive;

  const UpdateStoreStatusParams({
    required this.providerId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [providerId, isActive];
}
