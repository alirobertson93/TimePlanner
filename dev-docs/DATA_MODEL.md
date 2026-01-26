# Data Model Specification

Complete database schema for TimePlanner using Drift/SQLite.

## Overview

This document defines the complete data model for TimePlanner. The database is implemented using Drift (SQLite ORM) with code generation.

**Implementation Status**: ⚠️ Partial (see table status below)

**Current Schema Version**: 12 (Phase 9A in progress)

> **Note**: This document uses the term "Activity" as the unified model for all calendar items. The term "Event" may still appear in the current codebase but will be renamed to "Activity" as part of the Activity Model Refactor (see `ACTIVITY_REFACTOR_IMPLEMENTATION.md`).

**Implemented Tables** (9 total):
- Activities (currently named Events) ✅
- Categories ✅
- Goals ✅ (with personId for relationship goals, added v9)
- People ✅
- ActivityPeople (currently named EventPeople) ✅
- Locations ✅
- RecurrenceRules ✅
- Notifications ✅
- TravelTimePairs ✅ (added v10)

**Not Yet Implemented Tables** (7 total):
- ActivityConstraints (currently named EventConstraints) ❌
- ActivityGoals (currently named EventGoals) ❌
- GoalProgress ❌
- ActivityTemplates (currently named EventTemplates) ❌
- Schedules ❌
- ScheduledActivities (currently named ScheduledEvents) ❌
- UserSettings ❌ (Note: User settings use SharedPreferences instead)

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

### 1. Activities Table ✅

> **Naming Note**: Currently implemented as `Events` table in codebase. Will be renamed to `Activities` as part of the Activity Model Refactor.

Core table for all activities (scheduled and unscheduled, fixed and flexible).

**What is an Activity?**
An Activity is any item the user wants to track or schedule. An Activity can be:
- **Scheduled** - Has a specific date/time, appears on the calendar
- **Unscheduled** - No date/time, exists in an "activity bank" for the planning wizard

Both are the same entity type - the difference is whether time properties are populated.

