import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/services/series_matching_service.dart';
import '../../domain/services/series_edit_service.dart';
import 'repository_providers.dart';

/// Provider for the SeriesMatchingService.
/// 
/// This service finds existing series that match a given activity,
/// allowing users to group related activities together.
final seriesMatchingServiceProvider = Provider<SeriesMatchingService>((ref) {
  return SeriesMatchingService(
    ref.watch(eventRepositoryProvider),
    ref.watch(eventPeopleRepositoryProvider),
  );
});

/// Provider for the SeriesEditService.
/// 
/// This service handles editing activities in a series,
/// applying changes to multiple activities based on the selected scope.
final seriesEditServiceProvider = Provider<SeriesEditService>((ref) {
  return SeriesEditService(
    ref.watch(eventRepositoryProvider),
  );
});
