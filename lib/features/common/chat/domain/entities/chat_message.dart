import 'package:equatable/equatable.dart';

/// Entity untuk chat message
class ChatMessage extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType;
  final DateTime createdAt;
  final String? imageUrl;
  final String status;
  final Map<String, dynamic>? metadata;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    this.messageType = 'text',
    this.imageUrl,
    this.status = 'terkirim',
    this.metadata,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        message,
        messageType,
        createdAt,
        imageUrl,
        status,
        metadata,
      ];
}