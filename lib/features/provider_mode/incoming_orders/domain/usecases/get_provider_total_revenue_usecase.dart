import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/domain/repositories/order_repository.dart';

class GetProviderTotalRevenueUseCase implements UseCase<double, GetProviderTotalRevenueParams> {
  final OrderRepository repository;

  GetProviderTotalRevenueUseCase(this.repository);

  @override
  Future<Either<Failure, double>> call(GetProviderTotalRevenueParams params) async {
    return repository.getProviderTotalCompletedRevenue(params.providerId);
  }
}

class GetProviderTotalRevenueParams extends Equatable {
  final String providerId;

  const GetProviderTotalRevenueParams({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}
