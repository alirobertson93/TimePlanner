# Phase 2 Implementation - Setup Instructions

## Overview

Phase 2 of TimePlanner has been successfully implemented, including:
- ✅ Goals System (database, repository, tests)
- ✅ Scheduler Foundation (pure Dart, with unit tests)
- ✅ Day View UI (timeline, widgets, navigation)

This document outlines the steps needed to complete the setup and test the implementation.

---

## Required Setup Steps

### 1. Run Code Generation

The database schema has been updated to version 2 with the Goals table. You need to run Drift's code generator:

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `lib/data/database/app_database.g.dart` - Database implementation
- `lib/presentation/providers/event_providers.g.dart` - Riverpod providers

**Expected Output**: Code generation should complete successfully with no errors.

---

### 2. Run Tests

#### Repository Tests (requires Flutter)
```bash
flutter test test/repositories/goal_repository_test.dart
flutter test test/repositories/event_repository_test.dart
flutter test test/repositories/category_repository_test.dart
```

**Expected**: All repository tests should pass.

#### Scheduler Tests (pure Dart, no Flutter)
```bash
dart test test/scheduler/
```

**Expected**: All scheduler tests should pass, confirming pure Dart implementation with no Flutter dependencies.

---

### 3. Verify the Implementation

Run the app and test the Day View:

```bash
flutter run
```

**What to Test**:

1. **Home Screen**:
   - Tap "View Day" button
   - Should navigate to Day View screen

2. **Day View Screen**:
   - Should display 24-hour timeline (midnight to midnight)
   - Should show hour markers (12 AM, 1 AM, ..., 11 PM)
   - Navigation arrows should move between days
   - "Today" button should return to current date
   - Current time indicator (red line) should appear on today's view
   - FAB should show "Event creation coming soon" snackbar

3. **Event Display** (if you have events):
   - Fixed events should appear at their scheduled times
   - Events should be proportional to their duration
   - Tapping an event should open the detail bottom sheet

4. **Event Detail Sheet**:
   - Should show event name, time, duration, status, type
   - Should show description if present
   - Edit and Delete buttons should be present (not yet functional)

---

## What's Included

### Database Layer

**New Files**:
- `lib/domain/enums/goal_type.dart` - GoalType enum
- `lib/domain/enums/goal_metric.dart` - GoalMetric enum
- `lib/domain/enums/goal_period.dart` - GoalPeriod enum
- `lib/domain/enums/debt_strategy.dart` - DebtStrategy enum
- `lib/domain/entities/goal.dart` - Goal entity
- `lib/data/database/tables/goals.dart` - Goals table definition
- `lib/data/repositories/goal_repository.dart` - GoalRepository

**Modified Files**:
- `lib/data/database/app_database.dart` - Added Goals table, schema v2, migration

**Tests**:
- `test/repositories/goal_repository_test.dart` - Comprehensive tests

---

### Scheduler Foundation (Pure Dart)

**New Files**:
- `lib/scheduler/models/time_slot.dart` - 15-minute time slot
- `lib/scheduler/models/availability_grid.dart` - Tracks slot availability
- `lib/scheduler/models/schedule_request.dart` - Scheduling input
- `lib/scheduler/models/schedule_result.dart` - Scheduling output
- `lib/scheduler/models/scheduled_event.dart` - Scheduled event
- `lib/scheduler/models/conflict.dart` - Conflict representation
- `lib/scheduler/strategies/scheduling_strategy.dart` - Strategy interface
- `lib/scheduler/strategies/balanced_strategy.dart` - BalancedStrategy
- `lib/scheduler/event_scheduler.dart` - Main scheduler

**Tests**:
- `test/scheduler/time_slot_test.dart` - TimeSlot tests
- `test/scheduler/availability_grid_test.dart` - AvailabilityGrid tests
- `test/scheduler/balanced_strategy_test.dart` - BalancedStrategy tests

**Key Features**:
- ✅ Pure Dart (no Flutter dependencies)
- ✅ 15-minute slot granularity
- ✅ BalancedStrategy distributes events evenly
- ✅ Conflict detection
- ✅ Fixed and flexible event placement

---

### Day View UI

**New Files**:
- `lib/presentation/providers/event_providers.dart` - Event providers
- `lib/presentation/screens/day_view/day_view_screen.dart` - Main screen
- `lib/presentation/screens/day_view/widgets/day_timeline.dart` - Timeline widget
- `lib/presentation/screens/day_view/widgets/event_card.dart` - Event card
- `lib/presentation/screens/day_view/widgets/time_marker.dart` - Hour marker
- `lib/presentation/screens/day_view/widgets/current_time_indicator.dart` - Current time line
- `lib/presentation/screens/day_view/widgets/event_detail_sheet.dart` - Event details

**Modified Files**:
- `lib/app/router.dart` - Added /day route
- `lib/presentation/screens/home_screen.dart` - Navigation to day view
- `lib/presentation/providers/repository_providers.dart` - Added goalRepository

**Key Features**:
- ✅ Scrollable 24-hour timeline
- ✅ Hour markers (12 AM - 11 PM)
- ✅ Event cards proportional to duration
- ✅ Current time indicator (red line)
- ✅ Navigation between days
- ✅ Event detail bottom sheet
- ✅ FAB for adding events (placeholder)

---

## Architecture Compliance

The implementation follows the architecture specified in ARCHITECTURE.md:

✅ **Pure Dart Scheduler**: No Flutter dependencies in `lib/scheduler/`
✅ **Repository Pattern**: Data access through repositories only
✅ **Riverpod State Management**: Providers for state and dependencies
✅ **Clean Architecture**: Clear layer separation (domain, data, scheduler, presentation)
✅ **15-Minute Time Slots**: As per ALGORITHM.md specification

---

## Known Limitations

1. **Code Generation Not Run**: Requires Flutter environment to generate `.g.dart` files
2. **Tests Not Executed**: Cannot run in this environment, needs local Flutter setup
3. **Event Creation**: UI placeholder only, form not yet implemented
4. **Category Colors**: Events use default blue color, category color mapping pending
5. **Flexible Events**: Only fixed events shown in timeline, flexible events need scheduling UI

---

## Next Steps (Post-Setup)

After verifying the implementation:

1. **Implement Event Form**: Create/edit event UI
2. **Add Category Colors**: Map event cards to category colors
3. **Week View**: Multi-day timeline view
4. **Planning Wizard**: UI for schedule generation
5. **Additional Strategies**: FrontLoaded, MaxFreeTime, LeastDisruption
6. **Goal Dashboard**: UI for managing goals
7. **Integration**: Connect scheduler to UI for generating schedules

---

## Troubleshooting

### Code Generation Errors

If you see errors about missing `.g.dart` files:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Test Failures

If tests fail:
1. Ensure code generation completed successfully
2. Check that all dependencies are installed (`flutter pub get`)
3. Review test output for specific errors

### UI Issues

If Day View doesn't display correctly:
1. Check that code generation completed (event_providers.g.dart)
2. Verify router is properly configured
3. Check console for errors

---

## Support

For issues or questions:
- Review ARCHITECTURE.md for design patterns
- Check ALGORITHM.md for scheduler specifications
- See TESTING.md for test strategies
- Refer to DATA_MODEL.md for database schema

---

*Last Updated: 2026-01-16*
