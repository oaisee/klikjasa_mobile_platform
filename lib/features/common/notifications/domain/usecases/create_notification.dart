import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/notifications/domain/repositories/notification_repository.dart';

class CreateNotification implements UseCase<int, CreateNotificationParams> {
  final NotificationRepository repository;

  CreateNotification(this.repository);

  @override
  Future<Either<Failure, int>> call(CreateNotificationParams params) async {
    return await repository.createNotification(
      recipientUserId: params.recipientUserId,
      title: params.title,
      body: params.body,
      type: params.type,
      relatedEntityType: params.relatedEntityType,
      relatedEntityId: params.relatedEntityId,
      mode: params.mode
    );
  }
}

class CreateNotificationParams extends Equatable {
  final String recipientUserId;
  final String title;
  final String body;
  final String? type;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final String mode;

  const CreateNotificationParams({
    required this.recipientUserId,
    required this.title,
    required this.body,
    this.type,
    this.relatedEntityType,
    this.relatedEntityId,
    this.mode = 'both'
  });

  @override
  List<Object?> get props => [
    recipientUserId, 
    title, 
    body, 
    type, 
    relatedEntityType, 
    relatedEntityId,
    mode
  ];
}