```dart
class Activities extends Table {  // Currently: Events
  // Primary key
  TextColumn get id => text()();
  
  // Basic properties
  TextColumn get title => text().nullable()();  // NOW NULLABLE - see validation rules
  TextColumn get description => text().nullable()();
  IntColumn get timingType => intEnum<TimingType>()();
  IntColumn get status => intEnum<ActivityStatus>()();  // Currently: EventStatus
  
  // Time properties (null for unscheduled activities)
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
  TextColumn get templateId => text().nullable().references(ActivityTemplates, #id)();  // Currently: EventTemplates
  
  // Recurrence
  TextColumn get recurrenceRuleId => text().nullable().references(RecurrenceRules, #id)();
  DateTimeColumn get recurrenceParentDate => dateTime().nullable()();
  
  // Series grouping (NEW - Activity Model Refactor)
  TextColumn get seriesId => text().nullable()();  // Groups related activities together
  
  // Metadata
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Validation Rules**:

An Activity must have **at least one** of the following (enforced in repository/entity):
- `title` (non-empty)
- Person (via ActivityPeople junction)
- `locationId`
- `categoryId`

This makes `title` optional - an activity can exist with just a person, location, or category.

**Display Title Logic** (computed property):

Since title is now optional, the app uses a computed `displayTitle` for UI rendering:

```dart
String get displayTitle {
  if (title != null && title!.isNotEmpty) {
    return title!;
  }
  // Concatenate available properties with separator
  return [person?.name, location?.name, category?.name]
    .where((s) => s != null && s.isNotEmpty)
    .join(' · ');
}
```

**Series Field** (`seriesId`):

The `seriesId` field groups related activities together, independent of recurrence:

| Concept | Field | Purpose |
|---------|-------|---------|
| Recurrence | `recurrenceRuleId` | Defines a pattern (every Monday, monthly on 15th) |
| Series | `seriesId` | Groups related activities regardless of pattern |

- Recurring activities have BOTH `recurrenceRuleId` AND `seriesId`
- Ad-hoc matched activities have only `seriesId`
- Standalone activities have neither (or a unique `seriesId`)

**Indexes** (added in schema v11):
```dart
@TableIndex(name: 'idx_activities_start_time', columns: {#startTime})  // Currently: idx_events_start_time
@TableIndex(name: 'idx_activities_end_time', columns: {#endTime})  // Currently: idx_events_end_time
@TableIndex(name: 'idx_activities_category', columns: {#categoryId})  // Currently: idx_events_category
@TableIndex(name: 'idx_activities_status', columns: {#status})  // Currently: idx_events_status
@TableIndex(name: 'idx_activities_series', columns: {#seriesId})  // NEW - for series lookups
```

---

### 2. ActivityConstraints Table ❌

> **Naming Note**: Currently documented as `EventConstraints`. Will be renamed to `ActivityConstraints` as part of the Activity Model Refactor.

Detailed constraints for activity scheduling (time preferences, energy levels, etc.).

```dart
class ActivityConstraints extends Table {  // Currently: EventConstraints
  TextColumn get id => text()();
  TextColumn get activityId => text().references(Activities, #id, onDelete: KeyAction.cascade)();  // Currently: eventId
  
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

### 3. RecurrenceRules Table ✅

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
  
  // Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
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

### 5. People Table ✅

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

### 6. ActivityPeople Table ✅

> **Naming Note**: Currently implemented as `EventPeople` table in codebase. Will be renamed to `ActivityPeople` as part of the Activity Model Refactor.

Many-to-many relationship between Activities and People.

```dart
class ActivityPeople extends Table {  // Currently: EventPeople
  TextColumn get activityId => text().references(Activities, #id, onDelete: KeyAction.cascade)();  // Currently: eventId
  TextColumn get personId => text().references(People, #id, onDelete: KeyAction.cascade)();
  
  @override
  Set<Column> get primaryKey => {activityId, personId};  // Currently: {eventId, personId}
}
```

---

### 7. Locations Table ✅

Physical locations for events.

```dart
class Locations extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get address => text().nullable()();
  
  // Coordinates for travel time calculation
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  
  // Notes about the location
  TextColumn get notes => text().nullable()();
  
  DateTimeColumn get createdAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

---

### 8. TravelTimePairs Table ✅

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

**Note**: Travel time is directional but stored bidirectionally. Both (A→B) and (B→A) are stored with the same duration. Added in schema version 10.

---

### 9. Goals Table ✅

User-defined goals for time allocation.

```dart
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  IntColumn get type => intEnum<GoalType>()();
  
  // Goal target
  IntColumn get metric => intEnum<GoalMetric>()(); // hours, activities, etc.
  IntColumn get targetValue => integer()(); // e.g., 10 for "10 hours"
  IntColumn get period => intEnum<GoalPeriod>()(); // per week, per month
  
  // What this goal tracks
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get personId => text().nullable().references(People, #id)();
  TextColumn get locationId => text().nullable().references(Locations, #id)(); // Added in v12
  TextColumn get activityTitle => text().nullable()(); // Added in v12 - for activity-type goals (renamed from eventTitle)
  
  // Debt handling
  IntColumn get debtStrategy => intEnum<DebtStrategy>()();
  
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Indexes** (added in schema v11, expanded in v12):
```dart
@TableIndex(name: 'idx_goals_category', columns: {#categoryId})
@TableIndex(name: 'idx_goals_person', columns: {#personId})
@TableIndex(name: 'idx_goals_location', columns: {#locationId})  // Added in v12
@TableIndex(name: 'idx_goals_active', columns: {#isActive})
```

**Goal Types** (as of schema v12):
- `category`: Track time spent on a specific category (e.g., "Work", "Exercise")
- `person`: Track time spent with a specific person (e.g., "Girlfriend", "Mom")
- `location`: Track time spent at a specific location (e.g., "Home", "Office") - **Added in v12**
- `activity`: Track time spent on a specific recurring activity by title (e.g., "Guitar Practice") - **Added in v12** (renamed from `event`)
- `custom`: Custom goal (future use)

**Field Usage by Goal Type**:
- Category goals: use `categoryId`
- Person goals: use `personId`
- Location goals: use `locationId` - **Added in v12**
- Activity goals: use `activityTitle` (matches activity title, case-insensitive) - **Added in v12** (renamed from `eventTitle`)
- Custom goals: may use any combination

---

### 10. ActivityGoals Table ❌

> **Naming Note**: Currently documented as `EventGoals`. Will be renamed to `ActivityGoals` as part of the Activity Model Refactor.

Many-to-many relationship between Activities and Goals.

```dart
class ActivityGoals extends Table {  // Currently: EventGoals
  TextColumn get activityId => text().references(Activities, #id, onDelete: KeyAction.cascade)();  // Currently: eventId
  TextColumn get goalId => text().references(Goals, #id, onDelete: KeyAction.cascade)();
  
  // How much this activity contributes to the goal
  IntColumn get contributionMinutes => integer()();
  
  @override
  Set<Column> get primaryKey => {activityId, goalId};  // Currently: {eventId, goalId}
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

### 12. ActivityTemplates Table ❌

> **Naming Note**: Currently documented as `EventTemplates`. Will be renamed to `ActivityTemplates` as part of the Activity Model Refactor.

Reusable templates for common activities.

```dart
class ActivityTemplates extends Table {  // Currently: EventTemplates
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  
  // Template properties (same as Activities table)
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

### 14. ScheduledActivities Table ❌

> **Naming Note**: Currently documented as `ScheduledEvents`. Will be renamed to `ScheduledActivities` as part of the Activity Model Refactor.

Links activities to schedules with specific times.

```dart
class ScheduledActivities extends Table {  // Currently: ScheduledEvents
  TextColumn get id => text()();
  TextColumn get scheduleId => text().references(Schedules, #id, onDelete: KeyAction.cascade)();
  TextColumn get activityId => text().references(Activities, #id, onDelete: KeyAction.cascade)();  // Currently: eventId
  
  // Scheduled time (may differ from Activity.startTime for flexible activities)
  DateTimeColumn get scheduledStartTime => dateTime()();
  DateTimeColumn get scheduledEndTime => dateTime()();
  
  @override
  Set<Column> get primaryKey => {id};
}
```

**Unique Constraint**: `(scheduleId, activityId)` - Each activity appears once per schedule

**Index**: `(scheduleId, scheduledStartTime)`

---

### 15. UserSettings Table ❌

App configuration and user preferences.

> **Note**: User settings are currently stored via `SharedPreferences` (not a database table) for simple key-value persistence. See `lib/presentation/providers/settings_providers.dart`. This table specification is reserved for future complex preferences that may require relational storage.

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

### 16. Notifications Table ✅

Stores scheduled and delivered notifications for activities, goals, etc.

```dart
class Notifications extends Table {
  // Primary key
  TextColumn get id => text()();

  // Type of notification (activity reminder, schedule change, etc.)
  IntColumn get type => intEnum<NotificationType>()();

  // Title of the notification
  TextColumn get title => text()();

  // Optional body/description
  TextColumn get body => text().nullable()();

  // Reference to related activity (optional)
  TextColumn get activityId => text().nullable()();  // Currently: eventId

  // Reference to related goal (optional)
  TextColumn get goalId => text().nullable()();

  // When the notification should be delivered
  DateTimeColumn get scheduledAt => dateTime()();

  // When the notification was actually delivered
  DateTimeColumn get deliveredAt => dateTime().nullable()();

  // When the notification was read
  DateTimeColumn get readAt => dateTime().nullable()();

  // Current status of the notification
  IntColumn get status => intEnum<NotificationStatus>().withDefault(const Constant(0))();

  // Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Indexes** (added in schema v11):
```dart
@TableIndex(name: 'idx_notifications_scheduled', columns: {#scheduledAt})
@TableIndex(name: 'idx_notifications_status', columns: {#status})
@TableIndex(name: 'idx_notifications_activity', columns: {#activityId})  // Currently: idx_notifications_event
```

**Note**: Added in schema version 8.

---

## Enums

### TimingType

```dart
enum TimingType {
  fixed,    // Event has specific start/end time
  flexible  // Event has duration but no fixed time
}
```

### ActivityStatus

> **Naming Note**: Currently implemented as `EventStatus` in codebase. Will be renamed to `ActivityStatus` as part of the Activity Model Refactor.

```dart
enum ActivityStatus {  // Currently: EventStatus
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
  location,  // Time spent at a location (added in v12)
  activity,  // Specific recurring activity by title (added in v12, renamed from 'event')
  custom     // Custom goal (future)
}
```

### GoalMetric

```dart
enum GoalMetric {
  hours,         // Track hours
  activities,    // Track number of activities (renamed from 'events')
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

### NotificationType

```dart
enum NotificationType {
  activityReminder,   // Reminder before an activity starts (renamed from eventReminder)
  scheduleChange,     // Alert when schedule changes occur
  goalProgress,       // Notification about goal progress
  conflictWarning,    // Warning about scheduling conflicts
  goalAtRisk,         // Alert when a goal is at risk of not being met
  goalCompleted       // Notification when a goal is completed
}
```

### NotificationStatus

```dart
enum NotificationStatus {
  pending,     // Notification is pending delivery
  delivered,   // Notification has been delivered to the user
  read,        // Notification has been read by the user
  dismissed,   // Notification was dismissed by the user
  cancelled    // Notification was cancelled (e.g., event deleted before reminder)
}
```

---

## Database Class Definition

The following shows the actual implemented database schema (version 11):

> **Note**: Table and class names will be renamed as part of the Activity Model Refactor. Current names are shown with planned names in comments.

```dart
@DriftDatabase(
  tables: [
    Categories,
    Activities,     // Currently: Events
    Goals,
    People,
    ActivityPeople, // Currently: EventPeople
    Locations,
    RecurrenceRules,
    Notifications,
    TravelTimePairs,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  
  @override
  int get schemaVersion => 10;
  
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
      await _seedDefaultCategories();
    },
    beforeOpen: (details) async {
      // Enable foreign key constraints (required for cascade deletes)
      await customStatement('PRAGMA foreign_keys = ON');
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Migration from version 1 to 2: Add Goals table
      if (from == 1) {
        await m.createTable(goals);
      }
      // Migration from version 2 to 3: Add People table
      if (from <= 2) {
        await m.createTable(people);
      }
      // Migration from version 3 to 4: Add ActivityPeople junction table (currently EventPeople)
      if (from <= 3) {
        await m.createTable(activityPeople);  // Currently: eventPeople
      }
      // Migration from version 4 to 5: Add Locations table
      if (from <= 4) {
        await m.createTable(locations);
      }
      // Migration from version 5 to 6: Add locationId column to Activities table (currently Events)
      if (from <= 5) {
        await m.addColumn(activities, activities.locationId);  // Currently: events, events.locationId
      }
      // Migration from version 6 to 7: Add RecurrenceRules table and recurrenceRuleId column to Activities
      if (from <= 6) {
        await m.createTable(recurrenceRules);
        await m.addColumn(activities, activities.recurrenceRuleId);  // Currently: events
      }
      // Migration from version 7 to 8: Add Notifications table
      if (from <= 7) {
        await m.createTable(notifications);
      }
      // Migration from version 8 to 9: Add personId column to Goals table for relationship goals
      if (from <= 8) {
        await m.addColumn(goals, goals.personId);
      }
      // Migration from version 9 to 10: Add TravelTimePairs table for manual travel time entry
      if (from <= 9) {
        await m.createTable(travelTimePairs);
      }
      // Migration from version 10 to 11: Add indexes for query performance optimization
      if (from <= 10) {
        // Activities indexes (currently Events)
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_activities_start_time ON activities (start_time)');  // Currently: idx_events_start_time ON events
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_activities_end_time ON activities (end_time)');  // Currently: idx_events_end_time ON events
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_activities_category ON activities (category_id)');  // Currently: idx_events_category ON events
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_activities_status ON activities (status)');  // Currently: idx_events_status ON events
        // Goals indexes
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_goals_category ON goals (category_id)');
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_goals_person ON goals (person_id)');
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_goals_active ON goals (is_active)');
        // Notifications indexes
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications (scheduled_at)');
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications (status)');
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS idx_notifications_activity ON notifications (activity_id)');  // Currently: idx_notifications_event ON notifications (event_id)
      }
    },
  );
  
  Future<void> _seedDefaultCategories() async {
    // Insert default categories
  }
}
```

---

## Key Queries

### Get Activities for Date Range

```dart
Future<List<Activity>> getActivitiesForDateRange(DateTime start, DateTime end) {  // Currently: getEventsForDateRange
  return (select(activities)  // Currently: events
    ..where((a) =>   // Currently: (e) =>
      a.startTime.isBiggerOrEqualValue(start) &
      a.startTime.isSmallerThanValue(end))
    ..orderBy([(a) => OrderingTerm.asc(a.startTime)]))
    .get();
}
```

### Get Activities by Status

```dart
Stream<List<Activity>> watchActivitiesByStatus(ActivityStatus status) {  // Currently: watchEventsByStatus(EventStatus)
  return (select(activities)  // Currently: events
    ..where((a) => a.status.equals(status.index))
    ..orderBy([(a) => OrderingTerm.asc(a.startTime)]))
    .watch();
}
```

### Get Activities with Category

```dart
Future<List<ActivityWithCategory>> getActivitiesWithCategory() {  // Currently: getEventsWithCategory
  final query = select(activities).join([  // Currently: events
    leftOuterJoin(categories, categories.id.equalsExp(activities.categoryId)),  // Currently: events.categoryId
  ]);
  
  return query.map((row) {
    return ActivityWithCategory(  // Currently: EventWithCategory
      activity: row.readTable(activities),  // Currently: event: row.readTable(events)
      category: row.readTableOrNull(categories),
    );
  }).get();
}
```

### Get Goal Progress

```dart
Future<GoalProgressSummary> getGoalProgress(String goalId, DateTime periodStart) {
  // Join goals, activities, and activity_goals to calculate actual progress
}
```

---

## Indexes

```dart
// Activities table (currently Events)
@TableIndex(name: 'activities_start_time_idx', columns: {#startTime})  // Currently: events_start_time_idx
@TableIndex(name: 'activities_status_idx', columns: {#status})  // Currently: events_status_idx
@TableIndex(name: 'activities_category_idx', columns: {#categoryId})  // Currently: events_category_idx
@TableIndex(name: 'activities_series_idx', columns: {#seriesId})  // NEW - for series lookups

// ScheduledActivities table (currently ScheduledEvents)
@TableIndex(name: 'scheduled_activities_schedule_idx', columns: {#scheduleId, #scheduledStartTime})  // Currently: scheduled_events_schedule_idx

// GoalProgress table
@TableIndex(name: 'goal_progress_goal_period_idx', columns: {#goalId, #periodStart})
```

---

## Data Integrity Rules

### Cascade Deletes

- Deleting an Activity cascades to ActivityConstraints, ActivityPeople, ActivityGoals, ScheduledActivities
- Deleting a Category does NOT cascade (sets activity.categoryId to null)
- Deleting a Goal cascades to ActivityGoals and GoalProgress
- Deleting a Schedule cascades to ScheduledActivities

### Validation Rules

**Activities**:
- Must have at least one of: title, person (via ActivityPeople), locationId, categoryId
- Fixed activities must have startTime and endTime
- Flexible activities must have durationMinutes
- endTime must be after startTime (if both present)
- durationMinutes must be > 0 and <= 1440 (24 hours)

**Goals**:
- targetValue must be > 0
- Must have categoryId, personId, locationId, or activityTitle (depending on type)

**RecurrenceRules**:
- interval must be >= 1
- If endType is afterOccurrences, occurrences must be > 0
- If endType is onDate, endDate must be in future

---

## Domain Model Mapping

### Activity Entity

> **Naming Note**: Currently implemented as `Event` in codebase. Will be renamed to `Activity` as part of the Activity Model Refactor.

```dart
class Activity {  // Currently: Event
  final String id;
  final String? title;  // NOW NULLABLE
  final String? description;
  final TimingType timingType;
  final ActivityStatus status;  // Currently: EventStatus
  
  // Time (null for unscheduled activities)
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
  final String? seriesId;  // NEW - for grouping related activities
  
  // Computed properties
  Duration get duration {
    if (timingType == TimingType.fixed && startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    if (durationMinutes != null) {
      return Duration(minutes: durationMinutes!);
    }
    throw StateError('Cannot compute duration for activity');
  }
  
  bool get isFixed => timingType == TimingType.fixed;
  bool get isFlexible => timingType == TimingType.flexible;
  bool get isSchedulable => isFlexible && !isLocked;
  bool get isScheduled => startTime != null;  // NEW - scheduled vs unscheduled
  bool get isUnscheduled => startTime == null;  // NEW - for activity bank
  
  /// Display title for UI (handles nullable title)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    // Populated by repository with related entity names
    return _computedDisplayTitle ?? 'Untitled Activity';
  }
}
```

### Repository Responsibilities

Repositories handle:
- Mapping between database models and domain entities
- Validation before insert/update (including the new "at least one property" rule)
- Computing derived fields (including displayTitle with related entities)
- Handling cascade logic
- Exposing streams for reactive UI

Example:
```dart
class ActivityRepository {  // Currently: EventRepository
  final AppDatabase _db;
  
  // Convert database model to domain entity
  Activity _toEntity(ActivityData data) { ... }  // Currently: Event _toEntity(EventData data)
  
  // Convert domain entity to database model
  ActivitiesCompanion _toCompanion(Activity entity) { ... }  // Currently: EventsCompanion _toCompanion(Event entity)
  
  // Validation (NEW - Activity Model Refactor)
  void _validate(Activity activity, {List<String>? personIds}) {
    final hasTitle = activity.title != null && activity.title!.isNotEmpty;
    final hasPerson = personIds != null && personIds.isNotEmpty;
    final hasLocation = activity.locationId != null;
    final hasCategory = activity.categoryId != null;
    
    if (!hasTitle && !hasPerson && !hasLocation && !hasCategory) {
      throw ValidationException('Activity must have at least one of: title, person, location, or category');
    }
  }
  
  // CRUD operations
  Future<Activity> create(Activity activity, {List<String>? personIds}) async {
    _validate(activity, personIds: personIds);
    final id = await _db.into(_db.activities).insert(_toCompanion(activity));
    return activity;
  }
  
  Stream<List<Activity>> watchAll() {
    return _db.select(_db.activities).watch().map(
      (rows) => rows.map(_toEntity).toList()
    );
  }
  
  // NEW - Get unscheduled activities (activity bank)
  Stream<List<Activity>> watchUnscheduled() {
    return (_db.select(_db.activities)
      ..where((a) => a.startTime.isNull()))
      .watch()
      .map((rows) => rows.map(_toEntity).toList());
  }
  
  // NEW - Find activities by series
  Future<List<Activity>> getBySeriesId(String seriesId) async {
    final results = await (_db.select(_db.activities)
      ..where((a) => a.seriesId.equals(seriesId)))
      .get();
    return results.map(_toEntity).toList();
  }
}
```

---

## Migration Strategy

### Version 1 (Initial Schema)
- Events, Categories tables created
- Default categories seeded

### Version 2
- Added Goals table

### Version 3
- Added People table

### Version 4
- Added EventPeople junction table

### Version 5
- Added Locations table

### Version 6
- Added locationId column to Events table

### Version 7
- Added RecurrenceRules table
- Added recurrenceRuleId column to Events table

### Version 8
- Added Notifications table

### Version 9
- Added personId column to Goals table (for relationship goals)

### Version 10
- Added TravelTimePairs table

### Version 11
- Added database indexes for query performance optimization:
  - Events table: idx_events_start_time, idx_events_end_time, idx_events_category, idx_events_status
  - Goals table: idx_goals_category, idx_goals_person, idx_goals_active
  - Notifications table: idx_notifications_scheduled, idx_notifications_status, idx_notifications_event

### Version 12 (Current - Phase 9A)
- Added locationId column to Goals table (for location-based goals)
- Added eventTitle column to Goals table (for event-based goals)
- Added idx_goals_location index on Goals table
- Extended GoalType enum with `location` and `event` types

### Important: Foreign Key Support

SQLite doesn't enable foreign key constraints by default. To enable cascade deletes and other foreign key features, the database must execute `PRAGMA foreign_keys = ON` on every connection using the `beforeOpen` callback:

```dart
beforeOpen: (details) async {
  await customStatement('PRAGMA foreign_keys = ON');
},
```

### Future Migrations

When adding fields:
```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (Migrator m) async {
    await m.createAll();
    await _seedDefaultCategories();
  },
  beforeOpen: (details) async {
    // Enable foreign key constraints (required for cascade deletes)
    await customStatement('PRAGMA foreign_keys = ON');
  },
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

*Last updated: 2026-01-26 (Activity Model Refactor documentation)*
