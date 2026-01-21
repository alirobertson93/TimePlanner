# Project Roadmap

**Last Updated**: 2026-01-21

This document is the single source of truth for the project's current status, completed work, and upcoming phases. For session logs and development history, see [CHANGELOG.md](./CHANGELOG.md).

## Current Status

**Project Phase**: Phase 6 In Progress - Social & Location Features

**Overall Progress**: ~96% Complete

**Active Work**: Phase 6 - People Management implementation

## Completed Phases

### Phase 1: Foundation ✅ (Complete)

**Status**: 100% Complete

**What's Working**:
- ✅ Project structure established with clean architecture
- ✅ Flutter dependencies configured (Riverpod, Drift, go_router)
- ✅ Database setup with Drift/SQLite
- ✅ Basic domain entities and enums
- ✅ Code generation working (build_runner)
- ✅ Comprehensive documentation suite created
  - DEVELOPER_GUIDE.md, PRD.md, DATA_MODEL.md
  - ALGORITHM.md, ARCHITECTURE.md, TESTING.md
  - UX_FLOWS.md, WIREFRAMES.md, CHANGELOG.md

**Key Files Added**:
- Core project structure in `lib/`
- All documentation in `dev-docs/`
- Initial test infrastructure

### Phase 2: Core Functionality ✅ (Complete)

**Status**: 100% Complete

**What's Working**:

**Database Layer**:
- ✅ Events table with fixed/flexible timing support
- ✅ Categories table with default seed data
- ✅ Goals table with full schema
- ✅ People table with Phase 6
- ✅ EventRepository with CRUD operations
- ✅ CategoryRepository with CRUD operations
- ✅ GoalRepository with CRUD operations and comprehensive tests
- ✅ PersonRepository with CRUD operations and tests
- ✅ Database migration system (v1 → v2 → v3)

**Domain Model**:
- ✅ Event entity with validation logic
- ✅ Category entity
- ✅ Goal entity with all properties
- ✅ Person entity with contact info
- ✅ Core enums (TimingType, EventStatus)
- ✅ Goal enums (GoalType, GoalMetric, GoalPeriod, DebtStrategy)

**Scheduler Foundation** (Pure Dart):
- ✅ TimeSlot model with 15-minute granularity
- ✅ AvailabilityGrid for tracking occupied slots
- ✅ ScheduleRequest/ScheduleResult models
- ✅ ScheduledEvent and Conflict models
- ✅ SchedulingStrategy interface
- ✅ BalancedStrategy implementation
- ✅ EventScheduler main class
- ✅ Comprehensive unit tests (80%+ coverage for implemented parts)

**UI Layer**:
- ✅ Day View screen with 24-hour scrollable timeline
- ✅ DayTimeline widget with hour markers
- ✅ EventCard widget for displaying events
- ✅ TimeMarker and CurrentTimeIndicator widgets
- ✅ Event detail bottom sheet (DraggableScrollableSheet)
- ✅ Navigation between days (previous/today/next)
- ✅ Event providers with Riverpod
- ✅ Routing setup with go_router

**Key Achievements**:
- Pure Dart scheduler (no Flutter dependencies) enables thorough testing
- 15-minute time slot granularity established as standard
- Repository pattern fully implemented
- Clean architecture maintained across all layers

### Phase 3: Event Management UI ✅ (Complete)

**Status**: 100% Complete

**What's Working**:
- ✅ Event Form screen with full UI
- ✅ Event Form provider with state management
- ✅ Form validation (title required, time validation, duration validation)
- ✅ Fixed time and flexible event type support
- ✅ Category dropdown with color indicators
- ✅ Navigation routes for create/edit
- ✅ FAB integration in Day View
- ✅ Edit button wired up in Event Detail Sheet
- ✅ Delete functionality with confirmation dialog
- ✅ Category colors displayed in event cards
- ✅ Week View with 7-day grid display
- ✅ Navigation between Day View and Week View
- ✅ Event blocks with category colors in Week View

**Goals**:
- Create complete event form for creating/editing events
- Implement week view for broader schedule visibility
- Add category color coding to event cards
- Improve event management workflows

