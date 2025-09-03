import 'dart:async';
import 'package:flutter/material.dart';
import 'package:klik_jasa/features/provider_mode/incoming_orders/data/datasources/orders_realtime_subscription.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';
import '../bloc/provider_orders/provider_orders_bloc.dart';

class ProviderOrdersRealtimeHandler {
  final BuildContext context;
  final String providerId;
  OrdersRealtimeSubscription? _realtimeSub;
  Timer? _healthCheckTimer;
  bool _isActive = false;
  final Logger _logger = Logger();

  ProviderOrdersRealtimeHandler({required this.context, required this.providerId});

  void start() {
    if (_isActive) {
      _logger.i('🔄 Handler realtime orders sudah aktif untuk provider: $providerId');
      return;
    }
    
    _logger.i('🔄 Memulai handler realtime orders untuk provider: $providerId');
    _isActive = true;
    
    _realtimeSub = OrdersRealtimeSubscription(
      supabase: Supabase.instance.client,
      providerId: providerId,
      onOrderChanged: (order) {
        _logger.i('🔄 Menerima perubahan order: ${order['id']}, status: ${order['status']}');
        
        try {
          if (context.mounted) {
            _logger.i('🔄 Memicu refresh bloc dengan FetchAllProviderOrders');
            context.read<ProviderOrdersBloc>().add(
              FetchAllProviderOrders(providerId: providerId),
            );
          } else {
            _logger.w('⚠️ Context tidak mounted, tidak bisa memicu refresh bloc');
          }
        } catch (e) {
          _logger.e('❌ Error saat memicu refresh bloc: $e');
        }
      },
      onOrderDeleted: (orderId) {
        _logger.i('🔄 Menerima notifikasi order dihapus: $orderId');
        
        try {
          if (context.mounted) {
            _logger.i('🔄 Memicu refresh bloc dengan FetchAllProviderOrders setelah order dihapus');
            context.read<ProviderOrdersBloc>().add(
              FetchAllProviderOrders(providerId: providerId),
            );
          } else {
            _logger.w('⚠️ Context tidak mounted, tidak bisa memicu refresh bloc');
          }
        } catch (e) {
          _logger.e('❌ Error saat memicu refresh bloc setelah order dihapus: $e');
        }
      },
    );
    
    _realtimeSub!.subscribe();
    _startHealthCheck();
  }
  
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _logger.i('🔄 Melakukan health check pada subscription realtime orders');
      // Refresh subscription untuk memastikan tetap aktif
      _realtimeSub?.unsubscribe();
      _realtimeSub?.subscribe();
      
      // Refresh data juga
      if (context.mounted) {
        _logger.i('🔄 Memicu refresh data pada health check');
        context.read<ProviderOrdersBloc>().add(
          FetchAllProviderOrders(providerId: providerId),
        );
      }
    });
  }

  void stop() {
    _logger.i('🔄 Menghentikan handler realtime orders untuk provider: $providerId');
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _realtimeSub?.unsubscribe();
    _isActive = false;
  }
}
