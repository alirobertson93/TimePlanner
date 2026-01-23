import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/travel_time_pair.dart';
import 'repository_providers.dart';

part 'travel_time_providers.g.dart';

/// Provider to get all travel time pairs
@riverpod
Future<List<TravelTimePair>> allTravelTimePairs(AllTravelTimePairsRef ref) async {
  final repository = ref.watch(travelTimePairRepositoryProvider);
  return repository.getAll();
}

/// Provider to watch all travel time pairs reactively
@riverpod
Stream<List<TravelTimePair>> watchAllTravelTimePairs(WatchAllTravelTimePairsRef ref) {
  final repository = ref.watch(travelTimePairRepositoryProvider);
  return repository.watchAll();
}

/// Provider to get a travel time pair by location pair (bidirectional lookup)
@riverpod
Future<TravelTimePair?> travelTimeBetweenLocations(
  TravelTimeBetweenLocationsRef ref,
  String locationId1,
  String locationId2,
) async {
  final repository = ref.watch(travelTimePairRepositoryProvider);
  return repository.getByLocationPairBidirectional(locationId1, locationId2);
}

/// Provider to get all travel time pairs for a specific location
@riverpod
Future<List<TravelTimePair>> travelTimesForLocation(
  TravelTimesForLocationRef ref,
  String locationId,
) async {
  final repository = ref.watch(travelTimePairRepositoryProvider);
  return repository.getForLocation(locationId);
}
