import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:klik_jasa/core/error/failures.dart';

// Generic UseCase interface
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Digunakan jika use case tidak memerlukan parameter
class NoParams extends Equatable {
  const NoParams();
  @override
  List<Object?> get props => [];
}

// Untuk use case yang tidak memerlukan parameter
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

// Generic StreamUseCase interface
abstract class StreamUseCase<Type, Params> {
  Stream<Either<Failure, Type>> call(Params params);
}