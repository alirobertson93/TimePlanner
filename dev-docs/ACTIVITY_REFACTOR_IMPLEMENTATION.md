# Activity Model Refactor - Implementation Guide

## Overview

This document provides a comprehensive implementation guide for the Activity Model Refactor. The refactor establishes a unified "Activity" model, replacing the previous "Event" terminology, and introduces several new features including series support, optional titles, and an activity bank concept.

**Created**: 2026-01-26

**Related Documentation**:
- `DATA_MODEL.md` - Database schema with Activity terminology
- `UX_FLOWS.md` - User flows including series prompts
- `ARCHITECTURE.md` - Code organization with renamed files
- `ALGORITHM.md` - Scheduling algorithm with activity bank integration

---

## Key Concepts

### What is an Activity?

An Activity is any item the user wants to track or schedule. An Activity can be:
- **Scheduled** - Has a specific date/time, appears on the calendar
- **Unscheduled** - No date/time, exists in an "activity bank" for planning

Both are the same entity type - the difference is simply whether time properties are populated.

### Activity Bank

The activity bank contains unscheduled activities waiting to be placed on the calendar. The Planning Wizard draws from this bank when generating schedules.

### Activity Series

A series groups related activities together using a `seriesId` field, independent of recurrence. This allows users to edit multiple related activities at once.

---

## Phase 1: Terminology Refactor

### 1.1 Database Changes

**Tables to Rename** (with migration):

| Current Name | New Name |
|--------------|----------|
| `Events` | `Activities` |
| `EventPeople` | `ActivityPeople` |

**Columns to Rename**:

| Table | Current Column | New Column |
|-------|---------------|------------|
| `Goals` | `eventTitle` | `activityTitle` |
| `Notifications` | `eventId` | `activityId` |
| `ActivityPeople` | `eventId` | `activityId` |

**Migration SQL**:
```sql
-- Rename Events table to Activities
ALTER TABLE events RENAME TO activities;

-- Rename EventPeople table to ActivityPeople  
ALTER TABLE event_people RENAME TO activity_people;

-- Rename columns (SQLite requires table recreation)
-- Create new table with correct column names, copy data, drop old table
```

### 1.2 Entity & Repository Renames

| Current Path | New Path |
|--------------|----------|
| `lib/domain/entities/event.dart` | `lib/domain/entities/activity.dart` |
| `lib/domain/enums/event_status.dart` | `lib/domain/enums/activity_status.dart` |
| `lib/data/repositories/event_repository.dart` | `lib/data/repositories/activity_repository.dart` |
| `lib/data/repositories/event_people_repository.dart` | `lib/data/repositories/activity_people_repository.dart` |
| `lib/presentation/providers/event_providers.dart` | `lib/presentation/providers/activity_providers.dart` |
| `lib/presentation/providers/event_form_providers.dart` | `lib/presentation/providers/activity_form_providers.dart` |
| `lib/presentation/screens/event_form/event_form_screen.dart` | `lib/presentation/screens/activity_form/activity_form_screen.dart` |
| `lib/presentation/screens/event_detail/event_detail_screen.dart` | `lib/presentation/screens/activity_detail/activity_detail_screen.dart` |
| `lib/scheduler/event_scheduler.dart` | `lib/scheduler/activity_scheduler.dart` |
| `lib/scheduler/models/scheduled_event.dart` | `lib/scheduler/models/scheduled_activity.dart` |

### 1.3 Enum Updates

```dart
// lib/domain/enums/activity_status.dart
enum ActivityStatus {  // Renamed from EventStatus
  pending,
  inProgress,
  completed,
  cancelled,
}

// lib/domain/enums/goal_type.dart
enum GoalType {
  category,
  person,
  location,
  activity,  // Renamed from 'event'
  custom,
}
```

### 1.4 Goal Entity Updates

```dart
// lib/domain/entities/goal.dart
class Goal {
  // ... existing fields ...
  
  // Renamed from eventTitle
  final String? activityTitle;
  
  // Updated method name
  Future<Goal?> getByActivityTitle(String title);  // Renamed from getByEventTitle
}
```

### 1.5 UI String Updates

Files with hardcoded "event" strings to update:

| File | Strings to Update |
|------|-------------------|
| `lib/presentation/screens/day_view/day_view_screen.dart` | "No events", "Add Event" |
| `lib/presentation/screens/event_form/event_form_screen.dart` | "New Event", "Edit Event" |
| `lib/presentation/screens/planning_wizard/steps/*.dart` | "events scheduled", etc. |
| `lib/presentation/screens/onboarding/*.dart` | "Recurring Events", etc. |
| `lib/presentation/widgets/event_card.dart` | Widget name and semantics |

### 1.6 Testing

- Update all test files with Activity terminology
- Run full test suite to verify no regressions
- Add tests for renamed repository methods

---

## Phase 2: Optional Title + Display Logic

### 2.1 Make Title Nullable

```dart
// lib/domain/entities/activity.dart
class Activity {
  final String? title;  // Changed from String
  // ...
}
```

**Database Migration**:
```sql
-- SQLite doesn't support ALTER COLUMN, need to recreate table
-- The title column already allows NULL in current schema
```

### 2.2 Add Validation

