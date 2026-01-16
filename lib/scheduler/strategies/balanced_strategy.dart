import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import 'scheduling_strategy.dart';

/// Strategy that distributes events evenly across available time
class BalancedStrategy implements SchedulingStrategy {
  @override
  String get name => 'balanced';

  @override
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  ) {
    final duration = event.effectiveDuration;
    final slotsNeeded = TimeSlot.durationToSlots(duration);

    // Find the day with the fewest scheduled events
    final targetDay = _findLeastBusyDay(grid);

    // Try to find slots on that day first
    final dayStart = DateTime(targetDay.year, targetDay.month, targetDay.day, 9, 0);
    final dayEnd = DateTime(targetDay.year, targetDay.month, targetDay.day, 17, 0);

    var current = TimeSlot(TimeSlot.roundDown(dayStart));
    final candidates = <TimeSlot>[];

    while (current.start.isBefore(dayEnd)) {
      if (grid.isAvailable(current)) {
        candidates.add(current);

        if (candidates.length == slotsNeeded) {
          return candidates;
        }
      } else {
        candidates.clear();
      }

      current = current.next;
    }

    // If no slots found on target day, search across entire window
    return grid.findAvailableSlots(duration);
  }

  /// Find the day with the fewest scheduled events
  DateTime _findLeastBusyDay(AvailabilityGrid grid) {
    var leastBusy = grid.windowStart;
    var minEvents = double.infinity;

    var current = grid.windowStart;
    while (current.isBefore(grid.windowEnd)) {
      final eventCount = grid.getEventCountForDay(current);
      if (eventCount < minEvents) {
        minEvents = eventCount.toDouble();
        leastBusy = current;
      }
      current = current.add(const Duration(days: 1));
    }

    return leastBusy;
  }
}
