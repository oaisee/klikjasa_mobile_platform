import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';

/// Use case untuk mendapatkan persentase fee pengguna
class GetUserFeePercentage implements UseCase<double, NoParams> {
  final AppConfigRepository repository;

  GetUserFeePercentage(this.repository);

  @override
  Future<Either<Failure, double>> call(NoParams params) {
    return repository.getUserFeePercentage();
  }
}
