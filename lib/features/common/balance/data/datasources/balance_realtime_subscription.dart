import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';

/// Class untuk mengelola subscription Supabase Realtime untuk pembaruan saldo secara real-time
class BalanceRealtimeSubscription {
  final SupabaseClient _supabaseClient;
  RealtimeChannel? _channel;
  final StreamController<UserBalanceEntity> _balanceStreamController = StreamController<UserBalanceEntity>.broadcast();

  /// Stream yang dapat didengarkan oleh UI untuk mendapatkan pembaruan saldo secara real-time
  Stream<UserBalanceEntity> get balanceStream => _balanceStreamController.stream;

  BalanceRealtimeSubscription({
    required SupabaseClient supabaseClient,
  }) : _supabaseClient = supabaseClient;

  /// Memulai subscription untuk saldo pengguna tertentu
  Future<void> subscribeToUserBalance(String userId) async {
    try {
      logger.i('BalanceRealtimeSubscription: Memulai subscription untuk saldo user $userId');
      
      // Pastikan subscription sebelumnya sudah dibersihkan
      await unsubscribe();
      
      // Mulai subscription baru
      _channel = _supabaseClient
          .channel('public:user_balances')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'user_balances',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: _handleBalanceChange,
          )
          .subscribe();
          
      logger.i('BalanceRealtimeSubscription: Subscription berhasil dimulai');
    } catch (e) {
      logger.e('BalanceRealtimeSubscription: Error saat memulai subscription: $e');
    }
  }

  /// Handler untuk perubahan saldo
  void _handleBalanceChange(PostgresChangePayload payload) {
    try {
      logger.i('BalanceRealtimeSubscription: Menerima pembaruan saldo: $payload');
      
      // Kita tahu payload.newRecord tidak akan null untuk event update
      final Map<String, dynamic> data = payload.newRecord;
      if (data.isNotEmpty) {
        final UserBalanceEntity updatedBalance = UserBalanceEntity.fromJson(data);
        
        logger.i('BalanceRealtimeSubscription: Saldo baru: ${updatedBalance.balance}');
        _balanceStreamController.add(updatedBalance);
      }
    } catch (e) {
      logger.e('BalanceRealtimeSubscription: Error saat memproses pembaruan saldo: $e');
    }
  }

  /// Berhenti berlangganan dan bersihkan resource
  Future<void> unsubscribe() async {
    try {
      if (_channel != null) {
        logger.i('BalanceRealtimeSubscription: Menghentikan subscription');
        await _supabaseClient.removeChannel(_channel!);
        _channel = null;
      }
    } catch (e) {
      logger.e('BalanceRealtimeSubscription: Error saat menghentikan subscription: $e');
    }
  }

  /// Tutup stream controller saat tidak digunakan lagi
  void dispose() {
    unsubscribe();
    _balanceStreamController.close();
    logger.i('BalanceRealtimeSubscription: Disposed');
  }
}
