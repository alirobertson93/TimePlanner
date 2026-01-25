import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';

/// Represents a violation of a scheduling constraint
class ConstraintViolation {
  const ConstraintViolation({
    required this.eventId,
    required this.eventName,
    required this.violationType,
    required this.description,
    required this.strength,
    this.proposedTime,
    this.constraintTime,
  });

  /// ID of the event with the constraint violation
  final String eventId;

  /// Name of the event for display purposes
  final String eventName;

  /// Type of constraint that was violated
  final ConstraintViolationType violationType;

  /// Human-readable description of the violation
  final String description;

  /// Strength of the violated constraint
  final SchedulingPreferenceStrength strength;

  /// The proposed time that violated the constraint
  final DateTime? proposedTime;

  /// The constraint time that was violated
  final int? constraintTime;

  /// Returns true if this is a hard violation (locked constraint)
  bool get isHardViolation => strength == SchedulingPreferenceStrength.locked;

  /// Returns a penalty score for this violation based on strength
  /// Locked: not applicable (should reject)
  /// Strong: 100.0 penalty
  /// Weak: 10.0 penalty
  double get penaltyScore {
    switch (strength) {
      case SchedulingPreferenceStrength.locked:
        return double.infinity;
      case SchedulingPreferenceStrength.strong:
        return 100.0;
      case SchedulingPreferenceStrength.weak:
        return 10.0;
    }
  }

  @override
  String toString() {
    return 'ConstraintViolation($eventName: $violationType - $description)';
  }
}

/// Types of constraint violations
enum ConstraintViolationType {
  /// Event scheduled before its "not before" time
  scheduledTooEarly,

  /// Event scheduled after its "not after" time
  scheduledTooLate,

  /// Event scheduled outside the allowed time window
  outsideTimeWindow,

  /// Event scheduled on a non-preferred day
  wrongDay,

  /// Constraints conflict with each other (e.g., not before 3pm but not after 2pm)
  conflictingConstraints,

  /// No available slots that satisfy the constraint
  noValidSlots,
}
