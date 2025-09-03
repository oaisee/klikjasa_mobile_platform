import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/chat/domain/entities/chat_message.dart';

/// Repository interface untuk chat functionality
abstract class ChatRepository {
  /// Mengirim pesan chat
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
    String messageType = 'text',
  });

  /// Mengambil daftar pesan chat antara dua user
  Future<Either<Failure, List<ChatMessage>>> getChatMessages({
    required String userId,
    required String otherUserId,
  });

  /// Menandai pesan sebagai sudah dibaca
  Future<Either<Failure, void>> markMessagesAsRead({
    required String userId,
    required String otherUserId,
  });

  /// Mengambil daftar chat list untuk user
  Future<Either<Failure, List<Map<String, dynamic>>>> getChatList({
    required String userId,
  });
}