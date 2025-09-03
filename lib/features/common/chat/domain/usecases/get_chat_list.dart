import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/chat/domain/repositories/chat_repository.dart';

/// Use case untuk mengambil daftar chat
class GetChatList implements UseCase<List<Map<String, dynamic>>, GetChatListParams> {
  final ChatRepository repository;

  GetChatList(this.repository);

  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> call(GetChatListParams params) async {
    return await repository.getChatList(
      userId: params.userId,
    );
  }
}

/// Parameter untuk GetChatList use case
class GetChatListParams extends Equatable {
  final String userId;

  const GetChatListParams({
    required this.userId,
  });

  @override
  List<Object?> get props => [userId];
}