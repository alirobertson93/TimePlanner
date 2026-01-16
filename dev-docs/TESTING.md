# Testing Strategy

Comprehensive testing strategy for TimePlanner.

## Overview

Testing is critical for TimePlanner due to the complexity of the scheduling algorithm and the importance of data integrity. This document defines our testing approach across all layers.

**Last Updated**: 2026-01-16

---

## Test Distribution Goals

Target test coverage by layer:

| Layer | Unit Tests | Integration Tests | Widget Tests | Goal Coverage |
|-------|-----------|-------------------|--------------|---------------|
| Scheduler | 80%+ | 20+ scenarios | N/A | 90%+ |
| Domain | 70%+ | N/A | N/A | 80%+ |
| Data | 60%+ | 40% | N/A | 75%+ |
| Presentation | 40%+ | 20% | 60%+ | 70%+ |

**Rationale:**
- Scheduler is business-critical → highest test coverage
- Data layer needs integration tests for database operations
- Presentation layer relies more on widget tests than unit tests

---

## Folder Structure

```
test/
├── unit/
│   ├── scheduler/
│   │   ├── strategies/
│   │   │   ├── balanced_strategy_test.dart
│   │   │   ├── front_loaded_strategy_test.dart
│   │   │   └── max_free_time_strategy_test.dart
│   │   ├── validators/
│   │   │   ├── constraint_validator_test.dart
│   │   │   └── conflict_detector_test.dart
│   │   ├── event_scheduler_test.dart
│   │   └── goal_calculator_test.dart
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── event_test.dart
│   │   │   ├── goal_test.dart
│   │   │   └── ...
│   │   └── enums/
│   │       └── ...
│   └── core/
│       └── utils/
│           ├── date_utils_test.dart
│           └── validators_test.dart
│
├── integration/
│   ├── repositories/
│   │   ├── event_repository_test.dart
│   │   ├── category_repository_test.dart
│   │   └── goal_repository_test.dart
│   ├── database/
│   │   ├── migrations_test.dart
│   │   └── constraints_test.dart
│   └── scheduling/
│       ├── end_to_end_scheduling_test.dart
│       └── rescheduling_test.dart
│
├── widget/
│   ├── screens/
│   │   ├── day_view_screen_test.dart
│   │   ├── event_form_screen_test.dart
│   │   └── ...
│   └── widgets/
│       ├── event_card_test.dart
│       ├── time_picker_field_test.dart
│       └── ...
│
└── fixtures/
    ├── events.dart              # Test event data
    ├── categories.dart          # Test category data
    ├── goals.dart              # Test goal data
    └── schedules.dart          # Test schedule scenarios
```

---

## Unit Tests

### Scheduler Unit Tests

**Purpose**: Verify scheduling logic works correctly in isolation

#### Example: Balanced Strategy

