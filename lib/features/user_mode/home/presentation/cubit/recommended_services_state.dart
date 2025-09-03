import 'package:equatable/equatable.dart';

/// State untuk layanan yang direkomendasikan
abstract class RecommendedServicesState extends Equatable {
  const RecommendedServicesState();

  @override
  List<Object?> get props => [];
}

/// State ketika data sedang dimuat
class RecommendedServicesLoading extends RecommendedServicesState {}

/// State ketika data berhasil dimuat
class RecommendedServicesLoaded extends RecommendedServicesState {
  final List<Map<String, dynamic>> services;
  final bool showEmptyLocationMessage;

  const RecommendedServicesLoaded({
    required this.services,
    this.showEmptyLocationMessage = false,
  });

  @override
  List<Object?> get props => [services, showEmptyLocationMessage];
}

/// State ketika terjadi error
class RecommendedServicesError extends RecommendedServicesState {
  final String message;

  const RecommendedServicesError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State awal
class RecommendedServicesInitial extends RecommendedServicesState {}
