import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_bloc.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_event.dart';
import 'package:klik_jasa/features/common/notifications/presentation/bloc/notification_state.dart';

class NotificationBadgeIcon extends StatefulWidget {
  final String userId;
  final VoidCallback onTap;

  const NotificationBadgeIcon({
    super.key,
    required this.userId,
    required this.onTap,
  });

  @override
  State<NotificationBadgeIcon> createState() => _NotificationBadgeIconState();
}

class _NotificationBadgeIconState extends State<NotificationBadgeIcon> {
  @override
  void initState() {
    super.initState();
    // Memicu event untuk mendapatkan jumlah notifikasi yang belum dibaca saat widget dimuat
    _fetchNotifications();
    
    // Jadwalkan pembaruan berkala untuk badge notifikasi
    _schedulePeriodicUpdates();
  }
  
  // Timer untuk pembaruan berkala
  Timer? _updateTimer;
  
  void _schedulePeriodicUpdates() {
    // Perbarui notifikasi setiap 30 detik
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _fetchNotifications(silent: true);
      }
    });
  }
  
  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _fetchNotifications({bool silent = false}) {
    // Cek apakah state saat ini belum dimuat atau sudah lebih dari 1 menit sejak pembaruan terakhir
    final state = context.read<NotificationBloc>().state;
    bool shouldFetch = true;
    
    if (state is NotificationsLoaded) {
      // Jika silent mode, hanya perbarui jika sudah lebih dari 5 menit sejak update terakhir
      if (silent && state.lastUpdated != null) {
        final now = DateTime.now();
        final diff = now.difference(state.lastUpdated!);
        if (diff.inMinutes < 5) {
          shouldFetch = false;
        }
      }
    }

    if (shouldFetch) {
      logger.d('Memperbarui jumlah notifikasi yang belum dibaca untuk badge.');
      context.read<NotificationBloc>().add(GetNotificationsEvent(userId: widget.userId, page: 1, limit: 10));
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_outlined,
            size: 28,
          ),
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              int count = 0;
              if (state is NotificationsLoaded) {
                count = state.unreadCount;
              } else if (state is NotificationLoading && state.notifications.isNotEmpty) {
                count = state.notifications.where((n) => !n.isRead).length;
              }

              if (count == 0) {
                return const SizedBox.shrink();
              }

              return Positioned(
                top: -5,
                right: -5,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    count > 9 ? '9+' : count.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