```dart
// test/unit/scheduler/strategies/balanced_strategy_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:timeplanner/scheduler/strategies/balanced_strategy.dart';
import 'package:timeplanner/scheduler/models/availability_grid.dart';
import '../../fixtures/events.dart';

void main() {
  group('BalancedStrategy', () {
    late BalancedStrategy strategy;
    late AvailabilityGrid grid;
    
    setUp(() {
      strategy = BalancedStrategy();
      grid = AvailabilityGrid(
        DateTime(2026, 1, 13), // Monday
        DateTime(2026, 1, 19), // Sunday
      );
    });
    
    test('distributes events evenly across week', () {
      // Arrange
      final events = TestFixtures.createFlexibleEvents(count: 14); // 2 per day
      
      // Act
      for (final event in events) {
        final slots = strategy.findSlots(event, grid, mockRequest);
        grid.occupy(slots, event);
      }
      
      // Assert
      final monday = grid.getEventCountForDay(DateTime(2026, 1, 13));
      final tuesday = grid.getEventCountForDay(DateTime(2026, 1, 14));
      final wednesday = grid.getEventCountForDay(DateTime(2026, 1, 15));
      
      expect(monday, equals(2));
      expect(tuesday, equals(2));
      expect(wednesday, equals(2));
      // Distribution should be even (±1 event per day)
    });
    
    test('respects work hours when distributing', () {
      // Arrange
      final request = ScheduleRequest(
        events: TestFixtures.createFlexibleEvents(count: 5),
        windowStart: DateTime(2026, 1, 13),
        windowEnd: DateTime(2026, 1, 19),
        workDayStart: TimeOfDay(hour: 9, minute: 0),
        workDayEnd: TimeOfDay(hour: 17, minute: 0),
        strategy: strategy,
      );
      
      // Act
      final result = EventScheduler().schedule(request);
      
      // Assert
      for (final scheduled in result.scheduledEvents) {
        final hour = scheduled.scheduledStart.hour;
        expect(hour, greaterThanOrEqualTo(9));
        expect(hour, lessThanOrEqualTo(17));
      }
    });
    
    test('fills gaps before creating new days', () {
      // Arrange: Create a week with Monday having only 1 event
      grid.occupy(
        TimeWindow(
          DateTime(2026, 1, 13, 10, 0),
          DateTime(2026, 1, 13, 11, 0),
        ).getSlots(),
        TestFixtures.createFixedEvent(
          start: DateTime(2026, 1, 13, 10, 0),
          end: DateTime(2026, 1, 13, 11, 0),
        ),
      );
      
      final event = TestFixtures.createFlexibleEvent(durationMinutes: 60);
      
      // Act
      final slots = strategy.findSlots(event, grid, mockRequest);
      
      // Assert: Should schedule on Monday (least busy day)
      expect(slots.first.start.day, equals(13));
    });
  });
}
```

#### Example: Event Scheduler

```dart
// test/unit/scheduler/event_scheduler_test.dart
void main() {
  group('EventScheduler', () {
    late EventScheduler scheduler;
    
    setUp(() {
      scheduler = EventScheduler();
    });
    
    test('schedules fixed events at specified times', () {
      // Arrange
      final events = [
        TestFixtures.createFixedEvent(
          start: DateTime(2026, 1, 13, 10, 0),
          end: DateTime(2026, 1, 13, 11, 0),
          title: 'Meeting',
        ),
      ];
      
      final request = ScheduleRequest(
        events: events,
        windowStart: DateTime(2026, 1, 13),
        windowEnd: DateTime(2026, 1, 19),
        strategy: BalancedStrategy(),
      );
      
      // Act
      final result = scheduler.schedule(request);
      
      // Assert
      expect(result.success, isTrue);
      expect(result.scheduledEvents.length, equals(1));
      expect(result.scheduledEvents.first.scheduledStart, 
        equals(DateTime(2026, 1, 13, 10, 0)));
    });
    
    test('detects conflicts between fixed events', () {
      // Arrange
      final events = [
        TestFixtures.createFixedEvent(
          start: DateTime(2026, 1, 13, 10, 0),
          end: DateTime(2026, 1, 13, 11, 0),
          title: 'Meeting 1',
        ),
        TestFixtures.createFixedEvent(
          start: DateTime(2026, 1, 13, 10, 30),
          end: DateTime(2026, 1, 13, 11, 30),
          title: 'Meeting 2', // Overlaps with Meeting 1
        ),
      ];
      
      final request = ScheduleRequest(
        events: events,
        windowStart: DateTime(2026, 1, 13),
        windowEnd: DateTime(2026, 1, 19),
        strategy: BalancedStrategy(),
      );
      
      // Act
      final result = scheduler.schedule(request);
      
      // Assert
      expect(result.conflicts.length, greaterThan(0));
      expect(result.conflicts.first.type, equals(ConflictType.overlap));
    });
    
    test('places flexible events in available slots', () {
      // Arrange
      final fixedEvent = TestFixtures.createFixedEvent(
        start: DateTime(2026, 1, 13, 10, 0),
        end: DateTime(2026, 1, 13, 11, 0),
      );
      
      final flexibleEvent = TestFixtures.createFlexibleEvent(
        durationMinutes: 60,
      );
      
      final request = ScheduleRequest(
        events: [fixedEvent, flexibleEvent],
        windowStart: DateTime(2026, 1, 13),
        windowEnd: DateTime(2026, 1, 19),
        strategy: BalancedStrategy(),
      );
      
      // Act
      final result = scheduler.schedule(request);
      
      // Assert
      expect(result.scheduledEvents.length, equals(2));
      
      final scheduledFlexible = result.scheduledEvents
        .firstWhere((e) => e.event.id == flexibleEvent.id);
      
      // Should not overlap with fixed event
      expect(
        scheduledFlexible.scheduledStart.isAfter(fixedEvent.endTime!) ||
        scheduledFlexible.scheduledEnd.isBefore(fixedEvent.startTime!),
        isTrue,
      );
    });
    
    test('completes within performance target', () {
      // Arrange
      final events = TestFixtures.createMixedEvents(
        fixedCount: 10,
        flexibleCount: 40,
      );
      
      final request = ScheduleRequest(
        events: events,
        windowStart: DateTime(2026, 1, 13),
        windowEnd: DateTime(2026, 1, 19),
        strategy: BalancedStrategy(),
      );
      
      // Act
      final result = scheduler.schedule(request);
      
      // Assert
      expect(result.computationTime.inMilliseconds, lessThan(2000)); // < 2s
    });
  });
}
```

