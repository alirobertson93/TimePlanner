import 'package:test/test.dart';
import 'package:time_planner/scheduler/strategies/least_disruption_strategy.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/scheduler/models/scheduled_event.dart';
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

    test('name returns "least-disruption"', () {
      final strategy = LeastDisruptionStrategy();
      expect(strategy.name, equals('least-disruption'));
    });

    test('schedules at same time as previously scheduled event', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create an existing schedule with this event at 10 AM Tuesday
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 14, 10, 0),
          scheduledEnd: DateTime(2026, 1, 14, 11, 0),
        ),
      ];

      final strategy = LeastDisruptionStrategy(existingSchedule);
      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.length, equals(4)); // 1 hour = 4 slots
      // Should be scheduled at same time: 10 AM Tuesday
      expect(slots.first.start.day, equals(14)); // Tuesday
      expect(slots.first.start.hour, equals(10)); // 10 AM
    });

    test('finds nearest time when previous slot is occupied', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create an existing schedule with this event at 10 AM Tuesday
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 14, 10, 0),
          scheduledEnd: DateTime(2026, 1, 14, 11, 0),
        ),
      ];

      // Block 10 AM Tuesday
      final blockerEvent = Event(
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
          TimeSlot(DateTime(2026, 1, 14, 10, 0)),
          TimeSlot(DateTime(2026, 1, 14, 10, 15)),
          TimeSlot(DateTime(2026, 1, 14, 10, 30)),
          TimeSlot(DateTime(2026, 1, 14, 10, 45)),
        ],
        blockerEvent,
        DateTime(2026, 1, 14, 10, 0),
      );

      final strategy = LeastDisruptionStrategy(existingSchedule);
      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should find nearest available time to 10 AM Tuesday
      // Either 9 AM or 11 AM Tuesday
      expect(slots!.first.start.day, equals(14)); // Same day (Tuesday)
      expect(slots.first.start.hour == 9 || slots.first.start.hour == 11, isTrue);
    });

    test('falls back to any available slot when no previous schedule exists', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // No existing schedule
      final strategy = LeastDisruptionStrategy([]);
      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.length, equals(4)); // 1 hour = 4 slots
    });

    test('searches adjacent days when same day is full', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Previously scheduled at 10 AM Tuesday
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 14, 10, 0),
          scheduledEnd: DateTime(2026, 1, 14, 11, 0),
        ),
      ];

      // Fill all of Tuesday's work hours
      final fillerEvent = Event(
        id: 'filler',
        name: 'Filler',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(minutes: 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      var current = TimeSlot(DateTime(2026, 1, 14, 9, 0));
      final tuesdayEnd = DateTime(2026, 1, 14, 17, 0);

      while (current.start.isBefore(tuesdayEnd)) {
        grid.occupy([current], fillerEvent, current.start);
        current = current.next;
      }

      final strategy = LeastDisruptionStrategy(existingSchedule);
      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should be scheduled on an adjacent day (Monday or Wednesday)
      final day = slots!.first.start.day;
      expect(day == 13 || day == 15, isTrue);
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

      final strategy = LeastDisruptionStrategy();
      final slots = strategy.findSlots(event, grid, []);
      expect(slots, isNull);
    });

    test('prefers closer times when multiple options available', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Previously scheduled at 12 PM Tuesday
      final existingSchedule = [
        ScheduledEvent(
          event: event,
          scheduledStart: DateTime(2026, 1, 14, 12, 0),
          scheduledEnd: DateTime(2026, 1, 14, 13, 0),
        ),
      ];

      // Block 12 PM and 1 PM
      final blockerEvent = Event(
        id: 'blocker',
        name: 'Blocker',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 2),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 14, 12, 0)),
          TimeSlot(DateTime(2026, 1, 14, 12, 15)),
          TimeSlot(DateTime(2026, 1, 14, 12, 30)),
          TimeSlot(DateTime(2026, 1, 14, 12, 45)),
          TimeSlot(DateTime(2026, 1, 14, 13, 0)),
          TimeSlot(DateTime(2026, 1, 14, 13, 15)),
          TimeSlot(DateTime(2026, 1, 14, 13, 30)),
          TimeSlot(DateTime(2026, 1, 14, 13, 45)),
        ],
        blockerEvent,
        DateTime(2026, 1, 14, 12, 0),
      );

      final strategy = LeastDisruptionStrategy(existingSchedule);
      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      // Should find nearest available: either 11 AM or 2 PM on Tuesday
      expect(slots!.first.start.day, equals(14)); // Same day
      // 11 AM (one hour before) should be preferred over 2 PM
      expect(slots.first.start.hour, equals(11));
    });
  });
}
