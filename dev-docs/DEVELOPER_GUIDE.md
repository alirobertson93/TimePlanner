# Developer Guide

Welcome to TimePlanner! This guide is your entry point for development and serves as a comprehensive resource for working on this project, especially when using AI coding assistants.

## 📚 Documentation Suite Overview

This project includes a comprehensive documentation suite. Here's when to reference each document:

| Document | Purpose | When to Use |
|----------|---------|-------------|
| **[README.md](../README.md)** | Quick start and basic info | First time setup, running the app |
| **[DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md)** (this file) | Development workflow and patterns | Starting any development session |
| **[ROADMAP.md](./ROADMAP.md)** | Project status and upcoming phases | Understanding progress, planning work |
| **[PRD.md](../PRD.md)** | Product requirements | Understanding features, priorities, and goals |
| **[DATA_MODEL.md](./DATA_MODEL.md)** | Database schema | Working with data, adding tables/fields |
| **[ALGORITHM.md](./ALGORITHM.md)** | Scheduling engine logic | Implementing or modifying scheduling |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Code structure and layers | Adding features, understanding organization |
| **[TESTING.md](./TESTING.md)** | Testing strategy | Writing tests, running test suites |
| **[UX_FLOWS.md](./UX_FLOWS.md)** | User journeys | Building UI, understanding user interactions |
| **[WIREFRAMES.md](./WIREFRAMES.md)** | Screen layouts | Implementing screens, UI components |
| **[CHANGELOG.md](./CHANGELOG.md)** | Progress tracking | Session handoffs, tracking changes |

## 📖 Documentation Purpose Guide

Each documentation file has a **single, specific purpose**. This prevents duplication and ensures information is always up-to-date. **Never duplicate information across files** — use cross-references instead.

### Quick Reference: "Where Do I Look?"

| Question | Answer | File |
|----------|--------|------|
| "What's the current project status?" | Phase completion, component status, blockers | [ROADMAP.md](./ROADMAP.md) |
| "What was done in previous sessions?" | Session logs, decisions made, work completed | [CHANGELOG.md](./CHANGELOG.md) |
| "How do I start working on this project?" | Setup, workflows, patterns, conventions | [DEVELOPER_GUIDE.md](./DEVELOPER_GUIDE.md) |
| "How is the code organized?" | Layers, dependencies, folder structure | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| "What's the database schema?" | Tables, fields, relationships, migrations | [DATA_MODEL.md](./DATA_MODEL.md) |
| "How does the scheduler work?" | Algorithm, strategies, constraints | [ALGORITHM.md](./ALGORITHM.md) |
| "How do I write tests?" | Test patterns, coverage, examples | [TESTING.md](./TESTING.md) |
| "What should the UI look like?" | Screen layouts, design tokens | [WIREFRAMES.md](./WIREFRAMES.md) |
| "What are the user flows?" | User journeys, interactions | [UX_FLOWS.md](./UX_FLOWS.md) |
| "What features are planned?" | Requirements, priorities, scope | [PRD.md](../PRD.md) |

### File-by-File Instructions

#### ROADMAP.md — Project Status & Phases
**Purpose**: Single source of truth for project progress and planning.

**Contains**:
- Current status (overall % complete, active phase)
- Completed phases with details
- Upcoming phases with features, dependencies, estimates
- Component completion matrix
- Active blockers

