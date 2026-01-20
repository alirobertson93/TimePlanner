import 'package:test/test.dart';
import 'package:time_planner/scheduler/strategies/least_disruption_strategy.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/scheduled_event.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('LeastDisruptionStrategy', () {
    late AvailabilityGrid grid;

    setUp(() {
      // Monday to Friday, 9 AM to 5 PM
      grid = AvailabilityGrid(
        DateTime(2026, 1, 13, 9, 0),
        DateTime(2026, 1, 17, 17, 0),
      );
    });

    test('name returns "least_disruption"', () {
      final strategy = LeastDisruptionStrategy();
      expect(strategy.name, equals('least_disruption'));
    });

    test('places event at same time as previous schedule if available', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create strategy with existing schedule showing event at 2 PM Monday
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 13, 14, 0),
          scheduledEnd: DateTime(2026, 1, 13, 15, 0),
        ),
      ];

      final strategy = LeastDisruptionStrategy(existingSchedule: existingSchedule);

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.length, equals(4)); // 1 hour = 4 slots
      // Should be placed at 2 PM (same as previous schedule)
      expect(slots.first.start.hour, equals(14));
      expect(slots.first.start.day, equals(13)); // Monday
    });

    test('finds nearest available slot when previous time is occupied', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create strategy with existing schedule showing event at 2 PM Monday
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 13, 14, 0),
          scheduledEnd: DateTime(2026, 1, 13, 15, 0),
        ),
      ];

      // Block the 2 PM - 3 PM slot on Monday
      final blockingEvent = Event(
        id: 'blocking',
        name: 'Blocking Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 13, 14, 0));
      final blockEnd = TimeSlot(DateTime(2026, 1, 13, 15, 0));

      while (current.start.isBefore(blockEnd.start)) {
        grid.occupy([current], blockingEvent, current.start);
        current = current.next;
      }

      final strategy = LeastDisruptionStrategy(existingSchedule: existingSchedule);

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should find nearest slot (either before or after 2 PM)
      expect(slots!.length, equals(4));
      // Verify it's close to the original time
      expect(slots.first.start.day, equals(13)); // Same day
    });

    test('finds slots on least busy day when no previous schedule', () {
      // Add events on Monday to make it busy
      final mondayEvent = Event(
        id: 'monday',
        name: 'Monday Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 4),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 13, 9, 0));
      final mondayEnd = TimeSlot(DateTime(2026, 1, 13, 13, 0));

      while (current.start.isBefore(mondayEnd.start)) {
        grid.occupy([current], mondayEvent, current.start);
        current = current.next;
      }

      // Also add events on Tuesday
      final tuesdayEvent = Event(
        id: 'tuesday',
        name: 'Tuesday Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 3),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      current = TimeSlot(DateTime(2026, 1, 14, 9, 0));
      final tuesdayEnd = TimeSlot(DateTime(2026, 1, 14, 12, 0));

      while (current.start.isBefore(tuesdayEnd.start)) {
        grid.occupy([current], tuesdayEvent, current.start);
        current = current.next;
      }

      // Strategy without existing schedule
      final strategy = LeastDisruptionStrategy();

      final event = Event(
        id: 'new_event',
        name: 'New Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should be scheduled on one of the less busy days (Wed, Thu, or Fri)
      expect(slots!.first.start.day, greaterThanOrEqualTo(15)); // Wednesday or later
    });

    test('returns null when no slots available', () {
      // Fill the entire grid
      final fillerEvent = Event(
        id: 'filler',
        name: 'Filler',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(minutes: 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 13, 9, 0));
      final end = TimeSlot(DateTime(2026, 1, 17, 17, 0));

      while (current.start.isBefore(end.start)) {
        grid.occupy([current], fillerEvent, current.start);
        current = current.next;
      }

      final strategy = LeastDisruptionStrategy();

      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);
      expect(slots, isNull);
    });

    test('respects scheduling window boundaries', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create strategy with previous schedule at 5 PM (end of window)
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 13, 16, 30),
          scheduledEnd: DateTime(2026, 1, 13, 17, 30),
        ),
      ];

      final strategy = LeastDisruptionStrategy(existingSchedule: existingSchedule);

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should not schedule past end of window
      expect(slots!.last.end.hour, lessThanOrEqualTo(17));
    });
  });
}
