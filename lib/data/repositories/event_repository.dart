import 'dart:convert';
import 'package:drift/drift.dart';
import '../../domain/entities/event.dart' as domain;
import '../../domain/entities/scheduling_constraint.dart';
import '../../domain/enums/event_status.dart';
import '../../domain/enums/timing_type.dart';
import '../database/app_database.dart';

// CategoryRepository has been moved to category_repository.dart
// Re-export for backward compatibility
export 'category_repository.dart';

/// Interface for event repository operations
abstract class IEventRepository {
  Future<List<domain.Event>> getEventsInRange(DateTime start, DateTime end);
  Future<domain.Event?> getById(String id);
  Future<void> save(domain.Event event);
  Future<void> delete(String id);
  Future<List<domain.Event>> getAll();
  Future<List<domain.Event>> getByCategory(String categoryId);
  Future<List<domain.Event>> getByStatus(EventStatus status);
  Future<List<domain.Event>> getBySeriesId(String seriesId);
  Future<int> countInSeries(String seriesId);
}

/// Repository for managing events in the database
class EventRepository implements IEventRepository {
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

  /// Retrieves events by series ID
  @override
  Future<List<domain.Event>> getBySeriesId(String seriesId) async {
    final query = _db.select(_db.events)
      ..where((tbl) => tbl.seriesId.equals(seriesId));

    final results = await query.get();
    return results.map<domain.Event>(_mapToEntity).toList();
  }

  /// Counts events in a series
  @override
  Future<int> countInSeries(String seriesId) async {
    final result = await (selectOnly(_db.events)
          ..addColumns([countAll()])
          ..where(_db.events.seriesId.equals(seriesId)))
        .getSingle();
    return result.read(countAll()) ?? 0;
  }

  /// Maps a database event to a domain event entity
  domain.Event _mapToEntity(Event dbEvent) {
    // Parse scheduling constraints from JSON if present
    SchedulingConstraint? schedulingConstraint;
    if (dbEvent.schedulingConstraintsJson != null) {
      try {
        final json = jsonDecode(dbEvent.schedulingConstraintsJson!) as Map<String, dynamic>;
        schedulingConstraint = SchedulingConstraint.fromJson(json);
      } catch (_) {
        // If parsing fails, leave constraints as null
      }
    }

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
      locationId: dbEvent.locationId,
      recurrenceRuleId: dbEvent.recurrenceRuleId,
      seriesId: dbEvent.seriesId,
      schedulingConstraint: schedulingConstraint,
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
    // Serialize scheduling constraints to JSON if present
    String? constraintsJson;
    if (event.schedulingConstraint != null) {
      constraintsJson = jsonEncode(event.schedulingConstraint!.toJson());
    }

    return EventsCompanion(
      id: Value(event.id),
      name: Value(event.name),
      description: Value(event.description),
      timingType: Value(event.timingType),
      fixedStartTime: Value(event.startTime),
      fixedEndTime: Value(event.endTime),
      durationMinutes: Value(event.duration?.inMinutes),
      categoryId: Value(event.categoryId),
      locationId: Value(event.locationId),
      recurrenceRuleId: Value(event.recurrenceRuleId),
      seriesId: Value(event.seriesId),
      schedulingConstraintsJson: Value(constraintsJson),
      appCanMove: Value(event.appCanMove),
      appCanResize: Value(event.appCanResize),
      isUserLocked: Value(event.isUserLocked),
      status: Value(event.status),
      createdAt: Value(event.createdAt),
      updatedAt: Value(event.updatedAt),
    );
  }
}
