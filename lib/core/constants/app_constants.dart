/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// Default time slot duration in minutes
  static const int defaultTimeSlotDuration = 30;

  /// Minimum event duration in minutes
  static const int minEventDuration = 15;

  /// Maximum event duration in minutes (24 hours)
  static const int maxEventDuration = 1440;

  /// Default work day start hour (24-hour format)
  static const int defaultWorkDayStart = 9;

  /// Default work day end hour (24-hour format)
  static const int defaultWorkDayEnd = 17;
}
