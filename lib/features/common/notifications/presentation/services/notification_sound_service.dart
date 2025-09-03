import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/notification_type.dart';

enum NotificationSound {
  defaultSound('default', 'Default', 'notification_default'),
  gentle('gentle', 'Gentle', 'notification_gentle'),
  alert('alert', 'Alert', 'notification_alert'),
  chime('chime', 'Chime', 'notification_chime'),
  bell('bell', 'Bell', 'notification_bell'),
  pop('pop', 'Pop', 'notification_pop'),
  whistle('whistle', 'Whistle', 'notification_whistle'),
  none('none', 'Silent', null);

  const NotificationSound(this.id, this.displayName, this.fileName);

  final String id;
  final String displayName;
  final String? fileName;

  static NotificationSound fromId(String id) {
    return values.firstWhere(
      (sound) => sound.id == id,
      orElse: () => NotificationSound.defaultSound,
    );
  }
}

enum VibrationPattern {
  none('none', 'Tidak Ada', []),
  short('short', 'Pendek', [0, 200]),
  medium('medium', 'Sedang', [0, 300, 100, 300]),
  long('long', 'Panjang', [0, 500, 200, 500]),
  pulse('pulse', 'Pulse', [0, 100, 100, 100, 100, 100]),
  heartbeat('heartbeat', 'Heartbeat', [0, 200, 100, 200, 100, 400]),
  sos('sos', 'SOS', [0, 100, 100, 100, 100, 100, 200, 300, 200, 300, 200, 300, 200, 100, 100, 100, 100, 100]);

  const VibrationPattern(this.id, this.displayName, this.pattern);

  final String id;
  final String displayName;
  final List<int> pattern;

  static VibrationPattern fromId(String id) {
    return values.firstWhere(
      (pattern) => pattern.id == id,
      orElse: () => VibrationPattern.medium,
    );
  }
}

class NotificationSoundPreferences {
  final NotificationSound globalSound;
  final VibrationPattern globalVibration;
  final bool enableSoundInSilentMode;
  final bool enableVibrationInSilentMode;
  final Map<NotificationType, NotificationSound> soundByType;
  final Map<NotificationType, VibrationPattern> vibrationByType;
  final bool respectSystemSettings;
  final double volume;
  final bool enableQuietHours;
  final int quietHoursStart; // Hour (0-23)
  final int quietHoursEnd; // Hour (0-23)
  final NotificationSound quietHoursSound;
  final VibrationPattern quietHoursVibration;

  const NotificationSoundPreferences({
    this.globalSound = NotificationSound.defaultSound,
    this.globalVibration = VibrationPattern.medium,
    this.enableSoundInSilentMode = false,
    this.enableVibrationInSilentMode = true,
    this.soundByType = const {},
    this.vibrationByType = const {},
    this.respectSystemSettings = true,
    this.volume = 1.0,
    this.enableQuietHours = false,
    this.quietHoursStart = 22, // 10 PM
    this.quietHoursEnd = 7, // 7 AM
    this.quietHoursSound = NotificationSound.gentle,
    this.quietHoursVibration = VibrationPattern.short,
  });

