import 'package:test/test.dart';
import 'package:time_planner/domain/entities/activity.dart';
import 'package:time_planner/domain/entities/activity_series.dart';
import 'package:time_planner/domain/entities/person.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/activity_status.dart';
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/domain/services/series_matching_service.dart';
import 'package:time_planner/data/repositories/event_repository.dart';
import 'package:time_planner/data/repositories/event_people_repository.dart';

// Simple mock classes for testing
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

class MockEventPeopleRepository implements IEventPeopleRepository {
  Map<String, List<Person>> peopleByEvent = {};

  @override
  Future<List<Person>> getPeopleForEvent(String eventId) async {
    return peopleByEvent[eventId] ?? [];
  }

  @override
  Future<List<String>> getEventIdsForPerson(String personId) async {
    return peopleByEvent.entries
        .where((e) => e.value.any((p) => p.id == personId))
        .map((e) => e.key)
        .toList();
  }

  @override
  Future<void> addPersonToEvent(
      {required String eventId, required String personId}) async {
    // Not needed for these tests
  }

  @override
  Future<void> removePersonFromEvent(
      {required String eventId, required String personId}) async {
    // Not needed for these tests
  }

  @override
  Future<void> setPeopleForEvent(
      {required String eventId, required List<String> personIds}) async {
    // Not needed for these tests
  }

  @override
  Stream<List<Person>> watchPeopleForEvent(String eventId) {
    return Stream.value(peopleByEvent[eventId] ?? []);
  }
}

