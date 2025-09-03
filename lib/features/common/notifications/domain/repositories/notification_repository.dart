import 'package:dartz/dartz.dart' hide Order;
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';


abstract class NotificationRepository {
  /// Mendapatkan daftar notifikasi untuk pengguna tertentu dengan mode tertentu
  /// Mode bisa 'user', 'provider', atau 'both'
  /// Parameter page dan limit untuk pagination
  Future<Either<Failure, List<Notification>>> getNotifications(
    String userId, {
    String mode = 'both',
    int page = 1,
    int limit = 10,
  });

  /// Menandai notifikasi sebagai sudah dibaca
  Future<Either<Failure, bool>> markAsRead(int notificationId);

  /// Menandai beberapa notifikasi sekaligus sebagai sudah dibaca
  /// Lebih efisien daripada memanggil markAsRead untuk setiap notifikasi
  Future<Either<Failure, bool>> batchMarkAsRead(List<int> notificationIds);

  /// Menandai semua notifikasi pengguna sebagai dibaca untuk mode tertentu
  Future<Either<Failure, bool>> markAllAsRead(
    String userId, {
    String mode = 'both',
  });

  /// Mendapatkan jumlah notifikasi yang belum dibaca untuk mode tertentu
  Future<Either<Failure, int>> getUnreadCount(
    String userId, {
    String mode = 'both',
  });

  /// Membuat notifikasi baru dengan mode tertentu
  /// Mode bisa 'user', 'provider', atau 'both'
  Future<Either<Failure, int>> createNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String? type,
    String? relatedEntityType,
    String? relatedEntityId,
    String mode = 'both',
  });


}
