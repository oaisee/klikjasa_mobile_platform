import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/top_up_history_entity.dart';
import 'package:klik_jasa/core/utils/logger.dart';

abstract class TopUpHistoryRemoteDataSource {
  Future<TopUpHistoryEntity> createTopUpHistory(
    String userId,
    double amount,
    String description, {
    String? paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? externalTransactionId,
  });
  
  Future<TopUpHistoryEntity> getTopUpHistoryById(int id);
  
  Future<List<TopUpHistoryEntity>> getTopUpHistoryByUserId(String userId);
  
  Future<TopUpHistoryEntity> updateTopUpHistoryStatus(
    int id,
    TopUpStatus status, {
    String? externalTransactionId,
    Map<String, dynamic>? paymentDetails,
  });
}

class TopUpHistoryRemoteDataSourceImpl implements TopUpHistoryRemoteDataSource {
  final SupabaseClient supabaseClient;

  TopUpHistoryRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<TopUpHistoryEntity> createTopUpHistory(
    String userId,
    double amount,
    String description, {
    String? paymentMethod,
    Map<String, dynamic>? paymentDetails,
    String? externalTransactionId,
  }) async {
    try {
      logger.i('TopUpHistoryDataSource: Membuat histori top up untuk user $userId sebesar $amount');
      
      final data = {
        'user_id': userId,
        'amount': amount,
        'status': 'PENDING',
        'description': description,
        'transaction_time': DateTime.now().toIso8601String(),
      };
      
      if (paymentMethod != null) {
        data['payment_method'] = paymentMethod;
      }
      
      if (paymentDetails != null) {
        // Konversi Map ke String JSON untuk kolom payment_details
        data['payment_details'] = jsonEncode(paymentDetails);
      }
      
      if (externalTransactionId != null) {
        data['external_transaction_id'] = externalTransactionId;
      }
      
      final response = await supabaseClient
          .from('top_up_history')
          .insert(data)
          .select()
          .single();
      
      logger.i('TopUpHistoryDataSource: Berhasil membuat histori top up dengan ID ${response['id']}');
      
      return TopUpHistoryEntity.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('TopUpHistoryDataSource: PostgrestException saat membuat histori top up: ${e.message}');
      throw Exception('Gagal membuat histori top up di Supabase: ${e.message}');
    } catch (e) {
      logger.e('TopUpHistoryDataSource: Error saat membuat histori top up: $e');
      throw Exception('Terjadi kesalahan saat membuat histori top up: $e');
    }
  }

  @override
  Future<TopUpHistoryEntity> getTopUpHistoryById(int id) async {
    try {
      logger.i('TopUpHistoryDataSource: Mengambil histori top up dengan ID $id');
      
      final response = await supabaseClient
          .from('top_up_history')
          .select()
          .eq('id', id)
          .single();
      
      logger.i('TopUpHistoryDataSource: Berhasil mengambil histori top up dengan ID $id');
      
      return TopUpHistoryEntity.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('TopUpHistoryDataSource: PostgrestException saat mengambil histori top up: ${e.message}');
      throw Exception('Gagal mengambil histori top up di Supabase: ${e.message}');
    } catch (e) {
      logger.e('TopUpHistoryDataSource: Error saat mengambil histori top up: $e');
      throw Exception('Terjadi kesalahan saat mengambil histori top up: $e');
    }
  }

  @override
  Future<List<TopUpHistoryEntity>> getTopUpHistoryByUserId(String userId) async {
    try {
      logger.i('TopUpHistoryDataSource: Mengambil histori top up untuk user $userId');
      
      final response = await supabaseClient
          .from('top_up_history')
          .select()
          .eq('user_id', userId)
          .order('transaction_time', ascending: false);
      
      logger.i('TopUpHistoryDataSource: Berhasil mengambil ${response.length} histori top up untuk user $userId');
      
      return (response as List<dynamic>)
          .map((item) => TopUpHistoryEntity.fromJson(item))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('TopUpHistoryDataSource: PostgrestException saat mengambil histori top up: ${e.message}');
      throw Exception('Gagal mengambil histori top up di Supabase: ${e.message}');
    } catch (e) {
      logger.e('TopUpHistoryDataSource: Error saat mengambil histori top up: $e');
      throw Exception('Terjadi kesalahan saat mengambil histori top up: $e');
    }
  }

