import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/features/common/orders/data/datasources/order_remote_data_source.dart';
import 'package:klik_jasa/features/common/orders/domain/repositories/order_repository.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  OrderRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, void>> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
    String? cancellationReason,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await remoteDataSource.updateOrderStatus(
          orderId: orderId,
          status: status,
          notes: notes,
          cancellationReason: cancellationReason,
        );
        return const Right(null);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getOrderDetail(int orderId) async {
    if (await networkInfo.isConnected) {
      try {
        final orderDetail = await remoteDataSource.getOrderDetail(orderId);
        return Right(orderDetail);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserOrders(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final orders = await remoteDataSource.getUserOrders(userId);
        return Right(orders);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getProviderOrders(String providerId) async {
    if (await networkInfo.isConnected) {
      try {
        final orders = await remoteDataSource.getProviderOrders(providerId);
        return Right(orders);
      } on ServerException catch (e) {
        return Left(ServerFailure(message: e.message));
      }
    } else {
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }
}
