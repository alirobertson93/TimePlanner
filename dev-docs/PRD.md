# Product Requirements Document (PRD)

## Product Overview

**Product Name**: TimePlanner

**Version**: 1.0

**Last Updated**: 2026-01-20

### Problem Statement

Modern professionals struggle to balance fixed commitments (meetings, appointments) with flexible tasks (deep work, personal projects). Traditional calendar apps treat all events equally and don't help optimize how time is spent across priorities. This leads to:

- Important but flexible work getting perpetually postponed
- Poor visibility into whether goals are being met
- Reactive rather than proactive time management
- Constant context switching and schedule fragmentation

### Solution Overview

TimePlanner is an AI-powered time planning application that intelligently schedules both fixed and flexible events. Unlike traditional calendars, it:

1. **Plans your entire week** based on priorities and constraints
2. **Optimizes for your goals** (e.g., 10 hours/week on deep work)
3. **Handles the complexity** of scheduling flexible tasks around fixed commitments
4. **Adapts to reality** by rescheduling remaining work as you complete tasks
5. **Offers choices** with multiple schedule variations (balanced, front-loaded, etc.)

## User Personas

### Primary: Self-Managing Professional

**Background**:
- Works in knowledge work (software, consulting, creative fields)
- Has autonomy over their schedule
- Mix of fixed meetings (20-40%) and flexible work (60-80%)
- Wants to be intentional about time but struggles with planning

**Goals**:
- Protect time for deep work
- Meet work goals while maintaining life balance
- Reduce decision fatigue about what to work on next
- See realistic plans, not aspirational ones

**Pain Points**:
- Calendar shows meetings but not work blocks
- To-do lists don't account for time availability
- Manually blocking time is tedious and fragile
- Hard to know if goals are achievable given commitments

### Secondary: Freelancer

**Background**:
- Manages multiple clients with varying priorities
- No external structure; creates own schedule
- Needs to balance billable work, admin tasks, and personal life
- Often overcommits and struggles to fit everything in

**Goals**:
- Meet client commitments without overworking
- Maintain consistent work on each client
- Plan realistic work weeks
- Track time toward financial goals

**Pain Points**:
- Underestimates how long tasks take
- Reactive firefighting instead of proactive planning
- Guilty about not working on all clients equally
- Hard to communicate availability to clients

## Technical Stack

### Core Technologies

| Technology | Purpose | Rationale |
|------------|---------|-----------|
| **Flutter** | UI Framework | Cross-platform (iOS, Android, Web), excellent performance, rich ecosystem |
| **Dart** | Language | Type-safe, null-safe, great tooling, required for Flutter |
| **Riverpod** | State Management | Compile-safe, testable, handles async elegantly, recommended for Flutter |
| **Drift** | Database ORM | Type-safe SQLite access, code generation, migrations, reactive queries |
| **go_router** | Navigation | Declarative routing, deep linking, URL-based navigation |

### Supporting Libraries

| Library | Purpose |
|---------|---------|
| **uuid** | Generate unique IDs for entities |
| **intl** | Date/time formatting and internationalization |
| **build_runner** | Code generation for Drift and Riverpod |
| **mocktail** | Testing mocks and stubs |

### Architecture Decisions

**Pure Dart Scheduler**: The scheduling engine is implemented in pure Dart (no Flutter dependencies) to:
- Enable thorough unit testing without Flutter test harness
- Allow potential future reuse (e.g., backend service)
- Enforce separation of business logic from UI

**Offline-First**: All data stored locally in SQLite to:
- Work without internet connection
- Provide instant responsiveness
- Simplify architecture (no API layer needed for MVP)
- Enable future sync capability without breaking changes

**Repository Pattern**: Clear boundary between data and domain layers to:
- Abstract database implementation details
- Make testing easier with mock repositories
- Support future data source changes (e.g., adding cloud sync)

## Feature Requirements

### Priority Tier 0: MVP (Must Have)

**Core Data Model**
- ✅ Activities with fixed/flexible timing
- ✅ Categories for organizing activities
- ✅ Basic constraints (movable, resizable, locked)
- ✅ Activity status tracking
- ⏳ Series support for grouping related activities (Planned - Activity Model Refactor)

**Activity Management**
- Create, edit, delete activities
- Support duration-based and time-bound activities
- Assign categories
- Set timing constraints
- Optional title (with at least one of: title, person, location, category required)

