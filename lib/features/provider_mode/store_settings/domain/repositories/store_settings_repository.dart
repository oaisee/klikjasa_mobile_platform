import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';

abstract class StoreSettingsRepository {
  Future<Either<Failure, StoreSettingsEntity>> getStoreSettings(String providerId);
  Future<Either<Failure, bool>> updateStoreSettings(String providerId, StoreSettingsEntity settings);
  Future<Either<Failure, bool>> updateStoreStatus(String providerId, bool isActive);
  Future<Either<Failure, bool>> updateStoreLocation(String providerId, String address, double latitude, double longitude);
  Future<Either<Failure, bool>> updateServiceRadius(String providerId, double radius);
}
