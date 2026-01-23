import 'package:test/test.dart';
import 'package:time_planner/scheduler/event_scheduler.dart';
import 'package:time_planner/scheduler/models/schedule_request.dart';
import 'package:time_planner/scheduler/strategies/balanced_strategy.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('Scheduler Performance', () {
    late EventScheduler scheduler;
    late DateTime windowStart;
    late DateTime windowEnd;

    setUp(() {
      scheduler = EventScheduler();
      // 2-week scheduling window
      windowStart = DateTime(2026, 1, 13, 0, 0);
      windowEnd = DateTime(2026, 1, 27, 23, 59);
    });

    Event _createFlexibleEvent(int index, Duration duration) {
      return Event(
        id: 'event_$index',
        name: 'Flexible Event $index',
        timingType: TimingType.flexible,
        status: EventStatus.pending,
        duration: duration,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    Event _createFixedEvent(int index, DateTime start, Duration duration) {
      return Event(
        id: 'fixed_$index',
        name: 'Fixed Event $index',
        timingType: TimingType.fixed,
        status: EventStatus.pending,
        startTime: start,
        endTime: start.add(duration),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    test('schedules 10 events under 500ms', () {
      final flexibleEvents = List.generate(
        10,
        (i) => _createFlexibleEvent(i, const Duration(hours: 1)),
      );

      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: [],
        flexibleEvents: flexibleEvents,
        strategy: BalancedStrategy(),
        goals: [],
      );

      final result = scheduler.schedule(request);

      expect(result.computationTime.inMilliseconds, lessThan(500));
      expect(result.scheduledEvents.length, equals(10));
      print(
          '10 events scheduled in ${result.computationTime.inMilliseconds}ms');
    });

    test('schedules 25 events under 1000ms', () {
      final flexibleEvents = List.generate(
        25,
        (i) => _createFlexibleEvent(i, const Duration(minutes: 45)),
      );

      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: [],
        flexibleEvents: flexibleEvents,
        strategy: BalancedStrategy(),
        goals: [],
      );

      final result = scheduler.schedule(request);

      expect(result.computationTime.inMilliseconds, lessThan(1000));
      expect(result.scheduledEvents.length, equals(25));
      print(
          '25 events scheduled in ${result.computationTime.inMilliseconds}ms');
    });

    test('schedules 50 events under 2000ms (target)', () {
      final flexibleEvents = List.generate(
        50,
        (i) => _createFlexibleEvent(i, const Duration(minutes: 30)),
      );

      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: [],
        flexibleEvents: flexibleEvents,
        strategy: BalancedStrategy(),
        goals: [],
      );

      final result = scheduler.schedule(request);

      expect(result.computationTime.inMilliseconds, lessThan(2000));
      print(
          '50 events scheduled in ${result.computationTime.inMilliseconds}ms');
      print('Events scheduled: ${result.scheduledEvents.length}');
      print('Events unscheduled: ${result.unscheduledEvents.length}');
    });

    test('schedules 100 events under 5000ms', () {
      final flexibleEvents = List.generate(
        100,
        (i) => _createFlexibleEvent(i, const Duration(minutes: 30)),
      );

      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: [],
        flexibleEvents: flexibleEvents,
        strategy: BalancedStrategy(),
        goals: [],
      );

      final result = scheduler.schedule(request);

      expect(result.computationTime.inMilliseconds, lessThan(5000));
      print(
          '100 events scheduled in ${result.computationTime.inMilliseconds}ms');
      print('Events scheduled: ${result.scheduledEvents.length}');
      print('Events unscheduled: ${result.unscheduledEvents.length}');
    });

    test('handles mixed fixed and flexible events efficiently', () {
      // Create fixed events spread across the window
      final fixedEvents = <Event>[];
      for (int day = 0; day < 14; day++) {
        final dayStart = windowStart.add(Duration(days: day));
        // Add 2-3 fixed events per day
        fixedEvents.add(_createFixedEvent(
          day * 3,
          DateTime(dayStart.year, dayStart.month, dayStart.day, 9, 0),
          const Duration(hours: 1),
        ));
        fixedEvents.add(_createFixedEvent(
          day * 3 + 1,
          DateTime(dayStart.year, dayStart.month, dayStart.day, 14, 0),
          const Duration(hours: 1),
        ));
        if (day % 2 == 0) {
          fixedEvents.add(_createFixedEvent(
            day * 3 + 2,
            DateTime(dayStart.year, dayStart.month, dayStart.day, 16, 0),
            const Duration(minutes: 30),
          ));
        }
      }

      final flexibleEvents = List.generate(
        30,
        (i) => _createFlexibleEvent(i, const Duration(minutes: 45)),
      );

      final request = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: fixedEvents,
        flexibleEvents: flexibleEvents,
        strategy: BalancedStrategy(),
        goals: [],
      );

      final result = scheduler.schedule(request);

      expect(result.computationTime.inMilliseconds, lessThan(2000));
      print(
          'Mixed events (${fixedEvents.length} fixed + ${flexibleEvents.length} flexible) scheduled in ${result.computationTime.inMilliseconds}ms');
      print('Total scheduled: ${result.scheduledEvents.length}');
      print('Conflicts: ${result.conflicts.length}');
    });

    test('AvailabilityGrid initialization is efficient', () {
      // Test grid initialization for various window sizes
      final stopwatch = Stopwatch()..start();

      // 1 week window
      final oneWeekEnd = windowStart.add(const Duration(days: 7));
      final request1 = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: oneWeekEnd,
        fixedEvents: [],
        flexibleEvents: [_createFlexibleEvent(0, const Duration(hours: 1))],
        strategy: BalancedStrategy(),
        goals: [],
      );
      scheduler.schedule(request1);
      final oneWeekTime = stopwatch.elapsedMilliseconds;
      print('1-week window initialization: ${oneWeekTime}ms');

      stopwatch.reset();

      // 2 week window
      final request2 = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: windowEnd,
        fixedEvents: [],
        flexibleEvents: [_createFlexibleEvent(1, const Duration(hours: 1))],
        strategy: BalancedStrategy(),
        goals: [],
      );
      scheduler.schedule(request2);
      final twoWeekTime = stopwatch.elapsedMilliseconds;
      print('2-week window initialization: ${twoWeekTime}ms');

      stopwatch.reset();

      // 4 week window (month)
      final fourWeekEnd = windowStart.add(const Duration(days: 28));
      final request3 = ScheduleRequest(
        windowStart: windowStart,
        windowEnd: fourWeekEnd,
        fixedEvents: [],
        flexibleEvents: [_createFlexibleEvent(2, const Duration(hours: 1))],
        strategy: BalancedStrategy(),
        goals: [],
      );
      scheduler.schedule(request3);
      final fourWeekTime = stopwatch.elapsedMilliseconds;
      print('4-week window initialization: ${fourWeekTime}ms');

      // Should scale linearly, not exponentially
      expect(fourWeekTime, lessThan(2000));
    });
  });
}
