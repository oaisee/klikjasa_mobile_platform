import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/features/common/balance/domain/entities/user_balance_entity.dart';
import 'package:klik_jasa/features/common/balance/domain/repositories/user_balance_repository.dart';
import 'package:klik_jasa/features/common/balance/data/datasources/user_balance_remote_data_source.dart';

class UserBalanceRepositoryImpl implements UserBalanceRepository {
  final UserBalanceRemoteDataSource remoteDataSource;

  UserBalanceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, UserBalanceEntity>> getUserBalance(String userId) async {
    try {
      final userBalance = await remoteDataSource.getUserBalance(userId);
      return Right(userBalance);
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal mendapatkan saldo pengguna: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserBalanceEntity>> updateUserBalance(String userId, double newBalance) async {
    try {
      final updatedBalance = await remoteDataSource.updateUserBalance(userId, newBalance);
      return Right(updatedBalance);
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal memperbarui saldo pengguna: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> deductBalance(String userId, double amount, String description, String transactionType) async {
    try {
      final result = await remoteDataSource.deductBalance(userId, amount, description, transactionType);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal memotong saldo pengguna: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> addBalance(String userId, double amount, String description, String transactionType) async {
    try {
      final result = await remoteDataSource.addBalance(userId, amount, description, transactionType);
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal menambah saldo pengguna: ${e.toString()}'));
    }
  }
}
