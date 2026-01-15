import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables/categories.dart';
import 'tables/events.dart';

part 'app_database.g.dart';

/// Main database class for the TimePlanner app
@DriftDatabase(tables: [Categories, Events])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with in-memory database
  AppDatabase.forTesting(QueryExecutor executor) : super(executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaultCategories();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations will go here
      },
    );
  }

  /// Seeds the database with default categories
  Future<void> _seedDefaultCategories() async {
    final defaultCategories = [
      CategoriesCompanion.insert(
        id: 'cat_work',
        name: 'Work',
        colourHex: '#4A90D9',
        sortOrder: const Value(0),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat_personal',
        name: 'Personal',
        colourHex: '#50C878',
        sortOrder: const Value(1),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat_family',
        name: 'Family',
        colourHex: '#FFB347',
        sortOrder: const Value(2),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat_health',
        name: 'Health',
        colourHex: '#FF6B6B',
        sortOrder: const Value(3),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat_creative',
        name: 'Creative',
        colourHex: '#9B59B6',
        sortOrder: const Value(4),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat_chores',
        name: 'Chores',
        colourHex: '#95A5A6',
        sortOrder: const Value(5),
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        id: 'cat_social',
        name: 'Social',
        colourHex: '#F39C12',
        sortOrder: const Value(6),
        isDefault: const Value(true),
      ),
    ];

    for (final category in defaultCategories) {
      await into(categories).insert(category);
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'time_planner.db'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }

    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}
