import 'package:equatable/equatable.dart';

/// State untuk Provider Profile
abstract class ProviderProfileState extends Equatable {
  const ProviderProfileState();

  @override
  List<Object?> get props => [];
}

/// State ketika data sedang dimuat
class ProviderProfileLoading extends ProviderProfileState {}

/// State ketika data berhasil dimuat
class ProviderProfileLoaded extends ProviderProfileState {
  final Map<String, dynamic> profileData;
  final List<Map<String, dynamic>> services;
  final double averageRating;
  final int reviewCount;

  const ProviderProfileLoaded({
    required this.profileData,
    required this.services,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  @override
  List<Object?> get props => [profileData, services, averageRating, reviewCount];
}

/// State ketika terjadi error
class ProviderProfileError extends ProviderProfileState {
  final String message;

  const ProviderProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State awal
class ProviderProfileInitial extends ProviderProfileState {}
