import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

typedef OnOrderChanged = void Function(Map<String, dynamic> newOrder);

typedef OnOrderDeleted = void Function(String deletedOrderId);

class OrdersRealtimeSubscription {
  final SupabaseClient supabase;
  final String providerId;
  final OnOrderChanged onOrderChanged;
  final OnOrderDeleted? onOrderDeleted;
  RealtimeChannel? _channel;
  bool _isSubscribed = false;
  final Logger _logger = Logger();

  OrdersRealtimeSubscription({
    required this.supabase,
    required this.providerId,
    required this.onOrderChanged,
    this.onOrderDeleted,
  });

  void subscribe() {
    if (_isSubscribed) {
      _logger.i('📱 Subscription realtime orders sudah aktif untuk provider: $providerId');
      return;
    }
    
    _logger.i('📱 Memulai subscription realtime orders untuk provider: $providerId');
    
    try {
      _channel = supabase.channel('orders:provider:$providerId')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'provider_id',
            value: providerId,
          ),
          callback: (payload) {
            final eventType = payload.eventType;
            final newRow = payload.newRecord;
            final oldRow = payload.oldRecord;
            
            _logger.i('📱 Menerima event realtime: $eventType untuk order');
            _logger.d('📱 Payload: ${payload.toString()}');
            
            if (eventType == PostgresChangeEvent.delete) {
              _logger.i('📱 Order dihapus dengan ID: ${oldRow['id']}');
              onOrderDeleted?.call(oldRow['id'].toString());
            } else if (eventType == PostgresChangeEvent.insert || eventType == PostgresChangeEvent.update) {
              _logger.i('📱 Order berubah: ${newRow['id']}, status: ${newRow['status']}');
              onOrderChanged(newRow);
            }
          },
        )

        ..subscribe((status, [error]) {
          _logger.i('📱 Status subscription realtime orders: $status');
          if (error != null) {
            _logger.e('❌ Error pada subscription realtime orders: $error');
            _isSubscribed = false;
            return;
          }

          if (status == RealtimeSubscribeStatus.subscribed) {
            _logger.i('✅ Berhasil subscribe ke realtime orders.');
            _isSubscribed = true;
          } else {
            _isSubscribed = false;
          }
        });
    } catch (e) {
      _logger.e('❌ Exception saat setup subscription realtime orders: $e');
    }
  }

  Future<void> unsubscribe() async {
    if (_channel != null) {
      _logger.i('📱 Menghentikan subscription realtime orders untuk provider: $providerId');
      await _channel!.unsubscribe();
      _channel = null;
    }
    _isSubscribed = false;
  }
}
