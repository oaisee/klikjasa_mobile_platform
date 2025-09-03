import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/core/data/models/order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async' as dart_async;

abstract class ProviderOrderRemoteDataSource {
  /// Mengambil daftar pesanan yang menunggu konfirmasi untuk provider
  Future<List<OrderModel>> getPendingOrders(String providerId);
  
  /// Mengambil jumlah pesanan yang menunggu konfirmasi untuk provider
  Future<int> getPendingOrdersCount(String providerId);
  
  /// Mengambil detail pesanan berdasarkan ID
  Future<OrderModel> getOrderDetail(int orderId);
}

class SupabaseProviderOrderRemoteDataSource implements ProviderOrderRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseProviderOrderRemoteDataSource({required this.supabaseClient});

  @override
  Future<List<OrderModel>> getPendingOrders(String providerId) async {
    try {
      logger.i('Mengambil daftar pesanan pending untuk provider: $providerId');
      // Menggunakan RPC untuk menghindari masalah relasi many-to-one
      final response = await supabaseClient
          .rpc('get_provider_pending_orders', params: {
            'p_provider_id': providerId
          });
      
      final List<dynamic> data = response as List<dynamic>;
      logger.i('Berhasil mengambil ${data.length} pesanan pending');
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error saat mengambil daftar pesanan pending: $e');
      throw ServerException(message: 'Gagal mengambil daftar pesanan: ${e.toString()}');
    }
  }

  @override
  Future<int> getPendingOrdersCount(String providerId) async {
    try {
      logger.i('Menghitung jumlah pesanan pending untuk provider: $providerId');
      final response = await supabaseClient
          .rpc('get_provider_pending_orders_count', params: {
            'p_provider_id': providerId
          })
          .timeout(const Duration(seconds: 10), onTimeout: () {
            logger.w('Timeout saat menghitung jumlah pesanan pending');
            throw dart_async.TimeoutException('Koneksi ke server terlalu lama');
          });
      
      logger.i('Jumlah pesanan pending: $response');
      return response as int;
    } catch (e) {
      logger.e('Error saat menghitung jumlah pesanan pending: $e');
      if (e is dart_async.TimeoutException) {
        throw TimeoutException(message: 'Koneksi ke server terlalu lama, silakan coba lagi');
      } else if (e is PostgrestException) {
        // Tangani error Supabase secara spesifik
        throw ServerException(message: 'Gagal menghitung pesanan: ${e.message}', code: e.code);
      } else {
        throw ServerException(message: 'Gagal menghitung pesanan yang menunggu konfirmasi: ${e.toString()}');
      }
    }
  }

  @override
  Future<OrderModel> getOrderDetail(int orderId) async {
    try {
      logger.i('Mengambil detail pesanan dengan ID: $orderId');
      final response = await supabaseClient
          .rpc('get_order_detail', params: {
            'p_order_id': orderId
          });
      
      if (response == null) {
        logger.w('Pesanan dengan ID $orderId tidak ditemukan');
        throw ServerException(message: 'Pesanan tidak ditemukan');
      }
      
      logger.i('Berhasil mengambil detail pesanan dengan ID: $orderId');
      return OrderModel.fromJson(response);
    } catch (e) {
      logger.e('Error saat mengambil detail pesanan: $e');
      throw ServerException(message: 'Gagal mengambil detail pesanan: ${e.toString()}');
    }
  }
}
