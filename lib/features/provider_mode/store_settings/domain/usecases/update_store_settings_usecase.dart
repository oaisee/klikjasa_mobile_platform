import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/repositories/store_settings_repository.dart';

class UpdateStoreSettingsUseCase implements UseCase<bool, UpdateStoreSettingsParams> {
  final StoreSettingsRepository repository;

  UpdateStoreSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(UpdateStoreSettingsParams params) {
    return repository.updateStoreSettings(params.providerId, params.settings);
  }
}

class UpdateStoreSettingsParams extends Equatable {
  final String providerId;
  final StoreSettingsEntity settings;

  const UpdateStoreSettingsParams({
    required this.providerId,
    required this.settings,
  });

  @override
  List<Object?> get props => [providerId, settings];
}