  NotificationSoundPreferences copyWith({
    NotificationSound? globalSound,
    VibrationPattern? globalVibration,
    bool? enableSoundInSilentMode,
    bool? enableVibrationInSilentMode,
    Map<NotificationType, NotificationSound>? soundByType,
    Map<NotificationType, VibrationPattern>? vibrationByType,
    bool? respectSystemSettings,
    double? volume,
    bool? enableQuietHours,
    int? quietHoursStart,
    int? quietHoursEnd,
    NotificationSound? quietHoursSound,
    VibrationPattern? quietHoursVibration,
  }) {
    return NotificationSoundPreferences(
      globalSound: globalSound ?? this.globalSound,
      globalVibration: globalVibration ?? this.globalVibration,
      enableSoundInSilentMode: enableSoundInSilentMode ?? this.enableSoundInSilentMode,
      enableVibrationInSilentMode: enableVibrationInSilentMode ?? this.enableVibrationInSilentMode,
      soundByType: soundByType ?? this.soundByType,
      vibrationByType: vibrationByType ?? this.vibrationByType,
      respectSystemSettings: respectSystemSettings ?? this.respectSystemSettings,
      volume: volume ?? this.volume,
      enableQuietHours: enableQuietHours ?? this.enableQuietHours,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      quietHoursSound: quietHoursSound ?? this.quietHoursSound,
      quietHoursVibration: quietHoursVibration ?? this.quietHoursVibration,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'globalSound': globalSound.id,
      'globalVibration': globalVibration.id,
      'enableSoundInSilentMode': enableSoundInSilentMode,
      'enableVibrationInSilentMode': enableVibrationInSilentMode,
      'soundByType': soundByType.map((key, value) => MapEntry(key.value, value.id)),
      'vibrationByType': vibrationByType.map((key, value) => MapEntry(key.value, value.id)),
      'respectSystemSettings': respectSystemSettings,
      'volume': volume,
      'enableQuietHours': enableQuietHours,
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'quietHoursSound': quietHoursSound.id,
      'quietHoursVibration': quietHoursVibration.id,
    };
  }

  factory NotificationSoundPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationSoundPreferences(
      globalSound: NotificationSound.fromId(json['globalSound'] ?? 'default'),
      globalVibration: VibrationPattern.fromId(json['globalVibration'] ?? 'medium'),
      enableSoundInSilentMode: json['enableSoundInSilentMode'] ?? false,
      enableVibrationInSilentMode: json['enableVibrationInSilentMode'] ?? true,
      soundByType: (json['soundByType'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                NotificationType.values.firstWhere((type) => type.value == key),
                NotificationSound.fromId(value),
              )),
      vibrationByType: (json['vibrationByType'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(
                NotificationType.values.firstWhere((type) => type.value == key),
                VibrationPattern.fromId(value),
              )),
      respectSystemSettings: json['respectSystemSettings'] ?? true,
      volume: (json['volume'] ?? 1.0).toDouble(),
      enableQuietHours: json['enableQuietHours'] ?? false,
      quietHoursStart: json['quietHoursStart'] ?? 22,
      quietHoursEnd: json['quietHoursEnd'] ?? 7,
      quietHoursSound: NotificationSound.fromId(json['quietHoursSound'] ?? 'gentle'),
      quietHoursVibration: VibrationPattern.fromId(json['quietHoursVibration'] ?? 'short'),
    );
  }
}

class NotificationSoundService {
  static const String _prefsKey = 'notification_sound_preferences';
  static const MethodChannel _channel = MethodChannel('klik_jasa/notification_sound');
  
  final SharedPreferences _prefs;
  final Logger _logger = Logger();
  
  NotificationSoundPreferences _preferences = const NotificationSoundPreferences();
  
  NotificationSoundService(this._prefs);

  /// Initialize the service
  Future<void> initialize() async {
    try {
      await _loadPreferences();
      await _setupNativeSounds();
    } catch (e) {
      _logger.e('Failed to initialize notification sound service', error: e);
    }
  }

