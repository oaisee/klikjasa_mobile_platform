import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';
import 'package:klik_jasa/features/common/auth/domain/repositories/auth_repository.dart';

class SignUpUserUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    return await repository.signUpWithEmailPassword(
      email: params.email,
      password: params.password,
      data: params.data,
    );
  }
}

class SignUpParams extends Equatable {
  final String email;
  final String password;
  final Map<String, dynamic>? data; // Untuk nama, dll.

  const SignUpParams({
    required this.email,
    required this.password,
    this.data,
  });

  @override
  List<Object?> get props => [email, password, data];
}
