# Architecture Specification

Complete architecture and code organization for TimePlanner.

## Overview

TimePlanner follows a **clean architecture** pattern with clear separation of concerns across layers. This document defines the structure, responsibilities, and patterns for each layer.

**Last Updated**: 2026-01-17

---

## Core Principles

### 1. Pure Dart Scheduler

The scheduling engine is pure Dart with **zero Flutter dependencies**:
- ✅ Can be unit tested without Flutter test harness
- ✅ Can be profiled with standard Dart tools  
- ✅ Could be extracted to separate package or backend service
- ✅ Enforces clean separation between business logic and UI

### 2. Repositories as Persistence Boundary

Repositories are the **only** code that touches the database:
- ✅ Abstract away Drift implementation details
- ✅ Convert between database models and domain entities
- ✅ Handle data validation and integrity
- ✅ Enable easy mocking in tests

### 3. Riverpod for Composition

Riverpod providers compose the application:
- ✅ Dependency injection without boilerplate
- ✅ Compile-time safety
- ✅ Easy testing with provider overrides
- ✅ Reactive data flow

### 4. Thin UI Layer

Widgets should be thin and declarative:
- ✅ Minimal business logic in widgets
- ✅ State managed by Riverpod providers
- ✅ Widgets focused on layout and user interaction
- ✅ Easy to test with widget tests

---

## Folder Structure

```
lib/
├── main.dart                          # App entry point
│
├── app/                               # Application configuration
│   ├── app.dart                       # MaterialApp configuration
│   └── router.dart                    # go_router setup and routes
│
├── core/                              # Core utilities (cross-cutting)
│   ├── constants/
│   │   ├── app_constants.dart         # App-wide constants
│   │   └── route_constants.dart       # Route names
│   ├── theme/
│   │   ├── app_theme.dart             # Theme definition
│   │   └── color_schemes.dart         # Color palettes
│   ├── utils/
│   │   ├── date_utils.dart            # Date/time utilities
│   │   ├── validators.dart            # Input validators
│   │   └── extensions.dart            # Dart extensions
│   └── errors/
│       ├── exceptions.dart            # Custom exceptions
│       └── failures.dart              # Error handling types
│
├── domain/                            # Domain layer (pure business logic)
│   ├── entities/                      # Business entities
│   │   ├── event.dart
│   │   ├── category.dart
│   │   ├── goal.dart
│   │   ├── person.dart
│   │   ├── location.dart
│   │   └── ...
│   └── enums/                         # Domain enumerations
│       ├── timing_type.dart
│       ├── event_status.dart
│       ├── goal_type.dart
│       └── ...
│
├── data/                              # Data layer (persistence)
│   ├── database/
│   │   ├── app_database.dart          # Drift database definition
│   │   ├── app_database.g.dart        # Generated code
│   │   ├── tables/                    # Table definitions
│   │   │   ├── events_table.dart
│   │   │   ├── categories_table.dart
│   │   │   └── ...
│   │   └── daos/                      # Data Access Objects
│   │       ├── event_dao.dart
│   │       └── ...
│   └── repositories/                  # Repository implementations
│       ├── event_repository.dart
│       ├── category_repository.dart
│       ├── goal_repository.dart
│       └── ...
│
├── scheduler/                         # Scheduling engine (pure Dart)
│   ├── scheduler.dart                 # Main scheduler interface
│   ├── event_scheduler.dart           # Scheduler implementation
│   ├── models/                        # Scheduler-specific models
│   │   ├── schedule_request.dart
│   │   ├── schedule_result.dart
│   │   ├── scheduled_event.dart
│   │   ├── time_slot.dart
│   │   ├── time_window.dart
│   │   ├── conflict.dart
│   │   └── availability_grid.dart
│   ├── strategies/                    # Scheduling strategies
│   │   ├── strategy.dart              # Strategy interface
│   │   ├── balanced_strategy.dart
│   │   ├── front_loaded_strategy.dart
│   │   ├── max_free_time_strategy.dart
│   │   └── least_disruption_strategy.dart
│   ├── validators/                    # Constraint validation
│   │   ├── constraint_validator.dart
│   │   └── conflict_detector.dart
│   └── utils/                         # Scheduler utilities
│       ├── time_utils.dart
│       ├── goal_calculator.dart
│       └── travel_time_handler.dart
│
└── presentation/                      # Presentation layer (UI)
    ├── providers/                     # Riverpod providers
    │   ├── database_provider.dart     # Database instance
    │   ├── repository_providers.dart  # Repository instances
    │   ├── scheduler_provider.dart    # Scheduler instance
    │   ├── event_providers.dart       # Event-related state
    │   ├── category_providers.dart    # Category state
    │   └── ...
    │
    ├── screens/                       # App screens
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── widgets/
    │   │       ├── event_list.dart
    │   │       └── add_event_fab.dart
    │   ├── day_view/
    │   │   ├── day_view_screen.dart
    │   │   └── widgets/
    │   │       ├── day_timeline.dart
    │   │       ├── event_card.dart
    │   │       └── time_marker.dart
    │   ├── week_view/
    │   │   ├── week_view_screen.dart
    │   │   └── widgets/
    │   ├── event_detail/
    │   │   ├── event_detail_screen.dart
    │   │   └── widgets/
    │   ├── event_form/
    │   │   ├── event_form_screen.dart
    │   │   └── widgets/
    │   ├── planning_wizard/
    │   │   ├── planning_wizard_screen.dart
    │   │   └── steps/
    │   │       ├── date_range_step.dart
    │   │       ├── goals_review_step.dart
    │   │       ├── strategy_selection_step.dart
    │   │       └── plan_review_step.dart
    │   ├── goals/
    │   │   ├── goals_screen.dart
    │   │   └── widgets/
    │   └── settings/
    │       ├── settings_screen.dart
    │       └── widgets/
    │
    └── widgets/                       # Shared widgets
        ├── category_chip.dart
        ├── time_picker_field.dart
        ├── duration_picker.dart
        ├── constraint_picker.dart
        ├── loading_indicator.dart
        ├── error_message.dart
        └── ...
```

