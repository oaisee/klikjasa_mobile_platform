import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';

class GetPromotedServices implements UseCase<List<ServiceWithLocation>, PaginationParams> {
  final ServiceRepository repository;

  GetPromotedServices(this.repository);

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> call(PaginationParams params) {
    return repository.getPromotedServices(
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class PaginationParams extends Equatable {
  final int limit;
  final int offset;

  const PaginationParams({
    this.limit = 10,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [limit, offset];
}
