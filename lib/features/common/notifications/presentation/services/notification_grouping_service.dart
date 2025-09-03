import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/notification.dart';
import '../../domain/entities/notification_type.dart';

class NotificationGroup {
  final String id;
  final NotificationType type;
  final String title;
  final List<Notification> notifications;
  final DateTime lastUpdated;
  final int maxSize;

  const NotificationGroup({
    required this.id,
    required this.type,
    required this.title,
    required this.notifications,
    required this.lastUpdated,
    this.maxSize = 5,
  });

  NotificationGroup copyWith({
    String? id,
    NotificationType? type,
    String? title,
    List<Notification>? notifications,
    DateTime? lastUpdated,
    int? maxSize,
  }) {
    return NotificationGroup(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      notifications: notifications ?? this.notifications,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      maxSize: maxSize ?? this.maxSize,
    );
  }

  bool get isFull => notifications.length >= maxSize;
  
  String get summaryText {
    if (notifications.isEmpty) return '';
    if (notifications.length == 1) return notifications.first.body;
    
    switch (type) {
      case NotificationType.chatMessage:
        return '${notifications.length} pesan baru';
      case NotificationType.orderCreated:
        return '${notifications.length} pesanan baru';
      case NotificationType.orderAccepted:
        return '${notifications.length} pesanan diterima';
      case NotificationType.orderCompleted:
        return '${notifications.length} pesanan selesai';
      case NotificationType.balanceUpdated:
        return '${notifications.length} update saldo';
      case NotificationType.promotion:
        return '${notifications.length} promosi baru';
      default:
        return '${notifications.length} notifikasi ${type.displayName.toLowerCase()}';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'notifications': notifications.map((n) => {
        'id': n.id,
        'title': n.title,
        'body': n.body,
        'createdAt': n.createdAt.toIso8601String(),
      }).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'maxSize': maxSize,
    };
  }
}

class NotificationAction {
  final String id;
  final String title;
  final String? icon;
  final bool requiresAuth;
  final Map<String, dynamic> data;

  const NotificationAction({
    required this.id,
    required this.title,
    this.icon,
    this.requiresAuth = false,
    this.data = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'icon': icon,
      'requiresAuth': requiresAuth,
      'data': data,
    };
  }
}

class RichNotificationData {
  final String title;
  final String body;
  final String? imageUrl;
  final String? largeIcon;
  final List<NotificationAction> actions;
  final Map<String, dynamic> customData;
  final String? sound;
  final bool enableVibration;
  final String? channelId;
  final NotificationImportance importance;
  final NotificationPriority priority;

  const RichNotificationData({
    required this.title,
    required this.body,
    this.imageUrl,
    this.largeIcon,
    this.actions = const [],
    this.customData = const {},
    this.sound,
    this.enableVibration = true,
    this.channelId,
    this.importance = NotificationImportance.defaultImportance,
    this.priority = NotificationPriority.defaultPriority,
  });
}

enum NotificationImportance {
  min,
  low,
  defaultImportance,
  high,
  max,
}

enum NotificationPriority {
  min,
  low,
  defaultPriority,
  high,
  max,
}

class NotificationGroupingService {
  static const Duration _groupingWindow = Duration(minutes: 5);
  static const int _maxGroupSize = 5;
  
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Logger _logger = Logger();
  final Map<String, NotificationGroup> _activeGroups = {};
  
  NotificationGroupingService(this._localNotifications);

  /// Process notification for grouping
  Future<void> processNotification(Notification notification) async {
    try {
      final groupKey = _getGroupKey(notification);
      
      if (groupKey != null && _shouldGroup(notification.type)) {
        await _addToGroup(groupKey, notification);
      } else {
        await _showIndividualNotification(notification);
      }
    } catch (e) {
      _logger.e('Failed to process notification for grouping', error: e);
      // Fallback to individual notification
      await _showIndividualNotification(notification);
    }
  }

