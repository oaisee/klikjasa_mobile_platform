import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';

/// State untuk kategori layanan
abstract class CategoryState extends Equatable {
  const CategoryState();

  @override
  List<Object?> get props => [];
}

/// State saat loading data kategori
class CategoryLoading extends CategoryState {}

/// State saat data kategori berhasil dimuat
class CategoryLoaded extends CategoryState {
  final List<ServiceCategory> categories;

  const CategoryLoaded({required this.categories});

  @override
  List<Object?> get props => [categories];
}

/// State saat terjadi error saat memuat data kategori
class CategoryError extends CategoryState {
  final String message;

  const CategoryError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// State saat kategori berhasil dimuat berdasarkan ID
class CategoryByIdLoaded extends CategoryState {
  final ServiceCategory category;

  const CategoryByIdLoaded({required this.category});

  @override
  List<Object?> get props => [category];
}
