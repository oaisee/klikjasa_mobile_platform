import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

/// Use case untuk mengambil daftar layanan yang dimiliki oleh seorang provider.
/// Mengimplementasikan [UseCase] dengan parameter [GetProviderLayananParams] dan
/// mengembalikan [Either<Failure, List<Service>>].
class GetProviderLayananUseCase implements UseCase<List<Service>, GetProviderLayananParams> {
  final ServiceProviderRepository repository;

  GetProviderLayananUseCase(this.repository);

  @override
  Future<Either<Failure, List<Service>>> call(GetProviderLayananParams params) async {
    return repository.getProviderServices(params.providerId, isActive: params.isActive);
  }
}

/// Parameter untuk [GetProviderLayananUseCase].
/// Berisi ID provider dan flag opsional untuk memfilter layanan berdasarkan status aktif.
class GetProviderLayananParams extends Equatable {
  final String providerId;
  final bool? isActive;

  const GetProviderLayananParams({
    required this.providerId,
    this.isActive,
  });

  @override
  List<Object?> get props => [providerId, isActive];
}