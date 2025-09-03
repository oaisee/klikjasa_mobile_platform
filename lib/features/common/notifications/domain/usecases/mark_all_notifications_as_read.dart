import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class MarkAllNotificationsAsRead implements UseCase<void, MarkAllNotificationsAsReadParams> {
  final NotificationRepository repository;

  MarkAllNotificationsAsRead(this.repository);

  @override
  Future<Either<Failure, bool>> call(MarkAllNotificationsAsReadParams params) async {
    return await repository.markAllAsRead(params.userId);
  }
}

class MarkAllNotificationsAsReadParams extends Equatable {
  final String userId;

  const MarkAllNotificationsAsReadParams({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}
