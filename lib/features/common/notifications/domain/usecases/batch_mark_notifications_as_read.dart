import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

/// Use case untuk menandai beberapa notifikasi sekaligus sebagai sudah dibaca
/// Ini lebih efisien daripada memanggil markAsRead untuk setiap notifikasi
class BatchMarkNotificationsAsRead implements UseCase<bool, BatchMarkNotificationsAsReadParams> {
  final NotificationRepository repository;

  BatchMarkNotificationsAsRead(this.repository);

  @override
  Future<Either<Failure, bool>> call(BatchMarkNotificationsAsReadParams params) async {
    return await repository.batchMarkAsRead(params.notificationIds);
  }
}

class BatchMarkNotificationsAsReadParams extends Equatable {
  final List<int> notificationIds;

  const BatchMarkNotificationsAsReadParams({
    required this.notificationIds,
  });

  @override
  List<Object?> get props => [notificationIds];
}
