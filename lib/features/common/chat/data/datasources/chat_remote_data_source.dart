import 'package:klik_jasa/features/common/chat/data/models/chat_message_model.dart';

/// Interface untuk remote data source chat
abstract class ChatRemoteDataSource {
  /// Mengirim pesan chat ke server
  Future<ChatMessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
    String messageType = 'text',
  });

  /// Mengambil daftar pesan chat antara dua user
  Future<List<ChatMessageModel>> getChatMessages({
    required String userId,
    required String otherUserId,
  });

  /// Menandai pesan sebagai sudah dibaca
  Future<void> markMessagesAsRead({
    required String userId,
    required String otherUserId,
  });

  /// Mengambil daftar chat list untuk user
  Future<List<Map<String, dynamic>>> getChatList({
    required String userId,
  });
}