import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';
import 'package:klik_jasa/features/user_mode/search/data/datasources/search_remote_data_source.dart';
import 'package:klik_jasa/features/user_mode/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;

  SearchRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ServiceWithLocation>> searchServices(String query) async {
    return await remoteDataSource.searchServices(query);
  }
}