**Activity Bank** (NEW - Activity Model Refactor)
- Unscheduled activities stored without dates/times
- Planning wizard draws from activity bank
- Activities can be scheduled from bank or created as scheduled directly

**Basic Scheduling** (PLANNED)
- Schedule one week at a time
- Respect fixed activities
- Place flexible activities in available slots
- Handle basic conflicts

**Daily View** (PLANNED)
- See today's scheduled activities
- Mark activities as complete
- Quick add new activity

**Weekly Planning** (PLANNED)
- Simple wizard to generate schedule
- Review and accept schedule
- See what fits and what doesn't

### Priority Tier 1: V1.0 (Should Have)

**Advanced Scheduling**
- Multiple scheduling strategies (Balanced, Front-Loaded, Max Free Time)
- Travel time between locations
- Preference for specific times of day
- Multi-pass algorithm with priority levels

**Goals & Progress**
- Define goals (hours per week on category/person/location/activity)
- Track progress toward goals
- Show goal status in planning wizard
- Alert when goals can't be met
- Activities contribute to all relevant goals when completed

> **Conceptual Note (2026-01-25)**: Goals are **time tracking targets**, not independent items. A goal answers the question "How much time do I want to spend on [X]?" where X is a category (e.g., "Exercise", "Deep Work"), a person (e.g., "Mom", "Partner"), a location (e.g., "Home Office"), or a specific activity title (e.g., "Guitar Practice"). The goal title should be derived from or secondary to the target being tracked.

**People & Relationships**
- Associate people with activities
- Schedule time with specific people
- Track relationship goals

**Recurrence**
- Recurring activities (daily, weekly, monthly)
- Exceptions to recurrence rules
- Templates for common recurring patterns

**Series Support** (NEW - Activity Model Refactor)
- Group related activities with seriesId
- Detect similar activities and prompt to add to series
- Edit scope options: this one, all in series, this and future
- Property variance handling for bulk edits

**Rescheduling**
- Dynamic rescheduling of incomplete activities
- Conflict resolution UI
- Move/resize activities with constraint validation

**Enhanced UI**
- Week view
- Activity detail modal
- Full activity form with all fields
- Constraint picker
- Plan comparison view
- Series matching prompt
- Edit scope selection dialog

### Priority Tier 2: V1.x (Nice to Have)

**Schedule Variations**
- Generate 3-5 alternative schedules
- Side-by-side comparison
- Different optimization strategies
- User preference learning

**Smart Templates**
- Learn from past activities
- Suggest similar activities
- Template library with presets

**Advanced Constraints**
- Time-of-day preferences (morning person vs night owl)
- Energy levels throughout day
- Required breaks between certain activities
- Maximum activities per day

**Notifications**
- Event reminders
- Schedule change notifications
- Goal progress updates
- Conflict alerts

**Analytics**
- Time spent by category over time
- Goal completion trends
- Schedule adherence metrics
- Productivity insights

### Future Considerations (Not Committed)

**Cloud Sync**
- Multi-device synchronization
- Backup and restore
- Conflict resolution for offline edits

**Team Features**
- Shared calendars
- Meeting scheduling across multiple people
- Availability sharing

**Integrations**
- Import from Google Calendar, Outlook
- Export to standard calendar formats
- API for third-party integrations

**AI Enhancements**
- Learn optimal schedule patterns
- Predict event durations
- Suggest goals based on usage
- Natural language event input

## Non-Goals & Explicit Exclusions

**Out of Scope for V1.0**:
- ❌ No team/collaboration features (single-user only)
- ❌ No calendar integrations (standalone app)
- ❌ No real-time sync (offline-first, local only)
- ❌ No email integration
- ❌ No expense/budget tracking
- ❌ No complex project management (Gantt charts, dependencies)
- ❌ No time tracking/timers (focus is planning, not tracking)
- ❌ No habit tracking (dedicated habit apps do this better)

**Intentional Limitations**:
- **Mobile-first**: Desktop experience is secondary
- **Personal use**: Not designed for enterprise/organizational use
- **Planning horizon**: Focus on weekly planning, not long-term project scheduling
- **Simple goal metrics**: Hours per period, not complex KPIs

## Success Metrics

### User Engagement
- **Target**: 4+ sessions per week (weekly planning + daily check-ins)
- **Measure**: App opens per user per week

### Core Workflow Completion
- **Target**: 80%+ of users complete weekly planning wizard
- **Measure**: Wizard completion rate

