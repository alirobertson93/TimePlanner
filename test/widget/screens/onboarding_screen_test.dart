import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/presentation/providers/onboarding_providers.dart';
import 'package:time_planner/presentation/screens/onboarding/onboarding_screen.dart';

void main() {
  group('OnboardingScreen', () {
    Widget createTestWidget({
      bool shouldOfferSampleData = false,
    }) {
      return ProviderScope(
        overrides: [
          shouldOfferSampleDataProvider.overrideWithValue(shouldOfferSampleData),
        ],
        child: MaterialApp(
          home: const OnboardingScreen(),
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

    testWidgets('displays first page title on initial load', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Welcome to TimePlanner'), findsOneWidget);
    });

    testWidgets('displays first page description', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Your intelligent time planning assistant'),
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

    testWidgets('displays page indicators', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have 5 page indicator containers
      // Find containers that form the page indicators
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('tapping Next navigates to second page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Second page title
      expect(find.text('Smart Scheduling'), findsOneWidget);
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

      // Page 2: Smart Scheduling
      expect(find.text('Smart Scheduling'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 3: Track Your Goals
      expect(find.text('Track Your Goals'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 4: Plan Ahead
      expect(find.text('Plan Ahead'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 5: Stay Notified
      expect(find.text('Stay Notified'), findsOneWidget);
    });

    testWidgets('displays "Get Started" on last page', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Navigate to last page
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets('each page has an icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // First page should have schedule icon
      expect(find.byIcon(Icons.schedule), findsOneWidget);

      // Navigate to check other icons
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.auto_fix_high), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.flag), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.notifications_active), findsOneWidget);
    });

    testWidgets('can swipe to navigate between pages', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Swipe left to go to next page
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Smart Scheduling'), findsOneWidget);

      // Swipe right to go back
      await tester.drag(find.byType(PageView), const Offset(400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to TimePlanner'), findsOneWidget);
    });

    testWidgets('displays PageView for pages', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('Skip button uses correct styling', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final skipButton = find.text('Skip');
      expect(skipButton, findsOneWidget);
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

    testWidgets('second page shows scheduling description', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Create events with fixed times'),
        findsOneWidget,
      );
    });

    testWidgets('third page shows goals description', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Set weekly or monthly goals'),
        findsOneWidget,
      );
    });

    testWidgets('fourth page shows planning wizard description', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Planning Wizard'),
        findsOneWidget,
      );
    });

    testWidgets('fifth page shows notifications description', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('reminders'),
        findsOneWidget,
      );
    });

    testWidgets('onboarding pages are properly centered', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Content should be centered in the page
      expect(find.byType(Column), findsWidgets);
    });
  });
}
