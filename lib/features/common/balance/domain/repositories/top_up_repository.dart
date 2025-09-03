import 'package:klik_jasa/features/common/balance/domain/entities/top_up_history_entity.dart';

abstract class TopUpRepository {
  /// Membuat entri top up baru dengan status PENDING
  Future<TopUpHistoryEntity> createTopUp(
    String userId,
    double amount,
    String description, {
    String? paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? externalTransactionId,
  });
  
  /// Mengambil histori top up berdasarkan ID
  Future<TopUpHistoryEntity> getTopUpById(int id);
  
  /// Mengambil semua histori top up untuk user tertentu
  Future<List<TopUpHistoryEntity>> getTopUpHistoryByUserId(String userId);
  
  /// Memproses top up yang berhasil (mengubah status menjadi COMPLETED dan mencatat di transactions)
  Future<bool> processSuccessfulTopUp(
    int topUpId, {
    String? externalTransactionId,
    Map<String, dynamic>? paymentDetails,
  });
  
  /// Menandai top up sebagai gagal
  Future<bool> markTopUpAsFailed(
    int topUpId, {
    String? reason,
    String? externalTransactionId,
  });
}
