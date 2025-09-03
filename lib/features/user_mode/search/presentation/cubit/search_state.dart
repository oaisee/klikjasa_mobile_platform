import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';

/// State dasar untuk pencarian layanan
abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// State awal pencarian
class SearchInitial extends SearchState {}

/// State saat pencarian sedang berlangsung
class SearchLoading extends SearchState {}

/// State saat pencarian berhasil dengan hasil
class SearchLoaded extends SearchState {
  final List<ServiceWithLocation> services;

  const SearchLoaded(this.services);

  @override
  List<Object?> get props => [services];
}

/// State saat pencarian gagal
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}
