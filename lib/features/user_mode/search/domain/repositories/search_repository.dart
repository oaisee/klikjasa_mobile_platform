import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';

/// Repository untuk pencarian layanan
abstract class SearchRepository {
  /// Mencari layanan berdasarkan query
  Future<List<ServiceWithLocation>> searchServices(String query);
}
