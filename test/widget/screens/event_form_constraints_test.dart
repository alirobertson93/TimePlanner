import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/presentation/screens/event_form/event_form_screen.dart';
import 'package:time_planner/presentation/providers/event_form_providers.dart' as form_providers;

void main() {
  group('EventFormScreen Constraints', () {
    Widget createTestWidget({
      String? eventId,
      DateTime? initialDate,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: EventFormScreen(
            eventId: eventId,
            initialDate: initialDate,
          ),
        ),
      );
    }

    testWidgets('displays scheduling options section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Scheduling Options should be visible as a collapsible section
      expect(find.text('Scheduling Options'), findsOneWidget);
      expect(find.text('Advanced settings for the scheduler'), findsOneWidget);
    });

    testWidgets('scheduling options is collapsed by default', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The constraint toggles should not be visible until expanded
      // For fixed events, "Allow app to suggest changes" should exist but not visible
      expect(find.text('Allow app to suggest changes'), findsNothing);
    });

    testWidgets('can expand scheduling options section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap to expand the scheduling options
      await tester.tap(find.text('Scheduling Options'));
      await tester.pumpAndSettle();

      // For fixed events (default), "Allow app to suggest changes" should be visible
      expect(find.text('Allow app to suggest changes'), findsOneWidget);
      expect(
        find.text('Let the scheduler suggest moving this if there are conflicts'),
        findsOneWidget,
      );
    });

    testWidgets('fixed event shows appCanMove toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand scheduling options
      await tester.tap(find.text('Scheduling Options'));
      await tester.pumpAndSettle();

      // Verify the toggle for fixed events is present
      expect(find.text('Allow app to suggest changes'), findsOneWidget);
      
      // Find the SwitchListTile for "Allow app to suggest changes"
      final switchTile = find.byWidgetPredicate(
        (widget) => widget is SwitchListTile && 
          (widget.title as Text).data == 'Allow app to suggest changes',
      );
      expect(switchTile, findsOneWidget);
    });

    testWidgets('flexible event shows appCanResize toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to flexible timing
      await tester.tap(find.text('Flexible'));
      await tester.pumpAndSettle();

      // Expand scheduling options
      await tester.tap(find.text('Scheduling Options'));
      await tester.pumpAndSettle();

      // Verify the toggle for flexible events is present
      expect(find.text('Allow duration changes'), findsOneWidget);
      expect(
        find.text('Let the scheduler shorten this if needed'),
        findsOneWidget,
      );
    });

    testWidgets('lock toggle only shows for flexible events in edit mode with scheduled time', (tester) async {
      // For new events, the lock toggle should NOT be shown
      // because there's no scheduled time yet
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to flexible timing
      await tester.tap(find.text('Flexible'));
      await tester.pumpAndSettle();

      // Expand scheduling options
      await tester.tap(find.text('Scheduling Options'));
      await tester.pumpAndSettle();

      // Lock toggle should NOT appear for new events (no scheduled time)
      expect(find.text('Lock this time'), findsNothing);
    });

    testWidgets('changing timing type resets constraint fields', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Start with Fixed (default)
      // Expand scheduling options and verify initial state
      await tester.tap(find.text('Scheduling Options'));
      await tester.pumpAndSettle();

      // The fixed event toggle should be present
      expect(find.text('Allow app to suggest changes'), findsOneWidget);

      // Switch to Flexible
      await tester.tap(find.text('Flexible'));
      await tester.pumpAndSettle();

      // Now flexible options should be visible
      expect(find.text('Allow duration changes'), findsOneWidget);
      // Fixed event toggle should no longer be visible
      expect(find.text('Allow app to suggest changes'), findsNothing);

      // Switch back to Fixed
      await tester.tap(find.text('Fixed Time'));
      await tester.pumpAndSettle();

      // Fixed event toggle should be visible again
      expect(find.text('Allow app to suggest changes'), findsOneWidget);
      // Flexible event toggle should no longer be visible
      expect(find.text('Allow duration changes'), findsNothing);
    });

    testWidgets('scheduling options has tune icon', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // The tune icon should be visible in the expansion tile
      expect(find.byIcon(Icons.tune), findsOneWidget);
    });
  });
}
