import '../entities/goal.dart';
import '../entities/event.dart';
import '../enums/goal_period.dart';
import '../enums/goal_metric.dart';
import '../enums/goal_type.dart';

/// Represents a warning about a goal that may be unachievable
class GoalWarning {
  const GoalWarning({
    required this.goalId,
    required this.goalTitle,
    required this.type,
    required this.message,
    required this.severity,
    this.suggestedAction,
    this.currentValue,
    this.targetValue,
    this.requiredHoursPerDay,
  });

  /// The ID of the goal this warning is for
  final String goalId;

  /// The title of the goal
  final String goalTitle;

  /// The type of warning
  final GoalWarningType type;

  /// Human-readable warning message
  final String message;

  /// Severity of the warning
  final GoalWarningSeverity severity;

  /// Suggested action to address the warning
  final String? suggestedAction;

  /// Current progress value (if applicable)
  final double? currentValue;

  /// Target value (if applicable)
  final int? targetValue;

  /// Required hours per day to meet the goal (for hours-based goals)
  final double? requiredHoursPerDay;

  @override
  String toString() {
    return 'GoalWarning(goal: $goalTitle, type: $type, severity: $severity)';
  }
}

/// Types of goal warnings
enum GoalWarningType {
  /// Goal requires too many hours per day to be achievable
  unrealisticPace,

  /// Goal is significantly behind schedule
  significantlyBehind,

  /// No events are scheduled that contribute to this goal
  noScheduledEvents,

  /// Not enough time remaining in the period to catch up
  insufficientTimeRemaining,

  /// Goal has conflicting constraints
  conflictingGoals,
}

/// Severity levels for goal warnings
enum GoalWarningSeverity {
  /// Informational warning - goal is at risk but achievable
  info,

  /// Warning - goal is unlikely to be achieved without changes
  warning,

  /// Critical - goal is almost certainly unachievable
  critical,
}

/// Service for detecting and generating warnings for goals
class GoalWarningService {
  /// Maximum reasonable hours per day for any goal
  static const double maxReasonableHoursPerDay = 8.0;

  /// Threshold for "significantly behind" (% of expected progress)
  static const double significantlyBehindThreshold = 0.5;

  /// Analyze a goal and return any applicable warnings
  static List<GoalWarning> analyzeGoal({
    required Goal goal,
    required double currentProgress,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime now,
    required List<Event> scheduledEvents,
  }) {
    final warnings = <GoalWarning>[];

    // Only analyze hours-based goals for unrealistic pace
    if (goal.metric == GoalMetric.hours) {
      final paceWarning = _checkUnrealisticPace(
        goal: goal,
        currentProgress: currentProgress,
        periodStart: periodStart,
        periodEnd: periodEnd,
        now: now,
      );
      if (paceWarning != null) {
        warnings.add(paceWarning);
      }
    }

    // Check if goal is significantly behind schedule
    final behindWarning = _checkSignificantlyBehind(
      goal: goal,
      currentProgress: currentProgress,
      periodStart: periodStart,
      periodEnd: periodEnd,
      now: now,
    );
    if (behindWarning != null) {
      warnings.add(behindWarning);
    }

    // Check if there are no scheduled events contributing to this goal
    final noEventsWarning = _checkNoScheduledEvents(
      goal: goal,
      scheduledEvents: scheduledEvents,
    );
    if (noEventsWarning != null) {
      warnings.add(noEventsWarning);
    }

    return warnings;
  }

  /// Check if the goal requires an unrealistic pace to achieve
  static GoalWarning? _checkUnrealisticPace({
    required Goal goal,
    required double currentProgress,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime now,
  }) {
    if (goal.metric != GoalMetric.hours) return null;

    final remaining = goal.targetValue - currentProgress;
    if (remaining <= 0) return null; // Goal already achieved

    // Calculate days remaining in the period
    final daysRemaining = periodEnd.difference(now).inDays + 1;
    if (daysRemaining <= 0) return null;

    // Calculate required hours per day
    final requiredHoursPerDay = remaining / daysRemaining;

    if (requiredHoursPerDay > maxReasonableHoursPerDay) {
      return GoalWarning(
        goalId: goal.id,
        goalTitle: goal.title,
        type: GoalWarningType.unrealisticPace,
        message: 'Requires ${requiredHoursPerDay.toStringAsFixed(1)} hours/day '
            'to achieve (${remaining.toStringAsFixed(1)} hours in $daysRemaining days)',
        severity: requiredHoursPerDay > 12
            ? GoalWarningSeverity.critical
            : GoalWarningSeverity.warning,
        suggestedAction: 'Consider reducing the target or extending the period',
        currentValue: currentProgress,
        targetValue: goal.targetValue,
        requiredHoursPerDay: requiredHoursPerDay,
      );
    } else if (requiredHoursPerDay > maxReasonableHoursPerDay * 0.75) {
      return GoalWarning(
        goalId: goal.id,
        goalTitle: goal.title,
        type: GoalWarningType.unrealisticPace,
        message:
            'Requires ${requiredHoursPerDay.toStringAsFixed(1)} hours/day - '
            'this is a demanding pace',
        severity: GoalWarningSeverity.info,
        suggestedAction: 'Consider scheduling more time for this activity',
        currentValue: currentProgress,
        targetValue: goal.targetValue,
        requiredHoursPerDay: requiredHoursPerDay,
      );
    }

    return null;
  }

