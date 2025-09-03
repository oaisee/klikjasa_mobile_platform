part of 'incoming_orders_bloc.dart';

abstract class IncomingOrdersState extends Equatable {
  const IncomingOrdersState();

  @override
  List<Object?> get props => [];
}

class IncomingOrdersInitial extends IncomingOrdersState {}

class IncomingOrdersLoading extends IncomingOrdersState {}

class IncomingOrdersLoaded extends IncomingOrdersState {
  final List<Order> orders;

  const IncomingOrdersLoaded({required this.orders});

  @override
  List<Object> get props => [orders];
}

class IncomingOrdersError extends IncomingOrdersState {
  final String message;

  const IncomingOrdersError({required this.message});

  @override
  List<Object> get props => [message];
}

// States untuk aksi terima pesanan
class IncomingOrderAcceptLoading extends IncomingOrdersState {
  final String orderId;
  const IncomingOrderAcceptLoading({required this.orderId});
  @override
  List<Object> get props => [orderId];
}

class IncomingOrderAcceptSuccess extends IncomingOrdersState {
  final Order order; // Order yang telah diupdate
  const IncomingOrderAcceptSuccess({required this.order});
  @override
  List<Object> get props => [order];
}

class IncomingOrderAcceptFailure extends IncomingOrdersState {
  final String orderId;
  final String message;
  const IncomingOrderAcceptFailure({required this.orderId, required this.message});
  @override
  List<Object> get props => [orderId, message];
}

// States untuk aksi tolak pesanan
class IncomingOrderDeclineLoading extends IncomingOrdersState {
  final String orderId;
  const IncomingOrderDeclineLoading({required this.orderId});
  @override
  List<Object> get props => [orderId];
}

class IncomingOrderDeclineSuccess extends IncomingOrdersState {
  final Order order; // Order yang telah diupdate
  const IncomingOrderDeclineSuccess({required this.order});
  @override
  List<Object> get props => [order];
}

class IncomingOrderDeclineFailure extends IncomingOrdersState {
  final String orderId;
  final String message;
  const IncomingOrderDeclineFailure({required this.orderId, required this.message});
  @override
  List<Object> get props => [orderId, message];
}
