import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import 'scheduling_strategy.dart';

/// Strategy that schedules events as early as possible in the week
/// 
/// This strategy is useful for users who want to:
/// - Get important work done early in the week
/// - Front-load their schedule to leave time for unexpected tasks
/// - Ensure deadlines are met with buffer time
class FrontLoadedStrategy implements SchedulingStrategy {
  // Default work hours (9 AM to 5 PM)
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  @override
  String get name => 'front_loaded';

  @override
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  ) {
    final duration = event.effectiveDuration;
    final slotsNeeded = TimeSlot.durationToSlots(duration);

    // Start from the beginning of the scheduling window
    var currentDay = DateTime(
      grid.windowStart.year,
      grid.windowStart.month,
      grid.windowStart.day,
    );
    final windowEndDay = DateTime(
      grid.windowEnd.year,
      grid.windowEnd.month,
      grid.windowEnd.day,
    );

    // Search day by day, starting from the earliest
    while (!currentDay.isAfter(windowEndDay)) {
      final slots = _findSlotsInDay(currentDay, grid, slotsNeeded);
      if (slots != null) {
        return slots;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    // Fallback: search entire window for any available slots
    return grid.findAvailableSlots(duration);
  }

  /// Find the earliest available consecutive slots within a specific day
  List<TimeSlot>? _findSlotsInDay(
    DateTime day,
    AvailabilityGrid grid,
    int slotsNeeded,
  ) {
    final dayStart = DateTime(day.year, day.month, day.day, defaultWorkStartHour, 0);
    final dayEnd = DateTime(day.year, day.month, day.day, defaultWorkEndHour, 0);

    // Don't search before the scheduling window starts
    final searchStart = dayStart.isBefore(grid.windowStart) 
        ? TimeSlot(TimeSlot.roundUp(grid.windowStart))
        : TimeSlot(TimeSlot.roundDown(dayStart));
    
    // Don't search past the scheduling window ends
    final searchEnd = dayEnd.isAfter(grid.windowEnd) 
        ? grid.windowEnd 
        : dayEnd;

    var current = searchStart;
    final candidates = <TimeSlot>[];

    while (current.start.isBefore(searchEnd)) {
      if (grid.isAvailable(current)) {
        candidates.add(current);

        if (candidates.length == slotsNeeded) {
          return candidates;
        }
      } else {
        // Gap found, reset candidates
        candidates.clear();
      }

      current = current.next;
    }

    return null; // No slots found on this day
  }
}
