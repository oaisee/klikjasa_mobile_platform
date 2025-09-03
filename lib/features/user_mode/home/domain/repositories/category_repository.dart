import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';

/// Repository untuk mengakses data kategori layanan
abstract class CategoryRepository {
  /// Mengambil semua kategori layanan yang aktif
  Future<Either<Failure, List<ServiceCategory>>> getActiveCategories();
  
  /// Mengambil kategori layanan berdasarkan ID
  Future<Either<Failure, ServiceCategory>> getCategoryById(int id);
}
