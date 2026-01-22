import 'package:drift/drift.dart';
import '../../domain/entities/location.dart' as domain;
import '../database/app_database.dart';

/// Interface for location repository operations
abstract class ILocationRepository {
  Future<List<domain.Location>> getAll();
  Future<domain.Location?> getById(String id);
  Future<void> save(domain.Location location);
  Future<void> delete(String id);
  Future<List<domain.Location>> searchByName(String nameQuery);
  Stream<List<domain.Location>> watchAll();
}

/// Repository for managing locations in the database
class LocationRepository implements ILocationRepository {
  LocationRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all locations ordered by name
  Future<List<domain.Location>> getAll() async {
    final query = _db.select(_db.locations)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves a location by its ID
  Future<domain.Location?> getById(String id) async {
    final query = _db.select(_db.locations)..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Saves a location (insert or update)
  Future<void> save(domain.Location location) async {
    final companion = _mapToDbModel(location);
    await _db.into(_db.locations).insertOnConflictUpdate(companion);
  }

  /// Deletes a location by its ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.locations)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Searches for locations by name (case-insensitive)
  Future<List<domain.Location>> searchByName(String nameQuery) async {
    final query = _db.select(_db.locations)
      ..where((tbl) => tbl.name.lower().contains(nameQuery.toLowerCase()))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Watches all locations (reactive stream)
  Stream<List<domain.Location>> watchAll() {
    final query = _db.select(_db.locations)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.name)]);

    return query.watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  /// Maps a database location to a domain location entity
  domain.Location _mapToEntity(Location dbLocation) {
    return domain.Location(
      id: dbLocation.id,
      name: dbLocation.name,
      address: dbLocation.address,
      latitude: dbLocation.latitude,
      longitude: dbLocation.longitude,
      notes: dbLocation.notes,
      createdAt: dbLocation.createdAt,
    );
  }

  /// Maps a domain location entity to a database companion
  LocationsCompanion _mapToDbModel(domain.Location location) {
    return LocationsCompanion(
      id: Value(location.id),
      name: Value(location.name),
      address: Value(location.address),
      latitude: Value(location.latitude),
      longitude: Value(location.longitude),
      notes: Value(location.notes),
      createdAt: Value(location.createdAt),
    );
  }
}
