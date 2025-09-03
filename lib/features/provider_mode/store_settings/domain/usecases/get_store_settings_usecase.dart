import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/repositories/store_settings_repository.dart';

class GetStoreSettingsUseCase implements UseCase<StoreSettingsEntity, String> {
  final StoreSettingsRepository repository;

  GetStoreSettingsUseCase(this.repository);

  @override
  Future<Either<Failure, StoreSettingsEntity>> call(String providerId) {
    return repository.getStoreSettings(providerId);
  }
}