  /// Check if goal is significantly behind expected progress
  static GoalWarning? _checkSignificantlyBehind({
    required Goal goal,
    required double currentProgress,
    required DateTime periodStart,
    required DateTime periodEnd,
    required DateTime now,
  }) {
    // Calculate expected progress based on time elapsed
    final totalDuration = periodEnd.difference(periodStart);
    final elapsedDuration = now.difference(periodStart);

    if (totalDuration.inMinutes <= 0 || elapsedDuration.inMinutes <= 0) {
      return null;
    }

    final expectedProgressPercent =
        elapsedDuration.inMinutes / totalDuration.inMinutes;
    final expectedProgress = goal.targetValue * expectedProgressPercent;
    final actualProgressPercent = currentProgress / goal.targetValue;

    // Only warn if we're at least 25% into the period
    if (expectedProgressPercent < 0.25) return null;

    // Check if actual progress is less than threshold of expected
    if (actualProgressPercent <
        expectedProgressPercent * significantlyBehindThreshold) {
      final behindPercent =
          ((expectedProgressPercent - actualProgressPercent) * 100).round();

      return GoalWarning(
        goalId: goal.id,
        goalTitle: goal.title,
        type: GoalWarningType.significantlyBehind,
        message: 'Goal is $behindPercent% behind expected progress',
        severity: behindPercent > 50
            ? GoalWarningSeverity.critical
            : GoalWarningSeverity.warning,
        suggestedAction:
            'Schedule more time for this goal or adjust the target',
        currentValue: currentProgress,
        targetValue: goal.targetValue,
      );
    }

    return null;
  }

  /// Check if there are no events scheduled that contribute to the goal
  static GoalWarning? _checkNoScheduledEvents({
    required Goal goal,
    required List<Event> scheduledEvents,
  }) {
    if (scheduledEvents.isEmpty) return null;

    bool hasContributingEvents = false;

    for (final event in scheduledEvents) {
      // Check based on goal type
      switch (goal.type) {
        case GoalType.category:
          if (goal.categoryId != null && event.categoryId == goal.categoryId) {
            hasContributingEvents = true;
          }
          break;
        case GoalType.person:
          // Person goals require EventPeople association data which isn't available
          // in the simple event list. Skip this check to avoid false positives.
          // The warning would require passing EventPeople data to this method,
          // which could be done in a future enhancement.
          return null; // Skip noScheduledEvents check for person goals
        case GoalType.location:
          if (goal.locationId != null && event.locationId == goal.locationId) {
            hasContributingEvents = true;
          }
          break;
        case GoalType.activity:
          if (goal.activityTitle != null &&
              event.name.toLowerCase() == goal.activityTitle!.toLowerCase()) {
            hasContributingEvents = true;
          }
          break;
        case GoalType.custom:
          // Custom goals don't have automatic event matching
          return null;
      }

      if (hasContributingEvents) break;
    }

    if (!hasContributingEvents) {
      return GoalWarning(
        goalId: goal.id,
        goalTitle: goal.title,
        type: GoalWarningType.noScheduledEvents,
        message: 'No scheduled events contribute to this goal',
        severity: GoalWarningSeverity.warning,
        suggestedAction: 'Add events that will help you achieve this goal',
      );
    }

    return null;
  }

  /// Calculate estimated completion date for a goal based on current pace
  static DateTime? estimateCompletionDate({
    required Goal goal,
    required double currentProgress,
    required DateTime periodStart,
    required DateTime now,
  }) {
    if (goal.metric != GoalMetric.hours) return null;
    if (currentProgress <= 0) return null;
    if (currentProgress >= goal.targetValue) return now; // Already complete

    // Calculate pace (progress per day)
    final daysElapsed = now.difference(periodStart).inDays;
    if (daysElapsed <= 0) return null;

    final progressPerDay = currentProgress / daysElapsed;
    if (progressPerDay <= 0) return null;

    // Calculate remaining days needed
    final remaining = goal.targetValue - currentProgress;
    final daysNeeded = (remaining / progressPerDay).ceil();

    return now.add(Duration(days: daysNeeded));
  }

  /// Get summary statistics for goal warnings
  static GoalWarningsSummary summarizeWarnings(List<GoalWarning> warnings) {
    return GoalWarningsSummary(
      total: warnings.length,
      critical: warnings
          .where((w) => w.severity == GoalWarningSeverity.critical)
          .length,
      warnings: warnings
          .where((w) => w.severity == GoalWarningSeverity.warning)
          .length,
      info:
          warnings.where((w) => w.severity == GoalWarningSeverity.info).length,
    );
  }
}

/// Summary of goal warnings
class GoalWarningsSummary {
  const GoalWarningsSummary({
    required this.total,
    required this.critical,
    required this.warnings,
    required this.info,
  });

  final int total;
  final int critical;
  final int warnings;
  final int info;

  bool get hasWarnings => total > 0;
  bool get hasCritical => critical > 0;
}
