import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

/// Use case untuk mengambil detail satu layanan berdasarkan ID-nya.
/// Mengimplementasikan [UseCase] dengan parameter [GetLayananDetailParams] dan
/// mengembalikan [Either<Failure, Service>].
class GetLayananDetailUseCase implements UseCase<Service, GetLayananDetailParams> {
  final ServiceProviderRepository repository;

  GetLayananDetailUseCase(this.repository);

  @override
  Future<Either<Failure, Service>> call(GetLayananDetailParams params) async {
    return repository.getServiceDetail(params.layananId);
  }
}

/// Parameter untuk [GetLayananDetailUseCase].
/// Berisi ID layanan yang detailnya ingin diambil.
class GetLayananDetailParams extends Equatable {
  final String layananId;

  const GetLayananDetailParams({
    required this.layananId,
  });

  @override
  List<Object> get props => [layananId];
}