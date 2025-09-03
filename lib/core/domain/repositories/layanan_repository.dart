import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/domain/entities/layanan.dart';
import 'package:klik_jasa/core/error/failures.dart';

abstract class LayananRepositoryInterface {
  Future<Either<Failure, List<Layanan>>> getLayananList(
      {String? kategoriId, String? penyediaId, bool? isActive, int page = 1, int limit = 20});

  Future<Either<Failure, Layanan>> getLayananDetail(String id);

  Future<Either<Failure, Layanan>> createLayanan(Layanan layanan); // Admin atau Penyedia (untuk dirinya)

  Future<Either<Failure, Layanan>> updateLayanan(Layanan layanan); // Admin atau Penyedia (miliknya)
  
  Future<Either<Failure, void>> deleteLayanan(String id); // Admin atau Penyedia (miliknya)
}
