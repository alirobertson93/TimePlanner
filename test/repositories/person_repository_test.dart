import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/person_repository.dart';
import 'package:time_planner/domain/entities/person.dart';

void main() {
  late AppDatabase database;
  late PersonRepository repository;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PersonRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('PersonRepository', () {
    test('save and getById returns the saved person', () async {
      // Arrange
      final person = Person(
        id: 'person_1',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '555-1234',
        notes: 'Work colleague',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(person);
      final retrieved = await repository.getById('person_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('person_1'));
      expect(retrieved.name, equals('John Doe'));
      expect(retrieved.email, equals('john@example.com'));
      expect(retrieved.phone, equals('555-1234'));
      expect(retrieved.notes, equals('Work colleague'));
    });

    test('save updates existing person', () async {
      // Arrange
      final person = Person(
        id: 'person_1',
        name: 'John Doe',
        email: 'john@example.com',
        createdAt: DateTime.now(),
      );

      await repository.save(person);

      // Act
      final updated = person.copyWith(
        name: 'John Smith',
        email: 'john.smith@example.com',
      );
      await repository.save(updated);
      final retrieved = await repository.getById('person_1');

      // Assert
      expect(retrieved!.name, equals('John Smith'));
      expect(retrieved.email, equals('john.smith@example.com'));
    });

    test('delete removes person from database', () async {
      // Arrange
      final person = Person(
        id: 'person_1',
        name: 'Test Person',
        createdAt: DateTime.now(),
      );

      await repository.save(person);

      // Act
      await repository.delete('person_1');
      final retrieved = await repository.getById('person_1');

      // Assert
      expect(retrieved, isNull);
    });

    test('getById returns null for non-existent person', () async {
      // Act
      final retrieved = await repository.getById('non_existent');

      // Assert
      expect(retrieved, isNull);
    });

    test('getAll returns all people ordered by name', () async {
      // Arrange
      final person1 = Person(
        id: 'person_1',
        name: 'Charlie',
        createdAt: DateTime.now(),
      );

      final person2 = Person(
        id: 'person_2',
        name: 'Alice',
        createdAt: DateTime.now(),
      );

      final person3 = Person(
        id: 'person_3',
        name: 'Bob',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(person1);
      await repository.save(person2);
      await repository.save(person3);
      final people = await repository.getAll();

      // Assert
      expect(people.length, equals(3));
      expect(people[0].name, equals('Alice'));
      expect(people[1].name, equals('Bob'));
      expect(people[2].name, equals('Charlie'));
    });

    test('searchByName finds people with matching names', () async {
      // Arrange
      final person1 = Person(
        id: 'person_1',
        name: 'John Doe',
        createdAt: DateTime.now(),
      );

      final person2 = Person(
        id: 'person_2',
        name: 'Jane Doe',
        createdAt: DateTime.now(),
      );

      final person3 = Person(
        id: 'person_3',
        name: 'Bob Smith',
        createdAt: DateTime.now(),
      );

      await repository.save(person1);
      await repository.save(person2);
      await repository.save(person3);

      // Act
      final doeResults = await repository.searchByName('doe');

      // Assert
      expect(doeResults.length, equals(2));
      expect(doeResults.any((p) => p.name == 'John Doe'), isTrue);
      expect(doeResults.any((p) => p.name == 'Jane Doe'), isTrue);
    });

    test('searchByName is case-insensitive', () async {
      // Arrange
      final person = Person(
        id: 'person_1',
        name: 'John Doe',
        createdAt: DateTime.now(),
      );

      await repository.save(person);

      // Act
      final upperResults = await repository.searchByName('JOHN');
      final lowerResults = await repository.searchByName('john');
      final mixedResults = await repository.searchByName('JoHn');

      // Assert
      expect(upperResults.length, equals(1));
      expect(lowerResults.length, equals(1));
      expect(mixedResults.length, equals(1));
    });

    test('save person with optional fields as null', () async {
      // Arrange
      final person = Person(
        id: 'person_1',
        name: 'Minimal Person',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(person);
      final retrieved = await repository.getById('person_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Minimal Person'));
      expect(retrieved.email, isNull);
      expect(retrieved.phone, isNull);
      expect(retrieved.notes, isNull);
    });

    test('watchAll emits updates when people change', () async {
      // Arrange
      final person = Person(
        id: 'person_1',
        name: 'Test Person',
        createdAt: DateTime.now(),
      );

      // Act
      final stream = repository.watchAll();
      final emittedValues = <List<Person>>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await repository.save(person);
      await Future.delayed(const Duration(milliseconds: 100));
      await repository.delete('person_1');
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
