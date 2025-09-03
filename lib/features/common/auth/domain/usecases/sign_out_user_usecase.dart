import 'package:dartz/dartz.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';

class SignOutUserUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUserUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}
