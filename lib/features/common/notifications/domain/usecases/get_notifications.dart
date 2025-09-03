import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class GetNotifications implements UseCase<List<Notification>, GetNotificationsParams> {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  @override
  Future<Either<Failure, List<Notification>>> call(GetNotificationsParams params) async {
    return await repository.getNotifications(
      params.userId, 
      page: params.page,
      limit: params.limit,
    );
  }
}

class GetNotificationsParams extends Equatable {
  final String userId;

  final int page;
  final int limit;

  const GetNotificationsParams({
    required this.userId, 

    this.page = 1,
    this.limit = 10,
  });

  @override
  List<Object?> get props => [userId, page, limit];
}
