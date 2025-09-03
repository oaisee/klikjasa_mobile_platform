import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/common/auth/domain/entities/user_entity.dart';

abstract class AuthStateEntity extends Equatable {
  const AuthStateEntity();

  @override
  List<Object?> get props => [];
}

class AuthStateAuthenticated extends AuthStateEntity {
  final UserEntity user; // User harus ada jika state adalah Authenticated

  const AuthStateAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

class AuthStateUnauthenticated extends AuthStateEntity {}

class AuthStateLoading extends AuthStateEntity {} // Jika diperlukan untuk stream

class AuthStateInitial extends AuthStateEntity {} // Jika diperlukan untuk stream

class AuthStatePasswordRecovery extends AuthStateEntity {
  final String email;
  const AuthStatePasswordRecovery({required this.email});
   @override
  List<Object?> get props => [email];
}

class AuthStateError extends AuthStateEntity {
  final String message;
  const AuthStateError({required this.message});
   @override
  List<Object?> get props => [message];
}
