import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import 'scheduling_strategy.dart';

/// Strategy that maximizes contiguous free time blocks.
///
/// This strategy places events in a way that minimizes fragmentation
/// of free time. It analyzes available windows and places events
/// where they cause the least fragmentation, preserving larger
/// contiguous free blocks for longer activities or breaks.
class MaxFreeTimeStrategy implements SchedulingStrategy {
  // TODO: Make work hours configurable per user
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  @override
  String get name => 'max-free-time';

  @override
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  ) {
    final duration = event.effectiveDuration;
    final slotsNeeded = TimeSlot.durationToSlots(duration);

    // Find all possible placement positions
    final placements = _findAllPossiblePlacements(grid, slotsNeeded);

    if (placements.isEmpty) {
      // Fall back to any available slots
      return grid.findAvailableSlots(duration);
    }

    // Score each placement based on fragmentation impact
    List<TimeSlot>? bestPlacement;
    double bestScore = double.negativeInfinity;

    for (final placement in placements) {
      final score = _scorePlacement(placement, grid);
      if (score > bestScore) {
        bestScore = score;
        bestPlacement = placement;
      }
    }

    return bestPlacement;
  }

  /// Find all possible placement positions within work hours
  List<List<TimeSlot>> _findAllPossiblePlacements(
    AvailabilityGrid grid,
    int slotsNeeded,
  ) {
    final placements = <List<TimeSlot>>[];
    var currentDay = grid.windowStart;

    while (currentDay.isBefore(grid.windowEnd)) {
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

      while (current.start.isBefore(dayEnd)) {
        final candidates = <TimeSlot>[];
        var check = current;

        // Check if we can fit the required slots starting here
        while (candidates.length < slotsNeeded && check.start.isBefore(dayEnd)) {
          if (grid.isAvailable(check)) {
            candidates.add(check);
            check = check.next;
          } else {
            break;
          }
        }

        if (candidates.length == slotsNeeded) {
          placements.add(List.from(candidates));
        }

        current = current.next;
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }

    return placements;
  }

  /// Score a placement based on how well it preserves contiguous free time.
  ///
  /// Higher score = better placement (less fragmentation).
  /// We prefer placements that:
  /// 1. Are adjacent to already occupied slots (consolidate events)
  /// 2. Don't split large free blocks into small fragments
  double _scorePlacement(List<TimeSlot> placement, AvailabilityGrid grid) {
    double score = 0;

    final firstSlot = placement.first;
    final lastSlot = placement.last;

    // Check if placement is adjacent to existing events (good for consolidation)
    final slotBefore = firstSlot.previous;
    final slotAfter = lastSlot.next;

    // Reward adjacency to existing events
    if (grid.getEventAt(slotBefore) != null) {
      score += 10.0;
    }
    if (grid.getEventAt(slotAfter) != null) {
      score += 10.0;
    }

    // Calculate free block sizes before and after placement
    final freeBlockBefore = _measureFreeBlockSize(slotBefore, grid, -1);
    final freeBlockAfter = _measureFreeBlockSize(slotAfter, grid, 1);

    // Penalize if we're creating small fragments
    // Prefer positions where we're not splitting large free blocks
    if (freeBlockBefore == 0 && freeBlockAfter == 0) {
      // This would create isolated free time on both sides - penalize
      score -= 5.0;
    }

    // Prefer end-of-day or start-of-day placements (preserves midday free time)
    final hour = firstSlot.start.hour;
    final isStartOfDay = hour == defaultWorkStartHour;
    final isEndOfDay = lastSlot.end.hour >= defaultWorkEndHour - 1;
    if (isStartOfDay || isEndOfDay) {
      score += 5.0;
    }

    return score;
  }

  /// Measure the size of a contiguous free block in a given direction.
  /// Direction: -1 for backward, 1 for forward
  int _measureFreeBlockSize(TimeSlot start, AvailabilityGrid grid, int direction) {
    int count = 0;
    var current = start;

    // Limit search to reasonable bounds (work hours in 15-minute slots)
    // 8 hours * 4 slots per hour = 32 slots
    const slotsPerHour = 4;
    const maxSlots = (defaultWorkEndHour - defaultWorkStartHour) * slotsPerHour;

    while (count < maxSlots) {
      if (!grid.isAvailable(current)) {
        break;
      }
      count++;
      current = direction > 0 ? current.next : current.previous;
    }

    return count;
  }
}
