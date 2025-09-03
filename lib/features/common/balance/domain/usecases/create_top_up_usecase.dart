import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/top_up_history_entity.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/top_up_repository.dart';

class CreateTopUpParams {
  final String userId;
  final double amount;
  final String description;
  final String? paymentMethod;
  final Map<String, dynamic>? paymentDetails;
  final String? externalTransactionId;

  CreateTopUpParams({
    required this.userId,
    required this.amount,
    required this.description,
    this.paymentMethod,
    this.paymentDetails,
    this.externalTransactionId,
  });
}

class CreateTopUpUseCase implements UseCase<TopUpHistoryEntity, CreateTopUpParams> {
  final TopUpRepository repository;

  CreateTopUpUseCase(this.repository);

  @override
  Future<Either<Failure, TopUpHistoryEntity>> call(CreateTopUpParams params) async {
    try {
      final result = await repository.createTopUp(
        params.userId,
        params.amount,
        params.description,
        paymentMethod: params.paymentMethod,
        paymentDetails: params.paymentDetails,
        externalTransactionId: params.externalTransactionId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
