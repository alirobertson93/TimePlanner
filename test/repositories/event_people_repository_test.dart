import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/event_repository.dart';
import 'package:time_planner/data/repositories/person_repository.dart';
import 'package:time_planner/data/repositories/event_people_repository.dart';
import 'package:time_planner/domain/entities/event.dart';
import 'package:time_planner/domain/entities/person.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/event_status.dart';

void main() {
  late AppDatabase database;
  late EventRepository eventRepository;
  late PersonRepository personRepository;
  late EventPeopleRepository eventPeopleRepository;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    eventRepository = EventRepository(database);
    personRepository = PersonRepository(database);
    eventPeopleRepository = EventPeopleRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  // Helper to create a test event
  Event createTestEvent(String id, String name) {
    return Event(
      id: id,
      name: name,
      timingType: TimingType.fixed,
      startTime: DateTime.now(),
      endTime: DateTime.now().add(const Duration(hours: 1)),
      status: EventStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Helper to create a test person
  Person createTestPerson(String id, String name) {
    return Person(
      id: id,
      name: name,
      createdAt: DateTime.now(),
    );
  }

  group('EventPeopleRepository', () {
    test('addPersonToEvent associates a person with an event', () async {
      // Arrange
      final event = createTestEvent('event_1', 'Meeting');
      final person = createTestPerson('person_1', 'John Doe');
      await eventRepository.save(event);
      await personRepository.save(person);

      // Act
      await eventPeopleRepository.addPersonToEvent(
        eventId: 'event_1',
        personId: 'person_1',
      );

      final people = await eventPeopleRepository.getPeopleForEvent('event_1');

      // Assert
      expect(people.length, equals(1));
      expect(people[0].id, equals('person_1'));
      expect(people[0].name, equals('John Doe'));
    });

    test('getPeopleForEvent returns all people for an event', () async {
      // Arrange
      final event = createTestEvent('event_1', 'Team Meeting');
      final person1 = createTestPerson('person_1', 'Alice');
      final person2 = createTestPerson('person_2', 'Bob');
      final person3 = createTestPerson('person_3', 'Charlie');

      await eventRepository.save(event);
      await personRepository.save(person1);
      await personRepository.save(person2);
      await personRepository.save(person3);

      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_1');
      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_2');

      // Act
      final people = await eventPeopleRepository.getPeopleForEvent('event_1');

      // Assert
      expect(people.length, equals(2));
      // Should be ordered alphabetically by name
      expect(people[0].name, equals('Alice'));
      expect(people[1].name, equals('Bob'));
    });

    test('removePersonFromEvent removes the association', () async {
      // Arrange
      final event = createTestEvent('event_1', 'Meeting');
      final person = createTestPerson('person_1', 'John Doe');

      await eventRepository.save(event);
      await personRepository.save(person);
      await eventPeopleRepository.addPersonToEvent(
        eventId: 'event_1',
        personId: 'person_1',
      );

      // Act
      await eventPeopleRepository.removePersonFromEvent(
        eventId: 'event_1',
        personId: 'person_1',
      );

      final people = await eventPeopleRepository.getPeopleForEvent('event_1');

      // Assert
      expect(people.isEmpty, isTrue);
    });

    test('getEventIdsForPerson returns event IDs for a person', () async {
      // Arrange
      final event1 = createTestEvent('event_1', 'Meeting 1');
      final event2 = createTestEvent('event_2', 'Meeting 2');
      final person = createTestPerson('person_1', 'John Doe');

      await eventRepository.save(event1);
      await eventRepository.save(event2);
      await personRepository.save(person);

      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_1');
      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_2', personId: 'person_1');

      // Act
      final eventIds =
          await eventPeopleRepository.getEventIdsForPerson('person_1');

      // Assert
      expect(eventIds.length, equals(2));
      expect(eventIds.contains('event_1'), isTrue);
      expect(eventIds.contains('event_2'), isTrue);
    });

    test('setPeopleForEvent replaces all existing associations', () async {
      // Arrange
      final event = createTestEvent('event_1', 'Meeting');
      final person1 = createTestPerson('person_1', 'Alice');
      final person2 = createTestPerson('person_2', 'Bob');
      final person3 = createTestPerson('person_3', 'Charlie');

      await eventRepository.save(event);
      await personRepository.save(person1);
      await personRepository.save(person2);
      await personRepository.save(person3);

      // Add initial associations
      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_1');
      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_2');

      // Act - replace with new set
      await eventPeopleRepository.setPeopleForEvent(
        eventId: 'event_1',
        personIds: ['person_2', 'person_3'],
      );

      final people = await eventPeopleRepository.getPeopleForEvent('event_1');

      // Assert
      expect(people.length, equals(2));
      expect(people.any((p) => p.id == 'person_1'), isFalse); // Removed
      expect(people.any((p) => p.id == 'person_2'), isTrue); // Kept
      expect(people.any((p) => p.id == 'person_3'), isTrue); // Added
    });

    test('getPeopleForEvent returns empty list for event with no people',
        () async {
      // Arrange
      final event = createTestEvent('event_1', 'Solo Meeting');
      await eventRepository.save(event);

      // Act
      final people = await eventPeopleRepository.getPeopleForEvent('event_1');

      // Assert
      expect(people.isEmpty, isTrue);
    });

    test('deleting person removes association (cascade delete)', () async {
      // Arrange
      final event = createTestEvent('event_1', 'Meeting');
      final person = createTestPerson('person_1', 'John Doe');

      await eventRepository.save(event);
      await personRepository.save(person);
      await eventPeopleRepository.addPersonToEvent(
        eventId: 'event_1',
        personId: 'person_1',
      );

      // Act
      await personRepository.delete('person_1');
      final people = await eventPeopleRepository.getPeopleForEvent('event_1');

      // Assert
      expect(people.isEmpty, isTrue);
    });

    test('deleting event removes association (cascade delete)', () async {
      // Arrange
      final event = createTestEvent('event_1', 'Meeting');
      final person = createTestPerson('person_1', 'John Doe');

      await eventRepository.save(event);
      await personRepository.save(person);
      await eventPeopleRepository.addPersonToEvent(
        eventId: 'event_1',
        personId: 'person_1',
      );

      // Act
      await eventRepository.delete('event_1');
      final eventIds =
          await eventPeopleRepository.getEventIdsForPerson('person_1');

      // Assert
      expect(eventIds.isEmpty, isTrue);
    });

    test('watchPeopleForEvent emits updates when associations change',
        () async {
      // Arrange
      final event = createTestEvent('event_1', 'Meeting');
      final person1 = createTestPerson('person_1', 'Alice');
      final person2 = createTestPerson('person_2', 'Bob');

      await eventRepository.save(event);
      await personRepository.save(person1);
      await personRepository.save(person2);

      // Act
      final stream = eventPeopleRepository.watchPeopleForEvent('event_1');
      final emittedValues = <List<Person>>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_1');
      await Future.delayed(const Duration(milliseconds: 100));
      await eventPeopleRepository.addPersonToEvent(
          eventId: 'event_1', personId: 'person_2');
      await Future.delayed(const Duration(milliseconds: 100));
      await eventPeopleRepository.removePersonFromEvent(
          eventId: 'event_1', personId: 'person_1');
      await Future.delayed(const Duration(milliseconds: 100));

      await subscription.cancel();

      // Assert
      expect(emittedValues.length, greaterThanOrEqualTo(4));
      expect(emittedValues[0].length, equals(0)); // Initial empty
      expect(emittedValues[1].length, equals(1)); // After first add
      expect(emittedValues[2].length, equals(2)); // After second add
      expect(emittedValues[3].length, equals(1)); // After remove
    });
  });
}
