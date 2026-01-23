import 'dart:async';

import '../entities/notification.dart' as app;
import '../enums/notification_status.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_service.dart';

/// Service that schedules and delivers notifications using the system notification service.
/// This bridges the app's notification repository with the platform notification system.
class NotificationSchedulerService {
  NotificationSchedulerService({
    required this.notificationRepository,
    required this.notificationService,
  });

  final INotificationRepository notificationRepository;
  final INotificationService notificationService;

  Timer? _deliveryTimer;

  /// Initialize the scheduler and schedule all pending notifications
  Future<void> initialize() async {
    await notificationService.initialize();
    await _schedulePendingNotifications();
    _startDeliveryTimer();
  }

  /// Schedule all pending notifications from the repository
  Future<void> _schedulePendingNotifications() async {
    final pendingNotifications = await notificationRepository.getPendingToDeliver();
    
    for (final notification in pendingNotifications) {
      await _scheduleSystemNotification(notification);
    }
  }

  /// Schedule a system notification for an app notification
  Future<void> _scheduleSystemNotification(app.Notification notification) async {
    final now = DateTime.now();
    
    if (notification.scheduledAt.isBefore(now)) {
      // Notification is past due, show immediately
      await notificationService.showNotification(
        id: NotificationService.notificationIdFromString(notification.id),
        title: notification.title,
        body: notification.body,
        payload: _buildPayload(notification),
      );
      
      // Mark as delivered in repository
      await notificationRepository.markDelivered(notification.id);
    } else {
      // Schedule for future delivery
      await notificationService.scheduleNotification(
        id: NotificationService.notificationIdFromString(notification.id),
        title: notification.title,
        body: notification.body,
        scheduledAt: notification.scheduledAt,
        payload: _buildPayload(notification),
      );
    }
  }

  /// Schedule a new notification
  Future<void> scheduleNotification(app.Notification notification) async {
    // Save to repository first
    await notificationRepository.save(notification);
    
    // Then schedule with system
    await _scheduleSystemNotification(notification);
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(String notificationId) async {
    // Cancel from system
    await notificationService.cancelNotification(
      NotificationService.notificationIdFromString(notificationId),
    );
    
    // Update status in repository
    final notification = await notificationRepository.getById(notificationId);
    if (notification != null && notification.isPending) {
      await notificationRepository.save(
        notification.copyWith(status: NotificationStatus.cancelled),
      );
    }
  }

  /// Cancel all notifications for a specific event
  Future<void> cancelNotificationsForEvent(String eventId) async {
    final notifications = await notificationRepository.getByEventId(eventId);
    
    for (final notification in notifications) {
      if (notification.isPending) {
        await cancelNotification(notification.id);
      }
    }
  }

  /// Cancel all notifications for a specific goal
  Future<void> cancelNotificationsForGoal(String goalId) async {
    final notifications = await notificationRepository.getByGoalId(goalId);
    
    for (final notification in notifications) {
      if (notification.isPending) {
        await cancelNotification(notification.id);
      }
    }
  }

  /// Start a periodic timer to check for notifications that need delivery
  void _startDeliveryTimer() {
    // Check every minute for notifications that should be delivered
    _deliveryTimer?.cancel();
    _deliveryTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _checkAndDeliverNotifications(),
    );
  }

  /// Check for notifications that should be delivered now and mark them
  Future<void> _checkAndDeliverNotifications() async {
    final pendingNotifications = await notificationRepository.getPendingToDeliver();
    
    for (final notification in pendingNotifications) {
      // The system notification service handles the actual delivery timing,
      // but we update our repository when it's time
      await notificationRepository.markDelivered(notification.id);
    }
  }

  /// Refresh scheduled notifications (e.g., after app restart or timezone change)
  Future<void> refreshScheduledNotifications() async {
    // Cancel all system notifications
    await notificationService.cancelAllNotifications();
    
    // Re-schedule all pending notifications
    await _schedulePendingNotifications();
  }

  /// Clean up resources
  void dispose() {
    _deliveryTimer?.cancel();
    _deliveryTimer = null;
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
}
