import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/features/user_mode/search/domain/usecases/search_services_usecase.dart';
import 'package:klik_jasa/features/user_mode/search/presentation/cubit/search_state.dart';

/// Cubit untuk mengelola state pencarian layanan
class SearchCubit extends Cubit<SearchState> {
  final SearchServicesUseCase _searchServicesUseCase;
  
  // Tambahkan state untuk mengelola UI pencarian
  bool isSearching = false;
  String currentQuery = '';

  SearchCubit(this._searchServicesUseCase) : super(SearchInitial());

  /// Mengatur status pencarian (apakah sedang mencari atau tidak)
  void setSearching(bool value) {
    isSearching = value;
    // Tidak perlu emit state baru karena ini hanya mempengaruhi UI lokal
  }

  /// Mendapatkan status pencarian saat ini
  bool getSearchingStatus() {
    return isSearching;
  }

  /// Mengatur query pencarian saat ini
  void setCurrentQuery(String query) {
    currentQuery = query;
    if (query.isNotEmpty) {
      searchServices(query);
    } else {
      resetSearch();
    }
  }

  /// Mendapatkan query pencarian saat ini
  String getCurrentQuery() {
    return currentQuery;
  }

  /// Mencari layanan berdasarkan query
  Future<void> searchServices(String query) async {
    if (query.isEmpty) {
      emit(SearchInitial());
      return;
    }

    emit(SearchLoading());
    isSearching = true;
    currentQuery = query;

    try {
      final services = await _searchServicesUseCase.execute(query);
      emit(SearchLoaded(services));
    } catch (e) {
      emit(SearchError('Gagal mencari layanan: ${e.toString()}'));
    }
  }

  /// Mengatur ulang pencarian
  void resetSearch() {
    isSearching = false;
    currentQuery = '';
    emit(SearchInitial());
  }

  /// Membersihkan query pencarian
  void clearSearch() {
    isSearching = false;
    currentQuery = '';
    emit(SearchInitial());
  }
}
