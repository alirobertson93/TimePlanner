import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import '../services/constraint_checker.dart';
import 'scheduling_strategy.dart';

/// Strategy that distributes events evenly across available time
/// 
/// Now respects scheduling constraints:
/// - Locked constraints: slots outside constraint window are rejected
/// - Strong constraints: slots outside constraint window receive significant penalty
/// - Weak constraints: slots outside constraint window receive minor penalty
class BalancedStrategy implements SchedulingStrategy {
  // TODO: Make work hours configurable per user
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  final ConstraintChecker _constraintChecker;

  BalancedStrategy({ConstraintChecker? constraintChecker})
      : _constraintChecker = constraintChecker ?? const ConstraintChecker();

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
    final constraint = event.schedulingConstraint;

    // Find the day with the fewest scheduled events
    final targetDay = _findLeastBusyDay(grid, event);

    // Try to find slots on that day first (using configurable work hours)
    // Respect time constraints if present
    final effectiveStartHour = _getEffectiveStartHour(constraint);
    final effectiveEndHour = _getEffectiveEndHour(constraint);

    final dayStart = DateTime(targetDay.year, targetDay.month, targetDay.day, effectiveStartHour, _getEffectiveStartMinute(constraint));
    final dayEnd = DateTime(targetDay.year, targetDay.month, targetDay.day, effectiveEndHour, _getEffectiveEndMinute(constraint));

    // If constraint is locked, only search within the constraint window
    final isLockedConstraint = constraint?.timeConstraintStrength == SchedulingPreferenceStrength.locked;

    var slotsOnTargetDay = _findSlotsInDayWithConstraints(
      targetDay,
      dayStart,
      dayEnd,
      grid,
      event,
      slotsNeeded,
      isLockedConstraint,
    );

    if (slotsOnTargetDay != null) {
      return slotsOnTargetDay;
    }

    // If no slots on target day, search all days
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

    // Collect all possible placements with their penalty scores
    final candidates = <_ScoredPlacement>[];

    while (!currentDay.isAfter(windowEndDay)) {
      // Skip the target day (already searched)
      if (currentDay.day == targetDay.day &&
          currentDay.month == targetDay.month &&
          currentDay.year == targetDay.year) {
        currentDay = currentDay.add(const Duration(days: 1));
        continue;
      }

      final dayStartSearch = DateTime(currentDay.year, currentDay.month, currentDay.day, effectiveStartHour, _getEffectiveStartMinute(constraint));
      final dayEndSearch = DateTime(currentDay.year, currentDay.month, currentDay.day, effectiveEndHour, _getEffectiveEndMinute(constraint));

      final placements = _findAllPlacementsInDay(
        currentDay,
        dayStartSearch,
        dayEndSearch,
        grid,
        event,
        slotsNeeded,
        isLockedConstraint,
      );

      for (final slots in placements) {
        final penalty = _constraintChecker.calculatePenaltyScore(event, slots);
        // Only include if not a locked constraint violation
        if (penalty < double.infinity) {
          candidates.add(_ScoredPlacement(slots: slots, penalty: penalty));
        }
      }

      currentDay = currentDay.add(const Duration(days: 1));
    }

    if (candidates.isEmpty) {
      // Last resort: fall back to any available slot
      // (but check locked constraints)
      return _findFallbackSlots(grid, event, duration, isLockedConstraint);
    }

