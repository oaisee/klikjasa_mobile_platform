import 'package:flutter/material.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart'
    as notification_entity;
import 'package:klik_jasa/features/common/notifications/presentation/widgets/formatted_date_text_widget.dart';
import 'package:klik_jasa/features/common/notifications/presentation/widgets/notification_icon_widget.dart';
import 'package:klik_jasa/features/common/notifications/presentation/widgets/notification_status_chip_widget.dart';

class BaseNotificationItem extends StatelessWidget {
  final notification_entity.Notification notification;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final Border? border;
  final bool showUnreadDotIndicator;
  final Widget? trailingWidget; // Untuk aksi seperti Slidable atau Checkbox
  final EdgeInsetsGeometry? padding;
  final BorderRadiusGeometry? borderRadius;

  const BaseNotificationItem({
    super.key,
    required this.notification,
    this.onTap,
    this.onLongPress,
    this.backgroundColor,
    this.boxShadow,
    this.border,
    this.showUnreadDotIndicator = true,
    this.trailingWidget,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isUnread = !notification.isRead;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius as BorderRadius?,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              (isUnread
                  ? theme.primaryColor.withAlpha((0.05 * 255).round())
                  : theme.canvasColor),
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          border: border,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                NotificationIconWidget(
                  notificationType: notification.type.value,
                  isRead: notification.isRead,
                ),
                if (isUnread && showUnreadDotIndicator)
                  Positioned(
                    top: -3,
                    right: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).canvasColor,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.circle, size: 6, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: isUnread
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isUnread
                          ? theme.textTheme.bodyLarge?.color
                          : theme.textTheme.bodyMedium?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isUnread
                          ? theme.textTheme.bodyMedium?.color
                          : theme.textTheme.bodySmall?.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      FormattedDateTextWidget(
                        date: notification.createdAt,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isUnread)
                        NotificationStatusChipWidget(
                          notificationType: notification.type.value,
                          isRead: notification.isRead,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (trailingWidget != null) ...[
              const SizedBox(width: 8),
              trailingWidget!,
            ],
          ],
        ),
      ),
    );
  }
}
