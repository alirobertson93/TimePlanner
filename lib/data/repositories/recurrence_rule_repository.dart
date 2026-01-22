import 'package:drift/drift.dart';
import '../database/app_database.dart';
import '../../domain/entities/recurrence_rule.dart' as domain;
import '../../domain/enums/recurrence_frequency.dart';
import '../../domain/enums/recurrence_end_type.dart';

/// Interface for recurrence rule repository operations
abstract class IRecurrenceRuleRepository {
  Future<List<domain.RecurrenceRule>> getAll();
  Future<domain.RecurrenceRule?> getById(String id);
  Future<void> save(domain.RecurrenceRule rule);
  Future<void> delete(String id);
  Stream<List<domain.RecurrenceRule>> watchAll();
  Future<List<domain.RecurrenceRule>> getByFrequency(RecurrenceFrequency frequency);
}

/// Repository for managing recurrence rules
class RecurrenceRuleRepository implements IRecurrenceRuleRepository {
  final AppDatabase _db;

  RecurrenceRuleRepository(this._db);

  /// Get all recurrence rules
  Future<List<domain.RecurrenceRule>> getAll() async {
    final rows = await _db.select(_db.recurrenceRules).get();
    return rows.map(_mapToEntity).toList();
  }

  /// Get a recurrence rule by ID
  Future<domain.RecurrenceRule?> getById(String id) async {
    final query = _db.select(_db.recurrenceRules)
      ..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row != null ? _mapToEntity(row) : null;
  }

  /// Save (insert or update) a recurrence rule
  Future<void> save(domain.RecurrenceRule rule) async {
    final companion = _mapToDbModel(rule);
    await _db.into(_db.recurrenceRules).insertOnConflictUpdate(companion);
  }

  /// Delete a recurrence rule by ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.recurrenceRules)..where((t) => t.id.equals(id))).go();
  }

  /// Watch all recurrence rules (reactive stream)
  Stream<List<domain.RecurrenceRule>> watchAll() {
    return _db.select(_db.recurrenceRules).watch().map(
          (rows) => rows.map(_mapToEntity).toList(),
        );
  }

  /// Get recurrence rules by frequency type
  Future<List<domain.RecurrenceRule>> getByFrequency(RecurrenceFrequency frequency) async {
    final query = _db.select(_db.recurrenceRules)
      ..where((t) => t.frequency.equals(frequency.index));
    final rows = await query.get();
    return rows.map(_mapToEntity).toList();
  }

  /// Map database row to domain entity
  domain.RecurrenceRule _mapToEntity(RecurrenceRule dbRule) {
    return domain.RecurrenceRule(
      id: dbRule.id,
      frequency: dbRule.frequency,
      interval: dbRule.interval,
      byWeekDay: domain.RecurrenceRule.byWeekDayFromJson(dbRule.byWeekDay),
      byMonthDay: domain.RecurrenceRule.byMonthDayFromJson(dbRule.byMonthDay),
      endType: dbRule.endType,
      endDate: dbRule.endDate,
      occurrences: dbRule.occurrences,
      createdAt: dbRule.createdAt,
    );
  }

  /// Map domain entity to database model
  RecurrenceRulesCompanion _mapToDbModel(domain.RecurrenceRule rule) {
    return RecurrenceRulesCompanion(
      id: Value(rule.id),
      frequency: Value(rule.frequency),
      interval: Value(rule.interval),
      byWeekDay: Value(rule.byWeekDayJson),
      byMonthDay: Value(rule.byMonthDayJson),
      endType: Value(rule.endType),
      endDate: Value(rule.endDate),
      occurrences: Value(rule.occurrences),
      createdAt: Value(rule.createdAt),
    );
  }
}
