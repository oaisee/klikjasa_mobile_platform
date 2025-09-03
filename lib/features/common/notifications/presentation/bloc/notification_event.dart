import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object> get props => [];
}

class GetNotificationsEvent extends NotificationEvent {
  final String userId;
  final int page;
  final int limit;
  final bool loadMore;

  const GetNotificationsEvent({
    required this.userId,

    this.page = 1,
    this.limit = 10,
    this.loadMore = false,
  });

  @override
  List<Object> get props => [userId, page, limit, loadMore];
}

class MarkAsReadEvent extends NotificationEvent {
  final int notificationId;

  const MarkAsReadEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}

class MarkAllAsReadEvent extends NotificationEvent {
  final String userId;

  const MarkAllAsReadEvent({required this.userId});

  @override
  List<Object> get props => [userId];
}

class CreateNotificationEvent extends NotificationEvent {
  final Notification notification;

  const CreateNotificationEvent({required this.notification});

  @override
  List<Object> get props => [notification];
}

// Event untuk menangani notifikasi baru yang diterima dari layanan realtime
class NotificationReceived extends NotificationEvent {
  final Notification notification;

  const NotificationReceived(this.notification);

  @override
  List<Object> get props => [notification];
}

/// Event untuk memproses batch mark-as-read yang terakumulasi
class ProcessMarkAsReadBatchEvent extends NotificationEvent {
  final List<int> notificationIds;

  const ProcessMarkAsReadBatchEvent({required this.notificationIds});

  @override
  List<Object> get props => [notificationIds];
}

