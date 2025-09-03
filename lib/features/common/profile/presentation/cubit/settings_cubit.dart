import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../auth/data/services/biometric_auth_service.dart';
import 'settings_state.dart';

/// Cubit untuk mengelola state pengaturan aplikasi
class SettingsCubit extends Cubit<SettingsState> {
  final BiometricAuthService _biometricService;

  SettingsCubit({BiometricAuthService? biometricService})
    : _biometricService = biometricService ?? BiometricAuthService(),
      super(const SettingsState());

  /// Memuat pengaturan dari SharedPreferences
  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();

      emit(
        state.copyWith(
          notificationsEnabled: prefs.getBool('notifications_enabled') ?? true,
          emailNotifications: prefs.getBool('email_notifications') ?? true,
          pushNotifications: prefs.getBool('push_notifications') ?? true,
          selectedLanguage:
              prefs.getString('selected_language') ?? 'Bahasa Indonesia',
          biometricEnabled: prefs.getBool('biometric_enabled') ?? false,
          twoFactorEnabled: prefs.getBool('two_factor_enabled') ?? false,
          isLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Gagal memuat pengaturan: ${e.toString()}',
        ),
      );
    }
  }

  /// Memuat informasi versi aplikasi
  Future<void> loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      emit(state.copyWith(appVersion: packageInfo.version));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal memuat versi aplikasi: ${e.toString()}',
        ),
      );
    }
  }

  /// Memeriksa ketersediaan biometrik
  Future<void> checkBiometricAvailability() async {
    try {
      final isAvailable = await _biometricService.isAvailable();
      final availableBiometrics = await _biometricService
          .getAvailableBiometrics();

      emit(
        state.copyWith(
          isBiometricAvailable: isAvailable,
          availableBiometrics: availableBiometrics,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal memeriksa biometrik: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengubah pengaturan notifikasi
  Future<void> toggleNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', enabled);

      emit(state.copyWith(notificationsEnabled: enabled, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage:
              'Gagal menyimpan pengaturan notifikasi: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengubah pengaturan email notifikasi
  Future<void> toggleEmailNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('email_notifications', enabled);

      emit(state.copyWith(emailNotifications: enabled, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal menyimpan pengaturan email: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengubah pengaturan push notifikasi
  Future<void> togglePushNotifications(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('push_notifications', enabled);

      emit(state.copyWith(pushNotifications: enabled, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage:
              'Gagal menyimpan pengaturan push notifikasi: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengubah bahasa aplikasi
  Future<void> changeLanguage(String language) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', language);

      emit(state.copyWith(selectedLanguage: language, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal menyimpan pengaturan bahasa: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengubah pengaturan biometrik
  Future<void> toggleBiometric(bool enabled) async {
    if (!state.isBiometricAvailable) {
      emit(
        state.copyWith(
          errorMessage: 'Biometrik tidak tersedia di perangkat ini',
        ),
      );
      return;
    }

    try {
      if (enabled) {
        final isAuthenticated = await _biometricService.authenticate(
          localizedReason: 'Aktifkan autentikasi biometrik',
        );

        if (!isAuthenticated) {
          emit(state.copyWith(errorMessage: 'Autentikasi biometrik gagal'));
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', enabled);

      emit(state.copyWith(biometricEnabled: enabled, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal mengatur biometrik: ${e.toString()}',
        ),
      );
    }
  }

  /// Mengubah pengaturan two-factor authentication
  Future<void> toggleTwoFactor(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('two_factor_enabled', enabled);

      emit(state.copyWith(twoFactorEnabled: enabled, isSuccess: true));
    } catch (e) {
      emit(
        state.copyWith(
          errorMessage: 'Gagal menyimpan pengaturan 2FA: ${e.toString()}',
        ),
      );
    }
  }

  /// Reset pesan error
  void clearError() {
    emit(state.copyWith(errorMessage: null));
  }

  /// Reset status success
  void clearSuccess() {
    emit(state.copyWith(isSuccess: false));
  }
}
