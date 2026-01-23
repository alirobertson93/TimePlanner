import 'package:drift/drift.dart';
import '../../domain/entities/goal.dart' as domain;
import '../../domain/enums/goal_type.dart';
import '../../domain/enums/goal_metric.dart';
import '../../domain/enums/goal_period.dart';
import '../../domain/enums/debt_strategy.dart';
import '../database/app_database.dart';

/// Interface for goal repository operations
abstract class IGoalRepository {
  Future<List<domain.Goal>> getAll();
  Future<domain.Goal?> getById(String id);
  Future<void> save(domain.Goal goal);
  Future<void> delete(String id);
  Future<List<domain.Goal>> getByCategory(String categoryId);
  Future<List<domain.Goal>> getByPerson(String personId);
  Stream<List<domain.Goal>> watchAll();
}

/// Repository for managing goals in the database
class GoalRepository implements IGoalRepository {
  GoalRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all active goals
  Future<List<domain.Goal>> getAll() async {
    final query = _db.select(_db.goals)
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves a goal by its ID
  Future<domain.Goal?> getById(String id) async {
    final query = _db.select(_db.goals)..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Saves a goal (insert or update)
  Future<void> save(domain.Goal goal) async {
    final companion = _mapToDbModel(goal);
    await _db.into(_db.goals).insertOnConflictUpdate(companion);
  }

  /// Deletes a goal by its ID
  Future<void> delete(String id) async {
    await (_db.delete(_db.goals)..where((tbl) => tbl.id.equals(id))).go();
  }

  /// Retrieves goals for a specific category
  Future<List<domain.Goal>> getByCategory(String categoryId) async {
    final query = _db.select(_db.goals)
      ..where((tbl) => 
          tbl.categoryId.equals(categoryId) & tbl.isActive.equals(true));

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves goals for a specific person (relationship goals)
  Future<List<domain.Goal>> getByPerson(String personId) async {
    final query = _db.select(_db.goals)
      ..where((tbl) => 
          tbl.personId.equals(personId) & tbl.isActive.equals(true));

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Watches all active goals (reactive stream)
  Stream<List<domain.Goal>> watchAll() {
    final query = _db.select(_db.goals)
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.createdAt)]);

    return query.watch().map((rows) => rows.map(_mapToEntity).toList());
  }

  /// Maps a database goal to a domain goal entity
  domain.Goal _mapToEntity(GoalData dbGoal) {
    return domain.Goal(
      id: dbGoal.id,
      title: dbGoal.title,
      type: GoalType.fromValue(dbGoal.type),
      metric: GoalMetric.fromValue(dbGoal.metric),
      targetValue: dbGoal.targetValue,
      period: GoalPeriod.fromValue(dbGoal.period),
      categoryId: dbGoal.categoryId,
      personId: dbGoal.personId,
      debtStrategy: DebtStrategy.fromValue(dbGoal.debtStrategy),
      isActive: dbGoal.isActive,
      createdAt: dbGoal.createdAt,
      updatedAt: dbGoal.updatedAt,
    );
  }

  /// Maps a domain goal entity to a database companion
  GoalsCompanion _mapToDbModel(domain.Goal goal) {
    return GoalsCompanion(
      id: Value(goal.id),
      title: Value(goal.title),
      type: Value(goal.type.value),
      metric: Value(goal.metric.value),
      targetValue: Value(goal.targetValue),
      period: Value(goal.period.value),
      categoryId: Value(goal.categoryId),
      personId: Value(goal.personId),
      debtStrategy: Value(goal.debtStrategy.value),
      isActive: Value(goal.isActive),
      createdAt: Value(goal.createdAt),
      updatedAt: Value(goal.updatedAt),
    );
  }
}
