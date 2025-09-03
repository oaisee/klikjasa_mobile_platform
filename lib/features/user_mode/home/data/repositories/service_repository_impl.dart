import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/user_mode/home/data/datasources/service_data_source.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceDataSource dataSource;

  ServiceRepositoryImpl({required this.dataSource});
  
  @override
  void dispose() {
    dataSource.disposeSubscriptions();
  }

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> getServicesByLocation({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final services = await dataSource.getServicesByLocation(
        userProvinsi: userProvinsi,
        userKabupatenKota: userKabupatenKota,
        userKecamatan: userKecamatan,
        userDesaKelurahan: userDesaKelurahan,
        limit: limit,
        offset: offset,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> getPromotedServices({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final services = await dataSource.getPromotedServices(
        limit: limit,
        offset: offset,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> getServicesByHighestRating({
    int limit = 10,
    int offset = 0,
  }) async {
    try {
      final services = await dataSource.getServicesByHighestRating(
        limit: limit,
        offset: offset,
      );
      return Right(services);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, ServiceWithLocation>> getServiceById(int serviceId) async {
    try {
      final service = await dataSource.getServiceById(serviceId);
      return Right(service);
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(message: e.message, code: e.code, details: e.details));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code, details: e.details));
    }
  }
  
  @override
  Stream<Either<Failure, List<ServiceWithLocation>>> getServicesByLocationStream({
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
  }) {
    try {
      return dataSource.getServicesByLocationStream(
        userProvinsi: userProvinsi,
        userKabupatenKota: userKabupatenKota,
        userKecamatan: userKecamatan,
        userDesaKelurahan: userDesaKelurahan,
      ).map<Either<Failure, List<ServiceWithLocation>>>((services) => Right(services))
      .handleError((error) {
        debugPrint('Error in getServicesByLocationStream: $error');
        if (error is ServerException) {
          return Left(ServerFailure(message: error.message));
        }
        return Left(ServerFailure(message: error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(message: e.toString())));
    }
  }
  
  @override
  Stream<Either<Failure, List<ServiceWithLocation>>> getPromotedServicesStream() {
    try {
      return dataSource.getPromotedServicesStream()
        .map<Either<Failure, List<ServiceWithLocation>>>((services) => Right(services))
        .handleError((error) {
          debugPrint('Error in getPromotedServicesStream: $error');
          if (error is ServerException) {
            return Left(ServerFailure(message: error.message));
          }
          return Left(ServerFailure(message: error.toString()));
        });
    } catch (e) {
      return Stream.value(Left(ServerFailure(message: e.toString())));
    }
  }
  
  @override
  Stream<Either<Failure, List<ServiceWithLocation>>> getServicesByHighestRatingStream() {
    try {
      return dataSource.getServicesByHighestRatingStream()
        .map<Either<Failure, List<ServiceWithLocation>>>((services) => Right(services))
        .handleError((error) {
          debugPrint('Error in getServicesByHighestRatingStream: $error');
          if (error is ServerException) {
            return Left(ServerFailure(message: error.message));
          }
          return Left(ServerFailure(message: error.toString()));
        });
    } catch (e) {
      return Stream.value(Left(ServerFailure(message: e.toString())));
    }
  }
}