**Validation Rule**: Activity must have at least one of:
- `title` (non-empty)
- Person (via ActivityPeople junction)
- `locationId`
- `categoryId`

**Where to Enforce**:

1. **Entity Level** (soft validation):
```dart
// lib/domain/entities/activity.dart
class Activity {
  bool isValid({List<String>? personIds}) {
    final hasTitle = title != null && title!.isNotEmpty;
    final hasPerson = personIds != null && personIds.isNotEmpty;
    final hasLocation = locationId != null;
    final hasCategory = categoryId != null;
    
    return hasTitle || hasPerson || hasLocation || hasCategory;
  }
}
```

2. **Repository Level** (hard validation):
```dart
// lib/data/repositories/activity_repository.dart
Future<void> create(Activity activity, {List<String>? personIds}) async {
  _validateMinimumProperties(activity, personIds: personIds);
  // ... create activity
}

void _validateMinimumProperties(Activity activity, {List<String>? personIds}) {
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
```

3. **Form Level** (UI validation):
```dart
// lib/presentation/screens/activity_form/activity_form_screen.dart
bool _validateForm() {
  final state = ref.read(activityFormProvider);
  final people = ref.read(selectedPeopleProvider);
  
  return state.title?.isNotEmpty == true ||
         people.isNotEmpty ||
         state.locationId != null ||
         state.categoryId != null;
}
```

### 2.3 Implement displayTitle

**Option A: Computed Property in Entity** (requires related entity access):
```dart
// lib/domain/entities/activity.dart
class Activity {
  // Injected by repository when loading
  String? _personName;
  String? _locationName;
  String? _categoryName;
  
  String get displayTitle {
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    
    final parts = <String>[
      if (_personName != null) _personName!,
      if (_locationName != null) _locationName!,
      if (_categoryName != null) _categoryName!,
    ];
    
    return parts.isNotEmpty ? parts.join(' · ') : 'Untitled Activity';
  }
}
```

**Option B: DisplayTitleService** (cleaner separation):
```dart
// lib/domain/services/display_title_service.dart
class DisplayTitleService {
  String getDisplayTitle(
    Activity activity, {
    Person? person,
    Location? location,
    Category? category,
  }) {
    if (activity.title != null && activity.title!.isNotEmpty) {
      return activity.title!;
    }
    
    final parts = <String>[
      if (person != null) person.name,
      if (location != null) location.name,
      if (category != null) category.name,
    ];
    
    return parts.isNotEmpty ? parts.join(' · ') : 'Untitled Activity';
  }
}
```

### 2.4 Update UI Components

Files that display activity titles:

| File | Update Required |
|------|-----------------|
| `lib/presentation/screens/day_view/widgets/activity_card.dart` | Use displayTitle |
| `lib/presentation/screens/week_view/widgets/activity_block.dart` | Use displayTitle |
| `lib/presentation/screens/activity_detail/*.dart` | Use displayTitle |
| `lib/presentation/screens/planning_wizard/steps/plan_review_step.dart` | Use displayTitle |
| `lib/presentation/screens/goals/goals_dashboard.dart` | Use displayTitle for activity goals |

### 2.5 Testing

```dart
// test/domain/entities/activity_test.dart
group('displayTitle', () {
  test('returns title when present', () {
    final activity = Activity(title: 'Meeting');
    expect(activity.displayTitle, equals('Meeting'));
  });
  
  test('returns person name when title is null', () {
    final activity = Activity(title: null, _personName: 'John');
    expect(activity.displayTitle, equals('John'));
  });
  
  test('concatenates multiple properties', () {
    final activity = Activity(
      title: null, 
      _personName: 'John',
      _locationName: 'Office',
    );
    expect(activity.displayTitle, equals('John · Office'));
  });
  
  test('returns default when no properties', () {
    final activity = Activity(title: null);
    expect(activity.displayTitle, equals('Untitled Activity'));
  });
});

group('validation', () {
  test('valid with title only', () {
    final activity = Activity(title: 'Test');
    expect(activity.isValid(), isTrue);
  });
  
  test('valid with category only', () {
    final activity = Activity(title: null, categoryId: 'cat-1');
    expect(activity.isValid(), isTrue);
  });
  
  test('invalid with no properties', () {
    final activity = Activity(title: null);
    expect(activity.isValid(), isFalse);
  });
});
```

---

## Phase 3: Series Support

### 3.1 Add seriesId Field

**Entity Change**:
```dart
// lib/domain/entities/activity.dart
class Activity {
  // ... existing fields ...
  
  /// Groups related activities together (independent of recurrence)
  final String? seriesId;
  
  Activity({
    // ... existing params ...
    this.seriesId,
  });
}
```

**Database Migration**:
```sql
-- Add seriesId column to Activities table
ALTER TABLE activities ADD COLUMN series_id TEXT;

-- Add index for series lookups
CREATE INDEX idx_activities_series ON activities (series_id);
```

**Repository Update**:
```dart
// lib/data/repositories/activity_repository.dart
class ActivityRepository {
  Future<List<Activity>> getBySeriesId(String seriesId) async {
    final results = await (_db.select(_db.activities)
      ..where((a) => a.seriesId.equals(seriesId)))
      .get();
    return results.map(_toEntity).toList();
  }
  
  Future<int> countInSeries(String seriesId) async {
    final count = countAll(activities, where: (a) => a.seriesId.equals(seriesId));
    return await count.getSingle();
  }
}
```

