import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:time_planner/data/database/app_database.dart';
import 'package:time_planner/data/repositories/event_repository.dart';
import 'package:time_planner/domain/entities/category.dart' as domain;

void main() {
  late AppDatabase db;
  late CategoryRepository repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('CategoryRepository - default categories', () {
    test('database is seeded with default categories on creation', () async {
      // Act
      final categories = await repository.getAll();

      // Assert
      expect(categories.length, equals(7));
      
      final categoryIds = categories.map((c) => c.id).toSet();
      expect(categoryIds, contains('cat_work'));
      expect(categoryIds, contains('cat_personal'));
      expect(categoryIds, contains('cat_family'));
      expect(categoryIds, contains('cat_health'));
      expect(categoryIds, contains('cat_creative'));
      expect(categoryIds, contains('cat_chores'));
      expect(categoryIds, contains('cat_social'));
    });

    test('default categories have correct properties', () async {
      // Act
      final workCategory = await repository.getById('cat_work');

      // Assert
      expect(workCategory, isNotNull);
      expect(workCategory!.name, equals('Work'));
      expect(workCategory.colourHex, equals('#4A90D9'));
      expect(workCategory.sortOrder, equals(0));
      expect(workCategory.isDefault, isTrue);
    });

    test('categories are returned in sort order', () async {
      // Act
      final categories = await repository.getAll();

      // Assert
      for (int i = 0; i < categories.length - 1; i++) {
        expect(
          categories[i].sortOrder,
          lessThanOrEqualTo(categories[i + 1].sortOrder),
        );
      }
    });
  });

  group('CategoryRepository - CRUD operations', () {
    test('saves and retrieves custom category', () async {
      // Arrange
      const category = domain.Category(
        id: 'cat_custom',
        name: 'Custom Category',
        colourHex: '#123456',
        sortOrder: 10,
        isDefault: false,
      );

      // Act
      await repository.save(category);
      final retrieved = await repository.getById('cat_custom');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(category.id));
      expect(retrieved.name, equals(category.name));
      expect(retrieved.colourHex, equals(category.colourHex));
      expect(retrieved.sortOrder, equals(category.sortOrder));
      expect(retrieved.isDefault, equals(category.isDefault));
    });

    test('updates existing category', () async {
      // Arrange
      const category = domain.Category(
        id: 'cat_test',
        name: 'Original Name',
        colourHex: '#111111',
        sortOrder: 5,
      );

      await repository.save(category);

      // Act
      final updated = category.copyWith(
        name: 'Updated Name',
        colourHex: '#222222',
      );
      await repository.save(updated);

      final retrieved = await repository.getById('cat_test');

      // Assert
      expect(retrieved, isNotNull);
      expect(retrieved!.name, equals('Updated Name'));
      expect(retrieved.colourHex, equals('#222222'));
      expect(retrieved.sortOrder, equals(5));
    });

    test('deletes category', () async {
      // Arrange
      const category = domain.Category(
        id: 'cat_to_delete',
        name: 'Delete Me',
        colourHex: '#FFFFFF',
      );

      await repository.save(category);
      expect(await repository.getById('cat_to_delete'), isNotNull);

      // Act
      await repository.delete('cat_to_delete');

      // Assert
      final result = await repository.getById('cat_to_delete');
      expect(result, isNull);
    });

    test('returns null for non-existent category', () async {
      // Act
      final result = await repository.getById('non_existent_id');

      // Assert
      expect(result, isNull);
    });
  });

  group('CategoryRepository - getAll', () {
    test('returns all categories including custom ones', () async {
      // Arrange
      const customCategory1 = domain.Category(
        id: 'cat_custom1',
        name: 'Custom 1',
        colourHex: '#AAAAAA',
        sortOrder: 100,
      );

      const customCategory2 = domain.Category(
        id: 'cat_custom2',
        name: 'Custom 2',
        colourHex: '#BBBBBB',
        sortOrder: 101,
      );

      await repository.save(customCategory1);
      await repository.save(customCategory2);

      // Act
      final categories = await repository.getAll();

      // Assert
      expect(categories.length, equals(9)); // 7 default + 2 custom
      
      final customCategories = categories.where((c) => !c.isDefault).toList();
      expect(customCategories.length, equals(2));
    });
  });
}
