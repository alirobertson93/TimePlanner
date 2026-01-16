import 'package:time_planner/domain/entities/event.dart';
import 'time_slot.dart';
import 'scheduled_event.dart';

/// Grid tracking availability of time slots
class AvailabilityGrid {
  AvailabilityGrid(this.windowStart, this.windowEnd) {
    _initializeSlots();
  }

  /// Start of the scheduling window
  final DateTime windowStart;

  /// End of the scheduling window
  final DateTime windowEnd;

  /// Map of time slot to occupying event (if any)
  final Map<DateTime, Event?> _slots = {};

  /// Scheduled events
  final List<ScheduledEvent> _scheduledEvents = [];

  /// Initialize all slots in the window as available
  void _initializeSlots() {
    var current = TimeSlot(TimeSlot.roundDown(windowStart));
    final end = TimeSlot.roundUp(windowEnd);

    while (current.start.isBefore(end.start)) {
      _slots[current.start] = null;
      current = current.next;
    }
  }

  /// Check if a time slot is available
  bool isAvailable(TimeSlot slot) {
    return _slots[slot.start] == null;
  }

  /// Check if multiple consecutive slots are available
  bool areSlotsAvailable(List<TimeSlot> slots) {
    return slots.every((slot) => isAvailable(slot));
  }

  /// Occupy time slots with an event
  void occupy(List<TimeSlot> slots, Event event, DateTime scheduledStart) {
    for (final slot in slots) {
      _slots[slot.start] = event;
    }

    // Add to scheduled events
    final scheduledEnd = scheduledStart.add(event.effectiveDuration);
    _scheduledEvents.add(ScheduledEvent(
      event: event,
      scheduledStart: scheduledStart,
      scheduledEnd: scheduledEnd,
    ));
  }

  /// Get the event occupying a specific slot (if any)
  Event? getEventAt(TimeSlot slot) {
    return _slots[slot.start];
  }

  /// Get all scheduled events
  List<ScheduledEvent> get scheduledEvents => List.unmodifiable(_scheduledEvents);

  /// Get all time slots for a specific day
  List<TimeSlot> getSlotsForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final slots = <TimeSlot>[];
    var current = TimeSlot(dayStart);

    while (current.start.isBefore(dayEnd)) {
      if (_slots.containsKey(current.start)) {
        slots.add(current);
      }
      current = current.next;
    }

    return slots;
  }

  /// Get count of events scheduled on a specific day
  int getEventCountForDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _scheduledEvents
        .where((se) =>
            (se.scheduledStart.isAfter(dayStart) || 
             se.scheduledStart.isAtSameMomentAs(dayStart)) &&
            se.scheduledStart.isBefore(dayEnd))
        .length;
  }

  /// Find consecutive available slots of a given duration
  List<TimeSlot>? findAvailableSlots(Duration duration, {DateTime? afterTime}) {
    final slotsNeeded = TimeSlot.durationToSlots(duration);
    final startFrom = afterTime != null
        ? TimeSlot(TimeSlot.roundUp(afterTime))
        : TimeSlot(TimeSlot.roundDown(windowStart));

    var current = startFrom;
    final candidates = <TimeSlot>[];

    while (current.start.isBefore(TimeSlot.roundUp(windowEnd).start)) {
      if (isAvailable(current)) {
        candidates.add(current);

        if (candidates.length == slotsNeeded) {
          return candidates;
        }
      } else {
        candidates.clear();
      }

      current = current.next;
    }

    return null; // No available slots found
  }
}
