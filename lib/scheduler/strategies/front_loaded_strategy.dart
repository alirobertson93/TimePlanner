import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import 'scheduling_strategy.dart';

/// Strategy that schedules events as early as possible in the time window.
///
/// This strategy prioritizes placing events at the beginning of the week,
/// ensuring important work gets done early. It searches from the start
/// of the scheduling window and places each event in the first available
/// time slots that can accommodate it.
class FrontLoadedStrategy implements SchedulingStrategy {
  // TODO: Make work hours configurable per user
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  @override
  String get name => 'front-loaded';

  @override
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  ) {
    final duration = event.effectiveDuration;
    final slotsNeeded = TimeSlot.durationToSlots(duration);

    // Start from the beginning of the scheduling window
    var currentDay = grid.windowStart;

    // Search day by day from the start
    while (currentDay.isBefore(grid.windowEnd)) {
      // Try to find slots within work hours for this day
      final dayStart = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        defaultWorkStartHour,
        0,
      );
      final dayEnd = DateTime(
        currentDay.year,
        currentDay.month,
        currentDay.day,
        defaultWorkEndHour,
        0,
      );

      var current = TimeSlot(TimeSlot.roundDown(dayStart));
      final candidates = <TimeSlot>[];

      while (current.start.isBefore(dayEnd)) {
        if (grid.isAvailable(current)) {
          candidates.add(current);

          if (candidates.length == slotsNeeded) {
            return candidates;
          }
        } else {
          // Reset candidates if we hit an occupied slot
          candidates.clear();
        }

        current = current.next;
      }

      // Move to next day
      currentDay = currentDay.add(const Duration(days: 1));
    }

    // If no slots found within work hours, fall back to any available slots
    return grid.findAvailableSlots(duration);
  }
}
