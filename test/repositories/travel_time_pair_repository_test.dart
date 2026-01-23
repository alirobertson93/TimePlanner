import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/travel_time_pair_repository.dart';
import 'package:time_planner/data/repositories/location_repository.dart';
import 'package:time_planner/domain/entities/travel_time_pair.dart' as domain;
import 'package:time_planner/domain/entities/location.dart' as location_domain;

void main() {
  late AppDatabase database;
  late TravelTimePairRepository repository;
  late LocationRepository locationRepository;

  setUp(() async {
    // Create in-memory database for testing
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TravelTimePairRepository(database);
    locationRepository = LocationRepository(database);

    // Create test locations
    await locationRepository.save(location_domain.Location(
      id: 'location_1',
      name: 'Home',
      createdAt: DateTime.now(),
    ));
    await locationRepository.save(location_domain.Location(
      id: 'location_2',
      name: 'Office',
      createdAt: DateTime.now(),
    ));
    await locationRepository.save(location_domain.Location(
      id: 'location_3',
      name: 'Coffee Shop',
      createdAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await database.close();
  });

  group('TravelTimePairRepository', () {
    test('save and getByLocationPair returns the saved travel time', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(travelTime);
      final retrieved = await repository.getByLocationPair('location_1', 'location_2');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.fromLocationId, equals('location_1'));
      expect(retrieved.toLocationId, equals('location_2'));
      expect(retrieved.travelTimeMinutes, equals(30));
    });

    test('save updates existing travel time', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      await repository.save(travelTime);

      // Act
      final updated = travelTime.copyWith(
        travelTimeMinutes: 45,
        updatedAt: DateTime.now(),
      );
      await repository.save(updated);
      final retrieved = await repository.getByLocationPair('location_1', 'location_2');

      // Assert
      expect(retrieved!.travelTimeMinutes, equals(45));
    });

    test('saveBidirectional saves both directions', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.saveBidirectional(travelTime);
      final forward = await repository.getByLocationPair('location_1', 'location_2');
      final reverse = await repository.getByLocationPair('location_2', 'location_1');

      // Assert
      expect(forward, isNotNull);
      expect(reverse, isNotNull);
      expect(forward!.travelTimeMinutes, equals(30));
      expect(reverse!.travelTimeMinutes, equals(30));
    });

    test('delete removes travel time from database', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      await repository.save(travelTime);

      // Act
      await repository.delete('location_1', 'location_2');
      final retrieved = await repository.getByLocationPair('location_1', 'location_2');

      // Assert
      expect(retrieved, isNull);
    });

    test('deleteBidirectional removes both directions', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      await repository.saveBidirectional(travelTime);

      // Act
      await repository.deleteBidirectional('location_1', 'location_2');
      final forward = await repository.getByLocationPair('location_1', 'location_2');
      final reverse = await repository.getByLocationPair('location_2', 'location_1');

      // Assert
      expect(forward, isNull);
      expect(reverse, isNull);
    });

    test('getByLocationPair returns null for non-existent pair', () async {
      // Act
      final retrieved = await repository.getByLocationPair('location_1', 'location_2');

      // Assert
      expect(retrieved, isNull);
    });

    test('getByLocationPairBidirectional finds pair in either direction', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      await repository.save(travelTime); // Only save in one direction

      // Act
      final found1 = await repository.getByLocationPairBidirectional('location_1', 'location_2');
      final found2 = await repository.getByLocationPairBidirectional('location_2', 'location_1');

      // Assert
      expect(found1, isNotNull);
      expect(found2, isNotNull); // Should also find it even though we only saved one direction
      expect(found1!.travelTimeMinutes, equals(30));
    });

    test('getAll returns all travel time pairs', () async {
      // Arrange
      final travelTime1 = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      final travelTime2 = domain.TravelTimePair(
        fromLocationId: 'location_2',
        toLocationId: 'location_3',
        travelTimeMinutes: 15,
        updatedAt: DateTime.now(),
      );

      // Act
      await repository.save(travelTime1);
      await repository.save(travelTime2);
      final allPairs = await repository.getAll();

      // Assert
      expect(allPairs.length, equals(2));
    });

    test('getForLocation returns all pairs involving a location', () async {
      // Arrange
      final travelTime1 = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      final travelTime2 = domain.TravelTimePair(
        fromLocationId: 'location_3',
        toLocationId: 'location_1',
        travelTimeMinutes: 20,
        updatedAt: DateTime.now(),
      );

      final travelTime3 = domain.TravelTimePair(
        fromLocationId: 'location_2',
        toLocationId: 'location_3',
        travelTimeMinutes: 15,
        updatedAt: DateTime.now(),
      );

      await repository.save(travelTime1);
      await repository.save(travelTime2);
      await repository.save(travelTime3);

      // Act
      final location1Pairs = await repository.getForLocation('location_1');
      final location3Pairs = await repository.getForLocation('location_3');

      // Assert
      expect(location1Pairs.length, equals(2)); // travelTime1 (from) and travelTime2 (to)
      expect(location3Pairs.length, equals(2)); // travelTime2 (from) and travelTime3 (to)
    });

    test('watchAll emits updates when travel times change', () async {
      // Arrange
      final travelTime = domain.TravelTimePair(
        fromLocationId: 'location_1',
        toLocationId: 'location_2',
        travelTimeMinutes: 30,
        updatedAt: DateTime.now(),
      );

      // Act
      final stream = repository.watchAll();
      final emittedValues = <List<domain.TravelTimePair>>[];

      final subscription = stream.listen(emittedValues.add);

      await Future.delayed(const Duration(milliseconds: 100));
      await repository.save(travelTime);
      await Future.delayed(const Duration(milliseconds: 100));
      await repository.delete('location_1', 'location_2');
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
