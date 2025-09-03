import 'dart:async';
import 'dart:collection';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/create_notification.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/get_notifications.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/mark_all_as_read.dart';
import 'package:klik_jasa/features/common/notifications/domain/usecases/mark_as_read.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_event.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_state.dart';
import 'package:klik_jasa/features/common/notifications/presentation/services/notification_service.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final GetNotifications getNotifications;
  final MarkAsRead markAsRead;
  final MarkAllAsRead markAllAsRead;
  final CreateNotification createNotification;
  final NotificationService _notificationService = NotificationService();
  StreamSubscription<Notification>? _notificationSubscription;

  // Batching untuk operasi mark-as-read
  final Queue<int> _markAsReadQueue = Queue<int>();
  Timer? _markAsReadBatchTimer;
  final int _batchDelayMs = 2000; // 2 detik delay untuk batching

  NotificationBloc({
    required this.getNotifications,
    required this.markAsRead,
    required this.markAllAsRead,
    required this.createNotification,
  }) : super(NotificationInitial()) {
    _subscribeToNotifications();

    on<GetNotificationsEvent>(_onGetNotifications);
    on<MarkAsReadEvent>(_onMarkAsRead);
    on<MarkAllAsReadEvent>(_onMarkAllAsRead);
    on<CreateNotificationEvent>(_onCreateNotification);
    on<ProcessMarkAsReadBatchEvent>(_onProcessMarkAsReadBatch);
    on<NotificationReceived>(_onNotificationReceived);
  }

  void _subscribeToNotifications() {
    _notificationSubscription = _notificationService.notificationStream.listen(
      (notification) {
        add(NotificationReceived(notification));
      },
      onError: (error) {
        logger.e('Error on notification stream: $error');
      },
    );
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    _cancelMarkAsReadBatch();
    return super.close();
  }

  Future<void> _onNotificationReceived(
    NotificationReceived event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final newNotification = event.notification;

      // Hindari duplikasi
      if (currentState.notifications.any((n) => n.id == newNotification.id)) {
        return;
      }

      final updatedNotifications = [newNotification, ...currentState.notifications];
      final unreadCount = updatedNotifications.where((n) => n.isRead == false).length;

      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      ));
    }
  }

  Future<void> _onGetNotifications(
    GetNotificationsEvent event,
    Emitter<NotificationState> emit,
  ) async {
    if (event.loadMore) {
      if (state is NotificationsLoaded) {
        final currentState = state as NotificationsLoaded;
        if (currentState.hasReachedMax) return;

        emit(currentState.copyWith(isLoadingMore: true));

        final result = await getNotifications(GetNotificationsParams(
            userId: event.userId, page: event.page, limit: event.limit));

        result.fold(
          (failure) {
            emit(currentState.copyWith(isLoadingMore: false));
            // Optionally show an error message
          },
          (newNotifications) {
            final allNotifications = List.of(currentState.notifications)..addAll(newNotifications);
            final hasReachedMax = newNotifications.length < event.limit;
            emit(currentState.copyWith(
              notifications: allNotifications,
              currentPage: event.page,
              hasReachedMax: hasReachedMax,
              isLoadingMore: false,
            ));
          },
        );
      }
    } else {
      emit(NotificationLoading(notifications: state.notifications));

      final result = await getNotifications(GetNotificationsParams(
        userId: event.userId,
        page: 1, // Always start from page 1 on refresh
        limit: event.limit,
      ));

      result.fold(
        (failure) {
          emit(NotificationError(message: 'Gagal memuat notifikasi', notifications: state.notifications));
        },
        (newNotifications) {
          final unreadCount = newNotifications.where((n) => !n.isRead).length;
          final hasReachedMax = newNotifications.length < event.limit;

          emit(NotificationsLoaded(
            notifications: newNotifications,
            currentPage: 1,
            hasReachedMax: hasReachedMax,
            isLoadingMore: false,
            unreadCount: unreadCount,
            lastUpdated: DateTime.now(),
          ));
        },
      );
    }
  }

  Future<void> _onMarkAsRead(
    MarkAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    _markAsReadQueue.add(event.notificationId);
    _resetMarkAsReadBatchTimer();

    if (state is NotificationsLoaded) {
      final currentState = state as NotificationsLoaded;
      final updatedNotifications = currentState.notifications.map((n) {
        if (n.id == event.notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();
      
      // Hitung ulang jumlah notifikasi yang belum dibaca
      final unreadCount = updatedNotifications.where((n) => n.isRead == false).length;
      
      // Emit state baru dengan jumlah notifikasi yang belum dibaca yang diperbarui
      emit(currentState.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
        lastUpdated: DateTime.now(),
      ));
      
      // Log untuk membantu debug
      logger.d('Notifikasi #${event.notificationId} ditandai sebagai dibaca. Sisa notifikasi belum dibaca: $unreadCount');
      
      // Segera kirim permintaan ke server untuk memperbarui status notifikasi
      // tanpa menunggu batch timer
      final result = await markAsRead(MarkAsReadParams(notificationId: event.notificationId));
      result.fold(
        (failure) => logger.e('Gagal menandai notifikasi ${event.notificationId} sebagai dibaca: ${failure.message}'),
        (_) => logger.i('Berhasil menandai notifikasi ${event.notificationId} sebagai dibaca'),
      );
    }
  }

  void _resetMarkAsReadBatchTimer() {
    _cancelMarkAsReadBatch();
    _markAsReadBatchTimer = Timer(Duration(milliseconds: _batchDelayMs), () {
      if (_markAsReadQueue.isNotEmpty) {
        final idsToProcess = _markAsReadQueue.toList();
        _markAsReadQueue.clear();
        add(ProcessMarkAsReadBatchEvent(notificationIds: idsToProcess));
      }
    });
  }

  Future<void> _onProcessMarkAsReadBatch(
    ProcessMarkAsReadBatchEvent event,
    Emitter<NotificationState> emit,
  ) async {
    logger.i('Memproses batch mark-as-read dengan ${event.notificationIds.length} notifikasi');
    for (final notificationId in event.notificationIds) {
      final result = await markAsRead(MarkAsReadParams(notificationId: notificationId));
      result.fold(
        (failure) => logger.e('Gagal menandai notifikasi $notificationId sebagai dibaca: ${failure.message}'),
        (_) => logger.i('Berhasil menandai notifikasi $notificationId sebagai dibaca'),
      );
    }
  }

  void _cancelMarkAsReadBatch() {
    _markAsReadBatchTimer?.cancel();
    _markAsReadBatchTimer = null;
  }

  Future<void> _onMarkAllAsRead(
    MarkAllAsReadEvent event,
    Emitter<NotificationState> emit,
  ) async {
    _markAsReadQueue.clear();
    _cancelMarkAsReadBatch();

    final result = await markAllAsRead(MarkAllAsReadParams(userId: event.userId));
    result.fold(
      (failure) => emit(NotificationError(message: 'Gagal menandai semua notifikasi sebagai dibaca', notifications: state.notifications)),
      (_) {
        if (state is NotificationsLoaded) {
          final currentState = state as NotificationsLoaded;
          final updatedNotifications = currentState.notifications
              .map((notification) => notification.copyWith(isRead: true))
              .toList();
          emit(currentState.copyWith(notifications: updatedNotifications, unreadCount: 0));
        } else {
          add(GetNotificationsEvent(userId: event.userId, page: 1, limit: 10));
        }
      },
    );
  }

  Future<void> _onCreateNotification(
    CreateNotificationEvent event,
    Emitter<NotificationState> emit,
  ) async {
    final result = await createNotification(CreateNotificationParams(
      recipientUserId: event.notification.recipientUserId,
      title: event.notification.title,
      body: event.notification.body,
      type: event.notification.type.value,
      relatedEntityType: event.notification.relatedEntityType,
      relatedEntityId: event.notification.relatedEntityId,
      // 'mode' akan menggunakan nilai default 'both' dari use case
    ));
    result.fold(
      (failure) => logger.e('Gagal membuat notifikasi: ${failure.message}'),
      (notification) {
        // Tidak perlu refresh, karena realtime akan menangani
        logger.i('Notifikasi berhasil dibuat, akan diterima melalui stream.');
      },
    );
  }
}
