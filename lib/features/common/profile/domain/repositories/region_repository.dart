// lib/features/common/profile/domain/repositories/region_repository.dart
import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/desa_kelurahan.dart';
import '../entities/kabupaten_kota.dart';
import '../entities/kecamatan.dart';
import '../entities/provinsi.dart';

// Abstract class sebagai kontrak
abstract class RegionRepository {
  Future<Either<Failure, List<Provinsi>>> getProvinces();
  Future<Either<Failure, List<KabupatenKota>>> getKabupatenKota(String provinceId);
  Future<Either<Failure, List<Kecamatan>>> getKecamatan(String kabupatenKotaId);
  Future<Either<Failure, List<DesaKelurahan>>> getDesaKelurahan(String kecamatanId);
}

