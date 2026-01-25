import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/enums/scheduling_preference_strength.dart';
import '../models/availability_grid.dart';
import '../models/scheduled_event.dart';
import '../models/time_slot.dart';
import '../services/constraint_checker.dart';
import 'scheduling_strategy.dart';

/// Strategy that minimizes changes to an existing schedule
/// 
/// This strategy is useful for:
/// - Rescheduling when events are completed or cancelled
/// - Making small adjustments without disrupting the entire week
/// - Preserving user's mental model of their schedule
///
/// Now respects scheduling constraints:
/// - Locked constraints: only considers placements within constraint window
/// - Strong/Weak constraints: adds penalty to disruption score
class LeastDisruptionStrategy implements SchedulingStrategy {
  /// Optional: existing schedule to reference for disruption calculation
  final List<ScheduledEvent> existingSchedule;

  // Default work hours (9 AM to 5 PM)
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;
  
  /// Maximum number of 15-minute slots to search in either direction (24 hours)
  static const int maxSearchSlots = 96;

  final ConstraintChecker _constraintChecker;

  LeastDisruptionStrategy({
    this.existingSchedule = const [],
    ConstraintChecker? constraintChecker,
  }) : _constraintChecker = constraintChecker ?? const ConstraintChecker();

  @override
  String get name => 'least_disruption';

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

    // Check if this event was previously scheduled
    final previousScheduledTime = _findPreviousScheduledTime(event.id);

    if (previousScheduledTime != null) {
      // Check if the previous time still satisfies constraints
      final sameTimeSlots = _getSlotsForTime(previousScheduledTime, slotsNeeded);
      
      if (grid.areSlotsAvailable(sameTimeSlots)) {
        // Check constraint compliance
        if (isLockedConstraint) {
          if (_constraintChecker.satisfiesLockedConstraints(event, sameTimeSlots)) {
            return sameTimeSlots;
          }
        } else {
          return sameTimeSlots;
        }
      }

      // Try to find the nearest available slots to the previous time
      final nearestSlots = _findNearestAvailableSlots(
        previousScheduledTime,
        grid,
        event,
        slotsNeeded,
        isLockedConstraint,
      );
      if (nearestSlots != null) {
        return nearestSlots;
      }
    }

    // No previous schedule reference - use balanced approach within work hours
    // Find least busy day (respecting day constraints)
    final targetDay = _findLeastBusyDay(grid, event);
    final slotsInDay = _findSlotsInDay(targetDay, grid, event, slotsNeeded, isLockedConstraint);
    if (slotsInDay != null) {
      return slotsInDay;
    }

    // Fallback: find any available slots
    return _findFallbackSlots(grid, event, duration, isLockedConstraint);
  }

  /// Find when this event was previously scheduled (if at all)
  DateTime? _findPreviousScheduledTime(String eventId) {
    for (final scheduled in existingSchedule) {
      if (scheduled.event.id == eventId) {
        return scheduled.scheduledStart;
      }
    }
    return null;
  }

  /// Get time slots starting at a specific time
  List<TimeSlot> _getSlotsForTime(DateTime startTime, int slotsNeeded) {
    final slots = <TimeSlot>[];
    var current = TimeSlot(TimeSlot.roundDown(startTime));

    for (var i = 0; i < slotsNeeded; i++) {
      slots.add(current);
      current = current.next;
    }

    return slots;
  }

  /// Find the nearest available slots to a target time, respecting constraints
  List<TimeSlot>? _findNearestAvailableSlots(
    DateTime targetTime,
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
    bool isLockedConstraint,
  ) {
    var forwardSlot = TimeSlot(TimeSlot.roundDown(targetTime));
    var backwardSlot = forwardSlot.previous;

    int forwardDistance = 0;
    int backwardDistance = 0;

    while (forwardDistance < maxSearchSlots || backwardDistance < maxSearchSlots) {
      // Try forward
      if (forwardDistance < maxSearchSlots) {
        final forwardSlots = _tryPlacementAt(forwardSlot, grid, event, slotsNeeded, isLockedConstraint);
        if (forwardSlots != null) {
          return forwardSlots;
        }
        forwardSlot = forwardSlot.next;
        forwardDistance++;
      }

      // Try backward
      if (backwardDistance < maxSearchSlots && 
          backwardSlot.start.isAfter(grid.windowStart)) {
        final backwardSlots = _tryPlacementAt(backwardSlot, grid, event, slotsNeeded, isLockedConstraint);
        if (backwardSlots != null) {
          return backwardSlots;
        }
        backwardSlot = backwardSlot.previous;
        backwardDistance++;
      }

      // If we've exhausted backward search, just search forward
      if (backwardSlot.start.isBefore(grid.windowStart)) {
        backwardDistance = maxSearchSlots; // Stop backward search
      }
    }

    return null;
  }

  /// Try to place event at a specific slot and return the slots if successful
  List<TimeSlot>? _tryPlacementAt(
    TimeSlot startSlot,
    AvailabilityGrid grid,
    Event event,
    int slotsNeeded,
    bool isLockedConstraint,
  ) {
    // Check if slot is within window
    if (startSlot.start.isBefore(grid.windowStart) ||
        startSlot.start.isAfter(grid.windowEnd)) {
      return null;
    }

    final slots = <TimeSlot>[];
    var current = startSlot;

    for (var i = 0; i < slotsNeeded; i++) {
      if (!grid.isAvailable(current)) {
        return null;
      }
      if (current.end.isAfter(grid.windowEnd)) {
        return null;
      }
      slots.add(current);
      current = current.next;
    }

    // Check constraint compliance for locked constraints
    if (isLockedConstraint) {
      if (!_constraintChecker.satisfiesLockedConstraints(event, slots)) {
        return null;
      }
    }

    return slots;
  }

  /// Find the day with the fewest scheduled events, respecting day constraints
  DateTime _findLeastBusyDay(AvailabilityGrid grid, Event event) {
    var leastBusy = grid.windowStart;
    var minScore = double.infinity;

    final constraint = event.schedulingConstraint;
    final isLockedDayConstraint = constraint?.dayConstraintStrength == SchedulingPreferenceStrength.locked;

    var current = DateTime(
      grid.windowStart.year,
      grid.windowStart.month,
      grid.windowStart.day,
    );
    final windowEndDay = DateTime(
      grid.windowEnd.year,
      grid.windowEnd.month,
      grid.windowEnd.day,
    );

    while (!current.isAfter(windowEndDay)) {
      // Check day constraint if present and locked
      if (constraint?.hasDayConstraints == true) {
        final dayOfWeek = current.weekday == 7 ? 0 : current.weekday;
        if (!constraint!.preferredDays!.contains(dayOfWeek)) {
          if (isLockedDayConstraint) {
            current = current.add(const Duration(days: 1));
            continue;
          }
        }
      }

      final eventCount = grid.getEventCountForDay(current);

      // Add day constraint penalty if applicable
      var dayPenalty = 0.0;
      if (constraint?.hasDayConstraints == true) {
        final dayOfWeek = current.weekday == 7 ? 0 : current.weekday;
        if (!constraint!.preferredDays!.contains(dayOfWeek)) {
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

  /// Find available slots within a specific day's work hours, respecting constraints
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

    return null;
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
