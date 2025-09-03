import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class GetUnreadCount implements UseCase<int, GetUnreadCountParams> {
  final NotificationRepository repository;

  GetUnreadCount(this.repository);

  @override
  Future<Either<Failure, int>> call(GetUnreadCountParams params) async {
    return await repository.getUnreadCount(params.userId, mode: params.mode);
  }
}

class GetUnreadCountParams extends Equatable {
  final String userId;
  final String mode;

  const GetUnreadCountParams({required this.userId, this.mode = 'both'});

  @override
  List<Object?> get props => [userId, mode];
}
