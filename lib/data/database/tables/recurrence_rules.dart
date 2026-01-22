import 'package:drift/drift.dart';
import '../../../domain/enums/recurrence_frequency.dart';
import '../../../domain/enums/recurrence_end_type.dart';

/// RecurrenceRules table definition
/// Stores recurring event patterns (daily, weekly, monthly, yearly)
class RecurrenceRules extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Recurrence pattern (daily, weekly, monthly, yearly)
  IntColumn get frequency => intEnum<RecurrenceFrequency>()();

  /// Interval between occurrences (e.g., 2 for "every 2 weeks")
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// Days of the week for weekly recurrence - JSON array [0-6] (0 = Sunday)
  TextColumn get byWeekDay => text().nullable()();

  /// Days of the month for monthly recurrence - JSON array [1-31]
  TextColumn get byMonthDay => text().nullable()();

  /// End condition type
  IntColumn get endType => intEnum<RecurrenceEndType>()();

  /// End date (when endType is onDate)
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Number of occurrences (when endType is afterOccurrences)
  IntColumn get occurrences => integer().nullable()();

  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
