import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../strategies/scheduling_strategy.dart';

/// Request to schedule events
class ScheduleRequest {
  const ScheduleRequest({
    required this.windowStart,
    required this.windowEnd,
    required this.fixedEvents,
    required this.flexibleEvents,
    required this.goals,
    required this.strategy,
  });

  /// Start of scheduling window
  final DateTime windowStart;

  /// End of scheduling window
  final DateTime windowEnd;

  /// Events with fixed times that cannot be moved
  final List<Event> fixedEvents;

  /// Events that can be scheduled flexibly
  final List<Event> flexibleEvents;

  /// Goals to consider during scheduling
  final List<Goal> goals;

  /// Strategy to use for scheduling
  final SchedulingStrategy strategy;
}
