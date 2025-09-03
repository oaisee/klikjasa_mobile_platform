import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification_type.dart';

class NotificationModel {
  final int id;
  final String recipientUserId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedEntityType;
  final String? relatedEntityId;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;
  final String? actionUrl;
  final bool isDelivered;
  final bool isClicked;
  final DateTime? deliveredAt;
  final DateTime? clickedAt;

  const NotificationModel({
    required this.id,
    required this.recipientUserId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedEntityType,
    this.relatedEntityId,
    required this.isRead,
    required this.createdAt,
    this.metadata,
    this.actionUrl,
    this.isDelivered = false,
    this.isClicked = false,
    this.deliveredAt,
    this.clickedAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      recipientUserId: json['recipient_user_id'] as String,
      title: json['title'] as String? ?? '', // Default ke string kosong jika null
      body: json['body'] as String? ?? '',   // Default ke string kosong jika null
      type: NotificationType.fromValue(json['type'] as String? ?? 'system_alert'),
      relatedEntityType: json['related_entity_type'] as String?,
      relatedEntityId: json['related_entity_id'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
      actionUrl: json['action_url'] as String?,
      isDelivered: json['is_delivered'] as bool? ?? false,
      isClicked: json['is_clicked'] as bool? ?? false,
      deliveredAt: json['delivered_at'] != null 
          ? DateTime.parse(json['delivered_at'] as String) 
          : null,
      clickedAt: json['clicked_at'] != null 
          ? DateTime.parse(json['clicked_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_user_id': recipientUserId,
      'title': title,
      'body': body,
      'type': type.value,
      'related_entity_type': relatedEntityType,
      'related_entity_id': relatedEntityId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'metadata': metadata,
      'action_url': actionUrl,
      'is_delivered': isDelivered,
      'is_clicked': isClicked,
      'delivered_at': deliveredAt?.toIso8601String(),
      'clicked_at': clickedAt?.toIso8601String(),
    };
  }

  Notification toEntity() {
    return Notification(
      id: id,
      recipientUserId: recipientUserId,
      title: title,
      body: body,
      type: type,
      relatedEntityType: relatedEntityType,
      relatedEntityId: relatedEntityId,
      isRead: isRead,
      createdAt: createdAt,
      metadata: metadata,
      actionUrl: actionUrl,
      isDelivered: isDelivered,
      isClicked: isClicked,
      deliveredAt: deliveredAt,
      clickedAt: clickedAt,
    );
  }

  factory NotificationModel.fromEntity(Notification notification) {
    return NotificationModel(
      id: notification.id,
      recipientUserId: notification.recipientUserId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      relatedEntityType: notification.relatedEntityType,
      relatedEntityId: notification.relatedEntityId,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
      metadata: notification.metadata,
      actionUrl: notification.actionUrl,
      isDelivered: notification.isDelivered,
      isClicked: notification.isClicked,
      deliveredAt: notification.deliveredAt,
      clickedAt: notification.clickedAt,
    );
  }
}

// Extension untuk mempermudah konversi dari List<NotificationModel> ke List<Notification>
extension NotificationModelListExtension on List<NotificationModel> {
  List<Notification> toEntityList() {
    return map((model) => model.toEntity()).toList();
  }
}

// Extension untuk mempermudah konversi dari List<Notification> ke List<NotificationModel>
extension NotificationListExtension on List<Notification> {
  List<NotificationModel> toModelList() {
    return map((entity) => NotificationModel.fromEntity(entity)).toList();
  }
}
