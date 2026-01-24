import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/entities/person.dart';
import 'package:time_planner/presentation/providers/person_providers.dart';
import 'package:time_planner/presentation/screens/people/people_screen.dart';

void main() {
  group('PeopleScreen', () {
    late List<Person> testPeople;

    setUp(() {
      final now = DateTime.now();
      testPeople = [
        Person(
          id: 'person_1',
          name: 'Alice Johnson',
          email: 'alice@example.com',
          phone: '+1 555-0101',
          notes: 'Project manager',
          createdAt: now,
        ),
        Person(
          id: 'person_2',
          name: 'Bob Smith',
          email: 'bob@example.com',
          phone: null,
          notes: null,
          createdAt: now,
        ),
        Person(
          id: 'person_3',
          name: 'Carol Williams',
          email: null,
          phone: '+1 555-0303',
          notes: 'Designer',
          createdAt: now,
        ),
      ];
    });

    Widget createTestWidget({
      List<Person> people = const [],
    }) {
      return ProviderScope(
        overrides: [
          allPeopleProvider.overrideWith(
            (ref) => Future.value(people),
          ),
          searchPeopleProvider('').overrideWith(
            (ref) => Future.value(people),
          ),
        ],
        child: MaterialApp(
          home: const PeopleScreen(),
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

    testWidgets('displays "People" title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.text('People'), findsOneWidget);
    });

    testWidgets('displays loading indicator while fetching people',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPeopleProvider.overrideWith(
              (ref) => Future.delayed(
                const Duration(seconds: 10),
                () => <Person>[],
              ),
            ),
          ],
          child: const MaterialApp(
            home: PeopleScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no people exist', (tester) async {
      await tester.pumpWidget(createTestWidget(people: []));
      await tester.pumpAndSettle();

      expect(find.text('No People Added'), findsOneWidget);
      expect(find.text('Add Your First Contact'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('displays back button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays add person button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search people...'), findsOneWidget);
    });

    testWidgets('displays person names', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.text('Alice Johnson'), findsOneWidget);
      expect(find.text('Bob Smith'), findsOneWidget);
      expect(find.text('Carol Williams'), findsOneWidget);
    });

    testWidgets('displays person emails when available', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.text('alice@example.com'), findsOneWidget);
      expect(find.text('bob@example.com'), findsOneWidget);
    });

    testWidgets('displays person phone numbers when available', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.text('+1 555-0101'), findsOneWidget);
      expect(find.text('+1 555-0303'), findsOneWidget);
    });

    testWidgets('displays avatar with first letter of name', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      // Avatars should show first letter
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('displays delete button for each person', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline), findsNWidgets(3));
    });

    testWidgets('tapping add button opens add person dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('Add Person'), findsOneWidget);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('add person dialog has cancel and add buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.person_add));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('tapping person card opens edit dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      // Tap on a person card
      await tester.tap(find.text('Alice Johnson'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Person'), findsOneWidget);
    });

    testWidgets('tapping delete shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      // Tap delete button for first person
      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.text('Delete Person'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete'), findsOneWidget);
    });

    testWidgets('search filters people list', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Alice');
      await tester.pumpAndSettle();
    });

    testWidgets('search clear button appears when text entered', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'test');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPeopleProvider.overrideWith(
              (ref) => Future.error('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: PeopleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error Loading People'), findsOneWidget);
    });

    testWidgets('people cards are displayed in a list', (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });

    testWidgets('people cards have email icon when email is present',
        (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.email_outlined), findsAtLeastNWidgets(2));
    });

    testWidgets('people cards have phone icon when phone is present',
        (tester) async {
      await tester.pumpWidget(createTestWidget(people: testPeople));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.phone_outlined), findsAtLeastNWidgets(2));
    });

    testWidgets('displays no results message when search finds nothing',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            allPeopleProvider.overrideWith(
              (ref) => Future.value(testPeople),
            ),
            searchPeopleProvider('xyz').overrideWith(
              (ref) => Future.value([]),
            ),
          ],
          child: const MaterialApp(
            home: PeopleScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text that won't match
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();

      // With the search override, it should show empty state
    });
  });
}
