import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/route_constants.dart';
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
import '../presentation/screens/onboarding/enhanced_onboarding_screen.dart';
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
      initialLocation: RouteConstants.home,
      redirect: (context, state) {
        // Check if we should redirect to onboarding
        final needsOnboarding = ref.read(needsOnboardingProvider);
        final isOnOnboarding = state.matchedLocation == RouteConstants.onboarding;

        // During loading (null), don't redirect - let the current navigation proceed
        if (needsOnboarding == null) {
          return null;
        }

        // If needs onboarding and not already there, redirect
        if (needsOnboarding && !isOnOnboarding) {
          return RouteConstants.onboarding;
        }

        // If doesn't need onboarding but on onboarding page, redirect to home
        if (!needsOnboarding && isOnOnboarding) {
          return RouteConstants.home;
        }

        return null; // No redirect needed
      },
      routes: [
        GoRoute(
          path: RouteConstants.home,
          name: RouteConstants.homeName,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: RouteConstants.onboarding,
          name: RouteConstants.onboardingName,
          builder: (context, state) => const EnhancedOnboardingScreen(),
        ),
        GoRoute(
          path: RouteConstants.dayView,
          name: RouteConstants.dayViewName,
          builder: (context, state) => const DayViewScreen(),
        ),
        GoRoute(
          path: RouteConstants.weekView,
          name: RouteConstants.weekViewName,
          builder: (context, state) => const WeekViewScreen(),
        ),
        GoRoute(
          path: RouteConstants.eventNew,
          name: RouteConstants.eventNewName,
          builder: (context, state) {
            final initialDate = state.extra as DateTime?;
            return EventFormScreen(initialDate: initialDate);
          },
        ),
        GoRoute(
          path: RouteConstants.eventEdit,
          name: RouteConstants.eventEditName,
          builder: (context, state) {
            final eventId = state.pathParameters['id'];
            return EventFormScreen(eventId: eventId);
          },
        ),
        GoRoute(
          path: RouteConstants.planningWizard,
          name: RouteConstants.planningWizardName,
          builder: (context, state) => const PlanningWizardScreen(),
        ),
        GoRoute(
          path: RouteConstants.goalsDashboard,
          name: RouteConstants.goalsDashboardName,
          builder: (context, state) => const GoalsDashboardScreen(),
        ),
        GoRoute(
          path: RouteConstants.goalNew,
          name: RouteConstants.goalNewName,
          builder: (context, state) => const GoalFormScreen(),
        ),
        GoRoute(
          path: RouteConstants.goalEdit,
          name: RouteConstants.goalEditName,
          builder: (context, state) {
            final goalId = state.pathParameters['id'];
            return GoalFormScreen(goalId: goalId);
          },
        ),
        GoRoute(
          path: RouteConstants.people,
          name: RouteConstants.peopleName,
          builder: (context, state) => const PeopleScreen(),
        ),
        GoRoute(
          path: RouteConstants.locations,
          name: RouteConstants.locationsName,
          builder: (context, state) => const LocationsScreen(),
        ),
        GoRoute(
          path: RouteConstants.settings,
          name: RouteConstants.settingsName,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: RouteConstants.notifications,
          name: RouteConstants.notificationsName,
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: RouteConstants.travelTimes,
          name: RouteConstants.travelTimesName,
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

}
