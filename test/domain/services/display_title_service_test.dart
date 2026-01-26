import 'package:test/test.dart';
import 'package:time_planner/domain/entities/activity.dart';
import 'package:time_planner/domain/entities/category.dart';
import 'package:time_planner/domain/entities/location.dart';
import 'package:time_planner/domain/entities/person.dart';
import 'package:time_planner/domain/enums/timing_type.dart';
import 'package:time_planner/domain/enums/activity_status.dart';
import 'package:time_planner/domain/services/display_title_service.dart';

void main() {
  group('DisplayTitleService', () {
    late DisplayTitleService service;
    final now = DateTime.now();

    setUp(() {
      service = const DisplayTitleService();
    });

    Activity createTestActivity({
      String? name,
      String? categoryId,
      String? locationId,
    }) {
      return Activity(
        id: 'activity-1',
        name: name,
        timingType: TimingType.flexible,
        startTime: now,
        endTime: now.add(const Duration(hours: 1)),
        categoryId: categoryId,
        locationId: locationId,
        status: ActivityStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }

    Person createTestPerson(String id, String name) {
      return Person(
        id: id,
        name: name,
        createdAt: now,
      );
    }

    Location createTestLocation(String id, String name) {
      return Location(
        id: id,
        name: name,
        createdAt: now,
      );
    }

    Category createTestCategory(String id, String name) {
      return Category(
        id: id,
        name: name,
        colourHex: '#000000',
      );
    }

    group('getDisplayTitle', () {
      test('returns activity name when present', () {
        final activity = createTestActivity(name: 'Meeting');
        
        final result = service.getDisplayTitle(activity);
        
        expect(result, equals('Meeting'));
      });

      test('ignores other entities when name is present', () {
        final activity = createTestActivity(
          name: 'Meeting',
          categoryId: 'cat-1',
          locationId: 'loc-1',
        );
        final person = createTestPerson('p-1', 'John');
        final location = createTestLocation('loc-1', 'Office');
        final category = createTestCategory('cat-1', 'Work');

        final result = service.getDisplayTitle(
          activity,
          people: [person],
          location: location,
          category: category,
        );

        expect(result, equals('Meeting'));
      });

      test('returns person name when no title', () {
        final activity = createTestActivity(name: null);
        final person = createTestPerson('p-1', 'John');

        final result = service.getDisplayTitle(activity, people: [person]);

        expect(result, equals('John'));
      });

      test('returns multiple person names joined by comma', () {
        final activity = createTestActivity(name: null);
        final people = [
          createTestPerson('p-1', 'John'),
          createTestPerson('p-2', 'Jane'),
        ];

        final result = service.getDisplayTitle(activity, people: people);

        expect(result, equals('John, Jane'));
      });

      test('returns location name when no title or person', () {
        final activity = createTestActivity(name: null, locationId: 'loc-1');
        final location = createTestLocation('loc-1', 'Office');

        final result = service.getDisplayTitle(activity, location: location);

        expect(result, equals('Office'));
      });

      test('returns category name when no title, person, or location', () {
        final activity = createTestActivity(name: null, categoryId: 'cat-1');
        final category = createTestCategory('cat-1', 'Work');

        final result = service.getDisplayTitle(activity, category: category);

        expect(result, equals('Work'));
      });

      test('concatenates person and location with separator', () {
        final activity = createTestActivity(name: null, locationId: 'loc-1');
        final person = createTestPerson('p-1', 'John');
        final location = createTestLocation('loc-1', 'Office');

        final result = service.getDisplayTitle(
          activity,
          people: [person],
          location: location,
        );

        expect(result, equals('John · Office'));
      });

      test('concatenates all properties with separator', () {
        final activity = createTestActivity(
          name: null,
          locationId: 'loc-1',
          categoryId: 'cat-1',
        );
        final people = [createTestPerson('p-1', 'John')];
        final location = createTestLocation('loc-1', 'Office');
        final category = createTestCategory('cat-1', 'Work');

        final result = service.getDisplayTitle(
          activity,
          people: people,
          location: location,
          category: category,
        );

        expect(result, equals('John · Office · Work'));
      });

      test('returns "Untitled Activity" when no properties', () {
        final activity = createTestActivity(name: null);

        final result = service.getDisplayTitle(activity);

        expect(result, equals('Untitled Activity'));
      });

      test('returns "Untitled Activity" with empty people list', () {
        final activity = createTestActivity(name: null);

        final result = service.getDisplayTitle(activity, people: []);

        expect(result, equals('Untitled Activity'));
      });

      test('ignores empty name string', () {
        final activity = createTestActivity(name: '');
        final category = createTestCategory('cat-1', 'Work');

        final result = service.getDisplayTitle(activity, category: category);

        expect(result, equals('Work'));
      });
    });

    group('getShortDisplayTitle', () {
      test('returns activity name when present', () {
        final activity = createTestActivity(name: 'Meeting');

        final result = service.getShortDisplayTitle(activity);

        expect(result, equals('Meeting'));
      });

      test('truncates long names with ellipsis', () {
        final activity = createTestActivity(
          name: 'This is a very long activity name that exceeds the limit',
        );

        final result = service.getShortDisplayTitle(activity, maxLength: 20);

        expect(result, equals('This is a very long…'));
        expect(result.length, equals(20));
      });

      test('returns first person name only', () {
        final activity = createTestActivity(name: null);
        final people = [
          createTestPerson('p-1', 'John Smith'),
          createTestPerson('p-2', 'Jane Doe'),
        ];

        final result = service.getShortDisplayTitle(activity, people: people);

        expect(result, equals('John Smith'));
      });

      test('returns location name when no title or person', () {
        final activity = createTestActivity(name: null, locationId: 'loc-1');
        final location = createTestLocation('loc-1', 'Office Building');

        final result = service.getShortDisplayTitle(activity, location: location);

        expect(result, equals('Office Building'));
      });

      test('returns category name when no title, person, or location', () {
        final activity = createTestActivity(name: null, categoryId: 'cat-1');
        final category = createTestCategory('cat-1', 'Work');

        final result = service.getShortDisplayTitle(activity, category: category);

        expect(result, equals('Work'));
      });

      test('returns "Untitled" when no properties', () {
        final activity = createTestActivity(name: null);

        final result = service.getShortDisplayTitle(activity);

        expect(result, equals('Untitled'));
      });

      test('respects custom maxLength', () {
        final activity = createTestActivity(name: 'Short');

        final result = service.getShortDisplayTitle(activity, maxLength: 10);

        expect(result, equals('Short'));
        expect(result.length, lessThanOrEqualTo(10));
      });
    });
  });
}
