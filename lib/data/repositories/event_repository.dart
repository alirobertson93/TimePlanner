import 'package:drift/drift.dart';
import '../../domain/entities/event.dart' as domain;
import '../../domain/entities/category.dart' as domain;
import '../../domain/enums/event_status.dart';
import '../../domain/enums/timing_type.dart';
import '../database/app_database.dart';

/// Repository for managing events in the database
class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all events within a specified date range
  Future<List<domain.Event>> getEventsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final query = _db.select(_db.events)
      ..where((tbl) =>
          (tbl.fixedStartTime.isBiggerOrEqualValue(start) &
              tbl.fixedStartTime.isSmallerOrEqualValue(end)) |
          (tbl.fixedEndTime.isBiggerOrEqualValue(start) &
              tbl.fixedEndTime.isSmallerOrEqualValue(end)) |
          (tbl.fixedStartTime.isSmallerOrEqualValue(start) &
              tbl.fixedEndTime.isBiggerOrEqualValue(end)));

    final results = await query.get();
    return results.map<domain.Event>(_mapToEntity).toList();
  }

  /// Retrieves an event by its ID
  Future<domain.Event?> getById(String id) async {
    final query = _db.select(_db.events)..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Saves an event (insert or update)
  Future<void> save(domain.Event event) async {
    final companion = _mapToDbModel(event);
    await _db.into(_db.events).insertOnConflictUpdate(companion);
  }

  /// Deletes an event by its ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.events)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Retrieves all events
  Future<List<domain.Event>> getAll() async {
    final results = await _db.select(_db.events).get();
    return results.map<domain.Event>(_mapToEntity).toList();
  }

  /// Retrieves events by category
  Future<List<domain.Event>> getByCategory(String categoryId) async {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.categoryId.equals(categoryId));

    final results = await query.get();
    return results.map<domain.Event>(_mapToEntity).toList();
  }

  /// Retrieves events by status
  Future<List<domain.Event>> getByStatus(EventStatus status) async {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.status.equals(status.value));

    final results = await query.get();
    return results.map<domain.Event>(_mapToEntity).toList();
  }

  /// Maps a database event to a domain event entity
  domain.Event _mapToEntity(Event dbEvent) {
    return domain.Event(
      id: dbEvent.id,
      name: dbEvent.name,
      description: dbEvent.description,
      timingType: dbEvent.timingType,
      startTime: dbEvent.fixedStartTime,
      endTime: dbEvent.fixedEndTime,
      duration: dbEvent.durationMinutes != null
          ? Duration(minutes: dbEvent.durationMinutes!)
          : null,
      categoryId: dbEvent.categoryId,
      appCanMove: dbEvent.appCanMove,
      appCanResize: dbEvent.appCanResize,
      isUserLocked: dbEvent.isUserLocked,
      status: dbEvent.status,
      createdAt: dbEvent.createdAt,
      updatedAt: dbEvent.updatedAt,
    );
  }

  /// Maps a domain event entity to a database companion
  EventsCompanion _mapToDbModel(domain.Event event) {
    return EventsCompanion(
      id: Value(event.id),
      name: Value(event.name),
      description: Value(event.description),
      timingType: Value(event.timingType),
      fixedStartTime: Value(event.startTime),
      fixedEndTime: Value(event.endTime),
      durationMinutes: Value(event.duration?.inMinutes),
      categoryId: Value(event.categoryId),
      appCanMove: Value(event.appCanMove),
      appCanResize: Value(event.appCanResize),
      isUserLocked: Value(event.isUserLocked),
      status: Value(event.status),
      createdAt: Value(event.createdAt),
      updatedAt: Value(event.updatedAt),
    );
  }
}

/// Repository for managing categories in the database
class CategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all categories ordered by sort order
  Future<List<domain.Category>> getAll() async {
    final query = _db.select(_db.categories)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves a category by its ID
  Future<domain.Category?> getById(String id) async {
    final query = _db.select(_db.categories)
      ..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Saves a category (insert or update)
  Future<void> save(domain.Category category) async {
    final companion = _mapToDbModel(category);
    await _db.into(_db.categories).insertOnConflictUpdate(companion);
  }

  /// Deletes a category by its ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.categories)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Maps a database category to a domain category entity
  domain.Category _mapToEntity(Category dbCategory) {
    return domain.Category(
      id: dbCategory.id,
      name: dbCategory.name,
      colourHex: dbCategory.colourHex,
      sortOrder: dbCategory.sortOrder,
      isDefault: dbCategory.isDefault,
    );
  }

  /// Maps a domain category entity to a database companion
  CategoriesCompanion _mapToDbModel(domain.Category category) {
    return CategoriesCompanion(
      id: Value(category.id),
      name: Value(category.name),
      colourHex: Value(category.colourHex),
      sortOrder: Value(category.sortOrder),
      isDefault: Value(category.isDefault),
    );
  }
}
