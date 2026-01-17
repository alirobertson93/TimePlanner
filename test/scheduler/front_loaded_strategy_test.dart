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

    test('name returns "front-loaded"', () {
      expect(strategy.name, equals('front-loaded'));
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
      // Should be scheduled at 9 AM on Monday (first available)
      expect(slots.first.start.day, equals(13)); // Monday
      expect(slots.first.start.hour, equals(9)); // 9 AM
    });

    test('schedules on Monday when Monday morning is occupied', () {
      // Occupy Monday 9-10 AM
      final mondayEvent = Event(
        id: 'blocker',
        name: 'Blocker',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 13, 9, 0)),
          TimeSlot(DateTime(2026, 1, 13, 9, 15)),
          TimeSlot(DateTime(2026, 1, 13, 9, 30)),
          TimeSlot(DateTime(2026, 1, 13, 9, 45)),
        ],
        mondayEvent,
        DateTime(2026, 1, 13, 9, 0),
      );

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
      // Should be scheduled at 10 AM on Monday (next available)
      expect(slots!.first.start.day, equals(13)); // Monday
      expect(slots.first.start.hour, equals(10)); // 10 AM
    });

    test('skips to next day when day is full', () {
      // Fill Monday's work hours
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
      final mondayEnd = DateTime(2026, 1, 13, 17, 0);

      while (current.start.isBefore(mondayEnd)) {
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

      expect(slots, isNotNull);
      // Should be scheduled on Tuesday (first available after Monday)
      expect(slots!.first.start.day, equals(14)); // Tuesday
      expect(slots.first.start.hour, equals(9)); // 9 AM
    });

    test('returns null when no slots available in window', () {
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