### Goal Calculator Tests

```dart
// test/unit/scheduler/goal_calculator_test.dart
void main() {
  group('GoalCalculator', () {
    late GoalCalculator calculator;
    
    setUp(() {
      calculator = GoalCalculator();
    });
    
    test('calculates hours toward category goal', () {
      // Arrange
      final goal = TestFixtures.createGoal(
        type: GoalType.category,
        categoryId: 'work',
        targetValue: 40, // 40 hours per week
        metric: GoalMetric.hours,
        period: GoalPeriod.week,
      );
      
      final scheduled = [
        TestFixtures.createScheduledEvent(
          categoryId: 'work',
          durationMinutes: 120, // 2 hours
        ),
        TestFixtures.createScheduledEvent(
          categoryId: 'work',
          durationMinutes: 180, // 3 hours
        ),
        TestFixtures.createScheduledEvent(
          categoryId: 'personal',
          durationMinutes: 60, // Should not count
        ),
      ];
      
      // Act
      final progress = calculator.calculateProgress(
        scheduled,
        [goal],
        DateTime(2026, 1, 13),
        DateTime(2026, 1, 19),
      );
      
      // Assert
      expect(progress[goal.id]!.actual, equals(300)); // 5 hours = 300 minutes
      expect(progress[goal.id]!.target, equals(2400)); // 40 hours = 2400 minutes
      expect(progress[goal.id]!.percentage, closeTo(12.5, 0.1));
      expect(progress[goal.id]!.status, equals(GoalProgressStatus.behind));
    });
  });
}
```

---

## Integration Tests

### Repository Integration Tests

**Purpose**: Test database operations end-to-end

