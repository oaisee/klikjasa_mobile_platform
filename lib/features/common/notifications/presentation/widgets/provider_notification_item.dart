import 'package:flutter/material.dart';
import 'package:klik_jasa/core/constants/app_colors.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart' as notification_entity;
import 'package:klik_jasa/features/common/notifications/presentation/widgets/base_notification_item.dart';

class ProviderNotificationItem extends StatefulWidget {
  final notification_entity.Notification notification;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final ValueChanged<bool?>? onSelectionChanged; // Untuk checkbox
  final bool showAnimation;
  final bool isHighlighted;
  final bool isSelectionMode; // Untuk menampilkan checkbox

  const ProviderNotificationItem({
    super.key,
    required this.notification,
    required this.onTap,
    this.onLongPress,
    this.onSelectionChanged,
    this.showAnimation = false,
    this.isHighlighted = false,
    this.isSelectionMode = false,
  });

  @override
  State<ProviderNotificationItem> createState() => _ProviderNotificationItemState();
}

class _ProviderNotificationItemState extends State<ProviderNotificationItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Jika notifikasi baru dan perlu animasi, jalankan animasi pulse
    if (widget.showAnimation) {
      _animationController.repeat(reverse: true);
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isUnread = !widget.notification.isRead;

    Color itemBackgroundColor = widget.isHighlighted
        ? AppColors.primary.withAlpha((0.12 * 255).round()) // Lebih jelas saat di-highlight
        : isUnread 
            ? AppColors.primaryLight.withAlpha((0.07 * 255).round()) // Sedikit berbeda dari user mode
            : theme.canvasColor;

    Border? itemBorder = Border.all(
      color: widget.isHighlighted
          ? AppColors.primary.withAlpha((0.8 * 255).round())
          : isUnread 
              ? AppColors.primary.withAlpha((0.3 * 255).round())
              : theme.dividerColor.withAlpha((0.5 * 255).round()),
      width: widget.isHighlighted || isUnread ? 1.2 : 0.8,
    );

    List<BoxShadow>? itemBoxShadow = widget.isHighlighted || isUnread
        ? [
            BoxShadow(
              color: AppColors.primary.withAlpha((0.05 * 255).round()),
              blurRadius: 6,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ]
        : null;

    Widget? trailing;
    if (widget.isSelectionMode) {
      trailing = Checkbox(
        value: widget.isHighlighted,
        onChanged: widget.onSelectionChanged,
        activeColor: AppColors.primary,
        visualDensity: VisualDensity.compact,
        side: BorderSide(color: AppColors.primary.withAlpha((0.5 * 255).round()), width: 1.5),
      );
    }

    Widget itemContent = BaseNotificationItem(
      notification: widget.notification,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      backgroundColor: itemBackgroundColor,
      border: itemBorder,
      boxShadow: itemBoxShadow,
      trailingWidget: trailing,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      borderRadius: BorderRadius.circular(10),
      // showUnreadDotIndicator: isUnread, // Dikelola oleh BaseNotificationItem secara default
    );

    if (widget.showAnimation && isUnread) {
      return AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: itemContent,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // Memberi sedikit jarak antar item
      child: itemContent,
    );
  }
}
