import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';

abstract class AppConfigRepository {
  /// Mengambil semua pengaturan aplikasi
  Future<Either<Failure, List<AppConfig>>> getAllAppConfigs();

  /// Mengambil pengaturan aplikasi berdasarkan key
  Future<Either<Failure, AppConfig>> getAppConfigByKey(String key);

  /// Mengupdate nilai pengaturan aplikasi
  Future<Either<Failure, AppConfig>> updateAppConfig(String key, String value);
  
  /// Mengambil persentase fee untuk pengguna jasa
  Future<Either<Failure, double>> getUserFeePercentage();
  
  /// Mengambil persentase fee untuk penyedia jasa
  Future<Either<Failure, double>> getProviderFeePercentage();
}
