import 'package:klik_jasa/features/admin_mode/domain/entities/admin_dashboard_stats.dart';

abstract class AdminDashboardRepository {
  Future<AdminDashboardStats> getDashboardStats();
  
  /// Mengambil data statistik pengguna dan penyedia jasa berdasarkan periode
  /// 
  /// [period] bisa berupa 'Minggu', 'Bulan', atau 'Tahun'
  /// 
  /// Mengembalikan Map dengan struktur:
  /// {
  ///   'labels': List\<String\> label untuk sumbu X (hari/bulan/tahun),
  ///   'userData': Map\<String, int\> jumlah pengguna per label,
  ///   'providerData': Map\<String, int\> jumlah penyedia jasa per label
  /// }
  Future<Map<String, dynamic>> getUserProviderStatsByPeriod(String period);
  
  /// Mengambil data histori transaksi berdasarkan periode
  /// 
  /// [period] bisa berupa 'Minggu', 'Bulan', atau 'Tahun'
  /// 
  /// Mengembalikan Map dengan struktur:
  /// {
  ///   'labels': List\<String\> label untuk sumbu X (hari/bulan/tahun),
  ///   'completedOrdersData': Map\<String, int\> jumlah transaksi selesai per label,
  ///   'inProgressOrdersData': Map\<String, int\> jumlah transaksi dalam proses per label
  /// }
  Future<Map<String, dynamic>> getOrderHistoryByPeriod(String period);
}
