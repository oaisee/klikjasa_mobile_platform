import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:klik_jasa/features/common/auth/application/bloc/auth_bloc.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_bloc.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_event.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_state.dart';
import 'package:klik_jasa/injection_container.dart' as di;

class NotificationBellWidget extends StatefulWidget {
  const NotificationBellWidget({super.key});

  @override
  State<NotificationBellWidget> createState() => _NotificationBellWidgetState();
}

class _NotificationBellWidgetState extends State<NotificationBellWidget> {
  late NotificationBloc _notificationBloc;
  UserEntity? _currentUser;

  @override
  void initState() {
    super.initState();
    _notificationBloc = di.sl<NotificationBloc>();
    _getCurrentUser();
  }

  @override
  void dispose() {
    // Tutup bloc untuk mencegah memory leak dan widget lifecycle issues
    _notificationBloc.close();
    super.dispose();
  }

  void _getCurrentUser() {
    final authState = BlocProvider.of<AuthBloc>(context).state;
    if (authState is AuthAuthenticated) {
      _currentUser = authState.user;
      if (_currentUser != null) {
        _notificationBloc.add(GetNotificationsEvent(userId: _currentUser!.id, page: 1, limit: 10));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => _notificationBloc,
      child: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          int unreadCount = 0;
          if (state is NotificationsLoaded) {
            unreadCount = state.unreadCount;
          } else if (state is NotificationLoading && state.notifications.isNotEmpty) {
            // Show previous count while loading
            unreadCount = state.notifications.where((n) => !n.isRead).length;
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white),
                onPressed: () {
                  final authState = context.read<AuthBloc>().state;
                  if (authState is AuthAuthenticated) {
                    context.goNamed('userNotifications');
                  } else {
                    // Handle guest user case, e.g., show login screen
                    context.goNamed('login');
                  }
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
