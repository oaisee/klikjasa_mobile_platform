import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';

class GetAppConfigByKey implements UseCase<AppConfig, GetAppConfigByKeyParams> {
  final AppConfigRepository repository;

  GetAppConfigByKey({required this.repository});

  @override
  Future<Either<Failure, AppConfig>> call(GetAppConfigByKeyParams params) async {
    return await repository.getAppConfigByKey(params.key);
  }
}

class GetAppConfigByKeyParams extends Equatable {
  final String key;

  const GetAppConfigByKeyParams({required this.key});

  @override
  List<Object?> get props => [key];
}