```dart
// test/integration/repositories/event_repository_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:timeplanner/data/database/database.dart';
import 'package:timeplanner/data/repositories/event_repository.dart';

void main() {
  group('EventRepository Integration', () {
    late AppDatabase db;
    late EventRepository repository;
    
    setUp(() {
      // Create in-memory database for testing
      db = AppDatabase(NativeDatabase.memory());
      repository = EventRepository(db);
    });
    
    tearDown(() async {
      await db.close();
    });
    
    test('creates and retrieves event', () async {
      // Arrange
      final event = TestFixtures.createEvent();
      
      // Act
      await repository.create(event);
      final retrieved = await repository.getById(event.id);
      
      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(event.id));
      expect(retrieved.title, equals(event.title));
    });
    
    test('updates event', () async {
      // Arrange
      final event = TestFixtures.createEvent(title: 'Original');
      await repository.create(event);
      
      // Act
      final updated = event.copyWith(title: 'Updated');
      await repository.update(updated);
      final retrieved = await repository.getById(event.id);
      
      // Assert
      expect(retrieved!.title, equals('Updated'));
    });
    
    test('deletes event', () async {
      // Arrange
      final event = TestFixtures.createEvent();
      await repository.create(event);
      
      // Act
      await repository.delete(event.id);
      final retrieved = await repository.getById(event.id);
      
      // Assert
      expect(retrieved, isNull);
    });
    
    test('watches events reactively', () async {
      // Arrange
      final event = TestFixtures.createEvent();
      final stream = repository.watchAll();
      
      final emittedValues = <List<Event>>[];
      final subscription = stream.listen(emittedValues.add);
      
      // Act
      await Future.delayed(Duration(milliseconds: 100)); // Initial emit
      await repository.create(event);
      await Future.delayed(Duration(milliseconds: 100)); // After create
      await repository.delete(event.id);
      await Future.delayed(Duration(milliseconds: 100)); // After delete
      
      await subscription.cancel();
      
      // Assert
      expect(emittedValues.length, greaterThanOrEqualTo(3));
      expect(emittedValues[0].length, equals(0)); // Initially empty
      expect(emittedValues[1].length, equals(1)); // After create
      expect(emittedValues[2].length, equals(0)); // After delete
    });
    
    test('queries events by date range', () async {
      // Arrange
      await repository.create(TestFixtures.createFixedEvent(
        start: DateTime(2026, 1, 13, 10, 0),
        end: DateTime(2026, 1, 13, 11, 0),
      ));
      await repository.create(TestFixtures.createFixedEvent(
        start: DateTime(2026, 1, 15, 10, 0),
        end: DateTime(2026, 1, 15, 11, 0),
      ));
      await repository.create(TestFixtures.createFixedEvent(
        start: DateTime(2026, 1, 20, 10, 0), // Outside range
        end: DateTime(2026, 1, 20, 11, 0),
      ));
      
      // Act
      final events = await repository.getForDateRange(
        DateTime(2026, 1, 13),
        DateTime(2026, 1, 19),
      );
      
      // Assert
      expect(events.length, equals(2));
    });
  });
}
```

---

## Widget Tests

### Screen Widget Tests

```dart
// test/widget/screens/day_view_screen_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeplanner/presentation/screens/day_view/day_view_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockEventRepository extends Mock implements EventRepository {}

void main() {
  group('DayViewScreen', () {
    late MockEventRepository mockRepo;
    
    setUp(() {
      mockRepo = MockEventRepository();
    });
    
    testWidgets('displays loading indicator while fetching events', (tester) async {
      // Arrange
      when(() => mockRepo.watchForDateRange(any(), any()))
        .thenAnswer((_) => Stream.value([])); // Will show loading briefly
      
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: DayViewScreen(date: DateTime(2026, 1, 13)),
          ),
        ),
      );
      
      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('displays events for the day', (tester) async {
      // Arrange
      final events = [
        TestFixtures.createEvent(title: 'Event 1'),
        TestFixtures.createEvent(title: 'Event 2'),
      ];
      
      when(() => mockRepo.watchForDateRange(any(), any()))
        .thenAnswer((_) => Stream.value(events));
      
      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: DayViewScreen(date: DateTime(2026, 1, 13)),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Event 1'), findsOneWidget);
      expect(find.text('Event 2'), findsOneWidget);
    });
    
    testWidgets('opens add event dialog on FAB tap', (tester) async {
      // Arrange
      when(() => mockRepo.watchForDateRange(any(), any()))
        .thenAnswer((_) => Stream.value([]));
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            eventRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: DayViewScreen(date: DateTime(2026, 1, 13)),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Act
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(Dialog), findsOneWidget);
    });
  });
}
```

---

## Test Fixtures

### Event Fixtures

