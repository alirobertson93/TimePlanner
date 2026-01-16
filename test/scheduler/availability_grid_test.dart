import 'package:test/test.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('AvailabilityGrid', () {
    late AvailabilityGrid grid;
    late DateTime windowStart;
    late DateTime windowEnd;

    setUp(() {
      windowStart = DateTime(2026, 1, 13, 9, 0); // Monday 9 AM
      windowEnd = DateTime(2026, 1, 17, 17, 0); // Friday 5 PM
      grid = AvailabilityGrid(windowStart, windowEnd);
    });

    test('initializes all slots as available', () {
      final slot = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      expect(grid.isAvailable(slot), isTrue);
    });

    test('occupy marks slots as occupied', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = [
        TimeSlot(DateTime(2026, 1, 13, 10, 0)),
        TimeSlot(DateTime(2026, 1, 13, 10, 15)),
        TimeSlot(DateTime(2026, 1, 13, 10, 30)),
        TimeSlot(DateTime(2026, 1, 13, 10, 45)),
      ];

      grid.occupy(slots, event, slots.first.start);

      expect(grid.isAvailable(slots[0]), isFalse);
      expect(grid.isAvailable(slots[1]), isFalse);
      expect(grid.isAvailable(slots[2]), isFalse);
      expect(grid.isAvailable(slots[3]), isFalse);
    });

    test('getEventAt returns event occupying slot', () {
      final event = Event(
        id: 'event_1',
        name: 'Test Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slot = TimeSlot(DateTime(2026, 1, 13, 10, 0));
      grid.occupy([slot], event, slot.start);

      final retrieved = grid.getEventAt(slot);
      expect(retrieved, equals(event));
    });

    test('findAvailableSlots finds consecutive available slots', () {
      final slots = grid.findAvailableSlots(const Duration(hours: 1));

      expect(slots, isNotNull);
      expect(slots!.length, equals(4)); // 1 hour = 4 slots of 15 minutes
    });

    test('findAvailableSlots returns null when no space available', () {
      // Fill entire grid
      var current = TimeSlot(TimeSlot.roundDown(windowStart));
      final end = TimeSlot(TimeSlot.roundUp(windowEnd));

      final event = Event(
        id: 'event_1',
        name: 'Filler',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(minutes: 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      while (current.start.isBefore(end.start)) {
        grid.occupy([current], event, current.start);
        current = current.next;
      }

      final slots = grid.findAvailableSlots(const Duration(hours: 1));
      expect(slots, isNull);
    });

    test('getEventCountForDay counts events on specific day', () {
      final event1 = Event(
        id: 'event_1',
        name: 'Event 1',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final event2 = Event(
        id: 'event_2',
        name: 'Event 2',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Schedule both on Monday
      final monday = DateTime(2026, 1, 13);
      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 13, 10, 0)),
          TimeSlot(DateTime(2026, 1, 13, 10, 15)),
          TimeSlot(DateTime(2026, 1, 13, 10, 30)),
          TimeSlot(DateTime(2026, 1, 13, 10, 45)),
        ],
        event1,
        DateTime(2026, 1, 13, 10, 0),
      );

      grid.occupy(
        [
          TimeSlot(DateTime(2026, 1, 13, 14, 0)),
          TimeSlot(DateTime(2026, 1, 13, 14, 15)),
          TimeSlot(DateTime(2026, 1, 13, 14, 30)),
          TimeSlot(DateTime(2026, 1, 13, 14, 45)),
        ],
        event2,
        DateTime(2026, 1, 13, 14, 0),
      );

      expect(grid.getEventCountForDay(monday), equals(2));
      expect(grid.getEventCountForDay(DateTime(2026, 1, 14)), equals(0));
    });
  });
}
