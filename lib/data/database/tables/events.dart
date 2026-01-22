import 'package:drift/drift.dart';
import '../../../domain/enums/event_status.dart';
import '../../../domain/enums/timing_type.dart';
import 'categories.dart';
import 'locations.dart';

/// Events table definition
class Events extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  IntColumn get timingType => intEnum<TimingType>()();
  DateTimeColumn get fixedStartTime => dateTime().nullable()();
  DateTimeColumn get fixedEndTime => dateTime().nullable()();
  IntColumn get durationMinutes => integer().nullable()();
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)();
  TextColumn get locationId =>
      text().nullable().references(Locations, #id)();
  BoolColumn get appCanMove => boolean().withDefault(const Constant(true))();
  BoolColumn get appCanResize =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isUserLocked =>
      boolean().withDefault(const Constant(false))();
  IntColumn get status =>
      intEnum<EventStatus>().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
