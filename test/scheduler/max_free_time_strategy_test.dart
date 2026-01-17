import 'package:test/test.dart';
import 'package:time_planner/scheduler/strategies/max_free_time_strategy.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('MaxFreeTimeStrategy', () {
    late MaxFreeTimeStrategy strategy;
    late AvailabilityGrid grid;

    setUp(() {
      strategy = MaxFreeTimeStrategy();
      // Monday to Friday, 9 AM to 5 PM
      grid = AvailabilityGrid(
        DateTime(2026, 1, 13, 9, 0),
        DateTime(2026, 1, 17, 17, 0),
      );
    });

    test('name returns "max-free-time"', () {
      expect(strategy.name, equals('max-free-time'));
    });

    test('finds slots in available window', () {
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

      expect(slots, isNotNull);
      expect(slots!.length, equals(4)); // 1 hour = 4 slots
    });

    test('prefers placement adjacent to existing events', () {
      // Add an event at 10 AM Monday
      final existingEvent = Event(
        id: 'existing',
        name: 'Existing Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 13, 10, 0)),
          TimeSlot(DateTime(2026, 1, 13, 10, 15)),
          TimeSlot(DateTime(2026, 1, 13, 10, 30)),
          TimeSlot(DateTime(2026, 1, 13, 10, 45)),
        ],
        existingEvent,
        DateTime(2026, 1, 13, 10, 0),
      );

      final event = Event(
        id: 'event_1',
        name: 'New Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should prefer adjacent to existing (either 9 AM or 11 AM)
      // Based on scoring, it should choose a position adjacent to the existing event
      final startHour = slots!.first.start.hour;
      expect(startHour == 9 || startHour == 11, isTrue);
    });

    test('prefers start or end of day placements', () {
      // This test verifies that the strategy has a preference for
      // start-of-day or end-of-day placements when the grid is otherwise empty
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

      expect(slots, isNotNull);
      // On an empty grid, should prefer 9 AM (start of day)
      expect(slots!.first.start.hour, equals(9));
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

    test('handles multiple events spread across week', () {
      // Add events scattered across the week
      final eventMon = Event(
        id: 'mon',
        name: 'Monday Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final eventWed = Event(
        id: 'wed',
        name: 'Wednesday Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Monday 9 AM
      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 13, 9, 0)),
          TimeSlot(DateTime(2026, 1, 13, 9, 15)),
          TimeSlot(DateTime(2026, 1, 13, 9, 30)),
          TimeSlot(DateTime(2026, 1, 13, 9, 45)),
        ],
        eventMon,
        DateTime(2026, 1, 13, 9, 0),
      );

      // Wednesday 9 AM
      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 15, 9, 0)),
          TimeSlot(DateTime(2026, 1, 15, 9, 15)),
          TimeSlot(DateTime(2026, 1, 15, 9, 30)),
          TimeSlot(DateTime(2026, 1, 15, 9, 45)),
        ],
        eventWed,
        DateTime(2026, 1, 15, 9, 0),
      );

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
      // Strategy should find an available slot
      // The exact position depends on the scoring algorithm
      // But it should not conflict with existing events
      final scheduledTime = slots!.first.start;
      expect(
        (scheduledTime.day == 13 && scheduledTime.hour != 9) ||
            scheduledTime.day != 13,
        isTrue,
      );
    });
  });
}
