import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';

class UpdateAppConfig implements UseCase<AppConfig, UpdateAppConfigParams> {
  final AppConfigRepository repository;

  UpdateAppConfig({required this.repository});

  @override
  Future<Either<Failure, AppConfig>> call(UpdateAppConfigParams params) async {
    return await repository.updateAppConfig(params.key, params.value);
  }
}

class UpdateAppConfigParams extends Equatable {
  final String key;
  final String value;

  const UpdateAppConfigParams({required this.key, required this.value});

  @override
  List<Object?> get props => [key, value];
}
