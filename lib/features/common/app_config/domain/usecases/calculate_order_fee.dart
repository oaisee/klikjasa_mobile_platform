import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';

/// Use case untuk menghitung fee order berdasarkan tipe fee (user/provider)
class CalculateOrderFee {
  final AppConfigRepository repository;

  const CalculateOrderFee({required this.repository});

  Future<Either<Failure, double>> call(CalculateOrderFeeParams params) async {
    // Ambil persentase fee sesuai tipe pengguna
    final feePercentageEither = params.isUserFee
        ? await repository.getUserFeePercentage()
        : await repository.getProviderFeePercentage();

    return feePercentageEither.fold(
      (failure) => Left(failure),
      (feePercentage) {
        // Hitung fee berdasarkan persentase dan total harga
        final feeAmount = (params.orderAmount * feePercentage) / 100;
        return Right(feeAmount);
      },
    );
  }
}

/// Parameter untuk menghitung fee order
class CalculateOrderFeeParams extends Equatable {
  /// Jumlah total order
  final double orderAmount;
  
  /// Jenis fee: true untuk user fee, false untuk provider fee
  final bool isUserFee;

  const CalculateOrderFeeParams({
    required this.orderAmount,
    required this.isUserFee,
  });

  /// Factory constructor untuk membuat instance dari Map
  factory CalculateOrderFeeParams.fromMap(Map<String, dynamic> map) {
    return CalculateOrderFeeParams(
      orderAmount: map['orderAmount'] as double,
      isUserFee: map['isUserFee'] as bool? ?? true, // Default ke user fee
    );
  }

  /// Konversi ke Map
  Map<String, dynamic> toMap() {
    return {
      'orderAmount': orderAmount,
      'isUserFee': isUserFee,
    };
  }

  @override
  List<Object?> get props => [orderAmount, isUserFee];
}
