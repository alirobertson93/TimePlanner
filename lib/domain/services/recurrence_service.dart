import '../entities/event.dart';
import '../entities/recurrence_rule.dart';
import '../enums/recurrence_frequency.dart';
import '../enums/recurrence_end_type.dart';

/// Service for expanding recurring events into individual event instances.
/// 
/// This service takes events with recurrence rules and generates individual
/// occurrences within a specified date range. It handles various recurrence
/// patterns including weekly, monthly, and yearly recurrences with specific
/// day constraints.
class RecurrenceService {
  RecurrenceService._();

  /// Expands a recurring event into individual instances within a date range.
  /// 
  /// Takes an event with a recurrence rule and generates all occurrences that
  /// fall within [rangeStart] to [rangeEnd]. Each occurrence is a copy of the
  /// original event with adjusted start/end times.
  /// 
  /// Returns a list of event instances. If the event is not recurring or has
  /// no start time, returns an empty list.
  static List<Event> expandRecurringEvent({
    required Event event,
    required RecurrenceRule rule,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    // Validate that event has required fields
    if (event.startTime == null || event.endTime == null) {
      return [];
    }

    final instances = <Event>[];
    final eventDuration = event.endTime!.difference(event.startTime!);
    
    // Get the first occurrence date (could be before rangeStart)
    DateTime currentDate = event.startTime!;
    
    // Generate occurrences
    int occurrenceCount = 0;
    
    while (true) {
      // Check end conditions
      if (rule.endType == RecurrenceEndType.afterOccurrences) {
        if (rule.occurrences != null && occurrenceCount >= rule.occurrences!) {
          break;
        }
      } else if (rule.endType == RecurrenceEndType.onDate) {
        if (rule.endDate != null && currentDate.isAfter(rule.endDate!)) {
          break;
        }
      }
      
      // Stop if we're beyond the query range
      if (currentDate.isAfter(rangeEnd)) {
        break;
      }
      
      // Check if this occurrence should be included based on the recurrence pattern
      if (_shouldIncludeOccurrence(currentDate, rule)) {
        // Only add if it falls within the query range
        if (!currentDate.isBefore(rangeStart) && !currentDate.isAfter(rangeEnd)) {
          final instanceStartTime = currentDate;
          final instanceEndTime = currentDate.add(eventDuration);
          
          instances.add(event.copyWith(
            startTime: instanceStartTime,
            endTime: instanceEndTime,
          ));
        }
        
        occurrenceCount++;
      }
      
      // Move to next potential occurrence
      currentDate = _getNextOccurrenceDate(currentDate, rule);
      
      // Safety check to prevent infinite loops
      if (instances.length > 1000) {
        break;
      }
    }
    
    return instances;
  }

  /// Checks if a specific date should be included based on the recurrence rule.
  /// 
  /// For weekly recurrence with byWeekDay constraints, this checks if the
  /// weekday matches. For other frequencies, all dates are included by default.
  static bool _shouldIncludeOccurrence(DateTime date, RecurrenceRule rule) {
    if (rule.frequency == RecurrenceFrequency.weekly && rule.byWeekDay != null) {
      // Check if the weekday is in the byWeekDay list (0 = Sunday, 6 = Saturday)
      // DateTime.weekday uses 1=Monday to 7=Sunday, so convert:
      // DateTime: 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
      // byWeekDay: 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat
      final weekday = date.weekday == 7 ? 0 : date.weekday; // Convert 7 (Sun) to 0
      return rule.byWeekDay!.contains(weekday);
    }
    
    if (rule.frequency == RecurrenceFrequency.monthly && rule.byMonthDay != null) {
      return rule.byMonthDay!.contains(date.day);
    }
    
    return true;
  }

  /// Calculates the next potential occurrence date based on the recurrence rule.
  /// 
  /// This advances the date by the appropriate interval (daily, weekly, monthly,
  /// or yearly). The returned date may not be an actual occurrence - use
  /// [_shouldIncludeOccurrence] to check.
  static DateTime _getNextOccurrenceDate(DateTime current, RecurrenceRule rule) {
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return current.add(Duration(days: rule.interval));
      
      case RecurrenceFrequency.weekly:
        // For weekly recurrence, advance by one day at a time to check each day
        // This allows byWeekDay constraints to work correctly
        return current.add(const Duration(days: 1));
      
      case RecurrenceFrequency.monthly:
        return _addMonths(current, rule.interval);
      
      case RecurrenceFrequency.yearly:
        return DateTime(
          current.year + rule.interval,
          current.month,
          current.day,
          current.hour,
          current.minute,
          current.second,
        );
    }
  }

  /// Adds months to a date, handling day overflow correctly.
  /// 
  /// For example, adding 1 month to Jan 31 results in Feb 28/29.
  static DateTime _addMonths(DateTime date, int months) {
    int newYear = date.year;
    int newMonth = date.month + months;
    
    while (newMonth > 12) {
      newMonth -= 12;
      newYear += 1;
    }
    
    while (newMonth < 1) {
      newMonth += 12;
      newYear -= 1;
    }
    
    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
    int newDay = date.day;
    final daysInNewMonth = DateTime(newYear, newMonth + 1, 0).day;
    if (newDay > daysInNewMonth) {
      newDay = daysInNewMonth;
    }
    
    return DateTime(
      newYear,
      newMonth,
      newDay,
      date.hour,
      date.minute,
      date.second,
    );
  }

  /// Expands a list of events, handling both recurring and non-recurring events.
  /// 
  /// For events with recurrence rules, generates all instances within the range.
  /// For non-recurring events that fall within the range, includes them as-is.
  /// 
  /// Requires a function to look up recurrence rules by ID.
  static List<Event> expandEvents({
    required List<Event> events,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    required RecurrenceRule? Function(String id) getRecurrenceRule,
  }) {
    final expandedEvents = <Event>[];
    
    for (final event in events) {
      if (event.isRecurring && event.recurrenceRuleId != null) {
        // Get the recurrence rule
        final rule = getRecurrenceRule(event.recurrenceRuleId!);
        if (rule != null) {
          // Expand this recurring event
          final instances = expandRecurringEvent(
            event: event,
            rule: rule,
            rangeStart: rangeStart,
            rangeEnd: rangeEnd,
          );
          expandedEvents.addAll(instances);
        } else {
          // Rule not found, include event as-is if it falls in range
          if (event.startTime != null &&
              !event.startTime!.isBefore(rangeStart) &&
              !event.startTime!.isAfter(rangeEnd)) {
            expandedEvents.add(event);
          }
        }
      } else {
        // Non-recurring event - include if it falls in range
        if (event.startTime != null &&
            !event.startTime!.isBefore(rangeStart) &&
            !event.startTime!.isAfter(rangeEnd)) {
          expandedEvents.add(event);
        }
      }
    }
    
    return expandedEvents;
  }
}
