import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../presentation/screens/onboarding/onboarding_screen.dart';
import '../presentation/providers/onboarding_providers.dart';

/// Provider for the router
final routerProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// Application router configuration
class AppRouter {
  AppRouter._();

  static GoRouter createRouter(Ref ref) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        // Check if we should redirect to onboarding
        final needsOnboarding = ref.read(needsOnboardingProvider);
        final isOnOnboarding = state.matchedLocation == '/onboarding';
        
        // If needs onboarding and not already there, redirect
        if (needsOnboarding && !isOnOnboarding) {
          return '/onboarding';
        }
        
        // If doesn't need onboarding but on onboarding page, redirect to home
        if (!needsOnboarding && isOnOnboarding) {
          return '/';
        }
        
        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
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

  /// Legacy static router for backwards compatibility
  /// Use routerProvider instead for new code
  static GoRouter get router => GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
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