  /// Check if notification type should be grouped
  bool _shouldGroup(NotificationType type) {
    switch (type) {
      case NotificationType.chatMessage:
      case NotificationType.orderCreated:
      case NotificationType.orderAccepted:
      case NotificationType.orderCompleted:
      case NotificationType.balanceUpdated:
      case NotificationType.promotion:
        return true;
      case NotificationType.orderCancelled:
      case NotificationType.providerVerified:
      case NotificationType.systemAlert:
        return false;
    }
  }

  /// Get group key for notification
  String? _getGroupKey(Notification notification) {
    switch (notification.type) {
      case NotificationType.chatMessage:
        // Group by chat/conversation
        return 'chat_${notification.relatedEntityId ?? 'general'}';
      case NotificationType.orderCreated:
      case NotificationType.orderAccepted:
      case NotificationType.orderCompleted:
        // Group by order type
        return 'orders_${notification.type.value}';
      case NotificationType.balanceUpdated:
        return 'balance_updates';
      case NotificationType.promotion:
        return 'promotions';
      default:
        return null;
    }
  }

  /// Add notification to group
  Future<void> _addToGroup(String groupKey, Notification notification) async {
    final existingGroup = _activeGroups[groupKey];
    
    if (existingGroup == null) {
      // Create new group
      final group = NotificationGroup(
        id: groupKey,
        type: notification.type,
        title: _getGroupTitle(notification.type),
        notifications: [notification],
        lastUpdated: DateTime.now(),
        maxSize: _maxGroupSize,
      );
      
      _activeGroups[groupKey] = group;
      await _showGroupedNotification(group);
    } else {
      // Add to existing group
      final updatedNotifications = List<Notification>.from(existingGroup.notifications);
      
      // Remove oldest if group is full
      if (existingGroup.isFull) {
        updatedNotifications.removeAt(0);
      }
      
      updatedNotifications.add(notification);
      
      final updatedGroup = existingGroup.copyWith(
        notifications: updatedNotifications,
        lastUpdated: DateTime.now(),
      );
      
      _activeGroups[groupKey] = updatedGroup;
      await _showGroupedNotification(updatedGroup);
    }
    
    // Clean up old groups
    await _cleanupOldGroups();
  }

  /// Show grouped notification
  Future<void> _showGroupedNotification(NotificationGroup group) async {
    try {
      final richData = _createRichNotificationForGroup(group);
      await _showRichNotification(
        id: group.id.hashCode,
        richData: richData,
        payload: jsonEncode({
          'type': 'group',
          'groupId': group.id,
          'notificationIds': group.notifications.map((n) => n.id).toList(),
        }),
      );
    } catch (e) {
      _logger.e('Failed to show grouped notification', error: e);
    }
  }

  /// Show individual notification
  Future<void> _showIndividualNotification(Notification notification) async {
    try {
      final richData = _createRichNotificationForIndividual(notification);
      await _showRichNotification(
        id: notification.id,
        richData: richData,
        payload: jsonEncode({
          'type': 'individual',
          'notificationId': notification.id,
          'relatedEntityType': notification.relatedEntityType,
          'relatedEntityId': notification.relatedEntityId,
        }),
      );
    } catch (e) {
      _logger.e('Failed to show individual notification', error: e);
    }
  }

  /// Create rich notification data for group
  RichNotificationData _createRichNotificationForGroup(NotificationGroup group) {
    final actions = _getActionsForType(group.type, isGroup: true);
    
    return RichNotificationData(
      title: group.title,
      body: group.summaryText,
      actions: actions,
      importance: group.type.isHighPriority 
          ? NotificationImportance.high 
          : NotificationImportance.defaultImportance,
      priority: group.type.isHighPriority 
          ? NotificationPriority.high 
          : NotificationPriority.defaultPriority,
      customData: {
        'groupId': group.id,
        'notificationCount': group.notifications.length,
        'type': group.type.value,
      },
    );
  }

