import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/domain/entities/kategori_layanan.dart';
import 'package:klik_jasa/core/error/failures.dart';

abstract class KategoriLayananRepositoryInterface {
  Future<Either<Failure, List<KategoriLayanan>>> getKategoriLayananList();

  Future<Either<Failure, KategoriLayanan>> getKategoriLayananDetail(String id);

  Future<Either<Failure, KategoriLayanan>> createKategoriLayanan(KategoriLayanan kategori); // Admin

  Future<Either<Failure, KategoriLayanan>> updateKategoriLayanan(KategoriLayanan kategori); // Admin

  Future<Either<Failure, void>> deleteKategoriLayanan(String id); // Admin
}
