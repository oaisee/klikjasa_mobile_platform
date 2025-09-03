import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';
import 'package:klik_jasa/features/user_mode/home/domain/usecases/get_promoted_services.dart';

class GetServicesByHighestRating implements UseCase<List<ServiceWithLocation>, PaginationParams> {
  final ServiceRepository repository;

  GetServicesByHighestRating(this.repository);

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> call(PaginationParams params) {
    return repository.getServicesByHighestRating(
      limit: params.limit,
      offset: params.offset,
    );
  }
}
