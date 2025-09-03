import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/notification_type.dart';

class NotificationAnalyticsEvent {
  final String id;
  final String messageId;
  final String userId;
  final NotificationType type;
  final String event; // 'sent', 'delivered', 'opened', 'clicked', 'dismissed'
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  final String platform;
  final String? appVersion;
  final String? deviceModel;
  final String? osVersion;

  const NotificationAnalyticsEvent({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.type,
    required this.event,
    required this.timestamp,
    this.metadata = const {},
    required this.platform,
    this.appVersion,
    this.deviceModel,
    this.osVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message_id': messageId,
      'user_id': userId,
      'notification_type': type.value,
      'event': event,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
      'platform': platform,
      'app_version': appVersion,
      'device_model': deviceModel,
      'os_version': osVersion,
    };
  }

  factory NotificationAnalyticsEvent.fromJson(Map<String, dynamic> json) {
    return NotificationAnalyticsEvent(
      id: json['id'],
      messageId: json['message_id'],
      userId: json['user_id'],
      type: NotificationType.fromString(json['notification_type']),
      event: json['event'],
      timestamp: DateTime.parse(json['timestamp']),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      platform: json['platform'],
      appVersion: json['app_version'],
      deviceModel: json['device_model'],
      osVersion: json['os_version'],
    );
  }
}

class NotificationMetrics {
  final int totalSent;
  final int totalDelivered;
  final int totalOpened;
  final int totalClicked;
  final int totalDismissed;
  final double deliveryRate;
  final double openRate;
  final double clickRate;
  final Map<NotificationType, int> typeBreakdown;
  final Map<String, int> hourlyBreakdown;
  final DateTime periodStart;
  final DateTime periodEnd;

  const NotificationMetrics({
    required this.totalSent,
    required this.totalDelivered,
    required this.totalOpened,
    required this.totalClicked,
    required this.totalDismissed,
    required this.deliveryRate,
    required this.openRate,
    required this.clickRate,
    required this.typeBreakdown,
    required this.hourlyBreakdown,
    required this.periodStart,
    required this.periodEnd,
  });

  Map<String, dynamic> toJson() {
    return {
      'total_sent': totalSent,
      'total_delivered': totalDelivered,
      'total_opened': totalOpened,
      'total_clicked': totalClicked,
      'total_dismissed': totalDismissed,
      'delivery_rate': deliveryRate,
      'open_rate': openRate,
      'click_rate': clickRate,
      'type_breakdown': typeBreakdown.map(
        (key, value) => MapEntry(key.value, value),
      ),
      'hourly_breakdown': hourlyBreakdown,
      'period_start': periodStart.toIso8601String(),
      'period_end': periodEnd.toIso8601String(),
    };
  }
}

class NotificationAnalyticsService {
  static const String _localEventsKey = 'notification_analytics_events';
  static const String _lastSyncKey = 'notification_analytics_last_sync';
  static const int _maxLocalEvents = 1000;
  static const Duration _syncInterval = Duration(hours: 1);

  final SupabaseClient _supabaseClient;
  final Logger _logger = Logger();

  NotificationAnalyticsService(this._supabaseClient);

  /// Track notification event
  Future<void> trackEvent({
    required String messageId,
    required String userId,
    required NotificationType type,
    required String event,
    Map<String, dynamic> metadata = const {},
    String? appVersion,
    String? deviceModel,
    String? osVersion,
  }) async {
    try {
      final analyticsEvent = NotificationAnalyticsEvent(
        id: _generateEventId(),
        messageId: messageId,
        userId: userId,
        type: type,
        event: event,
        timestamp: DateTime.now(),
        metadata: metadata,
        platform: _getPlatform(),
        appVersion: appVersion,
        deviceModel: deviceModel,
        osVersion: osVersion,
      );

      // Store locally first
      await _storeEventLocally(analyticsEvent);

      // Try to sync immediately if online
      await _syncEventsToServer();

      _logger.d('Notification event tracked: $event for message $messageId');
    } catch (e) {
      _logger.e('Failed to track notification event', error: e);
    }
  }

