import 'dart:convert';
import '../enums/recurrence_frequency.dart';
import '../enums/recurrence_end_type.dart';

/// Pure domain entity representing a recurrence rule for repeating events
class RecurrenceRule {
  const RecurrenceRule({
    required this.id,
    required this.frequency,
    this.interval = 1,
    this.byWeekDay,
    this.byMonthDay,
    required this.endType,
    this.endDate,
    this.occurrences,
    required this.createdAt,
  });

  /// Unique identifier for the recurrence rule
  final String id;

  /// How often the event repeats (daily, weekly, monthly, yearly)
  final RecurrenceFrequency frequency;

  /// Interval between occurrences (e.g., 2 for "every 2 weeks")
  final int interval;

  /// Days of the week for weekly recurrence (0 = Sunday, 6 = Saturday)
  /// Stored as JSON array, e.g., [1, 3, 5] for Mon, Wed, Fri
  final List<int>? byWeekDay;

  /// Days of the month for monthly recurrence (1-31)
  /// Stored as JSON array, e.g., [1, 15] for 1st and 15th
  final List<int>? byMonthDay;

  /// When the recurrence ends
  final RecurrenceEndType endType;

  /// End date for the recurrence (when endType is onDate)
  final DateTime? endDate;

  /// Number of occurrences (when endType is afterOccurrences)
  final int? occurrences;

  /// When this rule was created
  final DateTime createdAt;

  /// Creates a copy of this recurrence rule with the given fields replaced
  RecurrenceRule copyWith({
    String? id,
    RecurrenceFrequency? frequency,
    int? interval,
    List<int>? byWeekDay,
    List<int>? byMonthDay,
    RecurrenceEndType? endType,
    DateTime? endDate,
    int? occurrences,
    DateTime? createdAt,
  }) {
    return RecurrenceRule(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      byWeekDay: byWeekDay ?? this.byWeekDay,
      byMonthDay: byMonthDay ?? this.byMonthDay,
      endType: endType ?? this.endType,
      endDate: endDate ?? this.endDate,
      occurrences: occurrences ?? this.occurrences,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Convert byWeekDay list to JSON string for storage
  String? get byWeekDayJson => byWeekDay != null ? jsonEncode(byWeekDay) : null;

  /// Convert byMonthDay list to JSON string for storage
  String? get byMonthDayJson => byMonthDay != null ? jsonEncode(byMonthDay) : null;

  /// Create byWeekDay list from JSON string
  static List<int>? byWeekDayFromJson(String? json) {
    if (json == null) return null;
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.cast<int>();
  }

  /// Create byMonthDay list from JSON string
  static List<int>? byMonthDayFromJson(String? json) {
    if (json == null) return null;
    final List<dynamic> decoded = jsonDecode(json);
    return decoded.cast<int>();
  }

  /// Get a human-readable description of the recurrence pattern
  String get description {
    final buffer = StringBuffer();
    
    // Frequency description
    if (interval == 1) {
      switch (frequency) {
        case RecurrenceFrequency.daily:
          buffer.write('Every day');
          break;
        case RecurrenceFrequency.weekly:
          buffer.write('Every week');
          break;
        case RecurrenceFrequency.monthly:
          buffer.write('Every month');
          break;
        case RecurrenceFrequency.yearly:
          buffer.write('Every year');
          break;
      }
    } else {
      switch (frequency) {
        case RecurrenceFrequency.daily:
          buffer.write('Every $interval days');
          break;
        case RecurrenceFrequency.weekly:
          buffer.write('Every $interval weeks');
          break;
        case RecurrenceFrequency.monthly:
          buffer.write('Every $interval months');
          break;
        case RecurrenceFrequency.yearly:
          buffer.write('Every $interval years');
          break;
      }
    }

    // Day constraints
    if (byWeekDay != null && byWeekDay!.isNotEmpty) {
      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      final days = byWeekDay!.map((d) => dayNames[d]).join(', ');
      buffer.write(' on $days');
    }

    if (byMonthDay != null && byMonthDay!.isNotEmpty) {
      final days = byMonthDay!.join(', ');
      buffer.write(' on day(s) $days');
    }

    // End condition
    switch (endType) {
      case RecurrenceEndType.never:
        // No end condition to show
        break;
      case RecurrenceEndType.afterOccurrences:
        if (occurrences != null) {
          buffer.write(', $occurrences times');
        }
        break;
      case RecurrenceEndType.onDate:
        if (endDate != null) {
          buffer.write(', until ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}');
        }
        break;
    }

    return buffer.toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecurrenceRule &&
        other.id == id &&
        other.frequency == frequency &&
        other.interval == interval &&
        _listEquals(other.byWeekDay, byWeekDay) &&
        _listEquals(other.byMonthDay, byMonthDay) &&
        other.endType == endType &&
        other.endDate == endDate &&
        other.occurrences == occurrences &&
        other.createdAt == createdAt;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      frequency,
      interval,
      byWeekDay?.join(','),
      byMonthDay?.join(','),
      endType,
      endDate,
      occurrences,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'RecurrenceRule(id: $id, frequency: $frequency, interval: $interval, endType: $endType)';
  }
}
