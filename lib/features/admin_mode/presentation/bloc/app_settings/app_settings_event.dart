import 'package:equatable/equatable.dart';

abstract class AppSettingsEvent extends Equatable {
  const AppSettingsEvent();

  @override
  List<Object> get props => [];
}

class GetAllAppSettingsEvent extends AppSettingsEvent {}

class GetAppSettingByKeyEvent extends AppSettingsEvent {
  final String key;

  const GetAppSettingByKeyEvent(this.key);

  @override
  List<Object> get props => [key];
}

class UpdateAppSettingEvent extends AppSettingsEvent {
  final String key;
  final String value;

  const UpdateAppSettingEvent({required this.key, required this.value});

  @override
  List<Object> get props => [key, value];
}
