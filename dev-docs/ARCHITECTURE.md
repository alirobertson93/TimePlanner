# Architecture Specification

Complete architecture and code organization for TimePlanner.

## Overview

TimePlanner follows a **clean architecture** pattern with clear separation of concerns across layers. This document defines the structure, responsibilities, and patterns for each layer.

> **Note**: This document uses the term "Activity" as the unified model for all calendar items. The term "Event" may still appear in the current codebase but will be renamed to "Activity" as part of the Activity Model Refactor (see `ACTIVITY_REFACTOR_IMPLEMENTATION.md`).

**Last Updated**: 2026-01-26

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
│   │   ├── activity.dart              # Currently: event.dart
│   │   ├── category.dart
│   │   ├── goal.dart
│   │   ├── person.dart
│   │   ├── location.dart
│   │   ├── notification.dart
│   │   ├── recurrence_rule.dart
│   │   └── ...
│   ├── enums/                         # Domain enumerations
│   │   ├── timing_type.dart
│   │   ├── activity_status.dart       # Currently: event_status.dart
│   │   ├── goal_type.dart
│   │   ├── notification_type.dart
│   │   ├── notification_status.dart
│   │   ├── recurrence_frequency.dart
│   │   ├── recurrence_end_type.dart
│   │   └── ...
│   └── services/                      # Domain services (NEW)
│       ├── series_matching_service.dart  # NEW - Series matching logic
│       └── ...
│
├── data/                              # Data layer (persistence)
│   ├── database/
│   │   ├── app_database.dart          # Drift database definition
│   │   ├── app_database.g.dart        # Generated code
│   │   ├── tables/                    # Table definitions
│   │   │   ├── activities_table.dart  # Currently: events_table.dart
│   │   │   ├── categories_table.dart
│   │   │   └── ...
│   │   └── daos/                      # Data Access Objects
│   │       ├── activity_dao.dart      # Currently: event_dao.dart
│   │       └── ...
│   └── repositories/                  # Repository implementations
│       ├── activity_repository.dart   # Currently: event_repository.dart
│       ├── category_repository.dart
│       ├── goal_repository.dart
│       ├── person_repository.dart
│       ├── location_repository.dart
│       ├── notification_repository.dart
│       ├── recurrence_rule_repository.dart
│       ├── activity_people_repository.dart  # Currently: event_people_repository.dart
│       └── ...
│
├── scheduler/                         # Scheduling engine (pure Dart)
│   ├── scheduler.dart                 # Main scheduler interface
│   ├── activity_scheduler.dart        # Currently: event_scheduler.dart
│   ├── models/                        # Scheduler-specific models
│   │   ├── schedule_request.dart
│   │   ├── schedule_result.dart
│   │   ├── scheduled_activity.dart    # Currently: scheduled_event.dart
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
    │   ├── activity_providers.dart    # Currently: event_providers.dart
    │   ├── category_providers.dart    # Category state
    │   ├── series_matching_providers.dart  # NEW - Series matching state
    │   └── ...
    │
    ├── screens/                       # App screens
    │   ├── home/
    │   │   ├── home_screen.dart
    │   │   └── widgets/
    │   │       ├── activity_list.dart  # Currently: event_list.dart
    │   │       └── add_activity_fab.dart  # Currently: add_event_fab.dart
    │   ├── day_view/
    │   │   ├── day_view_screen.dart
    │   │   └── widgets/
    │   │       ├── day_timeline.dart
    │   │       ├── activity_card.dart  # Currently: event_card.dart
    │   │       └── time_marker.dart
    │   ├── week_view/
    │   │   ├── week_view_screen.dart
    │   │   └── widgets/
    │   ├── activity_detail/           # Currently: event_detail/
    │   │   ├── activity_detail_screen.dart  # Currently: event_detail_screen.dart
    │   │   └── widgets/
    │   ├── activity_form/             # Currently: event_form/
    │   │   ├── activity_form_screen.dart  # Currently: event_form_screen.dart
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
        ├── series_prompt_dialog.dart  # NEW - Series selection UI
        ├── edit_scope_dialog.dart     # NEW - Edit scope selection UI
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
- ✅ Entity classes (Activity, Category, Goal, etc.)
- ✅ Enums (TimingType, ActivityStatus, etc.)
- ✅ Value objects (Email, Duration, etc.)
- ✅ Business rules (validation, calculations)
- ✅ Domain exceptions
- ✅ Domain services (SeriesMatchingService, etc.)

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
// lib/domain/entities/activity.dart (currently event.dart)
class Activity {  // Currently: Event
  final String id;
  final String? title;  // NOW NULLABLE
  final String? description;
  final TimingType timingType;
  final ActivityStatus status;  // Currently: EventStatus
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final bool isMovable;
  final bool isResizable;
  final bool isLocked;
  final String? categoryId;
  final String? seriesId;  // NEW - for grouping related activities
  
