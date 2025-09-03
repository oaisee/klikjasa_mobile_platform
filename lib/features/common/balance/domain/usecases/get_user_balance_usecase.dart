import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/user_balance_repository.dart';

class GetUserBalanceUsecase {
  final UserBalanceRepository repository;

  GetUserBalanceUsecase(this.repository);

  Future<Either<Failure, UserBalanceEntity>> call(String userId) async {
    return await repository.getUserBalance(userId);
  }
}