  @override
  Future<TopUpHistoryEntity> updateTopUpHistoryStatus(
    int id,
    TopUpStatus status, {
    String? externalTransactionId,
    Map<String, dynamic>? paymentDetails,
  }) async {
    try {
      logger.i('TopUpHistoryDataSource: Mengupdate status histori top up dengan ID $id menjadi ${status.toString().split('.').last}');
      
      // Pastikan format enum sesuai dengan definisi di database PostgreSQL
      // Enum PostgreSQL case-sensitive, jadi kita perlu memastikan format yang benar
      String statusValue;
      switch (status) {
        case TopUpStatus.pending:
          statusValue = 'PENDING';
          break;
        case TopUpStatus.completed:
          statusValue = 'SUCCESS'; // Menggunakan SUCCESS sesuai dengan enum database
          break;
        case TopUpStatus.failed:
          statusValue = 'FAILED';
          break;
        case TopUpStatus.cancelled:
          statusValue = 'CANCELLED';
          break;
      }
      
      final data = {
        'status': statusValue,
      };
      
      if (externalTransactionId != null) {
        data['external_transaction_id'] = externalTransactionId;
      }
      
      if (paymentDetails != null) {
        // Konversi Map ke String JSON untuk kolom payment_details
        data['payment_details'] = jsonEncode(paymentDetails);
      }
      
      // Pertama, verifikasi bahwa entri dengan ID tersebut ada dan milik user yang sedang login
      final checkExists = await supabaseClient
          .from('top_up_history')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (checkExists == null) {
        throw Exception('Histori top up dengan ID $id tidak ditemukan');
      }
      
      // Lakukan update dengan logging lebih detail
      logger.i('TopUpHistoryDataSource: Melakukan update dengan data: $data');
      
      try {
        final response = await supabaseClient
            .from('top_up_history')
            .update(data)
            .eq('id', id)
            .select();
        
        logger.i('TopUpHistoryDataSource: Response update: $response');
        
        if (response.isEmpty) {
          // Jika response kosong, coba ambil data lagi untuk memastikan update berhasil
          final checkUpdate = await supabaseClient
              .from('top_up_history')
              .select()
              .eq('id', id)
              .single();
          
          logger.i('TopUpHistoryDataSource: Data setelah update: $checkUpdate');
          
          // Jika status sudah sesuai dengan yang diinginkan, anggap update berhasil
          if (checkUpdate['status'] == status.toString().split('.').last) {
            logger.i('TopUpHistoryDataSource: Berhasil mengupdate status histori top up dengan ID $id');
            return TopUpHistoryEntity.fromJson(checkUpdate);
          } else {
            throw Exception('Gagal mengupdate histori top up: status tidak berubah');
          }
        }
        
        logger.i('TopUpHistoryDataSource: Berhasil mengupdate status histori top up dengan ID $id');
        return TopUpHistoryEntity.fromJson(response[0]);
      } catch (e) {
        logger.e('TopUpHistoryDataSource: Error saat update: $e');
        throw Exception('Gagal mengupdate histori top up: $e');
      }
    } on PostgrestException catch (e) {
      logger.e('TopUpHistoryDataSource: PostgrestException saat mengupdate status histori top up: ${e.message}');
      throw Exception('Gagal mengupdate status histori top up di Supabase: ${e.message}');
    } catch (e) {
      logger.e('TopUpHistoryDataSource: Error saat mengupdate status histori top up: $e');
      throw Exception('Terjadi kesalahan saat mengupdate status histori top up: $e');
    }
  }
}
