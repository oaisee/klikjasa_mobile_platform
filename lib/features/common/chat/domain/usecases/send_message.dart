import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/chat/domain/entities/chat_message.dart';
import 'package:klik_jasa/features/common/chat/domain/repositories/chat_repository.dart';

/// Use case untuk mengirim pesan chat
class SendMessage implements UseCase<ChatMessage, SendMessageParams> {
  final ChatRepository repository;

  SendMessage(this.repository);

  @override
  Future<Either<Failure, ChatMessage>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      senderId: params.senderId,
      receiverId: params.receiverId,
      message: params.message,
      imageUrl: params.imageUrl,
      messageType: params.messageType,
    );
  }
}

/// Parameter untuk SendMessage use case
class SendMessageParams extends Equatable {
  final String senderId;
  final String receiverId;
  final String message;
  final String? imageUrl;
  final String messageType;

  const SendMessageParams({
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.imageUrl,
    this.messageType = 'text',
  });

  @override
  List<Object?> get props => [
        senderId,
        receiverId,
        message,
        imageUrl,
        messageType,
      ];
}