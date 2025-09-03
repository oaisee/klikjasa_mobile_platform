import 'package:klik_jasa/features/common/app_config/data/models/app_config_model.dart';

/// Interface untuk remote data source AppConfig
abstract class AppConfigRemoteDataSource {
  /// Mengambil semua pengaturan aplikasi
  Future<List<AppConfigModel>> getAllAppConfigs();

  /// Mengambil pengaturan aplikasi berdasarkan key
  Future<AppConfigModel> getAppConfigByKey(String key);

  /// Mengupdate nilai pengaturan aplikasi
  Future<AppConfigModel> updateAppConfig(String key, String value);
  
  /// Mengambil persentase fee untuk pengguna jasa
  Future<double> getUserFeePercentage();
  
  /// Mengambil persentase fee untuk penyedia jasa
  Future<double> getProviderFeePercentage();
}
