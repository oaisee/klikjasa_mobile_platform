import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/network/network_info.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/data/datasources/notification_local_data_source.dart';
import 'package:klik_jasa/features/common/notifications/data/datasources/notification_remote_data_source.dart';
import 'package:klik_jasa/features/common/notifications/data/models/notification_model.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;
  final NotificationLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  NotificationRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Notification>>> getNotifications(
    String userId, {
    String mode = 'both',
    int page = 1,
    int limit = 10,
  }) async {
    logger.i(
      'Repository: Mengambil notifikasi untuk user $userId dengan mode $mode, halaman $page, limit $limit',
    );
    if (await networkInfo.isConnected) {
      try {
        final notificationModels = await remoteDataSource.getNotifications(
          userId,
          mode: mode,
          page: page,
          limit: limit,
        );
        logger.i(
          'Repository: Berhasil mengambil ${notificationModels.length} notifikasi dari server (halaman $page)',
        );

        // Cache notifikasi yang baru diambil jika ini adalah halaman pertama
        // Untuk halaman selanjutnya, kita tidak meng-cache karena akan menimpa data yang sudah ada
        if (page == 1) {
          await localDataSource.cacheNotifications(
            notificationModels,
            userId,
            mode: mode,
          );
          logger.i('Repository: Notifikasi halaman pertama di-cache');
        }

        return Right(notificationModels.toEntityList());
      } on ServerException catch (e) {
        logger.e(
          'Repository: Error server saat mengambil notifikasi: ${e.message}',
        );

        // Coba ambil dari cache jika server error dan ini adalah halaman pertama
        if (page == 1) {
          logger.i('Repository: Mencoba mengambil notifikasi dari cache');
          try {
            final cachedNotifications = await localDataSource
                .getCachedNotifications(userId, mode: mode);
            logger.i(
              'Repository: Berhasil mengambil ${cachedNotifications.length} notifikasi dari cache',
            );
            return Right(cachedNotifications.toEntityList());
          } on CacheException {
            logger.w('Repository: Tidak ada data notifikasi dalam cache');
            return Left(ServerFailure(message: 'Terjadi kesalahan server'));
          }
        } else {
          // Untuk halaman selanjutnya, jika gagal, kita tidak bisa menggunakan cache
          return Left(
            ServerFailure(message: 'Gagal memuat notifikasi tambahan'),
          );
        }
      } catch (e) {
        logger.e(
          'Repository: Error tidak terduga saat mengambil notifikasi: $e',
        );
        return Left(
          ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'),
        );
      }
    } else {
      logger.w(
        'Repository: Tidak ada koneksi internet, mencoba mengambil dari cache',
      );

      // Jika offline, kita hanya bisa mengembalikan cache untuk halaman pertama
      if (page == 1) {
        try {
          final cachedNotifications = await localDataSource
              .getCachedNotifications(userId, mode: mode);
          logger.i(
            'Repository: Berhasil mengambil ${cachedNotifications.length} notifikasi dari cache',
          );
          return Right(cachedNotifications.toEntityList());
        } on CacheException {
          logger.w('Repository: Tidak ada data notifikasi dalam cache');
          return Left(
            NetworkFailure(
              message: 'Tidak ada koneksi internet dan tidak ada data cache',
            ),
          );
        }
      } else {
        // Untuk halaman selanjutnya, jika offline, kita tidak bisa memuat lebih banyak data
        return Left(
          NetworkFailure(
            message:
                'Tidak ada koneksi internet untuk memuat lebih banyak notifikasi',
          ),
        );
      }
    }
  }

  @override
  Future<Either<Failure, bool>> markAsRead(int notificationId) async {
    logger.i('Repository: Menandai notifikasi $notificationId sebagai dibaca');
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.markAsRead(notificationId);
        logger.i(
          'Repository: Berhasil menandai notifikasi $notificationId sebagai dibaca di server',
        );

        // Update juga di cache
        await localDataSource.updateNotificationReadStatus(
          notificationId,
          true,
        );
        logger.i('Repository: Status notifikasi juga diperbarui di cache');

        return Right(result);
      } on ServerException catch (e) {
        logger.e(
          'Repository: Error server saat menandai notifikasi sebagai dibaca: ${e.message}',
        );
        return Left(ServerFailure(message: 'Terjadi kesalahan server'));
      } catch (e) {
        logger.e(
          'Repository: Error tidak terduga saat menandai notifikasi sebagai dibaca: $e',
        );
        return Left(
          ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'),
        );
      }
    } else {
      logger.w(
        'Repository: Tidak ada koneksi internet, mencoba update di cache saja',
      );
      try {
        // Update di cache saja, akan disinkronkan ke server saat online
        final result = await localDataSource.updateNotificationReadStatus(
          notificationId,
          true,
        );
        if (result) {
          logger.i(
            'Repository: Berhasil menandai notifikasi sebagai dibaca di cache',
          );
          return Right(true);
        } else {
          logger.w(
            'Repository: Gagal menandai notifikasi sebagai dibaca di cache',
          );
          return Left(CacheFailure(message: 'Gagal memperbarui cache'));
        }
      } catch (e) {
        logger.e('Repository: Error saat mencoba update cache: $e');
        return Left(CacheFailure(message: 'Gagal memperbarui cache'));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> batchMarkAsRead(
    List<int> notificationIds,
  ) async {
    logger.i(
      'Repository: Menandai ${notificationIds.length} notifikasi sebagai dibaca secara batch',
    );
    if (notificationIds.isEmpty) {
      return const Right(true); // Tidak ada yang perlu ditandai
    }

    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.batchMarkAsRead(notificationIds);
        logger.i(
          'Repository: Berhasil menandai ${notificationIds.length} notifikasi sebagai dibaca secara batch',
        );

        // Update juga di cache
        await localDataSource.batchMarkNotificationsAsRead(notificationIds);

        return Right(result);
      } on ServerException catch (e) {
        logger.e(
          'Repository: Error server saat menandai batch notifikasi sebagai dibaca: ${e.message}',
        );
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e(
          'Repository: Error tidak terduga saat menandai batch notifikasi sebagai dibaca: $e',
        );
        return Left(
          ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'),
        );
      }
    } else {
      logger.w(
        'Repository: Tidak ada koneksi internet, mencoba update batch di cache saja',
      );
      try {
        // Update di cache saja, akan disinkronkan ke server saat online
        final result = await localDataSource.batchMarkNotificationsAsRead(
          notificationIds,
        );
        if (result) {
          logger.i(
            'Repository: Berhasil menandai ${notificationIds.length} notifikasi sebagai dibaca di cache',
          );
          // TODO: Tambahkan ke antrian sinkronisasi
          return Right(true);
        } else {
          logger.w(
            'Repository: Gagal menandai batch notifikasi sebagai dibaca di cache',
          );
          return Left(CacheFailure(message: 'Gagal memperbarui cache'));
        }
      } catch (e) {
        logger.e('Repository: Error saat mencoba update batch di cache: $e');
        return Left(CacheFailure(message: 'Gagal memperbarui cache'));
      }
    }
  }

  @override
  Future<Either<Failure, bool>> markAllAsRead(
    String userId, {
    String mode = 'both',
  }) async {
    logger.i(
      'Repository: Menandai semua notifikasi user $userId dengan mode $mode sebagai dibaca',
    );
    if (await networkInfo.isConnected) {
      try {
        final result = await remoteDataSource.markAllAsRead(userId, mode: mode);
        logger.i(
          'Repository: Berhasil menandai semua notifikasi sebagai dibaca di server',
        );

        // Update juga di cache
        await localDataSource.markAllNotificationsAsRead(userId, mode: mode);
        // Reset unread count di cache
        await localDataSource.cacheUnreadCount(0, userId, mode: mode);
        logger.i(
          'Repository: Semua notifikasi juga ditandai sebagai dibaca di cache',
        );

        return Right(result);
      } on ServerException catch (e) {
        logger.e(
          'Repository: Error server saat menandai semua notifikasi sebagai dibaca: ${e.message}',
        );
        return Left(ServerFailure(message: 'Terjadi kesalahan server'));
      } catch (e) {
        logger.e(
          'Repository: Error tidak terduga saat menandai semua notifikasi sebagai dibaca: $e',
        );
        return Left(
          ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'),
        );
      }
    } else {
      logger.w(
        'Repository: Tidak ada koneksi internet, mencoba update di cache saja',
      );
      try {
        // Update di cache saja, akan disinkronkan ke server saat online
        final result = await localDataSource.markAllNotificationsAsRead(
          userId,
          mode: mode,
        );
        if (result) {
          logger.i(
            'Repository: Berhasil menandai semua notifikasi sebagai dibaca di cache',
          );
          return Right(true);
        } else {
          logger.w(
            'Repository: Gagal menandai semua notifikasi sebagai dibaca di cache',
          );
          return Left(CacheFailure(message: 'Gagal memperbarui cache'));
        }
      } catch (e) {
        logger.e('Repository: Error saat mencoba update cache: $e');
        return Left(CacheFailure(message: 'Gagal memperbarui cache'));
      }
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(
    String userId, {
    String mode = 'both',
  }) async {
    logger.i(
      'Repository: Menghitung jumlah notifikasi yang belum dibaca untuk user $userId dengan mode $mode',
    );
    if (await networkInfo.isConnected) {
      try {
        final count = await remoteDataSource.getUnreadCount(userId, mode: mode);
        logger.i(
          'Repository: Jumlah notifikasi yang belum dibaca dari server: $count',
        );

        // Cache jumlah notifikasi yang belum dibaca
        await localDataSource.cacheUnreadCount(count, userId, mode: mode);

        return Right(count);
      } on ServerException catch (e) {
        logger.e(
          'Repository: Error server saat menghitung notifikasi yang belum dibaca: ${e.message}',
        );

        // Coba ambil dari cache jika server error
        logger.i('Repository: Mencoba mengambil jumlah notifikasi dari cache');
        final cachedCount = await localDataSource.getCachedUnreadCount(
          userId,
          mode: mode,
        );
        logger.i(
          'Repository: Jumlah notifikasi yang belum dibaca dari cache: $cachedCount',
        );
        return Right(cachedCount);
      } catch (e) {
        logger.e(
          'Repository: Error tidak terduga saat menghitung notifikasi yang belum dibaca: $e',
        );
        return Left(
          ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'),
        );
      }
    } else {
      logger.w(
        'Repository: Tidak ada koneksi internet, mencoba mengambil dari cache',
      );
      final cachedCount = await localDataSource.getCachedUnreadCount(
        userId,
        mode: mode,
      );
      logger.i(
        'Repository: Jumlah notifikasi yang belum dibaca dari cache: $cachedCount',
      );
      return Right(cachedCount);
    }
  }

  @override
  Future<Either<Failure, int>> createNotification({
    required String recipientUserId,
    required String title,
    required String body,
    String? type,
    String? relatedEntityType,
    String? relatedEntityId,
    String mode = 'both',
  }) async {
    logger.i(
      'Repository: Membuat notifikasi baru untuk user $recipientUserId dengan judul "$title"',
    );
    if (await networkInfo.isConnected) {
      try {
        final notificationId = await remoteDataSource.createNotification(
          recipientUserId: recipientUserId,
          title: title,
          body: body,
          type: type,
          relatedEntityType: relatedEntityType,
          relatedEntityId: relatedEntityId,
          mode: mode,
        );
        logger.i(
          'Repository: Berhasil membuat notifikasi dengan ID $notificationId',
        );
        return Right(notificationId);
      } on ServerException catch (e) {
        logger.e(
          'Repository: Error server saat membuat notifikasi: ${e.message}',
        );
        return Left(ServerFailure(message: e.message));
      } catch (e) {
        logger.e('Repository: Error tidak terduga saat membuat notifikasi: $e');
        return Left(
          ServerFailure(message: 'Terjadi kesalahan: ${e.toString()}'),
        );
      }
    } else {
      logger.w(
        'Repository: Tidak ada koneksi internet saat mencoba membuat notifikasi',
      );
      return Left(NetworkFailure(message: 'Tidak ada koneksi internet'));
    }
  }
}
