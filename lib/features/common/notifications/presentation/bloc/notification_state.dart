import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';

abstract class NotificationState extends Equatable {
  final List<Notification> notifications;

  const NotificationState({this.notifications = const []});

  @override
  List<Object?> get props => [notifications];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial() : super(notifications: const []);
}

class NotificationLoading extends NotificationState {
  const NotificationLoading({super.notifications});
}

class NotificationsLoaded extends NotificationState {
  final int currentPage;
  final int totalPages;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final int unreadCount;
  final DateTime? lastUpdated; // Tambahkan properti untuk melacak waktu pembaruan terakhir

  const NotificationsLoaded({
    required super.notifications,
    this.currentPage = 1,
    this.totalPages = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.unreadCount = 0,
    this.lastUpdated,
  });

  NotificationsLoaded copyWith({
    List<Notification>? notifications,
    int? currentPage,
    int? totalPages,
    bool? hasReachedMax,
    bool? isLoadingMore,
    int? unreadCount,
    DateTime? lastUpdated,
  }) {
    return NotificationsLoaded(
      notifications: notifications ?? this.notifications,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadCount: unreadCount ?? this.unreadCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        notifications,
        currentPage,
        totalPages,
        hasReachedMax,
        isLoadingMore,
        unreadCount,
      ];
}




class NotificationError extends NotificationState {
  final String message;

  const NotificationError({
    required this.message,
    super.notifications,
  });

  @override
  List<Object?> get props => [message, notifications];
}
