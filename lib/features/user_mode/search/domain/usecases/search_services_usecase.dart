import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/search/domain/repositories/search_repository.dart';

/// Use case untuk mencari layanan berdasarkan query
class SearchServicesUseCase {
  final SearchRepository _searchRepository;

  SearchServicesUseCase(this._searchRepository);

  /// Mengeksekusi pencarian layanan berdasarkan query
  Future<List<ServiceWithLocation>> execute(String query) async {
    return await _searchRepository.searchServices(query);
  }
}
