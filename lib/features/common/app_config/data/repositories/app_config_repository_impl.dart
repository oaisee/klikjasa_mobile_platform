import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/features/common/app_config/data/datasources/app_config_remote_data_source.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';
import 'package:klik_jasa/features/common/app_config/domain/repositories/app_config_repository.dart';
import 'package:logger/logger.dart';

/// Implementasi repository untuk AppConfig
class AppConfigRepositoryImpl implements AppConfigRepository {
  final AppConfigRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final Logger logger;

  AppConfigRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.logger,
  });

  @override
  Future<Either<Failure, List<AppConfig>>> getAllAppConfigs() async {
    if (await networkInfo.isConnected) {
      try {
        final remoteConfigs = await remoteDataSource.getAllAppConfigs();
        return Right(remoteConfigs);
      } on ServerException {
        return Left(ServerFailure(message: 'Server error'));
      } catch (e) {
        logger.e('Unexpected error getting all app configs: $e');
        return Left(ServerFailure(message: 'Unexpected error'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AppConfig>> getAppConfigByKey(String key) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteConfig = await remoteDataSource.getAppConfigByKey(key);
        return Right(remoteConfig);
      } on ServerException {
        return Left(ServerFailure(message: 'Server error'));
      } catch (e) {
        logger.e('Unexpected error getting app config by key: $e');
        return Left(ServerFailure(message: 'Unexpected error'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, AppConfig>> updateAppConfig(String key, String value) async {
    if (await networkInfo.isConnected) {
      try {
        final updatedConfig = await remoteDataSource.updateAppConfig(key, value);
        return Right(updatedConfig);
      } on ServerException {
        return Left(ServerFailure(message: 'Server error'));
      } catch (e) {
        logger.e('Unexpected error updating app config: $e');
        return Left(ServerFailure(message: 'Unexpected error'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, double>> getUserFeePercentage() async {
    if (await networkInfo.isConnected) {
      try {
        final feePercentage = await remoteDataSource.getUserFeePercentage();
        return Right(feePercentage);
      } on ServerException {
        return Left(ServerFailure(message: 'Server error'));
      } catch (e) {
        logger.e('Unexpected error getting user fee percentage: $e');
        return Left(ServerFailure(message: 'Unexpected error'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
  
  @override
  Future<Either<Failure, double>> getProviderFeePercentage() async {
    if (await networkInfo.isConnected) {
      try {
        final feePercentage = await remoteDataSource.getProviderFeePercentage();
        return Right(feePercentage);
      } on ServerException {
        return Left(ServerFailure(message: 'Server error'));
      } catch (e) {
        logger.e('Unexpected error getting provider fee percentage: $e');
        return Left(ServerFailure(message: 'Unexpected error'));
      }
    } else {
      return Left(NetworkFailure(message: 'No internet connection'));
    }
  }
}