**Features**:
- [x] Event Form (create/edit)
  - [x] All event fields (title, description, category, timing, duration)
  - [x] Time-bound vs duration-based toggle
  - [x] Form validation
  - [ ] Constraint picker (movable, resizable, locked) - deferred to Phase 4
- [x] Week View
  - [x] 7-day grid display with day headers
  - [x] Event blocks with category colors
  - [x] Quick navigation (previous/next week, today)
  - [x] Day tap navigates to Day View
  - [x] Event tap navigates to Day View for that event
- [x] Category Colors
  - [x] Color display in category dropdown
  - [ ] Color picker in category management
  - [x] Color coding in event cards
  - [x] Consistent color usage across views
- [x] Event Management
  - [x] Create new events via FAB
  - [x] Edit existing events
  - [x] Delete events with confirmation
  - [ ] Quick event creation flow (deferred)

**Next Steps**:
1. Run build_runner to generate provider code
2. Test all Week View functionality
3. Test navigation between Day View and Week View
4. Begin Phase 4 Planning Wizard

**Dependencies**: None (Phase 2 complete)

### Phase 4: Planning Wizard ✅ (Complete)

**Status**: 100% Complete

**What's Working**:
- ✅ Planning Wizard 4-step flow
  - ✅ Step 1: Date range selection with quick select buttons
  - ✅ Step 2: Goals review with checkboxes
  - ✅ Step 3: Strategy selection (Balanced, with Coming Soon placeholders)
  - ✅ Step 4: Schedule preview with detailed results
- ✅ Schedule Generation Integration
  - ✅ Connect UI to EventScheduler
  - ✅ Display generated schedule grouped by day
  - ✅ Show conflicts and unscheduled events
  - ✅ Accept/reject workflow
- ✅ Schedule Review
  - ✅ Visual schedule preview
  - ✅ Summary cards (scheduled, unscheduled, conflicts)
  - ✅ Conflict highlighting
  - ✅ Events listed by day with times
- ✅ Navigation
  - ✅ /plan route added
  - ✅ Plan Week button in Day View
  - ✅ Success navigation to Week View

**Key Files Added**:
- lib/presentation/providers/planning_wizard_providers.dart
- lib/presentation/screens/planning_wizard/planning_wizard_screen.dart
- lib/presentation/screens/planning_wizard/steps/date_range_step.dart
- lib/presentation/screens/planning_wizard/steps/goals_review_step.dart
- lib/presentation/screens/planning_wizard/steps/strategy_selection_step.dart
- lib/presentation/screens/planning_wizard/steps/plan_review_step.dart

**Next Steps**:
1. Run build_runner to generate provider code
2. Test all Planning Wizard functionality
3. Begin Phase 5 Advanced Scheduling

**Dependencies**: Phase 3 (complete)

## In Progress Phases

### Phase 5: Advanced Scheduling ✅ (Complete)

**Target**: After Phase 4

**Status**: 100% Complete

**Goals**:
- Implement additional scheduling strategies
- Create Goals Dashboard for tracking
- Enhance scheduling algorithm

**What's Working**:
- ✅ FrontLoadedStrategy (important work early in week)
- ✅ MaxFreeTimeStrategy (maximize contiguous free blocks)
- ✅ LeastDisruptionStrategy (minimize schedule changes)
- ✅ Updated Planning Wizard to use all strategies
- ✅ Unit tests for all new strategies
- ✅ Goals Dashboard with progress tracking
- ✅ Goal progress calculation from events
- ✅ Visual progress indicators with status
- ✅ Navigation to Goals Dashboard from Day View
- ✅ Goal Creation Form with full UI
- ✅ Goal Editing with pre-populated form
- ✅ Goal Deletion with confirmation dialog
- ✅ Tap-to-edit goal cards in dashboard

**Features**:
- [x] Additional Scheduling Strategies
  - [x] FrontLoadedStrategy (important work early in week)
  - [x] MaxFreeTimeStrategy (maximize contiguous free blocks)
  - [x] LeastDisruptionStrategy (minimize schedule changes)
- [x] Goals Dashboard
  - [x] Visual progress indicators
  - [x] Weekly/monthly goal tracking
  - [x] Goal progress calculation
  - [x] Alerts for goals at risk
  - [x] Goal creation form
  - [x] Goal editing
  - [x] Goal deletion
