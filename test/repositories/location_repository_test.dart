import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/location_repository.dart';
import 'package:time_planner/domain/entities/location.dart';

void main() {
  late AppDatabase database;
  late LocationRepository repository;

  setUp(() {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = LocationRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('LocationRepository', () {
    test('save and getById returns the saved location', () async {
      // Arrange
      final location = Location(
        id: 'location_1',
        name: 'Office',
        address: '123 Main St, City',
        latitude: 40.7128,
        longitude: -74.0060,
        notes: 'Main office building',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(location);
      final retrieved = await repository.getById('location_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals('location_1'));
      expect(retrieved.name, equals('Office'));
      expect(retrieved.address, equals('123 Main St, City'));
      expect(retrieved.latitude, closeTo(40.7128, 0.0001));
      expect(retrieved.longitude, closeTo(-74.0060, 0.0001));
      expect(retrieved.notes, equals('Main office building'));
    });

    test('save updates existing location', () async {
      // Arrange
      final location = Location(
        id: 'location_1',
        name: 'Office',
        address: '123 Main St',
        createdAt: DateTime.now(),
      );

      await repository.save(location);

      // Act
      final updated = location.copyWith(
        name: 'New Office',
        address: '456 Oak Ave',
      );
      await repository.save(updated);
      final retrieved = await repository.getById('location_1');

      // Assert
      expect(retrieved!.name, equals('New Office'));
      expect(retrieved.address, equals('456 Oak Ave'));
    });

    test('delete removes location from database', () async {
      // Arrange
      final location = Location(
        id: 'location_1',
        name: 'Test Location',
        createdAt: DateTime.now(),
      );

      await repository.save(location);

      // Act
      await repository.delete('location_1');
      final retrieved = await repository.getById('location_1');

      // Assert
      expect(retrieved, isNull);
    });

    test('getById returns null for non-existent location', () async {
      // Act
      final retrieved = await repository.getById('non_existent');

      // Assert
      expect(retrieved, isNull);
    });

    test('getAll returns all locations ordered by name', () async {
      // Arrange
      final location1 = Location(
        id: 'location_1',
        name: 'Coffee Shop',
        createdAt: DateTime.now(),
      );

      final location2 = Location(
        id: 'location_2',
        name: 'Airport',
        createdAt: DateTime.now(),
      );

      final location3 = Location(
        id: 'location_3',
        name: 'Beach',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(location1);
      await repository.save(location2);
      await repository.save(location3);
      final locations = await repository.getAll();

      // Assert
      expect(locations.length, equals(3));
      expect(locations[0].name, equals('Airport'));
      expect(locations[1].name, equals('Beach'));
      expect(locations[2].name, equals('Coffee Shop'));
    });

    test('searchByName finds locations with matching names', () async {
      // Arrange
      final location1 = Location(
        id: 'location_1',
        name: 'Home Office',
        createdAt: DateTime.now(),
      );

      final location2 = Location(
        id: 'location_2',
        name: 'Work Office',
        createdAt: DateTime.now(),
      );

      final location3 = Location(
        id: 'location_3',
        name: 'Coffee Shop',
        createdAt: DateTime.now(),
      );

      await repository.save(location1);
      await repository.save(location2);
      await repository.save(location3);

      // Act
      final officeResults = await repository.searchByName('office');

      // Assert
      expect(officeResults.length, equals(2));
      expect(officeResults.any((l) => l.name == 'Home Office'), isTrue);
      expect(officeResults.any((l) => l.name == 'Work Office'), isTrue);
    });

    test('searchByName is case-insensitive', () async {
      // Arrange
      final location = Location(
        id: 'location_1',
        name: 'Coffee Shop',
        createdAt: DateTime.now(),
      );

      await repository.save(location);

      // Act
      final upperResults = await repository.searchByName('COFFEE');
      final lowerResults = await repository.searchByName('coffee');
      final mixedResults = await repository.searchByName('CoFfEe');

      // Assert
      expect(upperResults.length, equals(1));
      expect(lowerResults.length, equals(1));
      expect(mixedResults.length, equals(1));
    });

    test('save location with optional fields as null', () async {
      // Arrange
      final location = Location(
        id: 'location_1',
        name: 'Minimal Location',
        createdAt: DateTime.now(),
      );

      // Act
      await repository.save(location);
      final retrieved = await repository.getById('location_1');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Minimal Location'));
      expect(retrieved.address, isNull);
      expect(retrieved.latitude, isNull);
      expect(retrieved.longitude, isNull);
      expect(retrieved.notes, isNull);
    });

    test('watchAll emits updates when locations change', () async {
      // Arrange
      final location = Location(
        id: 'location_1',
        name: 'Test Location',
        createdAt: DateTime.now(),
      );

      // Act
      final stream = repository.watchAll();
      final emittedValues = <List<Location>>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await repository.save(location);
      await Future.delayed(const Duration(milliseconds: 100));
      await repository.delete('location_1');
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
