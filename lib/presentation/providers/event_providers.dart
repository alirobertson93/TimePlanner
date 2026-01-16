import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/event.dart';
import '../../core/utils/date_utils.dart';
import 'repository_providers.dart';

part 'event_providers.g.dart';

/// Provider for events on a specific date
@riverpod
Stream<List<Event>> eventsForDate(Ref ref, DateTime date) {
  final repository = ref.watch(eventRepositoryProvider);
  final start = DateTimeUtils.startOfDay(date);
  final end = DateTimeUtils.endOfDay(date);
  
  // Get events in the date range
  return Stream.fromFuture(repository.getEventsInRange(start, end));
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
