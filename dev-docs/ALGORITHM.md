# Scheduling Algorithm Specification

Complete specification for the TimePlanner scheduling engine.

## Overview

The scheduling engine is the core intelligence of TimePlanner. It takes a set of events (fixed and flexible) along with constraints and generates an optimal schedule.

**Status**: 🟢 Implemented (All 4 strategies complete)

## Architectural Context

### Pure Dart Implementation

The scheduler is implemented as **pure Dart code with zero Flutter dependencies**. This design enables:

- Unit testing without Flutter test harness
- Performance profiling with standard Dart tools
- Potential reuse in backend services
- Clear separation of concerns

### Location in Codebase

```
lib/scheduler/
├── event_scheduler.dart        # Main scheduling engine
├── models/
│   ├── schedule_request.dart   # Input model
│   ├── schedule_result.dart    # Output model
│   ├── time_slot.dart          # 15-minute time unit
│   └── conflict.dart           # Conflict representation
├── strategies/
│   ├── scheduling_strategy.dart     # Strategy interface
│   ├── balanced_strategy.dart       # Balanced strategy (✅ implemented)
│   ├── front_loaded_strategy.dart   # Front-loaded strategy (✅ implemented)
│   ├── max_free_time_strategy.dart  # Max free time strategy (✅ implemented)
│   └── least_disruption_strategy.dart # Least disruption strategy (✅ implemented)
├── validators/
│   ├── constraint_validator.dart
│   └── conflict_detector.dart
└── utils/
    ├── time_utils.dart
    └── goal_calculator.dart
```

**Note**: All 4 scheduling strategies are now fully implemented and available in the Planning Wizard.

---

## Input/Output Contracts

### ScheduleRequest

```dart
class ScheduleRequest {
  /// Events to schedule (mix of fixed and flexible)
  final List<Event> events;
  
  /// Time window for scheduling
  final DateTime windowStart;
  final DateTime windowEnd;
  
  /// User's working hours (for flexible event placement)
  final TimeOfDay workDayStart;
  final TimeOfDay workDayEnd;
  
  /// Goals to optimize for
  final List<Goal> goals;
  
  /// Strategy to use
  final SchedulingStrategy strategy;
  
  /// Travel time considerations
  final Map<String, Location> locations;
  final Map<(String, String), Duration> travelTimes;
  
  /// Constraints
  final List<EventConstraint> constraints;
  
  ScheduleRequest({
    required this.events,
    required this.windowStart,
    required this.windowEnd,
    required this.strategy,
    this.workDayStart = const TimeOfDay(hour: 9, minute: 0),
    this.workDayEnd = const TimeOfDay(hour: 17, minute: 0),
    this.goals = const [],
    this.locations = const {},
    this.travelTimes = const {},
    this.constraints = const [],
  });
}
```

### ScheduleResult

```dart
class ScheduleResult {
  /// Whether scheduling succeeded
  final bool success;
  
  /// Scheduled events with assigned times
  final List<ScheduledEvent> scheduledEvents;
  
  /// Events that couldn't be scheduled
  final List<Event> unscheduledEvents;
  
  /// Conflicts detected
  final List<Conflict> conflicts;
  
  /// Goal progress summary
  final Map<String, GoalProgress> goalProgress;
  
  /// Metadata
  final Duration computationTime;
  final String strategyUsed;
  final int iterationCount;
  
  /// Warnings and suggestions
  final List<String> warnings;
  
  ScheduleResult({
    required this.success,
    required this.scheduledEvents,
    required this.unscheduledEvents,
    required this.conflicts,
    required this.goalProgress,
    required this.computationTime,
    required this.strategyUsed,
    this.iterationCount = 0,
    this.warnings = const [],
  });
}
```

### ScheduledEvent

```dart
class ScheduledEvent {
  final Event event;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final Location? location;
  
  /// Confidence score (0.0 - 1.0)
  /// How well this placement satisfies constraints
  final double confidenceScore;
  
  ScheduledEvent({
    required this.event,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.location,
    this.confidenceScore = 1.0,
  });
}
```

---

## Time Representation

### Time Slots

The scheduler operates on **15-minute time slots** as the atomic unit:

```dart
class TimeSlot {
  final DateTime start;
  
  TimeSlot(this.start);
  
  /// Get end time of this slot (start + 15 minutes)
  DateTime get end => start.add(Duration(minutes: 15));
  
  /// Get next time slot
  TimeSlot get next => TimeSlot(end);
  
  /// Convert duration to slot count
  static int durationToSlots(Duration duration) {
    return (duration.inMinutes / 15).ceil();
  }
}
```