    // Sort by penalty (lower is better) and return the best
    candidates.sort((a, b) => a.penalty.compareTo(b.penalty));
    return candidates.first.slots;
  }

  /// Find the day with the fewest scheduled events
  /// Now considers day constraints if present
  DateTime _findLeastBusyDay(AvailabilityGrid grid, Event event) {
    var leastBusy = grid.windowStart;
    var minScore = double.infinity;

    final constraint = event.schedulingConstraint;
    final isLockedDayConstraint = constraint?.dayConstraintStrength == SchedulingPreferenceStrength.locked;

    var current = grid.windowStart;
    while (current.isBefore(grid.windowEnd)) {
      final eventCount = grid.getEventCountForDay(current);

      // Check if this day is allowed
      var dayPenalty = 0.0;
      if (constraint?.hasDayConstraints == true) {
        // Convert DateTime weekday (1-7, Mon-Sun) to constraint format (0-6, Sun-Sat)
        final dayOfWeek = current.weekday == 7 ? 0 : current.weekday;
        if (!constraint!.preferredDays!.contains(dayOfWeek)) {
          if (isLockedDayConstraint) {
            // Skip this day entirely if locked
            current = current.add(const Duration(days: 1));
            continue;
          }
          // Add penalty for non-preferred day
          dayPenalty = constraint.dayConstraintStrength == SchedulingPreferenceStrength.strong
              ? 100.0
              : 10.0;
        }
      }

      final totalScore = eventCount + dayPenalty;
      if (totalScore < minScore) {
        minScore = totalScore;
        leastBusy = current;
      }
      current = current.add(const Duration(days: 1));
    }

    return leastBusy;
  }

  /// Find slots in a specific day, respecting constraints
  List<TimeSlot>? _findSlotsInDayWithConstraints(
    DateTime day,
    DateTime dayStart,
    DateTime dayEnd,
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
    bool isLockedConstraint,
  ) {
    final placements = _findAllPlacementsInDay(
      day,
      dayStart,
      dayEnd,
      grid,
      event,
      slotsNeeded,
      isLockedConstraint,
    );

    if (placements.isEmpty) {
      return null;
    }

    // Score each placement and return the best
    final scoredPlacements = <_ScoredPlacement>[];
    for (final slots in placements) {
      final penalty = _constraintChecker.calculatePenaltyScore(event, slots);
      // Only include if not a hard constraint violation
      if (penalty < double.infinity) {
        scoredPlacements.add(_ScoredPlacement(slots: slots, penalty: penalty));
      }
    }

    if (scoredPlacements.isEmpty) {
      return null;
    }

    scoredPlacements.sort((a, b) => a.penalty.compareTo(b.penalty));
    return scoredPlacements.first.slots;
  }

  /// Find all possible placements within a day
  List<List<TimeSlot>> _findAllPlacementsInDay(
    DateTime day,
    DateTime dayStart,
    DateTime dayEnd,
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
    bool isLockedConstraint,
  ) {
    final placements = <List<TimeSlot>>[];

    // Don't search before the scheduling window starts
    final searchStart = dayStart.isBefore(grid.windowStart)
        ? TimeSlot(TimeSlot.roundUp(grid.windowStart))
        : TimeSlot(TimeSlot.roundDown(dayStart));

    // Don't search past the scheduling window ends
    final searchEnd = dayEnd.isAfter(grid.windowEnd) ? grid.windowEnd : dayEnd;

    var current = searchStart;
    var candidates = <TimeSlot>[];

    while (current.start.isBefore(searchEnd)) {
      if (grid.isAvailable(current)) {
        candidates.add(current);

        if (candidates.length >= slotsNeeded) {
          final placement = candidates.sublist(candidates.length - slotsNeeded).toList();
          
          // For locked constraints, only add if satisfies constraints
          if (isLockedConstraint) {
            if (_constraintChecker.satisfiesLockedConstraints(event, placement)) {
              placements.add(placement);
            }
          } else {
            placements.add(placement);
          }
        }
      } else {
        candidates = [];
      }

      current = current.next;
    }

    return placements;
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

  /// Get effective start hour considering constraints
  int _getEffectiveStartHour(dynamic constraint) {
    if (constraint?.notBeforeTime != null) {
      return constraint.notBeforeTime ~/ 60;
    }
    return defaultWorkStartHour;
  }

  /// Get effective start minute considering constraints
  int _getEffectiveStartMinute(dynamic constraint) {
    if (constraint?.notBeforeTime != null) {
      return constraint.notBeforeTime % 60;
    }
    return 0;
  }

  /// Get effective end hour considering constraints
  int _getEffectiveEndHour(dynamic constraint) {
    if (constraint?.notAfterTime != null) {
      return constraint.notAfterTime ~/ 60;
    }
    return defaultWorkEndHour;
  }

  /// Get effective end minute considering constraints
  int _getEffectiveEndMinute(dynamic constraint) {
    if (constraint?.notAfterTime != null) {
      return constraint.notAfterTime % 60;
    }
    return 0;
  }
}

/// Helper class to track placements with their penalty scores
class _ScoredPlacement {
  final List<TimeSlot> slots;
  final double penalty;

  _ScoredPlacement({required this.slots, required this.penalty});
}
