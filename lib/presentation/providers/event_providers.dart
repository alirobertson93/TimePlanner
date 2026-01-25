import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/recurrence_rule.dart';
import '../../domain/services/recurrence_service.dart';
import '../../core/utils/date_utils.dart';
import 'repository_providers.dart';

part 'event_providers.g.dart';

/// Provider for events on a specific date (with recurrence expansion)
@riverpod
Stream<List<Event>> eventsForDate(EventsForDateRef ref, DateTime date) async* {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final recurrenceRepository = ref.watch(recurrenceRuleRepositoryProvider);
  
  final start = DateTimeUtils.startOfDay(date);
  final end = DateTimeUtils.endOfDay(date);
  
  // Get all events (including recurring events that may have started before this date)
  // We need a wider range to catch recurring events that started in the past
  final searchStart = start.subtract(const Duration(days: 365)); // Look back 1 year
  final allEvents = await eventRepository.getEventsInRange(searchStart, end);
  
  // Get all recurrence rules that might be needed
  final recurrenceRuleIds = allEvents
      .where((e) => e.recurrenceRuleId != null)
      .map((e) => e.recurrenceRuleId!)
      .toSet();
  
  final recurrenceRulesMap = <String, RecurrenceRule>{};
  for (final ruleId in recurrenceRuleIds) {
    final rule = await recurrenceRepository.getById(ruleId);
    if (rule != null) {
      recurrenceRulesMap[ruleId] = rule;
    }
  }
  
  // Expand recurring events
  final expandedEvents = RecurrenceService.expandEvents(
    events: allEvents,
    rangeStart: start,
    rangeEnd: end,
    getRecurrenceRule: (id) => recurrenceRulesMap[id],
  );
  
  yield expandedEvents;
}

/// Provider for the currently selected date
@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    // Default to today
    return DateTime.now();
  }

  /// Set a specific date
  void setDate(DateTime date) {
    state = date;
  }

  /// Move to the next day
  void nextDay() {
    state = state.add(const Duration(days: 1));
  }

  /// Move to the previous day
  void previousDay() {
    state = state.subtract(const Duration(days: 1));
  }

  /// Move to today
  void today() {
    state = DateTime.now();
  }
}

/// Delete an event by ID
@riverpod
Future<void> deleteEvent(DeleteEventRef ref, String eventId) async {
  final repository = ref.watch(eventRepositoryProvider);
  await repository.delete(eventId);
  
  // Invalidate the events provider to refresh the list
  ref.invalidate(eventsForDateProvider);
}

/// Provider for events in a week starting from the given date (with recurrence expansion)
@riverpod
Stream<List<Event>> eventsForWeek(EventsForWeekRef ref, DateTime weekStart) async* {
  final eventRepository = ref.watch(eventRepositoryProvider);
  final recurrenceRepository = ref.watch(recurrenceRuleRepositoryProvider);
  
  final start = DateTimeUtils.startOfDay(weekStart);
  final end = DateTimeUtils.endOfDay(weekStart.add(const Duration(days: 6)));
  
  // Get all events (including recurring events that may have started before this week)
  // We need a wider range to catch recurring events that started in the past
  final searchStart = start.subtract(const Duration(days: 365)); // Look back 1 year
  final allEvents = await eventRepository.getEventsInRange(searchStart, end);
  
  // Get all recurrence rules that might be needed
  final recurrenceRuleIds = allEvents
      .where((e) => e.recurrenceRuleId != null)
      .map((e) => e.recurrenceRuleId!)
      .toSet();
  
  final recurrenceRulesMap = <String, RecurrenceRule>{};
  for (final ruleId in recurrenceRuleIds) {
    final rule = await recurrenceRepository.getById(ruleId);
    if (rule != null) {
      recurrenceRulesMap[ruleId] = rule;
    }
  }
  
  // Expand recurring events
  final expandedEvents = RecurrenceService.expandEvents(
    events: allEvents,
    rangeStart: start,
    rangeEnd: end,
    getRecurrenceRule: (id) => recurrenceRulesMap[id],
  );
  
  yield expandedEvents;
}
