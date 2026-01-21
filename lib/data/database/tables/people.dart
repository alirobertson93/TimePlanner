import 'package:drift/drift.dart';

/// People table for tracking people associated with events
@DataClassName('PersonData')
class People extends Table {
  /// Primary key
  TextColumn get id => text()();

  /// Person's name
  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// Person's email address (optional)
  TextColumn get email => text().nullable()();

  /// Person's phone number (optional)
  TextColumn get phone => text().nullable()();

  /// Additional notes about the person (optional)
  TextColumn get notes => text().nullable()();

  /// When the person was created
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