  /// Create rich notification data for individual notification
  RichNotificationData _createRichNotificationForIndividual(Notification notification) {
    final actions = _getActionsForType(notification.type, isGroup: false);
    
    return RichNotificationData(
      title: notification.title,
      body: notification.body,
      actions: actions,
      importance: notification.type.isHighPriority 
          ? NotificationImportance.high 
          : NotificationImportance.defaultImportance,
      priority: notification.type.isHighPriority 
          ? NotificationPriority.high 
          : NotificationPriority.defaultPriority,
      customData: {
        'notificationId': notification.id.toString(),
        'type': notification.type.value,
        'relatedEntityType': notification.relatedEntityType,
        'relatedEntityId': notification.relatedEntityId,
      },
    );
  }

  /// Get actions for notification type
  List<NotificationAction> _getActionsForType(NotificationType type, {required bool isGroup}) {
    switch (type) {
      case NotificationType.chatMessage:
        return [
          const NotificationAction(
            id: 'reply',
            title: 'Balas',
            icon: 'ic_reply',
          ),
          const NotificationAction(
            id: 'mark_read',
            title: 'Tandai Dibaca',
            icon: 'ic_check',
          ),
        ];
      
      case NotificationType.orderCreated:
        return [
          const NotificationAction(
            id: 'view_order',
            title: 'Lihat Pesanan',
            icon: 'ic_visibility',
          ),
          const NotificationAction(
            id: 'accept_order',
            title: 'Terima',
            icon: 'ic_check',
            requiresAuth: true,
          ),
        ];
      
      case NotificationType.orderAccepted:
      case NotificationType.orderCompleted:
        return [
          const NotificationAction(
            id: 'view_order',
            title: 'Lihat Pesanan',
            icon: 'ic_visibility',
          ),
        ];
      
      case NotificationType.balanceUpdated:
        return [
          const NotificationAction(
            id: 'view_balance',
            title: 'Lihat Saldo',
            icon: 'ic_account_balance_wallet',
          ),
        ];
      
      case NotificationType.promotion:
        return [
          const NotificationAction(
            id: 'view_promotion',
            title: 'Lihat Promo',
            icon: 'ic_local_offer',
          ),
          const NotificationAction(
            id: 'dismiss',
            title: 'Tutup',
            icon: 'ic_close',
          ),
        ];
      
      default:
        return [
          const NotificationAction(
            id: 'view',
            title: 'Lihat',
            icon: 'ic_visibility',
          ),
        ];
    }
  }

