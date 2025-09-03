import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/chat/domain/entities/chat_message.dart';
import 'package:klik_jasa/features/common/chat/domain/repositories/chat_repository.dart';

/// Use case untuk mengambil daftar pesan chat
class GetChatMessages implements UseCase<List<ChatMessage>, GetChatMessagesParams> {
  final ChatRepository repository;

  GetChatMessages(this.repository);

  @override
  Future<Either<Failure, List<ChatMessage>>> call(GetChatMessagesParams params) async {
    return await repository.getChatMessages(
      userId: params.userId,
      otherUserId: params.otherUserId,
    );
  }
}

/// Parameter untuk GetChatMessages use case
class GetChatMessagesParams extends Equatable {
  final String userId;
  final String otherUserId;

  const GetChatMessagesParams({
    required this.userId,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [userId, otherUserId];
}