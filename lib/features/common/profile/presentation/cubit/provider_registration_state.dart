import 'package:equatable/equatable.dart';
import 'dart:io';
import 'package:klik_jasa/features/common/profile/domain/entities/kabupaten_kota.dart';
import 'package:klik_jasa/features/common/services/domain/entities/service_category.dart';

/// State untuk mengelola registrasi provider
class ProviderRegistrationState extends Equatable {
  final File? ktpImageFile;
  final String imageVersion;
  final Map<String, dynamic>? userProfile;
  final bool isLoadingProfile;
  final bool useCurrentUserAddress;
  final bool isSubmitting;
  final bool agreeToTerms;
  final String? providerStatus;
  final List<KabupatenKota> kabupatenKotaList;
  final KabupatenKota? selectedKabupatenKota;
  final bool isKabupatenKotaLoading;
  final List<ServiceCategory> serviceCategories;
  final bool isLoadingServiceCategories;
  final String? errorMessage;
  final bool isSuccess;
  final String? successMessage;

  const ProviderRegistrationState({
    this.ktpImageFile,
    this.imageVersion = '',
    this.userProfile,
    this.isLoadingProfile = true,
    this.useCurrentUserAddress = true,
    this.isSubmitting = false,
    this.agreeToTerms = false,
    this.providerStatus,
    this.kabupatenKotaList = const [],
    this.selectedKabupatenKota,
    this.isKabupatenKotaLoading = false,
    this.serviceCategories = const [],
    this.isLoadingServiceCategories = false,
    this.errorMessage,
    this.isSuccess = false,
    this.successMessage,
  });

  ProviderRegistrationState copyWith({
    File? ktpImageFile,
    String? imageVersion,
    Map<String, dynamic>? userProfile,
    bool? isLoadingProfile,
    bool? useCurrentUserAddress,
    bool? isSubmitting,
    bool? agreeToTerms,
    String? providerStatus,
    List<KabupatenKota>? kabupatenKotaList,
    KabupatenKota? selectedKabupatenKota,
    bool? isKabupatenKotaLoading,
    List<ServiceCategory>? serviceCategories,
    bool? isLoadingServiceCategories,
    String? errorMessage,
    bool? isSuccess,
    String? successMessage,
  }) {
    return ProviderRegistrationState(
      ktpImageFile: ktpImageFile ?? this.ktpImageFile,
      imageVersion: imageVersion ?? this.imageVersion,
      userProfile: userProfile ?? this.userProfile,
      isLoadingProfile: isLoadingProfile ?? this.isLoadingProfile,
      useCurrentUserAddress: useCurrentUserAddress ?? this.useCurrentUserAddress,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      agreeToTerms: agreeToTerms ?? this.agreeToTerms,
      providerStatus: providerStatus ?? this.providerStatus,
      kabupatenKotaList: kabupatenKotaList ?? this.kabupatenKotaList,
      selectedKabupatenKota: selectedKabupatenKota ?? this.selectedKabupatenKota,
      isKabupatenKotaLoading: isKabupatenKotaLoading ?? this.isKabupatenKotaLoading,
      serviceCategories: serviceCategories ?? this.serviceCategories,
      isLoadingServiceCategories: isLoadingServiceCategories ?? this.isLoadingServiceCategories,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      successMessage: successMessage,
    );
  }

  /// State untuk clear KTP image
  ProviderRegistrationState clearKtpImage() {
    return copyWith(
      ktpImageFile: null,
      imageVersion: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  /// State untuk update image version
  ProviderRegistrationState updateImageVersion() {
    return copyWith(
      imageVersion: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  @override
  List<Object?> get props => [
        ktpImageFile,
        imageVersion,
        userProfile,
        isLoadingProfile,
        useCurrentUserAddress,
        isSubmitting,
        agreeToTerms,
        providerStatus,
        kabupatenKotaList,
        selectedKabupatenKota,
        isKabupatenKotaLoading,
        serviceCategories,
        isLoadingServiceCategories,
        errorMessage,
        isSuccess,
        successMessage,
      ];
}
