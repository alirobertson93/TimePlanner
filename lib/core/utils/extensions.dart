/// Dart extensions for common operations
extension DateTimeExtensions on DateTime {
  /// Returns true if this DateTime is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Returns true if this DateTime is in the past
  bool get isPast => isBefore(DateTime.now());

  /// Returns true if this DateTime is in the future
  bool get isFuture => isAfter(DateTime.now());
}

extension DurationExtensions on Duration {
  /// Converts duration to minutes
  int get inMinutesRounded => (inSeconds / 60).round();

  /// Formats duration as HH:MM
  String toHoursMinutes() {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

extension StringExtensions on String {
  /// Returns true if the string is a valid hex color
  bool get isValidHexColor {
    return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(this);
  }

  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
