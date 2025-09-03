import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/common/app_config/domain/entities/app_config.dart';

abstract class AppSettingsState extends Equatable {
  const AppSettingsState();
  
  @override
  List<Object?> get props => [];
}

class AppSettingsInitial extends AppSettingsState {}

class AppSettingsLoading extends AppSettingsState {}

class AppSettingsLoaded extends AppSettingsState {
  final List<AppConfig> settings;
  
  const AppSettingsLoaded(this.settings);
  
  @override
  List<Object?> get props => [settings];
}

class AppSettingLoaded extends AppSettingsState {
  final AppConfig setting;
  
  const AppSettingLoaded(this.setting);
  
  @override
  List<Object?> get props => [setting];
}

class AppSettingUpdated extends AppSettingsState {
  final AppConfig setting;
  
  const AppSettingUpdated(this.setting);
  
  @override
  List<Object?> get props => [setting];
}

class AppSettingsError extends AppSettingsState {
  final String message;
  
  const AppSettingsError(this.message);
  
  @override
  List<Object?> get props => [message];
}
