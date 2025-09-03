import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/top_up_repository.dart';

class ProcessSuccessfulTopUpParams {
  final int topUpId;
  final String? externalTransactionId;
  final Map<String, dynamic>? paymentDetails;

  ProcessSuccessfulTopUpParams({
    required this.topUpId,
    this.externalTransactionId,
    this.paymentDetails,
  });
}

class ProcessSuccessfulTopUpUseCase implements UseCase<bool, ProcessSuccessfulTopUpParams> {
  final TopUpRepository repository;

  ProcessSuccessfulTopUpUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(ProcessSuccessfulTopUpParams params) async {
    try {
      final result = await repository.processSuccessfulTopUp(
        params.topUpId,
        externalTransactionId: params.externalTransactionId,
        paymentDetails: params.paymentDetails,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
