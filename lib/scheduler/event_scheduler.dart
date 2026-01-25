import 'package:time_planner/domain/entities/event.dart';
import 'models/schedule_request.dart';
import 'models/schedule_result.dart';
import 'models/availability_grid.dart';
import 'models/conflict.dart';
import 'models/constraint_violation.dart';
import 'models/time_slot.dart';
import 'services/constraint_checker.dart';

/// Main event scheduler that places events in time slots
class EventScheduler {
  final ConstraintChecker _constraintChecker;

  EventScheduler({ConstraintChecker? constraintChecker})
      : _constraintChecker = constraintChecker ?? const ConstraintChecker();

  /// Schedule events according to the request
  ScheduleResult schedule(ScheduleRequest request) {
    final stopwatch = Stopwatch()..start();

    // Initialize availability grid
    final grid = AvailabilityGrid(request.windowStart, request.windowEnd);

    // Track conflicts, unscheduled events, and constraint violations
    final conflicts = <Conflict>[];
    final unscheduledEvents = <Event>[];
    final constraintViolations = <ConstraintViolation>[];

    // Pass 1: Place fixed events
    _placeFixedEvents(request.fixedEvents, grid, conflicts, constraintViolations);

    // Pass 2: Place flexible events using strategy
    _placeFlexibleEvents(
      request.flexibleEvents,
      grid,
      request.strategy,
      request.goals,
      unscheduledEvents,
      constraintViolations,
    );

    stopwatch.stop();

    return ScheduleResult(
      success: conflicts.isEmpty && unscheduledEvents.isEmpty,
      scheduledEvents: grid.scheduledEvents,
      unscheduledEvents: unscheduledEvents,
      conflicts: conflicts,
      constraintViolations: constraintViolations,
      computationTime: stopwatch.elapsed,
      strategyUsed: request.strategy.name,
    );
  }

  /// Place fixed events and detect conflicts
  void _placeFixedEvents(
    List<Event> fixedEvents,
    AvailabilityGrid grid,
    List<Conflict> conflicts,
    List<ConstraintViolation> constraintViolations,
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

      // Check for constraint violations (for fixed events, we report but don't prevent)
      final violations = _constraintChecker.checkConstraints(event, slots);
      for (final violation in violations) {
        // Only add non-locked violations as warnings (locked violations for fixed events are user errors)
        if (!violation.isHardViolation) {
          constraintViolations.add(violation);
        } else {
          // For locked constraint violations on fixed events, add as a conflict
          conflicts.add(Conflict(
            eventId1: event.id,
            eventId2: event.id,
            type: ConflictType.constraintViolation,
            description: '${event.name}: ${violation.description}',
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
    List<ConstraintViolation> constraintViolations,
  ) {
    for (final event in flexibleEvents) {
      final slots = strategy.findSlots(event, grid, goals);

      if (slots == null || slots.isEmpty) {
        unscheduledEvents.add(event);
        
        // Add a constraint violation if the event had constraints
        // This helps explain why it couldn't be scheduled
        if (event.hasSchedulingConstraints) {
          constraintViolations.add(ConstraintViolation(
            eventId: event.id,
            eventName: event.name,
            violationType: ConstraintViolationType.noValidSlots,
            description: 'No available slots that satisfy the time constraints',
            strength: event.schedulingConstraint!.timeConstraintStrength,
          ));
        }
        continue;
      }

      // Check for constraint violations on the scheduled slots
      final violations = _constraintChecker.checkConstraints(event, slots);
      for (final violation in violations) {
        if (!violation.isHardViolation) {
          // Add soft violations as warnings
          constraintViolations.add(violation);
        }
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