- [ ] Algorithm Enhancements (deferred to future)
  - [x] Goal progress calculation in scheduler
  - [ ] Time-of-day preferences
  - [ ] Multi-pass optimization
  - [ ] Performance optimizations

**Key Files Added**:
- lib/scheduler/strategies/front_loaded_strategy.dart
- lib/scheduler/strategies/max_free_time_strategy.dart
- lib/scheduler/strategies/least_disruption_strategy.dart
- lib/presentation/providers/goal_providers.dart
- lib/presentation/providers/goal_form_providers.dart
- lib/presentation/screens/goals_dashboard/goals_dashboard_screen.dart
- lib/presentation/screens/goal_form/goal_form_screen.dart
- test/scheduler/front_loaded_strategy_test.dart
- test/scheduler/max_free_time_strategy_test.dart
- test/scheduler/least_disruption_strategy_test.dart

**Next Steps**:
1. Run build_runner to generate provider code
2. Test Goal Form functionality
3. Begin Phase 6 Social & Location Features

**Dependencies**: Phase 4 (complete)

## In Progress Phases

### Phase 6: Social & Location Features 🟡 (In Progress)

**Target**: Mid-development

**Status**: 50% Complete

**Goals**:
- Add People and Location entities
- Support travel time calculations
- Enable relationship goal tracking

**What's Working**:
- ✅ Person entity with contact info
- ✅ People database table
- ✅ PersonRepository with CRUD operations
- ✅ PersonRepository tests
- ✅ Database migration (v2 → v3 → v4)
- ✅ Person provider for Riverpod
- ✅ EventPeople junction table for many-to-many relationships
- ✅ EventPeopleRepository with full CRUD
- ✅ EventPeopleRepository tests
- ✅ People Management Screen (CRUD)
- ✅ PeoplePicker widget for events
- ✅ Person providers for UI
- ✅ /people route in router
- ✅ People button in Day View

**Features**:
- [x] People Management
  - [x] People table and repository
  - [x] Person entity with contact info
  - [x] EventPeople junction table
  - [x] EventPeople repository
  - [x] People Management Screen
  - [x] People picker UI widget
  - [ ] Integrate people picker into Event Form
- [ ] Location Management
  - [ ] Locations table and repository
  - [ ] Location entity with address
  - [ ] Associate locations with events
  - [ ] Location picker UI
- [ ] Travel Time
  - [ ] Calculate travel time between locations
  - [ ] Auto-schedule travel buffer
  - [ ] Travel time in schedule generation
- [ ] Relationship Goals
  - [ ] Goals tied to specific people
  - [ ] Track time with each person
  - [ ] Relationship goal progress

**Key Files Added**:
- lib/domain/entities/person.dart
- lib/data/database/tables/people.dart
- lib/data/database/tables/event_people.dart
- lib/data/repositories/person_repository.dart
- lib/data/repositories/event_people_repository.dart
- lib/presentation/providers/person_providers.dart
- lib/presentation/screens/people/people_screen.dart
- lib/presentation/widgets/people_picker.dart
- test/repositories/person_repository_test.dart
- test/repositories/event_people_repository_test.dart

**Next Steps**:
1. Run build_runner to generate database and provider code
2. Test People Management functionality
3. Integrate PeoplePicker into Event Form
4. Begin Location Management implementation

**Dependencies**: Phase 5 (Goals Dashboard foundation) - complete

**Estimated Effort**: 3-4 development sessions remaining

## Upcoming Phases

### Phase 7: Advanced Features (Low Priority)

**Target**: Late development

**Goals**:
- Add recurring event support
- Implement notifications
- Create settings/preferences screen

**Features**:
- [ ] Recurrence
  - [ ] RecurrenceRules table
  - [ ] Recurring event UI
  - [ ] Recurrence patterns (daily, weekly, monthly)
  - [ ] Exception handling
- [ ] Notifications
  - [ ] Event reminders
  - [ ] Schedule change alerts
  - [ ] Goal progress notifications
  - [ ] Conflict warnings
