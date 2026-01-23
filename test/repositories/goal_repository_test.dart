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

    test('save and getById returns relationship goal with personId', () async {
      // Arrange
      final relationshipGoal = Goal(
        id: 'goal_relationship',
        title: 'Spend time with John',
        type: GoalType.person,
        metric: GoalMetric.hours,
        targetValue: 5,
        period: GoalPeriod.week,
        personId: 'person_john',
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(relationshipGoal);
      final retrieved = await repository.getById('goal_relationship');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('goal_relationship'));
      expect(retrieved.title, equals('Spend time with John'));
      expect(retrieved.type, equals(GoalType.person));
      expect(retrieved.personId, equals('person_john'));
      expect(retrieved.categoryId, isNull);
    });

    test('getByPerson returns goals for specific person', () async {
      // Arrange
      final personGoal1 = Goal(
        id: 'goal_1',
        title: 'Spend time with John',
        type: GoalType.person,
        metric: GoalMetric.hours,
        targetValue: 5,
        period: GoalPeriod.week,
        personId: 'person_john',
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final personGoal2 = Goal(
        id: 'goal_2',
        title: 'Spend time with Jane',
        type: GoalType.person,
        metric: GoalMetric.hours,
        targetValue: 3,
        period: GoalPeriod.week,
        personId: 'person_jane',
        debtStrategy: DebtStrategy.ignore,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final categoryGoal = Goal(
        id: 'goal_3',
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

      // Act
      await repository.save(personGoal1);
      await repository.save(personGoal2);
      await repository.save(categoryGoal);
      final johnGoals = await repository.getByPerson('person_john');

      // Assert
      expect(johnGoals.length, equals(1));
      expect(johnGoals.first.id, equals('goal_1'));
      expect(johnGoals.first.personId, equals('person_john'));
      expect(johnGoals.first.type, equals(GoalType.person));
    });

    test('relationship goal with all properties', () async {
      // Arrange
      final now = DateTime.now();
      final goal = Goal(
        id: 'goal_full',
        title: 'Relationship Goal',
        type: GoalType.person,
        metric: GoalMetric.events,
        targetValue: 4,
        period: GoalPeriod.month,
        personId: 'person_test',
        debtStrategy: DebtStrategy.carryForward,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await repository.save(goal);
      final retrieved = await repository.getById('goal_full');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.type, equals(GoalType.person));
      expect(retrieved.metric, equals(GoalMetric.events));
      expect(retrieved.targetValue, equals(4));
      expect(retrieved.period, equals(GoalPeriod.month));
      expect(retrieved.personId, equals('person_test'));
      expect(retrieved.categoryId, isNull);
      expect(retrieved.debtStrategy, equals(DebtStrategy.carryForward));
      expect(retrieved.isActive, isTrue);
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
