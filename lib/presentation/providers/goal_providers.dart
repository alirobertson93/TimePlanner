import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/goal_type.dart';
import '../../domain/enums/goal_metric.dart';
import '../../domain/enums/goal_period.dart';
import '../../domain/enums/event_status.dart';
import 'repository_providers.dart';

part 'goal_providers.g.dart';

/// Status of a goal's progress
enum GoalProgressStatus {
  onTrack,
  atRisk,
  behind,
}

/// Model representing a goal with its calculated progress
class GoalProgress {
  const GoalProgress({
    required this.goal,
    required this.currentValue,
    required this.targetValue,
    required this.periodStart,
    required this.periodEnd,
    required this.status,
  });

  final Goal goal;
  final double currentValue;
  final int targetValue;
  final DateTime periodStart;
  final DateTime periodEnd;
  final GoalProgressStatus status;

  /// Progress percentage (0.0 to 1.0)
  double get progressPercent {
    if (targetValue == 0) return 1.0;
    return (currentValue / targetValue).clamp(0.0, 1.0);
  }

  /// Progress percentage for display (0 to 100)
  int get progressPercentDisplay => (progressPercent * 100).round();

  /// Formatted current value string
  String get currentValueDisplay {
    if (goal.metric == GoalMetric.hours) {
      return currentValue.toStringAsFixed(1);
    }
    return currentValue.round().toString();
  }

  /// Returns the unit string for this goal's metric
  String get unitString {
    switch (goal.metric) {
      case GoalMetric.hours:
        return 'hours';
      case GoalMetric.events:
        return 'events';
      case GoalMetric.completions:
        return 'completions';
    }
  }

  /// Formatted progress text for display (e.g., "8.5/10 hours")
  String get progressText => '$currentValueDisplay/$targetValue $unitString';

  /// Formatted progress percentage text for display (e.g., "85%")
  String get progressPercentText => '$progressPercentDisplay%';

  /// Status icon string representation
  String get statusIcon {
    switch (status) {
      case GoalProgressStatus.onTrack:
        return '✅';
      case GoalProgressStatus.atRisk:
        return '⚠️';
      case GoalProgressStatus.behind:
        return '❌';
    }
  }

  /// Status text
  String get statusText {
    switch (status) {
      case GoalProgressStatus.onTrack:
        return 'On Track';
      case GoalProgressStatus.atRisk:
        return 'At Risk';
      case GoalProgressStatus.behind:
        return 'Behind';
    }
  }
}