**When to READ**: 
- Starting a new development session (check what's next)
- Deciding what to work on
- Checking if a feature is planned

**When to WRITE**:
- Completing a phase or major feature
- Updating component completion percentages
- Adding/removing blockers
- Adjusting phase priorities or estimates

**DO NOT put here**: Session logs, code patterns, architecture details

---

#### CHANGELOG.md — Session Logs & Development History
**Purpose**: Track what was done, when, and by whom. Enable session handoffs.

**Contains**:
- Session log entries (date, author, goals, work completed)
- Technical debt items
- Bug tracker
- Decisions made during development

**When to READ**:
- Starting a session (review last 2-3 entries)
- Understanding why something was built a certain way
- Finding known issues or debt

**When to WRITE**:
- After every development session (add session log entry)
- When discovering technical debt
- When finding bugs that aren't immediately fixed
- When making significant technical decisions

**DO NOT put here**: Project status summaries (use ROADMAP.md), code patterns (use DEVELOPER_GUIDE.md)

---

#### DEVELOPER_GUIDE.md — How to Work on This Project
**Purpose**: Entry point for development. Explains workflows, patterns, and conventions.

**Contains**:
- Documentation overview (this section!)
- Development workflow (start/during/end session)
- Code style guidelines
- Commit message conventions
- Common patterns (creating entities, adding features, building screens)
- Debugging tips
- Quick reference commands

**When to READ**:
- First time working on the project
- Starting any development session
- Need to remember a pattern or convention
- Debugging issues

**When to WRITE**:
- Adding new common patterns
- Updating conventions
- Adding debugging tips

**DO NOT put here**: Project status (use ROADMAP.md), session logs (use CHANGELOG.md), detailed architecture (use ARCHITECTURE.md)

---

#### ARCHITECTURE.md — Code Structure & Patterns
**Purpose**: Explain how the code is organized and the rules for each layer.

**Contains**:
- Folder structure specification
- Layer responsibilities (Core, Domain, Data, Scheduler, Presentation)
- Dependency rules between layers
- Data flow diagrams
- Error handling patterns
- State management patterns

**When to READ**:
- Understanding where code should go
- Adding a new feature
- Debugging layer-related issues

**When to WRITE**:
- Adding new layers or modules
- Changing architectural patterns
- Adding new error handling approaches

**DO NOT put here**: Database schema (use DATA_MODEL.md), algorithm details (use ALGORITHM.md)

---

#### DATA_MODEL.md — Database Schema
**Purpose**: Complete specification of database tables, fields, and relationships.

**Contains**:
- All table definitions
- Field types and constraints
- Relationships and foreign keys
- Indexes
- Default data (seed data)
- Migration notes

**When to READ**:
- Working with database
- Adding new tables or fields
- Understanding data relationships

**When to WRITE**:
- Adding new tables
- Modifying existing tables
- Changing relationships or constraints

**DO NOT put here**: How to use repositories (use ARCHITECTURE.md), algorithm logic (use ALGORITHM.md)

---

#### ALGORITHM.md — Scheduling Engine Specification
**Purpose**: Detailed specification of the scheduling algorithm and strategies.

**Contains**:
- Scheduling input/output contracts
- Multi-pass algorithm description
- Strategy implementations (Balanced, Front-Loaded, etc.)
- Constraint validation logic
- Goal evaluation
- Performance considerations

**When to READ**:
- Working on scheduler code
- Understanding how scheduling decisions are made
- Adding new scheduling strategies

**When to WRITE**:
- Implementing new strategies
- Modifying algorithm behavior
- Optimizing performance

**DO NOT put here**: Database schema (use DATA_MODEL.md), UI flows (use UX_FLOWS.md)

---

#### TESTING.md — Testing Strategy
**Purpose**: How to write and run tests for this project.

**Contains**:
- Test distribution goals by layer
- Test folder structure
- Unit test examples
- Integration test examples
- Widget test examples
- Test fixtures
- CI configuration

**When to READ**:
- Writing new tests
- Setting up test infrastructure
- Understanding coverage requirements

**When to WRITE**:
- Adding new test patterns
- Updating CI configuration
- Adding test utilities

---

#### WIREFRAMES.md — Screen Layouts
**Purpose**: Visual specifications for UI screens.

**Contains**:
- Screen inventory with priorities
- ASCII wireframes for each screen
- Design tokens (colors, typography, spacing)
- Responsive considerations
- Accessibility requirements

**When to READ**:
- Building new screens
- Understanding UI requirements
- Implementing design tokens

**When to WRITE**:
- Designing new screens
- Updating design specifications

---

#### UX_FLOWS.md — User Journeys
**Purpose**: Document how users interact with the app.

**Contains**:
- User flows (onboarding, planning wizard, daily use)
- Screen-to-screen navigation
- Interaction patterns
- Error states
- Notification flows

**When to READ**:
- Understanding user expectations
- Building user-facing features
- Implementing navigation

**When to WRITE**:
- Designing new user flows
- Modifying existing journeys

---

#### PRD.md — Product Requirements
**Purpose**: What the product should do and why.

**Contains**:
- Problem statement
- User personas
- Feature requirements by priority
- Non-goals (explicit exclusions)
- Success metrics
- Technical constraints

**When to READ**:
- Understanding product vision
- Prioritizing work
- Checking if a feature is in scope

**When to WRITE**:
- Changing product requirements
- Updating priorities
- Adding new feature requests

---

### Maintenance Rules

1. **Single Source of Truth**: Never duplicate information. If something is in ROADMAP.md, don't repeat it in CHANGELOG.md.

2. **Cross-References**: Use links like `See [ROADMAP.md](./ROADMAP.md) for current status` instead of copying content.

3. **Keep It Current**: Update docs as you work, not in a big batch later.

4. **Session Handoffs**: Always update CHANGELOG.md at the end of a session so the next developer (human or AI) knows what happened.

5. **Status Updates**: When completing significant work, update ROADMAP.md component percentages and phase status.

## 🤖 Working with AI Coding Assistants

This project is designed to be AI-assistant friendly. Follow these practices:

### Starting a Development Session

1. **Load Context**: Share relevant documentation files with your AI assistant
   - Always share: DEVELOPER_GUIDE.md (this file)
   - Task-specific: Share docs relevant to your task (see table above)
   - For status/planning: Share ROADMAP.md

2. **Review Current State**: Check [ROADMAP.md](./ROADMAP.md) for current phase and priorities, and [CHANGELOG.md](./CHANGELOG.md) for latest sessions and known issues

3. **Set Clear Goals**: Define specific, measurable objectives for the session

### During Development

- **Reference Patterns**: Use the "Common Patterns" section below for consistency
- **Follow Conventions**: Adhere to code style and commit message guidelines
- **Test Incrementally**: Run tests after each significant change
- **Document Decisions**: Note any important choices in code comments or CHANGELOG.md

### Ending a Session

1. **Update Documentation**: 
   - Add session notes to [CHANGELOG.md](./CHANGELOG.md)
   - Update [ROADMAP.md](./ROADMAP.md) if phase status changes
2. **Commit Changes**: Use proper commit message conventions
3. **Run Full Test Suite**: Ensure nothing is broken
4. **Note Blockers**: Document any issues or next steps

## 🎨 Code Style Guidelines

### General Principles

- **Readability First**: Code should be self-documenting
- **Single Responsibility**: Each function/class does one thing well
- **Pure Functions**: Prefer pure functions without side effects (especially in scheduler)
- **Immutability**: Use `final` by default, prefer immutable data structures
- **Type Safety**: Leverage Dart's strong typing, avoid `dynamic` when possible

### Naming Conventions

```dart
// Classes: PascalCase
class EventScheduler {}
class ScheduleRequest {}

// Files: snake_case
event_scheduler.dart
schedule_request.dart

// Variables and functions: camelCase
final DateTime startTime = DateTime.now();
void calculateSchedule() {}

// Constants: lowerCamelCase
const int maxEventsPerDay = 20;
const Duration defaultEventDuration = Duration(hours: 1);

// Private members: _prefixed
final String _internalId;
void _validateConstraints() {}

// Enums: PascalCase for type, camelCase for values
enum TimingType { fixed, flexible }
enum EventStatus { pending, inProgress, completed, cancelled }
```

### File Organization

```dart
// 1. Imports (Dart, Flutter, packages, relative)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/event.dart';
import 'event_repository.dart';

// 2. Part directives (if using code generation)
part 'event_providers.g.dart';

// 3. Constants
const int defaultPageSize = 20;

// 4. Main class/functions
class EventService {
  // Public fields
  final EventRepository repository;
  
  // Private fields
  final String _userId;
  
  // Constructor
  EventService(this.repository, this._userId);
  
  // Public methods
  Future<List<Event>> getEvents() async {}
  
  // Private methods
  void _validateEvent(Event event) {}
}
```

### Documentation Comments

```dart
/// Schedules events within the given time window.
///
/// Takes a [ScheduleRequest] containing events and constraints,
/// and returns a [ScheduleResult] with scheduled events or errors.
///
/// Example:
/// ```dart
/// final result = await scheduler.schedule(request);
/// if (result.success) {
///   // Use result.scheduledEvents
/// }
/// ```
Future<ScheduleResult> schedule(ScheduleRequest request) async {
  // Implementation
}
```

## 📝 Commit Message Conventions

Follow the Conventional Commits specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes (formatting, no logic change)
- `refactor`: Code refactoring (no feature change or bug fix)
- `test`: Adding or updating tests
- `chore`: Maintenance tasks (dependencies, build, etc.)
- `perf`: Performance improvements

### Examples

```
feat(scheduler): implement multi-pass scheduling algorithm

Add the core scheduling algorithm that processes events in multiple
passes: fixed events first, then flexible events by priority.

Implements the algorithm described in ALGORITHM.md section 3.1.
```

```
fix(database): prevent duplicate category names

Add unique constraint to categories table and handle duplicate
errors in the repository layer.

Fixes #123
```

```
test(repositories): add event repository integration tests

Add comprehensive tests for EventRepository covering CRUD operations
and constraint handling.
```

## 🔧 Common Patterns

### Creating a New Entity

1. **Define Domain Entity** in `lib/domain/entities/`
   ```dart
   class Goal {
     final String id;
     final String title;
     final GoalType type;
     
     Goal({required this.id, required this.title, required this.type});
   }
   ```

2. **Add Database Table** in `lib/data/database/database.dart`
   ```dart
   class Goals extends Table {
     TextColumn get id => text()();
     TextColumn get title => text()();
     IntColumn get type => intEnum<GoalType>()();
     
     @override
     Set<Column> get primaryKey => {id};
   }
   ```

3. **Run Code Generation**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Create Repository** in `lib/data/repositories/`
   ```dart
   class GoalRepository {
     final AppDatabase _db;
     
     GoalRepository(this._db);
     
     Future<List<Goal>> getAll() async {
       final results = await _db.select(_db.goals).get();
       return results.map(_toEntity).toList();
     }
     
     Goal _toEntity(GoalsCompanion data) {
       // Map database model to domain entity
     }
   }
   ```

5. **Create Riverpod Provider** in `lib/presentation/providers/`
   ```dart
   @riverpod
   GoalRepository goalRepository(GoalRepositoryRef ref) {
     final db = ref.watch(databaseProvider);
     return GoalRepository(db);
   }
   ```

### Adding a New Feature

1. **Check PRD.md**: Verify feature requirements and priority
2. **Update DATA_MODEL.md**: If database changes needed
3. **Update ARCHITECTURE.md**: If new layers/modules added
4. **Implement**: Follow layer order (Domain → Data → Scheduler → Presentation)
5. **Test**: Write tests following TESTING.md
6. **Update UX_FLOWS.md**: If user-facing changes
7. **Update CHANGELOG.md**: Document what was added

### Building a New Screen

1. **Review WIREFRAMES.md**: Check design specifications
2. **Review UX_FLOWS.md**: Understand user journey
3. **Create Screen File**: `lib/presentation/screens/feature_name/screen_name_screen.dart`
4. **Add Route**: Update `lib/app/router.dart`
5. **Create State Provider**: If stateful
6. **Build Widgets**: Extract reusable widgets to `lib/presentation/widgets/`
7. **Test**: Add widget tests in `test/presentation/screens/`

### Working with Riverpod

```dart
// Provider definition
@riverpod
EventRepository eventRepository(EventRepositoryRef ref) {
  final db = ref.watch(databaseProvider);
  return EventRepository(db);
}

// Stream provider for reactive data
@riverpod
Stream<List<Event>> todaysEvents(TodaysEventsRef ref) {
  final repo = ref.watch(eventRepositoryProvider);
  final today = DateTime.now();
  return repo.watchEventsForDate(today);
}

// Using in widgets (ConsumerWidget)
class EventListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(todaysEventsProvider);
    
    return eventsAsync.when(
      data: (events) => ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) => EventTile(events[index]),
      ),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => ErrorWidget(error),
    );
  }
}
```

## 🐛 Debugging Tips

### Common Issues

**Issue**: Code generation not working
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

**Issue**: Database schema mismatch
```bash
# Solution: Increment schema version in database.dart
@DriftDatabase(
  tables: [...],
  daos: [...],
  version: 2, // Increment this
)
```

**Issue**: Riverpod provider not found
```dart
// Make sure to import generated file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers.dart'; // Import provider file
part 'providers.g.dart'; // If using code generation
```

### Debugging the Scheduler

The scheduler is pure Dart (no Flutter dependencies), so you can:

1. **Unit test directly**
   ```dart
   test('schedules fixed event at specified time', () {
     final scheduler = EventScheduler();
     final result = scheduler.schedule(request);
     expect(result.scheduledEvents.length, equals(1));
   });
   ```

2. **Run in isolation**
   ```bash
   cd lib/scheduler
   dart test.dart  # If you create a standalone test file
   ```

3. **Add debug logging**
   ```dart
   void _logSchedulingPass(String passName, List<Event> events) {
     if (kDebugMode) {
       print('[$passName] Processing ${events.length} events');
     }
   }
   ```

## 🚀 Quick Reference

### Essential Commands

```bash
# Setup
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# Development
flutter run                 # Run app
flutter analyze            # Lint code
flutter format lib test    # Format code
flutter test              # Run tests
flutter test --coverage   # Run tests with coverage

