import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/service_repository.dart';

class GetServicesByLocation implements UseCase<List<ServiceWithLocation>, ServiceLocationParams> {
  final ServiceRepository repository;

  GetServicesByLocation(this.repository);

  @override
  Future<Either<Failure, List<ServiceWithLocation>>> call(ServiceLocationParams params) {
    return repository.getServicesByLocation(
      userProvinsi: params.userProvinsi,
      userKabupatenKota: params.userKabupatenKota,
      userKecamatan: params.userKecamatan,
      userDesaKelurahan: params.userDesaKelurahan,
      limit: params.limit,
      offset: params.offset,
    );
  }
}

class ServiceLocationParams extends Equatable {
  final String? userProvinsi;
  final String? userKabupatenKota;
  final String? userKecamatan;
  final String? userDesaKelurahan;
  final int limit;
  final int offset;

  const ServiceLocationParams({
    this.userProvinsi,
    this.userKabupatenKota,
    this.userKecamatan,
    this.userDesaKelurahan,
    this.limit = 10,
    this.offset = 0,
  });

  @override
  List<Object?> get props => [
        userProvinsi,
        userKabupatenKota,
        userKecamatan,
        userDesaKelurahan,
        limit,
        offset,
      ];
}
