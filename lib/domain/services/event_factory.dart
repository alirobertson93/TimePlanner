import 'package:uuid/uuid.dart';
import '../entities/event.dart';
import '../enums/timing_type.dart';
import '../enums/event_status.dart';

/// Factory class for creating Event entities from various input sources.
/// 
/// This class encapsulates the complex DateTime assembly logic that was
/// previously scattered in the presentation layer (event_form_providers.dart).
/// 
/// By moving this logic to the domain layer:
/// 1. Business logic is centralized and testable
/// 2. Presentation layer stays focused on UI concerns
/// 3. Event creation is consistent across the application
/// 
/// Recommended by: next-steps.md architecture audit (section 8)
class EventFactory {
  EventFactory._();

  /// Creates a new Event from form state parameters.
  /// 
  /// For fixed timing events, combines date and time components into DateTime.
  /// For flexible events, uses duration instead of specific times.
  static Event createFromFormState({
    required String? existingId,
    required String title,
    String? description,
    required TimingType timingType,
    DateTime? startDate,
    int? startHour,
    int? startMinute,
    DateTime? endDate,
    int? endHour,
    int? endMinute,
    int durationHours = 0,
    int durationMinutes = 0,
    String? categoryId,
    String? locationId,
    String? recurrenceRuleId,
    required DateTime createdAt,
    required DateTime updatedAt,
    EventStatus status = EventStatus.pending,
  }) {
    final uuid = const Uuid();
    final eventId = existingId ?? uuid.v4();

    // Assemble DateTime for fixed timing events
    DateTime? startTime;
    DateTime? endTime;
    Duration? duration;

    if (timingType == TimingType.fixed) {
      if (startDate != null && startHour != null && startMinute != null) {
        startTime = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
          startHour,
          startMinute,
        );
      }
      if (endDate != null && endHour != null && endMinute != null) {
        endTime = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
          endHour,
          endMinute,
        );
      }
    } else {
      // Flexible timing - use duration
      duration = Duration(hours: durationHours, minutes: durationMinutes);
    }

    return Event(
      id: eventId,
      name: title.trim(),
      description: description?.trim().isEmpty == true ? null : description?.trim(),
      timingType: timingType,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      categoryId: categoryId,
      locationId: locationId,
      recurrenceRuleId: recurrenceRuleId,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Validates event creation parameters before creating.
  /// 
  /// Returns null if valid, or an error message if invalid.
  static String? validateEventParams({
    required String title,
    required TimingType timingType,
    DateTime? startDate,
    int? startHour,
    int? startMinute,
    DateTime? endDate,
    int? endHour,
    int? endMinute,
    int durationHours = 0,
    int durationMinutes = 0,
  }) {
    // Title validation
    if (title.trim().isEmpty) {
      return 'Title is required';
    }

    // Timing validation
    if (timingType == TimingType.fixed) {
      if (startDate == null || startHour == null || startMinute == null) {
        return 'Start date and time are required for fixed events';
      }
      if (endDate == null || endHour == null || endMinute == null) {
        return 'End date and time are required for fixed events';
      }

      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        startHour,
        startMinute,
      );

      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        endHour,
        endMinute,
      );

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        return 'End time must be after start time';
      }
    } else {
      // Flexible event - validate duration values
      if (durationHours < 0 || durationMinutes < 0) {
        return 'Duration values cannot be negative';
      }
      if (durationHours == 0 && durationMinutes == 0) {
        return 'Duration must be greater than 0';
      }
    }

    return null;
  }

  /// Creates a copy of an existing event with updated times.
  /// 
  /// Useful for scheduling operations where event times need to be adjusted.
  static Event copyWithScheduledTimes({
    required Event original,
    required DateTime newStartTime,
    required DateTime newEndTime,
  }) {
    return original.copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
      updatedAt: DateTime.now(),
    );
  }
}
