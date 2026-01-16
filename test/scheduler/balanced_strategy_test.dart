import 'package:test/test.dart';
import 'package:time_planner/scheduler/strategies/balanced_strategy.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('BalancedStrategy', () {
    late BalancedStrategy strategy;
    late AvailabilityGrid grid;

    setUp(() {
      strategy = BalancedStrategy();
      // Monday to Friday, 9 AM to 5 PM
      grid = AvailabilityGrid(
        DateTime(2026, 1, 13, 9, 0),
        DateTime(2026, 1, 17, 17, 0),
      );
    });

    test('name returns "balanced"', () {
      expect(strategy.name, equals('balanced'));
    });

    test('finds slots on least busy day', () {
      // Add an event on Monday
      final mondayEvent = Event(
        id: 'event_1',
        name: 'Monday Event',
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
        mondayEvent,
        DateTime(2026, 1, 13, 10, 0),
      );

      // Try to schedule another event
      final newEvent = Event(
        id: 'event_2',
        name: 'New Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(newEvent, grid, []);

      expect(slots, isNotNull);
      expect(slots!.isNotEmpty, isTrue);
      // Should be scheduled on Tuesday (least busy day)
      expect(slots.first.start.day, equals(14)); // Tuesday
    });

    test('finds slots in available time window', () {
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
      expect(slots.first.start.hour, greaterThanOrEqualTo(9));
      expect(slots.last.end.hour, lessThanOrEqualTo(17));
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

      // Try to schedule another event
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
  });
}
