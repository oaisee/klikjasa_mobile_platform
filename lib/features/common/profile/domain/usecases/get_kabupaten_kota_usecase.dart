// lib/features/common/profile/domain/usecases/get_kabupaten_kota_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/profile/domain/repositories/region_repository.dart';
import 'package:klik_jasa/features/common/profile/domain/entities/kabupaten_kota.dart';
import 'package:logger/logger.dart';

class GetKabupatenKotaUseCase {
  final RegionRepository repository;
  final Logger _logger = Logger();

  GetKabupatenKotaUseCase(this.repository);

  Future<Either<Failure, List<KabupatenKota>>> call(String provinceId) async {
    _logger.d('GetKabupatenKotaUseCase called with provinceId: $provinceId');
    // return await repository.getKabupatenKota(provinceId);
    // Kode di atas adalah yang benar, namun untuk sementara kita pakai try-catch
    // untuk memastikan error handling yang lebih baik jika repository.getKabupatenKota
    // tidak mengembalikan Either secara langsung atau ada exception lain.
    try {
      // Pastikan repository.getKabupatenKota mengembalikan Future<Either<Failure, List<KabupatenKota>>>
      final result = await repository.getKabupatenKota(provinceId);
      return result;
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal mengambil data kabupaten/kota: ${e.toString()}'));
    }
  }
}
