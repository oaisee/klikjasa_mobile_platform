import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/repositories/provider_summary_repository.dart';
import 'package:klik_jasa/features/provider_mode/dashboard/domain/entities/provider_summary_data_entity.dart';

class WatchProviderSummaryDataUseCase implements StreamUseCase<ProviderSummaryDataEntity, GetProviderSummaryDataParams> {
  final ProviderSummaryRepository _repository;

  WatchProviderSummaryDataUseCase(this._repository);

  @override
  Stream<Either<Failure, ProviderSummaryDataEntity>> call(GetProviderSummaryDataParams params) {
    if (params.providerId.isEmpty) {
      return Stream.value(Left(ServerFailure(message: 'Provider ID tidak boleh kosong')));
    }
    
    return _repository.watchProviderSummaryData(params.providerId);
  }
}

class GetProviderSummaryDataParams extends Equatable {
  final String providerId;

  const GetProviderSummaryDataParams({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}