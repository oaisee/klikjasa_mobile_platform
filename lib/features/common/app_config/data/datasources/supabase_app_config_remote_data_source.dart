import 'package:klik_jasa/core/error/exceptions.dart';
import 'package:klik_jasa/features/common/app_config/data/datasources/app_config_remote_data_source.dart';
import 'package:klik_jasa/features/common/app_config/data/models/app_config_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logger/logger.dart';

/// Implementasi Supabase untuk remote data source AppConfig
class SupabaseAppConfigRemoteDataSource implements AppConfigRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Logger logger;

  SupabaseAppConfigRemoteDataSource({
    required this.supabaseClient,
    required this.logger,
  });

  /// Nama tabel di database
  static const String tableName = 'app_config';

  /// Key untuk fee pengguna
  static const String userFeeKey = 'user_fee_percentage';

  /// Key untuk fee penyedia
  static const String providerFeeKey = 'provider_fee_percentage';

  @override
  Future<List<AppConfigModel>> getAllAppConfigs() async {
    try {
      final response = await supabaseClient
          .from(tableName)
          .select()
          .order('key', ascending: true);

      return (response as List)
          .map((item) => AppConfigModel.fromJson(item))
          .toList();
    } catch (e) {
      logger.e('Error getting all app configs: $e');
      throw ServerException(message: 'Server error');
    }
  }

  @override
  Future<AppConfigModel> getAppConfigByKey(String key) async {
    try {
      final response = await supabaseClient
          .from(tableName)
          .select()
          .eq('key', key)
          .single();

      return AppConfigModel.fromJson(response);
    } catch (e) {
      logger.e('Error getting app config by key: $e');
      throw ServerException(message: 'Server error');
    }
  }

  @override
  Future<AppConfigModel> updateAppConfig(String key, String value) async {
    try {
      final response = await supabaseClient
          .from(tableName)
          .update({'value': value, 'updated_at': DateTime.now().toIso8601String()})
          .eq('key', key)
          .select()
          .single();

      return AppConfigModel.fromJson(response);
    } catch (e) {
      logger.e('Error updating app config: $e');
      throw ServerException(message: 'Server error');
    }
  }

  @override
  Future<double> getUserFeePercentage() async {
    try {
      final config = await getAppConfigByKey(userFeeKey);
      final feePercentage = double.tryParse(config.value) ?? 0.0;
      return feePercentage;
    } catch (e) {
      logger.e('Error getting user fee percentage: $e');
      throw ServerException(message: 'Server error');
    }
  }

  @override
  Future<double> getProviderFeePercentage() async {
    try {
      final config = await getAppConfigByKey(providerFeeKey);
      final feePercentage = double.tryParse(config.value) ?? 0.0;
      return feePercentage;
    } catch (e) {
      logger.e('Error getting provider fee percentage: $e');
      throw ServerException(message: 'Server error');
    }
  }
}
