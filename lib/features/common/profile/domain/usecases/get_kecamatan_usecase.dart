// lib/features/common/profile/domain/usecases/get_kecamatan_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/kecamatan.dart';
import 'package:klik_jasa/features/common/profile/domain/repositories/region_repository.dart';
import 'package:logger/logger.dart';

class GetKecamatanUseCase {
  final RegionRepository repository;
  final Logger _logger = Logger();

  GetKecamatanUseCase(this.repository);

  Future<Either<Failure, List<Kecamatan>>> call(String kabupatenKotaId) async {
    _logger.d('GetKecamatanUseCase called with kabupatenKotaId: $kabupatenKotaId');
    try {
      final result = await repository.getKecamatan(kabupatenKotaId);
      return result;
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal mengambil data kecamatan: ${e.toString()}'));
    }
  }
}
