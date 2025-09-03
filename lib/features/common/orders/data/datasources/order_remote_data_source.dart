import 'dart:convert';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class OrderRemoteDataSource {
  /// Update status pesanan
  /// Throws [ServerException] jika terjadi kesalahan
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
    String? cancellationReason,
  });
  
  /// Mendapatkan detail pesanan berdasarkan ID
  /// Throws [ServerException] jika terjadi kesalahan
  Future<Map<String, dynamic>> getOrderDetail(int orderId);
  
  /// Mendapatkan daftar pesanan untuk user
  /// Throws [ServerException] jika terjadi kesalahan
  Future<List<Map<String, dynamic>>> getUserOrders(String userId);
  
  /// Mendapatkan daftar pesanan untuk provider
  /// Throws [ServerException] jika terjadi kesalahan
  Future<List<Map<String, dynamic>>> getProviderOrders(String providerId);
}

class SupabaseOrderRemoteDataSource implements OrderRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseOrderRemoteDataSource({required this.supabaseClient});

  @override
  Future<void> updateOrderStatus({
    required int orderId,
    required String status,
    String? notes,
    String? cancellationReason,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'order_status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Simpan catatan atau alasan pembatalan ke kolom yang tersedia di database
      if (notes != null || cancellationReason != null) {
        // Gunakan kolom user_notes (text) untuk menyimpan catatan atau alasan pembatalan
        updateData['user_notes'] = cancellationReason ?? notes ?? '';
        
        // Gunakan kolom notes (jsonb) untuk menyimpan informasi tambahan dalam format JSON
        updateData['notes'] = json.encode({
          'reason': cancellationReason ?? '',
          'notes': notes ?? '',
          'timestamp': DateTime.now().toIso8601String(),
        });
      }

      if (status == 'completed') {
        updateData['completion_date'] = DateTime.now().toIso8601String();
      }

      await supabaseClient
          .from('orders')
          .update(updateData)
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(message: 'Gagal memperbarui status pesanan: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getOrderDetail(int orderId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select('''
            *,
            services (
              title, 
              price, 
              price_unit, 
              images_urls
            ),
            profiles!user_id (
              full_name, 
              avatar_url, 
              phone_number
            ),
            profiles!provider_id (
              full_name, 
              avatar_url, 
              phone_number
            )
          ''')
          .eq('id', orderId)
          .single();
      
      return response;
    } catch (e) {
      throw ServerException(message: 'Gagal mendapatkan detail pesanan: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select('''
            *,
            services (
              title, 
              price, 
              price_unit, 
              images_urls
            ),
            profiles!provider_id (
              full_name, 
              avatar_url
            )
          ''')
          .eq('user_id', userId)
          .order('order_date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ServerException(message: 'Gagal mendapatkan daftar pesanan: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getProviderOrders(String providerId) async {
    try {
      final response = await supabaseClient
          .from('orders')
          .select('''
            *,
            services (
              title, 
              price, 
              price_unit, 
              images_urls
            ),
            profiles!user_id (
              full_name, 
              avatar_url
            )
          ''')
          .eq('provider_id', providerId)
          .order('order_date', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw ServerException(message: 'Gagal mendapatkan daftar pesanan: $e');
    }
  }
}
