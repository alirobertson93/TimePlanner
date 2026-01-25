import 'package:test/test.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/recurrence_rule.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/domain/enums/recurrence_frequency.dart';
import 'package:time_planner/domain/enums/recurrence_end_type.dart';
import 'package:time_planner/domain/services/recurrence_service.dart';

void main() {
  group('RecurrenceService', () {
    final now = DateTime.now();
    
    Event createTestEvent({
      String id = 'test_event_1',
      required DateTime startTime,
      Duration duration = const Duration(hours: 1),
      String? recurrenceRuleId,
    }) {
      return Event(
        id: id,
        name: 'Test Event',
        description: 'Test Description',
        timingType: TimingType.fixed,
        startTime: startTime,
        endTime: startTime.add(duration),
        categoryId: null,
        locationId: null,
        recurrenceRuleId: recurrenceRuleId,
        status: EventStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }

    RecurrenceRule createTestRule({
      String id = 'test_rule_1',
      RecurrenceFrequency frequency = RecurrenceFrequency.weekly,
      int interval = 1,
      List<int>? byWeekDay,
      List<int>? byMonthDay,
      RecurrenceEndType endType = RecurrenceEndType.never,
      DateTime? endDate,
      int? occurrences,
    }) {
      return RecurrenceRule(
        id: id,
        frequency: frequency,
        interval: interval,
        byWeekDay: byWeekDay,
        byMonthDay: byMonthDay,
        endType: endType,
        endDate: endDate,
        occurrences: occurrences,
        createdAt: now,
      );
    }

    group('expandRecurringEvent', () {
      test('expands weekly recurrence with specific days (Mon, Wed, Fri)', () {
        // Create an event on Monday, Jan 1, 2024 at 9:00 AM
        final startDate = DateTime(2024, 1, 1, 9, 0); // This is a Monday
        final event = createTestEvent(
          startTime: startDate,
          recurrenceRuleId: 'rule_1',
        );

        // Rule: Every week on Mon(1), Wed(3), Fri(5)
        final rule = createTestRule(
          byWeekDay: [1, 3, 5], // Mon, Wed, Fri
        );

        // Expand for the first week (Jan 1-7, 2024)
        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 7, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        // Should have Mon (Jan 1), Wed (Jan 3), Fri (Jan 5)
        expect(instances.length, equals(3));
        expect(instances[0].startTime!.day, equals(1)); // Monday
        expect(instances[1].startTime!.day, equals(3)); // Wednesday
        expect(instances[2].startTime!.day, equals(5)); // Friday
      });

      test('expands daily recurrence', () {
        final startDate = DateTime(2024, 1, 1, 9, 0);
        final event = createTestEvent(
          startTime: startDate,
          recurrenceRuleId: 'rule_1',
        );

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
          interval: 1,
        );

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 5, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        // Should have 5 days: Jan 1, 2, 3, 4, 5
        expect(instances.length, equals(5));
        for (int i = 0; i < 5; i++) {
          expect(instances[i].startTime!.day, equals(i + 1));
        }
      });

      test('respects end date condition', () {
        final startDate = DateTime(2024, 1, 1, 9, 0);
        final event = createTestEvent(
          startTime: startDate,
          recurrenceRuleId: 'rule_1',
        );

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
          endType: RecurrenceEndType.onDate,
          endDate: DateTime(2024, 1, 3),
        );

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 10, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        // Should have only 3 days: Jan 1, 2, 3 (stops at end date)
        expect(instances.length, equals(3));
      });

      test('respects occurrence count condition', () {
        final startDate = DateTime(2024, 1, 1, 9, 0);
        final event = createTestEvent(
          startTime: startDate,
          recurrenceRuleId: 'rule_1',
        );

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
          endType: RecurrenceEndType.afterOccurrences,
          occurrences: 3,
        );

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 10, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        // Should have only 3 occurrences
        expect(instances.length, equals(3));
      });

      test('handles events that started before range but continue into it', () {
        // Event starts on Dec 25, 2023
        final startDate = DateTime(2023, 12, 25, 9, 0);
        final event = createTestEvent(
          startTime: startDate,
          recurrenceRuleId: 'rule_1',
        );

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
        );

        // Query range is Jan 1-5, 2024
        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 5, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        // Should have 5 days in January
        expect(instances.length, equals(5));
        expect(instances[0].startTime!.day, equals(1));
        expect(instances[4].startTime!.day, equals(5));
      });

      test('preserves event duration across instances', () {
        final startDate = DateTime(2024, 1, 1, 9, 0);
        final duration = const Duration(hours: 2, minutes: 30);
        final event = createTestEvent(
          startTime: startDate,
          duration: duration,
          recurrenceRuleId: 'rule_1',
        );

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
        );

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 3, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        for (final instance in instances) {
          final instanceDuration = instance.endTime!.difference(instance.startTime!);
          expect(instanceDuration, equals(duration));
        }
      });

      test('returns empty list for event without start time', () {
        final event = Event(
          id: 'test',
          name: 'Test',
          timingType: TimingType.flexible,
          duration: const Duration(hours: 1),
          recurrenceRuleId: 'rule_1',
          status: EventStatus.pending,
          createdAt: now,
          updatedAt: now,
        );

        final rule = createTestRule();
        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 7);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        expect(instances, isEmpty);
      });

      test('handles interval greater than 1 for daily recurrence', () {
        final startDate = DateTime(2024, 1, 1, 9, 0);
        final event = createTestEvent(
          startTime: startDate,
          recurrenceRuleId: 'rule_1',
        );

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
          interval: 2, // Every 2 days
        );

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 10, 23, 59, 59);

        final instances = RecurrenceService.expandRecurringEvent(
          event: event,
          rule: rule,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
        );

        // Should have Jan 1, 3, 5, 7, 9
        expect(instances.length, equals(5));
        expect(instances[0].startTime!.day, equals(1));
        expect(instances[1].startTime!.day, equals(3));
        expect(instances[2].startTime!.day, equals(5));
      });
    });

    group('expandEvents', () {
      test('expands recurring events and includes non-recurring events', () {
        // Create a recurring event
        final recurringEvent = createTestEvent(
          id: 'recurring',
          startTime: DateTime(2024, 1, 1, 9, 0),
          recurrenceRuleId: 'rule_1',
        );

        // Create a non-recurring event
        final nonRecurringEvent = createTestEvent(
          id: 'non_recurring',
          startTime: DateTime(2024, 1, 3, 10, 0),
          recurrenceRuleId: null,
        );

        final events = [recurringEvent, nonRecurringEvent];

        final rule = createTestRule(
          frequency: RecurrenceFrequency.daily,
        );

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 5, 23, 59, 59);

        final expandedEvents = RecurrenceService.expandEvents(
          events: events,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          getRecurrenceRule: (id) => id == 'rule_1' ? rule : null,
        );

        // Should have 5 recurring instances + 1 non-recurring = 6 total
        expect(expandedEvents.length, equals(6));
        
        // Check that the non-recurring event is included
        final nonRecurringInResults = expandedEvents.where((e) => e.id == 'non_recurring');
        expect(nonRecurringInResults.length, equals(1));
      });

      test('excludes non-recurring events outside the range', () {
        final event1 = createTestEvent(
          id: 'before',
          startTime: DateTime(2023, 12, 31, 9, 0),
          recurrenceRuleId: null,
        );

        final event2 = createTestEvent(
          id: 'inside',
          startTime: DateTime(2024, 1, 2, 9, 0),
          recurrenceRuleId: null,
        );

        final event3 = createTestEvent(
          id: 'after',
          startTime: DateTime(2024, 1, 6, 9, 0),
          recurrenceRuleId: null,
        );

        final events = [event1, event2, event3];

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 5, 23, 59, 59);

        final expandedEvents = RecurrenceService.expandEvents(
          events: events,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          getRecurrenceRule: (id) => null,
        );

        // Should only have event2
        expect(expandedEvents.length, equals(1));
        expect(expandedEvents[0].id, equals('inside'));
      });

      test('handles recurring event without rule gracefully', () {
        final event = createTestEvent(
          startTime: DateTime(2024, 1, 2, 9, 0),
          recurrenceRuleId: 'missing_rule',
        );

        final events = [event];

        final rangeStart = DateTime(2024, 1, 1);
        final rangeEnd = DateTime(2024, 1, 5, 23, 59, 59);

        final expandedEvents = RecurrenceService.expandEvents(
          events: events,
          rangeStart: rangeStart,
          rangeEnd: rangeEnd,
          getRecurrenceRule: (id) => null, // Rule not found
        );

        // Should include the event as-is since it's in range
        expect(expandedEvents.length, equals(1));
        expect(expandedEvents[0].id, equals('test_event_1'));
      });
    });
  });
}
