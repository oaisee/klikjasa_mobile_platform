import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/features/common/chat/data/datasources/chat_remote_data_source.dart';
import 'package:klik_jasa/features/common/chat/data/models/chat_message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Implementasi Supabase untuk remote data source chat
class SupabaseChatRemoteDataSource implements ChatRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Logger logger = Logger();

  SupabaseChatRemoteDataSource({required this.supabaseClient});

  @override
  Future<ChatMessageModel> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
    String messageType = 'text',
  }) async {
    try {
      logger.i('Sending message from $senderId to $receiverId');
      
      final messageData = {
        'sender_id': senderId,
        'receiver_id': receiverId,
        'message': message,
        'message_type': messageType,
        'image_url': imageUrl,
        'status': 'terkirim',
      };

      final response = await supabaseClient
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      logger.i('Message sent successfully: ${response['id']}');
      return ChatMessageModel.fromJson(response);
    } on PostgrestException catch (e) {
      logger.e('PostgrestException sending message: ${e.message}');
      throw ServerException(message: 'Failed to send message: ${e.message}');
    } catch (e) {
      logger.e('Error sending message: $e');
      throw ServerException(message: 'Failed to send message: $e');
    }
  }

  @override
  Future<List<ChatMessageModel>> getChatMessages({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      logger.i('Getting chat messages between $userId and $otherUserId');
      
      // Menggunakan RPC function yang sudah ada di database
      final response = await supabaseClient
          .rpc('get_chat_details', params: {
            'user_id_param': userId,
            'other_user_id_param': otherUserId,
          });

      logger.i('Retrieved ${response.length} messages');
      
      return (response as List)
          .map((json) => ChatMessageModel.fromJson(json))
          .toList();
    } on PostgrestException catch (e) {
      logger.e('PostgrestException getting chat messages: ${e.message}');
      throw ServerException(message: 'Failed to get chat messages: ${e.message}');
    } catch (e) {
      logger.e('Error getting chat messages: $e');
      throw ServerException(message: 'Failed to get chat messages: $e');
    }
  }

  @override
  Future<void> markMessagesAsRead({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      logger.i('Marking messages as read between $userId and $otherUserId');
      
      // Menggunakan RPC function yang sudah ada di database
      await supabaseClient.rpc('mark_messages_as_read', params: {
        'user_id_param': userId,
        'other_user_id_param': otherUserId,
      });

      logger.i('Messages marked as read successfully');
    } on PostgrestException catch (e) {
      logger.e('PostgrestException marking messages as read: ${e.message}');
      throw ServerException(message: 'Failed to mark messages as read: ${e.message}');
    } catch (e) {
      logger.e('Error marking messages as read: $e');
      throw ServerException(message: 'Failed to mark messages as read: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getChatList({
    required String userId,
  }) async {
    try {
      logger.i('Getting chat list for user $userId');
      
      // Menggunakan RPC function yang sudah ada di database
      final response = await supabaseClient
          .rpc('get_chat_list', params: {
            'p_user_id': userId,
          });

      logger.i('Retrieved ${response.length} chat items');
      
      return List<Map<String, dynamic>>.from(response);
    } on PostgrestException catch (e) {
      logger.e('PostgrestException getting chat list: ${e.message}');
      throw ServerException(message: 'Failed to get chat list: ${e.message}');
    } catch (e) {
      logger.e('Error getting chat list: $e');
      throw ServerException(message: 'Failed to get chat list: $e');
    }
  }
}