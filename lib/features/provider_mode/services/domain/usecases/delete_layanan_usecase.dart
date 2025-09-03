import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/provider_mode/services/domain/repositories/service_provider_repository.dart';

/// Use case untuk menghapus layanan berdasarkan ID layanan.
/// Mengimplementasikan [UseCase] dengan parameter [DeleteLayananParams] dan
/// mengembalikan [Either<Failure, void>].
class DeleteLayananUseCase implements UseCase<void, DeleteLayananParams> {
  final ServiceProviderRepository repository;

  DeleteLayananUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteLayananParams params) async {
    return repository.deleteService(params.layananId);
  }
}

/// Parameter untuk [DeleteLayananUseCase].
/// Berisi ID layanan yang akan dihapus.
class DeleteLayananParams extends Equatable {
  final String layananId;

  const DeleteLayananParams({
    required this.layananId,
  });

  @override
  List<Object> get props => [layananId];
}