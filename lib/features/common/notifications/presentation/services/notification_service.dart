import 'dart:async';

import 'package:flutter/material.dart' hide Notification;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:klik_jasa/core/utils/logger.dart';
import 'package:klik_jasa/features/common/notifications/data/datasources/notification_realtime_subscription.dart';
import 'package:klik_jasa/features/common/notifications/data/models/notification_model.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification.dart';
import 'package:klik_jasa/features/common/notifications/domain/entities/notification_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_preferences_service.dart';
import 'notification_analytics_service.dart';
import 'notification_grouping_service.dart';
import 'notification_sound_service.dart';

/// Layanan singleton untuk mengelola notifikasi realtime secara global.
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final Logger _logger = Logger();
  NotificationRealtimeSubscription? _subscription;
  GlobalKey<ScaffoldMessengerState>? _scaffoldMessengerKey;

  // Services
  NotificationPreferencesService? _preferencesService;
  NotificationAnalyticsService? _analyticsService;
  NotificationGroupingService? _groupingService;
  NotificationSoundService? _soundService;

  // Stream controller untuk menyiarkan notifikasi yang masuk
  final _notificationStreamController =
      StreamController<Notification>.broadcast();
  Stream<Notification> get notificationStream =>
      _notificationStreamController.stream;

  bool _isInitialized = false;

  /// Inisialisasi layanan dengan GlobalKey dari MaterialApp
  Future<void> initialize(GlobalKey<ScaffoldMessengerState> key) async {
    if (_isInitialized) {
      _logger.i('NotificationService sudah diinisialisasi');
      return;
    }

    try {
      _scaffoldMessengerKey = key;

      // Initialize SharedPreferences
      final prefs = await SharedPreferences.getInstance();

      // Initialize all services
      _preferencesService = NotificationPreferencesService();
      _analyticsService = NotificationAnalyticsService(
        Supabase.instance.client,
      );
      _soundService = NotificationSoundService(prefs);

      // Initialize preferences service (no initialize method needed)
      // await _preferencesService!.initialize();

      // Initialize analytics service (no initialize method needed)
      // await _analyticsService!.initialize();

      // Initialize sound service
      await _soundService!.initialize();

      // Initialize grouping service
      // TODO: Initialize grouping service properly

      _isInitialized = true;
      _logger.i('NotificationService berhasil diinisialisasi');
    } catch (e) {
      _logger.e('Gagal menginisialisasi NotificationService: $e');
      rethrow;
    }
  }

  /// Memulai listening notifikasi realtime untuk user tertentu.
  Future<void> startListening(String userId) async {
    if (!_isInitialized) {
      throw StateError(
        'NotificationService belum diinisialisasi. Panggil initialize() terlebih dahulu.',
      );
    }

    if (_subscription != null) {
      _logger.i('Subscription sudah berjalan, tidak memulai yang baru.');
      return;
    }
    _logger.i('Memulai listening notifikasi realtime untuk user $userId');

    // Start listening for notifications
    _logger.i('Starting notification listening for user: $userId');

    _subscription = NotificationRealtimeSubscription(
      supabaseClient: Supabase.instance.client,
      userId: userId,
      onNotificationReceived: _onNotificationReceived,
      onNotificationUpdated: _onNotificationUpdated,
      onNotificationDeleted: _onNotificationDeleted,
    );
    _subscription?.startSubscription();
  }

  /// Menghentikan listening notifikasi realtime.
  Future<void> stopListening() async {
    _logger.i('Menghentikan listening notifikasi realtime');

    // Stop notification listening
    _logger.i('Stopping notification listening');

    _subscription?.stopSubscription();
    _subscription = null;
  }

  /// Handler untuk notifikasi baru yang diterima dari Supabase.
  Future<void> _onNotificationReceived(NotificationModel notification) async {
    _logger.i('Notifikasi baru diterima via service: ${notification.id}');

    try {
      final entity = notification.toEntity();

      // Check preferences
      if (_preferencesService != null) {
        final shouldShow = await _preferencesService!.shouldShowNotification(
          entity.type,
        );
        if (!shouldShow) {
          _logger.i('Notifikasi dilewati berdasarkan preferensi pengguna');
          return;
        }
      }

      // Track analytics
      if (_analyticsService != null) {
        // TODO: Implement trackNotificationReceived method in analytics service
        _logger.i('Notification received tracked: ${entity.id}');
      }

      // Process for grouping
      if (_groupingService != null) {
        await _groupingService!.processNotification(entity);
      }

      // Play sound and vibration
      if (_soundService != null) {
        await _soundService!.playNotificationSound(entity.type);
        await _soundService!.triggerNotificationVibration(entity.type);
      }

      // Add to stream
      _notificationStreamController.add(entity);

      // Show in-app notification
      await _showInAppNotification(notification);
    } catch (e) {
      _logger.e('Error processing received notification: $e');
    }
  }

  /// Handler untuk notifikasi yang diperbarui.
  Future<void> _onNotificationUpdated(NotificationModel notification) async {
    _logger.i('Notifikasi diperbarui via service: ${notification.id}');

    try {
      final entity = notification.toEntity();

      // Track analytics
      if (_analyticsService != null) {
        // TODO: Implement trackNotificationUpdated method in analytics service
        _logger.i('Notification updated tracked: ${notification.id}');
      }

      // Add to stream
      _notificationStreamController.add(entity);
    } catch (e) {
      _logger.e('Error processing updated notification: $e');
    }
  }

  /// Handler untuk notifikasi yang dihapus.
  Future<void> _onNotificationDeleted(int notificationId) async {
    _logger.i('Notifikasi dihapus via service: $notificationId');

    try {
      // Track analytics
      if (_analyticsService != null) {
        // TODO: Implement trackNotificationDeleted method in analytics service
        _logger.i('Notification deleted tracked: $notificationId');
      }
    } catch (e) {
      _logger.e('Error processing deleted notification: $e');
    }
  }

  /// Menampilkan notifikasi dalam aplikasi (SnackBar).
  Future<void> _showInAppNotification(NotificationModel notification) async {
    try {
      // Check if in-app notifications are enabled
      if (_preferencesService != null) {
        // TODO: Add enableInAppNotifications property to NotificationPreferences
        // final preferences = await _preferencesService!.getPreferences();
        // if (!preferences.enableInAppNotifications) {
        //   return;
        // }
      }

      // Periksa apakah ScaffoldMessengerState masih aktif dan mounted
      if (_scaffoldMessengerKey?.currentState != null &&
          _scaffoldMessengerKey!.currentState!.mounted) {
        _scaffoldMessengerKey!.currentState!.showSnackBar(
          SnackBar(
            content: Text('${notification.title}: ${notification.body}'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Lihat',
              onPressed: () async {
                // Track click analytics
                if (_analyticsService != null) {
                  await _analyticsService!.trackNotificationClicked(
                    messageId: notification.id.toString(),
                    type: notification.type,
                    userId: notification.recipientUserId,
                  );
                }
                // TODO: Implementasi navigasi ke halaman notifikasi
              },
            ),
          ),
        );
      } else {
        _logger.w(
          'ScaffoldMessengerState tidak tersedia atau tidak mounted, melewati tampilan SnackBar',
        );
      }
    } catch (e) {
      _logger.e('Error saat menampilkan in-app notification: $e');
    }
  }



  /// Get preferences service
  NotificationPreferencesService? get preferencesService => _preferencesService;

  /// Get analytics service
  NotificationAnalyticsService? get analyticsService => _analyticsService;

  /// Get grouping service
  NotificationGroupingService? get groupingService => _groupingService;

  /// Get sound service
  NotificationSoundService? get soundService => _soundService;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Handle notification action from system
  Future<void> handleNotificationAction(
    String actionId,
    Map<String, dynamic> data,
  ) async {
    try {
      _logger.i('Handling notification action: $actionId');

      // Track analytics
      if (_analyticsService != null) {
        _logger.i('Analytics tracking for action: $actionId');
      }

      // Handle grouping actions
      if (_groupingService != null) {
        await _groupingService!.handleNotificationAction(actionId, data);
      }
    } catch (e) {
      _logger.e('Error handling notification action: $e');
    }
  }

  /// Send notification to user
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    String? relatedEntityType,
    String? relatedEntityId,
    Map<String, dynamic>? metadata,
    String? actionUrl,
  }) async {
    try {
      // FCM service implementation would go here
      // For now, we'll just log the notification
      _logger.i('Notification to user $userId: $title - $body');
    } catch (e) {
      _logger.e('Error sending notification to user: $e');
    }
  }

  /// Send notification to topic
  Future<void> sendNotificationToTopic({
    required String topic,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, dynamic>? data,
  }) async {
    try {
      // FCM service implementation would go here
      // For now, we'll just log the notification
      _logger.i('Notification to topic $topic: $title - $body');
    } catch (e) {
      _logger.e('Error sending notification to topic: $e');
    }
  }

  /// Membersihkan resource saat tidak lagi digunakan.
  Future<void> dispose() async {
    _notificationStreamController.close();
    await stopListening();

    // Dispose all services
    _groupingService?.clearAllGroups();

    _isInitialized = false;
  }
}
