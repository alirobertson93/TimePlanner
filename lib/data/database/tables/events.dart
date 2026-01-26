import 'package:drift/drift.dart';
import '../../../domain/enums/event_status.dart';
import '../../../domain/enums/timing_type.dart';
import 'categories.dart';
import 'locations.dart';
import 'recurrence_rules.dart';

/// Events table definition (will be renamed to Activities in future)
@TableIndex(name: 'idx_events_start_time', columns: {#fixedStartTime})
@TableIndex(name: 'idx_events_end_time', columns: {#fixedEndTime})
@TableIndex(name: 'idx_events_category', columns: {#categoryId})
@TableIndex(name: 'idx_events_status', columns: {#status})
@TableIndex(name: 'idx_events_series', columns: {#seriesId})
class Events extends Table {
  TextColumn get id => text()();
  /// The name/title of the activity. Can be null if the activity has
  /// associated people, locations, or categories.
  TextColumn get name => text().nullable().withLength(min: 0, max: 200)();
  TextColumn get description => text().nullable()();
  IntColumn get timingType => intEnum<TimingType>()();
  DateTimeColumn get fixedStartTime => dateTime().nullable()();
  DateTimeColumn get fixedEndTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get categoryId => text().nullable().references(Categories, #id)();
  TextColumn get locationId => text().nullable().references(Locations, #id)();

  /// Reference to the recurrence rule for repeating events
  TextColumn get recurrenceRuleId =>
      text().nullable().references(RecurrenceRules, #id)();
  
  /// Groups related activities together (independent of recurrence)
  TextColumn get seriesId => text().nullable()();
  
  /// JSON-encoded scheduling constraints (time restrictions, day preferences)
  TextColumn get schedulingConstraintsJson => text().nullable()();
  
  BoolColumn get appCanMove => boolean().withDefault(const Constant(true))();
  BoolColumn get appCanResize => boolean().withDefault(const Constant(true))();
  BoolColumn get isUserLocked => boolean().withDefault(const Constant(false))();
  IntColumn get status =>
      intEnum<EventStatus>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
