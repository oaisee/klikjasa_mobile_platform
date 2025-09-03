
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/data/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class NotificationRemoteDataSource {
  /// Mendapatkan daftar notifikasi untuk pengguna tertentu dengan pagination
  /// [page] adalah halaman yang diminta, dimulai dari 1
  /// [limit] adalah jumlah maksimum notifikasi per halaman
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    String mode = 'both',
    int page = 1,
    int limit = 10,
  });
  
  /// Menandai notifikasi sebagai sudah dibaca
  Future<bool> markAsRead(int notificationId);
  
  /// Menandai beberapa notifikasi sekaligus sebagai sudah dibaca
  /// Lebih efisien daripada memanggil markAsRead untuk setiap notifikasi
  Future<bool> batchMarkAsRead(List<int> notificationIds);
  
  /// Menandai semua notifikasi pengguna sebagai sudah dibaca
  Future<bool> markAllAsRead(String userId, {String mode = 'both'});
  
  /// Mendapatkan jumlah notifikasi yang belum dibaca
  Future<int> getUnreadCount(String userId, {String mode = 'both'});

  /// Membuat notifikasi baru dengan mode tertentu
  Future<int> createNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String? type,
    String? relatedEntityType,
    String? relatedEntityId,
    String mode = 'both'
  });
}

class SupabaseNotificationRemoteDataSource implements NotificationRemoteDataSource {
  final SupabaseClient supabaseClient;

  SupabaseNotificationRemoteDataSource({required this.supabaseClient});

  @override
  Future<List<NotificationModel>> getNotifications(
    String userId, {
    String mode = 'both',
    int page = 1,
    int limit = 10,
  }) async {
    try {
      // Hitung offset berdasarkan page dan limit
      final offset = (page - 1) * limit;
      
      // Gunakan fungsi RPC untuk pagination yang mendukung offset dan limit
      logger.i('Mengambil notifikasi untuk user ID: $userId dengan mode: $mode, page: $page, limit: $limit');
      final response = await supabaseClient
          .rpc('get_paginated_notifications_by_user_and_mode', params: {
            'p_user_id': userId,
            'p_mode': mode,
            'p_limit': limit,
            'p_offset': offset
          });

      logger.d('Response notifikasi diterima untuk halaman $page');
      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      logger.e('Error mengambil notifikasi: ${e.toString()}');
      throw ServerException(message: 'Gagal mengambil notifikasi: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAsRead(int notificationId) async {
    try {
      logger.i('Menandai notifikasi $notificationId sebagai dibaca menggunakan .update()');
      await supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      logger.d('Notifikasi $notificationId berhasil ditandai sebagai dibaca.');
      return true;
    } on PostgrestException catch (e) {
      logger.e('Error Postgrest saat menandai notifikasi sebagai dibaca: ${e.toString()}');
      throw ServerException(message: 'Gagal menandai notifikasi sebagai dibaca: ${e.message}');
    } catch (e) {
      logger.e('Error umum saat menandai notifikasi sebagai dibaca: ${e.toString()}');
      throw ServerException(message: 'Gagal menandai notifikasi sebagai dibaca: ${e.toString()}');
    }
  }
  
  @override
  Future<bool> batchMarkAsRead(List<int> notificationIds) async {
    try {
      if (notificationIds.isEmpty) {
        return true; // Tidak ada yang perlu ditandai
      }

      logger.i('Menandai ${notificationIds.length} notifikasi sebagai dibaca secara batch menggunakan .update()');

      // Menggunakan .update() dan .inFilter() daripada RPC untuk menghindari error di fungsi SQL
      await supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .inFilter('id', notificationIds);

      logger.d('Batch mark as read berhasil dieksekusi tanpa error.');
      return true; // Asumsikan berhasil jika tidak ada error
    } on PostgrestException catch (e) {
      logger.e('Error Postgrest saat menandai batch notifikasi sebagai dibaca: ${e.toString()}');
      throw ServerException(message: 'Gagal menandai batch notifikasi sebagai dibaca: ${e.message}');
    } catch (e) {
      logger.e('Error umum saat menandai batch notifikasi sebagai dibaca: ${e.toString()}');
      throw ServerException(message: 'Gagal menandai batch notifikasi sebagai dibaca: ${e.toString()}');
    }
  }

  @override
  Future<bool> markAllAsRead(String userId, {String mode = 'both'}) async {
    try {
      logger.i('Menandai semua notifikasi untuk user $userId dengan mode $mode sebagai dibaca');

      // Reimplementasi untuk menghindari RPC yang bermasalah.
      // Menggunakan .update() dengan filter pada recipient_user_id dan tipe notifikasi berdasarkan mode.
      final query = supabaseClient
          .from('notifications')
          .update({'is_read': true})
          .eq('recipient_user_id', userId);

      if (mode == 'provider') {
        // Filter untuk notifikasi yang relevan bagi provider
        query.or("type.like.order%,type.in.('verification','balance','complaint','chat','review','admin')");
      } else if (mode == 'user') {
        // Filter untuk notifikasi yang relevan bagi user
        query.inFilter('type', ['order_update', 'chat', 'promotion', 'admin', 'general']);
      }
      // Jika mode 'both', tidak ada filter tambahan pada 'type', semua notifikasi user akan ditandai.

      await query;

      logger.d('Semua notifikasi untuk user $userId dengan mode $mode berhasil ditandai sebagai dibaca.');
      return true;
    } catch (e) {
      logger.e('Error menandai semua notifikasi sebagai dibaca: ${e.toString()}');
      throw ServerException(message: 'Gagal menandai semua notifikasi sebagai dibaca: ${e.toString()}');
    }
  }

  @override
  Future<int> getUnreadCount(String userId, {String mode = 'both'}) async {
    try {
      logger.i('Menghitung notifikasi yang belum dibaca untuk user $userId dengan mode $mode');
      final response = await supabaseClient
          .rpc('get_unread_notification_count_by_mode', params: {
            'p_user_id': userId,
            'p_mode': mode
          });
      
      logger.d('Response unread count: $response');
      return response as int;
    } catch (e) {
      logger.e('Error menghitung notifikasi yang belum dibaca: ${e.toString()}');
      throw ServerException(message: 'Gagal menghitung notifikasi yang belum dibaca: ${e.toString()}');
    }
  }

  @override
  Future<int> createNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String? type,
    String? relatedEntityType,
    String? relatedEntityId,
    String mode = 'both'
  }) async {
    try {
      logger.i('Membuat notifikasi baru untuk user $recipientUserId dengan mode $mode');
      final response = await supabaseClient
          .rpc('create_notification', params: {
            'p_recipient_user_id': recipientUserId,
            'p_title': title,
            'p_body': body,
            'p_type': type ?? '',
            'p_related_entity_type': relatedEntityType ?? '',
            'p_related_entity_id': relatedEntityId ?? '',
            'p_user_mode': mode
          });
      
      logger.d('Response create notification: $response');
      return response as int;
    } catch (e) {
      logger.e('Error membuat notifikasi: ${e.toString()}');
      throw ServerException(message: 'Gagal membuat notifikasi: ${e.toString()}');
    }
  }
}
