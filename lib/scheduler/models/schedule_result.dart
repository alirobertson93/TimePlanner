import 'package:time_planner/domain/entities/event.dart';
import 'scheduled_event.dart';
import 'conflict.dart';

/// Result of a scheduling operation
class ScheduleResult {
  const ScheduleResult({
    required this.success,
    required this.scheduledEvents,
    required this.unscheduledEvents,
    required this.conflicts,
    required this.computationTime,
    required this.strategyUsed,
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

  @override
  String toString() {
    return 'ScheduleResult(success: $success, scheduled: ${scheduledEvents.length}, '
        'unscheduled: ${unscheduledEvents.length}, conflicts: ${conflicts.length}, '
        'time: ${computationTime.inMilliseconds}ms)';
  }
}
