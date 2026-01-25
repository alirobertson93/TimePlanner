import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import '../services/constraint_checker.dart';
import 'scheduling_strategy.dart';

/// Strategy that schedules events as early as possible in the week
/// 
/// This strategy is useful for users who want to:
/// - Get important work done early in the week
/// - Front-load their schedule to leave time for unexpected tasks
/// - Ensure deadlines are met with buffer time
///
/// Now respects scheduling constraints:
/// - Locked constraints: slots outside constraint window are rejected
/// - Strong/Weak constraints: prefer slots within constraint window
class FrontLoadedStrategy implements SchedulingStrategy {
  // Default work hours (9 AM to 5 PM)
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  final ConstraintChecker _constraintChecker;

  FrontLoadedStrategy({ConstraintChecker? constraintChecker})
      : _constraintChecker = constraintChecker ?? const ConstraintChecker();

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
    final constraint = event.schedulingConstraint;
    final isLockedConstraint = constraint?.timeConstraintStrength == SchedulingPreferenceStrength.locked;

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
    // For locked day constraints, skip non-preferred days
    while (!currentDay.isAfter(windowEndDay)) {
      // Check day constraint if present and locked
      if (constraint?.hasDayConstraints == true && 
          constraint!.dayConstraintStrength == SchedulingPreferenceStrength.locked) {
        final dayOfWeek = currentDay.weekday == 7 ? 0 : currentDay.weekday;
        if (!constraint.preferredDays!.contains(dayOfWeek)) {
          currentDay = currentDay.add(const Duration(days: 1));
          continue;
        }
      }

      final slots = _findSlotsInDay(currentDay, grid, event, slotsNeeded, isLockedConstraint);
      if (slots != null) {
        return slots;
      }
      currentDay = currentDay.add(const Duration(days: 1));
    }

    // Fallback: search entire window for any available slots
    return _findFallbackSlots(grid, event, duration, isLockedConstraint);
  }

  /// Find the earliest available consecutive slots within a specific day
  List<TimeSlot>? _findSlotsInDay(
    DateTime day,
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
    bool isLockedConstraint,
  ) {
    final constraint = event.schedulingConstraint;
    
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

    var current = searchStart;
    final candidates = <TimeSlot>[];

    while (current.start.isBefore(searchEnd)) {
      if (grid.isAvailable(current)) {
        candidates.add(current);

        if (candidates.length == slotsNeeded) {
          // Check constraints for locked constraints
          if (isLockedConstraint) {
            if (_constraintChecker.satisfiesLockedConstraints(event, candidates)) {
              return candidates.toList();
            }
            // Remove first candidate and continue searching
            candidates.removeAt(0);
          } else {
            return candidates.toList();
          }
        }
      } else {
        // Gap found, reset candidates
        candidates.clear();
      }

      current = current.next;
    }

    return null; // No slots found on this day
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
