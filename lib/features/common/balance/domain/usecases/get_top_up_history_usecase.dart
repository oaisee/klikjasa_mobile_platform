import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/top_up_history_entity.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/top_up_repository.dart';

class GetTopUpHistoryParams {
  final String userId;

  GetTopUpHistoryParams({required this.userId});
}

class GetTopUpHistoryUseCase implements UseCase<List<TopUpHistoryEntity>, GetTopUpHistoryParams> {
  final TopUpRepository repository;

  GetTopUpHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<TopUpHistoryEntity>>> call(GetTopUpHistoryParams params) async {
    try {
      final result = await repository.getTopUpHistoryByUserId(params.userId);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
