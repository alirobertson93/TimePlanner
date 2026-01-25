import 'package:time_planner/domain/entities/event.dart';
import 'scheduled_event.dart';
import 'conflict.dart';
import 'constraint_violation.dart';

/// Result of a scheduling operation
class ScheduleResult {
  const ScheduleResult({
    required this.success,
    required this.scheduledEvents,
    required this.unscheduledEvents,
    required this.conflicts,
    required this.computationTime,
    required this.strategyUsed,
    this.constraintViolations = const [],
  });

  /// Whether scheduling was successful
  final bool success;

  /// Events that were successfully scheduled
  final List<ScheduledEvent> scheduledEvents;

  /// Events that could not be scheduled
  final List<Event> unscheduledEvents;

  /// Conflicts detected during scheduling
  final List<Conflict> conflicts;

  /// Time taken to compute the schedule
  final Duration computationTime;

  /// Name of the strategy used
  final String strategyUsed;

  /// Constraint violations that occurred during scheduling
  /// 
  /// These are soft violations (weak/strong constraints) that were
  /// allowed but should be shown to the user as warnings.
  /// Hard violations (locked constraints) result in unscheduled events.
  final List<ConstraintViolation> constraintViolations;

  /// Returns true if there are any constraint warnings to show
  bool get hasConstraintWarnings => constraintViolations.isNotEmpty;

  /// Returns the number of events with constraint warnings
  int get eventsWithConstraintWarnings {
    final eventIds = constraintViolations.map((v) => v.eventId).toSet();
    return eventIds.length;
  }

  @override
  String toString() {
    return 'ScheduleResult(success: $success, scheduled: ${scheduledEvents.length}, '
        'unscheduled: ${unscheduledEvents.length}, conflicts: ${conflicts.length}, '
        'constraintWarnings: ${constraintViolations.length}, '
        'time: ${computationTime.inMilliseconds}ms)';
  }
}