### 3.2 Create SeriesMatchingService

```dart
// lib/domain/services/series_matching_service.dart
class SeriesMatchingService {
  final IActivityRepository _activityRepository;
  final IActivityPeopleRepository _activityPeopleRepository;
  
  SeriesMatchingService(this._activityRepository, this._activityPeopleRepository);
  
  /// Find existing series that match the given activity
  Future<List<ActivitySeries>> findMatchingSeries(Activity activity) async {
    final allActivities = await _activityRepository.getAll();
    final matchesBySeriesId = <String, List<Activity>>{};
    
    for (final existing in allActivities) {
      if (existing.id == activity.id) continue;
      
      if (await _isMatch(activity, existing)) {
        final seriesId = existing.seriesId ?? existing.id;
        matchesBySeriesId.putIfAbsent(seriesId, () => []).add(existing);
      }
    }
    
    return matchesBySeriesId.entries.map((e) => ActivitySeries(
      id: e.key,
      activities: e.value,
      displayTitle: e.value.first.displayTitle,
      count: e.value.length,
    )).toList();
  }
  
  /// Check if two activities match (should be in same series)
  Future<bool> _isMatch(Activity a, Activity b) async {
    // Rule 1: Same title (case-insensitive)
    if (a.title != null && b.title != null &&
        a.title!.toLowerCase() == b.title!.toLowerCase()) {
      return true;
    }
    
    // Rule 2: 2+ matching properties (person, location, category)
    int matchCount = 0;
    
    if (a.categoryId != null && a.categoryId == b.categoryId) {
      matchCount++;
    }
    
    if (a.locationId != null && a.locationId == b.locationId) {
      matchCount++;
    }
    
    // Check person match (requires junction table lookup)
    final aPeople = await _activityPeopleRepository.getPeopleForActivity(a.id);
    final bPeople = await _activityPeopleRepository.getPeopleForActivity(b.id);
    if (aPeople.any((p) => bPeople.contains(p))) {
      matchCount++;
    }
    
    return matchCount >= 2;
  }
}

/// Represents a group of related activities
class ActivitySeries {
  final String id;
  final List<Activity> activities;
  final String displayTitle;
  final int count;
  
  ActivitySeries({
    required this.id,
    required this.activities,
    required this.displayTitle,
    required this.count,
  });
}
```

### 3.3 Series Prompt UI

```dart
// lib/presentation/widgets/series_prompt_dialog.dart
class SeriesPromptDialog extends StatelessWidget {
  final ActivitySeries matchingSeries;
  final VoidCallback onAddToSeries;
  final VoidCallback onKeepStandalone;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('This looks similar to an existing activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '"${matchingSeries.displayTitle}" (${matchingSeries.count} previous times)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          _buildOption(
            context,
            title: 'Add to this series',
            subtitle: 'Changes to shared properties will apply to all activities in the series',
            onTap: onAddToSeries,
          ),
          const SizedBox(height: 8),
          _buildOption(
            context,
            title: 'Keep as standalone',
            subtitle: "This activity won't be linked to any others",
            onTap: onKeepStandalone,
          ),
        ],
      ),
    );
  }
}
```

**Integration Points**:
1. Activity form save → check for matches → show prompt
2. Planning wizard schedule → check for matches → show prompt

### 3.4 Edit Scope Prompt UI

```dart
// lib/presentation/widgets/edit_scope_dialog.dart
enum EditScope {
  thisOnly,
  allInSeries,
  thisAndFuture,  // Only for recurring activities
}

class EditScopeDialog extends StatelessWidget {
  final Activity activity;
  final int seriesCount;
  final bool isRecurring;
  final Function(EditScope) onScopeSelected;
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('This activity is part of a series ($seriesCount total)'),
          const SizedBox(height: 16),
          const Text('What would you like to edit?'),
          const SizedBox(height: 16),
          RadioListTile<EditScope>(
            title: const Text('This activity only'),
            value: EditScope.thisOnly,
            groupValue: _selectedScope,
            onChanged: _onChanged,
          ),
          RadioListTile<EditScope>(
            title: const Text('All activities in this series'),
            value: EditScope.allInSeries,
            groupValue: _selectedScope,
            onChanged: _onChanged,
          ),
          if (isRecurring)
            RadioListTile<EditScope>(
              title: const Text('This and all future activities'),
              value: EditScope.thisAndFuture,
              groupValue: _selectedScope,
              onChanged: _onChanged,
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => onScopeSelected(_selectedScope),
          child: const Text('Continue'),
        ),
      ],
    );
  }
}
```

### 3.5 Bulk Edit Logic

