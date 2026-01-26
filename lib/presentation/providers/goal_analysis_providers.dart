import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/goal_warning_service.dart';
import '../../domain/services/goal_recommendation_service.dart';
import '../../domain/entities/goal.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/goal_period.dart';
import '../../domain/enums/goal_metric.dart';
import '../../domain/enums/goal_type.dart';
import '../../data/repositories/event_people_repository.dart';
import 'repository_providers.dart';
import 'settings_providers.dart';

/// Provider for goal warnings for all active goals
final goalWarningsProvider = FutureProvider<List<GoalWarning>>((ref) async {
  final settings = ref.watch(settingsProvider);
  
  // Skip if warnings are disabled
  if (!settings.showGoalWarnings) {
    return [];
  }

  final goalRepository = ref.watch(goalRepositoryProvider);
  final eventRepository = ref.watch(eventRepositoryProvider);
  final eventPeopleRepository = ref.watch(eventPeopleRepositoryProvider);

  final goals = await goalRepository.getAll();
  final now = DateTime.now();
  final warnings = <GoalWarning>[];

  for (final goal in goals) {
    // Get period boundaries
    final (periodStart, periodEnd) = _getPeriodBoundaries(now, goal.period);

    // Get events in period
    final events = await eventRepository.getEventsInRange(periodStart, periodEnd);

    // Get current progress
    final progress = await _calculateProgress(
      goal: goal,
      events: events,
      eventPeopleRepository: eventPeopleRepository,
    );

    // Analyze for warnings
    final goalWarnings = GoalWarningService.analyzeGoal(
      goal: goal,
      currentProgress: progress,
      periodStart: periodStart,
      periodEnd: periodEnd,
      now: now,
      scheduledEvents: events,
    );

    warnings.addAll(goalWarnings);
  }

  return warnings;
});

/// Provider for goal warnings summary
final goalWarningsSummaryProvider = FutureProvider<GoalWarningsSummary>((ref) async {
  final warnings = await ref.watch(goalWarningsProvider.future);
  return GoalWarningService.summarizeWarnings(warnings);
});

/// Provider for goal recommendations
final goalRecommendationsProvider = FutureProvider<List<GoalRecommendation>>((ref) async {
  final settings = ref.watch(settingsProvider);
  
  // Skip if recommendations are disabled
  if (!settings.enableGoalRecommendations) {
    return [];
  }

  final eventRepository = ref.watch(eventRepositoryProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);
  final personRepository = ref.watch(personRepositoryProvider);
  final locationRepository = ref.watch(locationRepositoryProvider);
  final goalRepository = ref.watch(goalRepositoryProvider);

  // Get data for analysis (last 30 days of events)
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  
  final events = await eventRepository.getEventsInRange(thirtyDaysAgo, now);
  final categories = await categoryRepository.getAll();
  final people = await personRepository.getAll();
  final locations = await locationRepository.getAll();
  final existingGoals = await goalRepository.getAll();

  // Generate recommendations
  return GoalRecommendationService.analyzeAndRecommend(
    events: events,
    categories: categories,
    people: people,
    locations: locations,
    existingGoals: existingGoals,
    maxRecommendations: 5,
  );
});

/// Provider for warnings specific to a single goal
final warningsForGoalProvider = FutureProvider.family<List<GoalWarning>, String>((ref, goalId) async {
  final allWarnings = await ref.watch(goalWarningsProvider.future);
  return allWarnings.where((w) => w.goalId == goalId).toList();
});

// Helper function to get period boundaries
(DateTime, DateTime) _getPeriodBoundaries(DateTime now, GoalPeriod period) {
  switch (period) {
    case GoalPeriod.week:
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final periodStart = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final periodEnd = periodStart
          .add(const Duration(days: 7))
          .subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);

    case GoalPeriod.month:
      final periodStart = DateTime(now.year, now.month, 1);
      final periodEnd = DateTime(now.year, now.month + 1, 1)
          .subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);

    case GoalPeriod.quarter:
      final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
      final periodStart = DateTime(now.year, quarterMonth, 1);
      final periodEnd = DateTime(now.year, quarterMonth + 3, 1)
          .subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);

    case GoalPeriod.year:
      final periodStart = DateTime(now.year, 1, 1);
      final periodEnd =
          DateTime(now.year + 1, 1, 1).subtract(const Duration(seconds: 1));
      return (periodStart, periodEnd);
  }
}

// Helper to calculate progress for a goal
Future<double> _calculateProgress({
  required Goal goal,
  required List<Event> events,
  required IEventPeopleRepository eventPeopleRepository,
}) async {
  // Filter events based on goal type
  List<Event> relevantEvents;

  if (goal.type == GoalType.category && goal.categoryId != null) {
    // Category goals: filter by category
    relevantEvents = events.where((e) => e.categoryId == goal.categoryId).toList();
  } else if (goal.type == GoalType.person && goal.personId != null) {
    // Relationship goals: filter events by associated person
    final eventIdsForPerson = await eventPeopleRepository.getEventIdsForPerson(goal.personId!);
    relevantEvents = events.where((e) => eventIdsForPerson.contains(e.id)).toList();
  } else if (goal.type == GoalType.location && goal.locationId != null) {
    // Location goals: filter by location
    relevantEvents = events.where((e) => e.locationId == goal.locationId).toList();
  } else if (goal.type == GoalType.activity && goal.activityTitle != null) {
    // Event goals: filter by exact title (case-insensitive)
    final targetTitle = goal.activityTitle!.toLowerCase();
    relevantEvents = events.where((e) => e.name.toLowerCase() == targetTitle).toList();
  } else {
    relevantEvents = events;
  }

  // Calculate based on metric
  switch (goal.metric) {
    case GoalMetric.hours:
      var totalMinutes = 0;
      for (final event in relevantEvents) {
        if (event.startTime != null && event.endTime != null) {
          totalMinutes += event.endTime!.difference(event.startTime!).inMinutes;
        } else if (event.duration != null) {
          totalMinutes += event.duration!.inMinutes;
        }
      }
      return totalMinutes / 60.0;

    case GoalMetric.activities:
      return relevantEvents.length.toDouble();

    case GoalMetric.completions:
      return relevantEvents
          .where((e) => e.status.index == 2) // completed status
          .length
          .toDouble();
  }
}
