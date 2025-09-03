import 'dart:async';

import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Kelas untuk menangani subscription realtime pada tabel notifikasi
class NotificationRealtimeSubscription {
  final SupabaseClient supabaseClient;
  final String userId;
  final void Function(NotificationModel notification) onNotificationReceived;
  final void Function(NotificationModel notification) onNotificationUpdated;
  final void Function(int notificationId) onNotificationDeleted;
  
  StreamSubscription? _incomingSubscription;
  final Logger _logger = Logger();
  
  // Konfigurasi retry
  int _retryCount = 0;
  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  
  NotificationRealtimeSubscription({
    required this.supabaseClient,
    required this.userId,
    required this.onNotificationReceived,
    required this.onNotificationUpdated,
    required this.onNotificationDeleted,
  });
  
  /// Memulai subscription untuk notifikasi yang ditujukan ke user ini
  void startSubscription() {
    _logger.i('Memulai subscription notifikasi realtime untuk user $userId');
    _retryCount = 0;
    _attemptSubscription();
  }
  
  /// Mencoba membuat subscription dengan mekanisme retry
  void _attemptSubscription() {
    // Bersihkan subscription sebelumnya jika ada
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
    
    try {
      // Subscription untuk notifikasi yang ditujukan ke user ini
      _incomingSubscription = supabaseClient
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('recipient_user_id', userId)
          .listen(
            (data) {
              if (data.isEmpty) return;
              _logger.d('Menerima event notifikasi realtime. Data: $data');
              try {
                // .stream() tidak menyediakan eventType, hanya data baru.
                // Kita asumsikan setiap event adalah INSERT atau UPDATE.
                final notification = NotificationModel.fromJson(data.first);
                _logger.i('Notifikasi baru/update diterima: ${notification.id}');
                onNotificationReceived(notification); // Atau onNotificationUpdated jika ada logika pembeda
                
                // Reset retry counter jika berhasil menerima data
                _retryCount = 0;
              } catch (e) {
                _logger.e('Gagal mem-parsing notifikasi dari event realtime: $e');
              }
            },
            onError: (error) {
              if (error is RealtimeSubscribeException) {
                _logger.e('Koneksi Realtime Gagal. Periksa kebijakan RLS di Supabase. Detail: ${error.toString()}');
                _handleSubscriptionError();
              } else {
                _logger.e('Error pada subscription notifikasi: $error');
                _handleSubscriptionError();
              }
            },
          );
      
      _logger.i('Subscription notifikasi realtime berhasil dimulai');
    } catch (e) {
      _logger.e('Error saat memulai subscription: $e');
      _handleSubscriptionError();
    }
  }
  
  /// Menangani error subscription dan mencoba ulang jika masih dalam batas retry
  void _handleSubscriptionError() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      _logger.i('Mencoba ulang koneksi ($_retryCount/$_maxRetries) dalam ${_retryDelay.inSeconds} detik...');
      
      // Jadwalkan percobaan ulang
      Future.delayed(_retryDelay, () {
        _logger.i('Melakukan percobaan ulang koneksi ke-$_retryCount');
        _attemptSubscription();
      });
    } else {
      _logger.e('Batas maksimum percobaan koneksi tercapai ($_maxRetries). Menyerah.');
    }
  }
  
  /// Menghentikan semua subscription
  void stopSubscription() {
    _logger.i('Menghentikan subscription notifikasi realtime');
    _incomingSubscription?.cancel();
    _incomingSubscription = null;
    _retryCount = 0;
  }
}
