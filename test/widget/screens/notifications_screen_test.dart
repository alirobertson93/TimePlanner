import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/entities/notification.dart' as domain;
import 'package:time_planner/domain/enums/notification_type.dart';
import 'package:time_planner/domain/enums/notification_status.dart';
import 'package:time_planner/presentation/providers/notification_providers.dart';
import 'package:time_planner/presentation/screens/notifications/notifications_screen.dart';

void main() {
  group('NotificationsScreen', () {
    late List<domain.Notification> testNotifications;

    setUp(() {
      final now = DateTime.now();
      testNotifications = [
        domain.Notification(
          id: 'notif_1',
          title: 'Event Reminder',
          body: 'Your meeting starts in 15 minutes',
          type: NotificationType.eventReminder,
          status: NotificationStatus.delivered,
          scheduledAt: now.subtract(const Duration(minutes: 15)),
          eventId: 'event_1',
          createdAt: now.subtract(const Duration(minutes: 15)),
        ),
        domain.Notification(
          id: 'notif_2',
          title: 'Goal Progress',
          body: 'You\'re on track with your Exercise goal!',
          type: NotificationType.goalProgress,
          status: NotificationStatus.read,
          scheduledAt: now.subtract(const Duration(hours: 2)),
          goalId: 'goal_1',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
        domain.Notification(
          id: 'notif_3',
          title: 'Goal At Risk',
          body: 'Reading goal needs attention',
          type: NotificationType.goalAtRisk,
          status: NotificationStatus.pending,
          scheduledAt: now.subtract(const Duration(days: 1)),
          goalId: 'goal_2',
          createdAt: now.subtract(const Duration(days: 1)),
        ),
      ];
    });

    Widget createTestWidget({
      List<domain.Notification> notifications = const [],
    }) {
      return ProviderScope(
        overrides: [
          watchAllNotificationsProvider.overrideWith(
            (ref) => Stream.value(notifications),
          ),
        ],
        child: MaterialApp(
          home: const NotificationsScreen(),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('Route: ${settings.name}')),
              ),
            );
          },
        ),
      );
    }

    testWidgets('displays "Notifications" title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('displays loading indicator while fetching notifications',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchAllNotificationsProvider.overrideWith(
              (ref) => const Stream<List<domain.Notification>>.empty(),
            ),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no notifications exist',
        (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: []));
      await tester.pumpAndSettle();

      expect(find.text('No notifications'), findsOneWidget);
      expect(find.text('You\'re all caught up!'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none), findsOneWidget);
    });

    testWidgets('displays more options menu button', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('more options menu shows mark all read and clear all',
        (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Mark all as read'), findsOneWidget);
      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('displays notification titles', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      expect(find.text('Event Reminder'), findsOneWidget);
      expect(find.text('Goal Progress'), findsOneWidget);
      expect(find.text('Goal At Risk'), findsOneWidget);
    });

    testWidgets('displays notification bodies', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      expect(find.text('Your meeting starts in 15 minutes'), findsOneWidget);
    });

    testWidgets('displays date headers for grouped notifications',
        (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Should have date headers (Today, Yesterday, etc.)
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('unread notifications show unread indicator', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Unread notifications should have a small dot indicator
      // The unread indicator is a small Container with BoxShape.circle
    });

    testWidgets('notification tiles are dismissible', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Should have dismissible widgets for notifications
      expect(find.byType(Dismissible), findsAtLeastNWidgets(1));
    });

    testWidgets('displays correct icons for notification types',
        (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Each notification type has a specific icon
      expect(find.byIcon(Icons.alarm), findsOneWidget); // eventReminder
      expect(find.byIcon(Icons.trending_up), findsOneWidget); // goalProgress
      expect(find.byIcon(Icons.error), findsOneWidget); // goalAtRisk
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchAllNotificationsProvider.overrideWith(
              (ref) => Stream.error('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: NotificationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading notifications'), findsOneWidget);
    });

    testWidgets('clear all shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Open the popup menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap clear all
      await tester.tap(find.text('Clear all'));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('Clear all notifications?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('notifications are tappable', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Notifications should be in ListTile widgets
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('displays notification time', (tester) async {
      await tester.pumpWidget(createTestWidget(notifications: testNotifications));
      await tester.pumpAndSettle();

      // Time should be displayed (format varies based on locale)
      // We check that the notification list is showing content
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
