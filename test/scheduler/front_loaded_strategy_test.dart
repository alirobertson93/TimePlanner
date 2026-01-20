import 'package:test/test.dart';
import 'package:time_planner/scheduler/strategies/front_loaded_strategy.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('FrontLoadedStrategy', () {
    late FrontLoadedStrategy strategy;
    late AvailabilityGrid grid;

    setUp(() {
      strategy = FrontLoadedStrategy();
      // Monday to Friday, 9 AM to 5 PM
      grid = AvailabilityGrid(
        DateTime(2026, 1, 13, 9, 0),
        DateTime(2026, 1, 17, 17, 0),
      );
    });

    test('name returns "front_loaded"', () {
      expect(strategy.name, equals('front_loaded'));
    });

    test('schedules event at earliest available time', () {
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
      // Should be scheduled on Monday (first day) at 9 AM (first slot)
      expect(slots.first.start.day, equals(13)); // Monday
      expect(slots.first.start.hour, equals(9));
    });

    test('schedules on earliest available day when first day is full', () {
      // Fill Monday entirely (work hours 9-17)
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
      final mondayEnd = TimeSlot(DateTime(2026, 1, 13, 17, 0));

      while (current.start.isBefore(mondayEnd.start)) {
        grid.occupy([current], fillerEvent, current.start);
        current = current.next;
      }

      // Try to schedule a new event
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
      // Should be scheduled on Tuesday (first available day)
      expect(slots!.first.start.day, equals(14)); // Tuesday
      expect(slots.first.start.hour, equals(9));
    });

    test('finds earliest slot around existing events', () {
      // Block 9 AM to 11 AM on Monday
      final morningEvent = Event(
        id: 'morning',
        name: 'Morning Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 2),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 13, 9, 0));
      final morningEnd = TimeSlot(DateTime(2026, 1, 13, 11, 0));

      while (current.start.isBefore(morningEnd.start)) {
        grid.occupy([current], morningEvent, current.start);
        current = current.next;
      }

      // Try to schedule a 1-hour event
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
      // Should be scheduled at 11 AM (first available slot)
      expect(slots!.first.start.day, equals(13)); // Still Monday
      expect(slots.first.start.hour, equals(11));
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
  });
}