---

## Layer Responsibilities

### Core Layer

**Purpose**: Cross-cutting concerns and utilities

**What belongs here:**
- ✅ Constants (colors, sizes, durations)
- ✅ Theme definitions
- ✅ Date/time utilities
- ✅ Extension methods
- ✅ Validators (email, phone, etc.)
- ✅ Custom exceptions
- ✅ Result/Either types for error handling

**What doesn't:**
- ❌ Business logic
- ❌ Database code
- ❌ UI widgets
- ❌ State management

**Example:**
```dart
// lib/core/utils/date_utils.dart
class DateTimeUtils {
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
  
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
  
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
```

---

### Domain Layer

**Purpose**: Pure business entities and logic

**What belongs here:**
- ✅ Entity classes (Event, Category, Goal, etc.)
- ✅ Enums (TimingType, EventStatus, etc.)
- ✅ Value objects (Email, Duration, etc.)
- ✅ Business rules (validation, calculations)
- ✅ Domain exceptions

**What doesn't:**
- ❌ Database models (Drift tables)
- ❌ API models
- ❌ UI models
- ❌ Any framework dependencies

**Dependencies:**
- ✅ Core layer only
- ❌ No other layers

**Example:**
```dart
// lib/domain/entities/event.dart
class Event {
  final String id;
  final String title;
  final String? description;
  final TimingType timingType;
  final EventStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final bool isMovable;
  final bool isResizable;
  final bool isLocked;
  final String? categoryId;
  
  Event({
    required this.id,
    required this.title,
    required this.timingType,
    required this.status,
    this.description,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.isMovable = true,
    this.isResizable = true,
    this.isLocked = false,
    this.categoryId,
  });
  
  // Business logic
  Duration get duration {
    if (timingType == TimingType.fixed) {
      return endTime!.difference(startTime!);
    }
    return Duration(minutes: durationMinutes!);
  }
  
  bool get isFixed => timingType == TimingType.fixed;
  bool get isFlexible => timingType == TimingType.flexible;
  
  // Validation
  bool isValid() {
    if (timingType == TimingType.fixed) {
      return startTime != null && endTime != null && endTime!.isAfter(startTime!);
    } else {
      return durationMinutes != null && durationMinutes! > 0;
    }
  }
}
```

