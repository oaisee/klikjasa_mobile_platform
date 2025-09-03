import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/chat/data/datasources/chat_remote_data_source.dart';
import 'package:klik_jasa/features/common/chat/domain/entities/chat_message.dart';
import 'package:klik_jasa/features/common/chat/domain/repositories/chat_repository.dart';
import 'package:logger/logger.dart';

/// Implementasi repository untuk chat functionality
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;
  final Logger logger = Logger();

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String senderId,
    required String receiverId,
    required String message,
    String? imageUrl,
    String messageType = 'text',
  }) async {
    try {
      logger.i('Repository: Sending message from $senderId to $receiverId');
      
      final result = await remoteDataSource.sendMessage(
        senderId: senderId,
        receiverId: receiverId,
        message: message,
        imageUrl: imageUrl,
        messageType: messageType,
      );
      
      logger.i('Repository: Message sent successfully');
      return Right(result);
    } on ServerException catch (e) {
      logger.e('Repository: ServerException sending message: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Repository: Unexpected error sending message: $e');
      return Left(ServerFailure(message: 'Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessage>>> getChatMessages({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      logger.i('Repository: Getting chat messages between $userId and $otherUserId');
      
      final result = await remoteDataSource.getChatMessages(
        userId: userId,
        otherUserId: otherUserId,
      );
      
      logger.i('Repository: Retrieved ${result.length} messages');
      return Right(result);
    } on ServerException catch (e) {
      logger.e('Repository: ServerException getting chat messages: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Repository: Unexpected error getting chat messages: $e');
      return Left(ServerFailure(message: 'Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, void>> markMessagesAsRead({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      logger.i('Repository: Marking messages as read between $userId and $otherUserId');
      
      await remoteDataSource.markMessagesAsRead(
        userId: userId,
        otherUserId: otherUserId,
      );
      
      logger.i('Repository: Messages marked as read successfully');
      return const Right(null);
    } on ServerException catch (e) {
      logger.e('Repository: ServerException marking messages as read: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Repository: Unexpected error marking messages as read: $e');
      return Left(ServerFailure(message: 'Unexpected error occurred'));
    }
  }

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getChatList({
    required String userId,
  }) async {
    try {
      logger.i('Repository: Getting chat list for user $userId');
      
      final result = await remoteDataSource.getChatList(
        userId: userId,
      );
      
      logger.i('Repository: Retrieved ${result.length} chat items');
      return Right(result);
    } on ServerException catch (e) {
      logger.e('Repository: ServerException getting chat list: ${e.message}');
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      logger.e('Repository: Unexpected error getting chat list: $e');
      return Left(ServerFailure(message: 'Unexpected error occurred'));
    }
  }
}