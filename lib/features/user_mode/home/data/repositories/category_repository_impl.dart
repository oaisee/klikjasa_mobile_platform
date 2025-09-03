import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/features/user_mode/home/data/datasources/category_remote_data_source.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/category_repository.dart';

/// Implementasi repository untuk kategori layanan
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  CategoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<ServiceCategory>>> getActiveCategories() async {
    if (await networkInfo.isConnected) {
      try {
        final categories = await remoteDataSource.getActiveCategories();
        return Right(categories);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }

  @override
  Future<Either<Failure, ServiceCategory>> getCategoryById(int id) async {
    if (await networkInfo.isConnected) {
      try {
        final category = await remoteDataSource.getCategoryById(id);
        return Right(category);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }
}
