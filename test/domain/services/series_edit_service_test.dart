import 'package:test/test.dart';
import 'package:time_planner/domain/entities/activity.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/activity_status.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/domain/enums/edit_scope.dart';
import 'package:time_planner/domain/services/series_edit_service.dart';
import 'package:time_planner/data/repositories/event_repository.dart';

// Simple mock class for testing
class MockEventRepository implements IEventRepository {
  List<Event> events = [];

  @override
  Future<List<Event>> getAll() async => events;

  @override
  Future<Event?> getById(String id) async {
    try {
      return events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Event>> getBySeriesId(String seriesId) async {
    return events.where((e) => e.seriesId == seriesId).toList();
  }

  @override
  Future<int> countInSeries(String seriesId) async {
    return events.where((e) => e.seriesId == seriesId).length;
  }

  @override
  Future<void> save(Event event) async {
    final index = events.indexWhere((e) => e.id == event.id);
    if (index >= 0) {
      events[index] = event;
    } else {
      events.add(event);
    }
  }

  @override
  Future<void> delete(String id) async {
    events.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<Event>> getEventsInRange(DateTime start, DateTime end) async {
    return events.where((e) {
      if (e.startTime == null) return false;
      return e.startTime!.isAfter(start) && e.startTime!.isBefore(end);
    }).toList();
  }

  @override
  Future<List<Event>> getByCategory(String categoryId) async {
    return events.where((e) => e.categoryId == categoryId).toList();
  }

  @override
  Future<List<Event>> getByStatus(EventStatus status) async {
    return events.where((e) => e.status == status).toList();
  }
}

void main() {
  group('SeriesEditService', () {
    late MockEventRepository mockEventRepo;
    late SeriesEditService service;
    final now = DateTime.now();

    setUp(() {
      mockEventRepo = MockEventRepository();
      service = SeriesEditService(mockEventRepo);
    });

    Activity createTestActivity({
      required String id,
      String? name,
      String? categoryId,
      String? locationId,
      String? seriesId,
      DateTime? startTime,
    }) {
      return Activity(
        id: id,
        name: name,
        timingType: TimingType.flexible,
        startTime: startTime ?? now,
        endTime: (startTime ?? now).add(const Duration(hours: 1)),
        categoryId: categoryId,
        locationId: locationId,
        seriesId: seriesId,
        status: ActivityStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }

    Event eventFromActivity(Activity activity) {
      return Event(
        id: activity.id,
        name: activity.name,
        timingType: activity.timingType,
        startTime: activity.startTime,
        endTime: activity.endTime,
        categoryId: activity.categoryId,
        locationId: activity.locationId,
        seriesId: activity.seriesId,
        status: EventStatus.pending,
        createdAt: activity.createdAt,
        updatedAt: activity.updatedAt,
      );
    }

    group('updateWithScope', () {
      test('thisOnly updates only the specified activity', () async {
        final activity1 = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          seriesId: 'series-1',
        );
        final activity2 = createTestActivity(
          id: 'act-2',
          name: 'Gym',
          seriesId: 'series-1',
        );

        mockEventRepo.events = [
          eventFromActivity(activity1),
          eventFromActivity(activity2),
        ];

        final count = await service.updateWithScope(
          activity: activity1,
          updates: {'name': 'Updated Gym'},
          scope: EditScope.thisOnly,
        );

        expect(count, equals(1));

        final updated1 = await mockEventRepo.getById('act-1');
        final updated2 = await mockEventRepo.getById('act-2');

        expect(updated1?.name, equals('Updated Gym'));
        expect(updated2?.name, equals('Gym')); // Unchanged
      });

      test('allInSeries updates all activities in the series', () async {
        final activity1 = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          seriesId: 'series-1',
        );
        final activity2 = createTestActivity(
          id: 'act-2',
          name: 'Gym',
          seriesId: 'series-1',
        );
        final activity3 = createTestActivity(
          id: 'act-3',
          name: 'Yoga',
          seriesId: 'series-2',
        );

        mockEventRepo.events = [
          eventFromActivity(activity1),
          eventFromActivity(activity2),
          eventFromActivity(activity3),
        ];

        final count = await service.updateWithScope(
          activity: activity1,
          updates: {'name': 'Updated Gym'},
          scope: EditScope.allInSeries,
        );

        expect(count, equals(2));

        final updated1 = await mockEventRepo.getById('act-1');
        final updated2 = await mockEventRepo.getById('act-2');
        final updated3 = await mockEventRepo.getById('act-3');

        expect(updated1?.name, equals('Updated Gym'));
        expect(updated2?.name, equals('Updated Gym'));
        expect(updated3?.name, equals('Yoga')); // Different series - unchanged
      });

      test('thisAndFuture updates this and future activities', () async {
        final activity1 = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          seriesId: 'series-1',
          startTime: now.subtract(const Duration(days: 2)),
        );
        final activity2 = createTestActivity(
          id: 'act-2',
          name: 'Gym',
          seriesId: 'series-1',
          startTime: now, // Current activity
        );
        final activity3 = createTestActivity(
          id: 'act-3',
          name: 'Gym',
          seriesId: 'series-1',
          startTime: now.add(const Duration(days: 2)),
        );

        mockEventRepo.events = [
          eventFromActivity(activity1),
          eventFromActivity(activity2),
          eventFromActivity(activity3),
        ];

        final count = await service.updateWithScope(
          activity: activity2,
          updates: {'name': 'Updated Gym'},
          scope: EditScope.thisAndFuture,
        );

        expect(count, equals(2)); // activity2 and activity3

        final updated1 = await mockEventRepo.getById('act-1');
        final updated2 = await mockEventRepo.getById('act-2');
        final updated3 = await mockEventRepo.getById('act-3');

        expect(updated1?.name, equals('Gym')); // Past - unchanged
        expect(updated2?.name, equals('Updated Gym'));
        expect(updated3?.name, equals('Updated Gym'));
      });

      test('handles activity without seriesId', () async {
        final activity = createTestActivity(
          id: 'act-1',
          name: 'Standalone',
          seriesId: null,
        );

        mockEventRepo.events = [eventFromActivity(activity)];

        final count = await service.updateWithScope(
          activity: activity,
          updates: {'name': 'Updated'},
          scope: EditScope.allInSeries,
        );

        expect(count, equals(1)); // Just this activity

        final updated = await mockEventRepo.getById('act-1');
        expect(updated?.name, equals('Updated'));
      });
    });

    group('detectVariance', () {
      test('detects varying properties', () async {
        final activity1 = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          categoryId: 'cat-1',
          seriesId: 'series-1',
        );
        final activity2 = createTestActivity(
          id: 'act-2',
          name: 'Gym Session', // Different name
          categoryId: 'cat-1',
          seriesId: 'series-1',
        );

        mockEventRepo.events = [
          eventFromActivity(activity1),
          eventFromActivity(activity2),
        ];

        final variance = await service.detectVariance('series-1');

        expect(variance.containsKey('name'), isTrue);
        expect(variance['name'], containsAll(['Gym', 'Gym Session']));
        expect(variance.containsKey('categoryId'),
            isFalse); // Same across all - no variance
      });

      test('returns empty map when no variance', () async {
        final activity1 = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          seriesId: 'series-1',
        );
        final activity2 = createTestActivity(
          id: 'act-2',
          name: 'Gym',
          seriesId: 'series-1',
        );

        mockEventRepo.events = [
          eventFromActivity(activity1),
          eventFromActivity(activity2),
        ];

        final variance = await service.detectVariance('series-1');

        expect(variance, isEmpty);
      });
    });

    group('addToSeries', () {
      test('sets seriesId on activity', () async {
        final activity = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          seriesId: null,
        );

        mockEventRepo.events = [eventFromActivity(activity)];

        await service.addToSeries(activity, 'series-1');

        final updated = await mockEventRepo.getById('act-1');
        expect(updated?.seriesId, equals('series-1'));
      });
    });

    group('removeFromSeries', () {
      test('clears seriesId from activity', () async {
        final activity = createTestActivity(
          id: 'act-1',
          name: 'Gym',
          seriesId: 'series-1',
        );

        mockEventRepo.events = [eventFromActivity(activity)];

        await service.removeFromSeries(activity);

        final updated = await mockEventRepo.getById('act-1');
        expect(updated?.seriesId, isNull);
      });
    });
  });

  group('EditScope', () {
    test('label returns correct string', () {
      expect(EditScope.thisOnly.label, equals('This activity only'));
      expect(EditScope.allInSeries.label, equals('All activities in this series'));
      expect(
          EditScope.thisAndFuture.label, equals('This and all future activities'));
    });

    test('description returns correct string', () {
      expect(EditScope.thisOnly.description,
          equals('Changes will only apply to this activity'));
      expect(EditScope.allInSeries.description,
          equals('Changes will apply to all activities in the series'));
      expect(EditScope.thisAndFuture.description,
          equals('Changes will apply to this and all future occurrences'));
    });
  });
}