void main() {
  group('SeriesMatchingService', () {
    late MockEventRepository mockEventRepo;
    late MockEventPeopleRepository mockPeopleRepo;
    late SeriesMatchingService service;
    final now = DateTime.now();

    setUp(() {
      mockEventRepo = MockEventRepository();
      mockPeopleRepo = MockEventPeopleRepository();
      service = SeriesMatchingService(mockEventRepo, mockPeopleRepo);
    });

    Activity createTestActivity({
      required String id,
      String? name,
      String? categoryId,
      String? locationId,
      String? seriesId,
    }) {
      return Activity(
        id: id,
        name: name,
        timingType: TimingType.flexible,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
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

    test('matches activities with same title (case-insensitive)', () async {
      final newActivity = createTestActivity(id: 'new-1', name: 'Cinema');
      final existingActivity = createTestActivity(
        id: 'existing-1',
        name: 'cinema',
        seriesId: 'series-1',
      );

      mockEventRepo.events = [eventFromActivity(existingActivity)];

      final matches = await service.findMatchingSeries(newActivity);

      expect(matches, hasLength(1));
      expect(matches.first.id, equals('series-1'));
      expect(matches.first.displayTitle, equals('cinema'));
    });

    test('matches activities with 2+ property matches', () async {
      final newActivity = createTestActivity(
        id: 'new-1',
        categoryId: 'cat-1',
        locationId: 'loc-1',
      );
      final existingActivity = createTestActivity(
        id: 'existing-1',
        categoryId: 'cat-1',
        locationId: 'loc-1',
      );

      mockEventRepo.events = [eventFromActivity(existingActivity)];

      final matches = await service.findMatchingSeries(newActivity);

      expect(matches, hasLength(1));
      expect(matches.first.id, equals('existing-1'));
    });

    test('does not match with only 1 property match', () async {
      final newActivity = createTestActivity(
        id: 'new-1',
        categoryId: 'cat-1',
      );
      final existingActivity = createTestActivity(
        id: 'existing-1',
        categoryId: 'cat-1',
        locationId: 'loc-2',
      );

      mockEventRepo.events = [eventFromActivity(existingActivity)];

      final matches = await service.findMatchingSeries(newActivity);

      expect(matches, isEmpty);
    });

    test('groups multiple matching activities by seriesId', () async {
      final newActivity = createTestActivity(id: 'new-1', name: 'Gym');
      final existing1 = createTestActivity(
        id: 'existing-1',
        name: 'Gym',
        seriesId: 'series-gym',
      );
      final existing2 = createTestActivity(
        id: 'existing-2',
        name: 'Gym',
        seriesId: 'series-gym',
      );
      final existing3 = createTestActivity(
        id: 'existing-3',
        name: 'Gym', // No seriesId - should be its own group
      );

      mockEventRepo.events = [
        eventFromActivity(existing1),
        eventFromActivity(existing2),
        eventFromActivity(existing3),
      ];

      final matches = await service.findMatchingSeries(newActivity);

      expect(matches, hasLength(2)); // Two different groupings
      // Series with 2 activities should come first (sorted by count)
      expect(matches.first.count, equals(2));
      expect(matches.first.id, equals('series-gym'));
    });

    test('excludes the activity itself from matches', () async {
      final activity = createTestActivity(id: 'activity-1', name: 'Meeting');

      mockEventRepo.events = [eventFromActivity(activity)];

      final matches = await service.findMatchingSeries(activity);

      expect(matches, isEmpty);
    });

    test('hasMatchingSeries returns true when matches exist', () async {
      final newActivity = createTestActivity(id: 'new-1', name: 'Yoga');
      final existingActivity = createTestActivity(id: 'existing-1', name: 'Yoga');

      mockEventRepo.events = [eventFromActivity(existingActivity)];

      final hasMatches = await service.hasMatchingSeries(newActivity);

      expect(hasMatches, isTrue);
    });

    test('hasMatchingSeries returns false when no matches', () async {
      final newActivity = createTestActivity(id: 'new-1', name: 'Yoga');
      final existingActivity = createTestActivity(id: 'existing-1', name: 'Gym');

      mockEventRepo.events = [eventFromActivity(existingActivity)];

      final hasMatches = await service.hasMatchingSeries(newActivity);

      expect(hasMatches, isFalse);
    });

    test('matches by person overlap', () async {
      final person = Person(id: 'person-1', name: 'John', createdAt: now);

      final newActivity = createTestActivity(
        id: 'new-1',
        categoryId: 'cat-1',
      );
      final existingActivity = createTestActivity(
        id: 'existing-1',
        categoryId: 'cat-1',
      );

      // Both activities have the same person
      mockPeopleRepo.peopleByEvent = {
        'new-1': [person],
        'existing-1': [person],
      };

      mockEventRepo.events = [eventFromActivity(existingActivity)];

      final matches = await service.findMatchingSeries(newActivity);

      // Category + Person = 2 matches
      expect(matches, hasLength(1));
    });

    test('getSeriesCount returns correct count', () async {
      final activity1 = createTestActivity(
        id: 'act-1',
        seriesId: 'series-1',
      );
      final activity2 = createTestActivity(
        id: 'act-2',
        seriesId: 'series-1',
      );
      final activity3 = createTestActivity(
        id: 'act-3',
        seriesId: 'series-2',
      );

      mockEventRepo.events = [
        eventFromActivity(activity1),
        eventFromActivity(activity2),
        eventFromActivity(activity3),
      ];

      final count = await service.getSeriesCount('series-1');

      expect(count, equals(2));
    });
  });

  group('ActivitySeries', () {
    test('equality works correctly', () {
      final now = DateTime.now();
      final activity = Activity(
        id: 'act-1',
        name: 'Test',
        timingType: TimingType.flexible,
        status: ActivityStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final series1 = ActivitySeries(
        id: 'series-1',
        activities: [activity],
        displayTitle: 'Test',
        count: 1,
      );

      final series2 = ActivitySeries(
        id: 'series-1',
        activities: [activity],
        displayTitle: 'Test',
        count: 1,
      );

      expect(series1, equals(series2));
    });

    test('copyWith works correctly', () {
      final now = DateTime.now();
      final activity = Activity(
        id: 'act-1',
        name: 'Test',
        timingType: TimingType.flexible,
        status: ActivityStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final series = ActivitySeries(
        id: 'series-1',
        activities: [activity],
        displayTitle: 'Test',
        count: 1,
      );

      final updated = series.copyWith(displayTitle: 'Updated');

      expect(updated.id, equals('series-1'));
      expect(updated.displayTitle, equals('Updated'));
      expect(updated.count, equals(1));
    });
  });
}
