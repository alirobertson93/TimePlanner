import 'package:drift/drift.dart';
import '../../domain/entities/travel_time_pair.dart' as domain;
import '../database/app_database.dart';

/// Interface for travel time pair repository operations
abstract class ITravelTimePairRepository {
  Future<List<domain.TravelTimePair>> getAll();
  Future<domain.TravelTimePair?> getByLocationPair(String fromLocationId, String toLocationId);
  Future<domain.TravelTimePair?> getByLocationPairBidirectional(String locationId1, String locationId2);
  Future<void> save(domain.TravelTimePair travelTimePair);
  Future<void> saveBidirectional(domain.TravelTimePair travelTimePair);
  Future<void> delete(String fromLocationId, String toLocationId);
  Future<void> deleteBidirectional(String locationId1, String locationId2);
  Future<List<domain.TravelTimePair>> getForLocation(String locationId);
  Stream<List<domain.TravelTimePair>> watchAll();
}

/// Repository for managing travel time pairs in the database
class TravelTimePairRepository implements ITravelTimePairRepository {
  TravelTimePairRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all travel time pairs
  @override
  Future<List<domain.TravelTimePair>> getAll() async {
    final query = _db.select(_db.travelTimePairs);
    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves a travel time pair by its from/to location IDs (directional)
  @override
  Future<domain.TravelTimePair?> getByLocationPair(String fromLocationId, String toLocationId) async {
    final query = _db.select(_db.travelTimePairs)
      ..where((tbl) => tbl.fromLocationId.equals(fromLocationId) & tbl.toLocationId.equals(toLocationId));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Retrieves a travel time pair by location IDs (checks both directions)
  @override
  Future<domain.TravelTimePair?> getByLocationPairBidirectional(String locationId1, String locationId2) async {
    // First try locationId1 -> locationId2
    var result = await getByLocationPair(locationId1, locationId2);
    if (result != null) return result;
    
    // Then try locationId2 -> locationId1
    return getByLocationPair(locationId2, locationId1);
  }

  /// Saves a travel time pair (insert or update) - directional
  @override
  Future<void> save(domain.TravelTimePair travelTimePair) async {
    final companion = _mapToDbModel(travelTimePair);
    await _db.into(_db.travelTimePairs).insertOnConflictUpdate(companion);
  }

  /// Saves a travel time pair bidirectionally (stores both A→B and B→A with same time)
  @override
  Future<void> saveBidirectional(domain.TravelTimePair travelTimePair) async {
    await save(travelTimePair);
    
    // Also save the reverse direction
    final reversePair = domain.TravelTimePair(
      fromLocationId: travelTimePair.toLocationId,
      toLocationId: travelTimePair.fromLocationId,
      travelTimeMinutes: travelTimePair.travelTimeMinutes,
      updatedAt: travelTimePair.updatedAt,
    );
    await save(reversePair);
  }

  /// Deletes a travel time pair by its from/to location IDs (directional)
  @override
  Future<void> delete(String fromLocationId, String toLocationId) async {
    await (_db.delete(_db.travelTimePairs)
      ..where((tbl) => tbl.fromLocationId.equals(fromLocationId) & tbl.toLocationId.equals(toLocationId)))
      .go();
  }

  /// Deletes travel time pairs in both directions
  @override
  Future<void> deleteBidirectional(String locationId1, String locationId2) async {
    await delete(locationId1, locationId2);
    await delete(locationId2, locationId1);
  }

  /// Retrieves all travel time pairs that involve a specific location
  @override
  Future<List<domain.TravelTimePair>> getForLocation(String locationId) async {
    final query = _db.select(_db.travelTimePairs)
      ..where((tbl) => tbl.fromLocationId.equals(locationId) | tbl.toLocationId.equals(locationId));

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Watches all travel time pairs (reactive stream)
  @override
  Stream<List<domain.TravelTimePair>> watchAll() {
    return _db.select(_db.travelTimePairs).watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  /// Maps a database travel time pair to a domain entity
  domain.TravelTimePair _mapToEntity(TravelTimePair dbTravelTimePair) {
    return domain.TravelTimePair(
      fromLocationId: dbTravelTimePair.fromLocationId,
      toLocationId: dbTravelTimePair.toLocationId,
      travelTimeMinutes: dbTravelTimePair.travelTimeMinutes,
      updatedAt: dbTravelTimePair.updatedAt,
    );
  }

  /// Maps a domain entity to a database companion
  TravelTimePairsCompanion _mapToDbModel(domain.TravelTimePair travelTimePair) {
    return TravelTimePairsCompanion(
      fromLocationId: Value(travelTimePair.fromLocationId),
      toLocationId: Value(travelTimePair.toLocationId),
      travelTimeMinutes: Value(travelTimePair.travelTimeMinutes),
      updatedAt: Value(travelTimePair.updatedAt),
    );
  }
}