---

### Data Layer

**Purpose**: Data persistence and retrieval

**What belongs here:**
- ✅ Drift database definition
- ✅ Table definitions
- ✅ DAOs (Data Access Objects)
- ✅ Repositories
- ✅ Mappers (database ↔ domain)

**What doesn't:**
- ❌ Business logic (belongs in domain/scheduler)
- ❌ UI code
- ❌ Scheduling logic

**Dependencies:**
- ✅ Domain layer (entities, enums)
- ✅ Core layer (utilities)
- ❌ No scheduler or presentation

**Repository Pattern:**
```dart
// lib/data/repositories/event_repository.dart
class EventRepository {
  final AppDatabase _db;
  
  EventRepository(this._db);
  
  // Query methods
  Future<List<Event>> getAll() async {
    final results = await _db.select(_db.events).get();
    return results.map(_toEntity).toList();
  }
  
  Future<Event?> getById(String id) async {
    final result = await (_db.select(_db.events)
      ..where((e) => e.id.equals(id))).getSingleOrNull();
    return result != null ? _toEntity(result) : null;
  }
  
  Stream<List<Event>> watchForDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.events)
      ..where((e) => 
        e.startTime.isBiggerOrEqualValue(start) &
        e.startTime.isSmallerThanValue(end)))
      .watch()
      .map((rows) => rows.map(_toEntity).toList());
  }
  
  // Mutation methods
  Future<void> create(Event event) async {
    await _db.into(_db.events).insert(_toCompanion(event));
  }
  
  Future<void> update(Event event) async {
    await (_db.update(_db.events)..where((e) => e.id.equals(event.id)))
      .write(_toCompanion(event));
  }
  
  Future<void> delete(String id) async {
    await (_db.delete(_db.events)..where((e) => e.id.equals(id))).go();
  }
  
  // Mappers
  Event _toEntity(EventData data) {
    return Event(
      id: data.id,
      title: data.title,
      description: data.description,
      timingType: TimingType.values[data.timingType],
      status: EventStatus.values[data.status],
      startTime: data.startTime,
      endTime: data.endTime,
      durationMinutes: data.durationMinutes,
      isMovable: data.isMovable,
      isResizable: data.isResizable,
      isLocked: data.isLocked,
      categoryId: data.categoryId,
    );
  }
  
  EventsCompanion _toCompanion(Event entity) {
    return EventsCompanion.insert(
      id: entity.id,
      title: entity.title,
      description: Value(entity.description),
      timingType: entity.timingType.index,
      status: entity.status.index,
      startTime: Value(entity.startTime),
      endTime: Value(entity.endTime),
      durationMinutes: Value(entity.durationMinutes),
      isMovable: entity.isMovable,
      isResizable: entity.isResizable,
      isLocked: entity.isLocked,
      categoryId: Value(entity.categoryId),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
```

---

### Scheduler Layer

**Purpose**: Scheduling algorithm and logic

**What belongs here:**
- ✅ Scheduling strategies
- ✅ Constraint validation
- ✅ Conflict detection
- ✅ Goal calculation
- ✅ Travel time handling

**What doesn't:**
- ❌ Database access (use repositories via dependency injection)
- ❌ UI code
- ❌ Flutter dependencies

**Dependencies:**
- ✅ Domain layer
- ✅ Core layer
- ❌ No data layer (receives data via parameters)
- ❌ No presentation layer

