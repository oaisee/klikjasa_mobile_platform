import 'package:klik_jasa/core/data/datasources/supabase_data_source.dart';
import 'package:klik_jasa/core/domain/entities/consolidated_order.dart';
import 'package:klik_jasa/core/domain/enums/order_status.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/datasources/order_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseOrderRemoteDataSource extends SupabaseDataSource implements OrderRemoteDataSource {
  final String _tableName = 'orders';

  SupabaseOrderRemoteDataSource({
    required super.supabaseClient,
  });

  @override
  Future<List<Order>> getProviderOrders(String providerId, {OrderStatus? status}) async {
    return handleSupabaseOperation(
      operation: () async {
        var query = supabaseClient
            .from(_tableName)
            .select('*, services(*, service_categories(*)), profiles!orders_user_id_fkey(*)')
            .eq('provider_id', providerId);

        if (status != null) {
          query = query.eq('order_status', orderStatusToString(status));
        }

        final List<Map<String, dynamic>> response = await query.order('order_date', ascending: false);

        final orders = response
            .map((data) => Order.fromJson(data))
            .toList();
        return orders;
      },
      context: 'memuat pesanan penyedia',
    );
  }

  @override
  Future<double> getProviderTotalCompletedRevenue(String providerId) async {
    return handleSupabaseOperation(
      operation: () async {
        final List<Map<String, dynamic>> response = await supabaseClient
            .from(_tableName)
            .select('total_price')
            .eq('provider_id', providerId)
            .eq('order_status', 'completed_by_provider');

        double totalRevenue = 0.0;
        for (var item in response) {
          if (item.containsKey('total_price') && item['total_price'] != null) {
            totalRevenue += item['total_price'] is num ? (item['total_price'] as num).toDouble() : 0.0;
          }
        }
        return totalRevenue;
      },
      context: 'memuat total pendapatan',
    );
  }

  @override
  Future<int> getProviderActiveOrdersCount(String providerId) async {
    return handleSupabaseOperation(
      operation: () async {
        final count = await supabaseClient
            .from(_tableName)
            .count(CountOption.exact)
            .eq('provider_id', providerId)
            .inFilter('order_status', ['pending_confirmation', 'accepted_by_provider', 'in_progress']);
        return count;
      },
      context: 'mengambil jumlah pesanan aktif',
    );
  }

  @override
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus newStatus,
    String? providerNotes,
    String? cancellationReason,
  }) async {
    return handleSupabaseOperation(
      operation: () async {
        final Map<String, dynamic> updates = {
          'order_status': orderStatusToString(newStatus),
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

        final List<Map<String, dynamic>> response = await supabaseClient
            .from(_tableName)
            .update(updates)
            .eq('id', int.parse(orderId)) 
            .select('*, services(*, service_categories(*)), profiles!orders_user_id_fkey(*)'); 

        if (response.isEmpty) {
          throw Exception('Pesanan tidak ditemukan atau gagal diperbarui.');
        }
        
        return Order.fromJson(response.first);
      },
      context: 'memperbarui status pesanan',
    );
  }
}