### Schedule Adherence
- **Target**: 60%+ of scheduled flexible events completed
- **Measure**: Completion rate vs scheduled events

### Goal Achievement
- **Target**: 50%+ of goals met weekly
- **Measure**: Goal completion percentage

### User Retention
- **Target**: 40%+ weekly active users (WAU) at 4 weeks
- **Measure**: Weekly active users / total signups

### User Satisfaction
- **Target**: 4+ stars average rating
- **Measure**: App store ratings

## Technical Constraints

### Performance
- **Scheduling**: Generate schedule for 7 days in < 2 seconds
- **Database queries**: < 100ms for typical queries
- **UI responsiveness**: 60 FPS scrolling, < 100ms input response

### Scalability
- **Events**: Support 500+ events per user
- **Schedule generation**: Handle 100+ events in planning window

### Platform Support
- **Primary**: iOS 14+, Android 8+
- **Screen sizes**: Phone (portrait), Tablet (portrait/landscape)
- **Future**: Web (desktop/mobile browsers)

### Data Privacy
- **Local-first**: All user data stored locally on device
- **No tracking**: No analytics that expose PII
- **No account required**: App works without login

### Accessibility
- **WCAG 2.1 Level AA**: For UI components
- **Screen reader support**: Semantic labels for all interactive elements
- **Color contrast**: Minimum 4.5:1 for text
- **Touch targets**: Minimum 44x44 points

## Technical Risks & Mitigations

### Risk: Scheduling algorithm performance

**Risk**: Complex scheduling with many constraints could be too slow

**Mitigation**:
- Pure Dart implementation allows profiling
- Benchmarks in test suite
- Fallback to simpler algorithm if complex takes too long
- Limit events in planning window (e.g., 7 days only)

### Risk: Database migration complexity

**Risk**: Schema changes could break existing user data

**Mitigation**:
- Use Drift's built-in migration system
- Write migration tests
- Test migrations with real data
- Version database schema explicitly

### Risk: Schedule over-optimization

**Risk**: AI tries too hard to optimize, creates unrealistic plans

**Mitigation**:
- Offer multiple schedule variations
- Default to "Balanced" strategy (most realistic)
- Clear UI showing conflicts/issues
- Allow manual overrides

### Risk: UI complexity

**Risk**: Feature-rich app could become confusing

**Mitigation**:
- Onboarding wizard for first-time users
- Progressive disclosure of advanced features
- Clear information hierarchy
- User testing at each milestone

## Open Questions

1. **Should we support multiple users per device?** (e.g., family sharing)
   - Decision needed before finalizing data model
   - Impacts UserSettings table structure

2. **How far in advance should planning window extend?**
   - Current: 7 days (one week)
   - Consider: 14 days? Month view?

3. **Should goals be required or optional?**
   - Impact on scheduling algorithm
   - Affects onboarding flow

4. **What happens when a flexible event can't be scheduled?**
   - Show in "Unscheduled" list?
   - Suggest removing/shortening other events?
   - Auto-push to next week?

## Appendix: User Stories

### Weekly Planning
- As a user, I want to generate a schedule for next week so I can see if my commitments are realistic
- As a user, I want to see multiple schedule options so I can choose what works best
- As a user, I want to know which goals I'll meet so I can adjust if needed
- As a user, I want the wizard to draw from my activity bank so unscheduled tasks get placed

### Daily Execution
- As a user, I want to see what I should work on now so I don't waste time deciding
- As a user, I want to mark activities as complete so the schedule adjusts for remaining work
- As a user, I want to quickly add urgent tasks so they get scheduled appropriately

### Activity Management
- As a user, I want to create recurring activities so I don't have to re-enter weekly meetings
- As a user, I want to set time preferences so flexible activities are scheduled when I'm most productive
- As a user, I want to lock important activities so they never get moved
- As a user, I want to create activities without titles (just a person or location) for simple tracking
- As a user, I want to add unscheduled activities to my activity bank for future planning

### Activity Series
- As a user, I want similar activities to be detected so I can link them together
- As a user, I want to edit all activities in a series at once so I don't have to repeat changes
- As a user, I want to choose whether a new activity joins an existing series or stays standalone

### Goal Tracking
- As a user, I want to define how much time I spend on each area so I maintain balance
- As a user, I want to see progress toward goals so I know if I'm on track
- As a user, I want to be alerted if goals conflict so I can make informed trade-offs

---

*Last updated: 2026-01-25*
