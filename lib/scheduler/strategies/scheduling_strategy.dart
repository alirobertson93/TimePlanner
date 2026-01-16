import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';

/// Abstract strategy for scheduling events
abstract class SchedulingStrategy {
  /// Name of this strategy
  String get name;

  /// Find available slots for an event using this strategy
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  );
}
