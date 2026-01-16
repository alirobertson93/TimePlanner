/// Date and time utility functions
class DateTimeUtils {
  DateTimeUtils._();

  /// Returns the start of the day for a given DateTime
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Returns the end of the day for a given DateTime
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }

  /// Returns the start of the week for a given DateTime
  static DateTime startOfWeek(DateTime date) {
    final daysToSubtract = date.weekday - DateTime.monday;
    return startOfDay(date.subtract(Duration(days: daysToSubtract)));
  }

  /// Returns the end of the week for a given DateTime
  static DateTime endOfWeek(DateTime date) {
    final daysToAdd = DateTime.sunday - date.weekday;
    return endOfDay(date.add(Duration(days: daysToAdd)));
  }

  /// Checks if two dates are on the same day
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Rounds a DateTime to the nearest interval in minutes
  static DateTime roundToInterval(DateTime dateTime, int intervalMinutes) {
    final minutes = dateTime.minute;
    final roundedMinutes = (minutes / intervalMinutes).round() * intervalMinutes;
    return DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      roundedMinutes,
    );
  }

  /// Checks if a date range overlaps with another date range
  static bool rangesOverlap(
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }
}
