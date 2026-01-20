import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import 'scheduling_strategy.dart';

/// Strategy that maximizes contiguous free time blocks
/// 
/// This strategy places events to:
/// - Minimize fragmentation of free time
/// - Create larger blocks of uninterrupted time for deep work
/// - Cluster events together rather than spreading them out
class MaxFreeTimeStrategy implements SchedulingStrategy {
  // Default work hours (9 AM to 5 PM)
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  @override
  String get name => 'max_free_time';

  @override
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  ) {
    final duration = event.effectiveDuration;
    final slotsNeeded = TimeSlot.durationToSlots(duration);

    // Find all possible placement windows
    final possiblePlacements = _findAllPossiblePlacements(grid, slotsNeeded);

    if (possiblePlacements.isEmpty) {
      // Fallback: search entire window for any available slots
      return grid.findAvailableSlots(duration);
    }

    // Choose the placement that results in the least fragmentation
    List<TimeSlot>? bestPlacement;
    double lowestFragmentation = double.infinity;

    for (final placement in possiblePlacements) {
      final fragmentation = _calculateFragmentation(placement, grid, slotsNeeded);
      if (fragmentation < lowestFragmentation) {
        lowestFragmentation = fragmentation;
        bestPlacement = placement;
      }
    }

    return bestPlacement;
  }

  /// Find all possible placements within work hours
  List<List<TimeSlot>> _findAllPossiblePlacements(
    AvailabilityGrid grid,
    int slotsNeeded,
  ) {
    final placements = <List<TimeSlot>>[];
    
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

    while (!currentDay.isAfter(windowEndDay)) {
      final dayPlacements = _findPlacementsInDay(currentDay, grid, slotsNeeded);
      placements.addAll(dayPlacements);
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return placements;
  }

  /// Find all possible consecutive slot placements within a day
  List<List<TimeSlot>> _findPlacementsInDay(
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

    final placements = <List<TimeSlot>>[];
    var current = searchStart;
    var candidates = <TimeSlot>[];

    while (current.start.isBefore(searchEnd)) {
      if (grid.isAvailable(current)) {
        candidates.add(current);

        if (candidates.length >= slotsNeeded) {
          // Record this valid placement (take just the slots we need)
          placements.add(candidates.sublist(candidates.length - slotsNeeded).toList());
        }
      } else {
        // Gap found, reset candidates
        candidates = [];
      }

      current = current.next;
    }

    return placements;
  }

  /// Calculate fragmentation score for a potential placement
  /// Lower score = less fragmentation = better
  /// 
  /// The algorithm prefers placing events:
  /// 1. Adjacent to existing events (to cluster them together)
  /// 2. At the edges of free blocks (to preserve larger contiguous free time)
  double _calculateFragmentation(
    List<TimeSlot> placement,
    AvailabilityGrid grid,
    int slotsNeeded,
  ) {
    if (placement.isEmpty) return double.infinity;

    // Check slots before and after the placement
    final beforeSlot = placement.first.previous;
    final afterSlot = placement.last.next;

    final hasEventBefore = !grid.isAvailable(beforeSlot);
    final hasEventAfter = !grid.isAvailable(afterSlot);

    // Calculate how this placement affects free time fragmentation
    // Placing next to existing events is preferred (clusters events together)
    double score = 0;

    if (!hasEventBefore && !hasEventAfter) {
      // Placement creates two new free time fragments - highest fragmentation
      score = 2.0;
    } else if (hasEventBefore && hasEventAfter) {
      // Placement fills a gap exactly - lowest fragmentation
      score = 0.0;
    } else {
      // Placement is adjacent to one event - medium fragmentation
      score = 1.0;
    }

    // Prefer placements at the start of free blocks to preserve end-of-day flexibility
    // Find how far into the free block this placement is
    int slotsFromStart = 0;
    var checkSlot = placement.first.previous;
    while (grid.isAvailable(checkSlot) && 
           checkSlot.start.isAfter(grid.windowStart)) {
      slotsFromStart++;
      checkSlot = checkSlot.previous;
    }

    // Add small penalty for placements that leave small fragments at the start
    if (slotsFromStart > 0 && slotsFromStart < slotsNeeded) {
      score += 0.5; // Creating a small unusable fragment
    }

    return score;
  }
}
