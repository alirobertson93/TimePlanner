# Project Roadmap

**Last Updated**: 2026-01-17

This document is the single source of truth for the project's current status, completed work, and upcoming phases. For session logs and development history, see [CHANGELOG.md](./CHANGELOG.md).

## Current Status

**Project Phase**: Phase 3 Complete - Event Management UI

**Overall Progress**: ~70% Complete

**Active Work**: Phase 3 complete, ready for Phase 4 Planning Wizard

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
- ✅ EventRepository with CRUD operations
- ✅ CategoryRepository with CRUD operations
- ✅ GoalRepository with CRUD operations and comprehensive tests
- ✅ Database migration system (v1 → v2)

**Domain Model**:
- ✅ Event entity with validation logic
- ✅ Category entity
- ✅ Goal entity with all properties
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

## Upcoming Phases

### Phase 4: Planning Wizard (High Priority) 🎯

**Target**: Next Development Phase

**Goals**:
- Create 4-step planning wizard for weekly schedule generation
- Integrate scheduler with UI
- Provide schedule review and acceptance workflow

**Features**:
- [ ] Planning Wizard UI
  - [ ] Step 1: Date range selection (default: next 7 days)
  - [ ] Step 2: Goals review and adjustment
  - [ ] Step 3: Strategy selection (Balanced, Front-Loaded, etc.)
  - [ ] Step 4: Schedule preview and acceptance
- [ ] Schedule Generation Integration
  - [ ] Connect UI to EventScheduler
  - [ ] Display generated schedule
  - [ ] Show conflicts and unscheduled events
  - [ ] Accept/reject workflow
- [ ] Schedule Review
  - [ ] Visual schedule preview
  - [ ] Goal progress indicators
  - [ ] Conflict highlighting
  - [ ] Option to regenerate with different strategy

**Dependencies**: Phase 3 (Event Form needed for adjustments)

**Estimated Effort**: 3-4 development sessions

### Phase 5: Advanced Scheduling (Medium Priority)

**Target**: After Phase 4

**Goals**:
- Implement additional scheduling strategies
- Create Goals Dashboard for tracking
- Enhance scheduling algorithm

**Features**:
- [ ] Additional Scheduling Strategies
  - [ ] FrontLoadedStrategy (important work early in week)
  - [ ] MaxFreeTimeStrategy (maximize contiguous free blocks)
  - [ ] LeastDisruptionStrategy (minimize schedule changes)
- [ ] Goals Dashboard
  - [ ] Visual progress indicators
  - [ ] Weekly/monthly goal tracking
  - [ ] Goal completion trends
  - [ ] Alerts for goals at risk
- [ ] Algorithm Enhancements
  - [ ] Goal progress calculation in scheduler
  - [ ] Time-of-day preferences
  - [ ] Multi-pass optimization
  - [ ] Performance optimizations

**Dependencies**: Phase 4 (needs working wizard)

**Estimated Effort**: 3-4 development sessions

### Phase 6: Social & Location Features (Medium Priority)

**Target**: Mid-development

**Goals**:
- Add People and Location entities
- Support travel time calculations
- Enable relationship goal tracking

**Features**:
- [ ] People Management
  - [ ] People table and repository
  - [ ] Person entity with contact info
  - [ ] Associate people with events
  - [ ] People picker UI
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

**Dependencies**: Phase 5 (Goals Dashboard foundation)

**Estimated Effort**: 4-5 development sessions

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
| **Database Layer** | 🟢 Active | 70% | Events, Categories, Goals complete. People, Locations, Recurrence pending |
| **Domain Entities** | 🟢 Active | 60% | Core entities done. Person, Location pending |
| **Repositories** | 🟢 Active | 60% | Event, Category, Goal repos complete with tests |
| **Scheduler Engine** | 🟡 Partial | 60% | Core + BalancedStrategy done. 3 more strategies pending |
| **Day View** | 🟢 Complete | 100% | Timeline, events, navigation, category colors, Week View link |
| **Week View** | 🟢 Complete | 100% | 7-day grid, event blocks, category colors, navigation |
| **Event Form** | 🟢 Complete | 100% | Create, edit, delete implemented |
| **Planning Wizard** | ⚪ Planned | 0% | Not started (Phase 4) |
| **Goals Dashboard** | ⚪ Planned | 0% | Not started (Phase 5) |
| **People Management** | ⚪ Planned | 0% | Not started (Phase 6) |
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

*Last updated: 2026-01-17*
