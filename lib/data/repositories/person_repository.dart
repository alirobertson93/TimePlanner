import 'package:drift/drift.dart';
import '../../domain/entities/person.dart' as domain;
import '../database/app_database.dart';

/// Interface for person repository operations
abstract class IPersonRepository {
  Future<List<domain.Person>> getAll();
  Future<domain.Person?> getById(String id);
  Future<void> save(domain.Person person);
  Future<void> delete(String id);
  Future<List<domain.Person>> searchByName(String nameQuery);
  Stream<List<domain.Person>> watchAll();
}

/// Repository for managing people in the database
class PersonRepository implements IPersonRepository {
  PersonRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all people ordered by name
  Future<List<domain.Person>> getAll() async {
    final query = _db.select(_db.people)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves a person by their ID
  Future<domain.Person?> getById(String id) async {
    final query = _db.select(_db.people)..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Saves a person (insert or update)
  Future<void> save(domain.Person person) async {
    final companion = _mapToDbModel(person);
    await _db.into(_db.people).insertOnConflictUpdate(companion);
  }

  /// Deletes a person by their ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.people)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Searches for people by name (case-insensitive)
  Future<List<domain.Person>> searchByName(String nameQuery) async {
    final query = _db.select(_db.people)
      ..where((tbl) => tbl.name.lower().contains(nameQuery.toLowerCase()))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Watches all people (reactive stream)
  Stream<List<domain.Person>> watchAll() {
    final query = _db.select(_db.people)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    return query.watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  /// Maps a database person to a domain person entity
  domain.Person _mapToEntity(PersonData dbPerson) {
    return domain.Person(
      id: dbPerson.id,
      name: dbPerson.name,
      email: dbPerson.email,
      phone: dbPerson.phone,
      notes: dbPerson.notes,
      createdAt: dbPerson.createdAt,
    );
  }

  /// Maps a domain person entity to a database companion
  PeopleCompanion _mapToDbModel(domain.Person person) {
    return PeopleCompanion(
      id: Value(person.id),
      name: Value(person.name),
      email: Value(person.email),
      phone: Value(person.phone),
      notes: Value(person.notes),
      createdAt: Value(person.createdAt),
    );
  }
}