**Why 15 minutes?**
- Common calendar increment
- Balances granularity vs performance (96 slots per day)
- Aligns with typical event durations (30min, 45min, 1hr, etc.)

### Time Windows

```dart
class TimeWindow {
  final DateTime start;
  final DateTime end;
  
  TimeWindow(this.start, this.end);
  
  /// Get all time slots in this window
  List<TimeSlot> getSlots() {
    final slots = <TimeSlot>[];
    var current = TimeSlot(_roundDown(start));
    final windowEnd = _roundUp(end);
    
    while (current.start.isBefore(windowEnd)) {
      slots.add(current);
      current = current.next;
    }
    
    return slots;
  }
  
  /// Round down to nearest 15-minute mark
  DateTime _roundDown(DateTime dt) {
    final minutes = (dt.minute ~/ 15) * 15;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, minutes);
  }
  
  /// Round up to nearest 15-minute mark
  DateTime _roundUp(DateTime dt) {
    if (dt.minute % 15 == 0) return dt;
    final minutes = ((dt.minute ~/ 15) + 1) * 15;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, minutes % 60)
      .add(Duration(hours: minutes ~/ 60));
  }
}
```

---

## Event Classification

Events are classified for scheduling:

### 1. Fixed Events

- Have explicit `startTime` and `endTime`
- Cannot be moved (`isMovable = false` or `timingType = fixed`)
- Scheduled first, occupy time slots
- Block slots for flexible events

### 2. Flexible Events

- Have `durationMinutes` but no fixed time
- Can be placed anywhere in available slots
- Subject to constraints and optimization

### 3. Locked Events

- Already scheduled but cannot be changed
- Treated like fixed events during scheduling

### 4. Priority Levels

Events have implicit priority for scheduling:

```dart
enum EventPriority {
  critical,  // Must be scheduled (deadlines, appointments)
  high,      // Should be scheduled
  medium,    // Nice to schedule
  low        // Filler tasks
}

EventPriority _inferPriority(Event event) {
  // Logic to infer priority from:
  // - Explicit priority field (if added)
  // - Category
  // - Constraints
  // - Goal contribution
}
```

---

## Multi-Pass Scheduling Algorithm

The core algorithm processes events in multiple passes:

### Algorithm Pseudocode

```
function schedule(request: ScheduleRequest): ScheduleResult
  1. Initialize availability grid (all slots available)
  2. Pass 1: Place fixed events
     - Mark their slots as occupied
     - Detect conflicts between fixed events
  3. Pass 2: Place locked flexible events
     - Events previously scheduled and locked
  4. Pass 3: Place high-priority flexible events
     - Sort by priority
     - For each event:
       * Find best available window
       * Place event
       * Mark slots occupied
  5. Pass 4: Place remaining flexible events
     - Apply strategy-specific logic
  6. Pass 5: Optimize placement
     - Try to improve goal satisfaction
     - Minimize fragmentation
  7. Calculate goal progress
  8. Generate warnings
  9. Return result
```

### Detailed Pass Descriptions

#### Pass 1: Fixed Events

```dart
void _placeFixedEvents(
  List<Event> fixedEvents,
  AvailabilityGrid grid,
  List<Conflict> conflicts,
) {
  for (final event in fixedEvents) {
    final window = TimeWindow(event.startTime!, event.endTime!);
    final slots = window.getSlots();
    
    // Check for conflicts
    for (final slot in slots) {
      if (!grid.isAvailable(slot)) {
        conflicts.add(Conflict(
          event1: grid.getEventAt(slot),
          event2: event,
          slot: slot,
          type: ConflictType.overlap,
        ));
      }
    }
    
    // Place regardless (fixed events have priority)
    grid.occupy(slots, event);
  }
}
```

#### Pass 2: High-Priority Flexible Events

```dart
void _placeHighPriorityFlexible(
  List<Event> events,
  AvailabilityGrid grid,
  SchedulingStrategy strategy,
) {
  // Sort by priority
  final sorted = events.sortedBy((e) => _getPriority(e));
  
  for (final event in sorted) {
    final slots = _findBestSlots(event, grid, strategy);
    
    if (slots.isEmpty) {
      unscheduledEvents.add(event);
      continue;
    }
    
    grid.occupy(slots, event);
    scheduledEvents.add(ScheduledEvent(
      event: event,
      scheduledStart: slots.first.start,
      scheduledEnd: slots.last.end,
    ));
  }
}
```

#### Pass 3: Strategy-Specific Placement

Each strategy implements its own logic for remaining events:

```dart
abstract class SchedulingStrategy {
  List<TimeSlot> findSlots(
    Event event,
    AvailabilityGrid grid,
    ScheduleRequest request,
  );
}
```

