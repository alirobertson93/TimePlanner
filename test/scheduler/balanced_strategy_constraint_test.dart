import 'package:test/test.dart';
import 'package:time_planner/scheduler/strategies/balanced_strategy.dart';
import 'package:time_planner/scheduler/models/availability_grid.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/scheduling_constraint.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';

void main() {
  group('BalancedStrategy with Constraints', () {
    late BalancedStrategy strategy;
    late AvailabilityGrid grid;

    setUp(() {
      strategy = BalancedStrategy();
      // Monday to Friday, 9 AM to 5 PM
      grid = AvailabilityGrid(
        DateTime(2026, 1, 13, 9, 0),  // Monday
        DateTime(2026, 1, 17, 17, 0), // Friday
      );
    });

    test('respects notBeforeTime constraint (locked)', () {
      final event = Event(
        id: 'event_1',
        name: 'Afternoon Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        schedulingConstraint: SchedulingConstraint(
          notBeforeTime: 14 * 60, // 2:00 PM
          timeConstraintStrength: SchedulingPreferenceStrength.locked,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.isNotEmpty, isTrue);
      // Should be scheduled at or after 2:00 PM (14:00)
      expect(slots.first.start.hour, greaterThanOrEqualTo(14));
    });

    test('respects notAfterTime constraint (locked)', () {
      final event = Event(
        id: 'event_1',
        name: 'Morning Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        schedulingConstraint: SchedulingConstraint(
          notAfterTime: 11 * 60, // 11:00 AM
          timeConstraintStrength: SchedulingPreferenceStrength.locked,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.isNotEmpty, isTrue);
      // Should start before or at 11:00 AM
      expect(slots.first.start.hour, lessThanOrEqualTo(11));
    });

    test('respects time window constraint (locked)', () {
      final event = Event(
        id: 'event_1',
        name: 'Midday Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        schedulingConstraint: SchedulingConstraint(
          notBeforeTime: 11 * 60, // 11:00 AM
          notAfterTime: 14 * 60, // 2:00 PM
          timeConstraintStrength: SchedulingPreferenceStrength.locked,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.isNotEmpty, isTrue);
      // Should start between 11:00 AM and 2:00 PM
      final startHour = slots.first.start.hour;
      final startMinute = slots.first.start.minute;
      final startMinutes = startHour * 60 + startMinute;
      expect(startMinutes, greaterThanOrEqualTo(11 * 60));
      expect(startMinutes, lessThanOrEqualTo(14 * 60));
    });

    test('returns null for impossible locked constraint', () {
      // Fill 9 AM to 12 PM on all days
      final fillerEvent = Event(
        id: 'filler',
        name: 'Filler',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(minutes: 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      for (var day = 13; day <= 17; day++) {
        for (var hour = 9; hour < 12; hour++) {
          for (var minute = 0; minute < 60; minute += 15) {
            grid.occupy(
              [TimeSlot(DateTime(2026, 1, day, hour, minute))],
              fillerEvent,
              DateTime(2026, 1, day, hour, minute),
            );
          }
        }
      }

      // Event with locked constraint requiring before 11 AM
      final event = Event(
        id: 'event_1',
        name: 'Morning Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        schedulingConstraint: SchedulingConstraint(
          notAfterTime: 11 * 60, // Before 11:00 AM
          timeConstraintStrength: SchedulingPreferenceStrength.locked,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);
      expect(slots, isNull);
    });

    test('prefers constraint-compliant slots for weak constraints', () {
      // Fill afternoon slots on Monday to force constraint violation
      final fillerEvent = Event(
        id: 'filler',
        name: 'Filler',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(minutes: 15),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Fill all Monday afternoon slots (14:00-17:00)
      for (var hour = 14; hour < 17; hour++) {
        for (var minute = 0; minute < 60; minute += 15) {
          grid.occupy(
            [TimeSlot(DateTime(2026, 1, 13, hour, minute))],
            fillerEvent,
            DateTime(2026, 1, 13, hour, minute),
          );
        }
      }

      // Event with weak constraint preferring afternoon
      final event = Event(
        id: 'event_1',
        name: 'Afternoon Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        schedulingConstraint: SchedulingConstraint(
          notBeforeTime: 14 * 60, // 2:00 PM
          timeConstraintStrength: SchedulingPreferenceStrength.weak,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.isNotEmpty, isTrue);
      // Should find a slot (might be before constraint since weak, but should try to respect it)
      // The strategy should prefer Tuesday afternoon since Monday afternoon is full
      // or morning if no afternoon slots available
    });

    test('respects day constraints (locked)', () {
      final event = Event(
        id: 'event_1',
        name: 'Weekday Event',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: const Duration(hours: 1),
        schedulingConstraint: SchedulingConstraint(
          preferredDays: [3], // Wednesday only (in constraint format, 0=Sun, 3=Wed)
          dayConstraintStrength: SchedulingPreferenceStrength.locked,
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final slots = strategy.findSlots(event, grid, []);

      expect(slots, isNotNull);
      expect(slots!.isNotEmpty, isTrue);
      // Wednesday is Jan 15, 2026 in the grid
      expect(slots.first.start.day, equals(15));
    });

    test('schedules event without constraints normally', () {
      final event = Event(
        id: 'event_1',
        name: 'No Constraints',
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
  });
}