```dart
// lib/domain/services/series_edit_service.dart
class SeriesEditService {
  final IActivityRepository _activityRepository;
  
  /// Update all activities in a series with new values
  Future<void> updateSeries({
    required String seriesId,
    required Map<String, dynamic> updates,
    required Set<String> propertiesToSync,
  }) async {
    final activities = await _activityRepository.getBySeriesId(seriesId);
    
    for (final activity in activities) {
      final updatedActivity = _applyUpdates(activity, updates, propertiesToSync);
      await _activityRepository.update(updatedActivity);
    }
  }
  
  /// Detect which properties vary across activities in a series
  Future<Map<String, List<dynamic>>> detectVariance(String seriesId) async {
    final activities = await _activityRepository.getBySeriesId(seriesId);
    final variance = <String, Set<dynamic>>{};
    
    for (final activity in activities) {
      _addToVariance(variance, 'duration', activity.durationMinutes);
      _addToVariance(variance, 'location', activity.locationId);
      _addToVariance(variance, 'category', activity.categoryId);
      // ... other properties
    }
    
    // Return only properties that have multiple different values
    return Map.fromEntries(
      variance.entries
        .where((e) => e.value.length > 1)
        .map((e) => MapEntry(e.key, e.value.toList()))
    );
  }
}
```

### 3.6 Testing

```dart
// test/domain/services/series_matching_service_test.dart
group('SeriesMatchingService', () {
  test('matches activities with same title', () async {
    final service = SeriesMatchingService(mockRepo, mockPeopleRepo);
    
    final newActivity = Activity(title: 'Cinema');
    final existingActivity = Activity(title: 'cinema', seriesId: 'series-1');
    
    when(mockRepo.getAll()).thenAnswer((_) async => [existingActivity]);
    
    final matches = await service.findMatchingSeries(newActivity);
    
    expect(matches, hasLength(1));
    expect(matches.first.id, equals('series-1'));
  });
  
  test('matches activities with 2+ property matches', () async {
    final newActivity = Activity(categoryId: 'cat-1', locationId: 'loc-1');
    final existingActivity = Activity(categoryId: 'cat-1', locationId: 'loc-1');
    
    // ... test implementation
  });
  
  test('does not match with only 1 property match', () async {
    final newActivity = Activity(categoryId: 'cat-1');
    final existingActivity = Activity(categoryId: 'cat-1', locationId: 'loc-2');
    
    // ... test implementation
  });
});
```

---

## Phase 4: Onboarding Wizard Updates

### 4.1 Step 2: Recurring Activities

**Change**: Rename "Recurring Fixed Events" to "Recurring Activities"

```dart
// lib/presentation/screens/onboarding/enhanced_onboarding_screen.dart
Widget _buildRecurringActivitiesPage() {
  return OnboardingPage(
    title: 'Recurring Activities',  // Changed from "Recurring Fixed Events"
    description: 'Add activities that happen at the same time each week',
    icon: Icons.repeat,
    // ... rest unchanged
  );
}
```

### 4.2 Step 4: Unscheduled Activities

**Change**: Create Activity entities (not just Goals)

**Current Behavior**:
- Creates Goal entities only

**New Behavior**:
- Creates Activity entities WITHOUT dates/times (activity bank)
- Optionally creates associated Goals for these activities

```dart
// lib/presentation/screens/onboarding/steps/activities_step.dart
class ActivitiesStepScreen extends ConsumerWidget {
  Widget _buildAddActivityDialog() {
    return AlertDialog(
      title: const Text('Add Unscheduled Activity'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Activity Name'),
            controller: _nameController,
          ),
          DurationPicker(
            label: 'Default Duration',
            onChanged: (duration) => _defaultDuration = duration,
          ),
          CategoryDropdown(
            onChanged: (category) => _selectedCategory = category,
          ),
          const Divider(),
          const Text('Time Goal (Optional)'),
          Row(
            children: [
              HoursDropdown(onChanged: (hours) => _targetHours = hours),
              PeriodDropdown(onChanged: (period) => _period = period),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveActivity,
          child: const Text('Add'),
        ),
      ],
    );
  }
  
  Future<void> _saveActivity() async {
    // Create unscheduled Activity (no startTime/endTime)
    final activity = Activity(
      id: const Uuid().v4(),
      title: _nameController.text,
      durationMinutes: _defaultDuration?.inMinutes,
      categoryId: _selectedCategory?.id,
      timingType: TimingType.flexible,
      status: ActivityStatus.pending,
      // startTime and endTime are null - this goes to activity bank
    );
    
    await ref.read(activityRepositoryProvider).create(activity);
    
    // Optionally create associated Goal
    if (_targetHours != null && _targetHours! > 0) {
      final goal = Goal(
        id: const Uuid().v4(),
        type: GoalType.activity,
        activityTitle: _nameController.text,
        targetValue: _targetHours!,
        metric: GoalMetric.hours,
        period: _period ?? GoalPeriod.week,
        // ...
      );
      
      await ref.read(goalRepositoryProvider).create(goal);
    }
  }
}
```

### 4.3 Testing

```dart
// test/presentation/screens/onboarding/activities_step_test.dart
testWidgets('creates unscheduled activity', (tester) async {
  await tester.pumpWidget(/* ... */);
  
  await tester.tap(find.text('Add Activity'));
  await tester.pumpAndSettle();
  
  await tester.enterText(find.byType(TextField).first, 'Exercise');
  await tester.tap(find.text('Add'));
  await tester.pumpAndSettle();
  
  // Verify activity created without dates
  verify(mockActivityRepo.create(argThat(
    predicate((a) => 
      a.title == 'Exercise' && 
      a.startTime == null && 
      a.endTime == null
    )
  ))).called(1);
});
```

---

## Phase 5: Planning Wizard Updates

### 5.1 Query Both Activity Types

