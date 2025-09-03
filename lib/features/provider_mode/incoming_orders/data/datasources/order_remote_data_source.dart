import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/user_balance_remote_data_source.dart';
import 'package:klik_jasa/features/common/balance/domain/enums/transaction_type_enum.dart';

abstract class OrderRemoteDataSource {
  Future<List<Order>> getProviderOrders(String providerId, {OrderStatus? status});
  Future<double> getProviderTotalCompletedRevenue(String providerId);
  Future<int> getProviderActiveOrdersCount(String providerId);
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? providerNotes,
    String? cancellationReason,
  });
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient supabaseClient;
  late final UserBalanceRemoteDataSource _userBalanceDataSource;

  OrderRemoteDataSourceImpl({required this.supabaseClient}) {
    _userBalanceDataSource = UserBalanceRemoteDataSourceImpl(supabaseClient: supabaseClient);
  }

  @override
  Future<List<Order>> getProviderOrders(String providerId, {OrderStatus? status}) async {
    try {
      logger.i('DEBUG: Mengambil pesanan provider $providerId dengan status ${status?.toString() ?? "semua"}');
      
      var query = supabaseClient
          .from('orders')
          .select('*, services(*, service_categories(*)), user:profiles!user_id(*)')
          .eq('provider_id', providerId);

      if (status != null) {
        final statusString = orderStatusToString(status);
        logger.i('DEBUG: Filter status pesanan: $statusString');
        query = query.eq('order_status', statusString);
      }

      final List<Map<String, dynamic>> response = await query.order('order_date', ascending: false);
      
      logger.i('DEBUG: Jumlah pesanan yang ditemukan: ${response.length}');
      if (response.isNotEmpty) {
        logger.i('DEBUG: Contoh data pesanan pertama: ${response.first}');
      } else {
        logger.w('DEBUG: Tidak ada pesanan yang ditemukan dengan status ${status?.toString() ?? "semua"}');
      }

      final orders = response
          .map((data) => Order.fromJson(data))
          .toList();
      return orders;
    } catch (e) {
      logger.e('Error fetching provider orders: $e');
      throw Exception('Gagal memuat pesanan penyedia: ${e.toString()}');
    }
  }

  @override
  Future<double> getProviderTotalCompletedRevenue(String providerId) async {
    try {
      final List<Map<String, dynamic>> response = await supabaseClient
          .from('orders')
          .select('total_price')
          .eq('provider_id', providerId)
          .eq('order_status', 'completed_by_provider'); // Sesuai enum DB untuk pendapatan final

      double totalRevenue = 0.0;
      for (var item in response) {
        if (item.containsKey('total_price') && item['total_price'] != null) {
          totalRevenue += item['total_price'] is num ? (item['total_price'] as num).toDouble() : 0.0;
        }
      }
      return totalRevenue;
    } catch (e) {
      logger.e('Error fetching total completed revenue: $e');
      throw Exception('Gagal memuat total pendapatan: ${e.toString()}');
    }
  }

  @override
  Future<int> getProviderActiveOrdersCount(String providerId) async {
    try {
      final count = await supabaseClient
          .from('orders')
          .count(CountOption.exact) // Menggunakan CountOption.exact untuk mendapatkan jumlah pasti
          .eq('provider_id', providerId)
          .inFilter('order_status', ['pending_confirmation', 'accepted_by_provider', 'in_progress']); // Sesuai enum DB
      // Tidak perlu memeriksa tipe response di sini karena .count(CountOption.exact) akan mengembalikan int
      return count;
    } catch (e) {
      logger.e('Error in getProviderActiveOrdersCount: $e');
      throw Exception('Gagal mengambil jumlah pesanan aktif: ${e.toString()}');
    }
  }

  @override
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? providerNotes,
    String? cancellationReason,
  }) async {
    try {
      // Validasi input
      if (orderId.isEmpty) {
        throw Exception('ID pesanan tidak boleh kosong');
      }
      
      int orderIdInt;
      try {
        orderIdInt = int.parse(orderId);
      } catch (e) {
        logger.e('Error parsing orderId: $orderId is not a valid integer');
        throw Exception('ID pesanan harus berupa angka');
      }
      
      // Validasi status enum
      if (newStatus == OrderStatus.unknown) {
        throw Exception('Status pesanan tidak valid: OrderStatus.unknown');
      }
      
      // Konversi OrderStatus enum ke string untuk database
      final statusString = orderStatusToString(newStatus);
      logger.i('Updating order $orderId to status: $statusString (enum: $newStatus)');

      // Persiapkan data untuk update
      final Map<String, dynamic> updates = {
        'order_status': statusString,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (providerNotes != null) {
        updates['provider_notes'] = providerNotes;
      }
      if (cancellationReason != null && (newStatus == OrderStatus.cancelled || newStatus == OrderStatus.rejected)) {
        updates['cancellation_reason'] = cancellationReason;
      }
      if (newStatus == OrderStatus.completed) {
        updates['completion_date'] = DateTime.now().toIso8601String();
      }

      // Log data yang akan diupdate untuk debugging
      logger.i('Update data for order $orderId: $updates');

      // Periksa apakah pesanan ada sebelum memperbarui
      final orderData = await supabaseClient
          .from('orders')
          .select('id, provider_id, total_price, fee_amount, fee_percentage, fee_type')
          .eq('id', orderIdInt)
          .maybeSingle();
          
      if (orderData == null) {
        final errorMessage = 'Pesanan dengan ID $orderId tidak ditemukan';
        logger.e(errorMessage);
        throw Exception(errorMessage);
      }
      
      // Jika status baru adalah accepted_by_provider, potong biaya platform dari saldo provider
      if (newStatus == OrderStatus.confirmed) {
        final providerId = orderData['provider_id'] as String;
        final feeAmount = orderData['fee_amount'] is num 
            ? (orderData['fee_amount'] as num).toDouble() 
            : (orderData['application_fee'] is num 
                ? (orderData['application_fee'] as num).toDouble() 
                : 0.0);
        
        if (feeAmount > 0) {
          logger.i('Memotong biaya platform sebesar $feeAmount dari provider $providerId');
          try {
            // Potong biaya platform dari saldo provider
            await _userBalanceDataSource.deductBalance(
              providerId,
              feeAmount,
              'Biaya platform untuk pesanan #$orderId',
              TransactionType.platformFee.value, // Menggunakan enum yang valid
            );
            
            logger.i('Berhasil memotong biaya platform sebesar $feeAmount dari provider $providerId');
          } catch (e) {
            logger.e('Gagal memotong biaya platform: ${e.toString()}');
            
            // Tetap coba catat transaksi biaya platform meskipun gagal memotong saldo
            try {
              await supabaseClient.from('transactions').insert({
                'user_id': providerId,
                'order_id': orderIdInt,
                'transaction_type': 'platform_fee',
                'amount': -feeAmount, // Nilai negatif karena ini adalah pengurangan
                'description': 'Biaya platform untuk pesanan #$orderId',
                'status': 'completed',
                'transaction_date': DateTime.now().toIso8601String(),
              });
              logger.i('Berhasil mencatat transaksi biaya platform');
            } catch (transactionError) {
              logger.e('Gagal mencatat transaksi biaya platform: ${transactionError.toString()}');
              // Tetap lanjutkan proses update status pesanan meskipun gagal mencatat transaksi
              // Bisa ditambahkan logika retry atau notifikasi admin di sini
            }
          }
        }
      }

      final List<Map<String, dynamic>> response = await supabaseClient
          .from('orders')
          .update(updates)
          .eq('id', orderIdInt) 
          .select('*, services(*, service_categories(*)), user:profiles!user_id(*)');

      if (response.isEmpty) {
        final errorMessage = 'Pesanan berhasil diperbarui tetapi gagal mengambil data terbaru';
        logger.w(errorMessage);
        // Ambil data pesanan setelah update
        final updatedOrder = await supabaseClient
            .from('orders')
            .select('*, services(*, service_categories(*)), user:profiles!user_id(*)')
            .eq('id', orderIdInt)
            .single();
        logger.i('Retrieved updated order after update: ${updatedOrder['id']}');
        return Order.fromJson(updatedOrder);
      }
      
      logger.i('Order status updated successfully: ${response.first['id']}');
      return Order.fromJson(response.first);
    } catch (e) {
      final errorMessage = 'Gagal memperbarui status pesanan di Supabase: ${e.toString()}';
      logger.e('Error updating order status: $errorMessage');
      throw Exception(errorMessage);
    }
  }
}
