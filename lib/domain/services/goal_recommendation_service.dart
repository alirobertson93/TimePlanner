import '../entities/event.dart';
import '../entities/category.dart';
import '../entities/person.dart';
import '../entities/location.dart';
import '../entities/goal.dart';
import '../enums/goal_type.dart';
import '../enums/goal_metric.dart';
import '../enums/goal_period.dart';
import '../enums/debt_strategy.dart';

/// Represents a goal recommendation based on user activity patterns
class GoalRecommendation {
  const GoalRecommendation({
    required this.type,
    required this.title,
    required this.description,
    required this.suggestedTarget,
    required this.suggestedPeriod,
    required this.suggestedMetric,
    required this.reason,
    required this.confidence,
    this.categoryId,
    this.personId,
    this.locationId,
    this.eventTitle,
  });

  /// The type of goal being recommended
  final GoalType type;

  /// Suggested title for the goal
  final String title;

  /// Description of why this goal is recommended
  final String description;

  /// Suggested target value
  final int suggestedTarget;

  /// Suggested period for the goal
  final GoalPeriod suggestedPeriod;

  /// Suggested metric for the goal
  final GoalMetric suggestedMetric;

  /// Why this goal is being recommended
  final String reason;

  /// Confidence score (0.0 to 1.0) based on data quality
  final double confidence;

  /// Category ID (for category-type goals)
  final String? categoryId;

  /// Person ID (for person-type goals)
  final String? personId;

  /// Location ID (for location-type goals)
  final String? locationId;

  /// Event title (for event-type goals)
  final String? eventTitle;

