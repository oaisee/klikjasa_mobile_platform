part of 'incoming_orders_bloc.dart';

abstract class IncomingOrdersEvent extends Equatable {
  const IncomingOrdersEvent();

  @override
  List<Object?> get props => [];
}

class FetchIncomingOrders extends IncomingOrdersEvent {
  final String providerId;

  const FetchIncomingOrders({required this.providerId});

  @override
  List<Object> get props => [providerId];
}

class AcceptIncomingOrder extends IncomingOrdersEvent {
  final String orderId;
  final String providerId; // Dibutuhkan untuk refresh list
  final String? notes;

  const AcceptIncomingOrder({required this.orderId, required this.providerId, this.notes});

  @override
  List<Object?> get props => [orderId, providerId, notes];
}

class DeclineIncomingOrder extends IncomingOrdersEvent {
  final String orderId;
  final String providerId; // Dibutuhkan untuk refresh list
  final String reason;

  const DeclineIncomingOrder({required this.orderId, required this.providerId, required this.reason});

  @override
  List<Object?> get props => [orderId, providerId, reason];
}
