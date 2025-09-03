import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class MarkAllAsRead implements UseCase<bool, MarkAllAsReadParams> {
  final NotificationRepository repository;

  MarkAllAsRead(this.repository);

  @override
  Future<Either<Failure, bool>> call(MarkAllAsReadParams params) async {
    return await repository.markAllAsRead(params.userId, mode: params.mode);
  }
}

class MarkAllAsReadParams extends Equatable {
  final String userId;
  final String mode;

  const MarkAllAsReadParams({required this.userId, this.mode = 'both'});

  @override
  List<Object?> get props => [userId, mode];
}
