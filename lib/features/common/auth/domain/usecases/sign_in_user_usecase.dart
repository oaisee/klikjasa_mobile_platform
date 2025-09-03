import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';

class SignInUserUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;

  SignInUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    return await repository.signInWithEmailPassword(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
