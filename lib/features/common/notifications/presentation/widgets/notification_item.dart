import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart' as notification_entity;
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:klik_jasa/features/common/notifications/presentation/widgets/base_notification_item.dart';

class NotificationItem extends StatefulWidget {
  final notification_entity.Notification notification;
  final VoidCallback onTap;
  final VoidCallback onMarkAsRead;

  const NotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onMarkAsRead,
  });

  @override
  State<NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Jika notifikasi belum dibaca, jalankan animasi pulse
    if (!widget.notification.isRead) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(NotificationItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Jika status notifikasi berubah dari belum dibaca menjadi dibaca
    // hentikan animasi pulse
    if (!oldWidget.notification.isRead && widget.notification.isRead) {
      _animationController.stop();
      // Tambahkan animasi transisi halus saat notifikasi ditandai sebagai dibaca
      _animationController.forward(from: 0.0).then((_) => _animationController.reverse());
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Slidable(
      key: ValueKey(widget.notification.id), // Ensure Slidable updates correctly
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        extentRatio: 0.25, // Adjust if needed
        children: [
          SlidableAction(
            onPressed: (_) => widget.onMarkAsRead(),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            icon: Icons.check_circle_outline,
            label: 'Dibaca',
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ), // Match BaseNotificationItem's borderRadius if needed
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          // Apply scale animation only if not read
          return Transform.scale(
            scale: !widget.notification.isRead ? _scaleAnimation.value : 1.0,
            child: child,
          );
        },
        child: BaseNotificationItem(
          notification: widget.notification,
          onTap: widget.onTap,
          backgroundColor: widget.notification.isRead 
              ? theme.canvasColor 
              : AppColors.primaryLight.withAlpha((0.05 * 255).round()), // Adjusted opacity for subtlety
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12), // Adjusted padding
          boxShadow: widget.notification.isRead 
              ? null 
              : [
                  BoxShadow(
                    color: AppColors.primary.withAlpha((0.08 * 255).round()),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
          // showUnreadDotIndicator is true by default in BaseNotificationItem
        ),
      ),
    );
  }
}
