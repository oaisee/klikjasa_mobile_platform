import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';

/// Use case untuk menghitung fee order
class CalculateOrderFee implements UseCase<double, CalculateOrderFeeParams> {
  final AppConfigRepository appConfigRepository;

  CalculateOrderFee(this.appConfigRepository);

  @override
  Future<Either<Failure, double>> call(CalculateOrderFeeParams params) async {
    // Ambil persentase fee sesuai tipe pengguna
    final feePercentageEither = params.isUserFee
        ? await appConfigRepository.getUserFeePercentage()
        : await appConfigRepository.getProviderFeePercentage();

    return feePercentageEither.fold(
      (failure) => Left(failure),
      (feePercentage) {
        // Hitung fee berdasarkan persentase dan total harga
        final feeAmount = (params.totalPrice * feePercentage) / 100;
        return Right(feeAmount);
      },
    );
  }
}

/// Parameter untuk menghitung fee order
class CalculateOrderFeeParams extends Equatable {
  final double totalPrice;
  final bool isUserFee;

  const CalculateOrderFeeParams({
    required this.totalPrice,
    required this.isUserFee,
  });

  @override
  List<Object?> get props => [totalPrice, isUserFee];
}