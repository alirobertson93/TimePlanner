import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/scheduled_event.dart';
import '../models/time_slot.dart';
import 'scheduling_strategy.dart';

/// Strategy that minimizes changes to an existing schedule
/// 
/// This strategy is useful for:
/// - Rescheduling when events are completed or cancelled
/// - Making small adjustments without disrupting the entire week
/// - Preserving user's mental model of their schedule
class LeastDisruptionStrategy implements SchedulingStrategy {
  /// Optional: existing schedule to reference for disruption calculation
  final List<ScheduledEvent> existingSchedule;

  // Default work hours (9 AM to 5 PM)
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  LeastDisruptionStrategy({this.existingSchedule = const []});

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

    // Check if this event was previously scheduled
    final previousScheduledTime = _findPreviousScheduledTime(event.id);

    if (previousScheduledTime != null) {
      // Try to place at the same time if available
      final sameTimeSlots = _getSlotsForTime(previousScheduledTime, slotsNeeded);
      if (grid.areSlotsAvailable(sameTimeSlots)) {
        return sameTimeSlots;
      }

      // Try to find the nearest available slots to the previous time
      final nearestSlots = _findNearestAvailableSlots(
        previousScheduledTime,
        grid,
        slotsNeeded,
      );
      if (nearestSlots != null) {
        return nearestSlots;
      }
    }

    // No previous schedule reference - use balanced approach within work hours
    // Find least busy day and place there
    final targetDay = _findLeastBusyDay(grid);
    final slotsInDay = _findSlotsInDay(targetDay, grid, slotsNeeded);
    if (slotsInDay != null) {
      return slotsInDay;
    }

    // Fallback: find any available slots
    return grid.findAvailableSlots(duration);
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

  /// Find the nearest available slots to a target time
  /// Searches both forward and backward from the target time
  List<TimeSlot>? _findNearestAvailableSlots(
    DateTime targetTime,
    AvailabilityGrid grid,
    int slotsNeeded,
  ) {
    // Search up to 24 hours in either direction
    const maxSearchSlots = 96; // 24 hours worth of 15-minute slots
    
    var forwardSlot = TimeSlot(TimeSlot.roundDown(targetTime));
    var backwardSlot = forwardSlot.previous;

    int forwardDistance = 0;
    int backwardDistance = 0;

    while (forwardDistance < maxSearchSlots || backwardDistance < maxSearchSlots) {
      // Try forward
      if (forwardDistance < maxSearchSlots) {
        final forwardSlots = _tryPlacementAt(forwardSlot, grid, slotsNeeded);
        if (forwardSlots != null) {
          return forwardSlots;
        }
        forwardSlot = forwardSlot.next;
        forwardDistance++;
      }

      // Try backward
      if (backwardDistance < maxSearchSlots && 
          backwardSlot.start.isAfter(grid.windowStart)) {
        final backwardSlots = _tryPlacementAt(backwardSlot, grid, slotsNeeded);
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
    int slotsNeeded,
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

    return slots;
  }

  /// Find the day with the fewest scheduled events
  DateTime _findLeastBusyDay(AvailabilityGrid grid) {
    var leastBusy = grid.windowStart;
    var minEvents = double.infinity;

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
      final eventCount = grid.getEventCountForDay(current);
      if (eventCount < minEvents) {
        minEvents = eventCount.toDouble();
        leastBusy = current;
      }
      current = current.add(const Duration(days: 1));
    }

    return leastBusy;
  }

  /// Find available slots within a specific day's work hours
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

    return null;
  }
}
