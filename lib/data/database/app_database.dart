import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

import 'tables/categories.dart';
import 'tables/events.dart';
import 'tables/goals.dart';
import 'tables/people.dart';
import 'tables/event_people.dart';
import 'tables/locations.dart';
import 'tables/recurrence_rules.dart';
import 'tables/notifications.dart';
import 'tables/travel_time_pairs.dart';

// Import enums so the generated .g.dart file can access them
import '../../domain/enums/timing_type.dart';
import '../../domain/enums/event_status.dart';
import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/recurrence_end_type.dart';
import '../../domain/enums/notification_type.dart';
import '../../domain/enums/notification_status.dart';

part 'app_database.g.dart';

/// Main database class for the TimePlanner app
@DriftDatabase(tables: [
  Categories,
  Events,
  Goals,
  People,
  EventPeople,
  Locations,
  RecurrenceRules,
  Notifications,
  TravelTimePairs
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Constructor for testing with in-memory database
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaultCategories();
      },
      beforeOpen: (details) async {
        // Enable foreign key constraints (required for cascade deletes)
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Migration from version 1 to 2: Add Goals table
        if (from == 1) {
          await m.createTable(goals);
        }
        // Migration from version 2 to 3: Add People table
        if (from <= 2) {
          await m.createTable(people);
        }
        // Migration from version 3 to 4: Add EventPeople junction table
        if (from <= 3) {
          await m.createTable(eventPeople);
        }
        // Migration from version 4 to 5: Add Locations table
        if (from <= 4) {
          await m.createTable(locations);
        }
        // Migration from version 5 to 6: Add locationId column to Events table
        if (from <= 5) {
          await m.addColumn(events, events.locationId);
        }
        // Migration from version 6 to 7: Add RecurrenceRules table and recurrenceRuleId column to Events
        if (from <= 6) {
          await m.createTable(recurrenceRules);
          await m.addColumn(events, events.recurrenceRuleId);
        }
        // Migration from version 7 to 8: Add Notifications table
        if (from <= 7) {
          await m.createTable(notifications);
        }
        // Migration from version 8 to 9: Add personId column to Goals table for relationship goals
        if (from <= 8) {
          await m.addColumn(goals, goals.personId);
        }
        // Migration from version 9 to 10: Add TravelTimePairs table for manual travel time entry
        if (from <= 9) {
          await m.createTable(travelTimePairs);
        }
        // Migration from version 10 to 11: Add database indexes for performance
        if (from <= 10) {
          // Events indexes for common queries
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_events_start_time ON events (fixed_start_time)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_events_end_time ON events (fixed_end_time)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_events_category ON events (category_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_events_status ON events (status)');
          // Goals indexes
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_goals_category ON goals (category_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_goals_person ON goals (person_id)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_goals_active ON goals (is_active)');
          // Notifications indexes
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_notifications_scheduled ON notifications (scheduled_at)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_notifications_status ON notifications (status)');
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_notifications_event ON notifications (event_id)');
        }
        // Migration from version 11 to 12: Add location and event goal support
        if (from <= 11) {
          // Add locationId column to Goals table
          await m.addColumn(goals, goals.locationId);
          // Add eventTitle column to Goals table
          await m.addColumn(goals, goals.eventTitle);
          // Add index on locationId for location-based goals
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_goals_location ON goals (location_id)');
        }
        // Migration from version 12 to 13: Add scheduling constraints to Events table
        if (from <= 12) {
          await m.addColumn(events, events.schedulingConstraintsJson);
        }
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
