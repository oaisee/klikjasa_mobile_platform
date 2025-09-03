import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import '../../domain/entities/notification_type.dart';

class NotificationPreferences {
  final bool pushNotificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool inAppNotificationsEnabled;
  final Map<NotificationType, bool> typePreferences;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final bool groupSimilarNotifications;
  final int maxNotificationsPerHour;

  const NotificationPreferences({
    this.pushNotificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.inAppNotificationsEnabled = true,
    this.typePreferences = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    this.groupSimilarNotifications = true,
    this.maxNotificationsPerHour = 10,
  });

  NotificationPreferences copyWith({
    bool? pushNotificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? inAppNotificationsEnabled,
    Map<NotificationType, bool>? typePreferences,
    String? quietHoursStart,
    String? quietHoursEnd,
    bool? groupSimilarNotifications,
    int? maxNotificationsPerHour,
  }) {
    return NotificationPreferences(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      inAppNotificationsEnabled:
          inAppNotificationsEnabled ?? this.inAppNotificationsEnabled,
      typePreferences: typePreferences ?? this.typePreferences,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      groupSimilarNotifications:
          groupSimilarNotifications ?? this.groupSimilarNotifications,
      maxNotificationsPerHour:
          maxNotificationsPerHour ?? this.maxNotificationsPerHour,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'inAppNotificationsEnabled': inAppNotificationsEnabled,
      'typePreferences': typePreferences.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'quietHoursStart': quietHoursStart,
      'quietHoursEnd': quietHoursEnd,
      'groupSimilarNotifications': groupSimilarNotifications,
      'maxNotificationsPerHour': maxNotificationsPerHour,
    };
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final typePrefsMap = <NotificationType, bool>{};
    if (json['typePreferences'] != null) {
      final typePrefs = Map<String, bool>.from(json['typePreferences']);
      for (final entry in typePrefs.entries) {
        try {
          final type = NotificationType.fromString(entry.key);
          typePrefsMap[type] = entry.value;
        } catch (e) {
          // Skip invalid notification types
        }
      }
    }

    return NotificationPreferences(
      pushNotificationsEnabled: json['pushNotificationsEnabled'] ?? true,
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      inAppNotificationsEnabled: json['inAppNotificationsEnabled'] ?? true,
      typePreferences: typePrefsMap,
      quietHoursStart: json['quietHoursStart'],
      quietHoursEnd: json['quietHoursEnd'],
      groupSimilarNotifications: json['groupSimilarNotifications'] ?? true,
      maxNotificationsPerHour: json['maxNotificationsPerHour'] ?? 10,
    );
  }

  bool isTypeEnabled(NotificationType type) {
    return typePreferences[type] ?? true;
  }

  bool isInQuietHours() {
    if (quietHoursStart == null || quietHoursEnd == null) return false;

    final now = DateTime.now();
    final currentTime =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Simple time comparison (assumes same day)
    return currentTime.compareTo(quietHoursStart!) >= 0 &&
        currentTime.compareTo(quietHoursEnd!) <= 0;
  }
}

class NotificationPreferencesService {
  static const String _prefsKey = 'notification_preferences';
  static const String _notificationCountKey = 'notification_count_';

  final Logger _logger = Logger();
  NotificationPreferences? _cachedPreferences;

  /// Get notification preferences
  Future<NotificationPreferences> getPreferences() async {
    if (_cachedPreferences != null) {
      return _cachedPreferences!;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final prefsJson = prefs.getString(_prefsKey);

      if (prefsJson != null) {
        final Map<String, dynamic> json = Map<String, dynamic>.from(
          // Parse JSON string
          prefsJson.split(',').fold<Map<String, dynamic>>({}, (map, item) {
            final parts = item.split(':');
            if (parts.length == 2) {
              final key = parts[0]
                  .trim()
                  .replaceAll('"', '')
                  .replaceAll('{', '')
                  .replaceAll('}', '');
              final value = parts[1]
                  .trim()
                  .replaceAll('"', '')
                  .replaceAll('{', '')
                  .replaceAll('}', '');

              // Convert string values to appropriate types
              if (value == 'true') {
                map[key] = true;
              } else if (value == 'false') {
                map[key] = false;
              } else if (int.tryParse(value) != null) {
                map[key] = int.parse(value);
              } else {
                map[key] = value;
              }
            }
            return map;
          }),
        );

        _cachedPreferences = NotificationPreferences.fromJson(json);
      } else {
        _cachedPreferences = const NotificationPreferences();
      }
    } catch (e) {
      _logger.e('Failed to load notification preferences', error: e);
      _cachedPreferences = const NotificationPreferences();
    }

    return _cachedPreferences!;
  }

