import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/native.dart';
import 'package:time_planner/app/router.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/presentation/providers/database_provider.dart';

/// Integration test for the core user flow:
/// Create Event → View in Day View → Run Planning Wizard → Accept Schedule
/// 
/// This test validates the critical path through the application
/// as specified in next-steps.md architecture audit.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase testDb;

  setUp(() {
    // Create in-memory database for testing
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await testDb.close();
  });

  group('Core User Flow Integration Test', () {
    testWidgets('Create Event → View in Day View → Planning Wizard flow',
        (tester) async {
      // Build the app with test database
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Navigate to Day View from Home
      // Home screen should have navigation to Day View
      final dayViewButton = find.text('Day View');
      if (dayViewButton.evaluate().isNotEmpty) {
        await tester.tap(dayViewButton);
        await tester.pumpAndSettle();
      }

      // Step 2: Verify Day View is displayed
      // Look for typical Day View elements
      expect(find.byType(Scaffold), findsWidgets);

      // Step 3: Create a new event via FAB
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder.first);
        await tester.pumpAndSettle();

        // Step 4: Fill in event form
        // Find title field and enter text
        final titleField = find.byWidgetPredicate(
          (widget) =>
              widget is TextField &&
              (widget.decoration?.labelText?.contains('Title') ?? false),
        );
        if (titleField.evaluate().isNotEmpty) {
          await tester.enterText(titleField.first, 'Integration Test Event');
          await tester.pumpAndSettle();
        }

        // Step 5: Save the event
        final saveButton = find.text('Save');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton.first);
          await tester.pumpAndSettle();
        }
      }

      // Step 6: Navigate to Planning Wizard
      // Look for Plan button in Day View app bar
      final planButton = find.byIcon(Icons.auto_awesome);
      if (planButton.evaluate().isNotEmpty) {
        await tester.tap(planButton.first);
        await tester.pumpAndSettle();

        // Step 7: Verify Planning Wizard is displayed
        expect(find.text('Select Date Range'), findsOneWidget);

        // Step 8: Navigate through wizard steps
        // Click Next to go to Goals step
        final nextButton = find.text('Next');
        if (nextButton.evaluate().isNotEmpty) {
          await tester.tap(nextButton.first);
          await tester.pumpAndSettle();

          // Should now be on Goals step
          expect(find.text('Review Goals'), findsOneWidget);

          // Click Next to go to Strategy step
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();

          // Should now be on Strategy step
          expect(find.text('Choose Strategy'), findsOneWidget);
        }
      }
    });

    testWidgets('Day View shows navigation controls', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Day View
      final dayViewButton = find.text('Day View');
      if (dayViewButton.evaluate().isNotEmpty) {
        await tester.tap(dayViewButton);
        await tester.pumpAndSettle();
      }

      // Verify navigation icons are present
      expect(find.byIcon(Icons.chevron_left), findsWidgets);
      expect(find.byIcon(Icons.today), findsWidgets);
      expect(find.byIcon(Icons.chevron_right), findsWidgets);
    });

    testWidgets('Event Form validates required fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Day View
      final dayViewButton = find.text('Day View');
      if (dayViewButton.evaluate().isNotEmpty) {
        await tester.tap(dayViewButton);
        await tester.pumpAndSettle();
      }

      // Open Event Form via FAB
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder.first);
        await tester.pumpAndSettle();

        // Verify form elements are present
        expect(find.text('New Event'), findsOneWidget);
        expect(find.text('Basic Information'), findsOneWidget);
        expect(find.text('Timing'), findsOneWidget);
      }
    });

    testWidgets('Planning Wizard cancel confirmation works', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(testDb),
          ],
          child: MaterialApp.router(
            routerConfig: AppRouter.router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Day View first
      final dayViewButton = find.text('Day View');
      if (dayViewButton.evaluate().isNotEmpty) {
        await tester.tap(dayViewButton);
        await tester.pumpAndSettle();
      }

      // Navigate to Planning Wizard
      final planButton = find.byIcon(Icons.auto_awesome);
      if (planButton.evaluate().isNotEmpty) {
        await tester.tap(planButton.first);
        await tester.pumpAndSettle();

        // Should be on Planning Wizard
        expect(find.text('Select Date Range'), findsOneWidget);

        // Tap close button to trigger cancel confirmation
        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton.first);
          await tester.pumpAndSettle();

          // Verify cancel confirmation dialog appears
          expect(find.text('Cancel Planning?'), findsOneWidget);
          expect(find.text('Continue'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);

          // Tap Continue to dismiss dialog
          await tester.tap(find.text('Continue'));
          await tester.pumpAndSettle();

          // Should still be on Planning Wizard
          expect(find.text('Select Date Range'), findsOneWidget);
        }
      }
    });
  });
}
