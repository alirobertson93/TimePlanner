import 'package:time_planner/domain/entities/event.dart';
import 'models/schedule_request.dart';
import 'models/schedule_result.dart';
import 'models/availability_grid.dart';
import 'models/conflict.dart';
import 'models/time_slot.dart';

/// Main event scheduler that places events in time slots
class EventScheduler {
  /// Schedule events according to the request
  ScheduleResult schedule(ScheduleRequest request) {
    final stopwatch = Stopwatch()..start();

    // Initialize availability grid
    final grid = AvailabilityGrid(request.windowStart, request.windowEnd);

    // Track conflicts and unscheduled events
    final conflicts = <Conflict>[];
    final unscheduledEvents = <Event>[];

    // Pass 1: Place fixed events
    _placeFixedEvents(request.fixedEvents, grid, conflicts);

    // Pass 2: Place flexible events using strategy
    _placeFlexibleEvents(
      request.flexibleEvents,
      grid,
      request.strategy,
      request.goals,
      unscheduledEvents,
    );

    stopwatch.stop();

    return ScheduleResult(
      success: conflicts.isEmpty && unscheduledEvents.isEmpty,
      scheduledEvents: grid.scheduledEvents,
      unscheduledEvents: unscheduledEvents,
      conflicts: conflicts,
      computationTime: stopwatch.elapsed,
      strategyUsed: request.strategy.name,
    );
  }

  /// Place fixed events and detect conflicts
  void _placeFixedEvents(
    List<Event> fixedEvents,
    AvailabilityGrid grid,
    List<Conflict> conflicts,
  ) {
    for (final event in fixedEvents) {
      if (!event.isFixed || event.startTime == null || event.endTime == null) {
        continue;
      }

      // Get slots for this fixed event
      final slots = _getSlotsForTimeRange(event.startTime!, event.endTime!);

      // Check for conflicts
      for (final slot in slots) {
        final existingEvent = grid.getEventAt(slot);
        if (existingEvent != null) {
          conflicts.add(Conflict(
            eventId1: existingEvent.id,
            eventId2: event.id,
            type: ConflictType.overlap,
            description:
                'Fixed events "${existingEvent.name}" and "${event.name}" overlap',
          ));
        }
      }

      // Place the event regardless (fixed events have priority)
      grid.occupy(slots, event, event.startTime!);
    }
  }

  /// Place flexible events using the provided strategy
  void _placeFlexibleEvents(
    List<Event> flexibleEvents,
    AvailabilityGrid grid,
    dynamic strategy,
    List<dynamic> goals,
    List<Event> unscheduledEvents,
  ) {
    for (final event in flexibleEvents) {
      final slots = strategy.findSlots(event, grid, goals);

      if (slots == null || slots.isEmpty) {
        unscheduledEvents.add(event);
        continue;
      }

      // Place the event
      grid.occupy(slots, event, slots.first.start);
    }
  }

  /// Get time slots for a time range
  List<TimeSlot> _getSlotsForTimeRange(DateTime start, DateTime end) {
    final slots = <TimeSlot>[];
    var current = TimeSlot(TimeSlot.roundDown(start));
    final endSlot = TimeSlot.roundUp(end);

    while (current.start.isBefore(endSlot)) {
      slots.add(current);
      current = current.next;
    }

    return slots;
  }
}