  /// Save notification preferences
  Future<void> savePreferences(NotificationPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = preferences.toJson();

      // Convert to simple string format for SharedPreferences
      final jsonString = json.entries
          .map((e) => '"${e.key}":"${e.value}"')
          .join(',');
      await prefs.setString(_prefsKey, '{$jsonString}');

      _cachedPreferences = preferences;
      _logger.i('Notification preferences saved successfully');
    } catch (e) {
      _logger.e('Failed to save notification preferences', error: e);
      rethrow;
    }
  }

  /// Update specific preference
  Future<void> updatePreference<T>(String key, T value) async {
    final currentPrefs = await getPreferences();
    NotificationPreferences updatedPrefs;

    switch (key) {
      case 'pushNotificationsEnabled':
        updatedPrefs = currentPrefs.copyWith(
          pushNotificationsEnabled: value as bool,
        );
        break;
      case 'soundEnabled':
        updatedPrefs = currentPrefs.copyWith(soundEnabled: value as bool);
        break;
      case 'vibrationEnabled':
        updatedPrefs = currentPrefs.copyWith(vibrationEnabled: value as bool);
        break;
      case 'inAppNotificationsEnabled':
        updatedPrefs = currentPrefs.copyWith(
          inAppNotificationsEnabled: value as bool,
        );
        break;
      case 'groupSimilarNotifications':
        updatedPrefs = currentPrefs.copyWith(
          groupSimilarNotifications: value as bool,
        );
        break;
      case 'maxNotificationsPerHour':
        updatedPrefs = currentPrefs.copyWith(
          maxNotificationsPerHour: value as int,
        );
        break;
      case 'quietHoursStart':
        updatedPrefs = currentPrefs.copyWith(quietHoursStart: value as String?);
        break;
      case 'quietHoursEnd':
        updatedPrefs = currentPrefs.copyWith(quietHoursEnd: value as String?);
        break;
      default:
        throw ArgumentError('Unknown preference key: $key');
    }

    await savePreferences(updatedPrefs);
  }

  /// Update notification type preference
  Future<void> updateTypePreference(NotificationType type, bool enabled) async {
    final currentPrefs = await getPreferences();
    final updatedTypePrefs = Map<NotificationType, bool>.from(
      currentPrefs.typePreferences,
    );
    updatedTypePrefs[type] = enabled;

    final updatedPrefs = currentPrefs.copyWith(
      typePreferences: updatedTypePrefs,
    );
    await savePreferences(updatedPrefs);
  }

  /// Check if notification should be shown based on preferences
  Future<bool> shouldShowNotification(NotificationType type) async {
    final prefs = await getPreferences();

    // Check if push notifications are enabled
    if (!prefs.pushNotificationsEnabled) return false;

    // Check if this type is enabled
    if (!prefs.isTypeEnabled(type)) return false;

    // Check quiet hours
    if (prefs.isInQuietHours()) {
      // Only show high priority notifications during quiet hours
      return type.isHighPriority;
    }

    // Check rate limiting
    if (await _isRateLimited(prefs.maxNotificationsPerHour)) {
      // Only show high priority notifications when rate limited
      return type.isHighPriority;
    }

    return true;
  }

  /// Check if notifications are rate limited
  Future<bool> _isRateLimited(int maxPerHour) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final hourKey =
          '$_notificationCountKey${now.year}_${now.month}_${now.day}_${now.hour}';

      final count = prefs.getInt(hourKey) ?? 0;
      return count >= maxPerHour;
    } catch (e) {
      _logger.e('Failed to check rate limit', error: e);
      return false;
    }
  }

  /// Increment notification count for rate limiting
  Future<void> incrementNotificationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final hourKey =
          '$_notificationCountKey${now.year}_${now.month}_${now.day}_${now.hour}';

      final count = prefs.getInt(hourKey) ?? 0;
      await prefs.setInt(hourKey, count + 1);

      // Clean up old counts (keep only last 24 hours)
      await _cleanupOldCounts();
    } catch (e) {
      _logger.e('Failed to increment notification count', error: e);
    }
  }

  /// Clean up old notification counts
  Future<void> _cleanupOldCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where(
        (key) => key.startsWith(_notificationCountKey),
      );
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(hours: 24));

      for (final key in keys) {
        final parts = key.replaceFirst(_notificationCountKey, '').split('_');
        if (parts.length == 4) {
          try {
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            final hour = int.parse(parts[3]);

            final keyTime = DateTime(year, month, day, hour);
            if (keyTime.isBefore(cutoff)) {
              await prefs.remove(key);
            }
          } catch (e) {
            // Invalid key format, remove it
            await prefs.remove(key);
          }
        }
      }
    } catch (e) {
      _logger.e('Failed to cleanup old notification counts', error: e);
    }
  }

  /// Reset preferences to default
  Future<void> resetToDefaults() async {
    const defaultPrefs = NotificationPreferences();
    await savePreferences(defaultPrefs);
  }

  /// Clear cached preferences
  void clearCache() {
    _cachedPreferences = null;
  }
}
