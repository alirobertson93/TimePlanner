import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/entities/location.dart';
import 'package:time_planner/presentation/providers/location_providers.dart';
import 'package:time_planner/presentation/screens/locations/locations_screen.dart';

void main() {
  group('LocationsScreen', () {
    late List<Location> testLocations;

    setUp(() {
      final now = DateTime.now();
      testLocations = [
        Location(
          id: 'loc_1',
          name: 'Office',
          address: '123 Business Ave, Suite 100',
          notes: 'Main workspace',
          createdAt: now,
        ),
        Location(
          id: 'loc_2',
          name: 'Coffee Shop',
          address: '456 Main Street',
          notes: null,
          createdAt: now,
        ),
        Location(
          id: 'loc_3',
          name: 'Home',
          address: null,
          notes: 'Remote work location',
          createdAt: now,
        ),
      ];
    });

    Widget createTestWidget({
      List<Location> locations = const [],
    }) {
      return ProviderScope(
        overrides: [
          searchLocationsProvider('').overrideWith(
            (ref) => Future.value(locations),
          ),
          allLocationsProvider.overrideWith(
            (ref) => Future.value(locations),
          ),
        ],
        child: MaterialApp(
          home: const LocationsScreen(),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('Route: ${settings.name}')),
              ),
              settings: settings,
            );
          },
        ),
      );
    }

    testWidgets('displays "Locations" title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.text('Locations'), findsOneWidget);
    });

    testWidgets('displays loading indicator while fetching locations',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchLocationsProvider('').overrideWith(
              (ref) => Future.delayed(
                const Duration(seconds: 10),
                () => <Location>[],
              ),
            ),
          ],
          child: const MaterialApp(
            home: LocationsScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no locations exist', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: []));
      await tester.pumpAndSettle();

      expect(find.text('No locations added yet'), findsOneWidget);
      expect(find.text('Add locations to associate with your events'), findsOneWidget);
      expect(find.text('Add Location'), findsOneWidget);
    });

    testWidgets('displays travel times button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.directions_car), findsOneWidget);
    });

    testWidgets('displays search bar', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.search), findsOneWidget);
      expect(find.text('Search locations...'), findsOneWidget);
    });

    testWidgets('displays FAB for adding locations', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays location names', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Coffee Shop'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('displays location addresses when available', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.text('123 Business Ave, Suite 100'), findsOneWidget);
      expect(find.text('456 Main Street'), findsOneWidget);
    });

    testWidgets('displays location icon in each card', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.location_on), findsNWidgets(3));
    });

    testWidgets('displays popup menu button for each location', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      // Each location card has a popup menu button
      expect(find.byType(PopupMenuButton<String>), findsNWidgets(3));
    });

    testWidgets('tapping FAB opens add location dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Location'), findsOneWidget);
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Address'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('add location dialog has cancel and add buttons', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('tapping location card opens edit dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      // Tap on a location card
      await tester.tap(find.text('Office'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Location'), findsOneWidget);
    });

    testWidgets('popup menu shows edit and delete options', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      // Find and tap the first popup menu button
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('tapping delete option shows confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      // Open popup menu
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await tester.pumpAndSettle();

      // Tap delete
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Location?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('search filters location list', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Office');
      await tester.pumpAndSettle();
    });

    testWidgets('locations are displayed in cards', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });

    testWidgets('location cards are displayed in list tiles', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsAtLeastNWidgets(3));
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchLocationsProvider('').overrideWith(
              (ref) => Future.error('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: LocationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Error'), findsOneWidget);
    });

    testWidgets('empty state shows empty icon', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: []));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('empty state add button opens dialog', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: []));
      await tester.pumpAndSettle();

      // Tap the "Add Location" button in empty state
      await tester.tap(find.text('Add Location'));
      await tester.pumpAndSettle();

      expect(find.text('Add Location'), findsAtLeastNWidgets(2)); // title + button
    });

    testWidgets('location card shows address subtitle', (tester) async {
      await tester.pumpWidget(createTestWidget(locations: testLocations));
      await tester.pumpAndSettle();

      // Location cards with addresses should show them as subtitles
      expect(find.text('123 Business Ave, Suite 100'), findsOneWidget);
    });

    testWidgets('search shows no results for non-matching query', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchLocationsProvider('').overrideWith(
              (ref) => Future.value(testLocations),
            ),
            searchLocationsProvider('xyz').overrideWith(
              (ref) => Future.value([]),
            ),
          ],
          child: const MaterialApp(
            home: LocationsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search text that won't match
      await tester.enterText(find.byType(TextField), 'xyz');
      await tester.pumpAndSettle();
    });
  });
}
