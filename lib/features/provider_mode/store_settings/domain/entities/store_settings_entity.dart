import 'package:equatable/equatable.dart';

class StoreSettingsEntity extends Equatable {
  final bool isStoreActive;
  final bool autoAcceptOrders;
  final bool showDistance;
  final bool receiveNotifications;
  final Map<String, OperationalHourEntity> operationalHours;
  final String storeAddress;
  final double serviceRadius;
  final double? latitude;
  final double? longitude;

  const StoreSettingsEntity({
    required this.isStoreActive,
    required this.autoAcceptOrders,
    required this.showDistance,
    required this.receiveNotifications,
    required this.operationalHours,
    required this.storeAddress,
    required this.serviceRadius,
    this.latitude,
    this.longitude,
  });

  StoreSettingsEntity copyWith({
    bool? isStoreActive,
    bool? autoAcceptOrders,
    bool? showDistance,
    bool? receiveNotifications,
    Map<String, OperationalHourEntity>? operationalHours,
    String? storeAddress,
    double? serviceRadius,
    double? latitude,
    double? longitude,
  }) {
    return StoreSettingsEntity(
      isStoreActive: isStoreActive ?? this.isStoreActive,
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      showDistance: showDistance ?? this.showDistance,
      receiveNotifications: receiveNotifications ?? this.receiveNotifications,
      operationalHours: operationalHours ?? this.operationalHours,
      storeAddress: storeAddress ?? this.storeAddress,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> operationalHoursJson = {};
    operationalHours.forEach((key, value) {
      operationalHoursJson[key] = value.toJson();
    });

    return {
      'is_store_active': isStoreActive,
      'auto_accept_orders': autoAcceptOrders,
      'show_distance': showDistance,
      'receive_notifications': receiveNotifications,
      'operational_hours': operationalHoursJson,
      'store_address': storeAddress,
      'service_radius': serviceRadius,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory StoreSettingsEntity.fromJson(Map<String, dynamic> json) {
    final Map<String, OperationalHourEntity> operationalHours = {};
    
    if (json['operational_hours'] != null) {
      (json['operational_hours'] as Map<String, dynamic>).forEach((key, value) {
        operationalHours[key] = OperationalHourEntity.fromJson(value);
      });
    }

    return StoreSettingsEntity(
      isStoreActive: json['is_store_active'] ?? true,
      autoAcceptOrders: json['auto_accept_orders'] ?? false,
      showDistance: json['show_distance'] ?? true,
      receiveNotifications: json['receive_notifications'] ?? true,
      operationalHours: operationalHours,
      storeAddress: json['store_address'] ?? '',
      serviceRadius: (json['service_radius'] ?? 10.0).toDouble(),
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  factory StoreSettingsEntity.defaultSettings() {
    return StoreSettingsEntity(
      isStoreActive: true,
      autoAcceptOrders: false,
      showDistance: true,
      receiveNotifications: true,
      operationalHours: {
        'Senin': OperationalHourEntity(isOpen: true, openTime: '08:00', closeTime: '17:00'),
        'Selasa': OperationalHourEntity(isOpen: true, openTime: '08:00', closeTime: '17:00'),
        'Rabu': OperationalHourEntity(isOpen: true, openTime: '08:00', closeTime: '17:00'),
        'Kamis': OperationalHourEntity(isOpen: true, openTime: '08:00', closeTime: '17:00'),
        'Jumat': OperationalHourEntity(isOpen: true, openTime: '08:00', closeTime: '17:00'),
        'Sabtu': OperationalHourEntity(isOpen: true, openTime: '09:00', closeTime: '15:00'),
        'Minggu': OperationalHourEntity(isOpen: false, openTime: '00:00', closeTime: '00:00'),
      },
      storeAddress: '',
      serviceRadius: 10.0,
    );
  }

  @override
  List<Object?> get props => [
        isStoreActive,
        autoAcceptOrders,
        showDistance,
        receiveNotifications,
        operationalHours,
        storeAddress,
        serviceRadius,
        latitude,
        longitude,
      ];
}

class OperationalHourEntity extends Equatable {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const OperationalHourEntity({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  OperationalHourEntity copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return OperationalHourEntity(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }

  factory OperationalHourEntity.fromJson(Map<String, dynamic> json) {
    return OperationalHourEntity(
      isOpen: json['is_open'] ?? false,
      openTime: json['open_time'] ?? '08:00',
      closeTime: json['close_time'] ?? '17:00',
    );
  }

  @override
  List<Object?> get props => [isOpen, openTime, closeTime];
}
