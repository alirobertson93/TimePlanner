import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

import '../entities/notification.dart' as app;
import '../enums/notification_type.dart';

/// Interface for the notification service to enable testing
abstract class INotificationService {
  /// Initialize the notification service
  Future<void> initialize();

  /// Request permission to show notifications
  Future<bool> requestPermissions();

  /// Check if notifications are permitted
  Future<bool> areNotificationsEnabled();

  /// Show an immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    String? payload,
  });

  /// Schedule a notification for a future time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String? payload,
  });

  /// Cancel a specific notification
  Future<void> cancelNotification(int id);

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications();

  /// Get all pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications();
}

/// Service for managing system notifications using flutter_local_notifications
class NotificationService implements INotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Android notification channel configuration
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'time_planner_notifications',
    'Time Planner Notifications',
    description: 'Notifications for events and goal reminders',
    importance: Importance.high,
  );

  /// Callback for handling notification taps
  static void Function(NotificationResponse)? onNotificationTap;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data for scheduled notifications
    tz.initializeTimeZones();

    // Android initialization settings
    const androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS initialization settings
    const darwinInitSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    // Linux initialization settings
    const linuxInitSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
      macOS: darwinInitSettings,
      linux: linuxInitSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          _onBackgroundNotificationResponse,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    _isInitialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    onNotificationTap?.call(response);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // Handle background notification tap if needed
  }

  @override
  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    } else if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final result = await androidPlugin?.requestNotificationsPermission();
      return result ?? false;
    }
    // Linux and other platforms don't require explicit permission
    return true;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      final androidPlugin = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      return await androidPlugin?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS || Platform.isMacOS) {
      // iOS doesn't have a direct API to check, assume enabled after permission granted
      return true;
    }
    return true;
  }

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    String? body,
    String? payload,
  }) async {
    await _ensureInitialized();

    const androidDetails = AndroidNotificationDetails(
      'time_planner_notifications',
      'Time Planner Notifications',
      channelDescription: 'Notifications for events and goal reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledAt,
    String? payload,
  }) async {
    await _ensureInitialized();

    // Don't schedule if the time is in the past
    if (scheduledAt.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'time_planner_notifications',
      'Time Planner Notifications',
      channelDescription: 'Notifications for events and goal reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final tzScheduledAt = tz.TZDateTime.from(scheduledAt, tz.local);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledAt,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  @override
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  @override
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Helper method to convert a string notification ID to an integer for the plugin
  static int notificationIdFromString(String id) {
    return id.hashCode.abs() % 2147483647; // Ensure positive 32-bit int
  }

  /// Schedule a notification from an app Notification entity
  Future<void> scheduleFromNotification(app.Notification notification) async {
    await scheduleNotification(
      id: notificationIdFromString(notification.id),
      title: notification.title,
      body: notification.body,
      scheduledAt: notification.scheduledAt,
      payload: _buildPayload(notification),
    );
  }

  /// Cancel a notification using the app Notification entity
  Future<void> cancelFromNotification(app.Notification notification) async {
    await cancelNotification(notificationIdFromString(notification.id));
  }

  String _buildPayload(app.Notification notification) {
    final parts = <String>[notification.type.name];
    if (notification.eventId != null) {
      parts.add('event:${notification.eventId}');
    }
    if (notification.goalId != null) {
      parts.add('goal:${notification.goalId}');
    }
    return parts.join('|');
  }

  /// Parse a notification payload to extract type and IDs
  static NotificationPayload? parsePayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;

    final parts = payload.split('|');
    if (parts.isEmpty) return null;

    NotificationType? type;
    String? eventId;
    String? goalId;

    for (final part in parts) {
      if (part.startsWith('event:')) {
        eventId = part.substring(6);
      } else if (part.startsWith('goal:')) {
        goalId = part.substring(5);
      } else {
        // Try to parse as notification type
        type = NotificationType.values.where((t) => t.name == part).firstOrNull;
      }
    }

    return NotificationPayload(
      type: type,
      eventId: eventId,
      goalId: goalId,
    );
  }
}

/// Parsed notification payload data
class NotificationPayload {
  const NotificationPayload({
    this.type,
    this.eventId,
    this.goalId,
  });

  final NotificationType? type;
  final String? eventId;
  final String? goalId;
}