  /// Show rich notification
  Future<void> _showRichNotification({
    required int id,
    required RichNotificationData richData,
    String? payload,
  }) async {
    // Convert custom importance and priority to Flutter values
    final importance = _convertImportance(richData.importance);
    final priority = _convertPriority(richData.priority);
    
    // Create Android notification details
    final androidDetails = AndroidNotificationDetails(
      richData.channelId ?? 'default_channel',
      'KlikJasa Notifications',
      channelDescription: 'Notifikasi dari aplikasi KlikJasa',
      importance: importance,
      priority: priority,
      enableVibration: richData.enableVibration,
      playSound: true,
      sound: richData.sound != null 
          ? RawResourceAndroidNotificationSound(richData.sound!) 
          : null,
      largeIcon: richData.largeIcon != null 
          ? DrawableResourceAndroidBitmap(richData.largeIcon!) 
          : null,
      styleInformation: BigTextStyleInformation(
        richData.body,
        contentTitle: richData.title,
        summaryText: 'KlikJasa',
      ),
      actions: richData.actions.map((action) => AndroidNotificationAction(
        action.id,
        action.title,
        icon: action.icon != null ? DrawableResourceAndroidBitmap(action.icon!) : null,
        inputs: action.id == 'reply' ? [
          const AndroidNotificationActionInput(
            label: 'Tulis balasan...',
          ),
        ] : [],
      )).toList(),
    );
    
    // Create iOS notification details
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      id,
      richData.title,
      richData.body,
      details,
      payload: payload,
    );
  }

  /// Convert custom importance to Flutter importance
  Importance _convertImportance(NotificationImportance importance) {
    switch (importance) {
      case NotificationImportance.min:
        return Importance.min;
      case NotificationImportance.low:
        return Importance.low;
      case NotificationImportance.defaultImportance:
        return Importance.defaultImportance;
      case NotificationImportance.high:
        return Importance.high;
      case NotificationImportance.max:
        return Importance.max;
    }
  }

  /// Convert custom priority to Flutter priority
  Priority _convertPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.min:
        return Priority.min;
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.defaultPriority:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.max:
        return Priority.max;
    }
  }

  /// Get group title for notification type
  String _getGroupTitle(NotificationType type) {
    switch (type) {
      case NotificationType.chatMessage:
        return 'Pesan Chat';
      case NotificationType.orderCreated:
        return 'Pesanan Baru';
      case NotificationType.orderAccepted:
        return 'Pesanan Diterima';
      case NotificationType.orderCompleted:
        return 'Pesanan Selesai';
      case NotificationType.balanceUpdated:
        return 'Update Saldo';
      case NotificationType.promotion:
        return 'Promosi';
      default:
        return type.displayName;
    }
  }

  /// Clean up old groups
  Future<void> _cleanupOldGroups() async {
    final now = DateTime.now();
    final keysToRemove = <String>[];
    
    for (final entry in _activeGroups.entries) {
      final group = entry.value;
      final timeSinceLastUpdate = now.difference(group.lastUpdated);
      
      if (timeSinceLastUpdate > _groupingWindow) {
        keysToRemove.add(entry.key);
      }
    }
    
    for (final key in keysToRemove) {
      _activeGroups.remove(key);
    }
  }

  /// Clear all groups
  void clearAllGroups() {
    _activeGroups.clear();
  }

  /// Get active groups
  Map<String, NotificationGroup> get activeGroups => Map.unmodifiable(_activeGroups);

  /// Handle notification action
  Future<void> handleNotificationAction(String actionId, Map<String, dynamic> data) async {
    try {
      _logger.i('Handling notification action: $actionId with data: $data');
      
      switch (actionId) {
        case 'reply':
          await _handleReplyAction(data);
          break;
        case 'mark_read':
          await _handleMarkReadAction(data);
          break;
        case 'view_order':
          await _handleViewOrderAction(data);
          break;
        case 'accept_order':
          await _handleAcceptOrderAction(data);
          break;
        case 'view_balance':
          await _handleViewBalanceAction(data);
          break;
        case 'view_promotion':
          await _handleViewPromotionAction(data);
          break;
        case 'dismiss':
          await _handleDismissAction(data);
          break;
        default:
          _logger.w('Unknown notification action: $actionId');
      }
    } catch (e) {
      _logger.e('Failed to handle notification action', error: e);
    }
  }

  Future<void> _handleReplyAction(Map<String, dynamic> data) async {
    // TODO: Implement reply action
    _logger.i('Reply action triggered');
  }

  Future<void> _handleMarkReadAction(Map<String, dynamic> data) async {
    // TODO: Implement mark read action
    _logger.i('Mark read action triggered');
  }

  Future<void> _handleViewOrderAction(Map<String, dynamic> data) async {
    // TODO: Implement view order action
    _logger.i('View order action triggered');
  }

  Future<void> _handleAcceptOrderAction(Map<String, dynamic> data) async {
    // TODO: Implement accept order action
    _logger.i('Accept order action triggered');
  }

  Future<void> _handleViewBalanceAction(Map<String, dynamic> data) async {
    // TODO: Implement view balance action
    _logger.i('View balance action triggered');
  }

  Future<void> _handleViewPromotionAction(Map<String, dynamic> data) async {
    // TODO: Implement view promotion action
    _logger.i('View promotion action triggered');
  }

  Future<void> _handleDismissAction(Map<String, dynamic> data) async {
    // TODO: Implement dismiss action
    _logger.i('Dismiss action triggered');
  }
}