/// Provider for all active goals with their progress
@riverpod
Future<List<GoalProgress>> goalsWithProgress(GoalsWithProgressRef ref) async {
  final goalRepository = ref.watch(goalRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final eventPeopleRepository = ref.watch(eventPeopleRepositoryProvider);

  // Get all active goals
  final goals = await goalRepository.getAll();
  
  final now = DateTime.now();
  final progressList = <GoalProgress>[];

  for (final goal in goals) {
    // Calculate period boundaries
    final (periodStart, periodEnd) = _getPeriodBoundaries(now, goal.period);
    
    // Get events in the period
    final events = await eventRepository.getEventsInRange(periodStart, periodEnd);
    
    // Filter events based on goal type
    List<Event> relevantEvents;
    
    if (goal.type == GoalType.category && goal.categoryId != null) {
      // Category goals: filter by category
      relevantEvents = events.where((e) => e.categoryId == goal.categoryId).toList();
    } else if (goal.type == GoalType.person && goal.personId != null) {
      // Relationship goals: filter events by associated person
      // Get event IDs for this person
      final eventIdsForPerson = await eventPeopleRepository.getEventIdsForPerson(goal.personId!);
      relevantEvents = events.where((e) => eventIdsForPerson.contains(e.id)).toList();
    } else if (goal.type == GoalType.location && goal.locationId != null) {
      // Location goals: filter by location
      relevantEvents = events.where((e) => e.locationId == goal.locationId).toList();
    } else if (goal.type == GoalType.event && goal.eventTitle != null) {
      // Event goals: filter by exact title (case-insensitive)
      final targetTitle = goal.eventTitle!.toLowerCase();
      relevantEvents = events.where((e) => e.title.toLowerCase() == targetTitle).toList();
    } else {
      // Fallback: all events (for custom goals or invalid data)
      relevantEvents = events;
    }
    
    // Calculate current value based on metric
    final currentValue = _calculateProgress(relevantEvents, goal.metric);
    
    // Determine status
    final status = _determineStatus(
      currentValue: currentValue,
      targetValue: goal.targetValue,
      periodStart: periodStart,
      periodEnd: periodEnd,
      now: now,
    );
    
    progressList.add(GoalProgress(
      goal: goal,
      currentValue: currentValue,
      targetValue: goal.targetValue,
      periodStart: periodStart,
      periodEnd: periodEnd,
      status: status,
    ));
  }

  return progressList;
}

/// Provider for goals filtered by period
@riverpod
Future<List<GoalProgress>> goalsForPeriod(
  GoalsForPeriodRef ref,
  GoalPeriod period,
) async {
  final allGoals = await ref.watch(goalsWithProgressProvider.future);
  return allGoals.where((g) => g.goal.period == period).toList();
}

/// Provider for weekly goals
@riverpod
Future<List<GoalProgress>> weeklyGoals(WeeklyGoalsRef ref) async {
  return ref.watch(goalsForPeriodProvider(GoalPeriod.week).future);
}

/// Provider for monthly goals
@riverpod
Future<List<GoalProgress>> monthlyGoals(MonthlyGoalsRef ref) async {
  return ref.watch(goalsForPeriodProvider(GoalPeriod.month).future);
}

/// Summary statistics for goals
class GoalsSummary {
  const GoalsSummary({
    required this.totalGoals,
    required this.onTrack,
    required this.atRisk,
    required this.behind,
  });

  final int totalGoals;
  final int onTrack;
  final int atRisk;
  final int behind;

  /// Percentage of goals on track
  double get onTrackPercent {
    if (totalGoals == 0) return 100.0;
    return (onTrack / totalGoals) * 100;
  }
}

/// Provider for goals summary
@riverpod
Future<GoalsSummary> goalsSummary(GoalsSummaryRef ref) async {
  final goals = await ref.watch(goalsWithProgressProvider.future);
  
  return GoalsSummary(
    totalGoals: goals.length,
    onTrack: goals.where((g) => g.status == GoalProgressStatus.onTrack).length,
    atRisk: goals.where((g) => g.status == GoalProgressStatus.atRisk).length,
    behind: goals.where((g) => g.status == GoalProgressStatus.behind).length,
  );
}

// Helper functions

/// Get period start and end dates based on goal period
(DateTime, DateTime) _getPeriodBoundaries(DateTime now, GoalPeriod period) {
  switch (period) {
    case GoalPeriod.week:
      // Start from Monday of current week
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final periodStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final periodEnd = periodStart.add(const Duration(days: 7)).subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);
    
    case GoalPeriod.month:
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);
    
    case GoalPeriod.quarter:
      final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
      final periodStart = DateTime(now.year, quarterMonth, 1);
      final periodEnd = DateTime(now.year, quarterMonth + 3, 1).subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);
    
    case GoalPeriod.year:
      final periodStart = DateTime(now.year, 1, 1);
      final periodEnd = DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);
  }
}

/// Calculate progress value based on metric
double _calculateProgress(List<Event> events, GoalMetric metric) {
  switch (metric) {
    case GoalMetric.hours:
      // Sum up hours from scheduled events
      var totalMinutes = 0;
      for (final event in events) {
        if (event.startTime != null && event.endTime != null) {
          totalMinutes += event.endTime!.difference(event.startTime!).inMinutes;
        } else if (event.duration != null) {
          totalMinutes += event.duration!.inMinutes;
        }
      }
      return totalMinutes / 60.0;
    
    case GoalMetric.events:
      // Count number of events
      return events.length.toDouble();
    
    case GoalMetric.completions:
      // Count completed events
      return events.where((e) => e.status == EventStatus.completed).length.toDouble();
  }
}

/// Determine goal status based on progress and time elapsed
GoalProgressStatus _determineStatus({
  required double currentValue,
  required int targetValue,
  required DateTime periodStart,
  required DateTime periodEnd,
  required DateTime now,
}) {
  if (targetValue == 0) return GoalProgressStatus.onTrack;
  
  final progress = currentValue / targetValue;
  final totalDuration = periodEnd.difference(periodStart);
  final elapsedDuration = now.difference(periodStart);
  
  // Calculate expected progress based on time elapsed
  final expectedProgress = elapsedDuration.inMinutes / totalDuration.inMinutes;
  
  // If ahead or on pace, we're on track
  if (progress >= expectedProgress * 0.9) {
    return GoalProgressStatus.onTrack;
  }
  
  // If significantly behind (less than 70% of expected), we're behind
  if (progress < expectedProgress * 0.7) {
    return GoalProgressStatus.behind;
  }
  
  // Otherwise, at risk
  return GoalProgressStatus.atRisk;
}
