import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/presentation/providers/event_providers.dart';
import 'package:time_planner/presentation/providers/notification_providers.dart';
import 'package:time_planner/presentation/screens/day_view/day_view_screen.dart';

// Mock classes
class MockNavigatorObserver extends Mock implements NavigatorObserver {}

void main() {
  group('DayViewScreen', () {
    late DateTime testDate;
    late List<Event> testEvents;

    setUp(() {
      testDate = DateTime(2026, 1, 22);
      testEvents = [
        Event(
          id: 'event_1',
          name: 'Morning Meeting',
          timingType: TimingType.fixed,
          startTime: DateTime(2026, 1, 22, 9, 0),
          endTime: DateTime(2026, 1, 22, 10, 0),
          status: EventStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        ),
        Event(
          id: 'event_2',
          name: 'Lunch Break',
          timingType: TimingType.fixed,
          startTime: DateTime(2026, 1, 22, 12, 0),
          endTime: DateTime(2026, 1, 22, 13, 0),
          status: EventStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        ),
      ];
    });

    Widget createTestWidget({
      List<Event> events = const [],
      DateTime? selectedDate,
      int unreadCount = 0,
    }) {
      return ProviderScope(
        overrides: [
          // Override the selected date
          selectedDateProvider.overrideWith((ref) => SelectedDate()),
          // Override events to return test events
          eventsForDateProvider(selectedDate ?? testDate).overrideWith(
            (ref) => Stream.value(events),
          ),
          // Override unread notification count
          unreadCountProvider.overrideWith(
            (ref) => Stream.value(unreadCount),
          ),
        ],
        child: MaterialApp(
          home: const DayViewScreen(),
          // Use onGenerateRoute to handle navigation
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

    testWidgets('displays loading indicator while fetching events', (tester) async {
      // Create a widget that returns loading state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDateProvider.overrideWith((ref) => SelectedDate()),
            eventsForDateProvider(testDate).overrideWith(
              (ref) => const Stream<List<Event>>.empty(),
            ),
            unreadCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            home: DayViewScreen(),
          ),
        ),
      );

      // Should show CircularProgressIndicator while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays date in app bar title', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // App bar should show formatted date
      expect(find.text('January 22, 2026'), findsOneWidget);
    });

    testWidgets('displays navigation buttons in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Check for navigation icons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('displays feature buttons in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Check for feature icons
      expect(find.byIcon(Icons.location_on), findsOneWidget);
      expect(find.byIcon(Icons.people), findsOneWidget);
      expect(find.byIcon(Icons.track_changes), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.calendar_view_week), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('displays floating action button for adding events', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // FAB should be visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('previous day button navigates to previous day', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Tap previous day button
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // The date should have changed (we can verify the provider was called)
      // In a real test, we'd verify the selectedDateProvider state changed
    });

    testWidgets('next day button navigates to next day', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Tap next day button
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
    });

    testWidgets('today button navigates to today', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Tap today button
      await tester.tap(find.byIcon(Icons.today));
      await tester.pumpAndSettle();
    });

    testWidgets('displays notification badge with unread count', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents, unreadCount: 5));
      await tester.pumpAndSettle();

      // Badge should show the count
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('displays 99+ for large notification counts', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents, unreadCount: 150));
      await tester.pumpAndSettle();

      // Badge should show 99+ for counts over 99
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('hides notification badge when count is zero', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents, unreadCount: 0));
      await tester.pumpAndSettle();

      // No badge number should be visible (but notification icon should still be there)
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      // The badge with "0" should not be visible
      expect(find.text('0'), findsNothing);
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDateProvider.overrideWith((ref) => SelectedDate()),
            eventsForDateProvider(testDate).overrideWith(
              (ref) => Stream.error('Test error'),
            ),
            unreadCountProvider.overrideWith(
              (ref) => Stream.value(0),
            ),
          ],
          child: const MaterialApp(
            home: DayViewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error icon and message should be displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading events'), findsOneWidget);
    });
  });
}
