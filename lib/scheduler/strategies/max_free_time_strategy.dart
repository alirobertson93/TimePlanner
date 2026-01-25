import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import '../services/constraint_checker.dart';
import 'scheduling_strategy.dart';

/// Strategy that maximizes contiguous free time blocks
/// 
/// This strategy places events to:
/// - Minimize fragmentation of free time
/// - Create larger blocks of uninterrupted time for deep work
/// - Cluster events together rather than spreading them out
///
/// Now respects scheduling constraints:
/// - Locked constraints: only considers placements within constraint window
/// - Strong/Weak constraints: adds penalty to fragmentation score
class MaxFreeTimeStrategy implements SchedulingStrategy {
  // Default work hours (9 AM to 5 PM)
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;
  
  /// Penalty score for creating small unusable fragments
  static const double smallFragmentPenalty = 0.5;

  final ConstraintChecker _constraintChecker;

  MaxFreeTimeStrategy({ConstraintChecker? constraintChecker})
      : _constraintChecker = constraintChecker ?? const ConstraintChecker();

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
    final constraint = event.schedulingConstraint;
    final isLockedConstraint = constraint?.timeConstraintStrength == SchedulingPreferenceStrength.locked;

    // Find all possible placement windows
    final possiblePlacements = _findAllPossiblePlacements(grid, event, slotsNeeded);

    if (possiblePlacements.isEmpty) {
      // Fallback: search entire window for any available slots
      return _findFallbackSlots(grid, event, duration, isLockedConstraint);
    }

    // Choose the placement that results in the least fragmentation + constraint penalty
    List<TimeSlot>? bestPlacement;
    double lowestScore = double.infinity;

    for (final placement in possiblePlacements) {
      // Calculate combined score: fragmentation + constraint penalty
      final fragmentationScore = _calculateFragmentation(placement, grid, slotsNeeded);
      final constraintPenalty = _constraintChecker.calculatePenaltyScore(event, placement);
      
      // Skip if locked constraint is violated
      if (constraintPenalty == double.infinity) {
        continue;
      }

      final totalScore = fragmentationScore + constraintPenalty;
      if (totalScore < lowestScore) {
        lowestScore = totalScore;
        bestPlacement = placement;
      }
    }

    return bestPlacement ?? _findFallbackSlots(grid, event, duration, isLockedConstraint);
  }

  /// Find all possible placements within work hours, considering constraints
  List<List<TimeSlot>> _findAllPossiblePlacements(
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
  ) {
    final placements = <List<TimeSlot>>[];
    final constraint = event.schedulingConstraint;
    final isLockedDayConstraint = constraint?.dayConstraintStrength == SchedulingPreferenceStrength.locked;
    
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
      // Check day constraint if present and locked
      if (isLockedDayConstraint && constraint!.hasDayConstraints) {
        final dayOfWeek = currentDay.weekday == 7 ? 0 : currentDay.weekday;
        if (!constraint.preferredDays!.contains(dayOfWeek)) {
          currentDay = currentDay.add(const Duration(days: 1));
          continue;
        }
      }

      final dayPlacements = _findPlacementsInDay(currentDay, grid, event, slotsNeeded);
      placements.addAll(dayPlacements);
      currentDay = currentDay.add(const Duration(days: 1));
    }

    return placements;
  }

  /// Find all possible consecutive slot placements within a day
  List<List<TimeSlot>> _findPlacementsInDay(
    DateTime day,
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
  ) {
    final constraint = event.schedulingConstraint;
    final isLockedTimeConstraint = constraint?.timeConstraintStrength == SchedulingPreferenceStrength.locked;
    
    // Calculate effective work hours considering constraints
    final effectiveStartHour = constraint?.notBeforeTime != null 
        ? constraint!.notBeforeTime! ~/ 60 
        : defaultWorkStartHour;
    final effectiveStartMinute = constraint?.notBeforeTime != null 
        ? constraint!.notBeforeTime! % 60 
        : 0;
    final effectiveEndHour = constraint?.notAfterTime != null 
        ? constraint!.notAfterTime! ~/ 60 
        : defaultWorkEndHour;
    final effectiveEndMinute = constraint?.notAfterTime != null 
        ? constraint!.notAfterTime! % 60 
        : 0;

    final dayStart = DateTime(day.year, day.month, day.day, effectiveStartHour, effectiveStartMinute);
    final dayEnd = DateTime(day.year, day.month, day.day, effectiveEndHour, effectiveEndMinute);

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
          final placement = candidates.sublist(candidates.length - slotsNeeded).toList();
          
          // For locked constraints, only add if satisfies constraints
          if (isLockedTimeConstraint) {
            if (_constraintChecker.satisfiesLockedConstraints(event, placement)) {
              placements.add(placement);
            }
          } else {
            placements.add(placement);
          }
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
      score += smallFragmentPenalty; // Creating a small unusable fragment
    }

    return score;
  }

  /// Fallback to find any available slot
  List<TimeSlot>? _findFallbackSlots(
    AvailabilityGrid grid,
    Event event,
    Duration duration,
    bool isLockedConstraint,
  ) {
    if (!isLockedConstraint) {
      return grid.findAvailableSlots(duration);
    }

    // For locked constraints, search entire grid but filter by constraints
    final slotsNeeded = TimeSlot.durationToSlots(duration);
    var current = TimeSlot(TimeSlot.roundDown(grid.windowStart));
    var candidates = <TimeSlot>[];

    while (current.start.isBefore(grid.windowEnd)) {
      if (grid.isAvailable(current)) {
        candidates.add(current);

        if (candidates.length >= slotsNeeded) {
          final placement = candidates.sublist(candidates.length - slotsNeeded).toList();
          if (_constraintChecker.satisfiesLockedConstraints(event, placement)) {
            return placement;
          }
        }
      } else {
        candidates = [];
      }

      current = current.next;
    }

    return null;
  }
}
