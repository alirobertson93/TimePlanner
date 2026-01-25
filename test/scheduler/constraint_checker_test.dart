import 'package:test/test.dart';
import 'package:time_planner/scheduler/services/constraint_checker.dart';
import 'package:time_planner/scheduler/models/constraint_violation.dart';
import 'package:time_planner/scheduler/models/time_slot.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/scheduling_constraint.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';

void main() {
  group('ConstraintChecker', () {
    late ConstraintChecker checker;

    setUp(() {
      checker = const ConstraintChecker();
    });

    group('checkConstraints', () {
      test('returns empty list for event without constraints', () {
        final event = Event(
          id: 'event_1',
          name: 'No Constraints',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [
          TimeSlot(DateTime(2026, 1, 15, 10, 0)),
          TimeSlot(DateTime(2026, 1, 15, 10, 15)),
          TimeSlot(DateTime(2026, 1, 15, 10, 30)),
          TimeSlot(DateTime(2026, 1, 15, 10, 45)),
        ];

        final violations = checker.checkConstraints(event, slots);
        expect(violations, isEmpty);
      });

      test('detects violation when scheduled before notBeforeTime', () {
        final event = Event(
          id: 'event_1',
          name: 'Morning Event',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60, // 10:00 AM
            timeConstraintStrength: SchedulingPreferenceStrength.strong,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Schedule at 9:00 AM (before 10:00 AM constraint)
        final slots = [
          TimeSlot(DateTime(2026, 1, 15, 9, 0)),
          TimeSlot(DateTime(2026, 1, 15, 9, 15)),
          TimeSlot(DateTime(2026, 1, 15, 9, 30)),
          TimeSlot(DateTime(2026, 1, 15, 9, 45)),
        ];

        final violations = checker.checkConstraints(event, slots);
        expect(violations, hasLength(1));
        expect(violations.first.violationType, ConstraintViolationType.scheduledTooEarly);
        expect(violations.first.strength, SchedulingPreferenceStrength.strong);
      });

      test('detects violation when scheduled after notAfterTime', () {
        final event = Event(
          id: 'event_1',
          name: 'Afternoon Event',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notAfterTime: 14 * 60, // 2:00 PM
            timeConstraintStrength: SchedulingPreferenceStrength.locked,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Schedule at 3:00 PM (after 2:00 PM constraint)
        final slots = [
          TimeSlot(DateTime(2026, 1, 15, 15, 0)),
          TimeSlot(DateTime(2026, 1, 15, 15, 15)),
          TimeSlot(DateTime(2026, 1, 15, 15, 30)),
          TimeSlot(DateTime(2026, 1, 15, 15, 45)),
        ];

        final violations = checker.checkConstraints(event, slots);
        expect(violations, hasLength(1));
        expect(violations.first.violationType, ConstraintViolationType.scheduledTooLate);
        expect(violations.first.isHardViolation, isTrue);
      });

      test('no violation when within time window', () {
        final event = Event(
          id: 'event_1',
          name: 'Afternoon Event',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60, // 10:00 AM
            notAfterTime: 16 * 60, // 4:00 PM
            timeConstraintStrength: SchedulingPreferenceStrength.locked,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Schedule at 12:00 PM (within window)
        final slots = [
          TimeSlot(DateTime(2026, 1, 15, 12, 0)),
          TimeSlot(DateTime(2026, 1, 15, 12, 15)),
          TimeSlot(DateTime(2026, 1, 15, 12, 30)),
          TimeSlot(DateTime(2026, 1, 15, 12, 45)),
        ];

        final violations = checker.checkConstraints(event, slots);
        expect(violations, isEmpty);
      });

      test('detects conflicting constraints', () {
        final event = Event(
          id: 'event_1',
          name: 'Impossible Event',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 15 * 60, // 3:00 PM
            notAfterTime: 10 * 60, // 10:00 AM - impossible!
            timeConstraintStrength: SchedulingPreferenceStrength.locked,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [
          TimeSlot(DateTime(2026, 1, 15, 12, 0)),
        ];

        final violations = checker.checkConstraints(event, slots);
        expect(violations.any((v) => v.violationType == ConstraintViolationType.conflictingConstraints), isTrue);
      });

      test('detects day constraint violation', () {
        final event = Event(
          id: 'event_1',
          name: 'Weekday Event',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            preferredDays: [1, 2, 3, 4, 5], // Monday-Friday
            dayConstraintStrength: SchedulingPreferenceStrength.strong,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Schedule on Sunday (Jan 18, 2026 is a Sunday)
        // DateTime.weekday == 7 for Sunday, which converts to 0 in constraint format
        final slots = [
          TimeSlot(DateTime(2026, 1, 18, 10, 0)),
        ];

        final violations = checker.checkConstraints(event, slots);
        expect(violations, hasLength(1));
        expect(violations.first.violationType, ConstraintViolationType.wrongDay);
      });
    });

    group('satisfiesLockedConstraints', () {
      test('returns true for event without constraints', () {
        final event = Event(
          id: 'event_1',
          name: 'No Constraints',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [TimeSlot(DateTime(2026, 1, 15, 10, 0))];
        expect(checker.satisfiesLockedConstraints(event, slots), isTrue);
      });

      test('returns true for weak constraint violation', () {
        final event = Event(
          id: 'event_1',
          name: 'Weak Constraint',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60,
            timeConstraintStrength: SchedulingPreferenceStrength.weak,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Schedule before constraint (violation, but weak)
        final slots = [TimeSlot(DateTime(2026, 1, 15, 8, 0))];
        expect(checker.satisfiesLockedConstraints(event, slots), isTrue);
      });

      test('returns false for locked constraint violation', () {
        final event = Event(
          id: 'event_1',
          name: 'Locked Constraint',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60,
            timeConstraintStrength: SchedulingPreferenceStrength.locked,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Schedule before constraint (violation, and locked)
        final slots = [TimeSlot(DateTime(2026, 1, 15, 8, 0))];
        expect(checker.satisfiesLockedConstraints(event, slots), isFalse);
      });
    });

    group('calculatePenaltyScore', () {
      test('returns 0 for no violations', () {
        final event = Event(
          id: 'event_1',
          name: 'No Constraints',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [TimeSlot(DateTime(2026, 1, 15, 10, 0))];
        expect(checker.calculatePenaltyScore(event, slots), equals(0.0));
      });

      test('returns 10.0 for weak violation', () {
        final event = Event(
          id: 'event_1',
          name: 'Weak Constraint',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60,
            timeConstraintStrength: SchedulingPreferenceStrength.weak,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [TimeSlot(DateTime(2026, 1, 15, 8, 0))];
        expect(checker.calculatePenaltyScore(event, slots), equals(10.0));
      });

      test('returns 100.0 for strong violation', () {
        final event = Event(
          id: 'event_1',
          name: 'Strong Constraint',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60,
            timeConstraintStrength: SchedulingPreferenceStrength.strong,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [TimeSlot(DateTime(2026, 1, 15, 8, 0))];
        expect(checker.calculatePenaltyScore(event, slots), equals(100.0));
      });

      test('returns infinity for locked violation', () {
        final event = Event(
          id: 'event_1',
          name: 'Locked Constraint',
          timingType: TimingType.flexible,
          status: EventStatus.pending,
          duration: const Duration(hours: 1),
          schedulingConstraint: SchedulingConstraint(
            notBeforeTime: 10 * 60,
            timeConstraintStrength: SchedulingPreferenceStrength.locked,
          ),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final slots = [TimeSlot(DateTime(2026, 1, 15, 8, 0))];
        expect(checker.calculatePenaltyScore(event, slots), equals(double.infinity));
      });
    });
  });
}
