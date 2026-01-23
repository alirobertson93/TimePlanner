import 'package:drift/drift.dart';

import 'categories.dart';
import 'people.dart';

/// Goals table for tracking user-defined time allocation goals
@DataClassName('GoalData')
class Goals extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Goal title/name
  TextColumn get title => text()();

  /// Goal type (category, person, custom)
  IntColumn get type => integer()();

  /// Metric to track (hours, events, completions)
  IntColumn get metric => integer()();

  /// Target value for the goal
  IntColumn get targetValue => integer()();

  /// Time period for the goal (week, month, quarter, year)
  IntColumn get period => integer()();

  /// Related category ID (optional, for category-based goals)
  TextColumn get categoryId => text().nullable().references(Categories, #id)();

  /// Related person ID (optional, for relationship goals - tracking time with specific people)
  TextColumn get personId => text().nullable().references(People, #id)();

  /// Strategy for handling goal debt/shortfall
  IntColumn get debtStrategy => integer()();

  /// Whether the goal is currently active
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// When the goal was created
  DateTimeColumn get createdAt => dateTime()();

  /// When the goal was last updated
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
