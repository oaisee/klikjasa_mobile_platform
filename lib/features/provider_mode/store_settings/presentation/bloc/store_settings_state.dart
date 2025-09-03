import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';

abstract class StoreSettingsState extends Equatable {
  const StoreSettingsState();

  @override
  List<Object?> get props => [];
}

class StoreSettingsInitial extends StoreSettingsState {}

class StoreSettingsLoading extends StoreSettingsState {}

class StoreSettingsLoaded extends StoreSettingsState {
  final StoreSettingsEntity settings;

  const StoreSettingsLoaded({required this.settings});

  @override
  List<Object?> get props => [settings];
}

class StoreSettingsError extends StoreSettingsState {
  final String message;

  const StoreSettingsError({required this.message});

  @override
  List<Object?> get props => [message];
}

class StoreSettingsUpdating extends StoreSettingsState {}

class StoreSettingsUpdateSuccess extends StoreSettingsState {
  final String message;

  const StoreSettingsUpdateSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}

class StoreSettingsUpdateError extends StoreSettingsState {
  final String message;

  const StoreSettingsUpdateError({required this.message});

  @override
  List<Object?> get props => [message];
}
