import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Service untuk menangani autentikasi biometrik
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final Logger _logger = Logger();
  
  // Kunci untuk shared preferences
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricUserIdKey = 'biometric_user_id';
  
  /// Memeriksa apakah perangkat mendukung autentikasi biometrik
  Future<bool> checkBiometricAvailable() async {
    try {
      // Cek apakah hardware mendukung biometrik
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      
      return canAuthenticate;
    } on PlatformException catch (e) {
      _logger.e('Error checking biometric availability: $e');
      return false;
    }
  }
  
  /// Melakukan autentikasi biometrik
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      final isAvailable = await checkBiometricAvailable();
      if (!isAvailable) {
        return false;
      }
      
      return await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      _logger.e('Error authenticating with biometrics: $e');
      return false;
    }
  }
  
  /// Memeriksa apakah biometrik diaktifkan
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      _logger.e('Error checking if biometric is enabled: $e');
      return false;
    }
  }
  
  /// Mengaktifkan atau menonaktifkan biometrik
  Future<bool> setBiometricEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, value);
      return true;
    } catch (e) {
      _logger.e('Error setting biometric enabled: $e');
      return false;
    }
  }
  
  /// Menyimpan user ID untuk autentikasi biometrik
  Future<bool> setBiometricUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_biometricUserIdKey, userId);
      return true;
    } catch (e) {
      _logger.e('Error setting biometric user ID: $e');
      return false;
    }
  }
  
  /// Mendapatkan user ID yang tersimpan untuk autentikasi biometrik
  Future<String?> getBiometricUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_biometricUserIdKey);
    } catch (e) {
      _logger.e('Error getting biometric user ID: $e');
      return null;
    }
  }
  
  /// Menghapus semua data biometrik
  Future<bool> clearBiometricData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_biometricEnabledKey);
      await prefs.remove(_biometricUserIdKey);
      return true;
    } catch (e) {
      _logger.e('Error clearing biometric data: $e');
      return false;
    }
  }
}
