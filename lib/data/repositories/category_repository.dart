import 'package:drift/drift.dart';
import '../../domain/entities/category.dart' as domain;
import '../database/app_database.dart';

/// Interface for category repository operations
abstract class ICategoryRepository {
  Future<List<domain.Category>> getAll();
  Future<domain.Category?> getById(String id);
  Future<void> save(domain.Category category);
  Future<void> delete(String id);
}

/// Repository for managing categories in the database
class CategoryRepository implements ICategoryRepository {
  CategoryRepository(this._db);

  final AppDatabase _db;

  /// Retrieves all categories ordered by sort order
  @override
  Future<List<domain.Category>> getAll() async {
    final query = _db.select(_db.categories)
      ..orderBy([(tbl) => OrderingTerm.asc(tbl.sortOrder)]);

    final results = await query.get();
    return results.map(_mapToEntity).toList();
  }

  /// Retrieves a category by its ID
  @override
  Future<domain.Category?> getById(String id) async {
    final query = _db.select(_db.categories)..where((tbl) => tbl.id.equals(id));

    final result = await query.getSingleOrNull();
    return result != null ? _mapToEntity(result) : null;
  }

  /// Saves a category (insert or update)
  @override
  Future<void> save(domain.Category category) async {
    final companion = _mapToDbModel(category);
    await _db.into(_db.categories).insertOnConflictUpdate(companion);
  }

  /// Deletes a category by its ID
  @override
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
