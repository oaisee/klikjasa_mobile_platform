import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/domain/entities/service.dart';
import 'package:klik_jasa/core/error/failures.dart';

// Abstract class untuk repository layanan provider.
// Mendefinisikan kontrak untuk operasi terkait data layanan yang disediakan oleh provider.
abstract class ServiceProviderRepository {
  // Mengambil daftar layanan yang dimiliki oleh seorang provider berdasarkan ID provider.
  Future<Either<Failure, List<Service>>> getProviderServices(
    String providerId, {
    bool? isActive,
  });

  // Menambahkan layanan baru untuk provider.
  Future<Either<Failure, Service>> addService(Service service);

  // Memperbarui layanan yang sudah ada.
  Future<Either<Failure, Service>> updateService(Service service);

  // Menghapus layanan berdasarkan ID layanan.
  Future<Either<Failure, void>> deleteService(String serviceId);

  // Mengambil detail satu layanan berdasarkan ID-nya.
  Future<Either<Failure, Service>> getServiceDetail(String serviceId);

  // Memperbarui status promosi layanan.
  Future<Either<Failure, Service>> updateServicePromotion({
    required String serviceId,
    required bool isPromoted,
    DateTime? promotionStartDate,
    DateTime? promotionEndDate,
  });
}