```dart
// lib/presentation/providers/planning_wizard_providers.dart
@riverpod
Future<List<Activity>> availableActivities(AvailableActivitiesRef ref, DateTimeRange range) async {
  final repo = ref.watch(activityRepositoryProvider);
  
  // Get unscheduled activities (activity bank)
  final unscheduled = await repo.getUnscheduled();
  
  // Get previously scheduled activities in range (for rescheduling)
  final scheduled = await repo.getForDateRange(range.start, range.end);
  
  // Get recurring activities expanded for range
  final recurrenceService = ref.watch(recurrenceServiceProvider);
  final recurring = await recurrenceService.expandForRange(range.start, range.end);
  
  // Combine and deduplicate
  return [...unscheduled, ...scheduled, ...recurring].toSet().toList();
}
```

### 5.2 Ranking by Goal Contribution

```dart
// lib/scheduler/utils/activity_ranker.dart
class ActivityRanker {
  final List<Goal> activeGoals;
  
  /// Score activities by how much they contribute to active goals
  double scoreActivity(Activity activity) {
    double score = 0;
    
    for (final goal in activeGoals) {
      if (_activityContributesToGoal(activity, goal)) {
        // Weight by goal progress (activities that help catch up score higher)
        final progress = goal.currentProgress / goal.targetValue;
        final catchUpBonus = progress < 0.5 ? 2.0 : (progress < 0.8 ? 1.5 : 1.0);
        score += catchUpBonus;
      }
    }
    
    return score;
  }
  
  bool _activityContributesToGoal(Activity activity, Goal goal) {
    switch (goal.type) {
      case GoalType.category:
        return activity.categoryId == goal.categoryId;
      case GoalType.person:
        return _activityHasPerson(activity, goal.personId);
      case GoalType.location:
        return activity.locationId == goal.locationId;
      case GoalType.activity:
        return activity.title?.toLowerCase() == goal.activityTitle?.toLowerCase();
      case GoalType.custom:
        return false;
    }
  }
  
  /// Sort activities by score (highest first)
  List<Activity> rankActivities(List<Activity> activities) {
    return activities..sort((a, b) => 
      scoreActivity(b).compareTo(scoreActivity(a))
    );
  }
}
```

### 5.3 Series Integration

```dart
// lib/presentation/providers/planning_wizard_providers.dart
Future<void> scheduleActivity(Activity activity, TimeSlot slot) async {
  final seriesService = ref.read(seriesMatchingServiceProvider);
  
  // Check for series matches
  final matches = await seriesService.findMatchingSeries(activity);
  
  String? seriesId;
  if (matches.isNotEmpty) {
    // Show series prompt
    final result = await showDialog<SeriesPromptResult>(
      context: context,
      builder: (_) => SeriesPromptDialog(
        matchingSeries: matches.first,
        // ...
      ),
    );
    
    if (result == SeriesPromptResult.addToSeries) {
      seriesId = matches.first.id;
    }
  }
  
  // Create new scheduled Activity record
  final scheduledActivity = activity.copyWith(
    id: const Uuid().v4(),  // New ID - it's a new record
    startTime: slot.start,
    endTime: slot.end,
    seriesId: seriesId,
  );
  
  await ref.read(activityRepositoryProvider).create(scheduledActivity);
}
```

### 5.4 Testing

```dart
// test/presentation/providers/planning_wizard_providers_test.dart
group('Planning Wizard with Activity Bank', () {
  test('includes unscheduled activities in available activities', () async {
    final unscheduled = [
      Activity(id: '1', title: 'Exercise', startTime: null),
      Activity(id: '2', title: 'Reading', startTime: null),
    ];
    
    when(mockRepo.getUnscheduled()).thenAnswer((_) async => unscheduled);
    
    final result = await container.read(
      availableActivitiesProvider(DateTimeRange(...)).future
    );
    
    expect(result, containsAll(unscheduled));
  });
  
  test('shows series prompt when scheduling matching activity', () async {
    // ... test implementation
  });
});
```

---

## Migration Guide

### Database Migrations

**Migration to Schema Version 14**:
```dart
// lib/data/database/app_database.dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (Migrator m, int from, int to) async {
    // ... existing migrations ...
    
    // Migration to v14: Activity Model Refactor
    if (from <= 13) {
      // 1. Rename tables
      await m.database.customStatement('ALTER TABLE events RENAME TO activities');
      await m.database.customStatement('ALTER TABLE event_people RENAME TO activity_people');
      
      // 2. Add seriesId column
      await m.addColumn(activities, activities.seriesId);
      
      // 3. Add index for series lookups
      await m.database.customStatement(
        'CREATE INDEX IF NOT EXISTS idx_activities_series ON activities (series_id)'
      );
      
      // 4. Update Goals table (rename eventTitle to activityTitle)
      // SQLite doesn't support column rename, so we need to recreate
      await _recreateGoalsTableWithRenamedColumn(m);
      
      // 5. Update Notifications table (rename eventId to activityId)
      await _recreateNotificationsTableWithRenamedColumn(m);
    }
  },
);
```

### Breaking Changes

1. **Entity Renames**: All code referencing `Event` class must be updated to `Activity`
2. **Provider Renames**: All providers with `event` in name must be updated
3. **Repository Method Changes**: `eventTitle` → `activityTitle`, `getByEventTitle()` → `getByActivityTitle()`
4. **Title Now Nullable**: Code assuming non-null title must handle null case

