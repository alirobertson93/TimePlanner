import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:time_planner/domain/enums/goal_period.dart';
import 'package:time_planner/domain/enums/goal_type.dart';
import 'package:time_planner/domain/enums/goal_metric.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/presentation/providers/goal_providers.dart';
import 'package:time_planner/presentation/screens/goals_dashboard/goals_dashboard_screen.dart';

void main() {
  group('GoalsDashboardScreen', () {
    late List<GoalProgress> testGoals;

    setUp(() {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      testGoals = [
        GoalProgress(
          goal: Goal(
            id: 'goal_1',
            title: 'Exercise',
            type: GoalType.category,
            categoryId: 'cat_fitness',
            metric: GoalMetric.hours,
            targetValue: 10,
            period: GoalPeriod.week,
            createdAt: now,
            updatedAt: now,
          ),
          currentValue: 7.5,
          targetValue: 10,
          periodStart: weekStart,
          periodEnd: weekEnd,
          status: GoalProgressStatus.onTrack,
        ),
        GoalProgress(
          goal: Goal(
            id: 'goal_2',
            title: 'Reading',
            type: GoalType.category,
            categoryId: 'cat_learning',
            metric: GoalMetric.hours,
            targetValue: 5,
            period: GoalPeriod.week,
            createdAt: now,
            updatedAt: now,
          ),
          currentValue: 2.0,
          targetValue: 5,
          periodStart: weekStart,
          periodEnd: weekEnd,
          status: GoalProgressStatus.atRisk,
        ),
        GoalProgress(
          goal: Goal(
            id: 'goal_3',
            title: 'Team Meetings',
            type: GoalType.category,
            categoryId: 'cat_work',
            metric: GoalMetric.events,
            targetValue: 8,
            period: GoalPeriod.month,
            createdAt: now,
            updatedAt: now,
          ),
          currentValue: 2.0,
          targetValue: 8,
          periodStart: DateTime(now.year, now.month, 1),
          periodEnd: DateTime(now.year, now.month + 1, 0),
          status: GoalProgressStatus.behind,
        ),
      ];
    });

    Widget createTestWidget({
      List<GoalProgress> goals = const [],
    }) {
      return ProviderScope(
        overrides: [
          goalsWithProgressProvider.overrideWith(
            (ref) => Future.value(goals),
          ),
          goalsSummaryProvider.overrideWith(
            (ref) => Future.value(GoalsSummary(
              totalGoals: goals.length,
              onTrack: goals.where((g) => g.status == GoalProgressStatus.onTrack).length,
              atRisk: goals.where((g) => g.status == GoalProgressStatus.atRisk).length,
              behind: goals.where((g) => g.status == GoalProgressStatus.behind).length,
            )),
          ),
        ],
        child: MaterialApp(
          home: const GoalsDashboardScreen(),
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              builder: (context) => Scaffold(
                body: Center(child: Text('Route: ${settings.name}')),
              ),
            );
          },
        ),
      );
    }

    testWidgets('displays "Goals" title in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.text('Goals'), findsOneWidget);
    });

    testWidgets('displays loading indicator while fetching goals',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalsWithProgressProvider.overrideWith(
              (ref) => Future.delayed(
                const Duration(seconds: 10),
                () => <GoalProgress>[],
              ),
            ),
          ],
          child: const MaterialApp(
            home: GoalsDashboardScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('displays empty state when no goals exist', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: []));
      await tester.pumpAndSettle();

      expect(find.text('No Goals Set'), findsOneWidget);
      expect(find.text('Add Your First Goal'), findsOneWidget);
    });

    testWidgets('displays add goal button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays back button in app bar', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('displays goal summary card when goals exist', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.text('Goal Summary'), findsOneWidget);
    });

    testWidgets('displays summary statistics correctly', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      // Should show status labels
      expect(find.text('On Track'), findsWidgets);
      expect(find.text('At Risk'), findsWidgets);
      expect(find.text('Behind'), findsWidgets);
    });

    testWidgets('displays weekly goals section when weekly goals exist',
        (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.text('This Week'), findsOneWidget);
    });

    testWidgets('displays monthly goals section when monthly goals exist',
        (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.text('This Month'), findsOneWidget);
    });

    testWidgets('displays goal progress bars', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      // There should be progress indicators (LinearProgressIndicator) for each goal
      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });

    testWidgets('displays error state correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            goalsWithProgressProvider.overrideWith(
              (ref) => Future.error('Test error'),
            ),
          ],
          child: const MaterialApp(
            home: GoalsDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Error Loading Goals'), findsOneWidget);
    });

    testWidgets('goals are tappable for editing', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      // Goal cards should be wrapped in InkWell for tap functionality
      final inkWells = find.byType(InkWell);
      expect(inkWells, findsWidgets);
    });

    testWidgets('displays goal titles', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('Team Meetings'), findsOneWidget);
    });

    testWidgets('displays progress percentages', (tester) async {
      await tester.pumpWidget(createTestWidget(goals: testGoals));
      await tester.pumpAndSettle();

      // Progress percentages should be displayed
      expect(find.textContaining('%'), findsWidgets);
    });
  });
}