```dart
// test/fixtures/events.dart
class TestFixtures {
  static Event createEvent({
    String? id,
    String? title,
    TimingType timingType = TimingType.flexible,
    int? durationMinutes,
    String? categoryId,
  }) {
    return Event(
      id: id ?? const Uuid().v4(),
      title: title ?? 'Test Event',
      timingType: timingType,
      status: EventStatus.pending,
      durationMinutes: durationMinutes ?? 60,
      categoryId: categoryId,
    );
  }
  
  static Event createFixedEvent({
    required DateTime start,
    required DateTime end,
    String? title,
  }) {
    return Event(
      id: const Uuid().v4(),
      title: title ?? 'Fixed Event',
      timingType: TimingType.fixed,
      status: EventStatus.pending,
      startTime: start,
      endTime: end,
    );
  }
  
  static Event createFlexibleEvent({
    int durationMinutes = 60,
    String? title,
  }) {
    return Event(
      id: const Uuid().v4(),
      title: title ?? 'Flexible Event',
      timingType: TimingType.flexible,
      status: EventStatus.pending,
      durationMinutes: durationMinutes,
    );
  }
  
  static List<Event> createMixedEvents({
    int fixedCount = 5,
    int flexibleCount = 10,
  }) {
    final events = <Event>[];
    
    // Add fixed events
    var currentTime = DateTime(2026, 1, 13, 9, 0);
    for (var i = 0; i < fixedCount; i++) {
      events.add(createFixedEvent(
        start: currentTime,
        end: currentTime.add(Duration(hours: 1)),
        title: 'Fixed Event $i',
      ));
      currentTime = currentTime.add(Duration(hours: 2)); // 1 hour gap
    }
    
    // Add flexible events
    for (var i = 0; i < flexibleCount; i++) {
      events.add(createFlexibleEvent(
        durationMinutes: 60,
        title: 'Flexible Event $i',
      ));
    }
    
    return events;
  }
}
```

---

## Running Tests

### Command Line

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/scheduler/event_scheduler_test.dart

# Run tests matching pattern
flutter test --name "schedules fixed events"

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Run tests in watch mode (requires package)
flutter test --watch
```

### VS Code

Add to `.vscode/launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Flutter: Run Tests",
      "type": "dart",
      "request": "launch",
      "program": "test/"
    }
  ]
}
```

---

## CI Integration

### GitHub Actions

```yaml
# .github/workflows/test.yml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Run code generation
        run: flutter pub run build_runner build --delete-conflicting-outputs
      
      - name: Analyze code
        run: flutter analyze
      
      - name: Run tests
        run: flutter test --coverage
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          files: coverage/lcov.info
```

---

## Test-Driven Development Flow

### TDD Workflow

1. **Write failing test**
   ```dart
   test('schedules event in available slot', () {
     final result = scheduler.schedule(request);
     expect(result.success, isTrue);
   });
   ```

2. **Run test** → Should fail
   ```bash
   flutter test --name "schedules event"
   ```

3. **Write minimal code** to make test pass

4. **Run test** → Should pass

5. **Refactor** while keeping test green

6. **Repeat** for next feature

### Example TDD Session

```dart
// Step 1: Write test
test('distributes events evenly', () {
  final strategy = BalancedStrategy();
  final grid = AvailabilityGrid(start, end);
  
  for (final event in events) {
    final slots = strategy.findSlots(event, grid, request);
    grid.occupy(slots, event);
  }
  
  final distribution = grid.getEventCountPerDay();
  expect(distribution.standardDeviation(), lessThan(2.0));
});

// Step 2: Run → Fails (method doesn't exist)

// Step 3: Implement
class BalancedStrategy {
  List<TimeSlot> findSlots(...) {
    // Calculate target per day
    // Find least busy day
    // Place event there
  }
}

// Step 4: Run → Passes

// Step 5: Refactor
// Extract helper methods
// Add comments
// Optimize if needed
```

---

*Last updated: 2026-01-16*
