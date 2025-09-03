part of 'balance_bloc.dart';

abstract class BalanceState extends Equatable {
  const BalanceState();

  @override
  List<Object> get props => [];
}

class BalanceInitial extends BalanceState {}

class BalanceLoading extends BalanceState {}

class BalanceLoaded extends BalanceState {
  final UserBalanceEntity userBalance;

  const BalanceLoaded({required this.userBalance});

  @override
  List<Object> get props => [userBalance];
}

class BalanceError extends BalanceState {
  final String message;

  const BalanceError({required this.message});

  @override
  List<Object> get props => [message];
}