  Activity({
    required this.id,
    this.title,  // Now optional
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
    this.seriesId,
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
  bool get isScheduled => startTime != null;
  bool get isUnscheduled => startTime == null;
  
  // Display title (handles nullable title)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return _computedDisplayTitle ?? 'Untitled Activity';
  }
  
  // Validation
  bool isValid({List<String>? personIds}) {
    final hasTitle = title != null && title!.isNotEmpty;
    final hasPerson = personIds != null && personIds.isNotEmpty;
    final hasLocation = locationId != null;
    final hasCategory = categoryId != null;
    
    // Must have at least one identifying property
    if (!hasTitle && !hasPerson && !hasLocation && !hasCategory) {
      return false;
    }
    
    if (timingType == TimingType.fixed) {
      return startTime != null && endTime != null && endTime!.isAfter(startTime!);
    } else {
      return durationMinutes != null && durationMinutes! > 0;
    }
  }
}
```

**SeriesMatchingService** (NEW - Activity Model Refactor):
```dart
// lib/domain/services/series_matching_service.dart
class SeriesMatchingService {
  final IActivityRepository _activityRepository;
  final IActivityPeopleRepository _activityPeopleRepository;
  
  /// Find existing series that match the given activity
  Future<List<ActivitySeries>> findMatchingSeries(Activity activity) async {
    final allActivities = await _activityRepository.getAll();
    final matches = <String, List<Activity>>{};
    
    for (final existing in allActivities) {
      if (existing.id == activity.id) continue;
      if (_isMatch(activity, existing)) {
        final seriesId = existing.seriesId ?? existing.id;
        matches.putIfAbsent(seriesId, () => []).add(existing);
      }
    }
    
    return matches.entries.map((e) => ActivitySeries(
      id: e.key,
      activities: e.value,
      displayTitle: e.value.first.displayTitle,
    )).toList();
  }
  
