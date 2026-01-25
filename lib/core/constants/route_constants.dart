/// Route constants for navigation throughout the app.
/// 
/// Using constants instead of string literals for routes provides:
/// - Compile-time error checking
/// - Easy refactoring
/// - Centralized route management
class RouteConstants {
  RouteConstants._();

  // Route Paths
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String dayView = '/day';
  static const String weekView = '/week';
  static const String eventNew = '/event/new';
  static const String eventEdit = '/event/:id/edit';
  static const String planningWizard = '/plan';
  static const String goalsDashboard = '/goals';
  static const String goalNew = '/goal/new';
  static const String goalEdit = '/goal/:id/edit';
  static const String people = '/people';
  static const String locations = '/locations';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  static const String travelTimes = '/travel-times';

  // Route Names
  static const String homeName = 'home';
  static const String onboardingName = 'onboarding';
  static const String dayViewName = 'day_view';
  static const String weekViewName = 'week_view';
  static const String eventNewName = 'event_new';
  static const String eventEditName = 'event_edit';
  static const String planningWizardName = 'planning_wizard';
  static const String goalsDashboardName = 'goals_dashboard';
  static const String goalNewName = 'goal_new';
  static const String goalEditName = 'goal_edit';
  static const String peopleName = 'people';
  static const String locationsName = 'locations';
  static const String settingsName = 'settings';
  static const String notificationsName = 'notifications';
  static const String travelTimesName = 'travel_times';

  /// Builds the event edit path for a given event ID
  static String eventEditPath(String id) => '/event/$id/edit';

  /// Builds the goal edit path for a given goal ID
  static String goalEditPath(String id) => '/goal/$id/edit';
}
