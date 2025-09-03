part of 'provider_orders_bloc.dart';

abstract class ProviderOrdersState extends Equatable {
  const ProviderOrdersState();

  @override
  List<Object> get props => [];
}

class ProviderOrdersInitial extends ProviderOrdersState {}

class ProviderOrdersLoading extends ProviderOrdersState {}

class ProviderOrdersLoaded extends ProviderOrdersState {
  final Map<String, List<Order>> allOrders;

  const ProviderOrdersLoaded({required this.allOrders});

  @override
  List<Object> get props => [allOrders];

  ProviderOrdersLoaded copyWith({Map<String, List<Order>>? allOrders}) {
    return ProviderOrdersLoaded(allOrders: allOrders ?? this.allOrders);
  }
}

// State untuk menunjukkan bahwa pesanan sedang diperbarui
class ProviderOrdersUpdating extends ProviderOrdersLoaded {
  final int orderId; // ID pesanan yang sedang diperbarui

  const ProviderOrdersUpdating({
    required super.allOrders,
    required this.orderId,
  });

  @override
  List<Object> get props => [allOrders, orderId];
}

class ProviderOrdersError extends ProviderOrdersState {
  final String message;

  const ProviderOrdersError({required this.message});

  @override
  List<Object> get props => [message];
}
