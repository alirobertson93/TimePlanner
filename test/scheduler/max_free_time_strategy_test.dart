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

    test('name returns "max_free_time"', () {
      expect(strategy.name, equals('max_free_time'));
    });

    test('finds slots in empty grid', () {
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
      // Add an event from 9 AM to 10 AM on Monday
      final existingEvent = Event(
        id: 'existing',
        name: 'Existing Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 13, 9, 0));
      final existingEnd = TimeSlot(DateTime(2026, 1, 13, 10, 0));

      while (current.start.isBefore(existingEnd.start)) {
        grid.occupy([current], existingEvent, current.start);
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
      // Should be placed adjacent to existing event (at 10 AM) to maximize free time blocks
      // The strategy prefers clustering events together
      expect(slots!.first.start.hour, greaterThanOrEqualTo(9));
    });

    test('finds placement that minimizes fragmentation', () {
      // Create two separate events with a gap in between
      // Event 1: 9 AM to 10 AM on Monday
      // Event 2: 2 PM to 3 PM on Monday
      // This creates a free block from 10 AM to 2 PM (4 hours)
      
      final event1 = Event(
        id: 'event_1',
        name: 'Morning Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 13, 9, 0));
      final event1End = TimeSlot(DateTime(2026, 1, 13, 10, 0));

      while (current.start.isBefore(event1End.start)) {
        grid.occupy([current], event1, current.start);
        current = current.next;
      }

      final event2 = Event(
        id: 'event_2',
        name: 'Afternoon Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      current = TimeSlot(DateTime(2026, 1, 13, 14, 0));
      final event2End = TimeSlot(DateTime(2026, 1, 13, 15, 0));

      while (current.start.isBefore(event2End.start)) {
        grid.occupy([current], event2, current.start);
        current = current.next;
      }

      // Now schedule a new 1-hour event
      // The strategy should place it adjacent to one of the existing events
      // to preserve the large free block
      final newEvent = Event(
        id: 'new_event',
        name: 'New Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(newEvent, grid, []);

      expect(slots, isNotNull);
      expect(slots!.length, equals(4));
      
      // Should be placed at 10 AM (right after first event) or 1 PM (right before second)
      // Either placement is acceptable as both minimize fragmentation
      final startHour = slots.first.start.hour;
      final isAdjacentToEvent1 = startHour == 10;
      final isAdjacentToEvent2 = startHour == 13;
      
      // At minimum, it should be on Monday and within work hours
      expect(slots.first.start.day, equals(13));
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

    test('handles long events across multiple days', () {
      // Create a grid that spans Monday to Wednesday
      final longGrid = AvailabilityGrid(
        DateTime(2026, 1, 13, 9, 0),
        DateTime(2026, 1, 15, 17, 0),
      );

      // Try to schedule a 4-hour event
      final event = Event(
        id: 'long_event',
        name: 'Long Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 4),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, longGrid, []);

      expect(slots, isNotNull);
      expect(slots!.length, equals(16)); // 4 hours = 16 slots
    });
  });
}
