import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';

class GetProviderActiveOrdersCountUseCase implements UseCase<int, GetProviderActiveOrdersCountParams> {
  final OrderRepository repository;

  GetProviderActiveOrdersCountUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(GetProviderActiveOrdersCountParams params) async {
    return repository.getProviderActiveOrdersCount(params.providerId);
  }
}

class GetProviderActiveOrdersCountParams extends Equatable {
  final String providerId;

  const GetProviderActiveOrdersCountParams({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}