**Example:**
```dart
// lib/scheduler/event_scheduler.dart
class EventScheduler {
  // Pure function - no dependencies on database or UI
  ScheduleResult schedule(ScheduleRequest request) {
    final stopwatch = Stopwatch()..start();
    
    // Initialize availability grid
    final grid = AvailabilityGrid(request.windowStart, request.windowEnd);
    
    // Multi-pass scheduling
    final conflicts = <Conflict>[];
    _placeFixedEvents(request.fixedEvents, grid, conflicts);
    _placeFlexibleEvents(request.flexibleEvents, grid, request.strategy);
    
    // Calculate goal progress
    final goalProgress = _calculateGoalProgress(
      grid.scheduledEvents,
      request.goals,
      request.windowStart,
      request.windowEnd,
    );
    
    stopwatch.stop();
    
    return ScheduleResult(
      success: conflicts.isEmpty,
      scheduledEvents: grid.scheduledEvents,
      unscheduledEvents: grid.unscheduledEvents,
      conflicts: conflicts,
      goalProgress: goalProgress,
      computationTime: stopwatch.elapsed,
      strategyUsed: request.strategy.name,
    );
  }
}
```

---

### Presentation Layer

**Purpose**: UI and user interaction

**What belongs here:**
- ✅ Screens and widgets
- ✅ Riverpod providers
- ✅ UI state management
- ✅ Navigation
- ✅ Input handling

**What doesn't:**
- ❌ Business logic (delegate to domain/scheduler)
- ❌ Database queries (use repositories via providers)
- ❌ Complex calculations (use domain entities)

**Dependencies:**
- ✅ All other layers (via providers)

**Screen Structure:**
```dart
// lib/presentation/screens/day_view/day_view_screen.dart
class DayViewScreen extends ConsumerWidget {
  final DateTime date;
  
  const DayViewScreen({required this.date});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch events for this date
    final eventsAsync = ref.watch(eventsForDateProvider(date));
    
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMMd().format(date)),
      ),
      body: eventsAsync.when(
        data: (events) => _buildEventList(events),
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorMessage(error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEventList(List<Event> events) {
    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) => EventCard(events[index]),
    );
  }
}
```

**Provider Pattern:**
```dart
// lib/presentation/providers/event_providers.dart
@riverpod
EventRepository eventRepository(EventRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return EventRepository(db);
}

@riverpod
Stream<List<Event>> eventsForDate(EventsForDateRef ref, DateTime date) {
  final repo = ref.watch(eventRepositoryProvider);
  final start = DateTimeUtils.startOfDay(date);
  final end = DateTimeUtils.endOfDay(date);
  return repo.watchForDateRange(start, end);
}

@riverpod
class EventForm extends _$EventForm {
  @override
  Event build() {
    // Initial state
    return Event(
      id: const Uuid().v4(),
      title: '',
      timingType: TimingType.flexible,
      status: EventStatus.pending,
    );
  }
  
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }
  
  void updateTimingType(TimingType type) {
    state = state.copyWith(timingType: type);
  }
  
  Future<void> save() async {
    final repo = ref.read(eventRepositoryProvider);
    await repo.create(state);
  }
}
```

---

## Data Flow

### Read Flow (Query)

```
UI Widget
  ↓ watches provider
Riverpod Provider
  ↓ calls
Repository
  ↓ queries
Database (Drift)
  ↓ returns data
Repository (maps to entity)
  ↓ returns
Provider (streams to widget)
  ↓ updates
UI Widget (rebuilds)
```

### Write Flow (Command)

```
UI Widget (button pressed)
  ↓ calls provider method
Riverpod Provider
  ↓ validates input
  ↓ calls repository
Repository
  ↓ maps entity to database model
  ↓ writes to database
Database (Drift)
  ↓ on success
Repository
  ↓ returns
Provider (updates state if needed)
  ↓ triggers rebuild
UI Widget (shows success)
```

### Scheduling Flow

```
UI (Planning Wizard)
  ↓ user clicks "Generate Schedule"
Provider (scheduleProvider)
  ↓ fetches events from repository
  ↓ creates ScheduleRequest
  ↓ calls scheduler
Scheduler (EventScheduler)
  ↓ runs algorithm (pure function)
  ↓ returns ScheduleResult
Provider
  ↓ stores result in state
  ↓ notifies UI
UI (Plan Review Screen)
  ↓ displays schedule
```

---

## Dependency Rules