---

## Strategy Implementations

### 1. Balanced Strategy

**Goal**: Distribute flexible events evenly across the week

**Logic**:
```dart
class BalancedStrategy implements SchedulingStrategy {
  @override
  List<TimeSlot> findSlots(Event event, AvailabilityGrid grid, ScheduleRequest request) {
    // 1. Calculate target distribution
    final targetEventsPerDay = _calculateTargetPerDay(request);
    
    // 2. Find day with fewest scheduled events
    final targetDay = _findLeastBusyDay(grid, request.windowStart, request.windowEnd);
    
    // 3. Find best slots within that day
    return _findBestSlotsInDay(event, targetDay, grid);
  }
  
  DateTime _findLeastBusyDay(AvailabilityGrid grid, DateTime start, DateTime end) {
    var leastBusy = start;
    var minEvents = double.infinity;
    
    for (var day = start; day.isBefore(end); day = day.add(Duration(days: 1))) {
      final eventCount = grid.getEventCountForDay(day);
      if (eventCount < minEvents) {
        minEvents = eventCount;
        leastBusy = day;
      }
    }
    
    return leastBusy;
  }
}
```

### 2. Front-Loaded Strategy

**Goal**: Schedule as early as possible in the week

**Logic**:
```dart
class FrontLoadedStrategy implements SchedulingStrategy {
  @override
  List<TimeSlot> findSlots(Event event, AvailabilityGrid grid, ScheduleRequest request) {
    // Start from beginning of window
    var currentSlot = TimeSlot(request.windowStart);
    final endSlot = TimeSlot(request.windowEnd);
    
    while (currentSlot.start.isBefore(endSlot.start)) {
      // Try to fit event starting at this slot
      if (_canFitAt(event, currentSlot, grid)) {
        return _getSlotsForEvent(event, currentSlot);
      }
      
      currentSlot = currentSlot.next;
    }
    
    return []; // No space found
  }
}
```

### 3. Max Free Time Strategy

**Goal**: Create largest contiguous free blocks

**Logic**:
```dart
class MaxFreeTimeStrategy implements SchedulingStrategy {
  @override
  List<TimeSlot> findSlots(Event event, AvailabilityGrid grid, ScheduleRequest request) {
    // 1. Find all available windows
    final windows = grid.getAvailableWindows(request.windowStart, request.windowEnd);
    
    // 2. For each window, calculate resulting fragmentation if event placed there
    var bestWindow = windows.first;
    var minFragmentation = double.infinity;
    
    for (final window in windows) {
      final fragmentation = _calculateFragmentation(event, window, grid);
      if (fragmentation < minFragmentation) {
        minFragmentation = fragmentation;
        bestWindow = window;
      }
    }
    
    // 3. Place at start of window that minimizes fragmentation
    return _getSlotsForEvent(event, bestWindow.start);
  }
  
  double _calculateFragmentation(Event event, TimeWindow window, AvailabilityGrid grid) {
    // Simulate placing event and measure resulting free block sizes
    // Higher fragmentation = many small blocks
    // Lower fragmentation = few large blocks
  }
}
```

### 4. Least Disruption Strategy

**Goal**: Minimize changes to existing schedule (for rescheduling)

**Logic**:
```dart
class LeastDisruptionStrategy implements SchedulingStrategy {
  final List<ScheduledEvent> existingSchedule;
  
  LeastDisruptionStrategy(this.existingSchedule);
  
  @override
  List<TimeSlot> findSlots(Event event, AvailabilityGrid grid, ScheduleRequest request) {
    // 1. Check if event was previously scheduled
    final previousSlot = _findPreviousScheduledTime(event);
    
    // 2. Try to place at same time if available
    if (previousSlot != null && _canFitAt(event, previousSlot, grid)) {
      return _getSlotsForEvent(event, previousSlot);
    }
    
    // 3. Find nearest available slot to previous time
    return _findNearestAvailableSlot(event, previousSlot ?? TimeSlot(request.windowStart), grid);
  }
}
```

---

## Constraint Validation

### Constraint Types

```dart
abstract class EventConstraint {
  bool isSatisfied(Event event, List<TimeSlot> slots, AvailabilityGrid grid);
  double score(Event event, List<TimeSlot> slots, AvailabilityGrid grid);
}
```

### Time Window Constraint

