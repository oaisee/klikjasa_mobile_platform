import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';

abstract class UserBalanceRepository {
  Future<Either<Failure, UserBalanceEntity>> getUserBalance(String userId);
  Future<Either<Failure, UserBalanceEntity>> updateUserBalance(String userId, double newBalance);
  Future<Either<Failure, bool>> deductBalance(String userId, double amount, String description, String transactionType);
  Future<Either<Failure, bool>> addBalance(String userId, double amount, String description, String transactionType);
}
