import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/goal_repository.dart';
import 'package:time_planner/domain/entities/goal.dart';
import 'package:time_planner/domain/enums/goal_type.dart';
import 'package:time_planner/domain/enums/goal_metric.dart';
import 'package:time_planner/domain/enums/goal_period.dart';
import 'package:time_planner/domain/enums/debt_strategy.dart';

void main() {
  late AppDatabase database;
  late GoalRepository repository;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = GoalRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('GoalRepository', () {
    test('save and getById returns the saved goal', () async {
      // Arrange
      final goal = Goal(
        id: 'goal_1',
        title: 'Work 40 hours per week',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 40,
        period: GoalPeriod.week,
        categoryId: 'cat_work',
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(goal);
      final retrieved = await repository.getById('goal_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('goal_1'));
      expect(retrieved.title, equals('Work 40 hours per week'));
      expect(retrieved.type, equals(GoalType.category));
      expect(retrieved.metric, equals(GoalMetric.hours));
      expect(retrieved.targetValue, equals(40));
      expect(retrieved.period, equals(GoalPeriod.week));
      expect(retrieved.categoryId, equals('cat_work'));
      expect(retrieved.debtStrategy, equals(DebtStrategy.ignore));
      expect(retrieved.isActive, isTrue);
    });

    test('save updates existing goal', () async {
      // Arrange
      final goal = Goal(
        id: 'goal_1',
        title: 'Original Title',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 40,
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.save(goal);

      // Act
      final updated = goal.copyWith(
        title: 'Updated Title',
        targetValue: 50,
      );
      await repository.save(updated);
      final retrieved = await repository.getById('goal_1');

      // Assert
      expect(retrieved!.title, equals('Updated Title'));
      expect(retrieved.targetValue, equals(50));
    });

    test('delete removes goal from database', () async {
      // Arrange
      final goal = Goal(
        id: 'goal_1',
        title: 'Test Goal',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 40,
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.save(goal);

      // Act
      await repository.delete('goal_1');
      final retrieved = await repository.getById('goal_1');

      // Assert
      expect(retrieved, isNull);
    });

    test('getAll returns all active goals', () async {
      // Arrange
      final goal1 = Goal(
        id: 'goal_1',
        title: 'Goal 1',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 40,
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final goal2 = Goal(
        id: 'goal_2',
        title: 'Goal 2',
        type: GoalType.category,
        metric: GoalMetric.events,
        targetValue: 10,
        period: GoalPeriod.month,
        debtStrategy: DebtStrategy.carryForward,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final inactiveGoal = Goal(
        id: 'goal_3',
        title: 'Inactive Goal',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 20,
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.ignore,
        isActive: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(goal1);
      await repository.save(goal2);
      await repository.save(inactiveGoal);
      final goals = await repository.getAll();

      // Assert
      expect(goals.length, equals(2));
      expect(goals.any((g) => g.id == 'goal_1'), isTrue);
      expect(goals.any((g) => g.id == 'goal_2'), isTrue);
      expect(goals.any((g) => g.id == 'goal_3'), isFalse);
    });

    test('getByCategory returns goals for specific category', () async {
      // Arrange
      final workGoal = Goal(
        id: 'goal_1',
        title: 'Work Goal',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 40,
        period: GoalPeriod.week,
        categoryId: 'cat_work',
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personalGoal = Goal(
        id: 'goal_2',
        title: 'Personal Goal',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 10,
        period: GoalPeriod.week,
        categoryId: 'cat_personal',
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(workGoal);
      await repository.save(personalGoal);
      final workGoals = await repository.getByCategory('cat_work');

      // Assert
      expect(workGoals.length, equals(1));
      expect(workGoals.first.id, equals('goal_1'));
      expect(workGoals.first.categoryId, equals('cat_work'));
    });

    test('watchAll emits updates when goals change', () async {
      // Arrange
      final goal = Goal(
        id: 'goal_1',
        title: 'Test Goal',
        type: GoalType.category,
        metric: GoalMetric.hours,
        targetValue: 40,
        period: GoalPeriod.week,
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final stream = repository.watchAll();
      final emittedValues = <List<Goal>>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await repository.save(goal);
      await Future.delayed(const Duration(milliseconds: 100));
      await repository.delete('goal_1');
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Assert
      expect(emittedValues.length, greaterThanOrEqualTo(3));
      expect(emittedValues[0].length, equals(0)); // Initial empty
      expect(emittedValues[1].length, equals(1)); // After save
      expect(emittedValues[2].length, equals(0)); // After delete
    });
  });
}
