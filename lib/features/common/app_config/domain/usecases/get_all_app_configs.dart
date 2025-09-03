import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';

class GetAllAppConfigs implements UseCase<List<AppConfig>, NoParams> {
  final AppConfigRepository repository;

  GetAllAppConfigs({required this.repository});

  @override
  Future<Either<Failure, List<AppConfig>>> call(NoParams params) async {
    return await repository.getAllAppConfigs();
  }
}
