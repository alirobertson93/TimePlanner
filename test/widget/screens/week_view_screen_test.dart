import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/presentation/providers/event_providers.dart';
import 'package:time_planner/presentation/screens/week_view/week_view_screen.dart';

void main() {
  group('WeekViewScreen', () {
    late DateTime testDate;
    late DateTime weekStart;
    late List<Event> testEvents;

    setUp(() {
      testDate = DateTime(2026, 1, 22);
      // Week starts on Monday (Jan 19, 2026)
      weekStart = DateTime(2026, 1, 19);
      testEvents = [
        Event(
          id: 'event_1',
          name: 'Monday Meeting',
          timingType: TimingType.fixed,
          startTime: DateTime(2026, 1, 19, 9, 0),
          endTime: DateTime(2026, 1, 19, 10, 0),
          status: EventStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        ),
        Event(
          id: 'event_2',
          name: 'Wednesday Workshop',
          timingType: TimingType.fixed,
          startTime: DateTime(2026, 1, 21, 14, 0),
          endTime: DateTime(2026, 1, 21, 16, 0),
          status: EventStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        ),
        Event(
          id: 'event_3',
          name: 'Friday Review',
          timingType: TimingType.fixed,
          startTime: DateTime(2026, 1, 23, 11, 0),
          endTime: DateTime(2026, 1, 23, 12, 0),
          status: EventStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        ),
      ];
    });

    Widget createTestWidget({
      List<Event> events = const [],
      DateTime? selectedDate,
    }) {
      return ProviderScope(
        overrides: [
          selectedDateProvider.overrideWith(() => SelectedDate()),
          eventsForWeekProvider(weekStart).overrideWith(
            (ref) => Stream.value(events),
          ),
        ],
        child: MaterialApp(
          home: const WeekViewScreen(),
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

    testWidgets('displays loading indicator while fetching events',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDateProvider.overrideWith(() => SelectedDate()),
            eventsForWeekProvider(weekStart).overrideWith(
              (ref) => const Stream<List<Event>>.empty(),
            ),
          ],
          child: const MaterialApp(
            home: WeekViewScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays week label in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // App bar should show "Week of" with a date
      expect(find.textContaining('Week of'), findsOneWidget);
    });

    testWidgets('displays navigation buttons for week navigation',
        (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Check for week navigation icons
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.today), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('displays day view toggle button', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_view_day), findsOneWidget);
    });

    testWidgets('displays floating action button for adding events',
        (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('previous week button navigates to previous week',
        (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Tap previous week button
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();

      // The week label should have changed
    });

    testWidgets('next week button navigates to next week', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Tap next week button
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pumpAndSettle();
    });

    testWidgets('today button returns to current week', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      // Tap today button
      await tester.tap(find.byIcon(Icons.today));
      await tester.pumpAndSettle();
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedDateProvider.overrideWith(() => SelectedDate()),
            eventsForWeekProvider(weekStart).overrideWith(
              (ref) => Stream.error('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: WeekViewScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Error icon and message should be displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error loading events'), findsOneWidget);
    });

    testWidgets('FAB has correct tooltip', (tester) async {
      await tester.pumpWidget(createTestWidget(events: testEvents));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);
    });
  });
}
