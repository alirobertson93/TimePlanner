# Setup Instructions

This document provides instructions for completing the initial setup of the TimePlanner Flutter project.

## Current Status

✅ **Completed:**
- Project structure created
- Domain layer implemented (entities, enums)
- Core utilities and theme configured
- Drift database schema defined
- Repository layer implemented
- Riverpod providers created
- Basic app shell (main.dart, app.dart, router.dart)
- Comprehensive repository tests written
- Dependencies added to pubspec.yaml

⚠️ **Requires Action:**
- Code generation (Drift database files)
- Running tests to verify implementation

## Required Steps

### 1. Install Flutter SDK

If you don't have Flutter installed, follow the official guide:
https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter --version
dart --version
```

### 2. Install Dependencies

Navigate to the project directory and install dependencies:
```bash
cd TimePlanner
flutter pub get
```

### 3. Generate Code

The project uses code generation for Drift database classes. Run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This will generate:
- `lib/data/database/app_database.g.dart` - Drift database implementation

**Expected output:**
- No errors
- Generated file should be in `.gitignore` (it is)
- Database tables should be accessible

### 4. Run Tests

Verify the implementation by running tests:

```bash
# Run all tests
flutter test

# Run specific test suites
flutter test test/repositories/event_repository_test.dart
flutter test test/repositories/category_repository_test.dart
```

**Expected results:**
- All tests should pass
- Event repository tests verify CRUD operations and range queries
- Category repository tests verify default categories are seeded

### 5. Run the App (Optional)

While the app is minimal, you can verify it builds and runs:

```bash
# For web
flutter run -d chrome

# For mobile (with emulator/device connected)
flutter run
```

**Expected output:**
- App should launch without errors
- Home screen with "Welcome to TimePlanner" message
- No runtime errors in console

## Troubleshooting

### Code Generation Fails

If `build_runner` fails:
1. Ensure all dependencies are installed: `flutter pub get`
2. Check for syntax errors in table definitions
3. Try cleaning: `flutter clean && flutter pub get`
4. Delete `.dart_tool` and try again

### Import Errors

If you see import errors in your IDE:
1. Run code generation first (step 3)
2. Restart your IDE/analyzer
3. Run `flutter pub get` again

### Test Failures

If tests fail:
1. Ensure code generation completed successfully
2. Check that all dependencies installed correctly
3. Verify database tables are properly defined
4. Check test output for specific error messages

## Next Steps

After completing setup:

1. **Verify Database Seeding:**
   - Run the app
   - Check that 7 default categories are created
   - Verify category properties match DATA_MODEL.md

2. **Test Event Creation:**
   - Create a simple UI to add events
   - Verify events are saved to database
   - Test getEventsInRange query

3. **Implement Remaining Features:**
   - Event list screen
   - Event detail/edit screen
   - Category management
   - Calendar view
   - Scheduling algorithm

## Files That Will Be Generated

After running build_runner, these files will be created:

```
lib/data/database/app_database.g.dart  # Drift database implementation
```

These files are in `.gitignore` and should not be committed.

## Development Workflow

Going forward:

1. Make changes to source files
2. Run code generation if you modified:
   - Database tables
   - Riverpod providers (when using annotations)
3. Run tests: `flutter test`
4. Run analyzer: `flutter analyze`
5. Format code: `flutter format .`

## Support

If you encounter issues:
1. Check Flutter version compatibility
2. Review Drift documentation: https://drift.simonbinder.eu/
3. Check Riverpod documentation: https://riverpod.dev/
4. Review test error messages for specific issues

## Verification Checklist

Use this checklist to verify setup completion:

- [ ] Flutter SDK installed and in PATH
- [ ] Dependencies installed (`flutter pub get`)
- [ ] Code generation completed successfully
- [ ] `app_database.g.dart` file exists
- [ ] All tests pass (`flutter test`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] App builds and runs
- [ ] Home screen displays correctly
- [ ] No console errors when running app

Once all items are checked, the initial setup is complete!
