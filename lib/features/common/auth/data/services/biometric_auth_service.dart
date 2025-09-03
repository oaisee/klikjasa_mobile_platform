import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static final BiometricAuthService _instance = BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;
  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometricEnabled';
  static const String _biometricUserIdKey = 'biometricUserId';

  /// Memeriksa apakah perangkat mendukung biometrik
  Future<bool> isBiometricAvailable() async {
    try {
      // Memeriksa apakah hardware mendukung biometrik
      final bool canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      
      // Memeriksa apakah perangkat mendukung biometrik atau PIN/Pattern/Password
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();
      
      return canAuthenticate;
    } on PlatformException catch (e) {
      debugPrint('Error checking biometric availability: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking biometric availability: $e');
      return false;
    }
  }

  /// Mendapatkan jenis biometrik yang tersedia pada perangkat
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      debugPrint('Error getting available biometrics: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error getting available biometrics: $e');
      return [];
    }
  }

  /// Melakukan autentikasi biometrik
  Future<bool> authenticate({
    String localizedReason = 'Autentikasi dengan sidik jari atau wajah untuk masuk',
    bool useErrorDialogs = true,
  }) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: localizedReason,
        options: AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: useErrorDialogs,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == auth_error.notAvailable) {
        debugPrint('Biometric authentication not available');
      } else if (e.code == auth_error.notEnrolled) {
        debugPrint('No biometrics enrolled on this device');
      } else if (e.code == auth_error.lockedOut) {
        debugPrint('Biometric authentication locked out due to too many attempts');
      } else if (e.code == auth_error.permanentlyLockedOut) {
        debugPrint('Biometric authentication permanently locked out');
      } else {
        debugPrint('Error during biometric authentication: ${e.message}');
      }
      return false;
    } catch (e) {
      debugPrint('Unexpected error during biometric authentication: $e');
      return false;
    }
  }

  /// Menyimpan status biometrik enabled/disabled
  Future<bool> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      debugPrint('Error saving biometric status: $e');
      return false;
    }
  }

  /// Mendapatkan status biometrik enabled/disabled
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      debugPrint('Error getting biometric status: $e');
      return false;
    }
  }

  /// Menyimpan user ID untuk autentikasi biometrik
  Future<bool> setBiometricUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_biometricUserIdKey, userId);
    } catch (e) {
      debugPrint('Error saving biometric user ID: $e');
      return false;
    }
  }

  /// Mendapatkan user ID yang tersimpan untuk autentikasi biometrik
  Future<String?> getBiometricUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_biometricUserIdKey);
    } catch (e) {
      debugPrint('Error getting biometric user ID: $e');
      return null;
    }
  }

  /// Menghapus data biometrik yang tersimpan
  Future<bool> clearBiometricData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricUserIdKey);
      return await prefs.setBool(_biometricEnabledKey, false);
    } catch (e) {
      debugPrint('Error clearing biometric data: $e');
      return false;
    }
  }

  /// Alias untuk kompatibilitas dengan kode yang ada
  Future<bool> isAvailable() async {
    return await isBiometricAvailable();
  }
}