import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/day_view/day_view_screen.dart';
import '../presentation/screens/week_view/week_view_screen.dart';
import '../presentation/screens/event_form/event_form_screen.dart';
import '../presentation/screens/planning_wizard/planning_wizard_screen.dart';
import '../presentation/screens/goals_dashboard/goals_dashboard_screen.dart';
import '../presentation/screens/goal_form/goal_form_screen.dart';
import '../presentation/screens/people/people_screen.dart';
import '../presentation/screens/locations/locations_screen.dart';
import '../presentation/screens/settings/settings_screen.dart';
import '../presentation/screens/notifications/notifications_screen.dart';
import '../presentation/screens/travel_times/travel_times_screen.dart';

/// Application router configuration
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/day',
        name: 'day_view',
        builder: (context, state) => const DayViewScreen(),
      ),
      GoRoute(
        path: '/week',
        name: 'week_view',
        builder: (context, state) => const WeekViewScreen(),
      ),
      GoRoute(
        path: '/event/new',
        name: 'event_new',
        builder: (context, state) {
          final initialDate = state.extra as DateTime?;
          return EventFormScreen(initialDate: initialDate);
        },
      ),
      GoRoute(
        path: '/event/:id/edit',
        name: 'event_edit',
        builder: (context, state) {
          final eventId = state.pathParameters['id'];
          return EventFormScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/plan',
        name: 'planning_wizard',
        builder: (context, state) => const PlanningWizardScreen(),
      ),
      GoRoute(
        path: '/goals',
        name: 'goals_dashboard',
        builder: (context, state) => const GoalsDashboardScreen(),
      ),
      GoRoute(
        path: '/goal/new',
        name: 'goal_new',
        builder: (context, state) => const GoalFormScreen(),
      ),
      GoRoute(
        path: '/goal/:id/edit',
        name: 'goal_edit',
        builder: (context, state) {
          final goalId = state.pathParameters['id'];
          return GoalFormScreen(goalId: goalId);
        },
      ),
      GoRoute(
        path: '/people',
        name: 'people',
        builder: (context, state) => const PeopleScreen(),
      ),
      GoRoute(
        path: '/locations',
        name: 'locations',
        builder: (context, state) => const LocationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/travel-times',
        name: 'travel_times',
        builder: (context, state) => const TravelTimesScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
