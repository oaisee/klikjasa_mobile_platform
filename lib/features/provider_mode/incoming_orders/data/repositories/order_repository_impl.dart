import 'package:dartz/dartz.dart' hide Order;
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/datasources/order_remote_data_source.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';
class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource remoteDataSource;

  OrderRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Order>>> getProviderOrders(String providerId, {OrderStatus? status}) async {
    try {
      logger.i('Repository: Mengambil pesanan provider $providerId dengan status ${status?.toString() ?? 'semua'}');
      // remoteDataSource.getProviderOrders sekarang seharusnya mengembalikan List<Order> secara langsung
      // berdasarkan perbaikan sebelumnya di OrderRemoteDataSourceImpl
      final List<Order> orders = await remoteDataSource.getProviderOrders(providerId, status: status);
      logger.i('Repository: Berhasil mengambil ${orders.length} pesanan');
      return Right(orders);
    } catch (e) {
      logger.e('Repository: Error saat mengambil pesanan provider: $e');
      return Left(NetworkFailure(message: 'Gagal memuat pesanan provider: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getProviderTotalCompletedRevenue(String providerId) async {
    try {
      logger.i('Repository: Mengambil total pendapatan provider $providerId');
      final double totalRevenue = await remoteDataSource.getProviderTotalCompletedRevenue(providerId);
      logger.i('Repository: Total pendapatan: $totalRevenue');
      return Right(totalRevenue);
    } catch (e) {
      logger.e('Repository: Error saat mengambil total pendapatan: $e');
      return Left(NetworkFailure(message: 'Gagal memuat total pendapatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, int>> getProviderActiveOrdersCount(String providerId) async {
    try {
      logger.i('Repository: Menghitung jumlah pesanan aktif provider $providerId');
      final int activeOrdersCount = await remoteDataSource.getProviderActiveOrdersCount(providerId);
      logger.i('Repository: Jumlah pesanan aktif: $activeOrdersCount');
      return Right(activeOrdersCount);
    } catch (e) {
      logger.e('Repository: Error saat menghitung jumlah pesanan aktif: $e');
      return Left(NetworkFailure(message: 'Gagal memuat jumlah pesanan aktif: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? providerNotes,
    String? cancellationReason,
  }) async {
    try {
      logger.i('Repository: Memperbarui status pesanan $orderId menjadi ${newStatus.toString()}');
      final updatedOrder = await remoteDataSource.updateOrderStatus(
        orderId: orderId,
        newStatus: newStatus,
        providerNotes: providerNotes,
        cancellationReason: cancellationReason,
      );
      logger.i('Repository: Berhasil memperbarui status pesanan $orderId');
      return Right(updatedOrder);
    } catch (e) {
      logger.e('Repository: Error saat memperbarui status pesanan: $e');
      return Left(NetworkFailure(message: 'Gagal memperbarui status pesanan: ${e.toString()}'));
    }
  }
} // Implementasi metode lain dari OrderRepository akan ada di sini
