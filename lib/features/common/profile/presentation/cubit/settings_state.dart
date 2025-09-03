import 'package:equatable/equatable.dart';
import 'package:local_auth/local_auth.dart';

/// State untuk mengelola pengaturan aplikasi
class SettingsState extends Equatable {
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool pushNotifications;
  final String selectedLanguage;
  final bool biometricEnabled;
  final bool isBiometricAvailable;
  final List<BiometricType> availableBiometrics;
  final bool twoFactorEnabled;
  final String appVersion;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const SettingsState({
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.selectedLanguage = 'Bahasa Indonesia',
    this.biometricEnabled = false,
    this.isBiometricAvailable = false,
    this.availableBiometrics = const [],
    this.twoFactorEnabled = false,
    this.appVersion = '...',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  SettingsState copyWith({
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? pushNotifications,
    String? selectedLanguage,
    bool? biometricEnabled,
    bool? isBiometricAvailable,
    List<BiometricType>? availableBiometrics,
    bool? twoFactorEnabled,
    String? appVersion,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return SettingsState(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      selectedLanguage: selectedLanguage ?? this.selectedLanguage,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      availableBiometrics: availableBiometrics ?? this.availableBiometrics,
      twoFactorEnabled: twoFactorEnabled ?? this.twoFactorEnabled,
      appVersion: appVersion ?? this.appVersion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  @override
  List<Object?> get props => [
        notificationsEnabled,
        emailNotifications,
        pushNotifications,
        selectedLanguage,
        biometricEnabled,
        isBiometricAvailable,
        availableBiometrics,
        twoFactorEnabled,
        appVersion,
        isLoading,
        errorMessage,
        isSuccess,
      ];
}
