part of 'provider_orders_bloc.dart';

sealed class ProviderOrdersEvent extends Equatable {
  const ProviderOrdersEvent();

  @override
  List<Object> get props => [];
}

// Event untuk memuat semua pesanan provider untuk semua status
class FetchAllProviderOrders extends ProviderOrdersEvent {
  final String providerId;

  const FetchAllProviderOrders({required this.providerId});

  @override
  List<Object> get props => [providerId];
}

// Event untuk memperbarui status sebuah pesanan
class UpdateOrderStatus extends ProviderOrdersEvent {
  final int orderId;
  final String newStatus;
  final String providerId;

  const UpdateOrderStatus({
    required this.orderId,
    required this.newStatus,
    required this.providerId,
  });

  @override
  List<Object> get props => [orderId, newStatus, providerId];
}
