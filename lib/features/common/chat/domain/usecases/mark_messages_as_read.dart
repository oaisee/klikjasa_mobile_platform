import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/chat/domain/repositories/chat_repository.dart';

/// Use case untuk menandai pesan sebagai sudah dibaca
class MarkMessagesAsRead implements UseCase<void, MarkMessagesAsReadParams> {
  final ChatRepository repository;

  MarkMessagesAsRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkMessagesAsReadParams params) async {
    return await repository.markMessagesAsRead(
      userId: params.userId,
      otherUserId: params.otherUserId,
    );
  }
}

/// Parameter untuk MarkMessagesAsRead use case
class MarkMessagesAsReadParams extends Equatable {
  final String userId;
  final String otherUserId;

  const MarkMessagesAsReadParams({
    required this.userId,
    required this.otherUserId,
  });

  @override
  List<Object?> get props => [userId, otherUserId];
}