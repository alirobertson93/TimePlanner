import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/event_repository.dart';
import 'package:time_planner/domain/entities/event.dart' as domain;
import 'package:time_planner/domain/enums/event_status.dart';
import 'package:time_planner/domain/enums/timing_type.dart';

void main() {
  late AppDatabase db;
  late EventRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = EventRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('EventRepository - getEventsInRange', () {
    test('returns only events within specified range', () async {
      // Arrange
      final now = DateTime.now();
      final rangeStart = DateTime(now.year, now.month, now.day, 9, 0);
      final rangeEnd = DateTime(now.year, now.month, now.day, 17, 0);

      final eventInRange = domain.Event(
        id: 'event_1',
        name: 'Meeting',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 10, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
        createdAt: now,
        updatedAt: now,
      );

      final eventBeforeRange = domain.Event(
        id: 'event_2',
        name: 'Early Event',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 7, 0),
        endTime: DateTime(now.year, now.month, now.day, 8, 0),
        createdAt: now,
        updatedAt: now,
      );

      final eventAfterRange = domain.Event(
        id: 'event_3',
        name: 'Late Event',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 18, 0),
        endTime: DateTime(now.year, now.month, now.day, 19, 0),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(eventInRange);
      await repository.save(eventBeforeRange);
      await repository.save(eventAfterRange);

      // Act
      final result = await repository.getEventsInRange(rangeStart, rangeEnd);

      // Assert
      expect(result.length, equals(1));
      expect(result.first.id, equals('event_1'));
      expect(result.first.name, equals('Meeting'));
    });

    test('includes events that span range boundaries', () async {
      // Arrange
      final now = DateTime.now();
      final rangeStart = DateTime(now.year, now.month, now.day, 10, 0);
      final rangeEnd = DateTime(now.year, now.month, now.day, 15, 0);

      final eventStartsBeforeRangeEndsInRange = domain.Event(
        id: 'event_1',
        name: 'Starts Before',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 11, 0),
        createdAt: now,
        updatedAt: now,
      );

      final eventStartsInRangeEndsAfter = domain.Event(
        id: 'event_2',
        name: 'Ends After',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 16, 0),
        createdAt: now,
        updatedAt: now,
      );

      final eventSpansEntireRange = domain.Event(
        id: 'event_3',
        name: 'Spans Entire Range',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 8, 0),
        endTime: DateTime(now.year, now.month, now.day, 17, 0),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(eventStartsBeforeRangeEndsInRange);
      await repository.save(eventStartsInRangeEndsAfter);
      await repository.save(eventSpansEntireRange);

      // Act
      final result = await repository.getEventsInRange(rangeStart, rangeEnd);

      // Assert
      expect(result.length, equals(3));
      expect(result.map((e) => e.id).toSet(), equals({'event_1', 'event_2', 'event_3'}));
    });

    test('returns empty list when no events in range', () async {
      // Arrange
      final now = DateTime.now();
      final rangeStart = DateTime(now.year, now.month, now.day, 10, 0);
      final rangeEnd = DateTime(now.year, now.month, now.day, 12, 0);

      final eventOutsideRange = domain.Event(
        id: 'event_1',
        name: 'Outside Range',
        timingType: TimingType.fixed,
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 0),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(eventOutsideRange);

      // Act
      final result = await repository.getEventsInRange(rangeStart, rangeEnd);

      // Assert
      expect(result, isEmpty);
    });
  });

  group('EventRepository - save and retrieve', () {
    test('saves and retrieves event correctly', () async {
      // Arrange
      final now = DateTime.now();
      final event = domain.Event(
        id: 'event_1',
        name: 'Test Event',
        description: 'Test Description',
        timingType: TimingType.flexible,
        duration: const Duration(hours: 1),
        categoryId: 'cat_work',
        appCanMove: true,
        appCanResize: true,
        isUserLocked: false,
        status: EventStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      // Act
      await repository.save(event);
      final retrieved = await repository.getById('event_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(event.id));
      expect(retrieved.name, equals(event.name));
      expect(retrieved.description, equals(event.description));
      expect(retrieved.timingType, equals(event.timingType));
      expect(retrieved.duration, equals(event.duration));
      expect(retrieved.categoryId, equals(event.categoryId));
      expect(retrieved.appCanMove, equals(event.appCanMove));
      expect(retrieved.appCanResize, equals(event.appCanResize));
      expect(retrieved.isUserLocked, equals(event.isUserLocked));
      expect(retrieved.status, equals(event.status));
    });

    test('updates existing event', () async {
      // Arrange
      final now = DateTime.now();
      final event = domain.Event(
        id: 'event_1',
        name: 'Original Name',
        timingType: TimingType.fixed,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(event);

      // Act
      final updated = event.copyWith(
        name: 'Updated Name',
        updatedAt: now.add(const Duration(seconds: 1)),
      );
      await repository.save(updated);

      final retrieved = await repository.getById('event_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Updated Name'));
    });

    test('returns null for non-existent event', () async {
      // Act
      final result = await repository.getById('non_existent_id');

      // Assert
      expect(result, isNull);
    });
  });

  group('EventRepository - delete', () {
    test('deletes event from database', () async {
      // Arrange
      final now = DateTime.now();
      final event = domain.Event(
        id: 'event_1',
        name: 'Event to Delete',
        timingType: TimingType.fixed,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(event);
      expect(await repository.getById('event_1'), isNotNull);

      // Act
      await repository.delete('event_1');

      // Assert
      final result = await repository.getById('event_1');
      expect(result, isNull);
    });

    test('delete non-existent event does not throw error', () async {
      // Act & Assert
      expect(() => repository.delete('non_existent_id'), returnsNormally);
    });
  });

  group('EventRepository - additional queries', () {
    test('getAll returns all events', () async {
      // Arrange
      final now = DateTime.now();
      final event1 = domain.Event(
        id: 'event_1',
        name: 'Event 1',
        timingType: TimingType.fixed,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        createdAt: now,
        updatedAt: now,
      );

      final event2 = domain.Event(
        id: 'event_2',
        name: 'Event 2',
        timingType: TimingType.flexible,
        duration: const Duration(hours: 2),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(event1);
      await repository.save(event2);

      // Act
      final result = await repository.getAll();

      // Assert
      expect(result.length, equals(2));
      expect(result.map((e) => e.id).toSet(), equals({'event_1', 'event_2'}));
    });

    test('getByCategory returns events for specific category', () async {
      // Arrange
      final now = DateTime.now();
      final workEvent = domain.Event(
        id: 'event_1',
        name: 'Work Event',
        timingType: TimingType.fixed,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        categoryId: 'cat_work',
        createdAt: now,
        updatedAt: now,
      );

      final personalEvent = domain.Event(
        id: 'event_2',
        name: 'Personal Event',
        timingType: TimingType.fixed,
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        categoryId: 'cat_personal',
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(workEvent);
      await repository.save(personalEvent);

      // Act
      final result = await repository.getByCategory('cat_work');

      // Assert
      expect(result.length, equals(1));
      expect(result.first.id, equals('event_1'));
      expect(result.first.categoryId, equals('cat_work'));
    });

    test('getByStatus returns events with specific status', () async {
      // Arrange
      final now = DateTime.now();
      final pendingEvent = domain.Event(
        id: 'event_1',
        name: 'Pending Event',
        timingType: TimingType.fixed,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        status: EventStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      final completedEvent = domain.Event(
        id: 'event_2',
        name: 'Completed Event',
        timingType: TimingType.fixed,
        startTime: now.subtract(const Duration(hours: 2)),
        endTime: now.subtract(const Duration(hours: 1)),
        status: EventStatus.completed,
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(pendingEvent);
      await repository.save(completedEvent);

      // Act
      final result = await repository.getByStatus(EventStatus.pending);

      // Assert
      expect(result.length, equals(1));
      expect(result.first.id, equals('event_1'));
      expect(result.first.status, equals(EventStatus.pending));
    });
  });

  group('EventRepository - domain logic', () {
    test('event with duration calculates effectiveDuration correctly', () async {
      // Arrange
      final now = DateTime.now();
      final event = domain.Event(
        id: 'event_1',
        name: 'Event with Duration',
        timingType: TimingType.flexible,
        duration: const Duration(hours: 2, minutes: 30),
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(event);

      // Act
      final retrieved = await repository.getById('event_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.effectiveDuration, equals(const Duration(hours: 2, minutes: 30)));
    });

    test('event with start/end times calculates effectiveDuration correctly', () async {
      // Arrange
      final now = DateTime.now();
      final startTime = DateTime(now.year, now.month, now.day, 10, 0);
      final endTime = DateTime(now.year, now.month, now.day, 12, 30);
      
      final event = domain.Event(
        id: 'event_1',
        name: 'Event with Times',
        timingType: TimingType.fixed,
        startTime: startTime,
        endTime: endTime,
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(event);

      // Act
      final retrieved = await repository.getById('event_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.effectiveDuration, equals(const Duration(hours: 2, minutes: 30)));
    });

    test('isMovableByApp returns correct value', () async {
      // Arrange
      final now = DateTime.now();
      final movableEvent = domain.Event(
        id: 'event_1',
        name: 'Movable Event',
        timingType: TimingType.flexible,
        duration: const Duration(hours: 1),
        appCanMove: true,
        isUserLocked: false,
        createdAt: now,
        updatedAt: now,
      );

      final lockedEvent = domain.Event(
        id: 'event_2',
        name: 'Locked Event',
        timingType: TimingType.flexible,
        duration: const Duration(hours: 1),
        appCanMove: true,
        isUserLocked: true,
        createdAt: now,
        updatedAt: now,
      );

      await repository.save(movableEvent);
      await repository.save(lockedEvent);

      // Act
      final retrievedMovable = await repository.getById('event_1');
      final retrievedLocked = await repository.getById('event_2');

      // Assert
      expect(retrievedMovable!.isMovableByApp, isTrue);
      expect(retrievedLocked!.isMovableByApp, isFalse);
    });
  });
}
