import 'package:dartz/dartz.dart' hide Order;
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/error/failures.dart';

abstract class OrderRepository {
  Future<Either<Failure, List<Order>>> getProviderOrders(String providerId, {OrderStatus? status});
  Future<Either<Failure, double>> getProviderTotalCompletedRevenue(String providerId);
  Future<Either<Failure, int>> getProviderActiveOrdersCount(String providerId);
  Future<Either<Failure, Order>> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? providerNotes,
    String? cancellationReason,
  });
  // Tambahkan metode lain jika diperlukan (misalnya getOrderDetail, dll.)
}
