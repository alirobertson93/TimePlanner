import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/recurrence_rule_repository.dart';
import 'package:time_planner/domain/entities/recurrence_rule.dart';
import 'package:time_planner/domain/enums/recurrence_frequency.dart';
import 'package:time_planner/domain/enums/recurrence_end_type.dart';

void main() {
  late AppDatabase database;
  late RecurrenceRuleRepository repository;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = RecurrenceRuleRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('RecurrenceRuleRepository', () {
    test('save and getById returns the saved recurrence rule', () async {
      // Arrange
      final rule = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        byWeekDay: [1, 3, 5], // Mon, Wed, Fri
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(rule);
      final retrieved = await repository.getById('rule_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('rule_1'));
      expect(retrieved.frequency, equals(RecurrenceFrequency.weekly));
      expect(retrieved.interval, equals(1));
      expect(retrieved.byWeekDay, equals([1, 3, 5]));
      expect(retrieved.endType, equals(RecurrenceEndType.never));
    });

    test('save updates existing recurrence rule', () async {
      // Arrange
      final rule = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      await repository.save(rule);

      // Act
      final updated = rule.copyWith(
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        byWeekDay: [1, 5], // Mon, Fri
      );
      await repository.save(updated);
      final retrieved = await repository.getById('rule_1');

      // Assert
      expect(retrieved!.frequency, equals(RecurrenceFrequency.weekly));
      expect(retrieved.interval, equals(2));
      expect(retrieved.byWeekDay, equals([1, 5]));
    });

    test('delete removes recurrence rule from database', () async {
      // Arrange
      final rule = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      await repository.save(rule);

      // Act
      await repository.delete('rule_1');
      final retrieved = await repository.getById('rule_1');

      // Assert
      expect(retrieved, isNull);
    });

    test('getById returns null for non-existent rule', () async {
      // Act
      final retrieved = await repository.getById('non_existent');

      // Assert
      expect(retrieved, isNull);
    });

    test('getAll returns all recurrence rules', () async {
      // Arrange
      final rule1 = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      final rule2 = RecurrenceRule(
        id: 'rule_2',
        frequency: RecurrenceFrequency.weekly,
        interval: 2,
        byWeekDay: [1, 2, 3, 4, 5],
        endType: RecurrenceEndType.afterOccurrences,
        occurrences: 10,
        createdAt: DateTime.now(),
      );

      final rule3 = RecurrenceRule(
        id: 'rule_3',
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        byMonthDay: [1, 15],
        endType: RecurrenceEndType.onDate,
        endDate: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(rule1);
      await repository.save(rule2);
      await repository.save(rule3);
      final rules = await repository.getAll();

      // Assert
      expect(rules.length, equals(3));
    });

    test('getByFrequency filters by frequency type', () async {
      // Arrange
      final dailyRule = RecurrenceRule(
        id: 'rule_daily',
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      final weeklyRule = RecurrenceRule(
        id: 'rule_weekly',
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      final monthlyRule = RecurrenceRule(
        id: 'rule_monthly',
        frequency: RecurrenceFrequency.monthly,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      await repository.save(dailyRule);
      await repository.save(weeklyRule);
      await repository.save(monthlyRule);

      // Act
      final dailyRules = await repository.getByFrequency(RecurrenceFrequency.daily);
      final weeklyRules = await repository.getByFrequency(RecurrenceFrequency.weekly);

      // Assert
      expect(dailyRules.length, equals(1));
      expect(dailyRules[0].id, equals('rule_daily'));
      expect(weeklyRules.length, equals(1));
      expect(weeklyRules[0].id, equals('rule_weekly'));
    });

    test('save rule with end date', () async {
      // Arrange
      final endDate = DateTime.now().add(const Duration(days: 90));
      final rule = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        endType: RecurrenceEndType.onDate,
        endDate: endDate,
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(rule);
      final retrieved = await repository.getById('rule_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.endType, equals(RecurrenceEndType.onDate));
      expect(retrieved.endDate, isNotNull);
    });

    test('save rule with occurrences limit', () async {
      // Arrange
      final rule = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.weekly,
        interval: 1,
        endType: RecurrenceEndType.afterOccurrences,
        occurrences: 52,
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(rule);
      final retrieved = await repository.getById('rule_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.endType, equals(RecurrenceEndType.afterOccurrences));
      expect(retrieved.occurrences, equals(52));
    });

    test('watchAll emits updates when rules change', () async {
      // Arrange
      final rule = RecurrenceRule(
        id: 'rule_1',
        frequency: RecurrenceFrequency.daily,
        interval: 1,
        endType: RecurrenceEndType.never,
        createdAt: DateTime.now(),
      );

      // Act
      final stream = repository.watchAll();
      final emittedValues = <List<RecurrenceRule>>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await repository.save(rule);
      await Future.delayed(const Duration(milliseconds: 100));
      await repository.delete('rule_1');
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
