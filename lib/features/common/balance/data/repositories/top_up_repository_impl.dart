import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/top_up_history_remote_data_source.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/user_balance_remote_data_source.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/top_up_history_entity.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/top_up_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TopUpRepositoryImpl implements TopUpRepository {
  final TopUpHistoryRemoteDataSource topUpHistoryDataSource;
  final UserBalanceRemoteDataSource userBalanceDataSource;
  final SupabaseClient supabaseClient;

  TopUpRepositoryImpl({
    required this.topUpHistoryDataSource,
    required this.userBalanceDataSource,
    required this.supabaseClient,
  });

  @override
  Future<TopUpHistoryEntity> createTopUp(
    String userId,
    double amount,
    String description, {
    String? paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? externalTransactionId,
  }) async {
    try {
      logger.i('TopUpRepository: Membuat top up untuk user $userId sebesar $amount');
      
      // Buat entri di top_up_history dengan status PENDING
      final topUpHistory = await topUpHistoryDataSource.createTopUpHistory(
        userId,
        amount,
        description,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        externalTransactionId: externalTransactionId,
      );
      
      logger.i('TopUpRepository: Berhasil membuat top up dengan ID ${topUpHistory.id}');
      
      return topUpHistory;
    } catch (e) {
      logger.e('TopUpRepository: Error saat membuat top up: $e');
      throw Exception('Terjadi kesalahan saat membuat top up: $e');
    }
  }

  @override
  Future<TopUpHistoryEntity> getTopUpById(int id) async {
    try {
      logger.i('TopUpRepository: Mengambil top up dengan ID $id');
      
      final topUpHistory = await topUpHistoryDataSource.getTopUpHistoryById(id);
      
      logger.i('TopUpRepository: Berhasil mengambil top up dengan ID $id');
      
      return topUpHistory;
    } catch (e) {
      logger.e('TopUpRepository: Error saat mengambil top up: $e');
      throw Exception('Terjadi kesalahan saat mengambil top up: $e');
    }
  }

  @override
  Future<List<TopUpHistoryEntity>> getTopUpHistoryByUserId(String userId) async {
    try {
      logger.i('TopUpRepository: Mengambil histori top up untuk user $userId');
      
      final topUpHistoryList = await topUpHistoryDataSource.getTopUpHistoryByUserId(userId);
      
      logger.i('TopUpRepository: Berhasil mengambil ${topUpHistoryList.length} histori top up untuk user $userId');
      
      return topUpHistoryList;
    } catch (e) {
      logger.e('TopUpRepository: Error saat mengambil histori top up: $e');
      throw Exception('Terjadi kesalahan saat mengambil histori top up: $e');
    }
  }

  @override
  Future<bool> processSuccessfulTopUp(
    int topUpId, {
    String? externalTransactionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      logger.i('TopUpRepository: Memproses top up yang berhasil dengan ID $topUpId');
      
      // 1. Ambil data top up history
      final topUpHistory = await topUpHistoryDataSource.getTopUpHistoryById(topUpId);
      
      // 2. Update status menjadi COMPLETED
      await topUpHistoryDataSource.updateTopUpHistoryStatus(
        topUpId,
        TopUpStatus.completed,
        externalTransactionId: externalTransactionId,
        paymentDetails: paymentDetails,
      );
      
      // 3. Buat entri di tabel transactions
      await supabaseClient.from('transactions').insert({
        'user_id': topUpHistory.userId,
        'transaction_type': 'top_up',
        'amount': topUpHistory.amount,
        'description': 'Top up: ${topUpHistory.description ?? ""}',
        'status': 'completed',
        'transaction_date': DateTime.now().toIso8601String(),
        'metadata': {
          'top_up_id': topUpId,
          'payment_method': topUpHistory.paymentMethod,
          'external_transaction_id': externalTransactionId ?? topUpHistory.externalTransactionId,
        },
      });
      
      logger.i('TopUpRepository: Berhasil memproses top up yang berhasil dengan ID $topUpId');
      
      return true;
    } catch (e) {
      logger.e('TopUpRepository: Error saat memproses top up yang berhasil: $e');
      throw Exception('Terjadi kesalahan saat memproses top up yang berhasil: $e');
    }
  }

  @override
  Future<bool> markTopUpAsFailed(
    int topUpId, {
    String? reason,
    String? externalTransactionId,
  }) async {
    try {
      logger.i('TopUpRepository: Menandai top up dengan ID $topUpId sebagai gagal');
      
      // Update status menjadi FAILED
      await topUpHistoryDataSource.updateTopUpHistoryStatus(
        topUpId,
        TopUpStatus.failed,
        externalTransactionId: externalTransactionId,
        paymentDetails: reason != null ? {'failure_reason': reason} : null,
      );
      
      logger.i('TopUpRepository: Berhasil menandai top up dengan ID $topUpId sebagai gagal');
      
      return true;
    } catch (e) {
      logger.e('TopUpRepository: Error saat menandai top up sebagai gagal: $e');
      throw Exception('Terjadi kesalahan saat menandai top up sebagai gagal: $e');
    }
  }
}
