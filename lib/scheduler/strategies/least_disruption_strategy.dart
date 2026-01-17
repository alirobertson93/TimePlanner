import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/goal.dart';
import '../models/availability_grid.dart';
import '../models/time_slot.dart';
import '../models/scheduled_event.dart';
import 'scheduling_strategy.dart';

/// Strategy that minimizes changes to an existing schedule.
///
/// This strategy is used when rescheduling events. It attempts to place
/// events as close as possible to their previously scheduled times,
/// reducing disruption to the user's existing plans.
class LeastDisruptionStrategy implements SchedulingStrategy {
  /// Creates a LeastDisruptionStrategy with the existing schedule for reference.
  ///
  /// [existingSchedule] contains previously scheduled events that serve as
  /// reference points for minimizing disruption.
  LeastDisruptionStrategy([this.existingSchedule = const []]);

  /// The existing schedule to minimize disruption from
  final List<ScheduledEvent> existingSchedule;

  // TODO: Make work hours configurable per user
  static const int defaultWorkStartHour = 9;
  static const int defaultWorkEndHour = 17;

  @override
  String get name => 'least-disruption';

  @override
  List<TimeSlot>? findSlots(
    Event event,
    AvailabilityGrid grid,
    List<Goal> goals,
  ) {
    final duration = event.effectiveDuration;
    final slotsNeeded = TimeSlot.durationToSlots(duration);

    // Try to find the previous scheduled time for this event
    final previouslyScheduled = _findPreviousScheduledTime(event);

    if (previouslyScheduled != null) {
      // Try to place at the exact same time if available
      final sameSlotsResult = _tryPlaceAt(
        previouslyScheduled.scheduledStart,
        slotsNeeded,
        grid,
      );
      if (sameSlotsResult != null) {
        return sameSlotsResult;
      }

      // Try to find the nearest available time to the previous schedule
      final nearestSlots = _findNearestAvailableSlots(
        previouslyScheduled.scheduledStart,
        slotsNeeded,
        grid,
      );
      if (nearestSlots != null) {
        return nearestSlots;
      }
    }

    // No previous schedule or couldn't find nearby slots
    // Fall back to finding any available slots
    return grid.findAvailableSlots(duration);
  }

  /// Find the previously scheduled time for an event.
  ScheduledEvent? _findPreviousScheduledTime(Event event) {
    for (final scheduled in existingSchedule) {
      if (scheduled.event.id == event.id) {
        return scheduled;
      }
    }
    return null;
  }

  /// Try to place event at a specific start time.
  List<TimeSlot>? _tryPlaceAt(
    DateTime startTime,
    int slotsNeeded,
    AvailabilityGrid grid,
  ) {
    final slots = <TimeSlot>[];
    var current = TimeSlot(TimeSlot.roundDown(startTime));

    for (var i = 0; i < slotsNeeded; i++) {
      if (!grid.isAvailable(current)) {
        return null; // Can't place here
      }
      slots.add(current);
      current = current.next;
    }

    return slots;
  }

  /// Find the nearest available slots to a reference time.
  ///
  /// Searches both forward and backward from the reference time,
  /// returning whichever available slot is closer.
  List<TimeSlot>? _findNearestAvailableSlots(
    DateTime referenceTime,
    int slotsNeeded,
    AvailabilityGrid grid,
  ) {
    final referenceSlot = TimeSlot(TimeSlot.roundDown(referenceTime));
    final referenceDay = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );

    // Search in expanding circles from the reference time
    // First try same day, then adjacent days

    // Try same day first
    final sameDayResult = _searchDayForNearestSlots(
      referenceSlot,
      referenceDay,
      slotsNeeded,
      grid,
    );
    if (sameDayResult != null) {
      return sameDayResult;
    }

    // Try adjacent days
    for (var dayOffset = 1; dayOffset <= 7; dayOffset++) {
      // Try day before
      final dayBefore = referenceDay.subtract(Duration(days: dayOffset));
      if (dayBefore.isAfter(grid.windowStart) ||
          dayBefore.isAtSameMomentAs(grid.windowStart)) {
        final dayBeforeStart = DateTime(
          dayBefore.year,
          dayBefore.month,
          dayBefore.day,
          referenceTime.hour,
          referenceTime.minute,
        );
        final dayBeforeSlot = TimeSlot(TimeSlot.roundDown(dayBeforeStart));
        final beforeResult = _searchDayForNearestSlots(
          dayBeforeSlot,
          dayBefore,
          slotsNeeded,
          grid,
        );
        if (beforeResult != null) {
          return beforeResult;
        }
      }

      // Try day after
      final dayAfter = referenceDay.add(Duration(days: dayOffset));
      if (dayAfter.isBefore(grid.windowEnd)) {
        final dayAfterStart = DateTime(
          dayAfter.year,
          dayAfter.month,
          dayAfter.day,
          referenceTime.hour,
          referenceTime.minute,
        );
        final dayAfterSlot = TimeSlot(TimeSlot.roundDown(dayAfterStart));
        final afterResult = _searchDayForNearestSlots(
          dayAfterSlot,
          dayAfter,
          slotsNeeded,
          grid,
        );
        if (afterResult != null) {
          return afterResult;
        }
      }
    }

    return null;
  }

  /// Search a specific day for the nearest available slots to a reference slot.
  List<TimeSlot>? _searchDayForNearestSlots(
    TimeSlot referenceSlot,
    DateTime day,
    int slotsNeeded,
    AvailabilityGrid grid,
  ) {
    final dayStart = DateTime(
      day.year,
      day.month,
      day.day,
      defaultWorkStartHour,
      0,
    );
    final dayEnd = DateTime(
      day.year,
      day.month,
      day.day,
      defaultWorkEndHour,
      0,
    );

    // Search forward and backward from reference, taking the closer result
    List<TimeSlot>? forwardResult;
    List<TimeSlot>? backwardResult;
    int forwardDistance = 0;
    int backwardDistance = 0;

    // Small tolerance buffer for time boundary comparisons
    const toleranceBuffer = Duration(minutes: 1);

    // Search forward
    var forward = referenceSlot;
    while (forward.start.isBefore(dayEnd)) {
      final result = _tryPlaceAt(forward.start, slotsNeeded, grid);
      if (result != null && result.last.end.isBefore(dayEnd.add(toleranceBuffer))) {
        forwardResult = result;
        break;
      }
      forward = forward.next;
      forwardDistance++;
    }

    // Search backward
    var backward = referenceSlot.previous;
    while (backward.start.isAfter(dayStart) ||
        backward.start.isAtSameMomentAs(dayStart)) {
      final result = _tryPlaceAt(backward.start, slotsNeeded, grid);
      if (result != null && result.first.start.isAfter(dayStart.subtract(toleranceBuffer))) {
        backwardResult = result;
        break;
      }
      backward = backward.previous;
      backwardDistance++;
    }

    // Return the closer result
    if (forwardResult != null && backwardResult != null) {
      return forwardDistance <= backwardDistance
          ? forwardResult
          : backwardResult;
    }
    return forwardResult ?? backwardResult;
  }
}
