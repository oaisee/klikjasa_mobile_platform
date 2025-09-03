import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

/// Use case untuk memperbarui layanan yang sudah ada.
/// Mengimplementasikan [UseCase] dengan parameter [UpdateLayananParams] dan
/// mengembalikan [Either<Failure, void>].
class UpdateLayananUseCase implements UseCase<void, UpdateLayananParams> {
  final ServiceProviderRepository repository;

  UpdateLayananUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateLayananParams params) async {
    final result = await repository.updateService(params.service);
    return result.fold(
      (failure) => Left(failure),
      (service) => const Right(null),
    );
  }
}

/// Parameter untuk [UpdateLayananUseCase].
/// Berisi entitas [Service] dengan data yang diperbarui.
class UpdateLayananParams extends Equatable {
  final Service service;

  const UpdateLayananParams({
    required this.service,
  });

  @override
  List<Object> get props => [service];
}