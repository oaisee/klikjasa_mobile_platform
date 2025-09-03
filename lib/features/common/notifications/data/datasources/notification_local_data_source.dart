import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/data/models/notification_model.dart';

abstract class NotificationLocalDataSource {
  /// Gets the cached list of [NotificationModel] which was gotten the last time
  /// the user had an internet connection.
  /// 
  /// Throws [CacheException] if no cached data is present.
  Future<List<NotificationModel>> getCachedNotifications(String userId, {String mode = 'both'});

  /// Gets the cached unread count of notifications
  /// 
  /// Returns 0 if no cached data is present.
  Future<int> getCachedUnreadCount(String userId, {String mode = 'both'});

  /// Caches the list of [NotificationModel]
  Future<void> cacheNotifications(List<NotificationModel> notifications, String userId, {String mode = 'both'});

  /// Caches the unread count of notifications
  Future<void> cacheUnreadCount(int count, String userId, {String mode = 'both'});

  /// Updates the read status of a notification in the cache
  Future<bool> updateNotificationReadStatus(int notificationId, bool isRead);
  
  /// Updates the read status of multiple notifications in the cache
  /// More efficient than calling updateNotificationReadStatus for each notification
  Future<bool> batchMarkNotificationsAsRead(List<int> notificationIds);

  /// Updates all notifications as read in the cache for a specific user
  Future<bool> markAllNotificationsAsRead(String userId, {String mode = 'both'});
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  final SharedPreferences sharedPreferences;

  NotificationLocalDataSourceImpl({required this.sharedPreferences});

  String _getNotificationsCacheKey(String userId, String mode) => 'CACHED_NOTIFICATIONS_${userId}_$mode';
  String _getUnreadCountCacheKey(String userId, String mode) => 'CACHED_UNREAD_COUNT_${userId}_$mode';