  /// Track notification sent
  Future<void> trackNotificationSent({
    required String messageId,
    required String userId,
    required NotificationType type,
    Map<String, dynamic> metadata = const {},
  }) async {
    await trackEvent(
      messageId: messageId,
      userId: userId,
      type: type,
      event: 'sent',
      metadata: metadata,
    );
  }

  /// Track notification delivered
  Future<void> trackNotificationDelivered({
    required String messageId,
    required String userId,
    required NotificationType type,
    Map<String, dynamic> metadata = const {},
  }) async {
    await trackEvent(
      messageId: messageId,
      userId: userId,
      type: type,
      event: 'delivered',
      metadata: metadata,
    );
  }

  /// Track notification opened
  Future<void> trackNotificationOpened({
    required String messageId,
    required String userId,
    required NotificationType type,
    Map<String, dynamic> metadata = const {},
  }) async {
    await trackEvent(
      messageId: messageId,
      userId: userId,
      type: type,
      event: 'opened',
      metadata: metadata,
    );
  }

  /// Track notification clicked
  Future<void> trackNotificationClicked({
    required String messageId,
    required String userId,
    required NotificationType type,
    String? actionId,
    Map<String, dynamic> metadata = const {},
  }) async {
    final enrichedMetadata = Map<String, dynamic>.from(metadata);
    if (actionId != null) {
      enrichedMetadata['action_id'] = actionId;
    }

    await trackEvent(
      messageId: messageId,
      userId: userId,
      type: type,
      event: 'clicked',
      metadata: enrichedMetadata,
    );
  }

  /// Track notification dismissed
  Future<void> trackNotificationDismissed({
    required String messageId,
    required String userId,
    required NotificationType type,
    Map<String, dynamic> metadata = const {},
  }) async {
    await trackEvent(
      messageId: messageId,
      userId: userId,
      type: type,
      event: 'dismissed',
      metadata: metadata,
    );
  }

