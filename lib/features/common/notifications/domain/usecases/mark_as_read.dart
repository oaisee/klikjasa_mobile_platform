import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class MarkAsRead implements UseCase<bool, MarkAsReadParams> {
  final NotificationRepository repository;

  MarkAsRead(this.repository);

  @override
  Future<Either<Failure, bool>> call(MarkAsReadParams params) async {
    return await repository.markAsRead(params.notificationId);
  }
}

class MarkAsReadParams extends Equatable {
  final int notificationId;

  const MarkAsReadParams({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}
