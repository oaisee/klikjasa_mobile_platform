import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klik_jasa/core/error/failures.dart';
import 'package:klik_jasa/core/usecases/usecase.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_all_app_configs.dart';
import 'package:klik_jasa/features/common/app_config/domain/usecases/get_app_config_by_key.dart' as get_key;
import 'package:klik_jasa/features/common/app_config/domain/usecases/update_app_config.dart' as update_setting;
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_event.dart';
import 'package:klik_jasa/features/admin_mode/presentation/bloc/app_settings/app_settings_state.dart';
import 'package:klik_jasa/features/common/app_config/data/logging/app_config_change_logger.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  final GetAllAppConfigs getAllAppSettings;
  final get_key.GetAppConfigByKey getAppSettingByKey;
  final update_setting.UpdateAppConfig updateAppSetting;
  final Logger logger;
  late final AppConfigChangeLogger _configLogger;

  AppSettingsBloc({
    required this.getAllAppSettings,
    required this.getAppSettingByKey,
    required this.updateAppSetting,
    required this.logger,
  }) : super(AppSettingsInitial()) {
    _configLogger = AppConfigChangeLogger(
      logger: logger,
      supabaseClient: Supabase.instance.client,
    );
    on<GetAllAppSettingsEvent>(_onGetAllAppSettings);
    on<GetAppSettingByKeyEvent>(_onGetAppSettingByKey);
    on<UpdateAppSettingEvent>(_onUpdateAppSetting);
  }

  Future<void> _onGetAllAppSettings(
    GetAllAppSettingsEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(AppSettingsLoading());
    final result = await getAllAppSettings(NoParams());
    result.fold(
      (failure) => emit(AppSettingsError(_mapFailureToMessage(failure))),
      (configs) => emit(AppSettingsLoaded(configs)),
    );
  }

  Future<void> _onGetAppSettingByKey(
    GetAppSettingByKeyEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(AppSettingsLoading());
    final result = await getAppSettingByKey(get_key.GetAppConfigByKeyParams(key: event.key));
    result.fold(
      (failure) => emit(AppSettingsError(_mapFailureToMessage(failure))),
      (config) => emit(AppSettingLoaded(config)),
    );
  }

  Future<void> _onUpdateAppSetting(
    UpdateAppSettingEvent event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(AppSettingsLoading());
    
    // Ambil nilai lama sebelum update untuk logging
    String oldValue = '';
    final oldValueResult = await getAppSettingByKey(get_key.GetAppConfigByKeyParams(key: event.key));
    oldValueResult.fold(
      (failure) => {/* Abaikan error */},
      (config) => oldValue = config.value,
    );
    
    final result = await updateAppSetting(
      update_setting.UpdateAppConfigParams(key: event.key, value: event.value),
    );
    
    result.fold(
      (failure) => emit(AppSettingsError(_mapFailureToMessage(failure))),
      (config) async {
        // Log perubahan pengaturan penting
        await _configLogger.logConfigChange(
          key: event.key,
          oldValue: oldValue,
          newValue: event.value,
          changedBy: Supabase.instance.client.auth.currentUser?.email ?? 'unknown',
        );
        
        emit(AppSettingUpdated(config));
      },
    );
  }

  String _mapFailureToMessage(Failure failure) {
    switch (failure) {
      case ServerFailure _:
        return 'Terjadi kesalahan server. Silakan coba lagi nanti.';
      case NetworkFailure _:
        return 'Tidak ada koneksi internet. Silakan periksa koneksi Anda.';
      default:
        return 'Terjadi kesalahan yang tidak terduga. Silakan coba lagi nanti.';
    }
  }
}
