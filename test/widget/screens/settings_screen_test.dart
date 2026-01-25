import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/presentation/providers/settings_providers.dart';
import 'package:time_planner/presentation/screens/settings/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    Widget createTestWidget({
      AppSettings? settings,
    }) {
      return ProviderScope(
        overrides: [
          settingsProvider.overrideWith(
            (ref) => SettingsNotifier(null),
          ),
        ],
        child: MaterialApp(
          home: const SettingsScreen(),
          onGenerateRoute: (settingsRoute) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('Route: ${settingsRoute.name}')),
              ),
            );
          },
        ),
      );
    }

    testWidgets('displays "Settings" title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('displays back button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays Schedule section header', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsOneWidget);
    });

    testWidgets('displays Time Slot Duration setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Time Slot Duration'), findsOneWidget);
    });

    testWidgets('displays Work Hours setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Work Hours'), findsOneWidget);
    });

    testWidgets('displays First Day of Week setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('First Day of Week'), findsOneWidget);
    });

    testWidgets('displays Default Event Settings section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Default Event Settings'), findsOneWidget);
    });

    testWidgets('displays Default Event Duration setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Default Event Duration'), findsOneWidget);
    });

    testWidgets('displays Events Movable by Default toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Events Movable by Default'), findsOneWidget);
    });

    testWidgets('displays Events Resizable by Default toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Events Resizable by Default'), findsOneWidget);
    });

    testWidgets('displays Notifications section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('displays Event Reminders toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Event Reminders'), findsOneWidget);
    });

    testWidgets('displays Default Reminder Time setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Default Reminder Time'), findsOneWidget);
    });

    testWidgets('displays Goal Progress Alerts toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Goal Progress Alerts'), findsOneWidget);
    });

    testWidgets('displays Appearance section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('displays Theme setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('displays About section', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays Version setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('displays Terms of Service setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
    });

    testWidgets('displays Privacy Policy setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('displays switch toggles for boolean settings', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Should have switches for toggle settings
      expect(find.byType(SwitchListTile), findsAtLeastNWidgets(4));
    });

    testWidgets('tapping Time Slot Duration opens dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Time Slot Duration'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('5 minutes'), findsOneWidget);
      expect(find.text('15 minutes'), findsOneWidget);
    });

    testWidgets('tapping Work Hours opens dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Work Hours'));
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('tapping Theme opens dialog with options', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();

      // Dialog should show theme options
      expect(find.byType(SimpleDialog), findsOneWidget);
      expect(find.text('System default'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('tapping Terms of Service opens dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Terms of Service'));
      await tester.pumpAndSettle();

      // Dialog should appear with title
      expect(find.text('Terms of Service'), findsAtLeastNWidgets(2)); // title + setting
    });

    testWidgets('tapping Privacy Policy opens dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();

      // Dialog should appear with title
      expect(find.text('Privacy Policy'), findsAtLeastNWidgets(2)); // title + setting
    });

    testWidgets('settings use correct icons', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.schedule), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);
      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('switch can be toggled', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Find the first switch
      final switches = find.byType(Switch);
      expect(switches, findsAtLeastNWidgets(1));

      // Tap the first switch
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
    });

    testWidgets('displays Replay Onboarding setting', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Replay Onboarding'), findsOneWidget);
      expect(find.text('See the welcome wizard again'), findsOneWidget);
    });

    testWidgets('displays play_circle_outline icon for Replay Onboarding', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
    });

    testWidgets('tapping Replay Onboarding opens confirmation dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Replay Onboarding'));
      await tester.pumpAndSettle();

      // Dialog should appear with title and content
      expect(find.text('Replay Onboarding?'), findsOneWidget);
      expect(find.text('This will show the welcome wizard again. Your data will not be affected.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Show Wizard'), findsOneWidget);
    });

    testWidgets('Cancel button closes Replay Onboarding dialog', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Replay Onboarding'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.text('Replay Onboarding?'), findsNothing);
    });
  });
}