### Rollback Plan

If issues are encountered:
1. Keep old table structure with aliases during transition
2. Maintain backwards-compatible provider names temporarily
3. Database migration includes backup of original tables

---

## File Reference

### Files to Rename

| Current Path | New Path |
|--------------|----------|
| `lib/domain/entities/event.dart` | `lib/domain/entities/activity.dart` |
| `lib/domain/enums/event_status.dart` | `lib/domain/enums/activity_status.dart` |
| `lib/data/repositories/event_repository.dart` | `lib/data/repositories/activity_repository.dart` |
| `lib/data/repositories/event_people_repository.dart` | `lib/data/repositories/activity_people_repository.dart` |
| `lib/presentation/providers/event_providers.dart` | `lib/presentation/providers/activity_providers.dart` |
| `lib/presentation/providers/event_form_providers.dart` | `lib/presentation/providers/activity_form_providers.dart` |
| `lib/presentation/screens/event_form/` | `lib/presentation/screens/activity_form/` |
| `lib/presentation/screens/event_detail/` | `lib/presentation/screens/activity_detail/` |
| `lib/scheduler/event_scheduler.dart` | `lib/scheduler/activity_scheduler.dart` |
| `lib/scheduler/models/scheduled_event.dart` | `lib/scheduler/models/scheduled_activity.dart` |

### Files to Modify (no rename)

| Path | Changes |
|------|---------|
| `lib/domain/entities/goal.dart` | `eventTitle` → `activityTitle`, add `getByActivityTitle()` |
| `lib/domain/enums/goal_type.dart` | `GoalType.event` → `GoalType.activity` |
| `lib/data/database/app_database.dart` | Table renames, add seriesId column |
| `lib/presentation/screens/day_view/*.dart` | Update "event" strings to "activity" |
| `lib/presentation/screens/week_view/*.dart` | Update "event" strings to "activity" |
| `lib/presentation/screens/planning_wizard/*.dart` | Update terminology, add activity bank integration |
| `lib/presentation/screens/onboarding/*.dart` | Step 2 rename, Step 4 create activities |
| All UI files | Update hardcoded "event"/"Event" strings |

### New Files to Create

| Path | Purpose |
|------|---------|
| `lib/domain/services/series_matching_service.dart` | Series matching logic |
| `lib/domain/services/series_edit_service.dart` | Bulk edit logic for series |
| `lib/domain/services/display_title_service.dart` | Compute display title for activities |
| `lib/presentation/widgets/series_prompt_dialog.dart` | Series selection UI |
| `lib/presentation/widgets/edit_scope_dialog.dart` | Edit scope selection UI |
| `lib/presentation/providers/series_matching_providers.dart` | Series matching state |

---


## Checklist Summary

### Phase 1: Terminology Refactor
- [ ] Database table renames (Events → Activities, EventPeople → ActivityPeople)
- [x] Entity class renames - created Activity entity with backward compatibility
- [ ] Repository renames (file renames pending - currently using compatibility)
- [ ] Provider renames (file renames pending - currently using compatibility)
- [ ] Screen and widget renames (file renames pending)
- [x] Enum updates (ActivityStatus created, GoalType.event → GoalType.activity, GoalMetric.events → GoalMetric.activities)
- [x] Goal entity updates (eventTitle → activityTitle)
- [x] UI string updates (major screens updated)
- [ ] Test updates

### Phase 2: Optional Title + Display Logic
- [ ] Make Activity.title nullable
- [ ] Add validation rule (at least one property required)
- [ ] Implement displayTitle computed property
- [ ] Update UI to use displayTitle
- [ ] Add tests for validation and displayTitle

### Phase 3: Series Support
- [x] Add seriesId field to Activity - added to entity and database
- [x] Create SeriesMatchingService
- [x] Create series prompt dialog
- [x] Create edit scope dialog
- [x] Implement bulk edit logic
- [ ] Integrate with activity form
- [x] Add tests for series functionality

### Phase 4: Onboarding Wizard Updates
- [x] Rename Step 2 to "Recurring Activities"
- [ ] Refactor Step 4 to create unscheduled Activities
- [ ] Add optional goal creation for activities
- [ ] Update onboarding tests

### Phase 5: Planning Wizard Updates
- [ ] Query both scheduled and unscheduled activities
- [ ] Implement goal-based activity ranking
- [ ] Integrate series matching when scheduling
- [ ] Update planning wizard tests

---

## Implementation Progress

**Session: 2026-01-26 (Phase 10B Implementation - Optional Title + Display Logic)**

Added support for optional activity titles with display title fallback:

### Phase 10B Completed Work:

1. **Made Activity.name Nullable** (`lib/domain/entities/activity.dart`):
   - Changed `name` from `String` to `String?`
   - Added `hasName`, `hasLocation`, `hasCategory` computed properties
   - Added `isValid()` validation method for minimum property requirements

2. **Made Event.name Nullable** (`lib/domain/entities/event.dart`):
   - Changed `name` from `String` to `String?` for consistency
   - Added `hasName` computed property

