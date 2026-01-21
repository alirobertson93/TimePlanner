import 'package:drift/drift.dart';
import '../../domain/entities/person.dart' as domain;
import '../database/app_database.dart';

/// Repository for managing event-person associations
class EventPeopleRepository {
  EventPeopleRepository(this._db);

  final AppDatabase _db;

  /// Gets all people associated with an event
  Future<List<domain.Person>> getPeopleForEvent(String eventId) async {
    final query = _db.select(_db.eventPeople).join([
      innerJoin(_db.people, _db.people.id.equalsExp(_db.eventPeople.personId)),
    ])
      ..where(_db.eventPeople.eventId.equals(eventId))
      ..orderBy([OrderingTerm.asc(_db.people.name)]);

    final results = await query.get();
    return results.map((row) {
      final personData = row.readTable(_db.people);
      return domain.Person(
        id: personData.id,
        name: personData.name,
        email: personData.email,
        phone: personData.phone,
        notes: personData.notes,
        createdAt: personData.createdAt,
      );
    }).toList();
  }

  /// Gets all event IDs that a person is associated with
  Future<List<String>> getEventIdsForPerson(String personId) async {
    final query = _db.select(_db.eventPeople)
      ..where((tbl) => tbl.personId.equals(personId));

    final results = await query.get();
    return results.map((row) => row.eventId).toList();
  }

  /// Associates a person with an event
  Future<void> addPersonToEvent({
    required String eventId,
    required String personId,
  }) async {
    await _db.into(_db.eventPeople).insertOnConflictUpdate(
          EventPeopleCompanion(
            eventId: Value(eventId),
            personId: Value(personId),
          ),
        );
  }

  /// Removes a person from an event
  Future<void> removePersonFromEvent({
    required String eventId,
    required String personId,
  }) async {
    await (_db.delete(_db.eventPeople)
          ..where((tbl) =>
              tbl.eventId.equals(eventId) & tbl.personId.equals(personId)))
        .go();
  }

  /// Sets the people for an event (replaces all existing associations)
  Future<void> setPeopleForEvent({
    required String eventId,
    required List<String> personIds,
  }) async {
    // Remove all existing associations
    await (_db.delete(_db.eventPeople)
          ..where((tbl) => tbl.eventId.equals(eventId)))
        .go();

    // Add new associations
    for (final personId in personIds) {
      await _db.into(_db.eventPeople).insert(
            EventPeopleCompanion(
              eventId: Value(eventId),
              personId: Value(personId),
            ),
          );
    }
  }

  /// Watches people associated with an event (reactive stream)
  Stream<List<domain.Person>> watchPeopleForEvent(String eventId) {
    final query = _db.select(_db.eventPeople).join([
      innerJoin(_db.people, _db.people.id.equalsExp(_db.eventPeople.personId)),
    ])
      ..where(_db.eventPeople.eventId.equals(eventId))
      ..orderBy([OrderingTerm.asc(_db.people.name)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final personData = row.readTable(_db.people);
        return domain.Person(
          id: personData.id,
          name: personData.name,
          email: personData.email,
          phone: personData.phone,
          notes: personData.notes,
          createdAt: personData.createdAt,
        );
      }).toList();
    });
  }
}
