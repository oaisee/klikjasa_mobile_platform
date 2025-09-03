part of 'balance_bloc.dart';

abstract class BalanceEvent extends Equatable {
  const BalanceEvent();

  @override
  List<Object> get props => [];
}

class FetchBalanceEvent extends BalanceEvent {
  final String userId;

  const FetchBalanceEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}
