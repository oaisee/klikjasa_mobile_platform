import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class MarkNotificationAsRead implements UseCase<void, MarkNotificationAsReadParams> {
  final NotificationRepository repository;

  MarkNotificationAsRead(this.repository);

  @override
  Future<Either<Failure, bool>> call(MarkNotificationAsReadParams params) async {
    return await repository.markAsRead(params.notificationId);
  }
}

class MarkNotificationAsReadParams extends Equatable {
  final int notificationId;

  const MarkNotificationAsReadParams({
    required this.notificationId,
  });

  @override
  List<Object?> get props => [notificationId];
}