```dart
class TimeWindowConstraint extends EventConstraint {
  final TimeOfDay preferredStart;
  final TimeOfDay preferredEnd;
  final bool isHard; // true = must satisfy, false = soft preference
  
  @override
  bool isSatisfied(Event event, List<TimeSlot> slots, AvailabilityGrid grid) {
    if (!isHard) return true;
    
    final startTime = TimeOfDay.fromDateTime(slots.first.start);
    return _isWithinWindow(startTime, preferredStart, preferredEnd);
  }
  
  @override
  double score(Event event, List<TimeSlot> slots, AvailabilityGrid grid) {
    // Return 1.0 if within window, 0.0 if outside
    final startTime = TimeOfDay.fromDateTime(slots.first.start);
    return _isWithinWindow(startTime, preferredStart, preferredEnd) ? 1.0 : 0.0;
  }
}
```

### No Back-to-Back Constraint

```dart
class NoBackToBackConstraint extends EventConstraint {
  final Duration bufferTime;
  
  @override
  bool isSatisfied(Event event, List<TimeSlot> slots, AvailabilityGrid grid) {
    // Check if there's an event immediately before or after
    final before = slots.first.previous;
    final after = slots.last.next;
    
    return grid.isAvailable(before) && grid.isAvailable(after);
  }
}
```

---

## Travel Time Handling

When events have locations, the scheduler must account for travel:

```dart
class TravelTimeHandler {
  final Map<(String, String), Duration> travelTimes;
  
  Duration getTravelTime(Location? from, Location? to) {
    if (from == null || to == null) return Duration.zero;
    
    final key = (from.id, to.id);
    return travelTimes[key] ?? _estimateTravelTime(from, to);
  }
  
  Duration _estimateTravelTime(Location from, Location to) {
    // Fallback: estimate based on distance
    // or return default (e.g., 30 minutes)
  }
  
  void insertTravelTime(
    ScheduledEvent from,
    ScheduledEvent to,
    AvailabilityGrid grid,
  ) {
    final travelDuration = getTravelTime(from.location, to.location);
    if (travelDuration == Duration.zero) return;
    
    // Mark slots between events as occupied by travel
    final travelStart = from.scheduledEnd;
    final travelEnd = travelStart.add(travelDuration);
    final travelSlots = TimeWindow(travelStart, travelEnd).getSlots();
    
    grid.occupy(travelSlots, _createTravelEvent(from, to, travelDuration));
  }
}
```

---

## Goal Evaluation

After scheduling, calculate how well goals are met:

```dart
class GoalCalculator {
  Map<String, GoalProgress> calculateProgress(
    List<ScheduledEvent> scheduled,
    List<Goal> goals,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final progress = <String, GoalProgress>{};
    
    for (final goal in goals) {
      final relevantEvents = _filterRelevantEvents(scheduled, goal);
      final actualMinutes = _sumDuration(relevantEvents);
      final targetMinutes = _getTargetMinutes(goal, windowStart, windowEnd);
      
      progress[goal.id] = GoalProgress(
        goalId: goal.id,
        actual: actualMinutes,
        target: targetMinutes,
        percentage: (actualMinutes / targetMinutes * 100).clamp(0, 100),
        status: _determineStatus(actualMinutes, targetMinutes),
      );
    }
    
    return progress;
  }
  
  GoalProgressStatus _determineStatus(int actual, int target) {
    final percentage = actual / target;
    if (percentage >= 1.0) return GoalProgressStatus.exceeded;
    if (percentage >= 0.9) return GoalProgressStatus.onTrack;
    if (percentage >= 0.7) return GoalProgressStatus.atRisk;
    return GoalProgressStatus.behind;
  }
}
```

---

## Plan Variation Generation

> ⚠️ **Planned - Not Implemented**: This feature is designed but not yet implemented in the codebase. The current Planning Wizard allows selecting a single strategy; multi-variation generation is planned for a future release.

Generate multiple schedule variations:

```dart
class PlanGenerator {
  List<ScheduleResult> generateVariations(ScheduleRequest request) {
    final strategies = [
      BalancedStrategy(),
      FrontLoadedStrategy(),
      MaxFreeTimeStrategy(),
    ];
    
    final variations = <ScheduleResult>[];
    
    for (final strategy in strategies) {
      final result = _scheduleWithStrategy(request, strategy);
      variations.add(result);
    }
    
    // Sort by quality score
    variations.sort((a, b) => _scoreResult(b).compareTo(_scoreResult(a)));
    
    return variations.take(3).toList();
  }
  
  double _scoreResult(ScheduleResult result) {
    // Combine factors:
    // - Number of events scheduled (higher is better)
    // - Goal satisfaction (higher is better)
    // - Fragmentation (lower is better)
    // - Constraint violations (lower is better)
    
    final scheduledRatio = result.scheduledEvents.length / 
      (result.scheduledEvents.length + result.unscheduledEvents.length);
    
    final avgGoalProgress = result.goalProgress.values
      .map((g) => g.percentage)
      .average();
    
    final conflictPenalty = result.conflicts.length * 0.1;
    
    return (scheduledRatio * 0.5 + avgGoalProgress * 0.5) - conflictPenalty;
  }
}
```