# Code Generation
flutter pub run build_runner build                          # Generate once
flutter pub run build_runner build --delete-conflicting-outputs  # Clean build
flutter pub run build_runner watch                          # Watch mode

# Database
# Increment version in lib/data/database/database.dart to trigger migrations

# Build
flutter build apk          # Android APK
flutter build ios          # iOS build
flutter build web          # Web build
```

### Key Dependencies

| Package | Purpose | Documentation |
|---------|---------|---------------|
| flutter_riverpod | State management | [pub.dev/packages/flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| riverpod_annotation | Riverpod code gen | [pub.dev/packages/riverpod_annotation](https://pub.dev/packages/riverpod_annotation) |
| drift | SQLite ORM | [drift.simonbinder.eu](https://drift.simonbinder.eu) |
| go_router | Navigation | [pub.dev/packages/go_router](https://pub.dev/packages/go_router) |
| uuid | ID generation | [pub.dev/packages/uuid](https://pub.dev/packages/uuid) |

### Project Structure Quick Reference

```
lib/
├── main.dart              # Entry point
├── app/                   # App config & routing
├── core/                  # Theme, utils, errors
├── data/                  # Database & repositories
│   ├── database/
│   └── repositories/
├── domain/                # Entities & enums
│   ├── entities/
│   └── enums/
├── scheduler/             # Pure Dart scheduling logic
└── presentation/          # UI layer
    ├── providers/
    ├── screens/
    └── widgets/
```

## 📖 Additional Resources

- **Flutter Docs**: https://docs.flutter.dev
- **Dart Style Guide**: https://dart.dev/guides/language/effective-dart/style
- **Riverpod Docs**: https://riverpod.dev
- **Drift Documentation**: https://drift.simonbinder.eu/docs/getting-started/

## 🤝 Contributing

When contributing to this project:

1. Read this guide and relevant documentation files
2. Follow all conventions and patterns described
3. Write tests for new features
4. Update documentation if needed
5. Keep CHANGELOG.md up to date
6. Run linter and tests before committing

---

*Last updated: 2026-01-16*
