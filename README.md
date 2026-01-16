# TimePlanner

A smart time planning application with AI-powered scheduling built with Flutter.

## Architecture

This project follows a clean architecture pattern with the following layers:

- **Domain Layer**: Pure Dart entities and business logic
- **Data Layer**: Database (Drift/SQLite) and repositories
- **Presentation Layer**: UI with Flutter and Riverpod state management
- **Scheduler Layer**: Pure Dart scheduling algorithms (foundation implemented)

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── app/                           # App configuration
│   ├── app.dart                   # MaterialApp setup
│   └── router.dart                # go_router configuration
├── core/                          # Core utilities and theme
│   ├── constants/
│   ├── theme/
│   ├── utils/
│   └── errors/
├── data/                          # Data layer
│   ├── database/                  # Drift database
│   └── repositories/              # Data repositories
├── domain/                        # Domain layer
│   ├── entities/                  # Business entities
│   └── enums/                     # Domain enums
├── scheduler/                     # Scheduling engine (pure Dart)
└── presentation/                  # UI layer
    ├── providers/                 # Riverpod providers
    ├── screens/                   # App screens
    └── widgets/                   # Reusable widgets
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)

### Setup

1. Clone the repository:
```bash
git clone https://github.com/alirobertson93/TimePlanner.git
cd TimePlanner
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate code (Drift database and Riverpod):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/repositories/event_repository_test.dart

# Run tests with coverage
flutter test --coverage
```

## Documentation

Detailed development documentation is available in the [`dev-docs/`](./dev-docs/) folder:

- **[DEVELOPER_GUIDE.md](./dev-docs/DEVELOPER_GUIDE.md)** - Start here for development workflow
- **[ARCHITECTURE.md](./dev-docs/ARCHITECTURE.md)** - Code structure and patterns
- **[DATA_MODEL.md](./dev-docs/DATA_MODEL.md)** - Database schema
- **[ALGORITHM.md](./dev-docs/ALGORITHM.md)** - Scheduling engine specification
- **[TESTING.md](./dev-docs/TESTING.md)** - Testing strategy
- **[UX_FLOWS.md](./dev-docs/UX_FLOWS.md)** - User journeys
- **[WIREFRAMES.md](./dev-docs/WIREFRAMES.md)** - Screen layouts
- **[CHANGELOG.md](./dev-docs/CHANGELOG.md)** - Development progress tracking
- **[SETUP.md](./dev-docs/SETUP.md)** - Detailed setup instructions

## Database Schema

The app uses Drift (SQLite) for local data persistence with two main tables:

### Categories Table
- Default categories: Work, Personal, Family, Health, Creative, Chores, Social
- Custom category support

### Events Table
- Fixed and flexible timing types
- Duration-based or time-bound events
- Category associations
- Scheduling constraints (movable, resizable, locked)
- Status tracking (pending, in progress, completed, cancelled)

## Features

- **Event Management**: Create, edit, and delete events
- **Categories**: Organize events with customizable categories
- **Flexible Scheduling**: Support for both fixed and flexible event timing
- **Smart Constraints**: Control how the app can schedule events
- **Local Storage**: SQLite database for offline-first functionality

## Development

### Code Generation

This project uses code generation for:
- Drift database classes
- Riverpod providers

Always run code generation after modifying:
- Database table definitions
- Annotated Riverpod providers

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Code Style

The project follows the official Dart style guide with additional linting rules defined in `analysis_options.yaml`.

Run the analyzer:
```bash
flutter analyze
```

Format code:
```bash
flutter format lib test
```

## Dependencies

### Core Dependencies
- **flutter_riverpod**: State management
- **drift**: SQLite database ORM
- **go_router**: Navigation
- **uuid**: ID generation
- **intl**: Internationalization

### Dev Dependencies
- **build_runner**: Code generation
- **drift_dev**: Drift code generator
- **riverpod_generator**: Riverpod code generator
- **mocktail**: Testing mocks

## License

This project is licensed under the MIT License.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.