import 'package:test/test.dart';
import 'package:time_planner/domain/entities/activity.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/activity_status.dart';

void main() {
  group('Activity Entity', () {
    final now = DateTime.now();

    Activity createTestActivity({
      String? name = 'Test Activity',
      String? categoryId,
      String? locationId,
      TimingType timingType = TimingType.fixed,
      bool appCanMove = true,
      bool appCanResize = true,
      bool isUserLocked = false,
      DateTime? startTime,
      DateTime? endTime,
      Duration? duration,
    }) {
      return Activity(
        id: 'test_activity_1',
        name: name,
        description: 'Test Description',
        timingType: timingType,
        startTime: startTime ?? now,
        endTime: endTime ?? now.add(const Duration(hours: 1)),
        duration: duration,
        categoryId: categoryId,
        locationId: locationId,
        recurrenceRuleId: null,
        seriesId: null,
        appCanMove: appCanMove,
        appCanResize: appCanResize,
        isUserLocked: isUserLocked,
        status: ActivityStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }

    group('hasName', () {
      test('returns true when name is non-empty', () {
        final activity = createTestActivity(name: 'Test');
        expect(activity.hasName, isTrue);
      });

      test('returns false when name is null', () {
        final activity = createTestActivity(name: null);
        expect(activity.hasName, isFalse);
      });

      test('returns false when name is empty', () {
        final activity = createTestActivity(name: '');
        expect(activity.hasName, isFalse);
      });
    });

    group('hasLocation', () {
      test('returns true when locationId is set', () {
        final activity = createTestActivity(locationId: 'loc-1');
        expect(activity.hasLocation, isTrue);
      });

      test('returns false when locationId is null', () {
        final activity = createTestActivity(locationId: null);
        expect(activity.hasLocation, isFalse);
      });
    });

    group('hasCategory', () {
      test('returns true when categoryId is set', () {
        final activity = createTestActivity(categoryId: 'cat-1');
        expect(activity.hasCategory, isTrue);
      });

      test('returns false when categoryId is null', () {
        final activity = createTestActivity(categoryId: null);
        expect(activity.hasCategory, isFalse);
      });
    });

    group('isValid', () {
      test('valid with name only', () {
        final activity = createTestActivity(name: 'Test');
        expect(activity.isValid(), isTrue);
      });

      test('valid with category only', () {
        final activity = createTestActivity(name: null, categoryId: 'cat-1');
        expect(activity.isValid(), isTrue);
      });

      test('valid with location only', () {
        final activity = createTestActivity(name: null, locationId: 'loc-1');
        expect(activity.isValid(), isTrue);
      });

      test('valid with person only', () {
        final activity = createTestActivity(name: null);
        expect(activity.isValid(personIds: ['person-1']), isTrue);
      });

      test('valid with multiple properties', () {
        final activity = createTestActivity(
          name: 'Test',
          categoryId: 'cat-1',
          locationId: 'loc-1',
        );
        expect(activity.isValid(personIds: ['person-1']), isTrue);
      });

      test('invalid with no properties', () {
        final activity = createTestActivity(
          name: null,
          categoryId: null,
          locationId: null,
        );
        expect(activity.isValid(), isFalse);
      });

      test('invalid with empty name and no other properties', () {
        final activity = createTestActivity(
          name: '',
          categoryId: null,
          locationId: null,
        );
        expect(activity.isValid(), isFalse);
      });

      test('invalid with empty personIds list', () {
        final activity = createTestActivity(
          name: null,
          categoryId: null,
          locationId: null,
        );
        expect(activity.isValid(personIds: []), isFalse);
      });
    });

    group('isScheduled / isUnscheduled', () {
      test('isScheduled returns true when startTime is set', () {
        final activity = createTestActivity(startTime: now);
        expect(activity.isScheduled, isTrue);
        expect(activity.isUnscheduled, isFalse);
      });

      test('isUnscheduled returns true when startTime is null', () {
        final activity = createTestActivity(
          startTime: null,
          endTime: null,
          duration: const Duration(hours: 1),
        );
        expect(activity.isScheduled, isFalse);
        expect(activity.isUnscheduled, isTrue);
      });
    });

    group('isMovableByApp', () {
      test('returns true when appCanMove is true and not user locked', () {
        final activity = createTestActivity(
          appCanMove: true,
          isUserLocked: false,
        );
        expect(activity.isMovableByApp, isTrue);
      });

      test('returns false when appCanMove is false', () {
        final activity = createTestActivity(
          appCanMove: false,
          isUserLocked: false,
        );
        expect(activity.isMovableByApp, isFalse);
      });

      test('returns false when isUserLocked is true', () {
        final activity = createTestActivity(
          appCanMove: true,
          isUserLocked: true,
        );
        expect(activity.isMovableByApp, isFalse);
      });
    });

    group('isResizableByApp', () {
      test('returns true when appCanResize is true and not user locked', () {
        final activity = createTestActivity(
          appCanResize: true,
          isUserLocked: false,
        );
        expect(activity.isResizableByApp, isTrue);
      });

      test('returns false when appCanResize is false', () {
        final activity = createTestActivity(
          appCanResize: false,
          isUserLocked: false,
        );
        expect(activity.isResizableByApp, isFalse);
      });

      test('returns false when isUserLocked is true', () {
        final activity = createTestActivity(
          appCanResize: true,
          isUserLocked: true,
        );
        expect(activity.isResizableByApp, isFalse);
      });
    });

    group('isFixed', () {
      test('returns true for fixed timing type', () {
        final activity = createTestActivity(timingType: TimingType.fixed);
        expect(activity.isFixed, isTrue);
      });

      test('returns false for flexible timing type', () {
        final activity = createTestActivity(timingType: TimingType.flexible);
        expect(activity.isFixed, isFalse);
      });
    });

    group('copyWith', () {
      test('can change name to new value', () {
        final activity = createTestActivity(name: 'Test');
        final copied = activity.copyWith(name: 'New Name');
        expect(copied.name, 'New Name');
      });

      test('can clear name using clearName flag', () {
        final activity = createTestActivity(name: 'Test');
        final copied = activity.copyWith(clearName: true);
        expect(copied.name, isNull);
      });

      test('preserves name when clearName is false and name is null', () {
        final activity = createTestActivity(name: 'Test');
        // Passing null for name should preserve the existing value
        final copied = activity.copyWith(name: null);
        expect(copied.name, 'Test');
      });

      test('preserves all fields when not specified', () {
        final activity = createTestActivity(
          name: 'Test',
          categoryId: 'cat-1',
          locationId: 'loc-1',
          appCanMove: false,
          appCanResize: false,
          isUserLocked: true,
        );

        final copied = activity.copyWith();

        expect(copied.name, 'Test');
        expect(copied.categoryId, 'cat-1');
        expect(copied.locationId, 'loc-1');
        expect(copied.appCanMove, isFalse);
        expect(copied.appCanResize, isFalse);
        expect(copied.isUserLocked, isTrue);
      });
    });

    group('equality', () {
      test('two activities with same values are equal', () {
        final activity1 = createTestActivity(
          name: 'Test',
          categoryId: 'cat-1',
        );
        final activity2 = createTestActivity(
          name: 'Test',
          categoryId: 'cat-1',
        );
        expect(activity1, equals(activity2));
      });

      test('two activities with different names are not equal', () {
        final activity1 = createTestActivity(name: 'Test 1');
        final activity2 = createTestActivity(name: 'Test 2');
        expect(activity1, isNot(equals(activity2)));
      });

      test('activity with name and activity with null name are not equal', () {
        final activity1 = createTestActivity(name: 'Test');
        final activity2 = createTestActivity(name: null, categoryId: 'cat-1');
        expect(activity1, isNot(equals(activity2)));
      });
    });
  });
}
