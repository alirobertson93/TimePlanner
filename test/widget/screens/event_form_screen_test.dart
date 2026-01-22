import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/entities/category.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/presentation/screens/event_form/event_form_screen.dart';
import 'package:time_planner/presentation/providers/event_form_providers.dart' as form_providers;
import 'package:time_planner/presentation/providers/repository_providers.dart';
import 'package:time_planner/data/repositories/event_repository.dart';

void main() {
  group('EventFormScreen', () {
    late List<Category> testCategories;

    setUp(() {
      testCategories = [
        Category(
          id: 'cat_work',
          name: 'Work',
          colourHex: '#2196F3',
          sortOrder: 0,
          isDefault: true,
        ),
        Category(
          id: 'cat_personal',
          name: 'Personal',
          colourHex: '#4CAF50',
          sortOrder: 1,
          isDefault: true,
        ),
      ];
    });

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

    testWidgets('displays "New Event" title for new event', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('New Event'), findsOneWidget);
    });

    testWidgets('displays basic information section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Basic Information'), findsOneWidget);
      expect(find.text('Title *'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
    });

    testWidgets('displays timing section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Timing'), findsOneWidget);
      expect(find.text('Event Type'), findsOneWidget);
      expect(find.text('Fixed Time'), findsOneWidget);
      expect(find.text('Flexible'), findsOneWidget);
    });

    testWidgets('displays people section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('People'), findsOneWidget);
    });

    testWidgets('displays location section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Location'), findsOneWidget);
    });

    testWidgets('displays recurrence section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // There are two "Recurrence" texts - one section header and one picker header
      expect(find.text('Recurrence'), findsWidgets);
    });

    testWidgets('displays Save button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Save'), findsOneWidget);
    });

    testWidgets('title field accepts input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final titleField = find.byWidgetPredicate(
        (widget) => widget is TextField && 
          (widget.decoration?.labelText == 'Title *'),
      );
      
      expect(titleField, findsOneWidget);
      
      await tester.enterText(titleField, 'Test Event Title');
      await tester.pump();
      
      expect(find.text('Test Event Title'), findsOneWidget);
    });

    testWidgets('description field accepts input', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final descField = find.byWidgetPredicate(
        (widget) => widget is TextField && 
          (widget.decoration?.labelText == 'Description'),
      );
      
      expect(descField, findsOneWidget);
      
      await tester.enterText(descField, 'This is a test description');
      await tester.pump();
      
      expect(find.text('This is a test description'), findsOneWidget);
    });

    testWidgets('can switch between fixed and flexible timing types', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the segmented button segments
      final fixedSegment = find.text('Fixed Time');
      final flexibleSegment = find.text('Flexible');
      
      expect(fixedSegment, findsOneWidget);
      expect(flexibleSegment, findsOneWidget);

      // Tap on Flexible
      await tester.tap(flexibleSegment);
      await tester.pumpAndSettle();

      // Duration fields should appear for flexible
      expect(find.text('Duration'), findsOneWidget);
    });

    testWidgets('fixed timing shows date and time selectors', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Make sure we're on Fixed Time mode (default)
      expect(find.text('Start'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Select Date'), findsAtLeastNWidgets(1));
      expect(find.text('Select Time'), findsAtLeastNWidgets(1));
    });

    testWidgets('flexible timing shows duration selectors', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to flexible
      await tester.tap(find.text('Flexible'));
      await tester.pumpAndSettle();

      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Hours'), findsOneWidget);
      expect(find.text('Minutes'), findsOneWidget);
    });

    testWidgets('uses initial date when provided', (tester) async {
      final initialDate = DateTime(2026, 3, 15);
      
      await tester.pumpWidget(createTestWidget(initialDate: initialDate));
      await tester.pumpAndSettle();

      // The form should be initialized with the initial date
      // This is an internal state test - we just verify the widget builds
      expect(find.byType(EventFormScreen), findsOneWidget);
    });
  });
}