- [ ] Settings
  - [ ] User preferences
  - [ ] Time slot granularity
  - [ ] Default constraints
  - [ ] Notification preferences
  - [ ] Theme settings

**Dependencies**: Phase 6 (complete core functionality)

**Estimated Effort**: 3-4 development sessions

### Phase 8: Polish & Launch (Low Priority)

**Target**: Pre-release

**Goals**:
- Add onboarding experience
- Optimize performance
- Ensure accessibility
- Prepare for launch

**Features**:
- [ ] Onboarding
  - [ ] Welcome wizard
  - [ ] Feature tutorials
  - [ ] Sample data setup
  - [ ] First-time user guidance
- [ ] Performance
  - [ ] Profiling and optimization
  - [ ] Database query optimization
  - [ ] UI rendering optimization
  - [ ] Large dataset testing
- [ ] Accessibility
  - [ ] Screen reader support
  - [ ] Color contrast verification
  - [ ] Touch target sizing
  - [ ] Keyboard navigation
- [ ] Launch Preparation
  - [ ] App store assets
  - [ ] Marketing materials
  - [ ] Beta testing program
  - [ ] User documentation
  - [ ] Privacy policy
  - [ ] Terms of service

**Dependencies**: All previous phases

**Estimated Effort**: 4-6 development sessions

## Component Completion Summary

| Component | Status | Completion | Notes |
|-----------|--------|------------|-------|
| **Database Layer** | 🟢 Active | 85% | Events, Categories, Goals, People, EventPeople complete. Locations, Recurrence pending |
| **Domain Entities** | 🟢 Active | 80% | Core entities + Person done. Location pending |
| **Repositories** | 🟢 Active | 85% | Event, Category, Goal, Person, EventPeople repos complete with tests |
| **Scheduler Engine** | 🟢 Complete | 100% | All 4 strategies implemented (Balanced, FrontLoaded, MaxFreeTime, LeastDisruption) |
| **Day View** | 🟢 Complete | 100% | Timeline, events, navigation, category colors, Week View link, Plan button, Goals button, People button |
| **Week View** | 🟢 Complete | 100% | 7-day grid, event blocks, category colors, navigation |
| **Event Form** | 🟢 Complete | 100% | Create, edit, delete implemented |
| **Planning Wizard** | 🟢 Complete | 100% | 4-step flow, schedule generation, all strategies available |
| **Goals Dashboard** | 🟢 Complete | 100% | Progress tracking, status indicators, category grouping, goal CRUD |
| **Goal Form** | 🟢 Complete | 100% | Create, edit, delete with validation |
| **People Management** | 🟡 Partial | 75% | Entity, tables, repositories, providers, UI complete. Event form integration pending |
| **Location Management** | ⚪ Planned | 0% | Not started (Phase 6) |
| **Recurrence** | ⚪ Planned | 0% | Not started (Phase 7) |
| **Notifications** | ⚪ Planned | 0% | Not started (Phase 7) |
| **Settings** | ⚪ Planned | 0% | Not started (Phase 7) |
| **Onboarding** | ⚪ Planned | 0% | Not started (Phase 8) |

**Legend**:
- 🟢 Active: Currently working or recently completed
- 🟡 Partial: Some work done, needs completion
- ⚪ Planned: Not started, planned for future phase

## Blockers

**Current Blockers**: None

**Potential Future Blockers**:
- None identified at this time

## Notes

### Development Velocity
- Phase 1: ~1 session (documentation)
- Phase 2: ~1 session (core implementation)
- Estimated: 2-3 sessions per phase going forward

### Key Decisions
- 15-minute time slots as atomic unit
- Pure Dart scheduler (no Flutter dependencies)
- Repository pattern for data layer
- Offline-first architecture
- Clean architecture with strict layer separation

### Success Criteria
Before considering the project "complete":
- [ ] All 8 phases finished
- [ ] Test coverage >80% for business logic
- [ ] All critical user flows working end-to-end
- [ ] Performance targets met (schedule generation <2s)
- [ ] Accessibility requirements met (WCAG 2.1 AA)
- [ ] Beta testing with 10+ users

---

*For session logs and detailed development history, see [CHANGELOG.md](./CHANGELOG.md)*

*Last updated: 2026-01-21*
