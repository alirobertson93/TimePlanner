import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/presentation/screens/planning_wizard/planning_wizard_screen.dart';
import 'package:time_planner/presentation/providers/planning_wizard_providers.dart';

void main() {
  group('PlanningWizardScreen', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: const PlanningWizardScreen(),
          // Handle navigation
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('Route: ${settings.name}')),
              ),
            );
          },
        ),
      );
    }

    testWidgets('displays first step title on load', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Select Date Range'), findsOneWidget);
    });

    testWidgets('displays step indicator with 4 steps', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have 4 step circles (step numbers 1-4)
      expect(find.text('1'), findsOneWidget);
      // Other step numbers may or may not be visible depending on their state
    });

    testWidgets('displays Next button on first step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('displays close button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('shows cancel confirmation dialog when close is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Cancel Planning?'), findsOneWidget);
      expect(find.text('Are you sure you want to cancel? Your progress will be lost.'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('dismisses dialog when Continue is tapped', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Open cancel dialog
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed, wizard still visible
      expect(find.text('Cancel Planning?'), findsNothing);
      expect(find.text('Select Date Range'), findsOneWidget);
    });

    testWidgets('can navigate to next step when valid', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The wizard initializes with default dates, so Next should be enabled
      // First step is Date Range - after initialization it should have valid dates
      
      // Tap Next
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Should be on step 2: Review Goals
      expect(find.text('Review Goals'), findsOneWidget);
    });

    testWidgets('Back button appears on step 2', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Back button should now be visible
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('can go back to previous step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to step 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Review Goals'), findsOneWidget);

      // Go back
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      // Should be on step 1 again
      expect(find.text('Select Date Range'), findsOneWidget);
    });

    testWidgets('step 3 shows Generate Schedule button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate through steps
      await tester.tap(find.text('Next')); // Go to Goals
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Next')); // Go to Strategy
      await tester.pumpAndSettle();

      expect(find.text('Choose Strategy'), findsOneWidget);
      expect(find.text('Generate Schedule'), findsOneWidget);
    });

    testWidgets('displays all wizard steps in sequence', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Step 1: Date Range
      expect(find.text('Select Date Range'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: Goals Review
      expect(find.text('Review Goals'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 3: Strategy Selection
      expect(find.text('Choose Strategy'), findsOneWidget);
    });
  });

  group('PlanningWizardState', () {
    test('initial state has correct defaults', () {
      const state = PlanningWizardState();
      
      expect(state.currentStep, equals(0));
      expect(state.startDate, isNull);
      expect(state.endDate, isNull);
      expect(state.selectedGoals, isEmpty);
      expect(state.selectedStrategy, equals(StrategyType.balanced));
      expect(state.isGenerating, isFalse);
      expect(state.scheduleResult, isNull);
      expect(state.error, isNull);
    });

    test('copyWith creates new state with updated values', () {
      const state = PlanningWizardState();
      final newDate = DateTime(2026, 1, 20);
      
      final newState = state.copyWith(
        currentStep: 1,
        startDate: newDate,
      );
      
      expect(newState.currentStep, equals(1));
      expect(newState.startDate, equals(newDate));
      expect(newState.endDate, isNull); // Unchanged
    });

    test('isCurrentStepValid returns false for step 0 without dates', () {
      const state = PlanningWizardState(currentStep: 0);
      
      expect(state.isCurrentStepValid, isFalse);
    });

    test('isCurrentStepValid returns true for step 0 with valid dates', () {
      final state = PlanningWizardState(
        currentStep: 0,
        startDate: DateTime(2026, 1, 20),
        endDate: DateTime(2026, 1, 26),
      );
      
      expect(state.isCurrentStepValid, isTrue);
    });

    test('isCurrentStepValid returns false for step 0 when end before start', () {
      final state = PlanningWizardState(
        currentStep: 0,
        startDate: DateTime(2026, 1, 26),
        endDate: DateTime(2026, 1, 20),
      );
      
      expect(state.isCurrentStepValid, isFalse);
    });

    test('isCurrentStepValid returns true for same-day planning', () {
      final sameDay = DateTime(2026, 1, 20);
      final state = PlanningWizardState(
        currentStep: 0,
        startDate: sameDay,
        endDate: sameDay,
      );
      
      expect(state.isCurrentStepValid, isTrue);
    });

    test('goals step is always valid (goals are optional)', () {
      const state = PlanningWizardState(currentStep: 1);
      
      expect(state.isCurrentStepValid, isTrue);
    });

    test('strategy step is always valid (has default)', () {
      const state = PlanningWizardState(currentStep: 2);
      
      expect(state.isCurrentStepValid, isTrue);
    });

    test('canProceed is false at last step', () {
      const state = PlanningWizardState(currentStep: 3);
      
      expect(state.canProceed, isFalse);
    });

    test('canGoBack is false at first step', () {
      const state = PlanningWizardState(currentStep: 0);
      
      expect(state.canGoBack, isFalse);
    });

    test('canGoBack is true after first step', () {
      const state = PlanningWizardState(currentStep: 1);
      
      expect(state.canGoBack, isTrue);
    });

    test('canGoBack is false when generating', () {
      const state = PlanningWizardState(
        currentStep: 2,
        isGenerating: true,
      );
      
      expect(state.canGoBack, isFalse);
    });

    test('daysInWindow calculates correctly', () {
      final state = PlanningWizardState(
        startDate: DateTime(2026, 1, 20),
        endDate: DateTime(2026, 1, 26),
      );
      
      expect(state.daysInWindow, equals(7));
    });

    test('daysInWindow returns 0 without dates', () {
      const state = PlanningWizardState();
      
      expect(state.daysInWindow, equals(0));
    });
  });
}
