import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/category.dart';
import 'repository_providers.dart';

part 'category_providers.g.dart';

/// Provider for all categories
@riverpod
Future<List<Category>> categories(CategoriesRef ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAll();
}

/// Provider to get a single category by ID
@riverpod
Future<Category?> categoryById(CategoryByIdRef ref, String categoryId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getById(categoryId);
}