import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/provider_mode/store_settings/domain/entities/store_settings_entity.dart';

abstract class StoreSettingsEvent extends Equatable {
  const StoreSettingsEvent();

  @override
  List<Object?> get props => [];
}

class GetStoreSettingsEvent extends StoreSettingsEvent {
  final String providerId;

  const GetStoreSettingsEvent({required this.providerId});

  @override
  List<Object?> get props => [providerId];
}

class UpdateStoreSettingsEvent extends StoreSettingsEvent {
  final String providerId;
  final StoreSettingsEntity settings;

  const UpdateStoreSettingsEvent({
    required this.providerId,
    required this.settings,
  });

  @override
  List<Object?> get props => [providerId, settings];
}

class UpdateStoreStatusEvent extends StoreSettingsEvent {
  final String providerId;
  final bool isActive;

  const UpdateStoreStatusEvent({
    required this.providerId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [providerId, isActive];
}

class UpdateOperationalHoursEvent extends StoreSettingsEvent {
  final String providerId;
  final String day;
  final OperationalHourEntity hours;

  const UpdateOperationalHoursEvent({
    required this.providerId,
    required this.day,
    required this.hours,
  });

  @override
  List<Object?> get props => [providerId, day, hours];
}

class UpdateServiceRadiusEvent extends StoreSettingsEvent {
  final String providerId;
  final double radius;

  const UpdateServiceRadiusEvent({
    required this.providerId,
    required this.radius,
  });

  @override
  List<Object?> get props => [providerId, radius];
}

class UpdateStoreLocationEvent extends StoreSettingsEvent {
  final String providerId;
  final String address;
  final double latitude;
  final double longitude;

  const UpdateStoreLocationEvent({
    required this.providerId,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [providerId, address, latitude, longitude];
}

class UpdateAutoAcceptOrdersEvent extends StoreSettingsEvent {
  final String providerId;
  final bool autoAccept;

  const UpdateAutoAcceptOrdersEvent({
    required this.providerId,
    required this.autoAccept,
  });

  @override
  List<Object?> get props => [providerId, autoAccept];
}

class UpdateShowDistanceEvent extends StoreSettingsEvent {
  final String providerId;
  final bool showDistance;

  const UpdateShowDistanceEvent({
    required this.providerId,
    required this.showDistance,
  });

  @override
  List<Object?> get props => [providerId, showDistance];
}

class UpdateReceiveNotificationsEvent extends StoreSettingsEvent {
  final String providerId;
  final bool receiveNotifications;

  const UpdateReceiveNotificationsEvent({
    required this.providerId,
    required this.receiveNotifications,
  });

  @override
  List<Object?> get props => [providerId, receiveNotifications];
}
