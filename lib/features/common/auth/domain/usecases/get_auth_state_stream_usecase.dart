import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/auth_state_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';

class GetAuthStateStreamUseCase implements UseCase<Stream<AuthStateEntity>, NoParams> {
  final AuthRepository repository;

  GetAuthStateStreamUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<AuthStateEntity>>> call(NoParams params) async {
    try {
      final stream = repository.authStateChanges;
      return Right(stream);
    } catch (e) {
      return Left(ServerFailure(message: 'Gagal mendapatkan stream autentikasi: ${e.toString()}'));
    }
  }
}
