import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../presentation/screens/home_screen.dart';
import '../presentation/screens/day_view/day_view_screen.dart';
import '../presentation/screens/week_view/week_view_screen.dart';
import '../presentation/screens/event_form/event_form_screen.dart';
import '../presentation/screens/planning_wizard/planning_wizard_screen.dart';
import '../presentation/screens/goals_dashboard/goals_dashboard_screen.dart';

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
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Text('Error: ${state.error}'),
      ),
    ),
  );
}
