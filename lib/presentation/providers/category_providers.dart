import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/category.dart';
import 'repository_providers.dart';

part 'category_providers.g.dart';

/// Provider for all categories
@riverpod
Future<List<Category>> categories(Ref ref) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getAll();
}

/// Provider to get a single category by ID
@riverpod
Future<Category?> categoryById(Ref ref, String categoryId) async {
  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getById(categoryId);
}

/// Provider for deleting an event
@riverpod
class DeleteEvent extends _$DeleteEvent {
  @override
  FutureOr<void> build() {
    // Initial state - nothing to do
  }

  /// Delete an event by ID
  Future<bool> call(String eventId) async {
    state = const AsyncLoading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(eventRepositoryProvider);
      await repository.delete(eventId);
    });
    
    return !state.hasError;
  }
}