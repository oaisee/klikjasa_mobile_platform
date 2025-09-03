import 'package:equatable/equatable.dart';
import 'notification_type.dart';

class Notification extends Equatable {
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

  const Notification({
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

  Notification copyWith({
    int? id,
    String? recipientUserId,
    String? title,
    String? body,
    NotificationType? type,
    String? relatedEntityType,
    String? relatedEntityId,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? metadata,
    String? actionUrl,
    bool? isDelivered,
    bool? isClicked,
    DateTime? deliveredAt,
    DateTime? clickedAt,
  }) {
    return Notification(
      id: id ?? this.id,
      recipientUserId: recipientUserId ?? this.recipientUserId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      relatedEntityType: relatedEntityType ?? this.relatedEntityType,
      relatedEntityId: relatedEntityId ?? this.relatedEntityId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      metadata: metadata ?? this.metadata,
      actionUrl: actionUrl ?? this.actionUrl,
      isDelivered: isDelivered ?? this.isDelivered,
      isClicked: isClicked ?? this.isClicked,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      clickedAt: clickedAt ?? this.clickedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        recipientUserId,
        title,
        body,
        type,
        relatedEntityType,
        relatedEntityId,
        isRead,
        createdAt,
        metadata,
        actionUrl,
        isDelivered,
        isClicked,
        deliveredAt,
        clickedAt,
      ];
}