### Layer Dependencies (Allowed)

```
Presentation → Scheduler → Domain → Core
     ↓            ↓
   Data    ────────┘
     ↓
  Domain
```

### Rules

1. **Core** depends on nothing (pure utilities)
2. **Domain** depends only on Core
3. **Data** depends on Domain and Core
4. **Scheduler** depends on Domain and Core (NOT Data)
5. **Presentation** can depend on all layers (via providers)

### Anti-Patterns to Avoid

❌ Domain depending on Data
❌ Scheduler depending on Data
❌ Domain depending on Presentation
❌ Core depending on anything

---

## Error Handling Patterns

### Repository Errors

```dart
class EventRepository {
  Future<Event> create(Event event) async {
    try {
      await _db.into(_db.events).insert(_toCompanion(event));
      return event;
    } on SqliteException catch (e) {
      if (e.extendedResultCode == 2067) { // UNIQUE constraint
        throw DuplicateEventException(event.id);
      }
      throw DatabaseException('Failed to create event', e);
    }
  }
}
```

### Provider Errors

```dart
@riverpod
Future<Event> createEvent(CreateEventRef ref, Event event) async {
  try {
    final repo = ref.read(eventRepositoryProvider);
    return await repo.create(event);
  } on DuplicateEventException {
    throw UserFacingException('An event with this ID already exists');
  } on DatabaseException catch (e) {
    throw UserFacingException('Failed to save event: ${e.message}');
  }
}
```

### UI Error Handling

```dart
class EventFormScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue>(
      createEventProvider,
      (previous, next) {
        next.whenOrNull(
          error: (error, stack) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error.toString())),
            );
          },
        );
      },
    );
    
    // ... rest of UI
  }
}
```

---

## State Management Patterns

### Simple State (Read-Only)

```dart
// Just expose data from repository
@riverpod
Stream<List<Category>> categories(CategoriesRef ref) {
  final repo = ref.watch(categoryRepositoryProvider);
  return repo.watchAll();
}
```

### Stateful Operations

```dart
// Manage operation state (loading, success, error)
@riverpod
class DeleteEvent extends _$DeleteEvent {
  @override
  FutureOr<void> build() {
    // Initial state
  }
  
  Future<void> call(String eventId) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final repo = ref.read(eventRepositoryProvider);
      await repo.delete(eventId);
    });
  }
}
```

### Form State

```dart
@riverpod
class EventForm extends _$EventForm {
  @override
  Event build() => _initialEvent();
  
  void updateField(/* ... */) {
    state = state.copyWith(/* ... */);
  }
  
  bool validate() {
    return state.isValid();
  }
  
  Future<void> save() async {
    if (!validate()) throw ValidationException();
    final repo = ref.read(eventRepositoryProvider);
    await repo.create(state);
  }
}
```

---

## File Naming Conventions

### Classes

- Screens: `*_screen.dart` (e.g., `day_view_screen.dart`)
- Widgets: descriptive name (e.g., `event_card.dart`)
- Providers: `*_provider.dart` or `*_providers.dart`
- Repositories: `*_repository.dart`
- Entities: singular noun (e.g., `event.dart`, `category.dart`)

### Folders

- Use singular for single-file folders (e.g., `entity/`)
- Use plural for multi-file folders (e.g., `entities/`)
- Group by feature in presentation layer (e.g., `screens/day_view/`)

---

## Adding New Features Checklist

When adding a new feature:

- [ ] Define domain entities in `lib/domain/entities/`
- [ ] Add enums if needed in `lib/domain/enums/`
- [ ] Create database table in `lib/data/database/tables/`
- [ ] Run code generation: `flutter pub run build_runner build --delete-conflicting-outputs`
- [ ] Implement repository in `lib/data/repositories/`
- [ ] Create Riverpod providers in `lib/presentation/providers/`
- [ ] Build UI screens in `lib/presentation/screens/`
- [ ] Add routes in `lib/app/router.dart`
- [ ] Write tests in `test/`
- [ ] Update documentation if needed

---

*Last updated: 2026-01-16*
