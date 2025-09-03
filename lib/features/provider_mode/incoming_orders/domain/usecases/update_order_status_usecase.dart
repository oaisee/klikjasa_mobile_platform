import 'package:dartz/dartz.dart' hide Order;
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';
import 'package:equatable/equatable.dart';

class UpdateOrderStatusUseCase implements UseCase<Order, UpdateOrderStatusParams> {
  final OrderRepository repository;

  UpdateOrderStatusUseCase(this.repository);

  @override
  Future<Either<Failure, Order>> call(UpdateOrderStatusParams params) async {
    return repository.updateOrderStatus(
      orderId: params.orderId,
      newStatus: params.newStatus,
      providerNotes: params.providerNotes,
      cancellationReason: params.cancellationReason,
    );
  }
}

class UpdateOrderStatusParams extends Equatable {
  final String orderId;
  final OrderStatus newStatus;
  final String? providerNotes;
  final String? cancellationReason; // Digunakan jika statusnya cancelled/rejected

  const UpdateOrderStatusParams({
    required this.orderId,
    required this.newStatus,
    this.providerNotes,
    this.cancellationReason,
  });

  @override
  List<Object?> get props => [orderId, newStatus, providerNotes, cancellationReason];
}
