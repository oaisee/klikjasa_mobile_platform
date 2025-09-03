import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

/// Use case untuk menambahkan layanan baru untuk provider.
/// Mengimplementasikan [UseCase] dengan parameter [AddLayananParams] dan
/// mengembalikan [Either<Failure, void>].
class AddLayananUseCase implements UseCase<void, AddLayananParams> {
  final ServiceProviderRepository repository;

  AddLayananUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddLayananParams params) async {
    final result = await repository.addService(params.service);
    return result.fold(
      (failure) => Left(failure),
      (service) => const Right(null),
    );
  }
}

/// Parameter untuk [AddLayananUseCase].
/// Berisi entitas [Service] yang akan ditambahkan.
class AddLayananParams extends Equatable {
  final Service service;

  const AddLayananParams({
    required this.service,
  });

  @override
  List<Object> get props => [service];
}