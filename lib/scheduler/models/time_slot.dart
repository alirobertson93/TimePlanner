/// Represents a 15-minute time slot
class TimeSlot {
  TimeSlot(this.start);

  final DateTime start;

  /// Get end time of this slot (start + 15 minutes)
  DateTime get end => start.add(const Duration(minutes: 15));

  /// Get next time slot
  TimeSlot get next => TimeSlot(end);

  /// Get previous time slot
  TimeSlot get previous => TimeSlot(start.subtract(const Duration(minutes: 15)));

  /// Check if this slot overlaps with another
  bool overlaps(TimeSlot other) {
    return start.isBefore(other.end) && end.isAfter(other.start);
  }

  /// Check if this slot contains a specific time
  bool contains(DateTime time) {
    return (time.isAfter(start) || time.isAtSameMomentAs(start)) &&
        time.isBefore(end);
  }

  /// Convert duration to slot count
  static int durationToSlots(Duration duration) {
    return (duration.inMinutes / 15).ceil();
  }

  /// Round down to nearest 15-minute mark
  static DateTime roundDown(DateTime dt) {
    final minutes = (dt.minute ~/ 15) * 15;
    return DateTime(dt.year, dt.month, dt.day, dt.hour, minutes);
  }

  /// Round up to nearest 15-minute mark
  static DateTime roundUp(DateTime dt) {
    if (dt.minute % 15 == 0 && dt.second == 0 && dt.millisecond == 0) {
      return dt;
    }
    final minutes = ((dt.minute ~/ 15) + 1) * 15;
    if (minutes >= 60) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour + 1, 0);
    }
    return DateTime(dt.year, dt.month, dt.day, dt.hour, minutes);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot && other.start == start;
  }

  @override
  int get hashCode => start.hashCode;

  @override
  String toString() => 'TimeSlot($start - $end)';
}
