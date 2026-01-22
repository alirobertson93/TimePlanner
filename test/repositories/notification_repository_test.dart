import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart'
    hide Notification;
import 'package:time_planner/data/repositories/notification_repository.dart';
import 'package:time_planner/domain/entities/notification.dart';
import 'package:time_planner/domain/enums/notification_type.dart';
import 'package:time_planner/domain/enums/notification_status.dart';

void main() {
  late AppDatabase database;
  late NotificationRepository repository;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = NotificationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('NotificationRepository', () {
    test('save and getById returns the saved notification', () async {
      // Arrange
      final notification = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Event Starting Soon',
        body: 'Team Meeting starts in 15 minutes',
        eventId: 'event_1',
        scheduledAt: DateTime.now().add(const Duration(minutes: 15)),
        status: NotificationStatus.pending,
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(notification);
      final retrieved = await repository.getById('notif_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('notif_1'));
      expect(retrieved.type, equals(NotificationType.eventReminder));
      expect(retrieved.title, equals('Event Starting Soon'));
      expect(retrieved.eventId, equals('event_1'));
      expect(retrieved.status, equals(NotificationStatus.pending));
    });

    test('save updates existing notification', () async {
      // Arrange
      final notification = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Event Starting',
        scheduledAt: DateTime.now(),
        status: NotificationStatus.pending,
        createdAt: DateTime.now(),
      );

      await repository.save(notification);

      // Act
      final updated = notification.markDelivered();
      await repository.save(updated);
      final retrieved = await repository.getById('notif_1');

      // Assert
      expect(retrieved!.status, equals(NotificationStatus.delivered));
      expect(retrieved.deliveredAt, isNotNull);
    });

    test('delete removes notification from database', () async {
      // Arrange
      final notification = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Test',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await repository.save(notification);

      // Act
      await repository.delete('notif_1');
      final retrieved = await repository.getById('notif_1');

      // Assert
      expect(retrieved, isNull);
    });

    test('getById returns null for non-existent notification', () async {
      // Act
      final retrieved = await repository.getById('non_existent');

      // Assert
      expect(retrieved, isNull);
    });

    test('getAll returns all notifications', () async {
      // Arrange
      final notif1 = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Event 1',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final notif2 = Notification(
        id: 'notif_2',
        type: NotificationType.goalProgress,
        title: 'Goal Progress',
        goalId: 'goal_1',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final notif3 = Notification(
        id: 'notif_3',
        type: NotificationType.conflictWarning,
        title: 'Schedule Conflict',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(notif1);
      await repository.save(notif2);
      await repository.save(notif3);
      final notifications = await repository.getAll();

      // Assert
      expect(notifications.length, equals(3));
    });

    test('getByEventId returns notifications for specific event', () async {
      // Arrange
      final notif1 = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Event 1 Reminder',
        eventId: 'event_1',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final notif2 = Notification(
        id: 'notif_2',
        type: NotificationType.eventReminder,
        title: 'Event 2 Reminder',
        eventId: 'event_2',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await repository.save(notif1);
      await repository.save(notif2);

      // Act
      final event1Notifications = await repository.getByEventId('event_1');

      // Assert
      expect(event1Notifications.length, equals(1));
      expect(event1Notifications[0].eventId, equals('event_1'));
    });

    test('getByGoalId returns notifications for specific goal', () async {
      // Arrange
      final notif1 = Notification(
        id: 'notif_1',
        type: NotificationType.goalProgress,
        title: 'Goal 1 Progress',
        goalId: 'goal_1',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final notif2 = Notification(
        id: 'notif_2',
        type: NotificationType.goalAtRisk,
        title: 'Goal 2 At Risk',
        goalId: 'goal_2',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await repository.save(notif1);
      await repository.save(notif2);

      // Act
      final goal1Notifications = await repository.getByGoalId('goal_1');

      // Assert
      expect(goal1Notifications.length, equals(1));
      expect(goal1Notifications[0].goalId, equals('goal_1'));
    });

    test('getPendingToDeliver returns pending notifications scheduled for delivery', () async {
      // Arrange
      final now = DateTime.now();
      
      final pendingPast = Notification(
        id: 'notif_pending_past',
        type: NotificationType.eventReminder,
        title: 'Past Pending',
        scheduledAt: now.subtract(const Duration(minutes: 5)),
        status: NotificationStatus.pending,
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      final pendingFuture = Notification(
        id: 'notif_pending_future',
        type: NotificationType.eventReminder,
        title: 'Future Pending',
        scheduledAt: now.add(const Duration(hours: 1)),
        status: NotificationStatus.pending,
        createdAt: now,
      );

      final deliveredPast = Notification(
        id: 'notif_delivered',
        type: NotificationType.eventReminder,
        title: 'Already Delivered',
        scheduledAt: now.subtract(const Duration(minutes: 5)),
        status: NotificationStatus.delivered,
        createdAt: now.subtract(const Duration(hours: 1)),
      );

      await repository.save(pendingPast);
      await repository.save(pendingFuture);
      await repository.save(deliveredPast);

      // Act
      final toDeliver = await repository.getPendingToDeliver();

      // Assert
      expect(toDeliver.length, equals(1));
      expect(toDeliver[0].id, equals('notif_pending_past'));
    });

    test('markDelivered updates notification status', () async {
      // Arrange
      final notification = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Test',
        scheduledAt: DateTime.now(),
        status: NotificationStatus.pending,
        createdAt: DateTime.now(),
      );

      await repository.save(notification);

      // Act
      await repository.markDelivered('notif_1');
      final retrieved = await repository.getById('notif_1');

      // Assert
      expect(retrieved!.status, equals(NotificationStatus.delivered));
      expect(retrieved.deliveredAt, isNotNull);
    });

    test('markRead updates notification status', () async {
      // Arrange
      final notification = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Test',
        scheduledAt: DateTime.now(),
        status: NotificationStatus.delivered,
        createdAt: DateTime.now(),
      );

      await repository.save(notification);

      // Act
      await repository.markRead('notif_1');
      final retrieved = await repository.getById('notif_1');

      // Assert
      expect(retrieved!.status, equals(NotificationStatus.read));
      expect(retrieved.readAt, isNotNull);
    });

    test('getUnread returns only delivered (unread) notifications', () async {
      // Arrange
      final unread = Notification(
        id: 'notif_unread',
        type: NotificationType.eventReminder,
        title: 'Unread',
        scheduledAt: DateTime.now(),
        status: NotificationStatus.delivered,
        createdAt: DateTime.now(),
      );

      final read = Notification(
        id: 'notif_read',
        type: NotificationType.eventReminder,
        title: 'Read',
        scheduledAt: DateTime.now(),
        status: NotificationStatus.read,
        createdAt: DateTime.now(),
      );

      final pending = Notification(
        id: 'notif_pending',
        type: NotificationType.eventReminder,
        title: 'Pending',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        status: NotificationStatus.pending,
        createdAt: DateTime.now(),
      );

      await repository.save(unread);
      await repository.save(read);
      await repository.save(pending);

      // Act
      final unreadNotifications = await repository.getUnread();

      // Assert
      expect(unreadNotifications.length, equals(1));
      expect(unreadNotifications[0].id, equals('notif_unread'));
    });

    test('deleteByEventId removes all notifications for an event', () async {
      // Arrange
      final notif1 = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Reminder 1',
        eventId: 'event_1',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final notif2 = Notification(
        id: 'notif_2',
        type: NotificationType.eventReminder,
        title: 'Reminder 2',
        eventId: 'event_1',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      final notif3 = Notification(
        id: 'notif_3',
        type: NotificationType.eventReminder,
        title: 'Different Event',
        eventId: 'event_2',
        scheduledAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await repository.save(notif1);
      await repository.save(notif2);
      await repository.save(notif3);

      // Act
      await repository.deleteByEventId('event_1');
      final all = await repository.getAll();

      // Assert
      expect(all.length, equals(1));
      expect(all[0].eventId, equals('event_2'));
    });

    test('cancelPendingForEvent cancels only pending notifications for an event', () async {
      // Arrange
      final pending = Notification(
        id: 'notif_pending',
        type: NotificationType.eventReminder,
        title: 'Pending',
        eventId: 'event_1',
        scheduledAt: DateTime.now().add(const Duration(hours: 1)),
        status: NotificationStatus.pending,
        createdAt: DateTime.now(),
      );

      final delivered = Notification(
        id: 'notif_delivered',
        type: NotificationType.eventReminder,
        title: 'Delivered',
        eventId: 'event_1',
        scheduledAt: DateTime.now().subtract(const Duration(hours: 1)),
        status: NotificationStatus.delivered,
        createdAt: DateTime.now(),
      );

      await repository.save(pending);
      await repository.save(delivered);

      // Act
      await repository.cancelPendingForEvent('event_1');
      
      final pendingResult = await repository.getById('notif_pending');
      final deliveredResult = await repository.getById('notif_delivered');

      // Assert
      expect(pendingResult!.status, equals(NotificationStatus.cancelled));
      expect(deliveredResult!.status, equals(NotificationStatus.delivered));
    });

    test('watchUnreadCount emits count updates', () async {
      // Arrange
      final notification = Notification(
        id: 'notif_1',
        type: NotificationType.eventReminder,
        title: 'Test',
        scheduledAt: DateTime.now(),
        status: NotificationStatus.delivered,
        createdAt: DateTime.now(),
      );

      // Act
      final stream = repository.watchUnreadCount();
      final emittedValues = <int>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await repository.save(notification);
      await Future.delayed(const Duration(milliseconds: 100));
      await repository.markRead('notif_1');
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Assert
      expect(emittedValues.length, greaterThanOrEqualTo(3));
      expect(emittedValues[0], equals(0)); // Initial
      expect(emittedValues[1], equals(1)); // After save
      expect(emittedValues[2], equals(0)); // After mark read
    });
  });
}
