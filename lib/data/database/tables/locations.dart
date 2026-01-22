import 'package:drift/drift.dart';

/// Database table for storing locations
class Locations extends Table {
  /// Unique identifier for the location (UUID)
  TextColumn get id => text()();

  /// Display name for the location
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Full address of the location (optional)
  TextColumn get address => text().nullable()();

  /// Geographic latitude (optional)
  RealColumn get latitude => real().nullable()();

  /// Geographic longitude (optional)
  RealColumn get longitude => real().nullable()();

  /// Additional notes about the location (optional)
  TextColumn get notes => text().nullable()();

  /// Timestamp when the location was created
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