  /// Check if two activities match (should be in same series)
  bool _isMatch(Activity a, Activity b) {
    // Title match (case-insensitive)
    if (a.title != null && b.title != null &&
        a.title!.toLowerCase() == b.title!.toLowerCase()) {
      return true;
    }
    
    // Property match (2+ of: person, location, category)
    int matchCount = 0;
    if (a.categoryId != null && a.categoryId == b.categoryId) matchCount++;
    if (a.locationId != null && a.locationId == b.locationId) matchCount++;
    if (_hasSamePerson(a, b)) matchCount++;
    
    return matchCount >= 2;
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
// lib/data/repositories/activity_repository.dart (currently event_repository.dart)
class ActivityRepository implements IActivityRepository {  // Currently: EventRepository
  final AppDatabase _db;
  
  ActivityRepository(this._db);
  
  // Query methods
  Future<List<Activity>> getAll() async {
    final results = await _db.select(_db.activities).get();  // Currently: _db.events
    return results.map(_toEntity).toList();
  }
  
  Future<Activity?> getById(String id) async {
    final result = await (_db.select(_db.activities)  // Currently: _db.events
      ..where((a) => a.id.equals(id))).getSingleOrNull();
    return result != null ? _toEntity(result) : null;
  }
  
  Stream<List<Activity>> watchForDateRange(DateTime start, DateTime end) {
    return (_db.select(_db.activities)  // Currently: _db.events
      ..where((a) => 
        a.startTime.isBiggerOrEqualValue(start) &
        a.startTime.isSmallerThanValue(end)))
      .watch()
      .map((rows) => rows.map(_toEntity).toList());
  }
  
  // NEW - Get unscheduled activities (activity bank)
  Stream<List<Activity>> watchUnscheduled() {
    return (_db.select(_db.activities)
      ..where((a) => a.startTime.isNull()))
      .watch()
      .map((rows) => rows.map(_toEntity).toList());
  }
  
  // NEW - Get activities by series
  Future<List<Activity>> getBySeriesId(String seriesId) async {
    final results = await (_db.select(_db.activities)
      ..where((a) => a.seriesId.equals(seriesId)))
      .get();
    return results.map(_toEntity).toList();
  }
  
  // Mutation methods
  Future<void> create(Activity activity, {List<String>? personIds}) async {
    _validate(activity, personIds: personIds);
    await _db.into(_db.activities).insert(_toCompanion(activity));  // Currently: _db.events
  }
  
  Future<void> update(Activity activity) async {
    await (_db.update(_db.activities)..where((a) => a.id.equals(activity.id)))  // Currently: _db.events
      .write(_toCompanion(activity));
  }
  
  Future<void> delete(String id) async {
    await (_db.delete(_db.activities)..where((a) => a.id.equals(id))).go();  // Currently: _db.events
  }
  
  // Validation (NEW - Activity Model Refactor)
  void _validate(Activity activity, {List<String>? personIds}) {
    final hasTitle = activity.title != null && activity.title!.isNotEmpty;
    final hasPerson = personIds != null && personIds.isNotEmpty;
    final hasLocation = activity.locationId != null;
    final hasCategory = activity.categoryId != null;
    
    if (!hasTitle && !hasPerson && !hasLocation && !hasCategory) {
      throw ValidationException(
        'Activity must have at least one of: title, person, location, or category'
      );
    }
  }
  
  // Mappers
  Activity _toEntity(ActivityData data) {  // Currently: EventData
    return Activity(
      id: data.id,
      title: data.title,
      description: data.description,
      timingType: TimingType.values[data.timingType],
      status: ActivityStatus.values[data.status],  // Currently: EventStatus
      startTime: data.startTime,
      endTime: data.endTime,
      durationMinutes: data.durationMinutes,
      isMovable: data.isMovable,
      isResizable: data.isResizable,
      isLocked: data.isLocked,
      categoryId: data.categoryId,
      seriesId: data.seriesId,  // NEW
    );
  }
  
  ActivitiesCompanion _toCompanion(Activity entity) {  // Currently: EventsCompanion
    return ActivitiesCompanion.insert(
      id: entity.id,
      title: Value(entity.title),  // Now nullable
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
      seriesId: Value(entity.seriesId),  // NEW
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
// lib/scheduler/activity_scheduler.dart (currently event_scheduler.dart)
class ActivityScheduler {  // Currently: EventScheduler
  // Pure function - no dependencies on database or UI
  ScheduleResult schedule(ScheduleRequest request) {
    final stopwatch = Stopwatch()..start();
    
    // Initialize availability grid
    final grid = AvailabilityGrid(request.windowStart, request.windowEnd);
    
    // Multi-pass scheduling
    final conflicts = <Conflict>[];
    _placeFixedActivities(request.fixedActivities, grid, conflicts);
    _placeFlexibleActivities(request.flexibleActivities, grid, request.strategy);
    
    // Calculate goal progress
    final goalProgress = _calculateGoalProgress(
      grid.scheduledActivities,
      request.goals,
      request.windowStart,
      request.windowEnd,
    );
    
    stopwatch.stop();
    
    return ScheduleResult(
      success: conflicts.isEmpty,
      scheduledActivities: grid.scheduledActivities,
      unscheduledActivities: grid.unscheduledActivities,
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
    // Watch activities for this date
    final activitiesAsync = ref.watch(activitiesForDateProvider(date));  // Currently: eventsForDateProvider
    
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat.yMMMMd().format(date)),
      ),
      body: activitiesAsync.when(
        data: (activities) => _buildActivityList(activities),  // Currently: _buildEventList
        loading: () => const LoadingIndicator(),
        error: (error, stack) => ErrorMessage(error.toString()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivityDialog(context, ref),  // Currently: _showAddEventDialog
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildActivityList(List<Activity> activities) {  // Currently: _buildEventList(List<Event> events)
    return ListView.builder(
      itemCount: activities.length,
      itemBuilder: (context, index) => ActivityCard(activities[index]),  // Currently: EventCard
    );
  }
}
```

**Provider Pattern:**
```dart
// lib/presentation/providers/activity_providers.dart (currently event_providers.dart)
@riverpod
ActivityRepository activityRepository(ActivityRepositoryRef ref) {  // Currently: eventRepository
  final db = ref.watch(databaseProvider);
  return ActivityRepository(db);  // Currently: EventRepository
}

@riverpod
Stream<List<Activity>> activitiesForDate(ActivitiesForDateRef ref, DateTime date) {  // Currently: eventsForDate
  final repo = ref.watch(activityRepositoryProvider);  // Currently: eventRepositoryProvider
  final start = DateTimeUtils.startOfDay(date);
  final end = DateTimeUtils.endOfDay(date);
  return repo.watchForDateRange(start, end);
}

// NEW - Watch unscheduled activities (activity bank)
@riverpod
Stream<List<Activity>> unscheduledActivities(UnscheduledActivitiesRef ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return repo.watchUnscheduled();
}

@riverpod
class ActivityForm extends _$ActivityForm {  // Currently: EventForm
  @override
  Activity build() {  // Currently: Event
    // Initial state
    return Activity(
      id: const Uuid().v4(),
      title: null,  // Now nullable
      timingType: TimingType.flexible,
      status: ActivityStatus.pending,  // Currently: EventStatus
    );
  }
  
  void updateTitle(String? title) {
    state = state.copyWith(title: title);
  }
  
  void updateTimingType(TimingType type) {
    state = state.copyWith(timingType: type);
  }
  
  Future<void> save({List<String>? personIds}) async {
    final repo = ref.read(activityRepositoryProvider);  // Currently: eventRepositoryProvider
    await repo.create(state, personIds: personIds);
  }
}

// NEW - Series matching provider
@riverpod
class SeriesMatchingNotifier extends _$SeriesMatchingNotifier {
  @override
  AsyncValue<List<ActivitySeries>> build(Activity activity) {
    return const AsyncValue.loading();
  }
  
  Future<void> findMatches(Activity activity) async {
    state = const AsyncValue.loading();
    final service = ref.read(seriesMatchingServiceProvider);
    final matches = await service.findMatchingSeries(activity);
    state = AsyncValue.data(matches);
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

*Last updated: 2026-01-26 (Activity Model Refactor documentation)*
