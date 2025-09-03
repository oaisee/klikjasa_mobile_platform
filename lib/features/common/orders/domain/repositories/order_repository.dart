import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';

abstract class OrderRepository {
  /// Update status pesanan
  Future<Either<Failure, void>> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
    String? cancellationReason,
  });
  
  /// Mendapatkan detail pesanan berdasarkan ID
  Future<Either<Failure, Map<String, dynamic>>> getOrderDetail(int orderId);
  
  /// Mendapatkan daftar pesanan untuk user
  Future<Either<Failure, List<Map<String, dynamic>>>> getUserOrders(String userId);
  
  /// Mendapatkan daftar pesanan untuk provider
  Future<Either<Failure, List<Map<String, dynamic>>>> getProviderOrders(String providerId);
}