  /// Load preferences from storage
  Future<void> _loadPreferences() async {
    try {
      final prefsJson = _prefs.getString(_prefsKey);
      if (prefsJson != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          await compute(_parseJson, prefsJson),
        );
        _preferences = NotificationSoundPreferences.fromJson(json);
      }
    } catch (e) {
      _logger.e('Failed to load notification sound preferences', error: e);
      _preferences = const NotificationSoundPreferences();
    }
  }

  /// Save preferences to storage
  Future<void> _savePreferences() async {
    try {
      final json = _preferences.toJson();
      final jsonString = await compute(_encodeJson, json);
      await _prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      _logger.e('Failed to save notification sound preferences', error: e);
    }
  }

  /// Setup native sound files
  Future<void> _setupNativeSounds() async {
    try {
      if (Platform.isAndroid) {
        await _channel.invokeMethod('setupSounds', {
          'sounds': NotificationSound.values
              .where((sound) => sound.fileName != null)
              .map((sound) => {
                'id': sound.id,
                'fileName': sound.fileName,
                'displayName': sound.displayName,
              })
              .toList(),
        });
      }
    } catch (e) {
      _logger.e('Failed to setup native sounds', error: e);
    }
  }

  /// Get current preferences
  NotificationSoundPreferences get preferences => _preferences;

  /// Update global sound
  Future<void> updateGlobalSound(NotificationSound sound) async {
    _preferences = _preferences.copyWith(globalSound: sound);
    await _savePreferences();
  }

  /// Update global vibration
  Future<void> updateGlobalVibration(VibrationPattern pattern) async {
    _preferences = _preferences.copyWith(globalVibration: pattern);
    await _savePreferences();
  }

  /// Update sound for specific notification type
  Future<void> updateSoundForType(NotificationType type, NotificationSound sound) async {
    final updatedSoundByType = Map<NotificationType, NotificationSound>.from(_preferences.soundByType);
    updatedSoundByType[type] = sound;
    
    _preferences = _preferences.copyWith(soundByType: updatedSoundByType);
    await _savePreferences();
  }

  /// Update vibration for specific notification type
  Future<void> updateVibrationForType(NotificationType type, VibrationPattern pattern) async {
    final updatedVibrationByType = Map<NotificationType, VibrationPattern>.from(_preferences.vibrationByType);
    updatedVibrationByType[type] = pattern;
    
    _preferences = _preferences.copyWith(vibrationByType: updatedVibrationByType);
    await _savePreferences();
  }

  /// Update volume
  Future<void> updateVolume(double volume) async {
    final clampedVolume = volume.clamp(0.0, 1.0);
    _preferences = _preferences.copyWith(volume: clampedVolume);
    await _savePreferences();
  }

  /// Update quiet hours settings
  Future<void> updateQuietHours({
    bool? enabled,
    int? startHour,
    int? endHour,
    NotificationSound? sound,
    VibrationPattern? vibration,
  }) async {
    _preferences = _preferences.copyWith(
      enableQuietHours: enabled,
      quietHoursStart: startHour,
      quietHoursEnd: endHour,
      quietHoursSound: sound,
      quietHoursVibration: vibration,
    );
    await _savePreferences();
  }

  /// Update system settings respect
  Future<void> updateRespectSystemSettings(bool respect) async {
    _preferences = _preferences.copyWith(respectSystemSettings: respect);
    await _savePreferences();
  }

  /// Update silent mode settings
  Future<void> updateSilentModeSettings({
    bool? enableSound,
    bool? enableVibration,
  }) async {
    _preferences = _preferences.copyWith(
      enableSoundInSilentMode: enableSound,
      enableVibrationInSilentMode: enableVibration,
    );
    await _savePreferences();
  }

  /// Get sound for notification type
  NotificationSound getSoundForType(NotificationType type) {
    if (_isQuietHours()) {
      return _preferences.quietHoursSound;
    }
    
    return _preferences.soundByType[type] ?? _preferences.globalSound;
  }

  /// Get vibration for notification type
  VibrationPattern getVibrationForType(NotificationType type) {
    if (_isQuietHours()) {
      return _preferences.quietHoursVibration;
    }
    
    return _preferences.vibrationByType[type] ?? _preferences.globalVibration;
  }

  /// Check if currently in quiet hours
  bool _isQuietHours() {
    if (!_preferences.enableQuietHours) return false;
    
    final now = DateTime.now();
    final currentHour = now.hour;
    
    final start = _preferences.quietHoursStart;
    final end = _preferences.quietHoursEnd;
    
    if (start <= end) {
      // Same day range (e.g., 9 AM to 5 PM)
      return currentHour >= start && currentHour < end;
    } else {
      // Overnight range (e.g., 10 PM to 7 AM)
      return currentHour >= start || currentHour < end;
    }
  }

  /// Check if device is in silent mode
  Future<bool> _isDeviceInSilentMode() async {
    try {
      if (Platform.isAndroid) {
        final result = await _channel.invokeMethod<bool>('isInSilentMode');
        return result ?? false;
      } else if (Platform.isIOS) {
        // iOS doesn't provide a reliable way to check silent mode
        // We'll assume it's not in silent mode
        return false;
      }
    } catch (e) {
      _logger.e('Failed to check silent mode', error: e);
    }
    return false;
  }

  /// Should play sound for notification
  Future<bool> shouldPlaySound(NotificationType type) async {
    if (!_preferences.respectSystemSettings) {
      return getSoundForType(type) != NotificationSound.none;
    }
    
    final isInSilentMode = await _isDeviceInSilentMode();
    
    if (isInSilentMode && !_preferences.enableSoundInSilentMode) {
      return false;
    }
    
    return getSoundForType(type) != NotificationSound.none;
  }

  /// Should vibrate for notification
  Future<bool> shouldVibrate(NotificationType type) async {
    if (!_preferences.respectSystemSettings) {
      return getVibrationForType(type) != VibrationPattern.none;
    }
    
    final isInSilentMode = await _isDeviceInSilentMode();
    
    if (isInSilentMode && !_preferences.enableVibrationInSilentMode) {
      return false;
    }
    
    return getVibrationForType(type) != VibrationPattern.none;
  }

  /// Play notification sound
  Future<void> playNotificationSound(NotificationType type) async {
    try {
      final shouldPlay = await shouldPlaySound(type);
      if (!shouldPlay) return;
      
      final sound = getSoundForType(type);
      if (sound == NotificationSound.none || sound.fileName == null) return;
      
      if (Platform.isAndroid) {
        await _channel.invokeMethod('playSound', {
          'soundId': sound.id,
          'volume': _preferences.volume,
        });
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('playSound', {
          'soundFileName': sound.fileName,
          'volume': _preferences.volume,
        });
      }
    } catch (e) {
      _logger.e('Failed to play notification sound', error: e);
    }
  }

  /// Trigger notification vibration
  Future<void> triggerNotificationVibration(NotificationType type) async {
    try {
      final shouldVib = await shouldVibrate(type);
      if (!shouldVib) return;
      
      final pattern = getVibrationForType(type);
      if (pattern == VibrationPattern.none || pattern.pattern.isEmpty) return;
      
      await _channel.invokeMethod('vibrate', {
        'pattern': pattern.pattern,
      });
    } catch (e) {
      _logger.e('Failed to trigger notification vibration', error: e);
    }
  }

  /// Preview sound
  Future<void> previewSound(NotificationSound sound) async {
    try {
      if (sound == NotificationSound.none || sound.fileName == null) return;
      
      if (Platform.isAndroid) {
        await _channel.invokeMethod('playSound', {
          'soundId': sound.id,
          'volume': _preferences.volume,
        });
      } else if (Platform.isIOS) {
        await _channel.invokeMethod('playSound', {
          'soundFileName': sound.fileName,
          'volume': _preferences.volume,
        });
      }
    } catch (e) {
      _logger.e('Failed to preview sound', error: e);
    }
  }

  /// Preview vibration
  Future<void> previewVibration(VibrationPattern pattern) async {
    try {
      if (pattern == VibrationPattern.none || pattern.pattern.isEmpty) return;
      
      await _channel.invokeMethod('vibrate', {
        'pattern': pattern.pattern,
      });
    } catch (e) {
      _logger.e('Failed to preview vibration', error: e);
    }
  }

  /// Reset to defaults
  Future<void> resetToDefaults() async {
    _preferences = const NotificationSoundPreferences();
    await _savePreferences();
  }

  /// Get available sounds
  List<NotificationSound> get availableSounds => NotificationSound.values;

  /// Get available vibration patterns
  List<VibrationPattern> get availableVibrationPatterns => VibrationPattern.values;
}

// Helper functions for compute
Map<String, dynamic> _parseJson(String jsonString) {
  return Map<String, dynamic>.from(jsonDecode(jsonString));
}

String _encodeJson(Map<String, dynamic> json) {
  return jsonEncode(json);
}