import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Kelas untuk menangani subscription realtime pada chat messages
class ChatRealtimeSubscription {
  final SupabaseClient _supabaseClient;
  final String _currentUserId;
  final String _otherUserId;
  final void Function(Map<String, dynamic> message) onNewMessage;
  final void Function(Map<String, dynamic> message) onMessageUpdated;

  RealtimeChannel? _channel;
  final Logger _logger = Logger();
  bool _isSubscribed = false;

  ChatRealtimeSubscription({
    required SupabaseClient supabaseClient,
    required String currentUserId,
    required String otherUserId,
    required this.onNewMessage,
    required this.onMessageUpdated,
  }) : _supabaseClient = supabaseClient,
       _currentUserId = currentUserId,
       _otherUserId = otherUserId;

  /// Memulai subscription untuk chat messages antara dua user
  void startSubscription() {
    if (_isSubscribed) {
      _logger.i(
        'Chat subscription sudah aktif untuk $_currentUserId <-> $_otherUserId',
      );
      return;
    }

    _logger.i(
      'Memulai chat subscription untuk $_currentUserId <-> $_otherUserId',
    );

    try {
      // Buat channel unik untuk conversation ini
      final channelName = 'chat:${_generateConversationId()}';
      _channel = _supabaseClient.channel(channelName);

      // Subscribe ke perubahan pada tabel chat_messages
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        callback: (payload) {
          _logger.i('Received new chat message: ${payload.newRecord}');
          final message = _formatMessage(payload.newRecord);
          // Filter pesan yang relevan untuk conversation ini
          if (_isMessageForThisConversation(message)) {
            onNewMessage(message);
          }
        },
      );

      // Subscribe ke update pada tabel chat_messages (untuk status read)
      _channel!.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'chat_messages',
        callback: (payload) {
          _logger.i('Chat message updated: ${payload.newRecord}');
          final message = _formatMessage(payload.newRecord);
          // Filter pesan yang relevan untuk conversation ini
          if (_isMessageForThisConversation(message)) {
            onMessageUpdated(message);
          }
        },
      );

      // Subscribe ke channel
      _channel!.subscribe((status, error) {
        _logger.i('Chat subscription status: $status');
        if (error != null) {
          _logger.e('Chat subscription error: $error');
          _isSubscribed = false;
          return;
        }

        if (status == RealtimeSubscribeStatus.subscribed) {
          _logger.i('✅ Berhasil subscribe ke chat realtime.');
          _isSubscribed = true;
        } else {
          _isSubscribed = false;
        }
      });
    } catch (e) {
      _logger.e('❌ Exception saat setup chat subscription: $e');
    }
  }

  /// Menghentikan subscription
  void stopSubscription() {
    if (_channel != null) {
      _logger.i(
        'Menghentikan chat subscription untuk $_currentUserId <-> $_otherUserId',
      );
      _supabaseClient.removeChannel(_channel!);
      _channel = null;
      _isSubscribed = false;
    }
  }

  /// Generate ID unik untuk conversation
  String _generateConversationId() {
    // Urutkan ID untuk memastikan konsistensi
    final ids = [_currentUserId, _otherUserId]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Cek apakah pesan ini relevan untuk conversation ini
  bool _isMessageForThisConversation(Map<String, dynamic> message) {
    final senderId = message['sender_id'];
    final receiverId = message['receiver_id'];

    // Pesan relevan jika:
    // 1. Dari current user ke other user, atau
    // 2. Dari other user ke current user
    return (senderId == _currentUserId && receiverId == _otherUserId) ||
        (senderId == _otherUserId && receiverId == _currentUserId);
  }

  /// Format message dari database ke format yang digunakan UI
  Map<String, dynamic> _formatMessage(Map<String, dynamic> record) {
    return {
      'id': record['id'],
      'sender_id': record['sender_id'],
      'receiver_id': record['receiver_id'],
      'message': record['message'],
      'message_type': record['message_type'],
      'created_at': record['created_at'],
      'image_url': record['image_url'],
      'status': record['status'],
      'is_sender': record['sender_id'] == _currentUserId,
    };
  }

  bool get isSubscribed => _isSubscribed;
}
