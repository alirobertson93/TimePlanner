import 'package:drift/drift.dart';
import 'events.dart';
import 'people.dart';

/// Junction table for many-to-many relationship between Events and People
@DataClassName('EventPersonData')
class EventPeople extends Table {
  /// Reference to the event
  TextColumn get eventId =>
      text().references(Events, #id, onDelete: KeyAction.cascade)();

  /// Reference to the person
  TextColumn get personId =>
      text().references(People, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column> get primaryKey => {eventId, personId};
}
