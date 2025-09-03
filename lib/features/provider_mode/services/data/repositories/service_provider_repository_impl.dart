import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/features/provider_mode/services/data/datasources/service_provider_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/services/data/models/service_model.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

class ServiceProviderRepositoryImpl implements ServiceProviderRepository {
  final ServiceProviderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  ServiceProviderRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Service>>> getProviderServices(
    String providerId, {
    bool? isActive,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final remoteData = await remoteDataSource.getProviderServices(
          providerId,
        );
        final serviceList = remoteData
            .map((data) => ServiceModel.fromJson(data).toEntity())
            .where((service) {
              // Filter tambahan berdasarkan isActive jika disediakan
              if (isActive != null) {
                return service.isActive == isActive;
              }
              return true;
            })
            .toList();
        return Right(serviceList);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Gagal mengambil daftar layanan: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }

  @override
  Future<Either<Failure, Service>> addService(Service service) async {
    try {
      final response = await remoteDataSource.addService(ServiceModel.fromEntity(service));
      return Right(ServiceModel.fromJson(response).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal menambahkan layanan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Service>> updateService(Service service) async {
    try {
      final response = await remoteDataSource.updateService(ServiceModel.fromEntity(service));
      return Right(ServiceModel.fromJson(response).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal memperbarui layanan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteService(String id) async {
    try {
      await remoteDataSource.deleteService(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal menghapus layanan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Service>> getServiceDetail(String layananId) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.getServiceDetail(layananId);
        return Right(ServiceModel.fromJson(response).toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Gagal mengambil detail layanan: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }

  @override
  Future<Either<Failure, Service>> updateServicePromotion({
    required String serviceId,
    required bool isPromoted,
    DateTime? promotionStartDate,
    DateTime? promotionEndDate,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final response = await remoteDataSource.updateServicePromotion(
          serviceId: serviceId,
          isPromoted: isPromoted,
          promotionStartDate: promotionStartDate,
          promotionEndDate: promotionEndDate,
        );
        return Right(ServiceModel.fromJson(response).toEntity());
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        return Left(ServerFailure(message: 'Gagal memperbarui promosi layanan: ${e.toString()}'));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }
}
