import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

/// Service untuk mengelola pengaturan aplikasi
class SettingsService {
  final Logger _logger = Logger();
  
  // Kunci untuk shared preferences
  static const String _languageKey = 'app_language';
  static const String _themeModeKey = 'app_theme_mode';
  static const String _notificationEnabledKey = 'notification_enabled';
  
  /// Mendapatkan pengaturan bahasa aplikasi
  Future<String?> getLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_languageKey);
    } catch (e) {
      _logger.e('Error getting language setting: $e');
      return null;
    }
  }
  
  /// Mengatur bahasa aplikasi
  Future<bool> setLanguage(String languageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      return true;
    } catch (e) {
      _logger.e('Error setting language: $e');
      return false;
    }
  }
  
  /// Mendapatkan pengaturan tema aplikasi
  Future<int?> getThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_themeModeKey);
    } catch (e) {
      _logger.e('Error getting theme mode: $e');
      return null;
    }
  }
  
  /// Mengatur tema aplikasi
  Future<bool> setThemeMode(ThemeMode themeMode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, themeMode.index);
      return true;
    } catch (e) {
      _logger.e('Error setting theme mode: $e');
      return false;
    }
  }
  
  /// Mendapatkan status notifikasi
  Future<bool> isNotificationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_notificationEnabledKey) ?? true; // Default: enabled
    } catch (e) {
      _logger.e('Error checking notification status: $e');
      return true; // Default: enabled
    }
  }
  
  /// Mengatur status notifikasi
  Future<bool> setNotificationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationEnabledKey, enabled);
      return true;
    } catch (e) {
      _logger.e('Error setting notification status: $e');
      return false;
    }
  }
  
  /// Menghapus semua pengaturan dan mengembalikan ke default
  Future<bool> resetAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_languageKey);
      await prefs.remove(_themeModeKey);
      await prefs.remove(_notificationEnabledKey);
      return true;
    } catch (e) {
      _logger.e('Error resetting settings: $e');
      return false;
    }
  }
}
