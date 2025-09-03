import 'package:klik_jasa/features/common/chat/domain/entities/chat_message.dart';

/// Model untuk chat message yang mengimplementasikan entity ChatMessage
class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.message,
    required super.createdAt,
    super.messageType,
    super.imageUrl,
    super.status,
    super.metadata,
  });

  /// Factory constructor untuk membuat ChatMessageModel dari JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id']?.toString() ?? '00000000-0000-0000-0000-000000000000',
      senderId: json['sender_id'] ?? '00000000-0000-0000-0000-000000000000',
      receiverId: json['receiver_id'] ?? '00000000-0000-0000-0000-000000000000',
      message: json['message'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      imageUrl: json['image_url'],
      status: json['status'] ?? 'terkirim',
      metadata: json['metadata'],
    );
  }

  /// Mengkonversi ChatMessageModel ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'status': status,
      'metadata': metadata,
    };
  }

  /// Mengkonversi ke JSON untuk insert ke database (tanpa id)
  Map<String, dynamic> toInsertJson() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'image_url': imageUrl,
      'status': status,
      'metadata': metadata,
    };
  }

  /// Copy with method untuk membuat instance baru dengan perubahan
  ChatMessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    String? messageType,
    DateTime? createdAt,
    String? imageUrl,
    String? status,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }
}
