import 'package:test/test.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  group('Event Entity', () {
    final now = DateTime.now();
    
    Event createTestEvent({
      TimingType timingType = TimingType.fixed,
      bool appCanMove = true,
      bool appCanResize = true,
      bool isUserLocked = false,
      DateTime? startTime,
      DateTime? endTime,
      Duration? duration,
    }) {
      return Event(
        id: 'test_event_1',
        name: 'Test Event',
        description: 'Test Description',
        timingType: timingType,
        startTime: startTime ?? now,
        endTime: endTime ?? now.add(const Duration(hours: 1)),
        duration: duration,
        categoryId: null,
        locationId: null,
        recurrenceRuleId: null,
        appCanMove: appCanMove,
        appCanResize: appCanResize,
        isUserLocked: isUserLocked,
        status: EventStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('isMovableByApp', () {
      test('returns true when appCanMove is true and not user locked', () {
        final event = createTestEvent(
          appCanMove: true,
          isUserLocked: false,
        );
        
        expect(event.isMovableByApp, isTrue);
      });

      test('returns false when appCanMove is false', () {
        final event = createTestEvent(
          appCanMove: false,
          isUserLocked: false,
        );
        
        expect(event.isMovableByApp, isFalse);
      });

      test('returns false when isUserLocked is true', () {
        final event = createTestEvent(
          appCanMove: true,
          isUserLocked: true,
        );
        
        expect(event.isMovableByApp, isFalse);
      });

      test('returns false when both appCanMove is false and isUserLocked is true', () {
        final event = createTestEvent(
          appCanMove: false,
          isUserLocked: true,
        );
        
        expect(event.isMovableByApp, isFalse);
      });
    });

    group('isResizableByApp', () {
      test('returns true when appCanResize is true and not user locked', () {
        final event = createTestEvent(
          appCanResize: true,
          isUserLocked: false,
        );
        
        expect(event.isResizableByApp, isTrue);
      });

      test('returns false when appCanResize is false', () {
        final event = createTestEvent(
          appCanResize: false,
          isUserLocked: false,
        );
        
        expect(event.isResizableByApp, isFalse);
      });

      test('returns false when isUserLocked is true', () {
        final event = createTestEvent(
          appCanResize: true,
          isUserLocked: true,
        );
        
        expect(event.isResizableByApp, isFalse);
      });

      test('returns false when both appCanResize is false and isUserLocked is true', () {
        final event = createTestEvent(
          appCanResize: false,
          isUserLocked: true,
        );
        
        expect(event.isResizableByApp, isFalse);
      });
    });

    group('isFixed', () {
      test('returns true for fixed timing type', () {
        final event = createTestEvent(timingType: TimingType.fixed);
        
        expect(event.isFixed, isTrue);
      });

      test('returns false for flexible timing type', () {
        final event = createTestEvent(timingType: TimingType.flexible);
        
        expect(event.isFixed, isFalse);
      });
    });

    group('copyWith', () {
      test('preserves all constraint fields when not specified', () {
        final event = createTestEvent(
          appCanMove: true,
          appCanResize: false,
          isUserLocked: true,
        );
        
        final copied = event.copyWith(name: 'New Name');
        
        expect(copied.appCanMove, isTrue);
        expect(copied.appCanResize, isFalse);
        expect(copied.isUserLocked, isTrue);
        expect(copied.name, 'New Name');
      });

      test('can update appCanMove', () {
        final event = createTestEvent(appCanMove: true);
        
        final copied = event.copyWith(appCanMove: false);
        
        expect(copied.appCanMove, isFalse);
      });

      test('can update appCanResize', () {
        final event = createTestEvent(appCanResize: true);
        
        final copied = event.copyWith(appCanResize: false);
        
        expect(copied.appCanResize, isFalse);
      });

      test('can update isUserLocked', () {
        final event = createTestEvent(isUserLocked: false);
        
        final copied = event.copyWith(isUserLocked: true);
        
        expect(copied.isUserLocked, isTrue);
      });
    });

    group('equality', () {
      test('two events with same constraint values are equal', () {
        final event1 = createTestEvent(
          appCanMove: true,
          appCanResize: false,
          isUserLocked: true,
        );
        final event2 = createTestEvent(
          appCanMove: true,
          appCanResize: false,
          isUserLocked: true,
        );
        
        expect(event1, equals(event2));
      });

      test('two events with different appCanMove values are not equal', () {
        final event1 = createTestEvent(appCanMove: true);
        final event2 = createTestEvent(appCanMove: false);
        
        expect(event1, isNot(equals(event2)));
      });

      test('two events with different appCanResize values are not equal', () {
        final event1 = createTestEvent(appCanResize: true);
        final event2 = createTestEvent(appCanResize: false);
        
        expect(event1, isNot(equals(event2)));
      });

      test('two events with different isUserLocked values are not equal', () {
        final event1 = createTestEvent(isUserLocked: false);
        final event2 = createTestEvent(isUserLocked: true);
        
        expect(event1, isNot(equals(event2)));
      });
    });
  });
}
