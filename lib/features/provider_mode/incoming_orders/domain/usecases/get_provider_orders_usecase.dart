import 'package:dartz/dartz.dart' hide Order;
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';

class GetProviderOrdersUseCase implements UseCase<List<Order>, GetProviderOrdersParams> {
  final OrderRepository repository;

  GetProviderOrdersUseCase(this.repository);

  @override
  Future<Either<Failure, List<Order>>> call(GetProviderOrdersParams params) async {
    // Mengonversi status dari String ke Enum OrderStatus menggunakan parseOrderStatus
    final statusEnum = parseOrderStatus(params.status);
    return repository.getProviderOrders(params.providerId, status: statusEnum);
  }
}

class GetProviderOrdersParams extends Equatable {
  final String providerId;
  final String status;

  const GetProviderOrdersParams({required this.providerId, required this.status});

  @override
  List<Object?> get props => [providerId, status];
}
