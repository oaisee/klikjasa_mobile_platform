import 'package:dartz/dartz.dart' hide Order;
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';
import 'package:equatable/equatable.dart';

class GetIncomingOrdersUseCase {
  final OrderRepository repository;

  GetIncomingOrdersUseCase(this.repository);

  Future<Either<Failure, List<Order>>> call(GetIncomingOrdersParams params) async {
    // Mengambil pesanan dengan status 'pending_confirmation' sebagai pesanan masuk
    return repository.getProviderOrders(params.providerId, status: OrderStatus.pendingConfirmation);
  }
}

class GetIncomingOrdersParams extends Equatable {
  final String providerId;

  const GetIncomingOrdersParams({required this.providerId});

  @override
  List<Object> get props => [providerId];
}
