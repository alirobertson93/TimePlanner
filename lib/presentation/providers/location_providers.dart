import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/location.dart';
import 'repository_providers.dart';

part 'location_providers.g.dart';

/// Provider to get all locations
@riverpod
Future<List<Location>> allLocations(AllLocationsRef ref) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getAll();
}

/// Provider to watch all locations reactively
@riverpod
Stream<List<Location>> watchAllLocations(WatchAllLocationsRef ref) {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.watchAll();
}

/// Provider to get a location by ID
@riverpod
Future<Location?> locationById(LocationByIdRef ref, String id) async {
  final repository = ref.watch(locationRepositoryProvider);
  return repository.getById(id);
}

/// Provider to search locations by name
@riverpod
Future<List<Location>> searchLocations(SearchLocationsRef ref, String query) async {
  final repository = ref.watch(locationRepositoryProvider);
  if (query.isEmpty) {
    return repository.getAll();
  }
  return repository.searchByName(query);
}
