import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/home/domain/repositories/category_repository.dart';
import 'package:klik_jasa/features/user_mode/home/presentation/cubit/category_state.dart';

/// Cubit untuk mengelola state kategori layanan
class CategoryCubit extends Cubit<CategoryState> {
  final CategoryRepository repository;

  CategoryCubit({required this.repository}) : super(CategoryLoading());

  /// Memuat semua kategori layanan yang aktif
  Future<void> getActiveCategories() async {
    emit(CategoryLoading());

    final result = await repository.getActiveCategories();
    result.fold(
      (failure) => emit(CategoryError(message: failure.message)),
      (categories) => emit(CategoryLoaded(categories: categories)),
    );
  }

  /// Memuat kategori layanan berdasarkan ID
  Future<void> getCategoryById(int id) async {
    emit(CategoryLoading());

    final result = await repository.getCategoryById(id);
    result.fold(
      (failure) => emit(CategoryError(message: failure.message)),
      (category) => emit(CategoryByIdLoaded(category: category)),
    );
  }
}