---

## Rescheduling Operations

### Incremental Rescheduling

When user completes/cancels events, reschedule remaining:

```dart
class Rescheduler {
  ScheduleResult reschedule(
    ScheduleResult currentSchedule,
    List<String> completedEventIds,
    DateTime now,
  ) {
    // 1. Filter out completed events
    final remaining = currentSchedule.scheduledEvents
      .where((e) => !completedEventIds.contains(e.event.id))
      .where((e) => e.scheduledStart.isAfter(now))
      .toList();
    
    // 2. Create new request for remaining events
    final request = ScheduleRequest(
      events: remaining.map((e) => e.event).toList(),
      windowStart: now,
      windowEnd: currentSchedule.windowEnd,
      strategy: LeastDisruptionStrategy(remaining),
    );
    
    // 3. Re-schedule
    return schedule(request);
  }
}
```

### Single Event Rescheduling

When user manually moves an event:

```dart
ScheduleResult rescheduleEvent(
  ScheduleResult currentSchedule,
  String eventId,
  DateTime newStartTime,
) {
  // 1. Validate new time is available
  // 2. Check constraints
  // 3. Detect conflicts
  // 4. Update schedule
}
```

---

## Conflict Resolution

### Conflict Types

```dart
enum ConflictType {
  overlap,           // Two events occupy same time
  violatesConstraint, // Event placement violates constraint
  travelImpossible,  // Not enough travel time between events
  exceedsCapacity    // Too many events in time period
}

class Conflict {
  final Event? event1;
  final Event? event2;
  final TimeSlot slot;
  final ConflictType type;
  final String message;
  
  Conflict({
    this.event1,
    this.event2,
    required this.slot,
    required this.type,
    required this.message,
  });
}
```

### Conflict Resolution Strategies

```dart
class ConflictResolver {
  List<ConflictResolution> proposeResolutions(Conflict conflict) {
    switch (conflict.type) {
      case ConflictType.overlap:
        return [
          MoveEvent(conflict.event1, _findAlternativeSlot(conflict.event1)),
          MoveEvent(conflict.event2, _findAlternativeSlot(conflict.event2)),
          ShortenEvent(conflict.event1, conflict.slot.start),
          ShortenEvent(conflict.event2, conflict.slot.end),
        ];
      
      case ConflictType.violatesConstraint:
        return [
          MoveEvent(conflict.event1, _findConstraintSatisfyingSlot(conflict.event1)),
          RelaxConstraint(conflict.event1, conflict.constraint),
        ];
      
      // ... other cases
    }
  }
}
```

---

## Performance Considerations

### Optimization Techniques

1. **Early Termination**
   - Stop searching after finding "good enough" solution
   - Use time budget (e.g., max 2 seconds)

2. **Caching**
   - Cache constraint evaluations
   - Cache goal calculations
   - Cache travel time lookups

3. **Pruning**
   - Don't try every possible slot
   - Use heuristics to identify promising candidates
   - Skip obviously invalid placements

4. **Incremental Updates**
   - When rescheduling, only re-compute affected parts
   - Reuse previous schedule as starting point

### Performance Targets

| Operation | Target | Max Acceptable |
|-----------|--------|----------------|
| Schedule 7 days, 50 events | < 500ms | 2s |
| Schedule 7 days, 100 events | < 1s | 5s |
| Reschedule single event | < 100ms | 500ms |
| Generate 3 variations | < 2s | 10s |
| Detect conflicts | < 50ms | 200ms |

### Benchmarking

```dart
void benchmarkScheduler() {
  final stopwatch = Stopwatch()..start();
  
  final result = scheduler.schedule(request);
  
  stopwatch.stop();
  
  print('Scheduling took ${stopwatch.elapsedMilliseconds}ms');
  print('Iterations: ${result.iterationCount}');
  print('Events scheduled: ${result.scheduledEvents.length}');
}
```

---

## Testing Strategy

See TESTING.md for full testing strategy. Key test categories:

1. **Unit Tests** for each strategy
2. **Property Tests** (e.g., "no overlaps", "all fixed events placed")
3. **Integration Tests** with real-world scenarios
4. **Performance Tests** with large event sets
5. **Edge Cases** (empty schedule, all conflicts, etc.)

---

*Last updated: 2026-01-17*
