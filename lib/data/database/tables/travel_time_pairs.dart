import 'package:drift/drift.dart';
import 'locations.dart';

/// Database table for storing travel times between location pairs
class TravelTimePairs extends Table {
  /// Reference to the starting location
  TextColumn get fromLocationId => text().references(Locations, #id)();

  /// Reference to the destination location
  TextColumn get toLocationId => text().references(Locations, #id)();

  /// Travel time in minutes
  IntColumn get travelTimeMinutes => integer()();

  /// Timestamp when this entry was last updated
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {fromLocationId, toLocationId};
}