3. **Created DisplayTitleService** (`lib/domain/services/display_title_service.dart`):
   - `getDisplayTitle()` - Computes full display title from associated entities
   - `getShortDisplayTitle()` - Compact title for week view blocks
   - Priority order: name → people → location → category → "Untitled Activity"
   - Concatenates multiple properties with " · " separator

4. **Created DisplayTitle Provider** (`lib/presentation/providers/display_title_providers.dart`):
   - `displayTitleServiceProvider` - Riverpod provider for the service

5. **Updated Database Schema** (v15):
   - Made `name` column nullable in Events table
   - Migration strategy prepared

6. **Updated UI Components**:
   - `EventCard` - Now fetches people, location, category to compute displayTitle
   - `EventDetailSheet` - Uses displayTitle for title, delete confirmation, lock messages
   - `WeekTimeline` - Uses getShortDisplayTitle for compact event blocks
   - `PlanReviewStep` - Added null-safe handling for event names

7. **Created Tests**:
   - `test/domain/entities/activity_test.dart` - Activity validation tests
   - `test/domain/services/display_title_service_test.dart` - DisplayTitleService tests

### Files Changed:
- `lib/domain/entities/activity.dart` - Nullable name, validation methods
- `lib/domain/entities/event.dart` - Nullable name for consistency
- `lib/domain/services/display_title_service.dart` - **NEW**
- `lib/data/database/tables/events.dart` - Nullable name column
- `lib/data/database/app_database.dart` - Schema v15
- `lib/presentation/providers/display_title_providers.dart` - **NEW**
- `lib/presentation/screens/day_view/widgets/event_card.dart`
- `lib/presentation/screens/day_view/widgets/event_detail_sheet.dart`
- `lib/presentation/screens/week_view/widgets/week_timeline.dart`
- `lib/presentation/screens/planning_wizard/steps/plan_review_step.dart`
- `lib/presentation/providers/event_form_providers.dart`
- `lib/scheduler/models/scheduled_event.dart`

---

**Session: 2026-01-26 (Phase 10A Implementation)**

Significant progress made on Phase 10A - Terminology Refactor:

### Completed Work:
1. **Created Activity Entity** (`lib/domain/entities/activity.dart`):
   - New unified Activity class with seriesId field
   - isScheduled/isUnscheduled computed properties
   - Full copyWith, equality, and hashCode implementations

2. **Created ActivityStatus Enum** (`lib/domain/enums/activity_status.dart`):
   - Renamed from EventStatus with same values

3. **Updated Event Entity for Backward Compatibility**:
   - Added seriesId field
   - Added toActivity() conversion method
   - Added Event.fromActivity() factory constructor

4. **Updated Goal Entity**:
   - Renamed eventTitle → activityTitle

5. **Updated Goal Type Enum**:
   - Renamed GoalType.event → GoalType.activity

6. **Updated Goal Metric Enum**:
   - Renamed GoalMetric.events → GoalMetric.activities

7. **Updated Database**:
   - Added seriesId column to Events table
   - Added idx_events_series index
   - Schema version bumped to 14

8. **Updated Repositories**:
   - EventRepository: Added getBySeriesId(), countInSeries()
   - GoalRepository: Renamed getByEventTitle() → getByActivityTitle()

9. **Updated Domain Services**:
   - HistoricalEventService: Updated pattern types
   - GoalRecommendationService: Updated terminology
   - GoalWarningService: Updated terminology

10. **Updated Providers**:
    - All goal-related providers updated
    - Historical analysis providers updated

11. **Updated UI Screens**:
    - Day View, Week View, Event Form, Goal Form
    - Planning Wizard steps
    - Onboarding Wizard
    - Settings Screen
    - Goals Dashboard

### Remaining for Full Phase 1 Completion:
- File renames (event.dart → activity.dart as primary, etc.)
- Database table renames (Events → Activities)
- Test file updates
- Run build_runner to regenerate database code

### Note:
The Flutter SDK is required to run build_runner for database code generation. Current changes maintain backward compatibility using the Event entity while introducing Activity.

---

**Session: 2026-01-26 (Phase 10C Implementation - Series Support)**

Implemented series support features for grouping related activities:

### Phase 10C Completed Work:

1. **Created ActivitySeries Model** (`lib/domain/entities/activity_series.dart`):
   - `id` - Unique identifier for the series
   - `activities` - List of activities in the series
   - `displayTitle` - Human-readable title
   - `count` - Number of activities in the series
   - Full copyWith, equality, and hashCode implementations

2. **Created EditScope Enum** (`lib/domain/enums/edit_scope.dart`):
   - `thisOnly` - Edit only this activity
   - `allInSeries` - Edit all activities in the series
   - `thisAndFuture` - Edit this and all future activities
   - Includes `label` and `description` getters

3. **Created SeriesMatchingService** (`lib/domain/services/series_matching_service.dart`):
   - `findMatchingSeries()` - Find existing series matching an activity
   - `hasMatchingSeries()` - Quick check for matches
   - `getSeriesCount()` - Get count of activities in a series
   - Matching rules:
     - Same title (case-insensitive) = automatic match
     - 2+ property matches (category, location, person) = match

4. **Created SeriesEditService** (`lib/domain/services/series_edit_service.dart`):
   - `updateWithScope()` - Update activities based on edit scope
   - `detectVariance()` - Detect varying properties in a series
   - `addToSeries()` - Add an activity to a series
   - `removeFromSeries()` - Remove an activity from a series
   - Handles bulk edits with proper date filtering for "this and future"