  /// Store event locally
  Future<void> _storeEventLocally(NotificationAnalyticsEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_localEventsKey) ?? '[]';
      final events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));

      events.add(event.toJson());

      // Keep only the most recent events
      if (events.length > _maxLocalEvents) {
        events.removeRange(0, events.length - _maxLocalEvents);
      }

      await prefs.setString(_localEventsKey, jsonEncode(events));
    } catch (e) {
      _logger.e('Failed to store analytics event locally', error: e);
    }
  }

  /// Sync events to server
  Future<void> _syncEventsToServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSync = prefs.getString(_lastSyncKey);

      // Check if we should sync based on interval
      if (lastSync != null) {
        final lastSyncTime = DateTime.parse(lastSync);
        if (DateTime.now().difference(lastSyncTime) < _syncInterval) {
          return; // Too soon to sync again
        }
      }

      final eventsJson = prefs.getString(_localEventsKey) ?? '[]';
      final events = List<Map<String, dynamic>>.from(jsonDecode(eventsJson));

      if (events.isEmpty) return;

      // Send events to Supabase
      await _supabaseClient.from('notification_analytics').insert(events);

      // Clear local events after successful sync
      await prefs.setString(_localEventsKey, '[]');
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      _logger.i(
        'Synced ${events.length} notification analytics events to server',
      );
    } catch (e) {
      _logger.e('Failed to sync analytics events to server', error: e);
      // Keep events locally for next sync attempt
    }
  }

  /// Force sync events to server
  Future<void> forceSyncEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastSyncKey); // Remove last sync time to force sync
      await _syncEventsToServer();
    } catch (e) {
      _logger.e('Failed to force sync analytics events', error: e);
    }
  }

  /// Get notification metrics for a period
  Future<NotificationMetrics> getMetrics({
    required DateTime startDate,
    required DateTime endDate,
    String? userId,
    NotificationType? type,
  }) async {
    try {
      var query = _supabaseClient
          .from('notification_analytics')
          .select()
          .gte('timestamp', startDate.toIso8601String())
          .lte('timestamp', endDate.toIso8601String());

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (type != null) {
        query = query.eq('notification_type', type.value);
      }

      final response = await query;
      final events = response as List<dynamic>;

      return _calculateMetrics(events, startDate, endDate);
    } catch (e) {
      _logger.e('Failed to get notification metrics', error: e);
      rethrow;
    }
  }

  /// Calculate metrics from events
  NotificationMetrics _calculateMetrics(
    List<dynamic> events,
    DateTime startDate,
    DateTime endDate,
  ) {
    final sentEvents = events.where((e) => e['event'] == 'sent').length;
    final deliveredEvents = events
        .where((e) => e['event'] == 'delivered')
        .length;
    final openedEvents = events.where((e) => e['event'] == 'opened').length;
    final clickedEvents = events.where((e) => e['event'] == 'clicked').length;
    final dismissedEvents = events
        .where((e) => e['event'] == 'dismissed')
        .length;

    final deliveryRate = sentEvents > 0
        ? (deliveredEvents / sentEvents) * 100
        : 0.0;
    final openRate = deliveredEvents > 0
        ? (openedEvents / deliveredEvents) * 100
        : 0.0;
    final clickRate = openedEvents > 0
        ? (clickedEvents / openedEvents) * 100
        : 0.0;

    // Type breakdown
    final typeBreakdown = <NotificationType, int>{};
    for (final event in events) {
      final type = NotificationType.fromString(event['notification_type']);
      typeBreakdown[type] = (typeBreakdown[type] ?? 0) + 1;
    }

    // Hourly breakdown
    final hourlyBreakdown = <String, int>{};
    for (final event in events) {
      final timestamp = DateTime.parse(event['timestamp']);
      final hour = timestamp.hour.toString().padLeft(2, '0');
      hourlyBreakdown[hour] = (hourlyBreakdown[hour] ?? 0) + 1;
    }

    return NotificationMetrics(
      totalSent: sentEvents,
      totalDelivered: deliveredEvents,
      totalOpened: openedEvents,
      totalClicked: clickedEvents,
      totalDismissed: dismissedEvents,
      deliveryRate: deliveryRate,
      openRate: openRate,
      clickRate: clickRate,
      typeBreakdown: typeBreakdown,
      hourlyBreakdown: hourlyBreakdown,
      periodStart: startDate,
      periodEnd: endDate,
    );
  }

  /// Get user engagement score
  Future<double> getUserEngagementScore(String userId, {int days = 30}) async {
    try {
      final endDate = DateTime.now();
      final startDate = endDate.subtract(Duration(days: days));

      final metrics = await getMetrics(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      );

      // Calculate engagement score based on open rate and click rate
      final engagementScore =
          (metrics.openRate * 0.6) + (metrics.clickRate * 0.4);
      return engagementScore.clamp(0.0, 100.0);
    } catch (e) {
      _logger.e('Failed to calculate user engagement score', error: e);
      return 0.0;
    }
  }

  /// Get notification performance by type
  Future<Map<NotificationType, NotificationMetrics>> getPerformanceByType({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final performanceMap = <NotificationType, NotificationMetrics>{};

    for (final type in NotificationType.values) {
      try {
        final metrics = await getMetrics(
          startDate: startDate,
          endDate: endDate,
          type: type,
        );
        performanceMap[type] = metrics;
      } catch (e) {
        _logger.e('Failed to get performance for type ${type.value}', error: e);
      }
    }

    return performanceMap;
  }

  /// Get local events count
  Future<int> getLocalEventsCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_localEventsKey) ?? '[]';
      final events = List<dynamic>.from(jsonDecode(eventsJson));
      return events.length;
    } catch (e) {
      _logger.e('Failed to get local events count', error: e);
      return 0;
    }
  }

  /// Clear local events
  Future<void> clearLocalEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localEventsKey, '[]');
      _logger.i('Local analytics events cleared');
    } catch (e) {
      _logger.e('Failed to clear local events', error: e);
    }
  }

  /// Generate unique event ID
  String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'evt_${timestamp}_$random';
  }

  /// Get platform string
  String _getPlatform() {
    // This would be replaced with actual platform detection
    return 'flutter';
  }
}
