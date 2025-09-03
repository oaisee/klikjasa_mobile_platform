import 'package:klik_jasa/features/provider_mode/services/data/models/service_model.dart';

// Abstract class untuk data source jarak jauh layanan provider.
// Mendefinisikan kontrak untuk interaksi dengan backend (misalnya Supabase)
// terkait data layanan yang disediakan oleh provider.
abstract class ServiceProviderRemoteDataSource {
  // Mengambil daftar layanan model dari provider tertentu.
  Future<List<Map<String, dynamic>>> getProviderServices(String providerId);

  // Menambahkan layanan baru.
  Future<Map<String, dynamic>> addService(ServiceModel serviceModel);

  // Memperbarui layanan yang sudah ada.
  Future<Map<String, dynamic>> updateService(ServiceModel serviceModel);

  // Menghapus layanan berdasarkan ID.
  Future<void> deleteService(String serviceId);

  // Mengambil detail satu layanan berdasarkan ID-nya.
  Future<Map<String, dynamic>> getServiceDetail(String serviceId);

  // Memperbarui status promosi layanan.
  Future<Map<String, dynamic>> updateServicePromotion({
    required String serviceId,
    required bool isPromoted,
    DateTime? promotionStartDate,
    DateTime? promotionEndDate,
  });
}
