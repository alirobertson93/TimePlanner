import 'package:test/test.dart';
import 'package:time_planner/domain/services/goal_warning_service.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/goal_type.dart';
import 'package:time_planner/domain/enums/goal_metric.dart';
import 'package:time_planner/domain/enums/goal_period.dart';
import 'package:time_planner/domain/enums/debt_strategy.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('GoalWarningService', () {
    final now = DateTime(2024, 1, 15, 12, 0); // Mid-month
    final periodStart = DateTime(2024, 1, 8); // Week start
    final periodEnd = DateTime(2024, 1, 14, 23, 59, 59); // Week end

    Goal createTestGoal({
      String id = 'goal_1',
      String title = 'Test Goal',
      GoalType type = GoalType.category,
      GoalMetric metric = GoalMetric.hours,
      int targetValue = 10,
      GoalPeriod period = GoalPeriod.week,
      String? categoryId = 'cat_1',
    }) {
      return Goal(
        id: id,
        title: title,
        type: type,
        metric: metric,
        targetValue: targetValue,
        period: period,
        categoryId: categoryId,
        debtStrategy: DebtStrategy.carryOver,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    Event createTestEvent({
      String id = 'event_1',
      String name = 'Test Event',
      required DateTime startTime,
      required DateTime endTime,
      String? categoryId = 'cat_1',
    }) {
      return Event(
        id: id,
        name: name,
        description: '',
        timingType: TimingType.fixed,
        startTime: startTime,
        endTime: endTime,
        categoryId: categoryId,
        status: EventStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('analyzeGoal', () {
      test('returns unrealistic pace warning when goal requires >8 hours/day', () {
        final goal = createTestGoal(
          targetValue: 80, // 80 hours for the week
        );

        final warnings = GoalWarningService.analyzeGoal(
          goal: goal,
          currentProgress: 0.0,
          periodStart: periodStart,
          periodEnd: periodEnd,
          now: DateTime(2024, 1, 8, 12, 0), // Start of week
          scheduledEvents: [],
        );

        expect(warnings.any((w) => w.type == GoalWarningType.unrealisticPace), isTrue);
        
        final paceWarning = warnings.firstWhere(
          (w) => w.type == GoalWarningType.unrealisticPace,
        );
        expect(paceWarning.severity, equals(GoalWarningSeverity.critical));
      });

      test('returns no warning for achievable goal', () {
        final goal = createTestGoal(
          targetValue: 10, // 10 hours for the week (~1.5 hrs/day)
        );

        // Already have 5 hours done
        final warnings = GoalWarningService.analyzeGoal(
          goal: goal,
          currentProgress: 5.0,
          periodStart: periodStart,
          periodEnd: periodEnd,
          now: DateTime(2024, 1, 11, 12, 0), // Mid-week
          scheduledEvents: [
            createTestEvent(
              startTime: DateTime(2024, 1, 9, 9, 0),
              endTime: DateTime(2024, 1, 9, 14, 0), // 5 hours
            ),
          ],
        );

        expect(
          warnings.where((w) => w.type == GoalWarningType.unrealisticPace).isEmpty,
          isTrue,
        );
      });

      test('returns significantly behind warning when progress is too low', () {
        final goal = createTestGoal(
          targetValue: 20, // 20 hours for the week
        );

        final warnings = GoalWarningService.analyzeGoal(
          goal: goal,
          currentProgress: 2.0, // Only 2 hours done, should be ~10 by mid-week
          periodStart: periodStart,
          periodEnd: periodEnd,
          now: DateTime(2024, 1, 11, 12, 0), // Mid-week (50% through)
          scheduledEvents: [],
        );

        expect(
          warnings.any((w) => w.type == GoalWarningType.significantlyBehind),
          isTrue,
        );
      });

      test('returns noScheduledEvents warning when no events contribute', () {
        final goal = createTestGoal(
          categoryId: 'cat_exercise',
        );

        // Events are in different category
        final warnings = GoalWarningService.analyzeGoal(
          goal: goal,
          currentProgress: 0.0,
          periodStart: periodStart,
          periodEnd: periodEnd,
          now: DateTime(2024, 1, 11, 12, 0),
          scheduledEvents: [
            createTestEvent(
              startTime: DateTime(2024, 1, 9, 9, 0),
              endTime: DateTime(2024, 1, 9, 10, 0),
              categoryId: 'cat_work', // Different category
            ),
          ],
        );

        expect(
          warnings.any((w) => w.type == GoalWarningType.noScheduledEvents),
          isTrue,
        );
      });
    });

    group('estimateCompletionDate', () {
      test('returns null for already complete goals', () {
        final goal = createTestGoal(targetValue: 10);

        final result = GoalWarningService.estimateCompletionDate(
          goal: goal,
          currentProgress: 15.0, // More than target
          periodStart: periodStart,
          now: now,
        );

        expect(result, equals(now)); // Returns now since already complete
      });

      test('estimates completion date based on current pace', () {
        final goal = createTestGoal(targetValue: 20);
        final start = DateTime(2024, 1, 1);
        final current = DateTime(2024, 1, 11); // 10 days in

        final result = GoalWarningService.estimateCompletionDate(
          goal: goal,
          currentProgress: 10.0, // 10 hours in 10 days = 1 hr/day
          periodStart: start,
          now: current,
        );

        // Need 10 more hours at 1 hr/day = 10 more days
        expect(result!.difference(current).inDays, equals(10));
      });

      test('returns null for non-hours metrics', () {
        final goal = createTestGoal(
          metric: GoalMetric.events,
          targetValue: 5,
        );

        final result = GoalWarningService.estimateCompletionDate(
          goal: goal,
          currentProgress: 2.0,
          periodStart: periodStart,
          now: now,
        );

        expect(result, isNull);
      });
    });

    group('summarizeWarnings', () {
      test('correctly counts warning severities', () {
        final warnings = [
          GoalWarning(
            goalId: 'g1',
            goalTitle: 'Goal 1',
            type: GoalWarningType.unrealisticPace,
            message: 'Test',
            severity: GoalWarningSeverity.critical,
          ),
          GoalWarning(
            goalId: 'g2',
            goalTitle: 'Goal 2',
            type: GoalWarningType.significantlyBehind,
            message: 'Test',
            severity: GoalWarningSeverity.warning,
          ),
          GoalWarning(
            goalId: 'g3',
            goalTitle: 'Goal 3',
            type: GoalWarningType.noScheduledEvents,
            message: 'Test',
            severity: GoalWarningSeverity.warning,
          ),
          GoalWarning(
            goalId: 'g4',
            goalTitle: 'Goal 4',
            type: GoalWarningType.unrealisticPace,
            message: 'Test',
            severity: GoalWarningSeverity.info,
          ),
        ];

        final summary = GoalWarningService.summarizeWarnings(warnings);

        expect(summary.total, equals(4));
        expect(summary.critical, equals(1));
        expect(summary.warnings, equals(2));
        expect(summary.info, equals(1));
        expect(summary.hasWarnings, isTrue);
        expect(summary.hasCritical, isTrue);
      });

      test('returns empty summary for no warnings', () {
        final summary = GoalWarningService.summarizeWarnings([]);

        expect(summary.total, equals(0));
        expect(summary.hasWarnings, isFalse);
        expect(summary.hasCritical, isFalse);
      });
    });
  });
}