  @override
  Future<List<NotificationModel>> getCachedNotifications(String userId, {String mode = 'both'}) async {
    logger.i('LocalDataSource: Mengambil notifikasi dari cache untuk user $userId dengan mode $mode');
    final jsonString = sharedPreferences.getString(_getNotificationsCacheKey(userId, mode));
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        final notifications = jsonList
            .map((jsonItem) => NotificationModel.fromJson(jsonItem))
            .toList();
        
        logger.i('LocalDataSource: Berhasil mengambil ${notifications.length} notifikasi dari cache');
        return notifications;
      } catch (e) {
        logger.e('LocalDataSource: Error saat parsing data cache: $e');
        throw CacheException(message: 'Error saat parsing data cache: $e');
      }
    } else {
      logger.w('LocalDataSource: Tidak ada data notifikasi dalam cache');
      throw CacheException(message: 'Tidak ada data notifikasi dalam cache');
    }
  }

  @override
  Future<int> getCachedUnreadCount(String userId, {String mode = 'both'}) async {
    logger.i('LocalDataSource: Mengambil jumlah notifikasi belum dibaca dari cache untuk user $userId dengan mode $mode');
    final countString = sharedPreferences.getString(_getUnreadCountCacheKey(userId, mode));
    
    if (countString != null) {
      try {
        final count = int.parse(countString);
        logger.i('LocalDataSource: Jumlah notifikasi belum dibaca dari cache: $count');
        return count;
      } catch (e) {
        logger.e('LocalDataSource: Error saat parsing jumlah notifikasi dari cache: $e');
        return 0;
      }
    } else {
      logger.w('LocalDataSource: Tidak ada data jumlah notifikasi dalam cache');
      return 0;
    }
  }

  @override
  Future<void> cacheNotifications(List<NotificationModel> notifications, String userId, {String mode = 'both'}) async {
    logger.i('LocalDataSource: Menyimpan ${notifications.length} notifikasi ke cache untuk user $userId dengan mode $mode');
    final List<Map<String, dynamic>> jsonList = notifications.map((notification) => notification.toJson()).toList();
    
    await sharedPreferences.setString(
      _getNotificationsCacheKey(userId, mode),
      json.encode(jsonList),
    );
    logger.i('LocalDataSource: Berhasil menyimpan notifikasi ke cache');
  }

  @override
  Future<void> cacheUnreadCount(int count, String userId, {String mode = 'both'}) async {
    logger.i('LocalDataSource: Menyimpan jumlah notifikasi belum dibaca ($count) ke cache untuk user $userId dengan mode $mode');
    await sharedPreferences.setString(
      _getUnreadCountCacheKey(userId, mode),
      count.toString(),
    );
    logger.i('LocalDataSource: Berhasil menyimpan jumlah notifikasi belum dibaca ke cache');
  }

  @override
  Future<bool> updateNotificationReadStatus(int notificationId, bool isRead) async {
    logger.i('LocalDataSource: Memperbarui status baca notifikasi $notificationId menjadi $isRead');
    
    // Perlu mengambil semua data cache untuk semua user dan mode
    final allKeys = sharedPreferences.getKeys();
    final notificationKeys = allKeys.where((key) => key.startsWith('CACHED_NOTIFICATIONS_')).toList();
    
    bool updated = false;
    
    for (final key in notificationKeys) {
      final jsonString = sharedPreferences.getString(key);
      if (jsonString != null) {
        try {
          final List<dynamic> jsonList = json.decode(jsonString);
          bool hasChanges = false;
          
          final updatedJsonList = jsonList.map((jsonItem) {
            if (jsonItem['id'] == notificationId) {
              hasChanges = true;
              return {...jsonItem, 'is_read': isRead};
            }
            return jsonItem;
          }).toList();
          
          if (hasChanges) {
            await sharedPreferences.setString(key, json.encode(updatedJsonList));
            updated = true;
            
            // Update unread count
            final userId = key.split('_')[2];
            final mode = key.split('_')[3];
            final unreadCountKey = _getUnreadCountCacheKey(userId, mode);
            final currentCount = int.tryParse(sharedPreferences.getString(unreadCountKey) ?? '0') ?? 0;
            
            if (isRead && currentCount > 0) {
              await sharedPreferences.setString(unreadCountKey, (currentCount - 1).toString());
            } else if (!isRead) {
              await sharedPreferences.setString(unreadCountKey, (currentCount + 1).toString());
            }
            
            logger.i('LocalDataSource: Berhasil memperbarui status baca notifikasi di cache');
          }
        } catch (e) {
          logger.e('LocalDataSource: Error saat memperbarui status baca notifikasi: $e');
        }
      }
    }
    
    return updated;
  }

  @override
  Future<bool> batchMarkNotificationsAsRead(List<int> notificationIds) async {
    logger.i('LocalDataSource: Menandai ${notificationIds.length} notifikasi sebagai dibaca secara batch');
    
    if (notificationIds.isEmpty) {
      return true; // Tidak ada yang perlu ditandai
    }
    
    // Perlu mengambil semua data cache untuk semua user dan mode
    final allKeys = sharedPreferences.getKeys();
    final notificationKeys = allKeys.where((key) => key.startsWith('CACHED_NOTIFICATIONS_')).toList();
    
    bool updated = false;
    
    for (final key in notificationKeys) {
      final jsonString = sharedPreferences.getString(key);
      if (jsonString != null) {
        try {
          final List<dynamic> jsonList = json.decode(jsonString);
          int updatedCount = 0;
          
          final updatedJsonList = jsonList.map((jsonItem) {
            if (notificationIds.contains(jsonItem['id']) && jsonItem['is_read'] == false) {
              updatedCount++;
              return {...jsonItem, 'is_read': true};
            }
            return jsonItem;
          }).toList();
          
          if (updatedCount > 0) {
            await sharedPreferences.setString(key, json.encode(updatedJsonList));
            updated = true;
            
            // Update unread count
            final parts = key.split('_');
            if (parts.length >= 4) {
              final userId = parts[2];
              final mode = parts[3];
              final unreadCountKey = _getUnreadCountCacheKey(userId, mode);
              final currentCount = int.tryParse(sharedPreferences.getString(unreadCountKey) ?? '0') ?? 0;
              
              if (currentCount > 0) {
                final newCount = (currentCount - updatedCount) < 0 ? 0 : (currentCount - updatedCount);
                await sharedPreferences.setString(unreadCountKey, newCount.toString());
              }
            }
            
            logger.i('LocalDataSource: Berhasil memperbarui $updatedCount notifikasi di cache');
          }
        } catch (e) {
          logger.e('LocalDataSource: Error saat memperbarui batch notifikasi: $e');
        }
      }
    }
    
    return updated;
  }
  
  @override
  Future<bool> markAllNotificationsAsRead(String userId, {String mode = 'both'}) async {
    logger.i('LocalDataSource: Menandai semua notifikasi sebagai dibaca untuk user $userId dengan mode $mode');
    final key = _getNotificationsCacheKey(userId, mode);
    final jsonString = sharedPreferences.getString(key);
    
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        bool hasUnreadNotifications = false;
        
        final updatedJsonList = jsonList.map((jsonItem) {
          if (jsonItem['is_read'] == false) {
            hasUnreadNotifications = true;
            return {...jsonItem, 'is_read': true};
          }
          return jsonItem;
        }).toList();
        
        if (hasUnreadNotifications) {
          await sharedPreferences.setString(key, json.encode(updatedJsonList));
          await sharedPreferences.setString(_getUnreadCountCacheKey(userId, mode), '0');
          logger.i('LocalDataSource: Berhasil menandai semua notifikasi sebagai dibaca di cache');
          return true;
        }
        return false;
      } catch (e) {
        logger.e('LocalDataSource: Error saat menandai semua notifikasi sebagai dibaca: $e');
        return false;
      }
    } else {
      logger.w('LocalDataSource: Tidak ada data notifikasi dalam cache untuk ditandai sebagai dibaca');
      return false;
    }
  }
}
