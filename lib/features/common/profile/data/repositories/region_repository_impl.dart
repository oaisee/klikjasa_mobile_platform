// lib/features/common/profile/data/repositories/region_repository_impl.dart
import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart'; // Path yang benar
import '../../../../../core/error/exceptions.dart'; // Path yang benar
import '../../domain/entities/provinsi.dart';
import '../../domain/entities/kabupaten_kota.dart';
import '../../domain/entities/kecamatan.dart';
import '../../domain/entities/desa_kelurahan.dart';
import '../../domain/repositories/region_repository.dart';
import '../datasources/region_remote_data_source.dart'; // Sesuaikan path jika perlu

class RegionRepositoryImpl implements RegionRepository {
  final RegionRemoteDataSource remoteDataSource;
  // final NetworkInfo networkInfo; // Opsional, untuk cek koneksi internet

  RegionRepositoryImpl({
    required this.remoteDataSource,
    // required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Provinsi>>> getProvinces() async {
    // if (await networkInfo.isConnected) { // Opsional: Cek koneksi
    try {
      final remoteProvinces = await remoteDataSource.getProvinces();
      return Right(remoteProvinces);
    } on ServerException { // Tangkap ServerException dari data source jika ada
      return Left(ServerFailure(message: 'Gagal memuat provinsi')); // Kembalikan ServerFailure
    } catch (e) { // Tangkap error umum lainnya
      return Left(ServerFailure(message: 'Terjadi kesalahan tidak dikenal: ${e.toString()}'));
    }
    // } else {
    //   return Left(NetworkFailure()); // Jika tidak ada koneksi
    // }
  }

  @override
  Future<Either<Failure, List<KabupatenKota>>> getKabupatenKota(String provinceId) async {
    try {
      final remoteKabupatenKota = await remoteDataSource.getKabupatenKota(provinceId);
      return Right(remoteKabupatenKota);
    } on ServerException {
      return Left(ServerFailure(message: 'Gagal memuat kabupaten/kota'));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal memuat kabupaten/kota: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Kecamatan>>> getKecamatan(String kabupatenKotaId) async {
    try {
      final remoteKecamatan = await remoteDataSource.getKecamatan(kabupatenKotaId);
      return Right(remoteKecamatan);
    } on ServerException {
      return Left(ServerFailure(message: 'Gagal memuat kecamatan'));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal memuat kecamatan: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<DesaKelurahan>>> getDesaKelurahan(String kecamatanId) async {
    try {
      final remoteDesaKelurahan = await remoteDataSource.getDesaKelurahan(kecamatanId);
      return Right(remoteDesaKelurahan);
    } on ServerException {
      return Left(ServerFailure(message: 'Gagal memuat desa/kelurahan'));
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal memuat desa/kelurahan: ${e.toString()}'));
    }
  }
}
