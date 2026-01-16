# Data Model Specification

Complete database schema for TimePlanner using Drift/SQLite.

## Overview

This document defines the complete data model for TimePlanner. The database is implemented using Drift (SQLite ORM) with code generation.

**Implementation Status**: ⚠️ Partial (see table status below)

## Database Architecture

- **ORM**: Drift (type-safe SQLite wrapper)
- **Storage**: Local SQLite database on device
- **Migrations**: Managed by Drift's migration system
- **Code Generation**: Required after schema changes

## Table Definitions

### Status Legend
- ✅ Implemented
- 🟡 Partial
- ❌ Not yet implemented

---

### 1. Events Table ✅

Core table for all events (fixed and flexible).

```dart
class Events extends Table {
  // Primary key
  TextColumn get id => text()();
  
  // Basic properties
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  IntColumn get timingType => intEnum<TimingType>()();
  IntColumn get status => intEnum<EventStatus>()();
  
  // Time properties
  DateTimeColumn get startTime => dateTime().nullable()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  
  // Scheduling properties
  BoolColumn get isMovable => boolean().withDefault(const Constant(true))();
  BoolColumn get isResizable => boolean().withDefault(const Constant(true))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  
  // Relationships
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  TextColumn get templateId => text().nullable().references(EventTemplates, #id)();
  
  // Recurrence
  TextColumn get recurrenceRuleId => text().nullable().references(RecurrenceRules, #id)();
  DateTimeColumn get recurrenceParentDate => dateTime().nullable()();
  
  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Indexes**:
```dart
// Query by date range
Index on (startTime, endTime) where startTime IS NOT NULL
Index on (status)
Index on (categoryId)
```

---

### 2. EventConstraints Table ❌

Detailed constraints for event scheduling (time preferences, energy levels, etc.).

```dart
class EventConstraints extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(Events, #id, onDelete: KeyAction.cascade)();
  
  // Constraint details
  IntColumn get constraintType => intEnum<ConstraintType>()();
  TextColumn get value => text()(); // JSON-encoded constraint data
  
  // Time windows (for "must occur between" constraints)
  DateTimeColumn get preferredStartTime => dateTime().nullable()();
  DateTimeColumn get preferredEndTime => dateTime().nullable()();
  
  // Priority of this constraint (higher = more important)
  IntColumn get priority => integer().withDefault(const Constant(5))();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**ConstraintType Examples**:
- `mustOccurBetween`: Must be scheduled within time window
- `preferTimeOfDay`: Prefer morning/afternoon/evening
- `requiresHighEnergy`: Should be scheduled during high-energy periods
- `noBackToBack`: Needs buffer time before/after
- `maxPerDay`: Limit instances per day

---

### 3. RecurrenceRules Table ❌

Defines recurring event patterns.

```dart
class RecurrenceRules extends Table {
  TextColumn get id => text()();
  
  // Recurrence pattern
  IntColumn get frequency => intEnum<RecurrenceFrequency>()();
  IntColumn get interval => integer().withDefault(const Constant(1))();
  
  // Days of week (for weekly recurrence) - JSON array [0-6]
  TextColumn get byWeekDay => text().nullable()();
  
  // Days of month (for monthly recurrence) - JSON array [1-31]
  TextColumn get byMonthDay => text().nullable()();
  
  // End conditions
  IntColumn get endType => intEnum<RecurrenceEndType>()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get occurrences => integer().nullable()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 4. Categories Table ✅

Organize events into categories.

```dart
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()(); // Hex color code
  TextColumn get icon => text().nullable()(); // Icon identifier
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Default Categories** (seeded on first run):
```dart
final defaultCategories = [
  Category(id: 'work', name: 'Work', color: '#2196F3', isDefault: true),
  Category(id: 'personal', name: 'Personal', color: '#4CAF50', isDefault: true),
  Category(id: 'family', name: 'Family', color: '#FF9800', isDefault: true),
  Category(id: 'health', name: 'Health', color: '#F44336', isDefault: true),
  Category(id: 'creative', name: 'Creative', color: '#9C27B0', isDefault: true),
  Category(id: 'chores', name: 'Chores', color: '#795548', isDefault: true),
  Category(id: 'social', name: 'Social', color: '#E91E63', isDefault: true),
];
```

---

### 5. People Table ❌

Track people associated with events.

```dart
class People extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get notes => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Unique Constraint**: `name` (case-insensitive)

---

### 6. EventPeople Table ❌

Many-to-many relationship between Events and People.

```dart
class EventPeople extends Table {
  TextColumn get eventId => text().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get personId => text().references(People, #id, onDelete: KeyAction.cascade)();
  
  @override
  Set<Column> get primaryKey => {eventId, personId};
}
```

---

### 7. Locations Table ❌

Physical locations for events.

```dart
class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  
  // Coordinates for travel time calculation
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 8. TravelTimePairs Table ❌

Pre-computed travel times between location pairs.

```dart
class TravelTimePairs extends Table {
  TextColumn get fromLocationId => text().references(Locations, #id, onDelete: KeyAction.cascade)();
  TextColumn get toLocationId => text().references(Locations, #id, onDelete: KeyAction.cascade)();
  
  IntColumn get travelTimeMinutes => integer()();
  
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {fromLocationId, toLocationId};
}
```

**Note**: Travel time is directional but stored bidirectionally. Both (A→B) and (B→A) are stored.

---

### 9. Goals Table ✅

User-defined goals for time allocation.

```dart
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get type => intEnum<GoalType>()();
  
  // Goal target
  IntColumn get metric => intEnum<GoalMetric>()(); // hours, events, etc.
  IntColumn get targetValue => integer()(); // e.g., 10 for "10 hours"
  IntColumn get period => intEnum<GoalPeriod>()(); // per week, per month
  
  // What this goal tracks
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get personId => text().nullable().references(People, #id)();
  
  // Debt handling
  IntColumn get debtStrategy => intEnum<DebtStrategy>()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 10. EventGoals Table ❌

Many-to-many relationship between Events and Goals.

```dart
class EventGoals extends Table {
  TextColumn get eventId => text().references(Events, #id, onDelete: KeyAction.cascade)();
  TextColumn get goalId => text().references(Goals, #id, onDelete: KeyAction.cascade)();
  
  // How much this event contributes to the goal
  IntColumn get contributionMinutes => integer()();
  
  @override
  Set<Column> get primaryKey => {eventId, goalId};
}
```

---

### 11. GoalProgress Table ❌

Track actual progress toward goals over time.

```dart
class GoalProgress extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id, onDelete: KeyAction.cascade)();
  
  // Period this progress entry covers
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  
  // Progress metrics
  IntColumn get actualValue => integer()(); // e.g., actual hours spent
  IntColumn get targetValue => integer()(); // target for this period
  IntColumn get status => intEnum<GoalProgressStatus>()();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Index**: `(goalId, periodStart)`

---

### 12. EventTemplates Table ❌

Reusable templates for common events.

```dart
class EventTemplates extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  
  // Template properties (same as Events table)
  IntColumn get timingType => intEnum<TimingType>()();
  IntColumn get durationMinutes => integer().nullable()();
  BoolColumn get isMovable => boolean().withDefault(const Constant(true))();
  BoolColumn get isResizable => boolean().withDefault(const Constant(true))();
  
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get locationId => text().nullable().references(Locations, #id)();
  
  // Usage tracking
  IntColumn get useCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUsed => dateTime().nullable()();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 13. Schedules Table ❌

Generated schedule plans.

```dart
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()(); // e.g., "Week of Jan 15", "Balanced Plan"
  
  // Schedule window
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  
  // Metadata
  TextColumn get strategyUsed => text()(); // "balanced", "front_loaded", etc.
  IntColumn get status => intEnum<ScheduleStatus>()();
  
  // Generation info
  DateTimeColumn get generatedAt => dateTime()();
  IntColumn get generationTimeMs => integer()(); // Performance tracking
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 14. ScheduledEvents Table ❌

Links events to schedules with specific times.

```dart
class ScheduledEvents extends Table {
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(Schedules, #id, onDelete: KeyAction.cascade)();
  TextColumn get eventId => text().references(Events, #id, onDelete: KeyAction.cascade)();
  
  // Scheduled time (may differ from Event.startTime for flexible events)
  DateTimeColumn get scheduledStartTime => dateTime()();
  DateTimeColumn get scheduledEndTime => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Unique Constraint**: `(scheduleId, eventId)` - Each event appears once per schedule

**Index**: `(scheduleId, scheduledStartTime)`

---

### 15. UserSettings Table ❌

App configuration and user preferences.

```dart
class UserSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()(); // JSON-encoded value
  
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {key};
}
```

**Example Settings**:
```dart
{
  "work_hours_start": "09:00",
  "work_hours_end": "17:00",
  "default_event_duration": 60,
  "default_scheduling_strategy": "balanced",
  "week_start_day": 1, // Monday
  "time_slot_minutes": 15,
  "show_completed_events": true,
  "notification_reminder_minutes": 15,
  "theme_mode": "system", // light, dark, system
}
```

---

## Enums

### TimingType

```dart
enum TimingType {
  fixed,    // Event has specific start/end time
  flexible  // Event has duration but no fixed time
}
```

### EventStatus

```dart
enum EventStatus {
  pending,     // Not yet started
  inProgress,  // Currently happening
  completed,   // Finished
  cancelled    // Cancelled
}
```

### ConstraintType

```dart
enum ConstraintType {
  mustOccurBetween,      // Hard time window
  preferTimeOfDay,       // Soft preference
  requiresHighEnergy,    // Energy level requirement
  noBackToBack,          // Needs buffer
  maxPerDay,             // Frequency limit
  minTimeBetween,        // Gap between instances
  requiresWeather        // Weather-dependent (future)
}
```

### RecurrenceFrequency

```dart
enum RecurrenceFrequency {
  daily,
  weekly,
  monthly,
  yearly
}
```

### RecurrenceEndType

```dart
enum RecurrenceEndType {
  never,          // Recurs indefinitely
  afterOccurrences, // Stop after N occurrences
  onDate          // Stop on specific date
}
```

### GoalType

```dart
enum GoalType {
  category,  // Time spent on a category
  person,    // Time spent with a person
  custom     // Custom goal (future)
}
```

### GoalMetric

```dart
enum GoalMetric {
  hours,         // Track hours
  events,        // Track number of events
  completions    // Track completion percentage
}
```

### GoalPeriod

```dart
enum GoalPeriod {
  week,
  month,
  quarter,
  year
}
```

### DebtStrategy

```dart
enum DebtStrategy {
  ignore,           // Don't carry over shortfall
  carryForward,     // Add shortfall to next period
  distributeEvenly  // Spread shortfall over next N periods
}
```

### GoalProgressStatus

```dart
enum GoalProgressStatus {
  onTrack,     // Meeting target
  atRisk,      // Slightly behind
  behind,      // Significantly behind
  exceeded     // Over target
}
```

### ScheduleStatus

```dart
enum ScheduleStatus {
  draft,      // Generated but not accepted
  active,     // Currently active schedule
  completed,  // Past schedule
  archived    // Kept for history
}
```

---

## Database Class Definition

```dart
@DriftDatabase(
  tables: [
    Events,
    EventConstraints,
    RecurrenceRules,
    Categories,
    People,
    EventPeople,
    Locations,
    TravelTimePairs,
    Goals,
    EventGoals,
    GoalProgress,
    EventTemplates,
    Schedules,
    ScheduledEvents,
    UserSettings,
  ],
  daos: [
    EventDao,
    CategoryDao,
    GoalDao,
    ScheduleDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(QueryExecutor e) : super(e);
  
  @override
  int get schemaVersion => 1;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Future migrations go here
    },
  );
  
  Future<void> _seedDefaultCategories() async {
    // Insert default categories
  }
}
```

---

## Key Queries

### Get Events for Date Range

```dart
Future<List<Event>> getEventsForDateRange(DateTime start, DateTime end) {
  return (select(events)
    ..where((e) => 
      e.startTime.isBiggerOrEqualValue(start) &
      e.startTime.isSmallerThanValue(end))
    ..orderBy([(e) => OrderingTerm.asc(e.startTime)]))
    .get();
}
```

### Get Events by Status

```dart
Stream<List<Event>> watchEventsByStatus(EventStatus status) {
  return (select(events)
    ..where((e) => e.status.equals(status.index))
    ..orderBy([(e) => OrderingTerm.asc(e.startTime)]))
    .watch();
}
```

### Get Events with Category

```dart
Future<List<EventWithCategory>> getEventsWithCategory() {
  final query = select(events).join([
    leftOuterJoin(categories, categories.id.equalsExp(events.categoryId)),
  ]);
  
  return query.map((row) {
    return EventWithCategory(
      event: row.readTable(events),
      category: row.readTableOrNull(categories),
    );
  }).get();
}
```

### Get Goal Progress

```dart
Future<GoalProgressSummary> getGoalProgress(String goalId, DateTime periodStart) {
  // Join goals, events, and event_goals to calculate actual progress
}
```

---

## Indexes

```dart
// Events table
@TableIndex(name: 'events_start_time_idx', columns: {#startTime})
@TableIndex(name: 'events_status_idx', columns: {#status})
@TableIndex(name: 'events_category_idx', columns: {#categoryId})

// ScheduledEvents table
@TableIndex(name: 'scheduled_events_schedule_idx', columns: {#scheduleId, #scheduledStartTime})

// GoalProgress table
@TableIndex(name: 'goal_progress_goal_period_idx', columns: {#goalId, #periodStart})
```

---

## Data Integrity Rules

### Cascade Deletes

- Deleting an Event cascades to EventConstraints, EventPeople, EventGoals, ScheduledEvents
- Deleting a Category does NOT cascade (sets event.categoryId to null)
- Deleting a Goal cascades to EventGoals and GoalProgress
- Deleting a Schedule cascades to ScheduledEvents

### Validation Rules

**Events**:
- Fixed events must have startTime and endTime
- Flexible events must have durationMinutes
- endTime must be after startTime (if both present)
- durationMinutes must be > 0 and <= 1440 (24 hours)

**Goals**:
- targetValue must be > 0
- Must have either categoryId or personId (depending on type)

**RecurrenceRules**:
- interval must be >= 1
- If endType is afterOccurrences, occurrences must be > 0
- If endType is onDate, endDate must be in future

---

## Domain Model Mapping

### Event Entity

```dart
class Event {
  final String id;
  final String title;
  final String? description;
  final TimingType timingType;
  final EventStatus status;
  
  // Time
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  
  // Constraints
  final bool isMovable;
  final bool isResizable;
  final bool isLocked;
  
  // Relationships
  final String? categoryId;
  final String? locationId;
  final String? recurrenceRuleId;
  
  // Computed properties
  Duration get duration {
    if (timingType == TimingType.fixed && startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    if (durationMinutes != null) {
      return Duration(minutes: durationMinutes!);
    }
    throw StateError('Cannot compute duration for event');
  }
  
  bool get isFixed => timingType == TimingType.fixed;
  bool get isFlexible => timingType == TimingType.flexible;
  bool get isSchedulable => isFlexible && !isLocked;
}
```

### Repository Responsibilities

Repositories handle:
- Mapping between database models and domain entities
- Validation before insert/update
- Computing derived fields
- Handling cascade logic
- Exposing streams for reactive UI

Example:
```dart
class EventRepository {
  final AppDatabase _db;
  
  // Convert database model to domain entity
  Event _toEntity(EventsCompanion data) { ... }
  
  // Convert domain entity to database model
  EventsCompanion _toCompanion(Event entity) { ... }
  
  // CRUD operations
  Future<Event> create(Event event) async {
    await _validate(event);
    final id = await _db.into(_db.events).insert(_toCompanion(event));
    return event;
  }
  
  Stream<List<Event>> watchAll() {
    return _db.select(_db.events).watch().map(
      (rows) => rows.map(_toEntity).toList()
    );
  }
}
```

---

## Migration Strategy

### Version 1 (Initial Schema)
- All 15 tables created
- Default categories seeded
- Indexes created

### Future Migrations

When adding fields:
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (Migrator m, int from, int to) async {
    if (from == 1) {
      // Add new column with default value
      await m.addColumn(events, events.priority);
    }
  },
);
```

When adding tables:
```dart
if (from < 2) {
  await m.createTable(newTable);
}
```

---

*Last updated: 2026-01-16*