  /// Create a Goal entity from this recommendation
  Goal toGoal({required String id}) {
    final now = DateTime.now();
    return Goal(
      id: id,
      title: title,
      type: type,
      metric: suggestedMetric,
      targetValue: suggestedTarget,
      period: suggestedPeriod,
      categoryId: categoryId,
      personId: personId,
      locationId: locationId,
      eventTitle: eventTitle,
      debtStrategy: DebtStrategy.carryForward,
      isActive: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  String toString() {
    return 'GoalRecommendation(type: $type, title: $title, confidence: $confidence)';
  }
}

/// Service for analyzing event patterns and recommending goals
class GoalRecommendationService {
  /// Minimum number of events to consider a pattern significant
  static const int minEventsForPattern = 3;

  /// Analyze events and generate goal recommendations
  static List<GoalRecommendation> analyzeAndRecommend({
    required List<Event> events,
    required List<Category> categories,
    required List<Person> people,
    required List<Location> locations,
    required List<Goal> existingGoals,
    int maxRecommendations = 5,
  }) {
    final recommendations = <GoalRecommendation>[];

    // Analyze category-based patterns
    final categoryRecs = _analyzeCategoryPatterns(
      events: events,
      categories: categories,
      existingGoals: existingGoals,
    );
    recommendations.addAll(categoryRecs);

    // Analyze location-based patterns
    final locationRecs = _analyzeLocationPatterns(
      events: events,
      locations: locations,
      existingGoals: existingGoals,
    );
    recommendations.addAll(locationRecs);

    // Analyze recurring event patterns
    final eventRecs = _analyzeEventTitlePatterns(
      events: events,
      existingGoals: existingGoals,
    );
    recommendations.addAll(eventRecs);

    // Sort by confidence and limit results
    recommendations.sort((a, b) => b.confidence.compareTo(a.confidence));
    return recommendations.take(maxRecommendations).toList();
  }

  /// Analyze category-based patterns
  static List<GoalRecommendation> _analyzeCategoryPatterns({
    required List<Event> events,
    required List<Category> categories,
    required List<Goal> existingGoals,
  }) {
    final recommendations = <GoalRecommendation>[];
    final categoryStats = <String, _CategoryStats>{};

    // Calculate stats for each category
    for (final event in events) {
      if (event.categoryId == null) continue;

      final stats = categoryStats.putIfAbsent(
        event.categoryId!,
        () => _CategoryStats(categoryId: event.categoryId!),
      );
      stats.eventCount++;

      // Calculate hours
      if (event.startTime != null && event.endTime != null) {
        stats.totalMinutes +=
            event.endTime!.difference(event.startTime!).inMinutes;
      } else if (event.duration != null) {
        stats.totalMinutes += event.duration!.inMinutes;
      }
    }

    // Generate recommendations for significant categories
    for (final entry in categoryStats.entries) {
      final stats = entry.value;
      if (stats.eventCount < minEventsForPattern) continue;

      // Skip if there's already a goal for this category
      final hasExistingGoal = existingGoals.any(
        (g) => g.type == GoalType.category && g.categoryId == stats.categoryId,
      );
      if (hasExistingGoal) continue;

      // Find category info
      final category = categories.firstWhere(
        (c) => c.id == stats.categoryId,
        orElse: () => Category(
          id: stats.categoryId,
          name: 'Unknown',
          colourHex: 'FF000000',
        ),
      );

      final avgHoursPerWeek = (stats.totalMinutes / 60) / _weeksInData(events);
      final suggestedTarget = (avgHoursPerWeek * 1.1).ceil(); // 10% increase
      final confidence = _calculateConfidence(stats.eventCount, events.length);

      recommendations.add(GoalRecommendation(
        type: GoalType.category,
        title: '${suggestedTarget} hours on ${category.name}',
        description: 'Track time spent on ${category.name} activities',
        suggestedTarget: suggestedTarget,
        suggestedPeriod: GoalPeriod.week,
        suggestedMetric: GoalMetric.hours,
        reason:
            'You spend an average of ${avgHoursPerWeek.toStringAsFixed(1)} hours/week on ${category.name}',
        confidence: confidence,
        categoryId: stats.categoryId,
      ));
    }

    return recommendations;
  }

  /// Analyze location-based patterns
  static List<GoalRecommendation> _analyzeLocationPatterns({
    required List<Event> events,
    required List<Location> locations,
    required List<Goal> existingGoals,
  }) {
    final recommendations = <GoalRecommendation>[];
    final locationStats = <String, _LocationStats>{};

    // Calculate stats for each location
    for (final event in events) {
      if (event.locationId == null) continue;

      final stats = locationStats.putIfAbsent(
        event.locationId!,
        () => _LocationStats(locationId: event.locationId!),
      );
      stats.eventCount++;

      // Calculate hours
      if (event.startTime != null && event.endTime != null) {
        stats.totalMinutes +=
            event.endTime!.difference(event.startTime!).inMinutes;
      } else if (event.duration != null) {
        stats.totalMinutes += event.duration!.inMinutes;
      }
    }

    // Generate recommendations for significant locations
    for (final entry in locationStats.entries) {
      final stats = entry.value;
      if (stats.eventCount < minEventsForPattern) continue;

      // Skip if there's already a goal for this location
      final hasExistingGoal = existingGoals.any(
        (g) => g.type == GoalType.location && g.locationId == stats.locationId,
      );
      if (hasExistingGoal) continue;

      // Find location info
      final location = locations.firstWhere(
        (l) => l.id == stats.locationId,
        orElse: () => Location(
          id: stats.locationId,
          name: 'Unknown',
          createdAt: DateTime.now(),
        ),
      );

      final avgHoursPerWeek = (stats.totalMinutes / 60) / _weeksInData(events);
      final suggestedTarget = (avgHoursPerWeek * 1.1).ceil(); // 10% increase
      final confidence = _calculateConfidence(stats.eventCount, events.length);

      recommendations.add(GoalRecommendation(
        type: GoalType.location,
        title: '${suggestedTarget} hours at ${location.name}',
        description: 'Track time spent at ${location.name}',
        suggestedTarget: suggestedTarget,
        suggestedPeriod: GoalPeriod.week,
        suggestedMetric: GoalMetric.hours,
        reason:
            'You spend an average of ${avgHoursPerWeek.toStringAsFixed(1)} hours/week at ${location.name}',
        confidence: confidence,
        locationId: stats.locationId,
      ));
    }

    return recommendations;
  }

  /// Analyze recurring event title patterns
  static List<GoalRecommendation> _analyzeEventTitlePatterns({
    required List<Event> events,
    required List<Goal> existingGoals,
  }) {
    final recommendations = <GoalRecommendation>[];
    final titleStats = <String, _EventTitleStats>{};

    // Group events by normalized title
    for (final event in events) {
      final normalizedTitle = event.name.toLowerCase().trim();
      if (normalizedTitle.isEmpty) continue;

      final stats = titleStats.putIfAbsent(
        normalizedTitle,
        () => _EventTitleStats(title: event.name),
      );
      stats.eventCount++;

      // Calculate hours
      if (event.startTime != null && event.endTime != null) {
        stats.totalMinutes +=
            event.endTime!.difference(event.startTime!).inMinutes;
      } else if (event.duration != null) {
        stats.totalMinutes += event.duration!.inMinutes;
      }
    }

    // Generate recommendations for recurring events
    for (final entry in titleStats.entries) {
      final stats = entry.value;
      if (stats.eventCount < minEventsForPattern) continue;

      // Skip if there's already a goal for this event title
      final hasExistingGoal = existingGoals.any(
        (g) =>
            g.type == GoalType.event &&
            g.eventTitle?.toLowerCase() == entry.key,
      );
      if (hasExistingGoal) continue;

      final avgHoursPerWeek = (stats.totalMinutes / 60) / _weeksInData(events);
      final suggestedTarget = (avgHoursPerWeek * 1.1).ceil(); // 10% increase
      final confidence = _calculateConfidence(stats.eventCount, events.length);

      // Only recommend if there's meaningful time spent
      if (avgHoursPerWeek >= 0.5) {
        recommendations.add(GoalRecommendation(
          type: GoalType.event,
          title: '${suggestedTarget} hours on ${stats.title}',
          description: 'Track time spent on "${stats.title}" events',
          suggestedTarget: suggestedTarget,
          suggestedPeriod: GoalPeriod.week,
          suggestedMetric: GoalMetric.hours,
          reason:
              'You have ${stats.eventCount} "${stats.title}" events averaging ${avgHoursPerWeek.toStringAsFixed(1)} hours/week',
          confidence: confidence,
          eventTitle: stats.title,
        ));
      }
    }

    return recommendations;
  }

  /// Calculate approximate weeks in the event data
  static double _weeksInData(List<Event> events) {
    if (events.isEmpty) return 1;

    DateTime? earliest;
    DateTime? latest;

    for (final event in events) {
      final eventDate = event.startTime ?? event.createdAt;
      if (earliest == null || eventDate.isBefore(earliest)) {
        earliest = eventDate;
      }
      if (latest == null || eventDate.isAfter(latest)) {
        latest = eventDate;
      }
    }

    if (earliest == null || latest == null) return 1;

    final days = latest.difference(earliest).inDays;
    final weeks = days / 7.0;
    return weeks < 1 ? 1 : weeks;
  }

  /// Calculate confidence score based on data quantity
  static double _calculateConfidence(int relevantEvents, int totalEvents) {
    if (totalEvents == 0) return 0.0;

    // Base confidence on event count
    final eventFactor = (relevantEvents / 10).clamp(0.0, 1.0);

    // Adjust by proportion of relevant events
    final proportionFactor = relevantEvents / totalEvents;

    return ((eventFactor * 0.7) + (proportionFactor * 0.3)).clamp(0.0, 1.0);
  }
}

/// Stats for category analysis
class _CategoryStats {
  _CategoryStats({required this.categoryId});
  final String categoryId;
  int eventCount = 0;
  int totalMinutes = 0;
}

/// Stats for location analysis
class _LocationStats {
  _LocationStats({required this.locationId});
  final String locationId;
  int eventCount = 0;
  int totalMinutes = 0;
}

/// Stats for event title analysis
class _EventTitleStats {
  _EventTitleStats({required this.title});
  final String title;
  int eventCount = 0;
  int totalMinutes = 0;
}
