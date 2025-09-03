import 'package:equatable/equatable.dart';
import 'package:klik_jasa/features/user_mode/home/domain/entities/service_with_location.dart';

abstract class ServiceLocationState extends Equatable {
  const ServiceLocationState();

  @override
  List<Object?> get props => [];
}

class ServiceLocationInitial extends ServiceLocationState {}

class ServiceLocationLoading extends ServiceLocationState {}

class ServiceLocationLoaded extends ServiceLocationState {
  final List<ServiceWithLocation> services;
  final bool hasReachedMax;
  final String? userProvinsi;
  final String? userKabupatenKota;
  final String? userKecamatan;
  final String? userDesaKelurahan;
  final bool isProvinceLevel; // Flag untuk menandai apakah layanan difilter pada level provinsi (fallback)
  final bool showEmptyLocationMessage; // Flag untuk menampilkan pesan jika tidak ada layanan di lokasi spesifik
  final bool isRealtimeUpdate; // Flag untuk menandai apakah data berasal dari realtime update

  const ServiceLocationLoaded({
    required this.services,
    required this.hasReachedMax,
    this.userProvinsi,
    this.userKabupatenKota,
    this.userKecamatan,
    this.userDesaKelurahan,
    this.isProvinceLevel = false,
    this.showEmptyLocationMessage = false,
    this.isRealtimeUpdate = false,
  });

  ServiceLocationLoaded copyWith({
    List<ServiceWithLocation>? services,
    bool? hasReachedMax,
    String? userProvinsi,
    String? userKabupatenKota,
    String? userKecamatan,
    String? userDesaKelurahan,
    bool? isProvinceLevel,
    bool? showEmptyLocationMessage,
    bool? isRealtimeUpdate,
  }) {
    return ServiceLocationLoaded(
      services: services ?? this.services,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      userProvinsi: userProvinsi ?? this.userProvinsi,
      userKabupatenKota: userKabupatenKota ?? this.userKabupatenKota,
      userKecamatan: userKecamatan ?? this.userKecamatan,
      userDesaKelurahan: userDesaKelurahan ?? this.userDesaKelurahan,
      isProvinceLevel: isProvinceLevel ?? this.isProvinceLevel,
      showEmptyLocationMessage: showEmptyLocationMessage ?? this.showEmptyLocationMessage,
      isRealtimeUpdate: isRealtimeUpdate ?? this.isRealtimeUpdate,
    );
  }

  @override
  List<Object?> get props => [
        services,
        hasReachedMax,
        userProvinsi,
        userKabupatenKota,
        userKecamatan,
        userDesaKelurahan,
        isProvinceLevel,
        showEmptyLocationMessage,
      ];
}

class ServiceLocationError extends ServiceLocationState {
  final String message;

  const ServiceLocationError({required this.message});

  @override
  List<Object> get props => [message];
}

// State untuk layanan yang dipromosikan
class PromotedServicesLoaded extends ServiceLocationState {
  final List<ServiceWithLocation> services;
  final bool hasReachedMax;

  const PromotedServicesLoaded({
    required this.services,
    this.hasReachedMax = false,
  });

  PromotedServicesLoaded copyWith({
    List<ServiceWithLocation>? services,
    bool? hasReachedMax,
  }) {
    return PromotedServicesLoaded(
      services: services ?? this.services,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [services, hasReachedMax];
}

// State untuk layanan dengan rating tertinggi
class HighestRatedServicesLoaded extends ServiceLocationState {
  final List<ServiceWithLocation> services;
  final bool hasReachedMax;

  const HighestRatedServicesLoaded({
    required this.services,
    this.hasReachedMax = false,
  });

  HighestRatedServicesLoaded copyWith({
    List<ServiceWithLocation>? services,
    bool? hasReachedMax,
  }) {
    return HighestRatedServicesLoaded(
      services: services ?? this.services,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [services, hasReachedMax];
}