5. **Created SeriesPromptDialog** (`lib/presentation/widgets/series_prompt_dialog.dart`):
   - Shows when a new activity matches an existing series
   - Options: "Add to this series" or "Keep as standalone"
   - `showSeriesPromptDialog()` helper function
   - Material Design 3 styling

6. **Created EditScopeDialog** (`lib/presentation/widgets/edit_scope_dialog.dart`):
   - Shows when editing an activity in a series
   - Radio button selection for scope
   - Conditionally shows "This and future" option for recurring activities
   - `showEditScopeDialog()` helper function

7. **Created Series Providers** (`lib/presentation/providers/series_providers.dart`):
   - `seriesMatchingServiceProvider` - Provider for SeriesMatchingService
   - `seriesEditServiceProvider` - Provider for SeriesEditService

8. **Created Tests**:
   - `test/domain/services/series_matching_service_test.dart`:
     - Tests for title matching (case-insensitive)
     - Tests for property matching (2+ properties)
     - Tests for series grouping
     - Tests for ActivitySeries model
   - `test/domain/services/series_edit_service_test.dart`:
     - Tests for updateWithScope (all three scopes)
     - Tests for detectVariance
     - Tests for addToSeries/removeFromSeries
     - Tests for EditScope enum

### Files Created:
- `lib/domain/entities/activity_series.dart` - **NEW**
- `lib/domain/enums/edit_scope.dart` - **NEW**
- `lib/domain/services/series_matching_service.dart` - **NEW**
- `lib/domain/services/series_edit_service.dart` - **NEW**
- `lib/presentation/widgets/series_prompt_dialog.dart` - **NEW**
- `lib/presentation/widgets/edit_scope_dialog.dart` - **NEW**
- `lib/presentation/providers/series_providers.dart` - **NEW**
- `test/domain/services/series_matching_service_test.dart` - **NEW**
- `test/domain/services/series_edit_service_test.dart` - **NEW**

### Remaining for Phase 10C Completion:
- Integrate series prompt into activity form save flow
- Integrate edit scope dialog into activity form edit flow
- Run Flutter tests (requires Flutter SDK)

---

**Session: 2026-01-26 (Phase 10C Integration - Series in Activity Form)**

Integrated series support into the activity form save/edit flow:

### Phase 10C Integration Completed Work:

1. **Updated EventFormState** (`lib/presentation/providers/event_form_providers.dart`):
   - Added `seriesId` field to track series association
   - Added `isInSeries` getter to check if activity is in a series
   - Added `isRecurring` getter to check if activity has recurrence
   - Added `buildActivity()` method to create Activity from form state for series matching
   - Updated `copyWith()` with `seriesId` and `clearSeriesId` parameters
   - Updated `initializeForEdit()` to load seriesId from existing event
   - Updated `save()` to include seriesId when creating Event

2. **Added updateSeriesId Method** (`lib/presentation/providers/event_form_providers.dart`):
   - New method to update or clear the seriesId on the form state
   - Used when user chooses to add activity to a series

3. **Created _saveWithSeriesIntegration Method** (`lib/presentation/screens/event_form/event_form_screen.dart`):
   - Handles save with series integration for both new and existing activities
   - For new activities:
     - Calls SeriesMatchingService to find matching series
     - Shows SeriesPromptDialog if matches found
     - Sets seriesId if user chooses to add to series
   - For existing activities in a series:
     - Gets series count from SeriesMatchingService
     - Shows EditScopeDialog if series has multiple activities
     - Applies edits based on selected scope (thisOnly, allInSeries, thisAndFuture)
     - Uses SeriesEditService for bulk updates

4. **Created _handlePostSave Method** (`lib/presentation/screens/event_form/event_form_screen.dart`):
   - Extracted post-save operations for reuse
   - Handles travel time check and navigation

5. **Updated Save Button** (`lib/presentation/screens/event_form/event_form_screen.dart`):
   - Now calls `_saveWithSeriesIntegration` instead of direct `formNotifier.save()`

6. **Added Imports** (`lib/presentation/screens/event_form/event_form_screen.dart`):
   - Added uuid package for generating activity IDs
   - Added series_providers for SeriesMatchingService and SeriesEditService
   - Added series_prompt_dialog for SeriesPromptDialog
   - Added edit_scope_dialog for EditScopeDialog
   - Added edit_scope enum for EditScope

### Files Modified:
- `lib/presentation/providers/event_form_providers.dart` - Updated with seriesId support
- `lib/presentation/screens/event_form/event_form_screen.dart` - Integrated series dialogs

### Phase 10C Complete:
✅ ActivitySeries model class created
✅ EditScope enum created
✅ SeriesMatchingService created
✅ SeriesEditService created
✅ SeriesPromptDialog UI widget created
✅ EditScopeDialog UI widget created
✅ series_providers.dart with Riverpod providers created
✅ Unit tests for services created
✅ Series prompt integrated into activity form save flow
✅ Edit scope dialog integrated into activity form edit flow

### Remaining:
- Run Flutter tests (requires Flutter SDK)
- Phase 10D: Onboarding Wizard Updates

---

*Last updated: 2026-01-26*
