import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/presentation/screens/onboarding/enhanced_onboarding_screen.dart';

void main() {
  group('EnhancedOnboardingScreen', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          home: const EnhancedOnboardingScreen(),
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

    testWidgets('displays welcome page on initial load', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to TimePlanner'), findsOneWidget);
    });

    testWidgets('displays overview of what will be set up', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining("In the next few steps, you'll add:"),
        findsOneWidget,
      );
    });

    testWidgets('displays Skip button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('displays Next button on first page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('does not display Back button on first page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsNothing);
    });

    testWidgets('displays progress indicator', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('tapping Next navigates to recurring events page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Recurring Fixed Events'), findsOneWidget);
    });

    testWidgets('Back button appears on second page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('tapping Back returns to previous page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to page 2
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Go back to page 1
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to TimePlanner'), findsOneWidget);
    });

    testWidgets('can navigate through all pages', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Page 1: Welcome
      expect(find.text('Welcome to TimePlanner'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 2: Recurring Fixed Events
      expect(find.text('Recurring Fixed Events'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 3: People & Time Goals
      expect(find.text('People & Time Goals'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 4: Activity Goals
      expect(find.text('Activity Goals'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 5: Your Places
      expect(find.text('Your Places'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 6: Summary
      expect(find.text("You're All Set!"), findsOneWidget);
    });

    testWidgets('displays "Get Started" on last page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to last page
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('recurring events page shows add button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Add Recurring Event'), findsOneWidget);
    });

    testWidgets('people page shows add button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to people page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Add Person'), findsOneWidget);
    });

    testWidgets('activity goals page shows add button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to activity goals page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Add Activity Goal'), findsOneWidget);
    });

    testWidgets('activity goals page shows suggested activities', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to activity goals page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
    });

    testWidgets('places page shows add button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to places page
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Add Location'), findsOneWidget);
    });

    testWidgets('places page shows quick add chips', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to places page
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
    });

    testWidgets('clicking suggested activity adds it to the list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to activity goals page
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Tap on Exercise chip
      await tester.tap(find.text('Exercise'));
      await tester.pumpAndSettle();

      // Should see the card with Exercise title
      expect(find.text('3 hours per week'), findsOneWidget);
    });

    testWidgets('clicking quick add location adds it to the list', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to places page
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Tap on Home chip
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Should find delete icon for the added location
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('summary page shows counts when items added', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to activity goals page and add one
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }
      
      await tester.tap(find.text('Exercise'));
      await tester.pumpAndSettle();

      // Navigate to places page and add one
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      // Navigate to summary
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Check that counts are displayed
      expect(find.text('Activity Goals'), findsOneWidget);
      expect(find.text('Locations'), findsOneWidget);
    });

    testWidgets('FilledButton used for primary action', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('OutlinedButton used for Back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Go to second page to see Back button
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('SafeArea wraps content', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(SafeArea), findsOneWidget);
    });

    testWidgets('uses PageView for pages', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('pages cannot be swiped (controlled navigation)', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Try to swipe to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Should still be on first page due to NeverScrollableScrollPhysics
      expect(find.text('Welcome to TimePlanner'), findsOneWidget);
    });
  });
}
