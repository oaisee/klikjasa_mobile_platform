// lib/features/common/profile/domain/usecases/get_desa_kelurahan_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/profile/domain/repositories/region_repository.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/desa_kelurahan.dart';
import 'package:logger/logger.dart';

class GetDesaKelurahanUseCase {
  final RegionRepository repository;
  final Logger _logger = Logger();

  GetDesaKelurahanUseCase(this.repository);

  Future<Either<Failure, List<DesaKelurahan>>> call(String kecamatanId) async {
    _logger.d('GetDesaKelurahanUseCase called with kecamatanId: $kecamatanId');
    try {
      final result = await repository.getDesaKelurahan(kecamatanId);
      return result;
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal mengambil data desa/kelurahan: ${e.toString()}'));
    }
  }
}
