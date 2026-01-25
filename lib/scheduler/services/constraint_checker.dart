import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/scheduling_constraint.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';
import '../models/constraint_violation.dart';
import '../models/time_slot.dart';

/// Service to validate scheduling constraints
///
/// Checks time slots against event constraints and calculates penalty scores.
class ConstraintChecker {
  const ConstraintChecker();

  /// Check if a proposed time slot violates any constraints
  ///
  /// Returns a list of violations (empty if no violations)
  List<ConstraintViolation> checkConstraints(
    Event event,
    List<TimeSlot> proposedSlots,
  ) {
    final constraint = event.schedulingConstraint;
    if (constraint == null || !constraint.hasAnyConstraints) {
      return [];
    }

    final violations = <ConstraintViolation>[];
    final proposedStart = proposedSlots.first.start;
    final proposedEnd = proposedSlots.last.end;

    // Check for conflicting constraints first
    final conflictViolation = _checkConflictingConstraints(event, constraint);
    if (conflictViolation != null) {
      violations.add(conflictViolation);
    }

    // Check time constraints
    if (constraint.hasTimeConstraints) {
      violations.addAll(_checkTimeConstraints(
        event,
        constraint,
        proposedStart,
        proposedEnd,
      ));
    }

    // Check day constraints
    if (constraint.hasDayConstraints) {
      final dayViolation = _checkDayConstraints(
        event,
        constraint,
        proposedStart,
      );
      if (dayViolation != null) {
        violations.add(dayViolation);
      }
    }

    return violations;
  }

  /// Check if the proposed slot satisfies locked constraints
  ///
  /// Returns true if the slot is valid (no locked constraints violated)
  bool satisfiesLockedConstraints(
    Event event,
    List<TimeSlot> proposedSlots,
  ) {
    final violations = checkConstraints(event, proposedSlots);
    return !violations.any((v) => v.isHardViolation);
  }

  /// Calculate total penalty score for constraint violations
  ///
  /// Used by strategies to rank slot options. Lower is better.
  double calculatePenaltyScore(
    Event event,
    List<TimeSlot> proposedSlots,
  ) {
    final violations = checkConstraints(event, proposedSlots);
    return violations.fold(0.0, (sum, v) => sum + v.penaltyScore);
  }

  /// Check if the constraint itself is internally conflicting
  ConstraintViolation? _checkConflictingConstraints(
    Event event,
    SchedulingConstraint constraint,
  ) {
    // Check if not_before > not_after (impossible to satisfy)
    if (constraint.notBeforeTime != null && constraint.notAfterTime != null) {
      if (constraint.notBeforeTime! >= constraint.notAfterTime!) {
        return ConstraintViolation(
          eventId: event.id,
          eventName: event.name,
          violationType: ConstraintViolationType.conflictingConstraints,
          description:
              '"Not before ${SchedulingConstraint.formatTimeOfDay(constraint.notBeforeTime!)}" '
              'conflicts with "Not after ${SchedulingConstraint.formatTimeOfDay(constraint.notAfterTime!)}"',
          strength: constraint.timeConstraintStrength,
        );
      }
    }

    return null;
  }

  /// Check time-of-day constraints
  List<ConstraintViolation> _checkTimeConstraints(
    Event event,
    SchedulingConstraint constraint,
    DateTime proposedStart,
    DateTime proposedEnd,
  ) {
    final violations = <ConstraintViolation>[];
    final strength = constraint.timeConstraintStrength;

    // Convert proposed start time to minutes from midnight
    final proposedStartMinutes = proposedStart.hour * 60 + proposedStart.minute;

    // Check "not before" constraint
    if (constraint.notBeforeTime != null) {
      if (proposedStartMinutes < constraint.notBeforeTime!) {
        violations.add(ConstraintViolation(
          eventId: event.id,
          eventName: event.name,
          violationType: ConstraintViolationType.scheduledTooEarly,
          description:
              'Scheduled at ${_formatTime(proposedStartMinutes)} but should be after '
              '${SchedulingConstraint.formatTimeOfDay(constraint.notBeforeTime!)}',
          strength: strength,
          proposedTime: proposedStart,
          constraintTime: constraint.notBeforeTime,
        ));
      }
    }

    // Check "not after" constraint
    if (constraint.notAfterTime != null) {
      // The event must START before the "not after" time
      if (proposedStartMinutes > constraint.notAfterTime!) {
        violations.add(ConstraintViolation(
          eventId: event.id,
          eventName: event.name,
          violationType: ConstraintViolationType.scheduledTooLate,
          description:
              'Scheduled at ${_formatTime(proposedStartMinutes)} but should start before '
              '${SchedulingConstraint.formatTimeOfDay(constraint.notAfterTime!)}',
          strength: strength,
          proposedTime: proposedStart,
          constraintTime: constraint.notAfterTime,
        ));
      }
    }

    return violations;
  }

  /// Check day-of-week constraints
  ConstraintViolation? _checkDayConstraints(
    Event event,
    SchedulingConstraint constraint,
    DateTime proposedStart,
  ) {
    if (constraint.preferredDays == null || constraint.preferredDays!.isEmpty) {
      return null;
    }

    // Convert DateTime weekday (1-7, Mon-Sun) to constraint format (0-6, Sun-Sat)
    final proposedDayOfWeek = proposedStart.weekday == 7 ? 0 : proposedStart.weekday;

    if (!constraint.preferredDays!.contains(proposedDayOfWeek)) {
      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final preferredDayNames =
          constraint.preferredDays!.map((d) => dayNames[d]).join(', ');

      return ConstraintViolation(
        eventId: event.id,
        eventName: event.name,
        violationType: ConstraintViolationType.wrongDay,
        description:
            'Scheduled on ${dayNames[proposedDayOfWeek]} but preferred days are: $preferredDayNames',
        strength: constraint.dayConstraintStrength,
      );
    }

    return null;
  }

  /// Format minutes from midnight to a readable time string
  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHours = hours > 12 ? hours - 12 : (hours == 0 ? 12 : hours);
    return '$displayHours:${mins.toString().padLeft(2, '0')} $period';
  }

  /// Check if a time slot respects time constraints
  ///
  /// This is a quick check for filtering candidate slots
  bool isSlotWithinTimeConstraints(
    SchedulingConstraint? constraint,
    TimeSlot slot,
  ) {
    if (constraint == null || !constraint.hasTimeConstraints) {
      return true;
    }

    final slotMinutes = slot.start.hour * 60 + slot.start.minute;

    if (constraint.notBeforeTime != null &&
        slotMinutes < constraint.notBeforeTime!) {
      return false;
    }

    if (constraint.notAfterTime != null &&
        slotMinutes > constraint.notAfterTime!) {
      return false;
    }

    return true;
  }

  /// Get the earliest allowed start time based on constraints
  ///
  /// Returns the time in minutes from midnight, or null if no constraint
  int? getEarliestAllowedTime(SchedulingConstraint? constraint) {
    return constraint?.notBeforeTime;
  }

  /// Get the latest allowed start time based on constraints
  ///
  /// Returns the time in minutes from midnight, or null if no constraint
  int? getLatestAllowedTime(SchedulingConstraint? constraint) {
    return constraint?.notAfterTime;
  }
}
